
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

  OpenApiRestCall_601380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601380): Option[Scheme] {.used.} =
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
  Call_CloseTunnel_601718 = ref object of OpenApiRestCall_601380
proc url_CloseTunnel_601720(protocol: Scheme; host: string; base: string;
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

proc validate_CloseTunnel_601719(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601845 = header.getOrDefault("X-Amz-Target")
  valid_601845 = validateParameter(valid_601845, JString, required = true, default = newJString(
      "IoTSecuredTunneling.CloseTunnel"))
  if valid_601845 != nil:
    section.add "X-Amz-Target", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Signature")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Signature", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Content-Sha256", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Date")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Date", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Credential")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Credential", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Security-Token")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Security-Token", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Algorithm")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Algorithm", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-SignedHeaders", valid_601852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601876: Call_CloseTunnel_601718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Closes a tunnel identified by the unique tunnel id. When a <code>CloseTunnel</code> request is received, we close the WebSocket connections between the client and proxy server so no data can be transmitted.
  ## 
  let valid = call_601876.validator(path, query, header, formData, body)
  let scheme = call_601876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601876.url(scheme.get, call_601876.host, call_601876.base,
                         call_601876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601876, url, valid)

proc call*(call_601947: Call_CloseTunnel_601718; body: JsonNode): Recallable =
  ## closeTunnel
  ## Closes a tunnel identified by the unique tunnel id. When a <code>CloseTunnel</code> request is received, we close the WebSocket connections between the client and proxy server so no data can be transmitted.
  ##   body: JObject (required)
  var body_601948 = newJObject()
  if body != nil:
    body_601948 = body
  result = call_601947.call(nil, nil, nil, nil, body_601948)

var closeTunnel* = Call_CloseTunnel_601718(name: "closeTunnel",
                                        meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.CloseTunnel",
                                        validator: validate_CloseTunnel_601719,
                                        base: "/", url: url_CloseTunnel_601720,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTunnel_601987 = ref object of OpenApiRestCall_601380
proc url_DescribeTunnel_601989(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTunnel_601988(path: JsonNode; query: JsonNode;
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
  var valid_601990 = header.getOrDefault("X-Amz-Target")
  valid_601990 = validateParameter(valid_601990, JString, required = true, default = newJString(
      "IoTSecuredTunneling.DescribeTunnel"))
  if valid_601990 != nil:
    section.add "X-Amz-Target", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Signature")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Signature", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Content-Sha256", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Date")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Date", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Credential")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Credential", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-Security-Token")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-Security-Token", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Algorithm")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Algorithm", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-SignedHeaders", valid_601997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601999: Call_DescribeTunnel_601987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a tunnel identified by the unique tunnel id.
  ## 
  let valid = call_601999.validator(path, query, header, formData, body)
  let scheme = call_601999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601999.url(scheme.get, call_601999.host, call_601999.base,
                         call_601999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601999, url, valid)

proc call*(call_602000: Call_DescribeTunnel_601987; body: JsonNode): Recallable =
  ## describeTunnel
  ## Gets information about a tunnel identified by the unique tunnel id.
  ##   body: JObject (required)
  var body_602001 = newJObject()
  if body != nil:
    body_602001 = body
  result = call_602000.call(nil, nil, nil, nil, body_602001)

var describeTunnel* = Call_DescribeTunnel_601987(name: "describeTunnel",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.DescribeTunnel",
    validator: validate_DescribeTunnel_601988, base: "/", url: url_DescribeTunnel_601989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602002 = ref object of OpenApiRestCall_601380
proc url_ListTagsForResource_602004(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602003(path: JsonNode; query: JsonNode;
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
  var valid_602005 = header.getOrDefault("X-Amz-Target")
  valid_602005 = validateParameter(valid_602005, JString, required = true, default = newJString(
      "IoTSecuredTunneling.ListTagsForResource"))
  if valid_602005 != nil:
    section.add "X-Amz-Target", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Signature")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Signature", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Content-Sha256", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Date")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Date", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Credential")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Credential", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Security-Token")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Security-Token", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Algorithm")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Algorithm", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-SignedHeaders", valid_602012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602014: Call_ListTagsForResource_602002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified resource.
  ## 
  let valid = call_602014.validator(path, query, header, formData, body)
  let scheme = call_602014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602014.url(scheme.get, call_602014.host, call_602014.base,
                         call_602014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602014, url, valid)

proc call*(call_602015: Call_ListTagsForResource_602002; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   body: JObject (required)
  var body_602016 = newJObject()
  if body != nil:
    body_602016 = body
  result = call_602015.call(nil, nil, nil, nil, body_602016)

var listTagsForResource* = Call_ListTagsForResource_602002(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.ListTagsForResource",
    validator: validate_ListTagsForResource_602003, base: "/",
    url: url_ListTagsForResource_602004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTunnels_602017 = ref object of OpenApiRestCall_601380
proc url_ListTunnels_602019(protocol: Scheme; host: string; base: string;
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

proc validate_ListTunnels_602018(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602020 = query.getOrDefault("nextToken")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "nextToken", valid_602020
  var valid_602021 = query.getOrDefault("maxResults")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "maxResults", valid_602021
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
  var valid_602022 = header.getOrDefault("X-Amz-Target")
  valid_602022 = validateParameter(valid_602022, JString, required = true, default = newJString(
      "IoTSecuredTunneling.ListTunnels"))
  if valid_602022 != nil:
    section.add "X-Amz-Target", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Signature")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Signature", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Content-Sha256", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Date")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Date", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Credential")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Credential", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Security-Token")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Security-Token", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Algorithm")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Algorithm", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-SignedHeaders", valid_602029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602031: Call_ListTunnels_602017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tunnels for an AWS account. Tunnels are listed by creation time in descending order, newer tunnels will be listed before older tunnels.
  ## 
  let valid = call_602031.validator(path, query, header, formData, body)
  let scheme = call_602031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602031.url(scheme.get, call_602031.host, call_602031.base,
                         call_602031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602031, url, valid)

