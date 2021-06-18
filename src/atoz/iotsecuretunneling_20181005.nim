
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "api.tunneling.iot.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.tunneling.iot.ap-southeast-1.amazonaws.com", "us-west-2": "api.tunneling.iot.us-west-2.amazonaws.com", "eu-west-2": "api.tunneling.iot.eu-west-2.amazonaws.com", "ap-northeast-3": "api.tunneling.iot.ap-northeast-3.amazonaws.com", "eu-central-1": "api.tunneling.iot.eu-central-1.amazonaws.com", "us-east-2": "api.tunneling.iot.us-east-2.amazonaws.com", "us-east-1": "api.tunneling.iot.us-east-1.amazonaws.com", "cn-northwest-1": "api.tunneling.iot.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "api.tunneling.iot.ap-south-1.amazonaws.com", "eu-north-1": "api.tunneling.iot.eu-north-1.amazonaws.com", "ap-northeast-2": "api.tunneling.iot.ap-northeast-2.amazonaws.com", "us-west-1": "api.tunneling.iot.us-west-1.amazonaws.com", "us-gov-east-1": "api.tunneling.iot.us-gov-east-1.amazonaws.com", "eu-west-3": "api.tunneling.iot.eu-west-3.amazonaws.com", "cn-north-1": "api.tunneling.iot.cn-north-1.amazonaws.com.cn", "sa-east-1": "api.tunneling.iot.sa-east-1.amazonaws.com", "eu-west-1": "api.tunneling.iot.eu-west-1.amazonaws.com", "us-gov-west-1": "api.tunneling.iot.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.tunneling.iot.ap-southeast-2.amazonaws.com", "ca-central-1": "api.tunneling.iot.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CloseTunnel_402656288 = ref object of OpenApiRestCall_402656038
proc url_CloseTunnel_402656290(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CloseTunnel_402656289(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656384 = header.getOrDefault("X-Amz-Target")
  valid_402656384 = validateParameter(valid_402656384, JString, required = true, default = newJString(
      "IoTSecuredTunneling.CloseTunnel"))
  if valid_402656384 != nil:
    section.add "X-Amz-Target", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Security-Token", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Signature")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Signature", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Algorithm", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Date")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Date", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Credential")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Credential", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656391
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

proc call*(call_402656406: Call_CloseTunnel_402656288; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Closes a tunnel identified by the unique tunnel id. When a <code>CloseTunnel</code> request is received, we close the WebSocket connections between the client and proxy server so no data can be transmitted.
                                                                                         ## 
  let valid = call_402656406.validator(path, query, header, formData, body, _)
  let scheme = call_402656406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656406.makeUrl(scheme.get, call_402656406.host, call_402656406.base,
                                   call_402656406.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656406, uri, valid, _)

proc call*(call_402656455: Call_CloseTunnel_402656288; body: JsonNode): Recallable =
  ## closeTunnel
  ## Closes a tunnel identified by the unique tunnel id. When a <code>CloseTunnel</code> request is received, we close the WebSocket connections between the client and proxy server so no data can be transmitted.
  ##   
                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656456 = newJObject()
  if body != nil:
    body_402656456 = body
  result = call_402656455.call(nil, nil, nil, nil, body_402656456)

var closeTunnel* = Call_CloseTunnel_402656288(name: "closeTunnel",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.CloseTunnel",
    validator: validate_CloseTunnel_402656289, base: "/",
    makeUrl: url_CloseTunnel_402656290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTunnel_402656483 = ref object of OpenApiRestCall_402656038
proc url_DescribeTunnel_402656485(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTunnel_402656484(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656486 = header.getOrDefault("X-Amz-Target")
  valid_402656486 = validateParameter(valid_402656486, JString, required = true, default = newJString(
      "IoTSecuredTunneling.DescribeTunnel"))
  if valid_402656486 != nil:
    section.add "X-Amz-Target", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Security-Token", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Signature")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Signature", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Algorithm", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-Date")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Date", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Credential")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Credential", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656493
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

proc call*(call_402656495: Call_DescribeTunnel_402656483; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a tunnel identified by the unique tunnel id.
                                                                                         ## 
  let valid = call_402656495.validator(path, query, header, formData, body, _)
  let scheme = call_402656495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656495.makeUrl(scheme.get, call_402656495.host, call_402656495.base,
                                   call_402656495.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656495, uri, valid, _)

proc call*(call_402656496: Call_DescribeTunnel_402656483; body: JsonNode): Recallable =
  ## describeTunnel
  ## Gets information about a tunnel identified by the unique tunnel id.
  ##   body: JObject 
                                                                        ## (required)
  var body_402656497 = newJObject()
  if body != nil:
    body_402656497 = body
  result = call_402656496.call(nil, nil, nil, nil, body_402656497)

var describeTunnel* = Call_DescribeTunnel_402656483(name: "describeTunnel",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.DescribeTunnel",
    validator: validate_DescribeTunnel_402656484, base: "/",
    makeUrl: url_DescribeTunnel_402656485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656498 = ref object of OpenApiRestCall_402656038
proc url_ListTagsForResource_402656500(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402656499(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656501 = header.getOrDefault("X-Amz-Target")
  valid_402656501 = validateParameter(valid_402656501, JString, required = true, default = newJString(
      "IoTSecuredTunneling.ListTagsForResource"))
  if valid_402656501 != nil:
    section.add "X-Amz-Target", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Security-Token", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Signature")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Signature", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Algorithm", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Date")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Date", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Credential")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Credential", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656508
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

proc call*(call_402656510: Call_ListTagsForResource_402656498;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags for the specified resource.
                                                                                         ## 
  let valid = call_402656510.validator(path, query, header, formData, body, _)
  let scheme = call_402656510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656510.makeUrl(scheme.get, call_402656510.host, call_402656510.base,
                                   call_402656510.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656510, uri, valid, _)

proc call*(call_402656511: Call_ListTagsForResource_402656498; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   body: JObject (required)
  var body_402656512 = newJObject()
  if body != nil:
    body_402656512 = body
  result = call_402656511.call(nil, nil, nil, nil, body_402656512)

var listTagsForResource* = Call_ListTagsForResource_402656498(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.ListTagsForResource",
    validator: validate_ListTagsForResource_402656499, base: "/",
    makeUrl: url_ListTagsForResource_402656500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTunnels_402656513 = ref object of OpenApiRestCall_402656038
proc url_ListTunnels_402656515(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTunnels_402656514(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656516 = query.getOrDefault("maxResults")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "maxResults", valid_402656516
  var valid_402656517 = query.getOrDefault("nextToken")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "nextToken", valid_402656517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656518 = header.getOrDefault("X-Amz-Target")
  valid_402656518 = validateParameter(valid_402656518, JString, required = true, default = newJString(
      "IoTSecuredTunneling.ListTunnels"))
  if valid_402656518 != nil:
    section.add "X-Amz-Target", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Security-Token", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Signature")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Signature", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Algorithm", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Date")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Date", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Credential")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Credential", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656525
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

proc call*(call_402656527: Call_ListTunnels_402656513; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all tunnels for an AWS account. Tunnels are listed by creation time in descending order, newer tunnels will be listed before older tunnels.
                                                                                         ## 
  let valid = call_402656527.validator(path, query, header, formData, body, _)
  let scheme = call_402656527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656527.makeUrl(scheme.get, call_402656527.host, call_402656527.base,
                                   call_402656527.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656527, uri, valid, _)

proc call*(call_402656528: Call_ListTunnels_402656513; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listTunnels
  ## List all tunnels for an AWS account. Tunnels are listed by creation time in descending order, newer tunnels will be listed before older tunnels.
  ##   
                                                                                                                                                     ## maxResults: string
                                                                                                                                                     ##             
                                                                                                                                                     ## : 
                                                                                                                                                     ## Pagination 
                                                                                                                                                     ## limit
  ##   
                                                                                                                                                             ## nextToken: string
                                                                                                                                                             ##            
                                                                                                                                                             ## : 
                                                                                                                                                             ## Pagination 
                                                                                                                                                             ## token
  ##   
                                                                                                                                                                     ## body: JObject (required)
  var query_402656529 = newJObject()
  var body_402656530 = newJObject()
  add(query_402656529, "maxResults", newJString(maxResults))
  add(query_402656529, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656530 = body
  result = call_402656528.call(nil, query_402656529, nil, nil, body_402656530)

var listTunnels* = Call_ListTunnels_402656513(name: "listTunnels",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.ListTunnels",
    validator: validate_ListTunnels_402656514, base: "/",
    makeUrl: url_ListTunnels_402656515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_OpenTunnel_402656531 = ref object of OpenApiRestCall_402656038
proc url_OpenTunnel_402656533(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_OpenTunnel_402656532(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656534 = header.getOrDefault("X-Amz-Target")
  valid_402656534 = validateParameter(valid_402656534, JString, required = true, default = newJString(
      "IoTSecuredTunneling.OpenTunnel"))
  if valid_402656534 != nil:
    section.add "X-Amz-Target", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Security-Token", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Signature")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Signature", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Algorithm", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Date")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Date", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Credential")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Credential", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656541
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

proc call*(call_402656543: Call_OpenTunnel_402656531; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new tunnel, and returns two client access tokens for clients to use to connect to the AWS IoT Secure Tunneling proxy server. .
                                                                                         ## 
  let valid = call_402656543.validator(path, query, header, formData, body, _)
  let scheme = call_402656543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656543.makeUrl(scheme.get, call_402656543.host, call_402656543.base,
                                   call_402656543.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656543, uri, valid, _)

proc call*(call_402656544: Call_OpenTunnel_402656531; body: JsonNode): Recallable =
  ## openTunnel
  ## Creates a new tunnel, and returns two client access tokens for clients to use to connect to the AWS IoT Secure Tunneling proxy server. .
  ##   
                                                                                                                                             ## body: JObject (required)
  var body_402656545 = newJObject()
  if body != nil:
    body_402656545 = body
  result = call_402656544.call(nil, nil, nil, nil, body_402656545)

var openTunnel* = Call_OpenTunnel_402656531(name: "openTunnel",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.OpenTunnel",
    validator: validate_OpenTunnel_402656532, base: "/",
    makeUrl: url_OpenTunnel_402656533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656546 = ref object of OpenApiRestCall_402656038
proc url_TagResource_402656548(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402656547(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656549 = header.getOrDefault("X-Amz-Target")
  valid_402656549 = validateParameter(valid_402656549, JString, required = true, default = newJString(
      "IoTSecuredTunneling.TagResource"))
  if valid_402656549 != nil:
    section.add "X-Amz-Target", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Security-Token", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Signature")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Signature", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Algorithm", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Date")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Date", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Credential")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Credential", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656556
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

proc call*(call_402656558: Call_TagResource_402656546; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ## A resource tag.
                                                                                         ## 
  let valid = call_402656558.validator(path, query, header, formData, body, _)
  let scheme = call_402656558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656558.makeUrl(scheme.get, call_402656558.host, call_402656558.base,
                                   call_402656558.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656558, uri, valid, _)

proc call*(call_402656559: Call_TagResource_402656546; body: JsonNode): Recallable =
  ## tagResource
  ## A resource tag.
  ##   body: JObject (required)
  var body_402656560 = newJObject()
  if body != nil:
    body_402656560 = body
  result = call_402656559.call(nil, nil, nil, nil, body_402656560)

var tagResource* = Call_TagResource_402656546(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.TagResource",
    validator: validate_TagResource_402656547, base: "/",
    makeUrl: url_TagResource_402656548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656561 = ref object of OpenApiRestCall_402656038
proc url_UntagResource_402656563(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402656562(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656564 = header.getOrDefault("X-Amz-Target")
  valid_402656564 = validateParameter(valid_402656564, JString, required = true, default = newJString(
      "IoTSecuredTunneling.UntagResource"))
  if valid_402656564 != nil:
    section.add "X-Amz-Target", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Security-Token", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Signature")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Signature", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Algorithm", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Date")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Date", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Credential")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Credential", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656571
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

proc call*(call_402656573: Call_UntagResource_402656561; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a tag from a resource.
                                                                                         ## 
  let valid = call_402656573.validator(path, query, header, formData, body, _)
  let scheme = call_402656573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656573.makeUrl(scheme.get, call_402656573.host, call_402656573.base,
                                   call_402656573.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656573, uri, valid, _)

proc call*(call_402656574: Call_UntagResource_402656561; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from a resource.
  ##   body: JObject (required)
  var body_402656575 = newJObject()
  if body != nil:
    body_402656575 = body
  result = call_402656574.call(nil, nil, nil, nil, body_402656575)

var untagResource* = Call_UntagResource_402656561(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "api.tunneling.iot.amazonaws.com",
    route: "/#X-Amz-Target=IoTSecuredTunneling.UntagResource",
    validator: validate_UntagResource_402656562, base: "/",
    makeUrl: url_UntagResource_402656563, schemes: {Scheme.Https, Scheme.Http})
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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