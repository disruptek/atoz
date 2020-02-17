
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  Call_AddFlowOutputs_610996 = ref object of OpenApiRestCall_610658
proc url_AddFlowOutputs_610998(protocol: Scheme; host: string; base: string;
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

proc validate_AddFlowOutputs_610997(path: JsonNode; query: JsonNode;
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
  var valid_611124 = path.getOrDefault("flowArn")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "flowArn", valid_611124
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
  var valid_611125 = header.getOrDefault("X-Amz-Signature")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Signature", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Content-Sha256", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Date")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Date", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Credential")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Credential", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Security-Token")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Security-Token", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Algorithm")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Algorithm", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-SignedHeaders", valid_611131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611155: Call_AddFlowOutputs_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ## 
  let valid = call_611155.validator(path, query, header, formData, body)
  let scheme = call_611155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611155.url(scheme.get, call_611155.host, call_611155.base,
                         call_611155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611155, url, valid)

proc call*(call_611226: Call_AddFlowOutputs_610996; body: JsonNode; flowArn: string): Recallable =
  ## addFlowOutputs
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that you want to add outputs to.
  var path_611227 = newJObject()
  var body_611229 = newJObject()
  if body != nil:
    body_611229 = body
  add(path_611227, "flowArn", newJString(flowArn))
  result = call_611226.call(path_611227, nil, nil, nil, body_611229)

var addFlowOutputs* = Call_AddFlowOutputs_610996(name: "addFlowOutputs",
    meth: HttpMethod.HttpPost, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs", validator: validate_AddFlowOutputs_610997,
    base: "/", url: url_AddFlowOutputs_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlow_611285 = ref object of OpenApiRestCall_610658
proc url_CreateFlow_611287(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFlow_611286(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611288 = header.getOrDefault("X-Amz-Signature")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Signature", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Content-Sha256", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Date")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Date", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Credential")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Credential", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Security-Token")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Security-Token", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Algorithm")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Algorithm", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-SignedHeaders", valid_611294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611296: Call_CreateFlow_611285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ## 
  let valid = call_611296.validator(path, query, header, formData, body)
  let scheme = call_611296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611296.url(scheme.get, call_611296.host, call_611296.base,
                         call_611296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611296, url, valid)

proc call*(call_611297: Call_CreateFlow_611285; body: JsonNode): Recallable =
  ## createFlow
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ##   body: JObject (required)
  var body_611298 = newJObject()
  if body != nil:
    body_611298 = body
  result = call_611297.call(nil, nil, nil, nil, body_611298)

var createFlow* = Call_CreateFlow_611285(name: "createFlow",
                                      meth: HttpMethod.HttpPost,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows",
                                      validator: validate_CreateFlow_611286,
                                      base: "/", url: url_CreateFlow_611287,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlows_611268 = ref object of OpenApiRestCall_610658
proc url_ListFlows_611270(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFlows_611269(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611271 = query.getOrDefault("nextToken")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "nextToken", valid_611271
  var valid_611272 = query.getOrDefault("MaxResults")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "MaxResults", valid_611272
  var valid_611273 = query.getOrDefault("NextToken")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "NextToken", valid_611273
  var valid_611274 = query.getOrDefault("maxResults")
  valid_611274 = validateParameter(valid_611274, JInt, required = false, default = nil)
  if valid_611274 != nil:
    section.add "maxResults", valid_611274
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
  var valid_611275 = header.getOrDefault("X-Amz-Signature")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Signature", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Content-Sha256", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Date")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Date", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Credential")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Credential", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Security-Token")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Security-Token", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-Algorithm")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-Algorithm", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-SignedHeaders", valid_611281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611282: Call_ListFlows_611268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
  ## 
  let valid = call_611282.validator(path, query, header, formData, body)
  let scheme = call_611282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611282.url(scheme.get, call_611282.host, call_611282.base,
                         call_611282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611282, url, valid)

proc call*(call_611283: Call_ListFlows_611268; nextToken: string = "";
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
  var query_611284 = newJObject()
  add(query_611284, "nextToken", newJString(nextToken))
  add(query_611284, "MaxResults", newJString(MaxResults))
  add(query_611284, "NextToken", newJString(NextToken))
  add(query_611284, "maxResults", newJInt(maxResults))
  result = call_611283.call(nil, query_611284, nil, nil, nil)

var listFlows* = Call_ListFlows_611268(name: "listFlows", meth: HttpMethod.HttpGet,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows",
                                    validator: validate_ListFlows_611269,
                                    base: "/", url: url_ListFlows_611270,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlow_611299 = ref object of OpenApiRestCall_610658
proc url_DescribeFlow_611301(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFlow_611300(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611302 = path.getOrDefault("flowArn")
  valid_611302 = validateParameter(valid_611302, JString, required = true,
                                 default = nil)
  if valid_611302 != nil:
    section.add "flowArn", valid_611302
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
  var valid_611303 = header.getOrDefault("X-Amz-Signature")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Signature", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Content-Sha256", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Date")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Date", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Credential")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Credential", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Security-Token")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Security-Token", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Algorithm")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Algorithm", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-SignedHeaders", valid_611309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611310: Call_DescribeFlow_611299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ## 
  let valid = call_611310.validator(path, query, header, formData, body)
  let scheme = call_611310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611310.url(scheme.get, call_611310.host, call_611310.base,
                         call_611310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611310, url, valid)

proc call*(call_611311: Call_DescribeFlow_611299; flowArn: string): Recallable =
  ## describeFlow
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to describe.
  var path_611312 = newJObject()
  add(path_611312, "flowArn", newJString(flowArn))
  result = call_611311.call(path_611312, nil, nil, nil, nil)

var describeFlow* = Call_DescribeFlow_611299(name: "describeFlow",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}", validator: validate_DescribeFlow_611300,
    base: "/", url: url_DescribeFlow_611301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlow_611313 = ref object of OpenApiRestCall_610658
proc url_DeleteFlow_611315(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFlow_611314(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611316 = path.getOrDefault("flowArn")
  valid_611316 = validateParameter(valid_611316, JString, required = true,
                                 default = nil)
  if valid_611316 != nil:
    section.add "flowArn", valid_611316
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
  var valid_611317 = header.getOrDefault("X-Amz-Signature")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Signature", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Content-Sha256", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Date")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Date", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Credential")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Credential", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Security-Token")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Security-Token", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-Algorithm")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Algorithm", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-SignedHeaders", valid_611323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611324: Call_DeleteFlow_611313; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ## 
  let valid = call_611324.validator(path, query, header, formData, body)
  let scheme = call_611324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611324.url(scheme.get, call_611324.host, call_611324.base,
                         call_611324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611324, url, valid)

proc call*(call_611325: Call_DeleteFlow_611313; flowArn: string): Recallable =
  ## deleteFlow
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to delete.
  var path_611326 = newJObject()
  add(path_611326, "flowArn", newJString(flowArn))
  result = call_611325.call(path_611326, nil, nil, nil, nil)

var deleteFlow* = Call_DeleteFlow_611313(name: "deleteFlow",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows/{flowArn}",
                                      validator: validate_DeleteFlow_611314,
                                      base: "/", url: url_DeleteFlow_611315,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GrantFlowEntitlements_611327 = ref object of OpenApiRestCall_610658
proc url_GrantFlowEntitlements_611329(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GrantFlowEntitlements_611328(path: JsonNode; query: JsonNode;
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
  var valid_611330 = path.getOrDefault("flowArn")
  valid_611330 = validateParameter(valid_611330, JString, required = true,
                                 default = nil)
  if valid_611330 != nil:
    section.add "flowArn", valid_611330
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
  var valid_611331 = header.getOrDefault("X-Amz-Signature")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Signature", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Content-Sha256", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Date")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Date", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Credential")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Credential", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Security-Token")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Security-Token", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-Algorithm")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Algorithm", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-SignedHeaders", valid_611337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611339: Call_GrantFlowEntitlements_611327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants entitlements to an existing flow.
  ## 
  let valid = call_611339.validator(path, query, header, formData, body)
  let scheme = call_611339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611339.url(scheme.get, call_611339.host, call_611339.base,
                         call_611339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611339, url, valid)

proc call*(call_611340: Call_GrantFlowEntitlements_611327; body: JsonNode;
          flowArn: string): Recallable =
  ## grantFlowEntitlements
  ## Grants entitlements to an existing flow.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that you want to grant entitlements on.
  var path_611341 = newJObject()
  var body_611342 = newJObject()
  if body != nil:
    body_611342 = body
  add(path_611341, "flowArn", newJString(flowArn))
  result = call_611340.call(path_611341, nil, nil, nil, body_611342)

var grantFlowEntitlements* = Call_GrantFlowEntitlements_611327(
    name: "grantFlowEntitlements", meth: HttpMethod.HttpPost,
    host: "mediaconnect.amazonaws.com", route: "/v1/flows/{flowArn}/entitlements",
    validator: validate_GrantFlowEntitlements_611328, base: "/",
    url: url_GrantFlowEntitlements_611329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitlements_611343 = ref object of OpenApiRestCall_610658
proc url_ListEntitlements_611345(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEntitlements_611344(path: JsonNode; query: JsonNode;
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
  var valid_611346 = query.getOrDefault("nextToken")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "nextToken", valid_611346
  var valid_611347 = query.getOrDefault("MaxResults")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "MaxResults", valid_611347
  var valid_611348 = query.getOrDefault("NextToken")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "NextToken", valid_611348
  var valid_611349 = query.getOrDefault("maxResults")
  valid_611349 = validateParameter(valid_611349, JInt, required = false, default = nil)
  if valid_611349 != nil:
    section.add "maxResults", valid_611349
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
  var valid_611350 = header.getOrDefault("X-Amz-Signature")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Signature", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Content-Sha256", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Date")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Date", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Credential")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Credential", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Security-Token")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Security-Token", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Algorithm")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Algorithm", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-SignedHeaders", valid_611356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611357: Call_ListEntitlements_611343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
  ## 
  let valid = call_611357.validator(path, query, header, formData, body)
  let scheme = call_611357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611357.url(scheme.get, call_611357.host, call_611357.base,
                         call_611357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611357, url, valid)

proc call*(call_611358: Call_ListEntitlements_611343; nextToken: string = "";
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
  var query_611359 = newJObject()
  add(query_611359, "nextToken", newJString(nextToken))
  add(query_611359, "MaxResults", newJString(MaxResults))
  add(query_611359, "NextToken", newJString(NextToken))
  add(query_611359, "maxResults", newJInt(maxResults))
  result = call_611358.call(nil, query_611359, nil, nil, nil)

var listEntitlements* = Call_ListEntitlements_611343(name: "listEntitlements",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/entitlements", validator: validate_ListEntitlements_611344,
    base: "/", url: url_ListEntitlements_611345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611374 = ref object of OpenApiRestCall_610658
proc url_TagResource_611376(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_611375(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611377 = path.getOrDefault("resourceArn")
  valid_611377 = validateParameter(valid_611377, JString, required = true,
                                 default = nil)
  if valid_611377 != nil:
    section.add "resourceArn", valid_611377
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
  var valid_611378 = header.getOrDefault("X-Amz-Signature")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Signature", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Content-Sha256", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Date")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Date", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Credential")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Credential", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Security-Token")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Security-Token", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Algorithm")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Algorithm", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-SignedHeaders", valid_611384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611386: Call_TagResource_611374; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_611386.validator(path, query, header, formData, body)
  let scheme = call_611386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611386.url(scheme.get, call_611386.host, call_611386.base,
                         call_611386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611386, url, valid)

proc call*(call_611387: Call_TagResource_611374; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource to which to add tags.
  ##   body: JObject (required)
  var path_611388 = newJObject()
  var body_611389 = newJObject()
  add(path_611388, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_611389 = body
  result = call_611387.call(path_611388, nil, nil, nil, body_611389)

var tagResource* = Call_TagResource_611374(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconnect.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_611375,
                                        base: "/", url: url_TagResource_611376,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611360 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611362(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_611361(path: JsonNode; query: JsonNode;
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
  var valid_611363 = path.getOrDefault("resourceArn")
  valid_611363 = validateParameter(valid_611363, JString, required = true,
                                 default = nil)
  if valid_611363 != nil:
    section.add "resourceArn", valid_611363
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
  var valid_611364 = header.getOrDefault("X-Amz-Signature")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Signature", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Content-Sha256", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-Date")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Date", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Credential")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Credential", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Security-Token")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Security-Token", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Algorithm")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Algorithm", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-SignedHeaders", valid_611370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611371: Call_ListTagsForResource_611360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags on an AWS Elemental MediaConnect resource
  ## 
  let valid = call_611371.validator(path, query, header, formData, body)
  let scheme = call_611371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611371.url(scheme.get, call_611371.host, call_611371.base,
                         call_611371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611371, url, valid)

proc call*(call_611372: Call_ListTagsForResource_611360; resourceArn: string): Recallable =
  ## listTagsForResource
  ## List all tags on an AWS Elemental MediaConnect resource
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource for which to list the tags.
  var path_611373 = newJObject()
  add(path_611373, "resourceArn", newJString(resourceArn))
  result = call_611372.call(path_611373, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611360(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconnect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_611361, base: "/",
    url: url_ListTagsForResource_611362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowOutput_611390 = ref object of OpenApiRestCall_610658
proc url_UpdateFlowOutput_611392(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFlowOutput_611391(path: JsonNode; query: JsonNode;
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
  var valid_611393 = path.getOrDefault("outputArn")
  valid_611393 = validateParameter(valid_611393, JString, required = true,
                                 default = nil)
  if valid_611393 != nil:
    section.add "outputArn", valid_611393
  var valid_611394 = path.getOrDefault("flowArn")
  valid_611394 = validateParameter(valid_611394, JString, required = true,
                                 default = nil)
  if valid_611394 != nil:
    section.add "flowArn", valid_611394
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
  var valid_611395 = header.getOrDefault("X-Amz-Signature")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Signature", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Content-Sha256", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Date")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Date", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Credential")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Credential", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Security-Token")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Security-Token", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-Algorithm")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Algorithm", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-SignedHeaders", valid_611401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611403: Call_UpdateFlowOutput_611390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing flow output.
  ## 
  let valid = call_611403.validator(path, query, header, formData, body)
  let scheme = call_611403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611403.url(scheme.get, call_611403.host, call_611403.base,
                         call_611403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611403, url, valid)

proc call*(call_611404: Call_UpdateFlowOutput_611390; outputArn: string;
          body: JsonNode; flowArn: string): Recallable =
  ## updateFlowOutput
  ## Updates an existing flow output.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to update.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that is associated with the output that you want to update.
  var path_611405 = newJObject()
  var body_611406 = newJObject()
  add(path_611405, "outputArn", newJString(outputArn))
  if body != nil:
    body_611406 = body
  add(path_611405, "flowArn", newJString(flowArn))
  result = call_611404.call(path_611405, nil, nil, nil, body_611406)

var updateFlowOutput* = Call_UpdateFlowOutput_611390(name: "updateFlowOutput",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_UpdateFlowOutput_611391, base: "/",
    url: url_UpdateFlowOutput_611392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFlowOutput_611407 = ref object of OpenApiRestCall_610658
proc url_RemoveFlowOutput_611409(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveFlowOutput_611408(path: JsonNode; query: JsonNode;
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
  var valid_611410 = path.getOrDefault("outputArn")
  valid_611410 = validateParameter(valid_611410, JString, required = true,
                                 default = nil)
  if valid_611410 != nil:
    section.add "outputArn", valid_611410
  var valid_611411 = path.getOrDefault("flowArn")
  valid_611411 = validateParameter(valid_611411, JString, required = true,
                                 default = nil)
  if valid_611411 != nil:
    section.add "flowArn", valid_611411
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
  var valid_611412 = header.getOrDefault("X-Amz-Signature")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Signature", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Content-Sha256", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Date")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Date", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Credential")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Credential", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Security-Token")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Security-Token", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Algorithm")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Algorithm", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-SignedHeaders", valid_611418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611419: Call_RemoveFlowOutput_611407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ## 
  let valid = call_611419.validator(path, query, header, formData, body)
  let scheme = call_611419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611419.url(scheme.get, call_611419.host, call_611419.base,
                         call_611419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611419, url, valid)

proc call*(call_611420: Call_RemoveFlowOutput_611407; outputArn: string;
          flowArn: string): Recallable =
  ## removeFlowOutput
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to remove.
  ##   flowArn: string (required)
  ##          : The flow that you want to remove an output from.
  var path_611421 = newJObject()
  add(path_611421, "outputArn", newJString(outputArn))
  add(path_611421, "flowArn", newJString(flowArn))
  result = call_611420.call(path_611421, nil, nil, nil, nil)

var removeFlowOutput* = Call_RemoveFlowOutput_611407(name: "removeFlowOutput",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_RemoveFlowOutput_611408, base: "/",
    url: url_RemoveFlowOutput_611409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowEntitlement_611422 = ref object of OpenApiRestCall_610658
proc url_UpdateFlowEntitlement_611424(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFlowEntitlement_611423(path: JsonNode; query: JsonNode;
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
  var valid_611425 = path.getOrDefault("entitlementArn")
  valid_611425 = validateParameter(valid_611425, JString, required = true,
                                 default = nil)
  if valid_611425 != nil:
    section.add "entitlementArn", valid_611425
  var valid_611426 = path.getOrDefault("flowArn")
  valid_611426 = validateParameter(valid_611426, JString, required = true,
                                 default = nil)
  if valid_611426 != nil:
    section.add "flowArn", valid_611426
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
  var valid_611427 = header.getOrDefault("X-Amz-Signature")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Signature", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Content-Sha256", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Date")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Date", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Credential")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Credential", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Security-Token")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Security-Token", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Algorithm")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Algorithm", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-SignedHeaders", valid_611433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611435: Call_UpdateFlowEntitlement_611422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ## 
  let valid = call_611435.validator(path, query, header, formData, body)
  let scheme = call_611435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611435.url(scheme.get, call_611435.host, call_611435.base,
                         call_611435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611435, url, valid)

proc call*(call_611436: Call_UpdateFlowEntitlement_611422; entitlementArn: string;
          body: JsonNode; flowArn: string): Recallable =
  ## updateFlowEntitlement
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to update.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that is associated with the entitlement that you want to update.
  var path_611437 = newJObject()
  var body_611438 = newJObject()
  add(path_611437, "entitlementArn", newJString(entitlementArn))
  if body != nil:
    body_611438 = body
  add(path_611437, "flowArn", newJString(flowArn))
  result = call_611436.call(path_611437, nil, nil, nil, body_611438)

var updateFlowEntitlement* = Call_UpdateFlowEntitlement_611422(
    name: "updateFlowEntitlement", meth: HttpMethod.HttpPut,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_UpdateFlowEntitlement_611423, base: "/",
    url: url_UpdateFlowEntitlement_611424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeFlowEntitlement_611439 = ref object of OpenApiRestCall_610658
proc url_RevokeFlowEntitlement_611441(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RevokeFlowEntitlement_611440(path: JsonNode; query: JsonNode;
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
  var valid_611442 = path.getOrDefault("entitlementArn")
  valid_611442 = validateParameter(valid_611442, JString, required = true,
                                 default = nil)
  if valid_611442 != nil:
    section.add "entitlementArn", valid_611442
  var valid_611443 = path.getOrDefault("flowArn")
  valid_611443 = validateParameter(valid_611443, JString, required = true,
                                 default = nil)
  if valid_611443 != nil:
    section.add "flowArn", valid_611443
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
  var valid_611444 = header.getOrDefault("X-Amz-Signature")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Signature", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Content-Sha256", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Date")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Date", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Credential")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Credential", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Security-Token")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Security-Token", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Algorithm")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Algorithm", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-SignedHeaders", valid_611450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611451: Call_RevokeFlowEntitlement_611439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ## 
  let valid = call_611451.validator(path, query, header, formData, body)
  let scheme = call_611451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611451.url(scheme.get, call_611451.host, call_611451.base,
                         call_611451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611451, url, valid)

proc call*(call_611452: Call_RevokeFlowEntitlement_611439; entitlementArn: string;
          flowArn: string): Recallable =
  ## revokeFlowEntitlement
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to revoke.
  ##   flowArn: string (required)
  ##          : The flow that you want to revoke an entitlement from.
  var path_611453 = newJObject()
  add(path_611453, "entitlementArn", newJString(entitlementArn))
  add(path_611453, "flowArn", newJString(flowArn))
  result = call_611452.call(path_611453, nil, nil, nil, nil)

var revokeFlowEntitlement* = Call_RevokeFlowEntitlement_611439(
    name: "revokeFlowEntitlement", meth: HttpMethod.HttpDelete,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_RevokeFlowEntitlement_611440, base: "/",
    url: url_RevokeFlowEntitlement_611441, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFlow_611454 = ref object of OpenApiRestCall_610658
proc url_StartFlow_611456(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartFlow_611455(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611457 = path.getOrDefault("flowArn")
  valid_611457 = validateParameter(valid_611457, JString, required = true,
                                 default = nil)
  if valid_611457 != nil:
    section.add "flowArn", valid_611457
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
  var valid_611458 = header.getOrDefault("X-Amz-Signature")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Signature", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Content-Sha256", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Date")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Date", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-Credential")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Credential", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-Security-Token")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Security-Token", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Algorithm")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Algorithm", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-SignedHeaders", valid_611464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611465: Call_StartFlow_611454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a flow.
  ## 
  let valid = call_611465.validator(path, query, header, formData, body)
  let scheme = call_611465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611465.url(scheme.get, call_611465.host, call_611465.base,
                         call_611465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611465, url, valid)

proc call*(call_611466: Call_StartFlow_611454; flowArn: string): Recallable =
  ## startFlow
  ## Starts a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to start.
  var path_611467 = newJObject()
  add(path_611467, "flowArn", newJString(flowArn))
  result = call_611466.call(path_611467, nil, nil, nil, nil)

var startFlow* = Call_StartFlow_611454(name: "startFlow", meth: HttpMethod.HttpPost,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows/start/{flowArn}",
                                    validator: validate_StartFlow_611455,
                                    base: "/", url: url_StartFlow_611456,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFlow_611468 = ref object of OpenApiRestCall_610658
proc url_StopFlow_611470(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopFlow_611469(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611471 = path.getOrDefault("flowArn")
  valid_611471 = validateParameter(valid_611471, JString, required = true,
                                 default = nil)
  if valid_611471 != nil:
    section.add "flowArn", valid_611471
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
  var valid_611472 = header.getOrDefault("X-Amz-Signature")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-Signature", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Content-Sha256", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-Date")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Date", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-Credential")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Credential", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Security-Token")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Security-Token", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Algorithm")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Algorithm", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-SignedHeaders", valid_611478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611479: Call_StopFlow_611468; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a flow.
  ## 
  let valid = call_611479.validator(path, query, header, formData, body)
  let scheme = call_611479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611479.url(scheme.get, call_611479.host, call_611479.base,
                         call_611479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611479, url, valid)

proc call*(call_611480: Call_StopFlow_611468; flowArn: string): Recallable =
  ## stopFlow
  ## Stops a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to stop.
  var path_611481 = newJObject()
  add(path_611481, "flowArn", newJString(flowArn))
  result = call_611480.call(path_611481, nil, nil, nil, nil)

var stopFlow* = Call_StopFlow_611468(name: "stopFlow", meth: HttpMethod.HttpPost,
                                  host: "mediaconnect.amazonaws.com",
                                  route: "/v1/flows/stop/{flowArn}",
                                  validator: validate_StopFlow_611469, base: "/",
                                  url: url_StopFlow_611470,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611482 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611484(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_611483(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611485 = path.getOrDefault("resourceArn")
  valid_611485 = validateParameter(valid_611485, JString, required = true,
                                 default = nil)
  if valid_611485 != nil:
    section.add "resourceArn", valid_611485
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611486 = query.getOrDefault("tagKeys")
  valid_611486 = validateParameter(valid_611486, JArray, required = true, default = nil)
  if valid_611486 != nil:
    section.add "tagKeys", valid_611486
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
  var valid_611487 = header.getOrDefault("X-Amz-Signature")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Signature", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Content-Sha256", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Date")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Date", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Credential")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Credential", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-Security-Token")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-Security-Token", valid_611491
  var valid_611492 = header.getOrDefault("X-Amz-Algorithm")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-Algorithm", valid_611492
  var valid_611493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-SignedHeaders", valid_611493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611494: Call_UntagResource_611482; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_611494.validator(path, query, header, formData, body)
  let scheme = call_611494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611494.url(scheme.get, call_611494.host, call_611494.base,
                         call_611494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611494, url, valid)

proc call*(call_611495: Call_UntagResource_611482; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource from which to delete tags.
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  var path_611496 = newJObject()
  var query_611497 = newJObject()
  add(path_611496, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_611497.add "tagKeys", tagKeys
  result = call_611495.call(path_611496, query_611497, nil, nil, nil)

var untagResource* = Call_UntagResource_611482(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_611483,
    base: "/", url: url_UntagResource_611484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowSource_611498 = ref object of OpenApiRestCall_610658
proc url_UpdateFlowSource_611500(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFlowSource_611499(path: JsonNode; query: JsonNode;
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
  var valid_611501 = path.getOrDefault("sourceArn")
  valid_611501 = validateParameter(valid_611501, JString, required = true,
                                 default = nil)
  if valid_611501 != nil:
    section.add "sourceArn", valid_611501
  var valid_611502 = path.getOrDefault("flowArn")
  valid_611502 = validateParameter(valid_611502, JString, required = true,
                                 default = nil)
  if valid_611502 != nil:
    section.add "flowArn", valid_611502
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
  var valid_611503 = header.getOrDefault("X-Amz-Signature")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Signature", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Content-Sha256", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Date")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Date", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Credential")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Credential", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Security-Token")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Security-Token", valid_611507
  var valid_611508 = header.getOrDefault("X-Amz-Algorithm")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Algorithm", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-SignedHeaders", valid_611509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611511: Call_UpdateFlowSource_611498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the source of a flow.
  ## 
  let valid = call_611511.validator(path, query, header, formData, body)
  let scheme = call_611511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611511.url(scheme.get, call_611511.host, call_611511.base,
                         call_611511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611511, url, valid)

proc call*(call_611512: Call_UpdateFlowSource_611498; sourceArn: string;
          body: JsonNode; flowArn: string): Recallable =
  ## updateFlowSource
  ## Updates the source of a flow.
  ##   sourceArn: string (required)
  ##            : The ARN of the source that you want to update.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that is associated with the source that you want to update.
  var path_611513 = newJObject()
  var body_611514 = newJObject()
  add(path_611513, "sourceArn", newJString(sourceArn))
  if body != nil:
    body_611514 = body
  add(path_611513, "flowArn", newJString(flowArn))
  result = call_611512.call(path_611513, nil, nil, nil, body_611514)

var updateFlowSource* = Call_UpdateFlowSource_611498(name: "updateFlowSource",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/source/{sourceArn}",
    validator: validate_UpdateFlowSource_611499, base: "/",
    url: url_UpdateFlowSource_611500, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
