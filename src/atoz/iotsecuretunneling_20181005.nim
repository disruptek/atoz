
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS IoT Secure Tunneling
## version: 2018-10-05
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS IoT Secure Tunneling</fullname> <p>AWS IoT Secure Tunnling enables you to create remote connections to devices deployed in the field.</p> <p>For more information about how AWS IoT Secure Tunneling works, see the <a href="https://docs.aws.amazon.com/secure-tunneling/latest/ug/what-is-secure-tunneling.html">User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/iot/
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

  OpenApiRestCall_610649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610649): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "api.tunneling.iot.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.tunneling.iot.ap-southeast-1.amazonaws.com", "us-west-2": "api.tunneling.iot.us-west-2.amazonaws.com", "eu-west-2": "api.tunneling.iot.eu-west-2.amazonaws.com", "ap-northeast-3": "api.tunneling.iot.ap-northeast-3.amazonaws.com", "eu-central-1": "api.tunneling.iot.eu-central-1.amazonaws.com", "us-east-2": "api.tunneling.iot.us-east-2.amazonaws.com", "us-east-1": "api.tunneling.iot.us-east-1.amazonaws.com", "cn-northwest-1": "api.tunneling.iot.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "api.tunneling.iot.ap-south-1.amazonaws.com", "eu-north-1": "api.tunneling.iot.eu-north-1.amazonaws.com", "ap-northeast-2": "api.tunneling.iot.ap-northeast-2.amazonaws.com", "us-west-1": "api.tunneling.iot.us-west-1.amazonaws.com", "us-gov-east-1": "api.tunneling.iot.us-gov-east-1.amazonaws.com", "eu-west-3": "api.tunneling.iot.eu-west-3.amazonaws.com", "cn-north-1": "api.tunneling.iot.cn-north-1.amazonaws.com.cn", "sa-east-1": "api.tunneling.iot.sa-east-1.amazonaws.com", "eu-west-1": "api.tunneling.iot.eu-west-1.amazonaws.com", "us-gov-west-1": "api.tunneling.iot.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.tunneling.iot.ap-southeast-2.amazonaws.com", "ca-central-1": "api.tunneling.iot.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "api.tunneling.iot.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "api.tunneling.iot.ap-southeast-1.amazonaws.com",
      "us-west-2": "api.tunneling.iot.us-west-2.amazonaws.com",
      "eu-west-2": "api.tunneling.iot.eu-west-2.amazonaws.com",
      "ap-northeast-3": "api.tunneling.iot.ap-northeast-3.amazonaws.com",
      "eu-central-1": "api.tunneling.iot.eu-central-1.amazonaws.com",
      "us-east-2": "api.tunneling.iot.us-east-2.amazonaws.com",
      "us-east-1": "api.tunneling.iot.us-east-1.amazonaws.com",
      "cn-northwest-1": "api.tunneling.iot.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "api.tunneling.iot.ap-south-1.amazonaws.com",
      "eu-north-1": "api.tunneling.iot.eu-north-1.amazonaws.com",
      "ap-northeast-2": "api.tunneling.iot.ap-northeast-2.amazonaws.com",
      "us-west-1": "api.tunneling.iot.us-west-1.amazonaws.com",
      "us-gov-east-1": "api.tunneling.iot.us-gov-east-1.amazonaws.com",
      "eu-west-3": "api.tunneling.iot.eu-west-3.amazonaws.com",
      "cn-north-1": "api.tunneling.iot.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "api.tunneling.iot.sa-east-1.amazonaws.com",
      "eu-west-1": "api.tunneling.iot.eu-west-1.amazonaws.com",
      "us-gov-west-1": "api.tunneling.iot.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "api.tunneling.iot.ap-southeast-2.amazonaws.com",
      "ca-central-1": "api.tunneling.iot.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "iotsecuretunneling"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CloseTunnel_610987 = ref object of OpenApiRestCall_610649