proc call*(call_602032: Call_ListTunnels_602017; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTunnels
  ## List all tunnels for an AWS account. Tunnels are listed by creation time in descending order, newer tunnels will be listed before older tunnels.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602033 = newJObject()
  var body_602034 = newJObject()
  add(query_602033, "nextToken", newJString(nextToken))
  if body != nil:
    body_602034 = body
  add(query_602033, "maxResults", newJString(maxResults))
  result = call_602032.call(nil, query_602033, nil, nil, body_602034)

var listTunnels* = Call_ListTunnels_602017(name: "listTunnels",
                                        meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.ListTunnels",
                                        validator: validate_ListTunnels_602018,
                                        base: "/", url: url_ListTunnels_602019,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_OpenTunnel_602036 = ref object of OpenApiRestCall_601380
proc url_OpenTunnel_602038(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_OpenTunnel_602037(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602039 = header.getOrDefault("X-Amz-Target")
  valid_602039 = validateParameter(valid_602039, JString, required = true, default = newJString(
      "IoTSecuredTunneling.OpenTunnel"))
  if valid_602039 != nil:
    section.add "X-Amz-Target", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Signature")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Signature", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Content-Sha256", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Date")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Date", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Credential")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Credential", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Security-Token")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Security-Token", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Algorithm")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Algorithm", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-SignedHeaders", valid_602046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602048: Call_OpenTunnel_602036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new tunnel, and returns two client access tokens for clients to use to connect to the AWS IoT Secure Tunneling proxy server. .
  ## 
  let valid = call_602048.validator(path, query, header, formData, body)
  let scheme = call_602048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602048.url(scheme.get, call_602048.host, call_602048.base,
                         call_602048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602048, url, valid)

proc call*(call_602049: Call_OpenTunnel_602036; body: JsonNode): Recallable =
  ## openTunnel
  ## Creates a new tunnel, and returns two client access tokens for clients to use to connect to the AWS IoT Secure Tunneling proxy server. .
  ##   body: JObject (required)
  var body_602050 = newJObject()
  if body != nil:
    body_602050 = body
  result = call_602049.call(nil, nil, nil, nil, body_602050)

var openTunnel* = Call_OpenTunnel_602036(name: "openTunnel",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.OpenTunnel",
                                      validator: validate_OpenTunnel_602037,
                                      base: "/", url: url_OpenTunnel_602038,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602051 = ref object of OpenApiRestCall_601380
proc url_TagResource_602053(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602052(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602054 = header.getOrDefault("X-Amz-Target")
  valid_602054 = validateParameter(valid_602054, JString, required = true, default = newJString(
      "IoTSecuredTunneling.TagResource"))
  if valid_602054 != nil:
    section.add "X-Amz-Target", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Signature")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Signature", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Content-Sha256", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Date")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Date", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Credential")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Credential", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Security-Token")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Security-Token", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Algorithm")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Algorithm", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-SignedHeaders", valid_602061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602063: Call_TagResource_602051; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A resource tag.
  ## 
  let valid = call_602063.validator(path, query, header, formData, body)
  let scheme = call_602063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602063.url(scheme.get, call_602063.host, call_602063.base,
                         call_602063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602063, url, valid)

proc call*(call_602064: Call_TagResource_602051; body: JsonNode): Recallable =
  ## tagResource
  ## A resource tag.
  ##   body: JObject (required)
  var body_602065 = newJObject()
  if body != nil:
    body_602065 = body
  result = call_602064.call(nil, nil, nil, nil, body_602065)

var tagResource* = Call_TagResource_602051(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.TagResource",
                                        validator: validate_TagResource_602052,
                                        base: "/", url: url_TagResource_602053,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602066 = ref object of OpenApiRestCall_601380
proc url_UntagResource_602068(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602067(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602069 = header.getOrDefault("X-Amz-Target")
  valid_602069 = validateParameter(valid_602069, JString, required = true, default = newJString(
      "IoTSecuredTunneling.UntagResource"))
  if valid_602069 != nil:
    section.add "X-Amz-Target", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Signature")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Signature", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Content-Sha256", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Date")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Date", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Credential")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Credential", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Security-Token")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Security-Token", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Algorithm")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Algorithm", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-SignedHeaders", valid_602076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602078: Call_UntagResource_602066; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from a resource.
  ## 
  let valid = call_602078.validator(path, query, header, formData, body)
  let scheme = call_602078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602078.url(scheme.get, call_602078.host, call_602078.base,
                         call_602078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602078, url, valid)

proc call*(call_602079: Call_UntagResource_602066; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a resource.
  ##   body: JObject (required)
  var body_602080 = newJObject()
  if body != nil:
    body_602080 = body
  result = call_602079.call(nil, nil, nil, nil, body_602080)

var untagResource* = Call_UntagResource_602066(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.UntagResource",
    validator: validate_UntagResource_602067, base: "/", url: url_UntagResource_602068,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
