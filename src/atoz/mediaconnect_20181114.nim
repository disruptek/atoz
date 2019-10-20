
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddFlowOutputs_592703 = ref object of OpenApiRestCall_592364
proc url_AddFlowOutputs_592705(protocol: Scheme; host: string; base: string;
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

proc validate_AddFlowOutputs_592704(path: JsonNode; query: JsonNode;
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
  var valid_592831 = path.getOrDefault("flowArn")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = nil)
  if valid_592831 != nil:
    section.add "flowArn", valid_592831
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
  var valid_592832 = header.getOrDefault("X-Amz-Signature")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Signature", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Content-Sha256", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Date")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Date", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Credential")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Credential", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Security-Token")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Security-Token", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Algorithm")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Algorithm", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-SignedHeaders", valid_592838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592862: Call_AddFlowOutputs_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ## 
  let valid = call_592862.validator(path, query, header, formData, body)
  let scheme = call_592862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592862.url(scheme.get, call_592862.host, call_592862.base,
                         call_592862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592862, url, valid)

proc call*(call_592933: Call_AddFlowOutputs_592703; body: JsonNode; flowArn: string): Recallable =
  ## addFlowOutputs
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that you want to add outputs to.
  var path_592934 = newJObject()
  var body_592936 = newJObject()
  if body != nil:
    body_592936 = body
  add(path_592934, "flowArn", newJString(flowArn))
  result = call_592933.call(path_592934, nil, nil, nil, body_592936)

var addFlowOutputs* = Call_AddFlowOutputs_592703(name: "addFlowOutputs",
    meth: HttpMethod.HttpPost, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs", validator: validate_AddFlowOutputs_592704,
    base: "/", url: url_AddFlowOutputs_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlow_592992 = ref object of OpenApiRestCall_592364
proc url_CreateFlow_592994(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFlow_592993(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592995 = header.getOrDefault("X-Amz-Signature")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Signature", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Content-Sha256", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Date")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Date", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Credential")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Credential", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Security-Token")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Security-Token", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Algorithm")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Algorithm", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-SignedHeaders", valid_593001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593003: Call_CreateFlow_592992; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ## 
  let valid = call_593003.validator(path, query, header, formData, body)
  let scheme = call_593003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593003.url(scheme.get, call_593003.host, call_593003.base,
                         call_593003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593003, url, valid)

proc call*(call_593004: Call_CreateFlow_592992; body: JsonNode): Recallable =
  ## createFlow
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ##   body: JObject (required)
  var body_593005 = newJObject()
  if body != nil:
    body_593005 = body
  result = call_593004.call(nil, nil, nil, nil, body_593005)

var createFlow* = Call_CreateFlow_592992(name: "createFlow",
                                      meth: HttpMethod.HttpPost,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows",
                                      validator: validate_CreateFlow_592993,
                                      base: "/", url: url_CreateFlow_592994,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlows_592975 = ref object of OpenApiRestCall_592364
proc url_ListFlows_592977(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFlows_592976(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592978 = query.getOrDefault("nextToken")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "nextToken", valid_592978
  var valid_592979 = query.getOrDefault("MaxResults")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "MaxResults", valid_592979
  var valid_592980 = query.getOrDefault("NextToken")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "NextToken", valid_592980
  var valid_592981 = query.getOrDefault("maxResults")
  valid_592981 = validateParameter(valid_592981, JInt, required = false, default = nil)
  if valid_592981 != nil:
    section.add "maxResults", valid_592981
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
  var valid_592982 = header.getOrDefault("X-Amz-Signature")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Signature", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Content-Sha256", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Date")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Date", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Credential")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Credential", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Security-Token")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Security-Token", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Algorithm")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Algorithm", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-SignedHeaders", valid_592988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592989: Call_ListFlows_592975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
  ## 
  let valid = call_592989.validator(path, query, header, formData, body)
  let scheme = call_592989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592989.url(scheme.get, call_592989.host, call_592989.base,
                         call_592989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592989, url, valid)

proc call*(call_592990: Call_ListFlows_592975; nextToken: string = "";
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
  var query_592991 = newJObject()
  add(query_592991, "nextToken", newJString(nextToken))
  add(query_592991, "MaxResults", newJString(MaxResults))
  add(query_592991, "NextToken", newJString(NextToken))
  add(query_592991, "maxResults", newJInt(maxResults))
  result = call_592990.call(nil, query_592991, nil, nil, nil)

var listFlows* = Call_ListFlows_592975(name: "listFlows", meth: HttpMethod.HttpGet,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows",
                                    validator: validate_ListFlows_592976,
                                    base: "/", url: url_ListFlows_592977,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlow_593006 = ref object of OpenApiRestCall_592364
proc url_DescribeFlow_593008(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFlow_593007(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593009 = path.getOrDefault("flowArn")
  valid_593009 = validateParameter(valid_593009, JString, required = true,
                                 default = nil)
  if valid_593009 != nil:
    section.add "flowArn", valid_593009
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
  var valid_593010 = header.getOrDefault("X-Amz-Signature")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Signature", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Content-Sha256", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Date")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Date", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Credential")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Credential", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Security-Token")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Security-Token", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Algorithm")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Algorithm", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-SignedHeaders", valid_593016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593017: Call_DescribeFlow_593006; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ## 
  let valid = call_593017.validator(path, query, header, formData, body)
  let scheme = call_593017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593017.url(scheme.get, call_593017.host, call_593017.base,
                         call_593017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593017, url, valid)

proc call*(call_593018: Call_DescribeFlow_593006; flowArn: string): Recallable =
  ## describeFlow
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to describe.
  var path_593019 = newJObject()
  add(path_593019, "flowArn", newJString(flowArn))
  result = call_593018.call(path_593019, nil, nil, nil, nil)

var describeFlow* = Call_DescribeFlow_593006(name: "describeFlow",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}", validator: validate_DescribeFlow_593007,
    base: "/", url: url_DescribeFlow_593008, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlow_593020 = ref object of OpenApiRestCall_592364
proc url_DeleteFlow_593022(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteFlow_593021(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593023 = path.getOrDefault("flowArn")
  valid_593023 = validateParameter(valid_593023, JString, required = true,
                                 default = nil)
  if valid_593023 != nil:
    section.add "flowArn", valid_593023
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
  var valid_593024 = header.getOrDefault("X-Amz-Signature")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Signature", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Content-Sha256", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Date")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Date", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Credential")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Credential", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Security-Token")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Security-Token", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Algorithm")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Algorithm", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-SignedHeaders", valid_593030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593031: Call_DeleteFlow_593020; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ## 
  let valid = call_593031.validator(path, query, header, formData, body)
  let scheme = call_593031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593031.url(scheme.get, call_593031.host, call_593031.base,
                         call_593031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593031, url, valid)

proc call*(call_593032: Call_DeleteFlow_593020; flowArn: string): Recallable =
  ## deleteFlow
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to delete.
  var path_593033 = newJObject()
  add(path_593033, "flowArn", newJString(flowArn))
  result = call_593032.call(path_593033, nil, nil, nil, nil)

var deleteFlow* = Call_DeleteFlow_593020(name: "deleteFlow",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows/{flowArn}",
                                      validator: validate_DeleteFlow_593021,
                                      base: "/", url: url_DeleteFlow_593022,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GrantFlowEntitlements_593034 = ref object of OpenApiRestCall_592364
proc url_GrantFlowEntitlements_593036(protocol: Scheme; host: string; base: string;
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

proc validate_GrantFlowEntitlements_593035(path: JsonNode; query: JsonNode;
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
  var valid_593037 = path.getOrDefault("flowArn")
  valid_593037 = validateParameter(valid_593037, JString, required = true,
                                 default = nil)
  if valid_593037 != nil:
    section.add "flowArn", valid_593037
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
  var valid_593038 = header.getOrDefault("X-Amz-Signature")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Signature", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Content-Sha256", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Date")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Date", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Credential")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Credential", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Security-Token")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Security-Token", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Algorithm")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Algorithm", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-SignedHeaders", valid_593044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593046: Call_GrantFlowEntitlements_593034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants entitlements to an existing flow.
  ## 
  let valid = call_593046.validator(path, query, header, formData, body)
  let scheme = call_593046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593046.url(scheme.get, call_593046.host, call_593046.base,
                         call_593046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593046, url, valid)

proc call*(call_593047: Call_GrantFlowEntitlements_593034; body: JsonNode;
          flowArn: string): Recallable =
  ## grantFlowEntitlements
  ## Grants entitlements to an existing flow.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that you want to grant entitlements on.
  var path_593048 = newJObject()
  var body_593049 = newJObject()
  if body != nil:
    body_593049 = body
  add(path_593048, "flowArn", newJString(flowArn))
  result = call_593047.call(path_593048, nil, nil, nil, body_593049)

var grantFlowEntitlements* = Call_GrantFlowEntitlements_593034(
    name: "grantFlowEntitlements", meth: HttpMethod.HttpPost,
    host: "mediaconnect.amazonaws.com", route: "/v1/flows/{flowArn}/entitlements",
    validator: validate_GrantFlowEntitlements_593035, base: "/",
    url: url_GrantFlowEntitlements_593036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitlements_593050 = ref object of OpenApiRestCall_592364
proc url_ListEntitlements_593052(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEntitlements_593051(path: JsonNode; query: JsonNode;
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
  var valid_593053 = query.getOrDefault("nextToken")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "nextToken", valid_593053
  var valid_593054 = query.getOrDefault("MaxResults")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "MaxResults", valid_593054
  var valid_593055 = query.getOrDefault("NextToken")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "NextToken", valid_593055
  var valid_593056 = query.getOrDefault("maxResults")
  valid_593056 = validateParameter(valid_593056, JInt, required = false, default = nil)
  if valid_593056 != nil:
    section.add "maxResults", valid_593056
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
  var valid_593057 = header.getOrDefault("X-Amz-Signature")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Signature", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-Content-Sha256", valid_593058
  var valid_593059 = header.getOrDefault("X-Amz-Date")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Date", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Credential")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Credential", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Security-Token")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Security-Token", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Algorithm")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Algorithm", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-SignedHeaders", valid_593063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593064: Call_ListEntitlements_593050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
  ## 
  let valid = call_593064.validator(path, query, header, formData, body)
  let scheme = call_593064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593064.url(scheme.get, call_593064.host, call_593064.base,
                         call_593064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593064, url, valid)

proc call*(call_593065: Call_ListEntitlements_593050; nextToken: string = "";
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
  var query_593066 = newJObject()
  add(query_593066, "nextToken", newJString(nextToken))
  add(query_593066, "MaxResults", newJString(MaxResults))
  add(query_593066, "NextToken", newJString(NextToken))
  add(query_593066, "maxResults", newJInt(maxResults))
  result = call_593065.call(nil, query_593066, nil, nil, nil)

var listEntitlements* = Call_ListEntitlements_593050(name: "listEntitlements",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/entitlements", validator: validate_ListEntitlements_593051,
    base: "/", url: url_ListEntitlements_593052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593081 = ref object of OpenApiRestCall_592364
proc url_TagResource_593083(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_593082(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593084 = path.getOrDefault("resourceArn")
  valid_593084 = validateParameter(valid_593084, JString, required = true,
                                 default = nil)
  if valid_593084 != nil:
    section.add "resourceArn", valid_593084
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
  var valid_593085 = header.getOrDefault("X-Amz-Signature")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Signature", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Content-Sha256", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Date")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Date", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Credential")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Credential", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Security-Token")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Security-Token", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Algorithm")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Algorithm", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-SignedHeaders", valid_593091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593093: Call_TagResource_593081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_593093.validator(path, query, header, formData, body)
  let scheme = call_593093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593093.url(scheme.get, call_593093.host, call_593093.base,
                         call_593093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593093, url, valid)

proc call*(call_593094: Call_TagResource_593081; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource to which to add tags.
  ##   body: JObject (required)
  var path_593095 = newJObject()
  var body_593096 = newJObject()
  add(path_593095, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_593096 = body
  result = call_593094.call(path_593095, nil, nil, nil, body_593096)

var tagResource* = Call_TagResource_593081(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconnect.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_593082,
                                        base: "/", url: url_TagResource_593083,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593067 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593069(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_593068(path: JsonNode; query: JsonNode;
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
  var valid_593070 = path.getOrDefault("resourceArn")
  valid_593070 = validateParameter(valid_593070, JString, required = true,
                                 default = nil)
  if valid_593070 != nil:
    section.add "resourceArn", valid_593070
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
  var valid_593071 = header.getOrDefault("X-Amz-Signature")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Signature", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Content-Sha256", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Date")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Date", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Credential")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Credential", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Security-Token")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Security-Token", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Algorithm")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Algorithm", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-SignedHeaders", valid_593077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593078: Call_ListTagsForResource_593067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags on an AWS Elemental MediaConnect resource
  ## 
  let valid = call_593078.validator(path, query, header, formData, body)
  let scheme = call_593078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593078.url(scheme.get, call_593078.host, call_593078.base,
                         call_593078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593078, url, valid)

proc call*(call_593079: Call_ListTagsForResource_593067; resourceArn: string): Recallable =
  ## listTagsForResource
  ## List all tags on an AWS Elemental MediaConnect resource
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource for which to list the tags.
  var path_593080 = newJObject()
  add(path_593080, "resourceArn", newJString(resourceArn))
  result = call_593079.call(path_593080, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_593067(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconnect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_593068, base: "/",
    url: url_ListTagsForResource_593069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowOutput_593097 = ref object of OpenApiRestCall_592364
proc url_UpdateFlowOutput_593099(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFlowOutput_593098(path: JsonNode; query: JsonNode;
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
  var valid_593100 = path.getOrDefault("outputArn")
  valid_593100 = validateParameter(valid_593100, JString, required = true,
                                 default = nil)
  if valid_593100 != nil:
    section.add "outputArn", valid_593100
  var valid_593101 = path.getOrDefault("flowArn")
  valid_593101 = validateParameter(valid_593101, JString, required = true,
                                 default = nil)
  if valid_593101 != nil:
    section.add "flowArn", valid_593101
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
  var valid_593102 = header.getOrDefault("X-Amz-Signature")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Signature", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Content-Sha256", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Date")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Date", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Credential")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Credential", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Security-Token")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Security-Token", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Algorithm")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Algorithm", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-SignedHeaders", valid_593108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593110: Call_UpdateFlowOutput_593097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing flow output.
  ## 
  let valid = call_593110.validator(path, query, header, formData, body)
  let scheme = call_593110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593110.url(scheme.get, call_593110.host, call_593110.base,
                         call_593110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593110, url, valid)

proc call*(call_593111: Call_UpdateFlowOutput_593097; outputArn: string;
          body: JsonNode; flowArn: string): Recallable =
  ## updateFlowOutput
  ## Updates an existing flow output.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to update.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that is associated with the output that you want to update.
  var path_593112 = newJObject()
  var body_593113 = newJObject()
  add(path_593112, "outputArn", newJString(outputArn))
  if body != nil:
    body_593113 = body
  add(path_593112, "flowArn", newJString(flowArn))
  result = call_593111.call(path_593112, nil, nil, nil, body_593113)

var updateFlowOutput* = Call_UpdateFlowOutput_593097(name: "updateFlowOutput",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_UpdateFlowOutput_593098, base: "/",
    url: url_UpdateFlowOutput_593099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFlowOutput_593114 = ref object of OpenApiRestCall_592364
proc url_RemoveFlowOutput_593116(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveFlowOutput_593115(path: JsonNode; query: JsonNode;
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
  var valid_593117 = path.getOrDefault("outputArn")
  valid_593117 = validateParameter(valid_593117, JString, required = true,
                                 default = nil)
  if valid_593117 != nil:
    section.add "outputArn", valid_593117
  var valid_593118 = path.getOrDefault("flowArn")
  valid_593118 = validateParameter(valid_593118, JString, required = true,
                                 default = nil)
  if valid_593118 != nil:
    section.add "flowArn", valid_593118
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
  var valid_593119 = header.getOrDefault("X-Amz-Signature")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Signature", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Content-Sha256", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Date")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Date", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Credential")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Credential", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Security-Token")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Security-Token", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Algorithm")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Algorithm", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-SignedHeaders", valid_593125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593126: Call_RemoveFlowOutput_593114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ## 
  let valid = call_593126.validator(path, query, header, formData, body)
  let scheme = call_593126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593126.url(scheme.get, call_593126.host, call_593126.base,
                         call_593126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593126, url, valid)

proc call*(call_593127: Call_RemoveFlowOutput_593114; outputArn: string;
          flowArn: string): Recallable =
  ## removeFlowOutput
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to remove.
  ##   flowArn: string (required)
  ##          : The flow that you want to remove an output from.
  var path_593128 = newJObject()
  add(path_593128, "outputArn", newJString(outputArn))
  add(path_593128, "flowArn", newJString(flowArn))
  result = call_593127.call(path_593128, nil, nil, nil, nil)

var removeFlowOutput* = Call_RemoveFlowOutput_593114(name: "removeFlowOutput",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_RemoveFlowOutput_593115, base: "/",
    url: url_RemoveFlowOutput_593116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowEntitlement_593129 = ref object of OpenApiRestCall_592364
proc url_UpdateFlowEntitlement_593131(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFlowEntitlement_593130(path: JsonNode; query: JsonNode;
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
  var valid_593132 = path.getOrDefault("entitlementArn")
  valid_593132 = validateParameter(valid_593132, JString, required = true,
                                 default = nil)
  if valid_593132 != nil:
    section.add "entitlementArn", valid_593132
  var valid_593133 = path.getOrDefault("flowArn")
  valid_593133 = validateParameter(valid_593133, JString, required = true,
                                 default = nil)
  if valid_593133 != nil:
    section.add "flowArn", valid_593133
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
  var valid_593134 = header.getOrDefault("X-Amz-Signature")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Signature", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Content-Sha256", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Date")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Date", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Credential")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Credential", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Security-Token")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Security-Token", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Algorithm")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Algorithm", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-SignedHeaders", valid_593140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593142: Call_UpdateFlowEntitlement_593129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ## 
  let valid = call_593142.validator(path, query, header, formData, body)
  let scheme = call_593142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593142.url(scheme.get, call_593142.host, call_593142.base,
                         call_593142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593142, url, valid)

proc call*(call_593143: Call_UpdateFlowEntitlement_593129; entitlementArn: string;
          body: JsonNode; flowArn: string): Recallable =
  ## updateFlowEntitlement
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to update.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that is associated with the entitlement that you want to update.
  var path_593144 = newJObject()
  var body_593145 = newJObject()
  add(path_593144, "entitlementArn", newJString(entitlementArn))
  if body != nil:
    body_593145 = body
  add(path_593144, "flowArn", newJString(flowArn))
  result = call_593143.call(path_593144, nil, nil, nil, body_593145)

var updateFlowEntitlement* = Call_UpdateFlowEntitlement_593129(
    name: "updateFlowEntitlement", meth: HttpMethod.HttpPut,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_UpdateFlowEntitlement_593130, base: "/",
    url: url_UpdateFlowEntitlement_593131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeFlowEntitlement_593146 = ref object of OpenApiRestCall_592364
proc url_RevokeFlowEntitlement_593148(protocol: Scheme; host: string; base: string;
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

proc validate_RevokeFlowEntitlement_593147(path: JsonNode; query: JsonNode;
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
  var valid_593149 = path.getOrDefault("entitlementArn")
  valid_593149 = validateParameter(valid_593149, JString, required = true,
                                 default = nil)
  if valid_593149 != nil:
    section.add "entitlementArn", valid_593149
  var valid_593150 = path.getOrDefault("flowArn")
  valid_593150 = validateParameter(valid_593150, JString, required = true,
                                 default = nil)
  if valid_593150 != nil:
    section.add "flowArn", valid_593150
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
  var valid_593151 = header.getOrDefault("X-Amz-Signature")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Signature", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Content-Sha256", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Date")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Date", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Credential")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Credential", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Security-Token")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Security-Token", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Algorithm")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Algorithm", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-SignedHeaders", valid_593157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593158: Call_RevokeFlowEntitlement_593146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ## 
  let valid = call_593158.validator(path, query, header, formData, body)
  let scheme = call_593158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593158.url(scheme.get, call_593158.host, call_593158.base,
                         call_593158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593158, url, valid)

proc call*(call_593159: Call_RevokeFlowEntitlement_593146; entitlementArn: string;
          flowArn: string): Recallable =
  ## revokeFlowEntitlement
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to revoke.
  ##   flowArn: string (required)
  ##          : The flow that you want to revoke an entitlement from.
  var path_593160 = newJObject()
  add(path_593160, "entitlementArn", newJString(entitlementArn))
  add(path_593160, "flowArn", newJString(flowArn))
  result = call_593159.call(path_593160, nil, nil, nil, nil)

var revokeFlowEntitlement* = Call_RevokeFlowEntitlement_593146(
    name: "revokeFlowEntitlement", meth: HttpMethod.HttpDelete,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_RevokeFlowEntitlement_593147, base: "/",
    url: url_RevokeFlowEntitlement_593148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFlow_593161 = ref object of OpenApiRestCall_592364
proc url_StartFlow_593163(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StartFlow_593162(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593164 = path.getOrDefault("flowArn")
  valid_593164 = validateParameter(valid_593164, JString, required = true,
                                 default = nil)
  if valid_593164 != nil:
    section.add "flowArn", valid_593164
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
  var valid_593165 = header.getOrDefault("X-Amz-Signature")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Signature", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Content-Sha256", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-Date")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Date", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Credential")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Credential", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Security-Token")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Security-Token", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Algorithm")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Algorithm", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-SignedHeaders", valid_593171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593172: Call_StartFlow_593161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a flow.
  ## 
  let valid = call_593172.validator(path, query, header, formData, body)
  let scheme = call_593172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593172.url(scheme.get, call_593172.host, call_593172.base,
                         call_593172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593172, url, valid)

proc call*(call_593173: Call_StartFlow_593161; flowArn: string): Recallable =
  ## startFlow
  ## Starts a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to start.
  var path_593174 = newJObject()
  add(path_593174, "flowArn", newJString(flowArn))
  result = call_593173.call(path_593174, nil, nil, nil, nil)

var startFlow* = Call_StartFlow_593161(name: "startFlow", meth: HttpMethod.HttpPost,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows/start/{flowArn}",
                                    validator: validate_StartFlow_593162,
                                    base: "/", url: url_StartFlow_593163,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFlow_593175 = ref object of OpenApiRestCall_592364
proc url_StopFlow_593177(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopFlow_593176(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593178 = path.getOrDefault("flowArn")
  valid_593178 = validateParameter(valid_593178, JString, required = true,
                                 default = nil)
  if valid_593178 != nil:
    section.add "flowArn", valid_593178
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
  var valid_593179 = header.getOrDefault("X-Amz-Signature")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Signature", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Content-Sha256", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-Date")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Date", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-Credential")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Credential", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Security-Token")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Security-Token", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Algorithm")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Algorithm", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-SignedHeaders", valid_593185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593186: Call_StopFlow_593175; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a flow.
  ## 
  let valid = call_593186.validator(path, query, header, formData, body)
  let scheme = call_593186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593186.url(scheme.get, call_593186.host, call_593186.base,
                         call_593186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593186, url, valid)

proc call*(call_593187: Call_StopFlow_593175; flowArn: string): Recallable =
  ## stopFlow
  ## Stops a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to stop.
  var path_593188 = newJObject()
  add(path_593188, "flowArn", newJString(flowArn))
  result = call_593187.call(path_593188, nil, nil, nil, nil)

var stopFlow* = Call_StopFlow_593175(name: "stopFlow", meth: HttpMethod.HttpPost,
                                  host: "mediaconnect.amazonaws.com",
                                  route: "/v1/flows/stop/{flowArn}",
                                  validator: validate_StopFlow_593176, base: "/",
                                  url: url_StopFlow_593177,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593189 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593191(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_593190(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593192 = path.getOrDefault("resourceArn")
  valid_593192 = validateParameter(valid_593192, JString, required = true,
                                 default = nil)
  if valid_593192 != nil:
    section.add "resourceArn", valid_593192
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_593193 = query.getOrDefault("tagKeys")
  valid_593193 = validateParameter(valid_593193, JArray, required = true, default = nil)
  if valid_593193 != nil:
    section.add "tagKeys", valid_593193
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
  var valid_593194 = header.getOrDefault("X-Amz-Signature")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Signature", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Content-Sha256", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Date")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Date", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Credential")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Credential", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-Security-Token")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Security-Token", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Algorithm")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Algorithm", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-SignedHeaders", valid_593200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593201: Call_UntagResource_593189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_593201.validator(path, query, header, formData, body)
  let scheme = call_593201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593201.url(scheme.get, call_593201.host, call_593201.base,
                         call_593201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593201, url, valid)

proc call*(call_593202: Call_UntagResource_593189; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource from which to delete tags.
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  var path_593203 = newJObject()
  var query_593204 = newJObject()
  add(path_593203, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_593204.add "tagKeys", tagKeys
  result = call_593202.call(path_593203, query_593204, nil, nil, nil)

var untagResource* = Call_UntagResource_593189(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_593190,
    base: "/", url: url_UntagResource_593191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowSource_593205 = ref object of OpenApiRestCall_592364
proc url_UpdateFlowSource_593207(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFlowSource_593206(path: JsonNode; query: JsonNode;
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
  var valid_593208 = path.getOrDefault("sourceArn")
  valid_593208 = validateParameter(valid_593208, JString, required = true,
                                 default = nil)
  if valid_593208 != nil:
    section.add "sourceArn", valid_593208
  var valid_593209 = path.getOrDefault("flowArn")
  valid_593209 = validateParameter(valid_593209, JString, required = true,
                                 default = nil)
  if valid_593209 != nil:
    section.add "flowArn", valid_593209
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
  var valid_593210 = header.getOrDefault("X-Amz-Signature")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Signature", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Content-Sha256", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-Date")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-Date", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-Credential")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Credential", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-Security-Token")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-Security-Token", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-Algorithm")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Algorithm", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-SignedHeaders", valid_593216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593218: Call_UpdateFlowSource_593205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the source of a flow.
  ## 
  let valid = call_593218.validator(path, query, header, formData, body)
  let scheme = call_593218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593218.url(scheme.get, call_593218.host, call_593218.base,
                         call_593218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593218, url, valid)

proc call*(call_593219: Call_UpdateFlowSource_593205; sourceArn: string;
          body: JsonNode; flowArn: string): Recallable =
  ## updateFlowSource
  ## Updates the source of a flow.
  ##   sourceArn: string (required)
  ##            : The ARN of the source that you want to update.
  ##   body: JObject (required)
  ##   flowArn: string (required)
  ##          : The flow that is associated with the source that you want to update.
  var path_593220 = newJObject()
  var body_593221 = newJObject()
  add(path_593220, "sourceArn", newJString(sourceArn))
  if body != nil:
    body_593221 = body
  add(path_593220, "flowArn", newJString(flowArn))
  result = call_593219.call(path_593220, nil, nil, nil, body_593221)

var updateFlowSource* = Call_UpdateFlowSource_593205(name: "updateFlowSource",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/source/{sourceArn}",
    validator: validate_UpdateFlowSource_593206, base: "/",
    url: url_UpdateFlowSource_593207, schemes: {Scheme.Https, Scheme.Http})
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