proc url_CloseTunnel_610989(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CloseTunnel_610988(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Closes a tunnel identified by the unique tunnel id. When a <code>CloseTunnel</code> request is received, we close the WebSocket connections between the client and proxy server so no data can be transmitted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611114 = header.getOrDefault("X-Amz-Target")
  valid_611114 = validateParameter(valid_611114, JString, required = true, default = newJString(
      "IoTSecuredTunneling.CloseTunnel"))
  if valid_611114 != nil:
    section.add "X-Amz-Target", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Signature")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Signature", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Content-Sha256", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-Date")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-Date", valid_611117
  var valid_611118 = header.getOrDefault("X-Amz-Credential")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-Credential", valid_611118
  var valid_611119 = header.getOrDefault("X-Amz-Security-Token")
  valid_611119 = validateParameter(valid_611119, JString, required = false,
                                 default = nil)
  if valid_611119 != nil:
    section.add "X-Amz-Security-Token", valid_611119
  var valid_611120 = header.getOrDefault("X-Amz-Algorithm")
  valid_611120 = validateParameter(valid_611120, JString, required = false,
                                 default = nil)
  if valid_611120 != nil:
    section.add "X-Amz-Algorithm", valid_611120
  var valid_611121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611121 = validateParameter(valid_611121, JString, required = false,
                                 default = nil)
  if valid_611121 != nil:
    section.add "X-Amz-SignedHeaders", valid_611121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611145: Call_CloseTunnel_610987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Closes a tunnel identified by the unique tunnel id. When a <code>CloseTunnel</code> request is received, we close the WebSocket connections between the client and proxy server so no data can be transmitted.
  ## 
  let valid = call_611145.validator(path, query, header, formData, body)
  let scheme = call_611145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611145.url(scheme.get, call_611145.host, call_611145.base,
                         call_611145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611145, url, valid)

proc call*(call_611216: Call_CloseTunnel_610987; body: JsonNode): Recallable =
  ## closeTunnel
  ## Closes a tunnel identified by the unique tunnel id. When a <code>CloseTunnel</code> request is received, we close the WebSocket connections between the client and proxy server so no data can be transmitted.
  ##   body: JObject (required)
  var body_611217 = newJObject()
  if body != nil:
    body_611217 = body
  result = call_611216.call(nil, nil, nil, nil, body_611217)

var closeTunnel* = Call_CloseTunnel_610987(name: "closeTunnel",
                                        meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.CloseTunnel",
                                        validator: validate_CloseTunnel_610988,
                                        base: "/", url: url_CloseTunnel_610989,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTunnel_611256 = ref object of OpenApiRestCall_610649
proc url_DescribeTunnel_611258(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTunnel_611257(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about a tunnel identified by the unique tunnel id.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611259 = header.getOrDefault("X-Amz-Target")
  valid_611259 = validateParameter(valid_611259, JString, required = true, default = newJString(
      "IoTSecuredTunneling.DescribeTunnel"))
  if valid_611259 != nil:
    section.add "X-Amz-Target", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-Signature")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-Signature", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Content-Sha256", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-Date")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-Date", valid_611262
  var valid_611263 = header.getOrDefault("X-Amz-Credential")
  valid_611263 = validateParameter(valid_611263, JString, required = false,
                                 default = nil)
  if valid_611263 != nil:
    section.add "X-Amz-Credential", valid_611263
  var valid_611264 = header.getOrDefault("X-Amz-Security-Token")
  valid_611264 = validateParameter(valid_611264, JString, required = false,
                                 default = nil)
  if valid_611264 != nil:
    section.add "X-Amz-Security-Token", valid_611264
  var valid_611265 = header.getOrDefault("X-Amz-Algorithm")
  valid_611265 = validateParameter(valid_611265, JString, required = false,
                                 default = nil)
  if valid_611265 != nil:
    section.add "X-Amz-Algorithm", valid_611265
  var valid_611266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611266 = validateParameter(valid_611266, JString, required = false,
                                 default = nil)
  if valid_611266 != nil:
    section.add "X-Amz-SignedHeaders", valid_611266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611268: Call_DescribeTunnel_611256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a tunnel identified by the unique tunnel id.
  ## 
  let valid = call_611268.validator(path, query, header, formData, body)
  let scheme = call_611268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611268.url(scheme.get, call_611268.host, call_611268.base,
                         call_611268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611268, url, valid)

proc call*(call_611269: Call_DescribeTunnel_611256; body: JsonNode): Recallable =
  ## describeTunnel
  ## Gets information about a tunnel identified by the unique tunnel id.
  ##   body: JObject (required)
  var body_611270 = newJObject()
  if body != nil:
    body_611270 = body
  result = call_611269.call(nil, nil, nil, nil, body_611270)

var describeTunnel* = Call_DescribeTunnel_611256(name: "describeTunnel",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.DescribeTunnel",
    validator: validate_DescribeTunnel_611257, base: "/", url: url_DescribeTunnel_611258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611271 = ref object of OpenApiRestCall_610649
proc url_ListTagsForResource_611273(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_611272(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags for the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611274 = header.getOrDefault("X-Amz-Target")
  valid_611274 = validateParameter(valid_611274, JString, required = true, default = newJString(
      "IoTSecuredTunneling.ListTagsForResource"))
  if valid_611274 != nil:
    section.add "X-Amz-Target", valid_611274
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611283: Call_ListTagsForResource_611271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified resource.
  ## 
  let valid = call_611283.validator(path, query, header, formData, body)
  let scheme = call_611283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611283.url(scheme.get, call_611283.host, call_611283.base,
                         call_611283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611283, url, valid)

proc call*(call_611284: Call_ListTagsForResource_611271; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   body: JObject (required)
  var body_611285 = newJObject()
  if body != nil:
    body_611285 = body
  result = call_611284.call(nil, nil, nil, nil, body_611285)

var listTagsForResource* = Call_ListTagsForResource_611271(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.ListTagsForResource",
    validator: validate_ListTagsForResource_611272, base: "/",
    url: url_ListTagsForResource_611273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTunnels_611286 = ref object of OpenApiRestCall_610649
proc url_ListTunnels_611288(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTunnels_611287(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## List all tunnels for an AWS account. Tunnels are listed by creation time in descending order, newer tunnels will be listed before older tunnels.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_611289 = query.getOrDefault("nextToken")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "nextToken", valid_611289
  var valid_611290 = query.getOrDefault("maxResults")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "maxResults", valid_611290
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611291 = header.getOrDefault("X-Amz-Target")
  valid_611291 = validateParameter(valid_611291, JString, required = true, default = newJString(
      "IoTSecuredTunneling.ListTunnels"))
  if valid_611291 != nil:
    section.add "X-Amz-Target", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Signature")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Signature", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Content-Sha256", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Date")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Date", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Credential")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Credential", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Security-Token")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Security-Token", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Algorithm")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Algorithm", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-SignedHeaders", valid_611298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611300: Call_ListTunnels_611286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tunnels for an AWS account. Tunnels are listed by creation time in descending order, newer tunnels will be listed before older tunnels.
  ## 
  let valid = call_611300.validator(path, query, header, formData, body)
  let scheme = call_611300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611300.url(scheme.get, call_611300.host, call_611300.base,
                         call_611300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611300, url, valid)

proc call*(call_611301: Call_ListTunnels_611286; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTunnels
  ## List all tunnels for an AWS account. Tunnels are listed by creation time in descending order, newer tunnels will be listed before older tunnels.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611302 = newJObject()
  var body_611303 = newJObject()
  add(query_611302, "nextToken", newJString(nextToken))
  if body != nil:
    body_611303 = body
  add(query_611302, "maxResults", newJString(maxResults))
  result = call_611301.call(nil, query_611302, nil, nil, body_611303)

var listTunnels* = Call_ListTunnels_611286(name: "listTunnels",
                                        meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.ListTunnels",
                                        validator: validate_ListTunnels_611287,
                                        base: "/", url: url_ListTunnels_611288,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_OpenTunnel_611305 = ref object of OpenApiRestCall_610649
proc url_OpenTunnel_611307(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_OpenTunnel_611306(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new tunnel, and returns two client access tokens for clients to use to connect to the AWS IoT Secure Tunneling proxy server. .
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611308 = header.getOrDefault("X-Amz-Target")
  valid_611308 = validateParameter(valid_611308, JString, required = true, default = newJString(
      "IoTSecuredTunneling.OpenTunnel"))
  if valid_611308 != nil:
    section.add "X-Amz-Target", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Signature")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Signature", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Content-Sha256", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Date")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Date", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Credential")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Credential", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Security-Token")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Security-Token", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Algorithm")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Algorithm", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-SignedHeaders", valid_611315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611317: Call_OpenTunnel_611305; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new tunnel, and returns two client access tokens for clients to use to connect to the AWS IoT Secure Tunneling proxy server. .
  ## 
  let valid = call_611317.validator(path, query, header, formData, body)
  let scheme = call_611317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611317.url(scheme.get, call_611317.host, call_611317.base,
                         call_611317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611317, url, valid)

proc call*(call_611318: Call_OpenTunnel_611305; body: JsonNode): Recallable =
  ## openTunnel
  ## Creates a new tunnel, and returns two client access tokens for clients to use to connect to the AWS IoT Secure Tunneling proxy server. .
  ##   body: JObject (required)
  var body_611319 = newJObject()
  if body != nil:
    body_611319 = body
  result = call_611318.call(nil, nil, nil, nil, body_611319)

var openTunnel* = Call_OpenTunnel_611305(name: "openTunnel",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.OpenTunnel",
                                      validator: validate_OpenTunnel_611306,
                                      base: "/", url: url_OpenTunnel_611307,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611320 = ref object of OpenApiRestCall_610649
proc url_TagResource_611322(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_611321(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## A resource tag.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611323 = header.getOrDefault("X-Amz-Target")
  valid_611323 = validateParameter(valid_611323, JString, required = true, default = newJString(
      "IoTSecuredTunneling.TagResource"))
  if valid_611323 != nil:
    section.add "X-Amz-Target", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Signature")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Signature", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Content-Sha256", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Date")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Date", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Credential")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Credential", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Security-Token")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Security-Token", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Algorithm")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Algorithm", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-SignedHeaders", valid_611330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611332: Call_TagResource_611320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A resource tag.
  ## 
  let valid = call_611332.validator(path, query, header, formData, body)
  let scheme = call_611332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611332.url(scheme.get, call_611332.host, call_611332.base,
                         call_611332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611332, url, valid)

proc call*(call_611333: Call_TagResource_611320; body: JsonNode): Recallable =
  ## tagResource
  ## A resource tag.
  ##   body: JObject (required)
  var body_611334 = newJObject()
  if body != nil:
    body_611334 = body
  result = call_611333.call(nil, nil, nil, nil, body_611334)

var tagResource* = Call_TagResource_611320(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.TagResource",
                                        validator: validate_TagResource_611321,
                                        base: "/", url: url_TagResource_611322,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611335 = ref object of OpenApiRestCall_610649
proc url_UntagResource_611337(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_611336(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a tag from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611338 = header.getOrDefault("X-Amz-Target")
  valid_611338 = validateParameter(valid_611338, JString, required = true, default = newJString(
      "IoTSecuredTunneling.UntagResource"))
  if valid_611338 != nil:
    section.add "X-Amz-Target", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Signature")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Signature", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Content-Sha256", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Date")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Date", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Credential")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Credential", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Security-Token")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Security-Token", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Algorithm")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Algorithm", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-SignedHeaders", valid_611345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611347: Call_UntagResource_611335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a resource.
  ## 
  let valid = call_611347.validator(path, query, header, formData, body)
  let scheme = call_611347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611347.url(scheme.get, call_611347.host, call_611347.base,
                         call_611347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611347, url, valid)

proc call*(call_611348: Call_UntagResource_611335; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a resource.
  ##   body: JObject (required)
  var body_611349 = newJObject()
  if body != nil:
    body_611349 = body
  result = call_611348.call(nil, nil, nil, nil, body_611349)

var untagResource* = Call_UntagResource_611335(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.UntagResource",
    validator: validate_UntagResource_611336, base: "/", url: url_UntagResource_611337,
    schemes: {Scheme.Https, Scheme.Http})
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
