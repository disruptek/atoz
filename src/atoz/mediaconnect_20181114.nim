
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddFlowOutputs_593774 = ref object of OpenApiRestCall_593437
proc url_AddFlowOutputs_593776(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_AddFlowOutputs_593775(path: JsonNode; query: JsonNode;
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
  var valid_593902 = path.getOrDefault("flowArn")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = nil)
  if valid_593902 != nil:
    section.add "flowArn", valid_593902
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
  var valid_593903 = header.getOrDefault("X-Amz-Date")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "X-Amz-Date", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Security-Token")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Security-Token", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Content-Sha256", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Algorithm")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Algorithm", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Signature")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Signature", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-SignedHeaders", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Credential")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Credential", valid_593909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593933: Call_AddFlowOutputs_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ## 
  let valid = call_593933.validator(path, query, header, formData, body)
  let scheme = call_593933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593933.url(scheme.get, call_593933.host, call_593933.base,
                         call_593933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593933, url, valid)

proc call*(call_594004: Call_AddFlowOutputs_593774; flowArn: string; body: JsonNode): Recallable =
  ## addFlowOutputs
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ##   flowArn: string (required)
  ##          : The flow that you want to add outputs to.
  ##   body: JObject (required)
  var path_594005 = newJObject()
  var body_594007 = newJObject()
  add(path_594005, "flowArn", newJString(flowArn))
  if body != nil:
    body_594007 = body
  result = call_594004.call(path_594005, nil, nil, nil, body_594007)

