
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

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
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
  Call_CloseTunnel_605918 = ref object of OpenApiRestCall_605580
proc url_CloseTunnel_605920(protocol: Scheme; host: string; base: string;
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

proc validate_CloseTunnel_605919(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606045 = header.getOrDefault("X-Amz-Target")
  valid_606045 = validateParameter(valid_606045, JString, required = true, default = newJString(
      "IoTSecuredTunneling.CloseTunnel"))
  if valid_606045 != nil:
    section.add "X-Amz-Target", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Signature")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Signature", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Content-Sha256", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Date")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Date", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Credential")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Credential", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Security-Token")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Security-Token", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-Algorithm")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-Algorithm", valid_606051
  var valid_606052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606052 = validateParameter(valid_606052, JString, required = false,
                                 default = nil)
  if valid_606052 != nil:
    section.add "X-Amz-SignedHeaders", valid_606052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606076: Call_CloseTunnel_605918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Closes a tunnel identified by the unique tunnel id. When a <code>CloseTunnel</code> request is received, we close the WebSocket connections between the client and proxy server so no data can be transmitted.
  ## 
  let valid = call_606076.validator(path, query, header, formData, body)
  let scheme = call_606076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606076.url(scheme.get, call_606076.host, call_606076.base,
                         call_606076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606076, url, valid)

proc call*(call_606147: Call_CloseTunnel_605918; body: JsonNode): Recallable =
  ## closeTunnel
  ## Closes a tunnel identified by the unique tunnel id. When a <code>CloseTunnel</code> request is received, we close the WebSocket connections between the client and proxy server so no data can be transmitted.
  ##   body: JObject (required)
  var body_606148 = newJObject()
  if body != nil:
    body_606148 = body
  result = call_606147.call(nil, nil, nil, nil, body_606148)

