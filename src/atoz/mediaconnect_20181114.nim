
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
  Call_AddFlowOutputs_612996 = ref object of OpenApiRestCall_612658
proc url_AddFlowOutputs_612998(protocol: Scheme; host: string; base: string;
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

proc validate_AddFlowOutputs_612997(path: JsonNode; query: JsonNode;
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
  var valid_613124 = path.getOrDefault("flowArn")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "flowArn", valid_613124
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
  var valid_613125 = header.getOrDefault("X-Amz-Signature")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Signature", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Content-Sha256", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Date")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Date", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Credential")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Credential", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Security-Token")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Security-Token", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Algorithm")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Algorithm", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-SignedHeaders", valid_613131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613155: Call_AddFlowOutputs_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ## 
  let valid = call_613155.validator(path, query, header, formData, body)
  let scheme = call_613155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613155.url(scheme.get, call_613155.host, call_613155.base,
                         call_613155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613155, url, valid)

proc call*(call_613226: Call_AddFlowOutputs_612996; body: JsonNode; flowArn: string): Recallable =
  ## addFlowOutputs
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that you want to add outputs to.
  var path_613227 = newJObject()
  var body_613229 = newJObject()
  if body != nil:
    body_613229 = body
  add(path_613227, "flowArn", newJString(flowArn))
  result = call_613226.call(path_613227, nil, nil, nil, body_613229)

var addFlowOutputs* = Call_AddFlowOutputs_612996(name: "addFlowOutputs",
    meth: HttpMethod.HttpPost, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs", validator: validate_AddFlowOutputs_612997,
    base: "/", url: url_AddFlowOutputs_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlow_613285 = ref object of OpenApiRestCall_612658
proc url_CreateFlow_613287(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateFlow_613286(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613288 = header.getOrDefault("X-Amz-Signature")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Signature", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Content-Sha256", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Date")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Date", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Credential")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Credential", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Security-Token")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Security-Token", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Algorithm")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Algorithm", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-SignedHeaders", valid_613294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613296: Call_CreateFlow_613285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ## 
  let valid = call_613296.validator(path, query, header, formData, body)
  let scheme = call_613296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613296.url(scheme.get, call_613296.host, call_613296.base,
                         call_613296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613296, url, valid)

proc call*(call_613297: Call_CreateFlow_613285; body: JsonNode): Recallable =
  ## createFlow
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ##   body: JObject (required)
  var body_613298 = newJObject()
  if body != nil:
    body_613298 = body
  result = call_613297.call(nil, nil, nil, nil, body_613298)

var createFlow* = Call_CreateFlow_613285(name: "createFlow",
                                      meth: HttpMethod.HttpPost,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows",
                                      validator: validate_CreateFlow_613286,
                                      base: "/", url: url_CreateFlow_613287,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlows_613268 = ref object of OpenApiRestCall_612658
proc url_ListFlows_613270(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListFlows_613269(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613271 = query.getOrDefault("nextToken")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "nextToken", valid_613271
  var valid_613272 = query.getOrDefault("MaxResults")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "MaxResults", valid_613272
  var valid_613273 = query.getOrDefault("NextToken")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "NextToken", valid_613273
  var valid_613274 = query.getOrDefault("maxResults")
  valid_613274 = validateParameter(valid_613274, JInt, required = false, default = nil)
  if valid_613274 != nil:
    section.add "maxResults", valid_613274
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
  var valid_613275 = header.getOrDefault("X-Amz-Signature")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Signature", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Content-Sha256", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Date")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Date", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Credential")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Credential", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Security-Token")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Security-Token", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Algorithm")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Algorithm", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-SignedHeaders", valid_613281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613282: Call_ListFlows_613268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
  ## 
  let valid = call_613282.validator(path, query, header, formData, body)
  let scheme = call_613282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613282.url(scheme.get, call_613282.host, call_613282.base,
                         call_613282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613282, url, valid)

proc call*(call_613283: Call_ListFlows_613268; nextToken: string = "";
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
  var query_613284 = newJObject()
  add(query_613284, "nextToken", newJString(nextToken))
  add(query_613284, "MaxResults", newJString(MaxResults))
  add(query_613284, "NextToken", newJString(NextToken))
  add(query_613284, "maxResults", newJInt(maxResults))
  result = call_613283.call(nil, query_613284, nil, nil, nil)

var listFlows* = Call_ListFlows_613268(name: "listFlows", meth: HttpMethod.HttpGet,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows",
                                    validator: validate_ListFlows_613269,
                                    base: "/", url: url_ListFlows_613270,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlow_613299 = ref object of OpenApiRestCall_612658
proc url_DescribeFlow_613301(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFlow_613300(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613302 = path.getOrDefault("flowArn")
  valid_613302 = validateParameter(valid_613302, JString, required = true,
                                 default = nil)
  if valid_613302 != nil:
    section.add "flowArn", valid_613302
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
  var valid_613303 = header.getOrDefault("X-Amz-Signature")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Signature", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Content-Sha256", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Date")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Date", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Credential")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Credential", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Security-Token")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Security-Token", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Algorithm")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Algorithm", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-SignedHeaders", valid_613309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613310: Call_DescribeFlow_613299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ## 
  let valid = call_613310.validator(path, query, header, formData, body)
  let scheme = call_613310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613310.url(scheme.get, call_613310.host, call_613310.base,
                         call_613310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613310, url, valid)

proc call*(call_613311: Call_DescribeFlow_613299; flowArn: string): Recallable =
  ## describeFlow
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to describe.
  var path_613312 = newJObject()
  add(path_613312, "flowArn", newJString(flowArn))
  result = call_613311.call(path_613312, nil, nil, nil, nil)

var describeFlow* = Call_DescribeFlow_613299(name: "describeFlow",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}", validator: validate_DescribeFlow_613300,
    base: "/", url: url_DescribeFlow_613301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlow_613313 = ref object of OpenApiRestCall_612658
proc url_DeleteFlow_613315(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteFlow_613314(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613316 = path.getOrDefault("flowArn")
  valid_613316 = validateParameter(valid_613316, JString, required = true,
                                 default = nil)
  if valid_613316 != nil:
    section.add "flowArn", valid_613316
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
  var valid_613317 = header.getOrDefault("X-Amz-Signature")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Signature", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Content-Sha256", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Date")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Date", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Credential")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Credential", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Security-Token")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Security-Token", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Algorithm")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Algorithm", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-SignedHeaders", valid_613323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613324: Call_DeleteFlow_613313; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ## 
  let valid = call_613324.validator(path, query, header, formData, body)
  let scheme = call_613324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613324.url(scheme.get, call_613324.host, call_613324.base,
                         call_613324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613324, url, valid)

proc call*(call_613325: Call_DeleteFlow_613313; flowArn: string): Recallable =
  ## deleteFlow
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to delete.
  var path_613326 = newJObject()
  add(path_613326, "flowArn", newJString(flowArn))
  result = call_613325.call(path_613326, nil, nil, nil, nil)

var deleteFlow* = Call_DeleteFlow_613313(name: "deleteFlow",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows/{flowArn}",
                                      validator: validate_DeleteFlow_613314,
                                      base: "/", url: url_DeleteFlow_613315,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GrantFlowEntitlements_613327 = ref object of OpenApiRestCall_612658
proc url_GrantFlowEntitlements_613329(protocol: Scheme; host: string; base: string;
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

proc validate_GrantFlowEntitlements_613328(path: JsonNode; query: JsonNode;
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
  var valid_613330 = path.getOrDefault("flowArn")
  valid_613330 = validateParameter(valid_613330, JString, required = true,
                                 default = nil)
  if valid_613330 != nil:
    section.add "flowArn", valid_613330
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
  var valid_613331 = header.getOrDefault("X-Amz-Signature")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Signature", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Content-Sha256", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Date")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Date", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Credential")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Credential", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Security-Token")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Security-Token", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Algorithm")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Algorithm", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-SignedHeaders", valid_613337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613339: Call_GrantFlowEntitlements_613327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants entitlements to an existing flow.
  ## 
  let valid = call_613339.validator(path, query, header, formData, body)
  let scheme = call_613339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613339.url(scheme.get, call_613339.host, call_613339.base,
                         call_613339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613339, url, valid)

proc call*(call_613340: Call_GrantFlowEntitlements_613327; body: JsonNode;
          flowArn: string): Recallable =
  ## grantFlowEntitlements
  ## Grants entitlements to an existing flow.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that you want to grant entitlements on.
  var path_613341 = newJObject()
  var body_613342 = newJObject()
  if body != nil:
    body_613342 = body
  add(path_613341, "flowArn", newJString(flowArn))
  result = call_613340.call(path_613341, nil, nil, nil, body_613342)

var grantFlowEntitlements* = Call_GrantFlowEntitlements_613327(
    name: "grantFlowEntitlements", meth: HttpMethod.HttpPost,
    host: "mediaconnect.amazonaws.com", route: "/v1/flows/{flowArn}/entitlements",
    validator: validate_GrantFlowEntitlements_613328, base: "/",
    url: url_GrantFlowEntitlements_613329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitlements_613343 = ref object of OpenApiRestCall_612658
proc url_ListEntitlements_613345(protocol: Scheme; host: string; base: string;
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

proc validate_ListEntitlements_613344(path: JsonNode; query: JsonNode;
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
  var valid_613346 = query.getOrDefault("nextToken")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "nextToken", valid_613346
  var valid_613347 = query.getOrDefault("MaxResults")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "MaxResults", valid_613347
  var valid_613348 = query.getOrDefault("NextToken")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "NextToken", valid_613348
  var valid_613349 = query.getOrDefault("maxResults")
  valid_613349 = validateParameter(valid_613349, JInt, required = false, default = nil)
  if valid_613349 != nil:
    section.add "maxResults", valid_613349
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
  var valid_613350 = header.getOrDefault("X-Amz-Signature")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Signature", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Content-Sha256", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Date")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Date", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Credential")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Credential", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Security-Token")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Security-Token", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Algorithm")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Algorithm", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-SignedHeaders", valid_613356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613357: Call_ListEntitlements_613343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
  ## 
  let valid = call_613357.validator(path, query, header, formData, body)
  let scheme = call_613357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613357.url(scheme.get, call_613357.host, call_613357.base,
                         call_613357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613357, url, valid)

proc call*(call_613358: Call_ListEntitlements_613343; nextToken: string = "";
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
  var query_613359 = newJObject()
  add(query_613359, "nextToken", newJString(nextToken))
  add(query_613359, "MaxResults", newJString(MaxResults))
  add(query_613359, "NextToken", newJString(NextToken))
  add(query_613359, "maxResults", newJInt(maxResults))
  result = call_613358.call(nil, query_613359, nil, nil, nil)

var listEntitlements* = Call_ListEntitlements_613343(name: "listEntitlements",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/entitlements", validator: validate_ListEntitlements_613344,
    base: "/", url: url_ListEntitlements_613345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613374 = ref object of OpenApiRestCall_612658
proc url_TagResource_613376(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613375(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613377 = path.getOrDefault("resourceArn")
  valid_613377 = validateParameter(valid_613377, JString, required = true,
                                 default = nil)
  if valid_613377 != nil:
    section.add "resourceArn", valid_613377
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
  var valid_613378 = header.getOrDefault("X-Amz-Signature")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Signature", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Content-Sha256", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Date")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Date", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Credential")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Credential", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Security-Token")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Security-Token", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-Algorithm")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Algorithm", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-SignedHeaders", valid_613384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613386: Call_TagResource_613374; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_613386.validator(path, query, header, formData, body)
  let scheme = call_613386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613386.url(scheme.get, call_613386.host, call_613386.base,
                         call_613386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613386, url, valid)

proc call*(call_613387: Call_TagResource_613374; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource to which to add tags.
  ##   body: JObject (required)
  var path_613388 = newJObject()
  var body_613389 = newJObject()
  add(path_613388, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_613389 = body
  result = call_613387.call(path_613388, nil, nil, nil, body_613389)

var tagResource* = Call_TagResource_613374(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconnect.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_613375,
                                        base: "/", url: url_TagResource_613376,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613360 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613362(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613361(path: JsonNode; query: JsonNode;
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
  var valid_613363 = path.getOrDefault("resourceArn")
  valid_613363 = validateParameter(valid_613363, JString, required = true,
                                 default = nil)
  if valid_613363 != nil:
    section.add "resourceArn", valid_613363
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
  var valid_613364 = header.getOrDefault("X-Amz-Signature")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Signature", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Content-Sha256", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Date")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Date", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Credential")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Credential", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Security-Token")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Security-Token", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Algorithm")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Algorithm", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-SignedHeaders", valid_613370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613371: Call_ListTagsForResource_613360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags on an AWS Elemental MediaConnect resource
  ## 
  let valid = call_613371.validator(path, query, header, formData, body)
  let scheme = call_613371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613371.url(scheme.get, call_613371.host, call_613371.base,
                         call_613371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613371, url, valid)

proc call*(call_613372: Call_ListTagsForResource_613360; resourceArn: string): Recallable =
  ## listTagsForResource
  ## List all tags on an AWS Elemental MediaConnect resource
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource for which to list the tags.
  var path_613373 = newJObject()
  add(path_613373, "resourceArn", newJString(resourceArn))
  result = call_613372.call(path_613373, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613360(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconnect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_613361, base: "/",
    url: url_ListTagsForResource_613362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowOutput_613390 = ref object of OpenApiRestCall_612658
proc url_UpdateFlowOutput_613392(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFlowOutput_613391(path: JsonNode; query: JsonNode;
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
  var valid_613393 = path.getOrDefault("outputArn")
  valid_613393 = validateParameter(valid_613393, JString, required = true,
                                 default = nil)
  if valid_613393 != nil:
    section.add "outputArn", valid_613393
  var valid_613394 = path.getOrDefault("flowArn")
  valid_613394 = validateParameter(valid_613394, JString, required = true,
                                 default = nil)
  if valid_613394 != nil:
    section.add "flowArn", valid_613394
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
  var valid_613395 = header.getOrDefault("X-Amz-Signature")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Signature", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Content-Sha256", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Date")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Date", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-Credential")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Credential", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-Security-Token")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-Security-Token", valid_613399
  var valid_613400 = header.getOrDefault("X-Amz-Algorithm")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Algorithm", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-SignedHeaders", valid_613401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613403: Call_UpdateFlowOutput_613390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing flow output.
  ## 
  let valid = call_613403.validator(path, query, header, formData, body)
  let scheme = call_613403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613403.url(scheme.get, call_613403.host, call_613403.base,
                         call_613403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613403, url, valid)

proc call*(call_613404: Call_UpdateFlowOutput_613390; outputArn: string;
          body: JsonNode; flowArn: string): Recallable =
  ## updateFlowOutput
  ## Updates an existing flow output.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to update.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that is associated with the output that you want to update.
  var path_613405 = newJObject()
  var body_613406 = newJObject()
  add(path_613405, "outputArn", newJString(outputArn))
  if body != nil:
    body_613406 = body
  add(path_613405, "flowArn", newJString(flowArn))
  result = call_613404.call(path_613405, nil, nil, nil, body_613406)

var updateFlowOutput* = Call_UpdateFlowOutput_613390(name: "updateFlowOutput",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_UpdateFlowOutput_613391, base: "/",
    url: url_UpdateFlowOutput_613392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFlowOutput_613407 = ref object of OpenApiRestCall_612658
proc url_RemoveFlowOutput_613409(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveFlowOutput_613408(path: JsonNode; query: JsonNode;
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
  var valid_613410 = path.getOrDefault("outputArn")
  valid_613410 = validateParameter(valid_613410, JString, required = true,
                                 default = nil)
  if valid_613410 != nil:
    section.add "outputArn", valid_613410
  var valid_613411 = path.getOrDefault("flowArn")
  valid_613411 = validateParameter(valid_613411, JString, required = true,
                                 default = nil)
  if valid_613411 != nil:
    section.add "flowArn", valid_613411
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
  var valid_613412 = header.getOrDefault("X-Amz-Signature")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Signature", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Content-Sha256", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Date")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Date", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Credential")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Credential", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Security-Token")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Security-Token", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Algorithm")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Algorithm", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-SignedHeaders", valid_613418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613419: Call_RemoveFlowOutput_613407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ## 
  let valid = call_613419.validator(path, query, header, formData, body)
  let scheme = call_613419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613419.url(scheme.get, call_613419.host, call_613419.base,
                         call_613419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613419, url, valid)

proc call*(call_613420: Call_RemoveFlowOutput_613407; outputArn: string;
          flowArn: string): Recallable =
  ## removeFlowOutput
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to remove.
  ##   flowArn: string (required)
  ##          : The flow that you want to remove an output from.
  var path_613421 = newJObject()
  add(path_613421, "outputArn", newJString(outputArn))
  add(path_613421, "flowArn", newJString(flowArn))
  result = call_613420.call(path_613421, nil, nil, nil, nil)

var removeFlowOutput* = Call_RemoveFlowOutput_613407(name: "removeFlowOutput",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_RemoveFlowOutput_613408, base: "/",
    url: url_RemoveFlowOutput_613409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowEntitlement_613422 = ref object of OpenApiRestCall_612658
proc url_UpdateFlowEntitlement_613424(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFlowEntitlement_613423(path: JsonNode; query: JsonNode;
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
  var valid_613425 = path.getOrDefault("entitlementArn")
  valid_613425 = validateParameter(valid_613425, JString, required = true,
                                 default = nil)
  if valid_613425 != nil:
    section.add "entitlementArn", valid_613425
  var valid_613426 = path.getOrDefault("flowArn")
  valid_613426 = validateParameter(valid_613426, JString, required = true,
                                 default = nil)
  if valid_613426 != nil:
    section.add "flowArn", valid_613426
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
  var valid_613427 = header.getOrDefault("X-Amz-Signature")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Signature", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Content-Sha256", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Date")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Date", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Credential")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Credential", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Security-Token")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Security-Token", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Algorithm")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Algorithm", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-SignedHeaders", valid_613433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613435: Call_UpdateFlowEntitlement_613422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ## 
  let valid = call_613435.validator(path, query, header, formData, body)
  let scheme = call_613435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613435.url(scheme.get, call_613435.host, call_613435.base,
                         call_613435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613435, url, valid)

proc call*(call_613436: Call_UpdateFlowEntitlement_613422; entitlementArn: string;
          body: JsonNode; flowArn: string): Recallable =
  ## updateFlowEntitlement
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to update.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that is associated with the entitlement that you want to update.
  var path_613437 = newJObject()
  var body_613438 = newJObject()
  add(path_613437, "entitlementArn", newJString(entitlementArn))
  if body != nil:
    body_613438 = body
  add(path_613437, "flowArn", newJString(flowArn))
  result = call_613436.call(path_613437, nil, nil, nil, body_613438)

var updateFlowEntitlement* = Call_UpdateFlowEntitlement_613422(
    name: "updateFlowEntitlement", meth: HttpMethod.HttpPut,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_UpdateFlowEntitlement_613423, base: "/",
    url: url_UpdateFlowEntitlement_613424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeFlowEntitlement_613439 = ref object of OpenApiRestCall_612658
proc url_RevokeFlowEntitlement_613441(protocol: Scheme; host: string; base: string;
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

proc validate_RevokeFlowEntitlement_613440(path: JsonNode; query: JsonNode;
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
  var valid_613442 = path.getOrDefault("entitlementArn")
  valid_613442 = validateParameter(valid_613442, JString, required = true,
                                 default = nil)
  if valid_613442 != nil:
    section.add "entitlementArn", valid_613442
  var valid_613443 = path.getOrDefault("flowArn")
  valid_613443 = validateParameter(valid_613443, JString, required = true,
                                 default = nil)
  if valid_613443 != nil:
    section.add "flowArn", valid_613443
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
  var valid_613444 = header.getOrDefault("X-Amz-Signature")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Signature", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Content-Sha256", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Date")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Date", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Credential")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Credential", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Security-Token")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Security-Token", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Algorithm")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Algorithm", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-SignedHeaders", valid_613450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613451: Call_RevokeFlowEntitlement_613439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ## 
  let valid = call_613451.validator(path, query, header, formData, body)
  let scheme = call_613451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613451.url(scheme.get, call_613451.host, call_613451.base,
                         call_613451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613451, url, valid)

proc call*(call_613452: Call_RevokeFlowEntitlement_613439; entitlementArn: string;
          flowArn: string): Recallable =
  ## revokeFlowEntitlement
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to revoke.
  ##   flowArn: string (required)
  ##          : The flow that you want to revoke an entitlement from.
  var path_613453 = newJObject()
  add(path_613453, "entitlementArn", newJString(entitlementArn))
  add(path_613453, "flowArn", newJString(flowArn))
  result = call_613452.call(path_613453, nil, nil, nil, nil)

var revokeFlowEntitlement* = Call_RevokeFlowEntitlement_613439(
    name: "revokeFlowEntitlement", meth: HttpMethod.HttpDelete,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_RevokeFlowEntitlement_613440, base: "/",
    url: url_RevokeFlowEntitlement_613441, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFlow_613454 = ref object of OpenApiRestCall_612658
proc url_StartFlow_613456(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StartFlow_613455(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613457 = path.getOrDefault("flowArn")
  valid_613457 = validateParameter(valid_613457, JString, required = true,
                                 default = nil)
  if valid_613457 != nil:
    section.add "flowArn", valid_613457
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
  var valid_613458 = header.getOrDefault("X-Amz-Signature")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Signature", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Content-Sha256", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Date")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Date", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Credential")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Credential", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Security-Token")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Security-Token", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Algorithm")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Algorithm", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-SignedHeaders", valid_613464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613465: Call_StartFlow_613454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a flow.
  ## 
  let valid = call_613465.validator(path, query, header, formData, body)
  let scheme = call_613465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613465.url(scheme.get, call_613465.host, call_613465.base,
                         call_613465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613465, url, valid)

proc call*(call_613466: Call_StartFlow_613454; flowArn: string): Recallable =
  ## startFlow
  ## Starts a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to start.
  var path_613467 = newJObject()
  add(path_613467, "flowArn", newJString(flowArn))
  result = call_613466.call(path_613467, nil, nil, nil, nil)

var startFlow* = Call_StartFlow_613454(name: "startFlow", meth: HttpMethod.HttpPost,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows/start/{flowArn}",
                                    validator: validate_StartFlow_613455,
                                    base: "/", url: url_StartFlow_613456,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFlow_613468 = ref object of OpenApiRestCall_612658
proc url_StopFlow_613470(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopFlow_613469(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613471 = path.getOrDefault("flowArn")
  valid_613471 = validateParameter(valid_613471, JString, required = true,
                                 default = nil)
  if valid_613471 != nil:
    section.add "flowArn", valid_613471
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
  var valid_613472 = header.getOrDefault("X-Amz-Signature")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Signature", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Content-Sha256", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Date")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Date", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Credential")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Credential", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Security-Token")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Security-Token", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Algorithm")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Algorithm", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-SignedHeaders", valid_613478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613479: Call_StopFlow_613468; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a flow.
  ## 
  let valid = call_613479.validator(path, query, header, formData, body)
  let scheme = call_613479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613479.url(scheme.get, call_613479.host, call_613479.base,
                         call_613479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613479, url, valid)

proc call*(call_613480: Call_StopFlow_613468; flowArn: string): Recallable =
  ## stopFlow
  ## Stops a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to stop.
  var path_613481 = newJObject()
  add(path_613481, "flowArn", newJString(flowArn))
  result = call_613480.call(path_613481, nil, nil, nil, nil)

var stopFlow* = Call_StopFlow_613468(name: "stopFlow", meth: HttpMethod.HttpPost,
                                  host: "mediaconnect.amazonaws.com",
                                  route: "/v1/flows/stop/{flowArn}",
                                  validator: validate_StopFlow_613469, base: "/",
                                  url: url_StopFlow_613470,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613482 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613484(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_613483(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613485 = path.getOrDefault("resourceArn")
  valid_613485 = validateParameter(valid_613485, JString, required = true,
                                 default = nil)
  if valid_613485 != nil:
    section.add "resourceArn", valid_613485
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613486 = query.getOrDefault("tagKeys")
  valid_613486 = validateParameter(valid_613486, JArray, required = true, default = nil)
  if valid_613486 != nil:
    section.add "tagKeys", valid_613486
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
  var valid_613487 = header.getOrDefault("X-Amz-Signature")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Signature", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Content-Sha256", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Date")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Date", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Credential")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Credential", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Security-Token")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Security-Token", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Algorithm")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Algorithm", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-SignedHeaders", valid_613493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613494: Call_UntagResource_613482; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_613494.validator(path, query, header, formData, body)
  let scheme = call_613494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613494.url(scheme.get, call_613494.host, call_613494.base,
                         call_613494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613494, url, valid)

proc call*(call_613495: Call_UntagResource_613482; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource from which to delete tags.
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  var path_613496 = newJObject()
  var query_613497 = newJObject()
  add(path_613496, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_613497.add "tagKeys", tagKeys
  result = call_613495.call(path_613496, query_613497, nil, nil, nil)

var untagResource* = Call_UntagResource_613482(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_613483,
    base: "/", url: url_UntagResource_613484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowSource_613498 = ref object of OpenApiRestCall_612658
proc url_UpdateFlowSource_613500(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFlowSource_613499(path: JsonNode; query: JsonNode;
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
  var valid_613501 = path.getOrDefault("sourceArn")
  valid_613501 = validateParameter(valid_613501, JString, required = true,
                                 default = nil)
  if valid_613501 != nil:
    section.add "sourceArn", valid_613501
  var valid_613502 = path.getOrDefault("flowArn")
  valid_613502 = validateParameter(valid_613502, JString, required = true,
                                 default = nil)
  if valid_613502 != nil:
    section.add "flowArn", valid_613502
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
  var valid_613503 = header.getOrDefault("X-Amz-Signature")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Signature", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Content-Sha256", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Date")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Date", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Credential")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Credential", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Security-Token")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Security-Token", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-Algorithm")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Algorithm", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-SignedHeaders", valid_613509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613511: Call_UpdateFlowSource_613498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the source of a flow.
  ## 
  let valid = call_613511.validator(path, query, header, formData, body)
  let scheme = call_613511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613511.url(scheme.get, call_613511.host, call_613511.base,
                         call_613511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613511, url, valid)

proc call*(call_613512: Call_UpdateFlowSource_613498; sourceArn: string;
          body: JsonNode; flowArn: string): Recallable =
  ## updateFlowSource
  ## Updates the source of a flow.
  ##   sourceArn: string (required)
  ##            : The ARN of the source that you want to update.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that is associated with the source that you want to update.
  var path_613513 = newJObject()
  var body_613514 = newJObject()
  add(path_613513, "sourceArn", newJString(sourceArn))
  if body != nil:
    body_613514 = body
  add(path_613513, "flowArn", newJString(flowArn))
  result = call_613512.call(path_613513, nil, nil, nil, body_613514)

var updateFlowSource* = Call_UpdateFlowSource_613498(name: "updateFlowSource",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/source/{sourceArn}",
    validator: validate_UpdateFlowSource_613499, base: "/",
    url: url_UpdateFlowSource_613500, schemes: {Scheme.Https, Scheme.Http})
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