var addFlowOutputs* = Call_AddFlowOutputs_593774(name: "addFlowOutputs",
    meth: HttpMethod.HttpPost, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs", validator: validate_AddFlowOutputs_593775,
    base: "/", url: url_AddFlowOutputs_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlow_594063 = ref object of OpenApiRestCall_593437
proc url_CreateFlow_594065(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFlow_594064(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594066 = header.getOrDefault("X-Amz-Date")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Date", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Security-Token")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Security-Token", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Content-Sha256", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Algorithm")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Algorithm", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Signature")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Signature", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-SignedHeaders", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Credential")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Credential", valid_594072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594074: Call_CreateFlow_594063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ## 
  let valid = call_594074.validator(path, query, header, formData, body)
  let scheme = call_594074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594074.url(scheme.get, call_594074.host, call_594074.base,
                         call_594074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594074, url, valid)

proc call*(call_594075: Call_CreateFlow_594063; body: JsonNode): Recallable =
  ## createFlow
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ##   body: JObject (required)
  var body_594076 = newJObject()
  if body != nil:
    body_594076 = body
  result = call_594075.call(nil, nil, nil, nil, body_594076)

var createFlow* = Call_CreateFlow_594063(name: "createFlow",
                                      meth: HttpMethod.HttpPost,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows",
                                      validator: validate_CreateFlow_594064,
                                      base: "/", url: url_CreateFlow_594065,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlows_594046 = ref object of OpenApiRestCall_593437
proc url_ListFlows_594048(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFlows_594047(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_594049 = query.getOrDefault("NextToken")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "NextToken", valid_594049
  var valid_594050 = query.getOrDefault("maxResults")
  valid_594050 = validateParameter(valid_594050, JInt, required = false, default = nil)
  if valid_594050 != nil:
    section.add "maxResults", valid_594050
  var valid_594051 = query.getOrDefault("nextToken")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "nextToken", valid_594051
  var valid_594052 = query.getOrDefault("MaxResults")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "MaxResults", valid_594052
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
  var valid_594053 = header.getOrDefault("X-Amz-Date")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Date", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Security-Token")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Security-Token", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Content-Sha256", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Algorithm")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Algorithm", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Signature")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Signature", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-SignedHeaders", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Credential")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Credential", valid_594059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594060: Call_ListFlows_594046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
  ## 
  let valid = call_594060.validator(path, query, header, formData, body)
  let scheme = call_594060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594060.url(scheme.get, call_594060.host, call_594060.base,
                         call_594060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594060, url, valid)

proc call*(call_594061: Call_ListFlows_594046; NextToken: string = "";
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
  var query_594062 = newJObject()
  add(query_594062, "NextToken", newJString(NextToken))
  add(query_594062, "maxResults", newJInt(maxResults))
  add(query_594062, "nextToken", newJString(nextToken))
  add(query_594062, "MaxResults", newJString(MaxResults))
  result = call_594061.call(nil, query_594062, nil, nil, nil)

var listFlows* = Call_ListFlows_594046(name: "listFlows", meth: HttpMethod.HttpGet,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows",
                                    validator: validate_ListFlows_594047,
                                    base: "/", url: url_ListFlows_594048,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlow_594077 = ref object of OpenApiRestCall_593437
proc url_DescribeFlow_594079(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeFlow_594078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594080 = path.getOrDefault("flowArn")
  valid_594080 = validateParameter(valid_594080, JString, required = true,
                                 default = nil)
  if valid_594080 != nil:
    section.add "flowArn", valid_594080
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
  var valid_594081 = header.getOrDefault("X-Amz-Date")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Date", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Security-Token")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Security-Token", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Content-Sha256", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Algorithm")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Algorithm", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Signature")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Signature", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-SignedHeaders", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Credential")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Credential", valid_594087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594088: Call_DescribeFlow_594077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ## 
  let valid = call_594088.validator(path, query, header, formData, body)
  let scheme = call_594088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594088.url(scheme.get, call_594088.host, call_594088.base,
                         call_594088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594088, url, valid)

proc call*(call_594089: Call_DescribeFlow_594077; flowArn: string): Recallable =
  ## describeFlow
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to describe.
  var path_594090 = newJObject()
  add(path_594090, "flowArn", newJString(flowArn))
  result = call_594089.call(path_594090, nil, nil, nil, nil)

var describeFlow* = Call_DescribeFlow_594077(name: "describeFlow",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}", validator: validate_DescribeFlow_594078,
    base: "/", url: url_DescribeFlow_594079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlow_594091 = ref object of OpenApiRestCall_593437
proc url_DeleteFlow_594093(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_DeleteFlow_594092(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594094 = path.getOrDefault("flowArn")
  valid_594094 = validateParameter(valid_594094, JString, required = true,
                                 default = nil)
  if valid_594094 != nil:
    section.add "flowArn", valid_594094
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
  var valid_594095 = header.getOrDefault("X-Amz-Date")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Date", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Security-Token")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Security-Token", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Content-Sha256", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Algorithm")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Algorithm", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Signature")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Signature", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-SignedHeaders", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Credential")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Credential", valid_594101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594102: Call_DeleteFlow_594091; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ## 
  let valid = call_594102.validator(path, query, header, formData, body)
  let scheme = call_594102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594102.url(scheme.get, call_594102.host, call_594102.base,
                         call_594102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594102, url, valid)

proc call*(call_594103: Call_DeleteFlow_594091; flowArn: string): Recallable =
  ## deleteFlow
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to delete.
  var path_594104 = newJObject()
  add(path_594104, "flowArn", newJString(flowArn))
  result = call_594103.call(path_594104, nil, nil, nil, nil)

var deleteFlow* = Call_DeleteFlow_594091(name: "deleteFlow",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows/{flowArn}",
                                      validator: validate_DeleteFlow_594092,
                                      base: "/", url: url_DeleteFlow_594093,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GrantFlowEntitlements_594105 = ref object of OpenApiRestCall_593437
proc url_GrantFlowEntitlements_594107(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GrantFlowEntitlements_594106(path: JsonNode; query: JsonNode;
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
  var valid_594108 = path.getOrDefault("flowArn")
  valid_594108 = validateParameter(valid_594108, JString, required = true,
                                 default = nil)
  if valid_594108 != nil:
    section.add "flowArn", valid_594108
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
  var valid_594109 = header.getOrDefault("X-Amz-Date")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Date", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Security-Token")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Security-Token", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Content-Sha256", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Algorithm")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Algorithm", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Signature")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Signature", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-SignedHeaders", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Credential")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Credential", valid_594115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594117: Call_GrantFlowEntitlements_594105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants entitlements to an existing flow.
  ## 
  let valid = call_594117.validator(path, query, header, formData, body)
  let scheme = call_594117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594117.url(scheme.get, call_594117.host, call_594117.base,
                         call_594117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594117, url, valid)

proc call*(call_594118: Call_GrantFlowEntitlements_594105; flowArn: string;
          body: JsonNode): Recallable =
  ## grantFlowEntitlements
  ## Grants entitlements to an existing flow.
  ##   flowArn: string (required)
  ##          : The flow that you want to grant entitlements on.
  ##   body: JObject (required)
  var path_594119 = newJObject()
  var body_594120 = newJObject()
  add(path_594119, "flowArn", newJString(flowArn))
  if body != nil:
    body_594120 = body
  result = call_594118.call(path_594119, nil, nil, nil, body_594120)

var grantFlowEntitlements* = Call_GrantFlowEntitlements_594105(
    name: "grantFlowEntitlements", meth: HttpMethod.HttpPost,
    host: "mediaconnect.amazonaws.com", route: "/v1/flows/{flowArn}/entitlements",
    validator: validate_GrantFlowEntitlements_594106, base: "/",
    url: url_GrantFlowEntitlements_594107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitlements_594121 = ref object of OpenApiRestCall_593437
proc url_ListEntitlements_594123(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEntitlements_594122(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_594124 = query.getOrDefault("NextToken")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "NextToken", valid_594124
  var valid_594125 = query.getOrDefault("maxResults")
  valid_594125 = validateParameter(valid_594125, JInt, required = false, default = nil)
  if valid_594125 != nil:
    section.add "maxResults", valid_594125
  var valid_594126 = query.getOrDefault("nextToken")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "nextToken", valid_594126
  var valid_594127 = query.getOrDefault("MaxResults")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "MaxResults", valid_594127
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
  var valid_594128 = header.getOrDefault("X-Amz-Date")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Date", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Security-Token")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Security-Token", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Content-Sha256", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Algorithm")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Algorithm", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Signature")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Signature", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-SignedHeaders", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Credential")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Credential", valid_594134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594135: Call_ListEntitlements_594121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
  ## 
  let valid = call_594135.validator(path, query, header, formData, body)
  let scheme = call_594135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594135.url(scheme.get, call_594135.host, call_594135.base,
                         call_594135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594135, url, valid)

proc call*(call_594136: Call_ListEntitlements_594121; NextToken: string = "";
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
  var query_594137 = newJObject()
  add(query_594137, "NextToken", newJString(NextToken))
  add(query_594137, "maxResults", newJInt(maxResults))
  add(query_594137, "nextToken", newJString(nextToken))
  add(query_594137, "MaxResults", newJString(MaxResults))
  result = call_594136.call(nil, query_594137, nil, nil, nil)

var listEntitlements* = Call_ListEntitlements_594121(name: "listEntitlements",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/entitlements", validator: validate_ListEntitlements_594122,
    base: "/", url: url_ListEntitlements_594123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594152 = ref object of OpenApiRestCall_593437
proc url_TagResource_594154(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TagResource_594153(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594155 = path.getOrDefault("resourceArn")
  valid_594155 = validateParameter(valid_594155, JString, required = true,
                                 default = nil)
  if valid_594155 != nil:
    section.add "resourceArn", valid_594155
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
  var valid_594156 = header.getOrDefault("X-Amz-Date")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Date", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Security-Token")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Security-Token", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Content-Sha256", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Algorithm")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Algorithm", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Signature")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Signature", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-SignedHeaders", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Credential")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Credential", valid_594162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594164: Call_TagResource_594152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_594164.validator(path, query, header, formData, body)
  let scheme = call_594164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594164.url(scheme.get, call_594164.host, call_594164.base,
                         call_594164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594164, url, valid)

proc call*(call_594165: Call_TagResource_594152; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource to which to add tags.
  var path_594166 = newJObject()
  var body_594167 = newJObject()
  if body != nil:
    body_594167 = body
  add(path_594166, "resourceArn", newJString(resourceArn))
  result = call_594165.call(path_594166, nil, nil, nil, body_594167)

var tagResource* = Call_TagResource_594152(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconnect.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_594153,
                                        base: "/", url: url_TagResource_594154,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594138 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_594140(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_594139(path: JsonNode; query: JsonNode;
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
  var valid_594141 = path.getOrDefault("resourceArn")
  valid_594141 = validateParameter(valid_594141, JString, required = true,
                                 default = nil)
  if valid_594141 != nil:
    section.add "resourceArn", valid_594141
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
  var valid_594142 = header.getOrDefault("X-Amz-Date")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Date", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Security-Token")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Security-Token", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Content-Sha256", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Algorithm")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Algorithm", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Signature")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Signature", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-SignedHeaders", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Credential")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Credential", valid_594148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594149: Call_ListTagsForResource_594138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags on an AWS Elemental MediaConnect resource
  ## 
  let valid = call_594149.validator(path, query, header, formData, body)
  let scheme = call_594149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594149.url(scheme.get, call_594149.host, call_594149.base,
                         call_594149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594149, url, valid)

proc call*(call_594150: Call_ListTagsForResource_594138; resourceArn: string): Recallable =
  ## listTagsForResource
  ## List all tags on an AWS Elemental MediaConnect resource
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource for which to list the tags.
  var path_594151 = newJObject()
  add(path_594151, "resourceArn", newJString(resourceArn))
  result = call_594150.call(path_594151, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594138(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconnect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_594139, base: "/",
    url: url_ListTagsForResource_594140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowOutput_594168 = ref object of OpenApiRestCall_593437
proc url_UpdateFlowOutput_594170(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateFlowOutput_594169(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_594171 = path.getOrDefault("flowArn")
  valid_594171 = validateParameter(valid_594171, JString, required = true,
                                 default = nil)
  if valid_594171 != nil:
    section.add "flowArn", valid_594171
  var valid_594172 = path.getOrDefault("outputArn")
  valid_594172 = validateParameter(valid_594172, JString, required = true,
                                 default = nil)
  if valid_594172 != nil:
    section.add "outputArn", valid_594172
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
  var valid_594173 = header.getOrDefault("X-Amz-Date")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Date", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Security-Token")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Security-Token", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-Content-Sha256", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-Algorithm")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Algorithm", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Signature")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Signature", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-SignedHeaders", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Credential")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Credential", valid_594179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594181: Call_UpdateFlowOutput_594168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing flow output.
  ## 
  let valid = call_594181.validator(path, query, header, formData, body)
  let scheme = call_594181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594181.url(scheme.get, call_594181.host, call_594181.base,
                         call_594181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594181, url, valid)

proc call*(call_594182: Call_UpdateFlowOutput_594168; flowArn: string;
          outputArn: string; body: JsonNode): Recallable =
  ## updateFlowOutput
  ## Updates an existing flow output.
  ##   flowArn: string (required)
  ##          : The flow that is associated with the output that you want to update.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to update.
  ##   body: JObject (required)
  var path_594183 = newJObject()
  var body_594184 = newJObject()
  add(path_594183, "flowArn", newJString(flowArn))
  add(path_594183, "outputArn", newJString(outputArn))
  if body != nil:
    body_594184 = body
  result = call_594182.call(path_594183, nil, nil, nil, body_594184)

var updateFlowOutput* = Call_UpdateFlowOutput_594168(name: "updateFlowOutput",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_UpdateFlowOutput_594169, base: "/",
    url: url_UpdateFlowOutput_594170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFlowOutput_594185 = ref object of OpenApiRestCall_593437
proc url_RemoveFlowOutput_594187(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_RemoveFlowOutput_594186(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_594188 = path.getOrDefault("flowArn")
  valid_594188 = validateParameter(valid_594188, JString, required = true,
                                 default = nil)
  if valid_594188 != nil:
    section.add "flowArn", valid_594188
  var valid_594189 = path.getOrDefault("outputArn")
  valid_594189 = validateParameter(valid_594189, JString, required = true,
                                 default = nil)
  if valid_594189 != nil:
    section.add "outputArn", valid_594189
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
  var valid_594190 = header.getOrDefault("X-Amz-Date")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-Date", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Security-Token")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Security-Token", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Content-Sha256", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Algorithm")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Algorithm", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Signature")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Signature", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-SignedHeaders", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Credential")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Credential", valid_594196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594197: Call_RemoveFlowOutput_594185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ## 
  let valid = call_594197.validator(path, query, header, formData, body)
  let scheme = call_594197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594197.url(scheme.get, call_594197.host, call_594197.base,
                         call_594197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594197, url, valid)

proc call*(call_594198: Call_RemoveFlowOutput_594185; flowArn: string;
          outputArn: string): Recallable =
  ## removeFlowOutput
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ##   flowArn: string (required)
  ##          : The flow that you want to remove an output from.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to remove.
  var path_594199 = newJObject()
  add(path_594199, "flowArn", newJString(flowArn))
  add(path_594199, "outputArn", newJString(outputArn))
  result = call_594198.call(path_594199, nil, nil, nil, nil)

var removeFlowOutput* = Call_RemoveFlowOutput_594185(name: "removeFlowOutput",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_RemoveFlowOutput_594186, base: "/",
    url: url_RemoveFlowOutput_594187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowEntitlement_594200 = ref object of OpenApiRestCall_593437
proc url_UpdateFlowEntitlement_594202(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateFlowEntitlement_594201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_594203 = path.getOrDefault("flowArn")
  valid_594203 = validateParameter(valid_594203, JString, required = true,
                                 default = nil)
  if valid_594203 != nil:
    section.add "flowArn", valid_594203
  var valid_594204 = path.getOrDefault("entitlementArn")
  valid_594204 = validateParameter(valid_594204, JString, required = true,
                                 default = nil)
  if valid_594204 != nil:
    section.add "entitlementArn", valid_594204
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
  var valid_594205 = header.getOrDefault("X-Amz-Date")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Date", valid_594205
  var valid_594206 = header.getOrDefault("X-Amz-Security-Token")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Security-Token", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Content-Sha256", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Algorithm")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Algorithm", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Signature")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Signature", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-SignedHeaders", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Credential")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Credential", valid_594211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594213: Call_UpdateFlowEntitlement_594200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ## 
  let valid = call_594213.validator(path, query, header, formData, body)
  let scheme = call_594213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594213.url(scheme.get, call_594213.host, call_594213.base,
                         call_594213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594213, url, valid)

proc call*(call_594214: Call_UpdateFlowEntitlement_594200; flowArn: string;
          body: JsonNode; entitlementArn: string): Recallable =
  ## updateFlowEntitlement
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ##   flowArn: string (required)
  ##          : The flow that is associated with the entitlement that you want to update.
  ##   body: JObject (required)
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to update.
  var path_594215 = newJObject()
  var body_594216 = newJObject()
  add(path_594215, "flowArn", newJString(flowArn))
  if body != nil:
    body_594216 = body
  add(path_594215, "entitlementArn", newJString(entitlementArn))
  result = call_594214.call(path_594215, nil, nil, nil, body_594216)

var updateFlowEntitlement* = Call_UpdateFlowEntitlement_594200(
    name: "updateFlowEntitlement", meth: HttpMethod.HttpPut,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_UpdateFlowEntitlement_594201, base: "/",
    url: url_UpdateFlowEntitlement_594202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeFlowEntitlement_594217 = ref object of OpenApiRestCall_593437
proc url_RevokeFlowEntitlement_594219(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_RevokeFlowEntitlement_594218(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_594220 = path.getOrDefault("flowArn")
  valid_594220 = validateParameter(valid_594220, JString, required = true,
                                 default = nil)
  if valid_594220 != nil:
    section.add "flowArn", valid_594220
  var valid_594221 = path.getOrDefault("entitlementArn")
  valid_594221 = validateParameter(valid_594221, JString, required = true,
                                 default = nil)
  if valid_594221 != nil:
    section.add "entitlementArn", valid_594221
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
  var valid_594222 = header.getOrDefault("X-Amz-Date")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-Date", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Security-Token")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Security-Token", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Content-Sha256", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Algorithm")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Algorithm", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Signature")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Signature", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-SignedHeaders", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Credential")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Credential", valid_594228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594229: Call_RevokeFlowEntitlement_594217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ## 
  let valid = call_594229.validator(path, query, header, formData, body)
  let scheme = call_594229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594229.url(scheme.get, call_594229.host, call_594229.base,
                         call_594229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594229, url, valid)

proc call*(call_594230: Call_RevokeFlowEntitlement_594217; flowArn: string;
          entitlementArn: string): Recallable =
  ## revokeFlowEntitlement
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ##   flowArn: string (required)
  ##          : The flow that you want to revoke an entitlement from.
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to revoke.
  var path_594231 = newJObject()
  add(path_594231, "flowArn", newJString(flowArn))
  add(path_594231, "entitlementArn", newJString(entitlementArn))
  result = call_594230.call(path_594231, nil, nil, nil, nil)

var revokeFlowEntitlement* = Call_RevokeFlowEntitlement_594217(
    name: "revokeFlowEntitlement", meth: HttpMethod.HttpDelete,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_RevokeFlowEntitlement_594218, base: "/",
    url: url_RevokeFlowEntitlement_594219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFlow_594232 = ref object of OpenApiRestCall_593437
proc url_StartFlow_594234(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_StartFlow_594233(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594235 = path.getOrDefault("flowArn")
  valid_594235 = validateParameter(valid_594235, JString, required = true,
                                 default = nil)
  if valid_594235 != nil:
    section.add "flowArn", valid_594235
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
  var valid_594236 = header.getOrDefault("X-Amz-Date")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Date", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Security-Token")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Security-Token", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Content-Sha256", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Algorithm")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Algorithm", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Signature")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Signature", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-SignedHeaders", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Credential")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Credential", valid_594242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594243: Call_StartFlow_594232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a flow.
  ## 
  let valid = call_594243.validator(path, query, header, formData, body)
  let scheme = call_594243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594243.url(scheme.get, call_594243.host, call_594243.base,
                         call_594243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594243, url, valid)

proc call*(call_594244: Call_StartFlow_594232; flowArn: string): Recallable =
  ## startFlow
  ## Starts a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to start.
  var path_594245 = newJObject()
  add(path_594245, "flowArn", newJString(flowArn))
  result = call_594244.call(path_594245, nil, nil, nil, nil)

var startFlow* = Call_StartFlow_594232(name: "startFlow", meth: HttpMethod.HttpPost,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows/start/{flowArn}",
                                    validator: validate_StartFlow_594233,
                                    base: "/", url: url_StartFlow_594234,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFlow_594246 = ref object of OpenApiRestCall_593437
proc url_StopFlow_594248(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_StopFlow_594247(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594249 = path.getOrDefault("flowArn")
  valid_594249 = validateParameter(valid_594249, JString, required = true,
                                 default = nil)
  if valid_594249 != nil:
    section.add "flowArn", valid_594249
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
  var valid_594250 = header.getOrDefault("X-Amz-Date")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Date", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Security-Token")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Security-Token", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Content-Sha256", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Algorithm")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Algorithm", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Signature")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Signature", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-SignedHeaders", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Credential")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Credential", valid_594256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594257: Call_StopFlow_594246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a flow.
  ## 
  let valid = call_594257.validator(path, query, header, formData, body)
  let scheme = call_594257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594257.url(scheme.get, call_594257.host, call_594257.base,
                         call_594257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594257, url, valid)

proc call*(call_594258: Call_StopFlow_594246; flowArn: string): Recallable =
  ## stopFlow
  ## Stops a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to stop.
  var path_594259 = newJObject()
  add(path_594259, "flowArn", newJString(flowArn))
  result = call_594258.call(path_594259, nil, nil, nil, nil)

var stopFlow* = Call_StopFlow_594246(name: "stopFlow", meth: HttpMethod.HttpPost,
                                  host: "mediaconnect.amazonaws.com",
                                  route: "/v1/flows/stop/{flowArn}",
                                  validator: validate_StopFlow_594247, base: "/",
                                  url: url_StopFlow_594248,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594260 = ref object of OpenApiRestCall_593437
proc url_UntagResource_594262(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_594261(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594263 = path.getOrDefault("resourceArn")
  valid_594263 = validateParameter(valid_594263, JString, required = true,
                                 default = nil)
  if valid_594263 != nil:
    section.add "resourceArn", valid_594263
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_594264 = query.getOrDefault("tagKeys")
  valid_594264 = validateParameter(valid_594264, JArray, required = true, default = nil)
  if valid_594264 != nil:
    section.add "tagKeys", valid_594264
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
  var valid_594265 = header.getOrDefault("X-Amz-Date")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Date", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Security-Token")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Security-Token", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Content-Sha256", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-Algorithm")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Algorithm", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Signature")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Signature", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-SignedHeaders", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Credential")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Credential", valid_594271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594272: Call_UntagResource_594260; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_594272.validator(path, query, header, formData, body)
  let scheme = call_594272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594272.url(scheme.get, call_594272.host, call_594272.base,
                         call_594272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594272, url, valid)

proc call*(call_594273: Call_UntagResource_594260; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource from which to delete tags.
  var path_594274 = newJObject()
  var query_594275 = newJObject()
  if tagKeys != nil:
    query_594275.add "tagKeys", tagKeys
  add(path_594274, "resourceArn", newJString(resourceArn))
  result = call_594273.call(path_594274, query_594275, nil, nil, nil)

var untagResource* = Call_UntagResource_594260(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_594261,
    base: "/", url: url_UntagResource_594262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowSource_594276 = ref object of OpenApiRestCall_593437
proc url_UpdateFlowSource_594278(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateFlowSource_594277(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_594279 = path.getOrDefault("flowArn")
  valid_594279 = validateParameter(valid_594279, JString, required = true,
                                 default = nil)
  if valid_594279 != nil:
    section.add "flowArn", valid_594279
  var valid_594280 = path.getOrDefault("sourceArn")
  valid_594280 = validateParameter(valid_594280, JString, required = true,
                                 default = nil)
  if valid_594280 != nil:
    section.add "sourceArn", valid_594280
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
  var valid_594281 = header.getOrDefault("X-Amz-Date")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Date", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-Security-Token")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-Security-Token", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Content-Sha256", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-Algorithm")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-Algorithm", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-Signature")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Signature", valid_594285
  var valid_594286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-SignedHeaders", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Credential")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Credential", valid_594287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594289: Call_UpdateFlowSource_594276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the source of a flow.
  ## 
  let valid = call_594289.validator(path, query, header, formData, body)
  let scheme = call_594289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594289.url(scheme.get, call_594289.host, call_594289.base,
                         call_594289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594289, url, valid)

proc call*(call_594290: Call_UpdateFlowSource_594276; flowArn: string;
          body: JsonNode; sourceArn: string): Recallable =
  ## updateFlowSource
  ## Updates the source of a flow.
  ##   flowArn: string (required)
  ##          : The flow that is associated with the source that you want to update.
  ##   body: JObject (required)
  ##   sourceArn: string (required)
  ##            : The ARN of the source that you want to update.
  var path_594291 = newJObject()
  var body_594292 = newJObject()
  add(path_594291, "flowArn", newJString(flowArn))
  if body != nil:
    body_594292 = body
  add(path_594291, "sourceArn", newJString(sourceArn))
  result = call_594290.call(path_594291, nil, nil, nil, body_594292)

var updateFlowSource* = Call_UpdateFlowSource_594276(name: "updateFlowSource",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/source/{sourceArn}",
    validator: validate_UpdateFlowSource_594277, base: "/",
    url: url_UpdateFlowSource_594278, schemes: {Scheme.Https, Scheme.Http})
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