var closeTunnel* = Call_CloseTunnel_605918(name: "closeTunnel",
                                        meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.CloseTunnel",
                                        validator: validate_CloseTunnel_605919,
                                        base: "/", url: url_CloseTunnel_605920,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTunnel_606187 = ref object of OpenApiRestCall_605580
proc url_DescribeTunnel_606189(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTunnel_606188(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606190 = header.getOrDefault("X-Amz-Target")
  valid_606190 = validateParameter(valid_606190, JString, required = true, default = newJString(
      "IoTSecuredTunneling.DescribeTunnel"))
  if valid_606190 != nil:
    section.add "X-Amz-Target", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Signature")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Signature", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Content-Sha256", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Date")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Date", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-Credential")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-Credential", valid_606194
  var valid_606195 = header.getOrDefault("X-Amz-Security-Token")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "X-Amz-Security-Token", valid_606195
  var valid_606196 = header.getOrDefault("X-Amz-Algorithm")
  valid_606196 = validateParameter(valid_606196, JString, required = false,
                                 default = nil)
  if valid_606196 != nil:
    section.add "X-Amz-Algorithm", valid_606196
  var valid_606197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606197 = validateParameter(valid_606197, JString, required = false,
                                 default = nil)
  if valid_606197 != nil:
    section.add "X-Amz-SignedHeaders", valid_606197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606199: Call_DescribeTunnel_606187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a tunnel identified by the unique tunnel id.
  ## 
  let valid = call_606199.validator(path, query, header, formData, body)
  let scheme = call_606199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606199.url(scheme.get, call_606199.host, call_606199.base,
                         call_606199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606199, url, valid)

proc call*(call_606200: Call_DescribeTunnel_606187; body: JsonNode): Recallable =
  ## describeTunnel
  ## Gets information about a tunnel identified by the unique tunnel id.
  ##   body: JObject (required)
  var body_606201 = newJObject()
  if body != nil:
    body_606201 = body
  result = call_606200.call(nil, nil, nil, nil, body_606201)

var describeTunnel* = Call_DescribeTunnel_606187(name: "describeTunnel",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.DescribeTunnel",
    validator: validate_DescribeTunnel_606188, base: "/", url: url_DescribeTunnel_606189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606202 = ref object of OpenApiRestCall_605580
proc url_ListTagsForResource_606204(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606203(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606205 = header.getOrDefault("X-Amz-Target")
  valid_606205 = validateParameter(valid_606205, JString, required = true, default = newJString(
      "IoTSecuredTunneling.ListTagsForResource"))
  if valid_606205 != nil:
    section.add "X-Amz-Target", valid_606205
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606214: Call_ListTagsForResource_606202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified resource.
  ## 
  let valid = call_606214.validator(path, query, header, formData, body)
  let scheme = call_606214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606214.url(scheme.get, call_606214.host, call_606214.base,
                         call_606214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606214, url, valid)

proc call*(call_606215: Call_ListTagsForResource_606202; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   body: JObject (required)
  var body_606216 = newJObject()
  if body != nil:
    body_606216 = body
  result = call_606215.call(nil, nil, nil, nil, body_606216)

var listTagsForResource* = Call_ListTagsForResource_606202(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.ListTagsForResource",
    validator: validate_ListTagsForResource_606203, base: "/",
    url: url_ListTagsForResource_606204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTunnels_606217 = ref object of OpenApiRestCall_605580
proc url_ListTunnels_606219(protocol: Scheme; host: string; base: string;
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

proc validate_ListTunnels_606218(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606220 = query.getOrDefault("nextToken")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "nextToken", valid_606220
  var valid_606221 = query.getOrDefault("maxResults")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "maxResults", valid_606221
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606222 = header.getOrDefault("X-Amz-Target")
  valid_606222 = validateParameter(valid_606222, JString, required = true, default = newJString(
      "IoTSecuredTunneling.ListTunnels"))
  if valid_606222 != nil:
    section.add "X-Amz-Target", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Signature")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Signature", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Content-Sha256", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Date")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Date", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Credential")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Credential", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Security-Token")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Security-Token", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Algorithm")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Algorithm", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-SignedHeaders", valid_606229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606231: Call_ListTunnels_606217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tunnels for an AWS account. Tunnels are listed by creation time in descending order, newer tunnels will be listed before older tunnels.
  ## 
  let valid = call_606231.validator(path, query, header, formData, body)
  let scheme = call_606231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606231.url(scheme.get, call_606231.host, call_606231.base,
                         call_606231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606231, url, valid)

proc call*(call_606232: Call_ListTunnels_606217; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTunnels
  ## List all tunnels for an AWS account. Tunnels are listed by creation time in descending order, newer tunnels will be listed before older tunnels.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606233 = newJObject()
  var body_606234 = newJObject()
  add(query_606233, "nextToken", newJString(nextToken))
  if body != nil:
    body_606234 = body
  add(query_606233, "maxResults", newJString(maxResults))
  result = call_606232.call(nil, query_606233, nil, nil, body_606234)

var listTunnels* = Call_ListTunnels_606217(name: "listTunnels",
                                        meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.ListTunnels",
                                        validator: validate_ListTunnels_606218,
                                        base: "/", url: url_ListTunnels_606219,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_OpenTunnel_606236 = ref object of OpenApiRestCall_605580
proc url_OpenTunnel_606238(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_OpenTunnel_606237(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606239 = header.getOrDefault("X-Amz-Target")
  valid_606239 = validateParameter(valid_606239, JString, required = true, default = newJString(
      "IoTSecuredTunneling.OpenTunnel"))
  if valid_606239 != nil:
    section.add "X-Amz-Target", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Signature")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Signature", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Content-Sha256", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Date")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Date", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Credential")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Credential", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Security-Token")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Security-Token", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Algorithm")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Algorithm", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-SignedHeaders", valid_606246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606248: Call_OpenTunnel_606236; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new tunnel, and returns two client access tokens for clients to use to connect to the AWS IoT Secure Tunneling proxy server. .
  ## 
  let valid = call_606248.validator(path, query, header, formData, body)
  let scheme = call_606248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606248.url(scheme.get, call_606248.host, call_606248.base,
                         call_606248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606248, url, valid)

proc call*(call_606249: Call_OpenTunnel_606236; body: JsonNode): Recallable =
  ## openTunnel
  ## Creates a new tunnel, and returns two client access tokens for clients to use to connect to the AWS IoT Secure Tunneling proxy server. .
  ##   body: JObject (required)
  var body_606250 = newJObject()
  if body != nil:
    body_606250 = body
  result = call_606249.call(nil, nil, nil, nil, body_606250)

var openTunnel* = Call_OpenTunnel_606236(name: "openTunnel",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.OpenTunnel",
                                      validator: validate_OpenTunnel_606237,
                                      base: "/", url: url_OpenTunnel_606238,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606251 = ref object of OpenApiRestCall_605580
proc url_TagResource_606253(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606254 = header.getOrDefault("X-Amz-Target")
  valid_606254 = validateParameter(valid_606254, JString, required = true, default = newJString(
      "IoTSecuredTunneling.TagResource"))
  if valid_606254 != nil:
    section.add "X-Amz-Target", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Signature")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Signature", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Content-Sha256", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Date")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Date", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Credential")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Credential", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Security-Token")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Security-Token", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Algorithm")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Algorithm", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-SignedHeaders", valid_606261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606263: Call_TagResource_606251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A resource tag.
  ## 
  let valid = call_606263.validator(path, query, header, formData, body)
  let scheme = call_606263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606263.url(scheme.get, call_606263.host, call_606263.base,
                         call_606263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606263, url, valid)

proc call*(call_606264: Call_TagResource_606251; body: JsonNode): Recallable =
  ## tagResource
  ## A resource tag.
  ##   body: JObject (required)
  var body_606265 = newJObject()
  if body != nil:
    body_606265 = body
  result = call_606264.call(nil, nil, nil, nil, body_606265)

var tagResource* = Call_TagResource_606251(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.TagResource",
                                        validator: validate_TagResource_606252,
                                        base: "/", url: url_TagResource_606253,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606266 = ref object of OpenApiRestCall_605580
proc url_UntagResource_606268(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606267(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606269 = header.getOrDefault("X-Amz-Target")
  valid_606269 = validateParameter(valid_606269, JString, required = true, default = newJString(
      "IoTSecuredTunneling.UntagResource"))
  if valid_606269 != nil:
    section.add "X-Amz-Target", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Signature")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Signature", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Content-Sha256", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Date")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Date", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Credential")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Credential", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Security-Token")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Security-Token", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Algorithm")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Algorithm", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-SignedHeaders", valid_606276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606278: Call_UntagResource_606266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a resource.
  ## 
  let valid = call_606278.validator(path, query, header, formData, body)
  let scheme = call_606278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606278.url(scheme.get, call_606278.host, call_606278.base,
                         call_606278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606278, url, valid)

proc call*(call_606279: Call_UntagResource_606266; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a resource.
  ##   body: JObject (required)
  var body_606280 = newJObject()
  if body != nil:
    body_606280 = body
  result = call_606279.call(nil, nil, nil, nil, body_606280)

var untagResource* = Call_UntagResource_606266(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.UntagResource",
    validator: validate_UntagResource_606267, base: "/", url: url_UntagResource_606268,
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