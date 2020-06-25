
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625426): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CloseTunnel_21625770 = ref object of OpenApiRestCall_21625426
proc url_CloseTunnel_21625772(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CloseTunnel_21625771(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Closes a tunnel identified by the unique tunnel id. When a <code>CloseTunnel</code> request is received, we close the WebSocket connections between the client and proxy server so no data can be transmitted.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625873 = header.getOrDefault("X-Amz-Date")
  valid_21625873 = validateParameter(valid_21625873, JString, required = false,
                                   default = nil)
  if valid_21625873 != nil:
    section.add "X-Amz-Date", valid_21625873
  var valid_21625874 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625874 = validateParameter(valid_21625874, JString, required = false,
                                   default = nil)
  if valid_21625874 != nil:
    section.add "X-Amz-Security-Token", valid_21625874
  var valid_21625889 = header.getOrDefault("X-Amz-Target")
  valid_21625889 = validateParameter(valid_21625889, JString, required = true, default = newJString(
      "IoTSecuredTunneling.CloseTunnel"))
  if valid_21625889 != nil:
    section.add "X-Amz-Target", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-Algorithm", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-Signature")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-Signature", valid_21625892
  var valid_21625893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625893 = validateParameter(valid_21625893, JString, required = false,
                                   default = nil)
  if valid_21625893 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625893
  var valid_21625894 = header.getOrDefault("X-Amz-Credential")
  valid_21625894 = validateParameter(valid_21625894, JString, required = false,
                                   default = nil)
  if valid_21625894 != nil:
    section.add "X-Amz-Credential", valid_21625894
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

proc call*(call_21625920: Call_CloseTunnel_21625770; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Closes a tunnel identified by the unique tunnel id. When a <code>CloseTunnel</code> request is received, we close the WebSocket connections between the client and proxy server so no data can be transmitted.
  ## 
  let valid = call_21625920.validator(path, query, header, formData, body, _)
  let scheme = call_21625920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625920.makeUrl(scheme.get, call_21625920.host, call_21625920.base,
                               call_21625920.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625920, uri, valid, _)

proc call*(call_21625983: Call_CloseTunnel_21625770; body: JsonNode): Recallable =
  ## closeTunnel
  ## Closes a tunnel identified by the unique tunnel id. When a <code>CloseTunnel</code> request is received, we close the WebSocket connections between the client and proxy server so no data can be transmitted.
  ##   body: JObject (required)
  var body_21625984 = newJObject()
  if body != nil:
    body_21625984 = body
  result = call_21625983.call(nil, nil, nil, nil, body_21625984)

var closeTunnel* = Call_CloseTunnel_21625770(name: "closeTunnel",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.CloseTunnel",
    validator: validate_CloseTunnel_21625771, base: "/", makeUrl: url_CloseTunnel_21625772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTunnel_21626020 = ref object of OpenApiRestCall_21625426
proc url_DescribeTunnel_21626022(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTunnel_21626021(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about a tunnel identified by the unique tunnel id.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626023 = header.getOrDefault("X-Amz-Date")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Date", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Security-Token", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Target")
  valid_21626025 = validateParameter(valid_21626025, JString, required = true, default = newJString(
      "IoTSecuredTunneling.DescribeTunnel"))
  if valid_21626025 != nil:
    section.add "X-Amz-Target", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Algorithm", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Signature")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Signature", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-Credential")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Credential", valid_21626030
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

proc call*(call_21626032: Call_DescribeTunnel_21626020; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a tunnel identified by the unique tunnel id.
  ## 
  let valid = call_21626032.validator(path, query, header, formData, body, _)
  let scheme = call_21626032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626032.makeUrl(scheme.get, call_21626032.host, call_21626032.base,
                               call_21626032.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626032, uri, valid, _)

proc call*(call_21626033: Call_DescribeTunnel_21626020; body: JsonNode): Recallable =
  ## describeTunnel
  ## Gets information about a tunnel identified by the unique tunnel id.
  ##   body: JObject (required)
  var body_21626034 = newJObject()
  if body != nil:
    body_21626034 = body
  result = call_21626033.call(nil, nil, nil, nil, body_21626034)

var describeTunnel* = Call_DescribeTunnel_21626020(name: "describeTunnel",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.DescribeTunnel",
    validator: validate_DescribeTunnel_21626021, base: "/",
    makeUrl: url_DescribeTunnel_21626022, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626035 = ref object of OpenApiRestCall_21625426
proc url_ListTagsForResource_21626037(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626036(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the tags for the specified resource.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626038 = header.getOrDefault("X-Amz-Date")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Date", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Security-Token", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Target")
  valid_21626040 = validateParameter(valid_21626040, JString, required = true, default = newJString(
      "IoTSecuredTunneling.ListTagsForResource"))
  if valid_21626040 != nil:
    section.add "X-Amz-Target", valid_21626040
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626047: Call_ListTagsForResource_21626035; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags for the specified resource.
  ## 
  let valid = call_21626047.validator(path, query, header, formData, body, _)
  let scheme = call_21626047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626047.makeUrl(scheme.get, call_21626047.host, call_21626047.base,
                               call_21626047.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626047, uri, valid, _)

proc call*(call_21626048: Call_ListTagsForResource_21626035; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   body: JObject (required)
  var body_21626049 = newJObject()
  if body != nil:
    body_21626049 = body
  result = call_21626048.call(nil, nil, nil, nil, body_21626049)

var listTagsForResource* = Call_ListTagsForResource_21626035(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.ListTagsForResource",
    validator: validate_ListTagsForResource_21626036, base: "/",
    makeUrl: url_ListTagsForResource_21626037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTunnels_21626050 = ref object of OpenApiRestCall_21625426
proc url_ListTunnels_21626052(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTunnels_21626051(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List all tunnels for an AWS account. Tunnels are listed by creation time in descending order, newer tunnels will be listed before older tunnels.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626053 = query.getOrDefault("maxResults")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "maxResults", valid_21626053
  var valid_21626054 = query.getOrDefault("nextToken")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "nextToken", valid_21626054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626055 = header.getOrDefault("X-Amz-Date")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Date", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Security-Token", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Target")
  valid_21626057 = validateParameter(valid_21626057, JString, required = true, default = newJString(
      "IoTSecuredTunneling.ListTunnels"))
  if valid_21626057 != nil:
    section.add "X-Amz-Target", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Algorithm", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Signature")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Signature", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Credential")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Credential", valid_21626062
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

proc call*(call_21626064: Call_ListTunnels_21626050; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List all tunnels for an AWS account. Tunnels are listed by creation time in descending order, newer tunnels will be listed before older tunnels.
  ## 
  let valid = call_21626064.validator(path, query, header, formData, body, _)
  let scheme = call_21626064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626064.makeUrl(scheme.get, call_21626064.host, call_21626064.base,
                               call_21626064.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626064, uri, valid, _)

proc call*(call_21626065: Call_ListTunnels_21626050; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listTunnels
  ## List all tunnels for an AWS account. Tunnels are listed by creation time in descending order, newer tunnels will be listed before older tunnels.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626067 = newJObject()
  var body_21626068 = newJObject()
  add(query_21626067, "maxResults", newJString(maxResults))
  add(query_21626067, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626068 = body
  result = call_21626065.call(nil, query_21626067, nil, nil, body_21626068)

var listTunnels* = Call_ListTunnels_21626050(name: "listTunnels",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.ListTunnels",
    validator: validate_ListTunnels_21626051, base: "/", makeUrl: url_ListTunnels_21626052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_OpenTunnel_21626072 = ref object of OpenApiRestCall_21625426
proc url_OpenTunnel_21626074(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_OpenTunnel_21626073(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new tunnel, and returns two client access tokens for clients to use to connect to the AWS IoT Secure Tunneling proxy server. .
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626075 = header.getOrDefault("X-Amz-Date")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Date", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Security-Token", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Target")
  valid_21626077 = validateParameter(valid_21626077, JString, required = true, default = newJString(
      "IoTSecuredTunneling.OpenTunnel"))
  if valid_21626077 != nil:
    section.add "X-Amz-Target", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Algorithm", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Signature")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Signature", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Credential")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Credential", valid_21626082
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

proc call*(call_21626084: Call_OpenTunnel_21626072; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new tunnel, and returns two client access tokens for clients to use to connect to the AWS IoT Secure Tunneling proxy server. .
  ## 
  let valid = call_21626084.validator(path, query, header, formData, body, _)
  let scheme = call_21626084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626084.makeUrl(scheme.get, call_21626084.host, call_21626084.base,
                               call_21626084.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626084, uri, valid, _)

proc call*(call_21626085: Call_OpenTunnel_21626072; body: JsonNode): Recallable =
  ## openTunnel
  ## Creates a new tunnel, and returns two client access tokens for clients to use to connect to the AWS IoT Secure Tunneling proxy server. .
  ##   body: JObject (required)
  var body_21626086 = newJObject()
  if body != nil:
    body_21626086 = body
  result = call_21626085.call(nil, nil, nil, nil, body_21626086)

var openTunnel* = Call_OpenTunnel_21626072(name: "openTunnel",
                                        meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com", route: "/#X-Amz-Target=IoTSecuredTunneling.OpenTunnel",
                                        validator: validate_OpenTunnel_21626073,
                                        base: "/", makeUrl: url_OpenTunnel_21626074,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626087 = ref object of OpenApiRestCall_21625426
proc url_TagResource_21626089(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21626088(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## A resource tag.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626090 = header.getOrDefault("X-Amz-Date")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Date", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Security-Token", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Target")
  valid_21626092 = validateParameter(valid_21626092, JString, required = true, default = newJString(
      "IoTSecuredTunneling.TagResource"))
  if valid_21626092 != nil:
    section.add "X-Amz-Target", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Algorithm", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Signature")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Signature", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Credential")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Credential", valid_21626097
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

proc call*(call_21626099: Call_TagResource_21626087; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## A resource tag.
  ## 
  let valid = call_21626099.validator(path, query, header, formData, body, _)
  let scheme = call_21626099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626099.makeUrl(scheme.get, call_21626099.host, call_21626099.base,
                               call_21626099.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626099, uri, valid, _)

proc call*(call_21626100: Call_TagResource_21626087; body: JsonNode): Recallable =
  ## tagResource
  ## A resource tag.
  ##   body: JObject (required)
  var body_21626101 = newJObject()
  if body != nil:
    body_21626101 = body
  result = call_21626100.call(nil, nil, nil, nil, body_21626101)

var tagResource* = Call_TagResource_21626087(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.TagResource",
    validator: validate_TagResource_21626088, base: "/", makeUrl: url_TagResource_21626089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626102 = ref object of OpenApiRestCall_21625426
proc url_UntagResource_21626104(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21626103(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes a tag from a resource.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626105 = header.getOrDefault("X-Amz-Date")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Date", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Security-Token", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-Target")
  valid_21626107 = validateParameter(valid_21626107, JString, required = true, default = newJString(
      "IoTSecuredTunneling.UntagResource"))
  if valid_21626107 != nil:
    section.add "X-Amz-Target", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Algorithm", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Signature")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Signature", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Credential")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Credential", valid_21626112
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

proc call*(call_21626114: Call_UntagResource_21626102; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a tag from a resource.
  ## 
  let valid = call_21626114.validator(path, query, header, formData, body, _)
  let scheme = call_21626114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626114.makeUrl(scheme.get, call_21626114.host, call_21626114.base,
                               call_21626114.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626114, uri, valid, _)

proc call*(call_21626115: Call_UntagResource_21626102; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a resource.
  ##   body: JObject (required)
  var body_21626116 = newJObject()
  if body != nil:
    body_21626116 = body
  result = call_21626115.call(nil, nil, nil, nil, body_21626116)

var untagResource* = Call_UntagResource_21626102(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.UntagResource",
    validator: validate_UntagResource_21626103, base: "/",
    makeUrl: url_UntagResource_21626104, schemes: {Scheme.Https, Scheme.Http})
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