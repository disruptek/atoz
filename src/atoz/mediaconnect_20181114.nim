
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddFlowOutputs_772933 = ref object of OpenApiRestCall_772597
proc url_AddFlowOutputs_772935(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn"),
               (kind: ConstantSegment, value: "/outputs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_AddFlowOutputs_772934(path: JsonNode; query: JsonNode;
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
  var valid_773061 = path.getOrDefault("flowArn")
  valid_773061 = validateParameter(valid_773061, JString, required = true,
                                 default = nil)
  if valid_773061 != nil:
    section.add "flowArn", valid_773061
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
  var valid_773062 = header.getOrDefault("X-Amz-Date")
  valid_773062 = validateParameter(valid_773062, JString, required = false,
                                 default = nil)
  if valid_773062 != nil:
    section.add "X-Amz-Date", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Security-Token")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Security-Token", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Content-Sha256", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Algorithm")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Algorithm", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Signature")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Signature", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-SignedHeaders", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-Credential")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-Credential", valid_773068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773092: Call_AddFlowOutputs_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ## 
  let valid = call_773092.validator(path, query, header, formData, body)
  let scheme = call_773092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773092.url(scheme.get, call_773092.host, call_773092.base,
                         call_773092.route, valid.getOrDefault("path"))
  result = hook(call_773092, url, valid)

proc call*(call_773163: Call_AddFlowOutputs_772933; flowArn: string; body: JsonNode): Recallable =
  ## addFlowOutputs
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ##   flowArn: string (required)
  ##          : The flow that you want to add outputs to.
  ##   body: JObject (required)
  var path_773164 = newJObject()
  var body_773166 = newJObject()
  add(path_773164, "flowArn", newJString(flowArn))
  if body != nil:
    body_773166 = body
  result = call_773163.call(path_773164, nil, nil, nil, body_773166)

var addFlowOutputs* = Call_AddFlowOutputs_772933(name: "addFlowOutputs",
    meth: HttpMethod.HttpPost, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs", validator: validate_AddFlowOutputs_772934,
    base: "/", url: url_AddFlowOutputs_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlow_773222 = ref object of OpenApiRestCall_772597
proc url_CreateFlow_773224(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFlow_773223(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773225 = header.getOrDefault("X-Amz-Date")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Date", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Security-Token")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Security-Token", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Content-Sha256", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Algorithm")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Algorithm", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Signature")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Signature", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-SignedHeaders", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Credential")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Credential", valid_773231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773233: Call_CreateFlow_773222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ## 
  let valid = call_773233.validator(path, query, header, formData, body)
  let scheme = call_773233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773233.url(scheme.get, call_773233.host, call_773233.base,
                         call_773233.route, valid.getOrDefault("path"))
  result = hook(call_773233, url, valid)

proc call*(call_773234: Call_CreateFlow_773222; body: JsonNode): Recallable =
  ## createFlow
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ##   body: JObject (required)
  var body_773235 = newJObject()
  if body != nil:
    body_773235 = body
  result = call_773234.call(nil, nil, nil, nil, body_773235)

var createFlow* = Call_CreateFlow_773222(name: "createFlow",
                                      meth: HttpMethod.HttpPost,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows",
                                      validator: validate_CreateFlow_773223,
                                      base: "/", url: url_CreateFlow_773224,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlows_773205 = ref object of OpenApiRestCall_772597
proc url_ListFlows_773207(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListFlows_773206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773208 = query.getOrDefault("NextToken")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "NextToken", valid_773208
  var valid_773209 = query.getOrDefault("maxResults")
  valid_773209 = validateParameter(valid_773209, JInt, required = false, default = nil)
  if valid_773209 != nil:
    section.add "maxResults", valid_773209
  var valid_773210 = query.getOrDefault("nextToken")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "nextToken", valid_773210
  var valid_773211 = query.getOrDefault("MaxResults")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "MaxResults", valid_773211
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
  var valid_773212 = header.getOrDefault("X-Amz-Date")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Date", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Security-Token")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Security-Token", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Content-Sha256", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Algorithm")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Algorithm", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Signature")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Signature", valid_773216
  var valid_773217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "X-Amz-SignedHeaders", valid_773217
  var valid_773218 = header.getOrDefault("X-Amz-Credential")
  valid_773218 = validateParameter(valid_773218, JString, required = false,
                                 default = nil)
  if valid_773218 != nil:
    section.add "X-Amz-Credential", valid_773218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773219: Call_ListFlows_773205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
  ## 
  let valid = call_773219.validator(path, query, header, formData, body)
  let scheme = call_773219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773219.url(scheme.get, call_773219.host, call_773219.base,
                         call_773219.route, valid.getOrDefault("path"))
  result = hook(call_773219, url, valid)

proc call*(call_773220: Call_ListFlows_773205; NextToken: string = "";
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
  var query_773221 = newJObject()
  add(query_773221, "NextToken", newJString(NextToken))
  add(query_773221, "maxResults", newJInt(maxResults))
  add(query_773221, "nextToken", newJString(nextToken))
  add(query_773221, "MaxResults", newJString(MaxResults))
  result = call_773220.call(nil, query_773221, nil, nil, nil)

var listFlows* = Call_ListFlows_773205(name: "listFlows", meth: HttpMethod.HttpGet,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows",
                                    validator: validate_ListFlows_773206,
                                    base: "/", url: url_ListFlows_773207,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlow_773236 = ref object of OpenApiRestCall_772597
proc url_DescribeFlow_773238(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeFlow_773237(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773239 = path.getOrDefault("flowArn")
  valid_773239 = validateParameter(valid_773239, JString, required = true,
                                 default = nil)
  if valid_773239 != nil:
    section.add "flowArn", valid_773239
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
  var valid_773240 = header.getOrDefault("X-Amz-Date")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Date", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Security-Token")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Security-Token", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Content-Sha256", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Algorithm")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Algorithm", valid_773243
  var valid_773244 = header.getOrDefault("X-Amz-Signature")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "X-Amz-Signature", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-SignedHeaders", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-Credential")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Credential", valid_773246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773247: Call_DescribeFlow_773236; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ## 
  let valid = call_773247.validator(path, query, header, formData, body)
  let scheme = call_773247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773247.url(scheme.get, call_773247.host, call_773247.base,
                         call_773247.route, valid.getOrDefault("path"))
  result = hook(call_773247, url, valid)

proc call*(call_773248: Call_DescribeFlow_773236; flowArn: string): Recallable =
  ## describeFlow
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to describe.
  var path_773249 = newJObject()
  add(path_773249, "flowArn", newJString(flowArn))
  result = call_773248.call(path_773249, nil, nil, nil, nil)

var describeFlow* = Call_DescribeFlow_773236(name: "describeFlow",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}", validator: validate_DescribeFlow_773237,
    base: "/", url: url_DescribeFlow_773238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlow_773250 = ref object of OpenApiRestCall_772597
proc url_DeleteFlow_773252(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteFlow_773251(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773253 = path.getOrDefault("flowArn")
  valid_773253 = validateParameter(valid_773253, JString, required = true,
                                 default = nil)
  if valid_773253 != nil:
    section.add "flowArn", valid_773253
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
  var valid_773254 = header.getOrDefault("X-Amz-Date")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Date", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Security-Token")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Security-Token", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Content-Sha256", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Algorithm")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Algorithm", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Signature")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Signature", valid_773258
  var valid_773259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-SignedHeaders", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Credential")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Credential", valid_773260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773261: Call_DeleteFlow_773250; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ## 
  let valid = call_773261.validator(path, query, header, formData, body)
  let scheme = call_773261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773261.url(scheme.get, call_773261.host, call_773261.base,
                         call_773261.route, valid.getOrDefault("path"))
  result = hook(call_773261, url, valid)

proc call*(call_773262: Call_DeleteFlow_773250; flowArn: string): Recallable =
  ## deleteFlow
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to delete.
  var path_773263 = newJObject()
  add(path_773263, "flowArn", newJString(flowArn))
  result = call_773262.call(path_773263, nil, nil, nil, nil)

var deleteFlow* = Call_DeleteFlow_773250(name: "deleteFlow",
                                      meth: HttpMethod.HttpDelete,
                                      host: "mediaconnect.amazonaws.com",
                                      route: "/v1/flows/{flowArn}",
                                      validator: validate_DeleteFlow_773251,
                                      base: "/", url: url_DeleteFlow_773252,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GrantFlowEntitlements_773264 = ref object of OpenApiRestCall_772597
proc url_GrantFlowEntitlements_773266(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
               (kind: VariableSegment, value: "flowArn"),
               (kind: ConstantSegment, value: "/entitlements")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GrantFlowEntitlements_773265(path: JsonNode; query: JsonNode;
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
  var valid_773267 = path.getOrDefault("flowArn")
  valid_773267 = validateParameter(valid_773267, JString, required = true,
                                 default = nil)
  if valid_773267 != nil:
    section.add "flowArn", valid_773267
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
  var valid_773268 = header.getOrDefault("X-Amz-Date")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Date", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Security-Token")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Security-Token", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Content-Sha256", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Algorithm")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Algorithm", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Signature")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Signature", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-SignedHeaders", valid_773273
  var valid_773274 = header.getOrDefault("X-Amz-Credential")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-Credential", valid_773274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773276: Call_GrantFlowEntitlements_773264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Grants entitlements to an existing flow.
  ## 
  let valid = call_773276.validator(path, query, header, formData, body)
  let scheme = call_773276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773276.url(scheme.get, call_773276.host, call_773276.base,
                         call_773276.route, valid.getOrDefault("path"))
  result = hook(call_773276, url, valid)

proc call*(call_773277: Call_GrantFlowEntitlements_773264; flowArn: string;
          body: JsonNode): Recallable =
  ## grantFlowEntitlements
  ## Grants entitlements to an existing flow.
  ##   flowArn: string (required)
  ##          : The flow that you want to grant entitlements on.
  ##   body: JObject (required)
  var path_773278 = newJObject()
  var body_773279 = newJObject()
  add(path_773278, "flowArn", newJString(flowArn))
  if body != nil:
    body_773279 = body
  result = call_773277.call(path_773278, nil, nil, nil, body_773279)

var grantFlowEntitlements* = Call_GrantFlowEntitlements_773264(
    name: "grantFlowEntitlements", meth: HttpMethod.HttpPost,
    host: "mediaconnect.amazonaws.com", route: "/v1/flows/{flowArn}/entitlements",
    validator: validate_GrantFlowEntitlements_773265, base: "/",
    url: url_GrantFlowEntitlements_773266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitlements_773280 = ref object of OpenApiRestCall_772597
proc url_ListEntitlements_773282(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListEntitlements_773281(path: JsonNode; query: JsonNode;
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
  var valid_773283 = query.getOrDefault("NextToken")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "NextToken", valid_773283
  var valid_773284 = query.getOrDefault("maxResults")
  valid_773284 = validateParameter(valid_773284, JInt, required = false, default = nil)
  if valid_773284 != nil:
    section.add "maxResults", valid_773284
  var valid_773285 = query.getOrDefault("nextToken")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "nextToken", valid_773285
  var valid_773286 = query.getOrDefault("MaxResults")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "MaxResults", valid_773286
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
  var valid_773287 = header.getOrDefault("X-Amz-Date")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Date", valid_773287
  var valid_773288 = header.getOrDefault("X-Amz-Security-Token")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-Security-Token", valid_773288
  var valid_773289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Content-Sha256", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Algorithm")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Algorithm", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-Signature")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Signature", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-SignedHeaders", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Credential")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Credential", valid_773293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773294: Call_ListEntitlements_773280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
  ## 
  let valid = call_773294.validator(path, query, header, formData, body)
  let scheme = call_773294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773294.url(scheme.get, call_773294.host, call_773294.base,
                         call_773294.route, valid.getOrDefault("path"))
  result = hook(call_773294, url, valid)

proc call*(call_773295: Call_ListEntitlements_773280; NextToken: string = "";
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
  var query_773296 = newJObject()
  add(query_773296, "NextToken", newJString(NextToken))
  add(query_773296, "maxResults", newJInt(maxResults))
  add(query_773296, "nextToken", newJString(nextToken))
  add(query_773296, "MaxResults", newJString(MaxResults))
  result = call_773295.call(nil, query_773296, nil, nil, nil)

var listEntitlements* = Call_ListEntitlements_773280(name: "listEntitlements",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/entitlements", validator: validate_ListEntitlements_773281,
    base: "/", url: url_ListEntitlements_773282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_773311 = ref object of OpenApiRestCall_772597
proc url_TagResource_773313(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TagResource_773312(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773314 = path.getOrDefault("resourceArn")
  valid_773314 = validateParameter(valid_773314, JString, required = true,
                                 default = nil)
  if valid_773314 != nil:
    section.add "resourceArn", valid_773314
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
  var valid_773315 = header.getOrDefault("X-Amz-Date")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Date", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-Security-Token")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-Security-Token", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Content-Sha256", valid_773317
  var valid_773318 = header.getOrDefault("X-Amz-Algorithm")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-Algorithm", valid_773318
  var valid_773319 = header.getOrDefault("X-Amz-Signature")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-Signature", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-SignedHeaders", valid_773320
  var valid_773321 = header.getOrDefault("X-Amz-Credential")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "X-Amz-Credential", valid_773321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773323: Call_TagResource_773311; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_773323.validator(path, query, header, formData, body)
  let scheme = call_773323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773323.url(scheme.get, call_773323.host, call_773323.base,
                         call_773323.route, valid.getOrDefault("path"))
  result = hook(call_773323, url, valid)

proc call*(call_773324: Call_TagResource_773311; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource to which to add tags.
  var path_773325 = newJObject()
  var body_773326 = newJObject()
  if body != nil:
    body_773326 = body
  add(path_773325, "resourceArn", newJString(resourceArn))
  result = call_773324.call(path_773325, nil, nil, nil, body_773326)

var tagResource* = Call_TagResource_773311(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconnect.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_773312,
                                        base: "/", url: url_TagResource_773313,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773297 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_773299(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTagsForResource_773298(path: JsonNode; query: JsonNode;
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
  var valid_773300 = path.getOrDefault("resourceArn")
  valid_773300 = validateParameter(valid_773300, JString, required = true,
                                 default = nil)
  if valid_773300 != nil:
    section.add "resourceArn", valid_773300
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
  var valid_773301 = header.getOrDefault("X-Amz-Date")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-Date", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Security-Token")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Security-Token", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Content-Sha256", valid_773303
  var valid_773304 = header.getOrDefault("X-Amz-Algorithm")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-Algorithm", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-Signature")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Signature", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-SignedHeaders", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Credential")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Credential", valid_773307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773308: Call_ListTagsForResource_773297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags on an AWS Elemental MediaConnect resource
  ## 
  let valid = call_773308.validator(path, query, header, formData, body)
  let scheme = call_773308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773308.url(scheme.get, call_773308.host, call_773308.base,
                         call_773308.route, valid.getOrDefault("path"))
  result = hook(call_773308, url, valid)

proc call*(call_773309: Call_ListTagsForResource_773297; resourceArn: string): Recallable =
  ## listTagsForResource
  ## List all tags on an AWS Elemental MediaConnect resource
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource for which to list the tags.
  var path_773310 = newJObject()
  add(path_773310, "resourceArn", newJString(resourceArn))
  result = call_773309.call(path_773310, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_773297(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconnect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_773298, base: "/",
    url: url_ListTagsForResource_773299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowOutput_773327 = ref object of OpenApiRestCall_772597
proc url_UpdateFlowOutput_773329(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateFlowOutput_773328(path: JsonNode; query: JsonNode;
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
  var valid_773330 = path.getOrDefault("flowArn")
  valid_773330 = validateParameter(valid_773330, JString, required = true,
                                 default = nil)
  if valid_773330 != nil:
    section.add "flowArn", valid_773330
  var valid_773331 = path.getOrDefault("outputArn")
  valid_773331 = validateParameter(valid_773331, JString, required = true,
                                 default = nil)
  if valid_773331 != nil:
    section.add "outputArn", valid_773331
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
  var valid_773332 = header.getOrDefault("X-Amz-Date")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Date", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Security-Token")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Security-Token", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-Content-Sha256", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-Algorithm")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Algorithm", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-Signature")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-Signature", valid_773336
  var valid_773337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-SignedHeaders", valid_773337
  var valid_773338 = header.getOrDefault("X-Amz-Credential")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "X-Amz-Credential", valid_773338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773340: Call_UpdateFlowOutput_773327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing flow output.
  ## 
  let valid = call_773340.validator(path, query, header, formData, body)
  let scheme = call_773340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773340.url(scheme.get, call_773340.host, call_773340.base,
                         call_773340.route, valid.getOrDefault("path"))
  result = hook(call_773340, url, valid)

proc call*(call_773341: Call_UpdateFlowOutput_773327; flowArn: string;
          outputArn: string; body: JsonNode): Recallable =
  ## updateFlowOutput
  ## Updates an existing flow output.
  ##   flowArn: string (required)
  ##          : The flow that is associated with the output that you want to update.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to update.
  ##   body: JObject (required)
  var path_773342 = newJObject()
  var body_773343 = newJObject()
  add(path_773342, "flowArn", newJString(flowArn))
  add(path_773342, "outputArn", newJString(outputArn))
  if body != nil:
    body_773343 = body
  result = call_773341.call(path_773342, nil, nil, nil, body_773343)

var updateFlowOutput* = Call_UpdateFlowOutput_773327(name: "updateFlowOutput",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_UpdateFlowOutput_773328, base: "/",
    url: url_UpdateFlowOutput_773329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFlowOutput_773344 = ref object of OpenApiRestCall_772597
proc url_RemoveFlowOutput_773346(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RemoveFlowOutput_773345(path: JsonNode; query: JsonNode;
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
  var valid_773347 = path.getOrDefault("flowArn")
  valid_773347 = validateParameter(valid_773347, JString, required = true,
                                 default = nil)
  if valid_773347 != nil:
    section.add "flowArn", valid_773347
  var valid_773348 = path.getOrDefault("outputArn")
  valid_773348 = validateParameter(valid_773348, JString, required = true,
                                 default = nil)
  if valid_773348 != nil:
    section.add "outputArn", valid_773348
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
  var valid_773349 = header.getOrDefault("X-Amz-Date")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-Date", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Security-Token")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Security-Token", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Content-Sha256", valid_773351
  var valid_773352 = header.getOrDefault("X-Amz-Algorithm")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-Algorithm", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Signature")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Signature", valid_773353
  var valid_773354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-SignedHeaders", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Credential")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Credential", valid_773355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773356: Call_RemoveFlowOutput_773344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ## 
  let valid = call_773356.validator(path, query, header, formData, body)
  let scheme = call_773356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773356.url(scheme.get, call_773356.host, call_773356.base,
                         call_773356.route, valid.getOrDefault("path"))
  result = hook(call_773356, url, valid)

proc call*(call_773357: Call_RemoveFlowOutput_773344; flowArn: string;
          outputArn: string): Recallable =
  ## removeFlowOutput
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ##   flowArn: string (required)
  ##          : The flow that you want to remove an output from.
  ##   outputArn: string (required)
  ##            : The ARN of the output that you want to remove.
  var path_773358 = newJObject()
  add(path_773358, "flowArn", newJString(flowArn))
  add(path_773358, "outputArn", newJString(outputArn))
  result = call_773357.call(path_773358, nil, nil, nil, nil)

var removeFlowOutput* = Call_RemoveFlowOutput_773344(name: "removeFlowOutput",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_RemoveFlowOutput_773345, base: "/",
    url: url_RemoveFlowOutput_773346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowEntitlement_773359 = ref object of OpenApiRestCall_772597
proc url_UpdateFlowEntitlement_773361(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateFlowEntitlement_773360(path: JsonNode; query: JsonNode;
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
  var valid_773362 = path.getOrDefault("flowArn")
  valid_773362 = validateParameter(valid_773362, JString, required = true,
                                 default = nil)
  if valid_773362 != nil:
    section.add "flowArn", valid_773362
  var valid_773363 = path.getOrDefault("entitlementArn")
  valid_773363 = validateParameter(valid_773363, JString, required = true,
                                 default = nil)
  if valid_773363 != nil:
    section.add "entitlementArn", valid_773363
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
  var valid_773364 = header.getOrDefault("X-Amz-Date")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Date", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-Security-Token")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Security-Token", valid_773365
  var valid_773366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "X-Amz-Content-Sha256", valid_773366
  var valid_773367 = header.getOrDefault("X-Amz-Algorithm")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-Algorithm", valid_773367
  var valid_773368 = header.getOrDefault("X-Amz-Signature")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Signature", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-SignedHeaders", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Credential")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Credential", valid_773370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773372: Call_UpdateFlowEntitlement_773359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ## 
  let valid = call_773372.validator(path, query, header, formData, body)
  let scheme = call_773372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773372.url(scheme.get, call_773372.host, call_773372.base,
                         call_773372.route, valid.getOrDefault("path"))
  result = hook(call_773372, url, valid)

proc call*(call_773373: Call_UpdateFlowEntitlement_773359; flowArn: string;
          body: JsonNode; entitlementArn: string): Recallable =
  ## updateFlowEntitlement
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ##   flowArn: string (required)
  ##          : The flow that is associated with the entitlement that you want to update.
  ##   body: JObject (required)
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to update.
  var path_773374 = newJObject()
  var body_773375 = newJObject()
  add(path_773374, "flowArn", newJString(flowArn))
  if body != nil:
    body_773375 = body
  add(path_773374, "entitlementArn", newJString(entitlementArn))
  result = call_773373.call(path_773374, nil, nil, nil, body_773375)

var updateFlowEntitlement* = Call_UpdateFlowEntitlement_773359(
    name: "updateFlowEntitlement", meth: HttpMethod.HttpPut,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_UpdateFlowEntitlement_773360, base: "/",
    url: url_UpdateFlowEntitlement_773361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeFlowEntitlement_773376 = ref object of OpenApiRestCall_772597
proc url_RevokeFlowEntitlement_773378(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_RevokeFlowEntitlement_773377(path: JsonNode; query: JsonNode;
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
  var valid_773379 = path.getOrDefault("flowArn")
  valid_773379 = validateParameter(valid_773379, JString, required = true,
                                 default = nil)
  if valid_773379 != nil:
    section.add "flowArn", valid_773379
  var valid_773380 = path.getOrDefault("entitlementArn")
  valid_773380 = validateParameter(valid_773380, JString, required = true,
                                 default = nil)
  if valid_773380 != nil:
    section.add "entitlementArn", valid_773380
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
  var valid_773381 = header.getOrDefault("X-Amz-Date")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "X-Amz-Date", valid_773381
  var valid_773382 = header.getOrDefault("X-Amz-Security-Token")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-Security-Token", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Content-Sha256", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-Algorithm")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-Algorithm", valid_773384
  var valid_773385 = header.getOrDefault("X-Amz-Signature")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Signature", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-SignedHeaders", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Credential")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Credential", valid_773387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773388: Call_RevokeFlowEntitlement_773376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ## 
  let valid = call_773388.validator(path, query, header, formData, body)
  let scheme = call_773388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773388.url(scheme.get, call_773388.host, call_773388.base,
                         call_773388.route, valid.getOrDefault("path"))
  result = hook(call_773388, url, valid)

proc call*(call_773389: Call_RevokeFlowEntitlement_773376; flowArn: string;
          entitlementArn: string): Recallable =
  ## revokeFlowEntitlement
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ##   flowArn: string (required)
  ##          : The flow that you want to revoke an entitlement from.
  ##   entitlementArn: string (required)
  ##                 : The ARN of the entitlement that you want to revoke.
  var path_773390 = newJObject()
  add(path_773390, "flowArn", newJString(flowArn))
  add(path_773390, "entitlementArn", newJString(entitlementArn))
  result = call_773389.call(path_773390, nil, nil, nil, nil)

var revokeFlowEntitlement* = Call_RevokeFlowEntitlement_773376(
    name: "revokeFlowEntitlement", meth: HttpMethod.HttpDelete,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_RevokeFlowEntitlement_773377, base: "/",
    url: url_RevokeFlowEntitlement_773378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFlow_773391 = ref object of OpenApiRestCall_772597
proc url_StartFlow_773393(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/start/"),
               (kind: VariableSegment, value: "flowArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_StartFlow_773392(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773394 = path.getOrDefault("flowArn")
  valid_773394 = validateParameter(valid_773394, JString, required = true,
                                 default = nil)
  if valid_773394 != nil:
    section.add "flowArn", valid_773394
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
  var valid_773395 = header.getOrDefault("X-Amz-Date")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Date", valid_773395
  var valid_773396 = header.getOrDefault("X-Amz-Security-Token")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-Security-Token", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Content-Sha256", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-Algorithm")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Algorithm", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Signature")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Signature", valid_773399
  var valid_773400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-SignedHeaders", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Credential")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Credential", valid_773401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773402: Call_StartFlow_773391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a flow.
  ## 
  let valid = call_773402.validator(path, query, header, formData, body)
  let scheme = call_773402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773402.url(scheme.get, call_773402.host, call_773402.base,
                         call_773402.route, valid.getOrDefault("path"))
  result = hook(call_773402, url, valid)

proc call*(call_773403: Call_StartFlow_773391; flowArn: string): Recallable =
  ## startFlow
  ## Starts a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to start.
  var path_773404 = newJObject()
  add(path_773404, "flowArn", newJString(flowArn))
  result = call_773403.call(path_773404, nil, nil, nil, nil)

var startFlow* = Call_StartFlow_773391(name: "startFlow", meth: HttpMethod.HttpPost,
                                    host: "mediaconnect.amazonaws.com",
                                    route: "/v1/flows/start/{flowArn}",
                                    validator: validate_StartFlow_773392,
                                    base: "/", url: url_StartFlow_773393,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFlow_773405 = ref object of OpenApiRestCall_772597
proc url_StopFlow_773407(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/stop/"),
               (kind: VariableSegment, value: "flowArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_StopFlow_773406(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773408 = path.getOrDefault("flowArn")
  valid_773408 = validateParameter(valid_773408, JString, required = true,
                                 default = nil)
  if valid_773408 != nil:
    section.add "flowArn", valid_773408
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
  var valid_773409 = header.getOrDefault("X-Amz-Date")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Date", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-Security-Token")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-Security-Token", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Content-Sha256", valid_773411
  var valid_773412 = header.getOrDefault("X-Amz-Algorithm")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Algorithm", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-Signature")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Signature", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-SignedHeaders", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Credential")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Credential", valid_773415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773416: Call_StopFlow_773405; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a flow.
  ## 
  let valid = call_773416.validator(path, query, header, formData, body)
  let scheme = call_773416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773416.url(scheme.get, call_773416.host, call_773416.base,
                         call_773416.route, valid.getOrDefault("path"))
  result = hook(call_773416, url, valid)

proc call*(call_773417: Call_StopFlow_773405; flowArn: string): Recallable =
  ## stopFlow
  ## Stops a flow.
  ##   flowArn: string (required)
  ##          : The ARN of the flow that you want to stop.
  var path_773418 = newJObject()
  add(path_773418, "flowArn", newJString(flowArn))
  result = call_773417.call(path_773418, nil, nil, nil, nil)

var stopFlow* = Call_StopFlow_773405(name: "stopFlow", meth: HttpMethod.HttpPost,
                                  host: "mediaconnect.amazonaws.com",
                                  route: "/v1/flows/stop/{flowArn}",
                                  validator: validate_StopFlow_773406, base: "/",
                                  url: url_StopFlow_773407,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_773419 = ref object of OpenApiRestCall_772597
proc url_UntagResource_773421(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_773420(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773422 = path.getOrDefault("resourceArn")
  valid_773422 = validateParameter(valid_773422, JString, required = true,
                                 default = nil)
  if valid_773422 != nil:
    section.add "resourceArn", valid_773422
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_773423 = query.getOrDefault("tagKeys")
  valid_773423 = validateParameter(valid_773423, JArray, required = true, default = nil)
  if valid_773423 != nil:
    section.add "tagKeys", valid_773423
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
  var valid_773424 = header.getOrDefault("X-Amz-Date")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Date", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Security-Token")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Security-Token", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Content-Sha256", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-Algorithm")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Algorithm", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Signature")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Signature", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-SignedHeaders", valid_773429
  var valid_773430 = header.getOrDefault("X-Amz-Credential")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Credential", valid_773430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773431: Call_UntagResource_773419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_773431.validator(path, query, header, formData, body)
  let scheme = call_773431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773431.url(scheme.get, call_773431.host, call_773431.base,
                         call_773431.route, valid.getOrDefault("path"))
  result = hook(call_773431, url, valid)

proc call*(call_773432: Call_UntagResource_773419; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource from which to delete tags.
  var path_773433 = newJObject()
  var query_773434 = newJObject()
  if tagKeys != nil:
    query_773434.add "tagKeys", tagKeys
  add(path_773433, "resourceArn", newJString(resourceArn))
  result = call_773432.call(path_773433, query_773434, nil, nil, nil)

var untagResource* = Call_UntagResource_773419(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_773420,
    base: "/", url: url_UntagResource_773421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowSource_773435 = ref object of OpenApiRestCall_772597
proc url_UpdateFlowSource_773437(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateFlowSource_773436(path: JsonNode; query: JsonNode;
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
  var valid_773438 = path.getOrDefault("flowArn")
  valid_773438 = validateParameter(valid_773438, JString, required = true,
                                 default = nil)
  if valid_773438 != nil:
    section.add "flowArn", valid_773438
  var valid_773439 = path.getOrDefault("sourceArn")
  valid_773439 = validateParameter(valid_773439, JString, required = true,
                                 default = nil)
  if valid_773439 != nil:
    section.add "sourceArn", valid_773439
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
  var valid_773440 = header.getOrDefault("X-Amz-Date")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Date", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Security-Token")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Security-Token", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Content-Sha256", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Algorithm")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Algorithm", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-Signature")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-Signature", valid_773444
  var valid_773445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-SignedHeaders", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Credential")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Credential", valid_773446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773448: Call_UpdateFlowSource_773435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the source of a flow.
  ## 
  let valid = call_773448.validator(path, query, header, formData, body)
  let scheme = call_773448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773448.url(scheme.get, call_773448.host, call_773448.base,
                         call_773448.route, valid.getOrDefault("path"))
  result = hook(call_773448, url, valid)

proc call*(call_773449: Call_UpdateFlowSource_773435; flowArn: string;
          body: JsonNode; sourceArn: string): Recallable =
  ## updateFlowSource
  ## Updates the source of a flow.
  ##   flowArn: string (required)
  ##          : The flow that is associated with the source that you want to update.
  ##   body: JObject (required)
  ##   sourceArn: string (required)
  ##            : The ARN of the source that you want to update.
  var path_773450 = newJObject()
  var body_773451 = newJObject()
  add(path_773450, "flowArn", newJString(flowArn))
  if body != nil:
    body_773451 = body
  add(path_773450, "sourceArn", newJString(sourceArn))
  result = call_773449.call(path_773450, nil, nil, nil, body_773451)

var updateFlowSource* = Call_UpdateFlowSource_773435(name: "updateFlowSource",
    meth: HttpMethod.HttpPut, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/source/{sourceArn}",
    validator: validate_UpdateFlowSource_773436, base: "/",
    url: url_UpdateFlowSource_773437, schemes: {Scheme.Https, Scheme.Http})
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
