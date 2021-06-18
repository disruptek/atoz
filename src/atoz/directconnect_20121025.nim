
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Direct Connect
## version: 2012-10-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Direct Connect links your internal network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end of the cable is connected to your router, the other to an AWS Direct Connect router. With this connection in place, you can create virtual interfaces directly to the AWS cloud (for example, to Amazon EC2 and Amazon S3) and to Amazon VPC, bypassing Internet service providers in your network path. A connection provides access to all AWS Regions except the China (Beijing) and (China) Ningxia Regions. AWS resources in the China Regions can only be accessed through locations associated with those Regions.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/directconnect/
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "directconnect.ap-northeast-1.amazonaws.com", "ap-southeast-1": "directconnect.ap-southeast-1.amazonaws.com", "us-west-2": "directconnect.us-west-2.amazonaws.com", "eu-west-2": "directconnect.eu-west-2.amazonaws.com", "ap-northeast-3": "directconnect.ap-northeast-3.amazonaws.com", "eu-central-1": "directconnect.eu-central-1.amazonaws.com", "us-east-2": "directconnect.us-east-2.amazonaws.com", "us-east-1": "directconnect.us-east-1.amazonaws.com", "cn-northwest-1": "directconnect.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "directconnect.ap-south-1.amazonaws.com", "eu-north-1": "directconnect.eu-north-1.amazonaws.com", "ap-northeast-2": "directconnect.ap-northeast-2.amazonaws.com", "us-west-1": "directconnect.us-west-1.amazonaws.com", "us-gov-east-1": "directconnect.us-gov-east-1.amazonaws.com", "eu-west-3": "directconnect.eu-west-3.amazonaws.com", "cn-north-1": "directconnect.cn-north-1.amazonaws.com.cn", "sa-east-1": "directconnect.sa-east-1.amazonaws.com", "eu-west-1": "directconnect.eu-west-1.amazonaws.com", "us-gov-west-1": "directconnect.us-gov-west-1.amazonaws.com", "ap-southeast-2": "directconnect.ap-southeast-2.amazonaws.com", "ca-central-1": "directconnect.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "directconnect.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "directconnect.ap-southeast-1.amazonaws.com",
      "us-west-2": "directconnect.us-west-2.amazonaws.com",
      "eu-west-2": "directconnect.eu-west-2.amazonaws.com",
      "ap-northeast-3": "directconnect.ap-northeast-3.amazonaws.com",
      "eu-central-1": "directconnect.eu-central-1.amazonaws.com",
      "us-east-2": "directconnect.us-east-2.amazonaws.com",
      "us-east-1": "directconnect.us-east-1.amazonaws.com",
      "cn-northwest-1": "directconnect.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "directconnect.ap-south-1.amazonaws.com",
      "eu-north-1": "directconnect.eu-north-1.amazonaws.com",
      "ap-northeast-2": "directconnect.ap-northeast-2.amazonaws.com",
      "us-west-1": "directconnect.us-west-1.amazonaws.com",
      "us-gov-east-1": "directconnect.us-gov-east-1.amazonaws.com",
      "eu-west-3": "directconnect.eu-west-3.amazonaws.com",
      "cn-north-1": "directconnect.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "directconnect.sa-east-1.amazonaws.com",
      "eu-west-1": "directconnect.eu-west-1.amazonaws.com",
      "us-gov-west-1": "directconnect.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "directconnect.ap-southeast-2.amazonaws.com",
      "ca-central-1": "directconnect.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "directconnect"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AcceptDirectConnectGatewayAssociationProposal_402656294 = ref object of OpenApiRestCall_402656044
proc url_AcceptDirectConnectGatewayAssociationProposal_402656296(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptDirectConnectGatewayAssociationProposal_402656295(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Accepts a proposal request to attach a virtual private gateway or transit gateway to a Direct Connect gateway.
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
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "OvertureService.AcceptDirectConnectGatewayAssociationProposal"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
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

proc call*(call_402656412: Call_AcceptDirectConnectGatewayAssociationProposal_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Accepts a proposal request to attach a virtual private gateway or transit gateway to a Direct Connect gateway.
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_AcceptDirectConnectGatewayAssociationProposal_402656294;
           body: JsonNode): Recallable =
  ## acceptDirectConnectGatewayAssociationProposal
  ## Accepts a proposal request to attach a virtual private gateway or transit gateway to a Direct Connect gateway.
  ##   
                                                                                                                   ## body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var acceptDirectConnectGatewayAssociationProposal* = Call_AcceptDirectConnectGatewayAssociationProposal_402656294(
    name: "acceptDirectConnectGatewayAssociationProposal",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.AcceptDirectConnectGatewayAssociationProposal",
    validator: validate_AcceptDirectConnectGatewayAssociationProposal_402656295,
    base: "/", makeUrl: url_AcceptDirectConnectGatewayAssociationProposal_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocateConnectionOnInterconnect_402656489 = ref object of OpenApiRestCall_402656044
proc url_AllocateConnectionOnInterconnect_402656491(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocateConnectionOnInterconnect_402656490(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deprecated. Use <a>AllocateHostedConnection</a> instead.</p> <p>Creates a hosted connection on an interconnect.</p> <p>Allocates a VLAN number and a specified amount of bandwidth for use by a hosted connection on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
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
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "OvertureService.AllocateConnectionOnInterconnect"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
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

proc call*(call_402656501: Call_AllocateConnectionOnInterconnect_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deprecated. Use <a>AllocateHostedConnection</a> instead.</p> <p>Creates a hosted connection on an interconnect.</p> <p>Allocates a VLAN number and a specified amount of bandwidth for use by a hosted connection on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_AllocateConnectionOnInterconnect_402656489;
           body: JsonNode): Recallable =
  ## allocateConnectionOnInterconnect
  ## <p>Deprecated. Use <a>AllocateHostedConnection</a> instead.</p> <p>Creates a hosted connection on an interconnect.</p> <p>Allocates a VLAN number and a specified amount of bandwidth for use by a hosted connection on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var allocateConnectionOnInterconnect* = Call_AllocateConnectionOnInterconnect_402656489(
    name: "allocateConnectionOnInterconnect", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocateConnectionOnInterconnect",
    validator: validate_AllocateConnectionOnInterconnect_402656490, base: "/",
    makeUrl: url_AllocateConnectionOnInterconnect_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocateHostedConnection_402656504 = ref object of OpenApiRestCall_402656044
proc url_AllocateHostedConnection_402656506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocateHostedConnection_402656505(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a hosted connection on the specified interconnect or a link aggregation group (LAG) of interconnects.</p> <p>Allocates a VLAN number and a specified amount of capacity (bandwidth) for use by a hosted connection on the specified interconnect or LAG of interconnects. AWS polices the hosted connection for the specified capacity and the AWS Direct Connect Partner must also police the hosted connection for the specified capacity.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
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
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "OvertureService.AllocateHostedConnection"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
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

proc call*(call_402656516: Call_AllocateHostedConnection_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a hosted connection on the specified interconnect or a link aggregation group (LAG) of interconnects.</p> <p>Allocates a VLAN number and a specified amount of capacity (bandwidth) for use by a hosted connection on the specified interconnect or LAG of interconnects. AWS polices the hosted connection for the specified capacity and the AWS Direct Connect Partner must also police the hosted connection for the specified capacity.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_AllocateHostedConnection_402656504;
           body: JsonNode): Recallable =
  ## allocateHostedConnection
  ## <p>Creates a hosted connection on the specified interconnect or a link aggregation group (LAG) of interconnects.</p> <p>Allocates a VLAN number and a specified amount of capacity (bandwidth) for use by a hosted connection on the specified interconnect or LAG of interconnects. AWS polices the hosted connection for the specified capacity and the AWS Direct Connect Partner must also police the hosted connection for the specified capacity.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var allocateHostedConnection* = Call_AllocateHostedConnection_402656504(
    name: "allocateHostedConnection", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocateHostedConnection",
    validator: validate_AllocateHostedConnection_402656505, base: "/",
    makeUrl: url_AllocateHostedConnection_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocatePrivateVirtualInterface_402656519 = ref object of OpenApiRestCall_402656044
proc url_AllocatePrivateVirtualInterface_402656521(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocatePrivateVirtualInterface_402656520(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Provisions a private virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this action must be confirmed by the owner using <a>ConfirmPrivateVirtualInterface</a>. Until then, the virtual interface is in the <code>Confirming</code> state and is not available to handle traffic.</p>
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
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "OvertureService.AllocatePrivateVirtualInterface"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
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

proc call*(call_402656531: Call_AllocatePrivateVirtualInterface_402656519;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Provisions a private virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this action must be confirmed by the owner using <a>ConfirmPrivateVirtualInterface</a>. Until then, the virtual interface is in the <code>Confirming</code> state and is not available to handle traffic.</p>
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_AllocatePrivateVirtualInterface_402656519;
           body: JsonNode): Recallable =
  ## allocatePrivateVirtualInterface
  ## <p>Provisions a private virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this action must be confirmed by the owner using <a>ConfirmPrivateVirtualInterface</a>. Until then, the virtual interface is in the <code>Confirming</code> state and is not available to handle traffic.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var allocatePrivateVirtualInterface* = Call_AllocatePrivateVirtualInterface_402656519(
    name: "allocatePrivateVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocatePrivateVirtualInterface",
    validator: validate_AllocatePrivateVirtualInterface_402656520, base: "/",
    makeUrl: url_AllocatePrivateVirtualInterface_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocatePublicVirtualInterface_402656534 = ref object of OpenApiRestCall_402656044
proc url_AllocatePublicVirtualInterface_402656536(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocatePublicVirtualInterface_402656535(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Provisions a public virtual interface to be owned by the specified AWS account.</p> <p>The owner of a connection calls this function to provision a public virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this function must be confirmed by the owner using <a>ConfirmPublicVirtualInterface</a>. Until this step has been completed, the virtual interface is in the <code>confirming</code> state and is not available to handle traffic.</p> <p>When creating an IPv6 public virtual interface, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p>
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
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "OvertureService.AllocatePublicVirtualInterface"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
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

proc call*(call_402656546: Call_AllocatePublicVirtualInterface_402656534;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Provisions a public virtual interface to be owned by the specified AWS account.</p> <p>The owner of a connection calls this function to provision a public virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this function must be confirmed by the owner using <a>ConfirmPublicVirtualInterface</a>. Until this step has been completed, the virtual interface is in the <code>confirming</code> state and is not available to handle traffic.</p> <p>When creating an IPv6 public virtual interface, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p>
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_AllocatePublicVirtualInterface_402656534;
           body: JsonNode): Recallable =
  ## allocatePublicVirtualInterface
  ## <p>Provisions a public virtual interface to be owned by the specified AWS account.</p> <p>The owner of a connection calls this function to provision a public virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this function must be confirmed by the owner using <a>ConfirmPublicVirtualInterface</a>. Until this step has been completed, the virtual interface is in the <code>confirming</code> state and is not available to handle traffic.</p> <p>When creating an IPv6 public virtual interface, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var allocatePublicVirtualInterface* = Call_AllocatePublicVirtualInterface_402656534(
    name: "allocatePublicVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocatePublicVirtualInterface",
    validator: validate_AllocatePublicVirtualInterface_402656535, base: "/",
    makeUrl: url_AllocatePublicVirtualInterface_402656536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocateTransitVirtualInterface_402656549 = ref object of OpenApiRestCall_402656044
proc url_AllocateTransitVirtualInterface_402656551(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocateTransitVirtualInterface_402656550(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Provisions a transit virtual interface to be owned by the specified AWS account. Use this type of interface to connect a transit gateway to your Direct Connect gateway.</p> <p>The owner of a connection provisions a transit virtual interface to be owned by the specified AWS account.</p> <p>After you create a transit virtual interface, it must be confirmed by the owner using <a>ConfirmTransitVirtualInterface</a>. Until this step has been completed, the transit virtual interface is in the <code>requested</code> state and is not available to handle traffic.</p>
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
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "OvertureService.AllocateTransitVirtualInterface"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
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

proc call*(call_402656561: Call_AllocateTransitVirtualInterface_402656549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Provisions a transit virtual interface to be owned by the specified AWS account. Use this type of interface to connect a transit gateway to your Direct Connect gateway.</p> <p>The owner of a connection provisions a transit virtual interface to be owned by the specified AWS account.</p> <p>After you create a transit virtual interface, it must be confirmed by the owner using <a>ConfirmTransitVirtualInterface</a>. Until this step has been completed, the transit virtual interface is in the <code>requested</code> state and is not available to handle traffic.</p>
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_AllocateTransitVirtualInterface_402656549;
           body: JsonNode): Recallable =
  ## allocateTransitVirtualInterface
  ## <p>Provisions a transit virtual interface to be owned by the specified AWS account. Use this type of interface to connect a transit gateway to your Direct Connect gateway.</p> <p>The owner of a connection provisions a transit virtual interface to be owned by the specified AWS account.</p> <p>After you create a transit virtual interface, it must be confirmed by the owner using <a>ConfirmTransitVirtualInterface</a>. Until this step has been completed, the transit virtual interface is in the <code>requested</code> state and is not available to handle traffic.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var allocateTransitVirtualInterface* = Call_AllocateTransitVirtualInterface_402656549(
    name: "allocateTransitVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocateTransitVirtualInterface",
    validator: validate_AllocateTransitVirtualInterface_402656550, base: "/",
    makeUrl: url_AllocateTransitVirtualInterface_402656551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateConnectionWithLag_402656564 = ref object of OpenApiRestCall_402656044
proc url_AssociateConnectionWithLag_402656566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateConnectionWithLag_402656565(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Associates an existing connection with a link aggregation group (LAG). The connection is interrupted and re-established as a member of the LAG (connectivity to AWS is interrupted). The connection must be hosted on the same AWS Direct Connect endpoint as the LAG, and its bandwidth must match the bandwidth for the LAG. You can re-associate a connection that's currently associated with a different LAG; however, if removing the connection would cause the original LAG to fall below its setting for minimum number of operational connections, the request fails.</p> <p>Any virtual interfaces that are directly associated with the connection are automatically re-associated with the LAG. If the connection was originally associated with a different LAG, the virtual interfaces remain associated with the original LAG.</p> <p>For interconnects, any hosted connections are automatically re-associated with the LAG. If the interconnect was originally associated with a different LAG, the hosted connections remain associated with the original LAG.</p>
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
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "OvertureService.AssociateConnectionWithLag"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
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

proc call*(call_402656576: Call_AssociateConnectionWithLag_402656564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates an existing connection with a link aggregation group (LAG). The connection is interrupted and re-established as a member of the LAG (connectivity to AWS is interrupted). The connection must be hosted on the same AWS Direct Connect endpoint as the LAG, and its bandwidth must match the bandwidth for the LAG. You can re-associate a connection that's currently associated with a different LAG; however, if removing the connection would cause the original LAG to fall below its setting for minimum number of operational connections, the request fails.</p> <p>Any virtual interfaces that are directly associated with the connection are automatically re-associated with the LAG. If the connection was originally associated with a different LAG, the virtual interfaces remain associated with the original LAG.</p> <p>For interconnects, any hosted connections are automatically re-associated with the LAG. If the interconnect was originally associated with a different LAG, the hosted connections remain associated with the original LAG.</p>
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_AssociateConnectionWithLag_402656564;
           body: JsonNode): Recallable =
  ## associateConnectionWithLag
  ## <p>Associates an existing connection with a link aggregation group (LAG). The connection is interrupted and re-established as a member of the LAG (connectivity to AWS is interrupted). The connection must be hosted on the same AWS Direct Connect endpoint as the LAG, and its bandwidth must match the bandwidth for the LAG. You can re-associate a connection that's currently associated with a different LAG; however, if removing the connection would cause the original LAG to fall below its setting for minimum number of operational connections, the request fails.</p> <p>Any virtual interfaces that are directly associated with the connection are automatically re-associated with the LAG. If the connection was originally associated with a different LAG, the virtual interfaces remain associated with the original LAG.</p> <p>For interconnects, any hosted connections are automatically re-associated with the LAG. If the interconnect was originally associated with a different LAG, the hosted connections remain associated with the original LAG.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var associateConnectionWithLag* = Call_AssociateConnectionWithLag_402656564(
    name: "associateConnectionWithLag", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AssociateConnectionWithLag",
    validator: validate_AssociateConnectionWithLag_402656565, base: "/",
    makeUrl: url_AssociateConnectionWithLag_402656566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateHostedConnection_402656579 = ref object of OpenApiRestCall_402656044
proc url_AssociateHostedConnection_402656581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateHostedConnection_402656580(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Associates a hosted connection and its virtual interfaces with a link aggregation group (LAG) or interconnect. If the target interconnect or LAG has an existing hosted connection with a conflicting VLAN number or IP address, the operation fails. This action temporarily interrupts the hosted connection's connectivity to AWS as it is being migrated.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
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
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "OvertureService.AssociateHostedConnection"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
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

proc call*(call_402656591: Call_AssociateHostedConnection_402656579;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates a hosted connection and its virtual interfaces with a link aggregation group (LAG) or interconnect. If the target interconnect or LAG has an existing hosted connection with a conflicting VLAN number or IP address, the operation fails. This action temporarily interrupts the hosted connection's connectivity to AWS as it is being migrated.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_AssociateHostedConnection_402656579;
           body: JsonNode): Recallable =
  ## associateHostedConnection
  ## <p>Associates a hosted connection and its virtual interfaces with a link aggregation group (LAG) or interconnect. If the target interconnect or LAG has an existing hosted connection with a conflicting VLAN number or IP address, the operation fails. This action temporarily interrupts the hosted connection's connectivity to AWS as it is being migrated.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var associateHostedConnection* = Call_AssociateHostedConnection_402656579(
    name: "associateHostedConnection", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AssociateHostedConnection",
    validator: validate_AssociateHostedConnection_402656580, base: "/",
    makeUrl: url_AssociateHostedConnection_402656581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateVirtualInterface_402656594 = ref object of OpenApiRestCall_402656044
proc url_AssociateVirtualInterface_402656596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateVirtualInterface_402656595(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Associates a virtual interface with a specified link aggregation group (LAG) or connection. Connectivity to AWS is temporarily interrupted as the virtual interface is being migrated. If the target connection or LAG has an associated virtual interface with a conflicting VLAN number or a conflicting IP address, the operation fails.</p> <p>Virtual interfaces associated with a hosted connection cannot be associated with a LAG; hosted connections must be migrated along with their virtual interfaces using <a>AssociateHostedConnection</a>.</p> <p>To reassociate a virtual interface to a new connection or LAG, the requester must own either the virtual interface itself or the connection to which the virtual interface is currently associated. Additionally, the requester must own the connection or LAG for the association.</p>
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
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "OvertureService.AssociateVirtualInterface"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
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

proc call*(call_402656606: Call_AssociateVirtualInterface_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates a virtual interface with a specified link aggregation group (LAG) or connection. Connectivity to AWS is temporarily interrupted as the virtual interface is being migrated. If the target connection or LAG has an associated virtual interface with a conflicting VLAN number or a conflicting IP address, the operation fails.</p> <p>Virtual interfaces associated with a hosted connection cannot be associated with a LAG; hosted connections must be migrated along with their virtual interfaces using <a>AssociateHostedConnection</a>.</p> <p>To reassociate a virtual interface to a new connection or LAG, the requester must own either the virtual interface itself or the connection to which the virtual interface is currently associated. Additionally, the requester must own the connection or LAG for the association.</p>
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_AssociateVirtualInterface_402656594;
           body: JsonNode): Recallable =
  ## associateVirtualInterface
  ## <p>Associates a virtual interface with a specified link aggregation group (LAG) or connection. Connectivity to AWS is temporarily interrupted as the virtual interface is being migrated. If the target connection or LAG has an associated virtual interface with a conflicting VLAN number or a conflicting IP address, the operation fails.</p> <p>Virtual interfaces associated with a hosted connection cannot be associated with a LAG; hosted connections must be migrated along with their virtual interfaces using <a>AssociateHostedConnection</a>.</p> <p>To reassociate a virtual interface to a new connection or LAG, the requester must own either the virtual interface itself or the connection to which the virtual interface is currently associated. Additionally, the requester must own the connection or LAG for the association.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var associateVirtualInterface* = Call_AssociateVirtualInterface_402656594(
    name: "associateVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AssociateVirtualInterface",
    validator: validate_AssociateVirtualInterface_402656595, base: "/",
    makeUrl: url_AssociateVirtualInterface_402656596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmConnection_402656609 = ref object of OpenApiRestCall_402656044
proc url_ConfirmConnection_402656611(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmConnection_402656610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Confirms the creation of the specified hosted connection on an interconnect.</p> <p>Upon creation, the hosted connection is initially in the <code>Ordering</code> state, and remains in this state until the owner confirms creation of the hosted connection.</p>
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
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "OvertureService.ConfirmConnection"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
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

proc call*(call_402656621: Call_ConfirmConnection_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Confirms the creation of the specified hosted connection on an interconnect.</p> <p>Upon creation, the hosted connection is initially in the <code>Ordering</code> state, and remains in this state until the owner confirms creation of the hosted connection.</p>
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_ConfirmConnection_402656609; body: JsonNode): Recallable =
  ## confirmConnection
  ## <p>Confirms the creation of the specified hosted connection on an interconnect.</p> <p>Upon creation, the hosted connection is initially in the <code>Ordering</code> state, and remains in this state until the owner confirms creation of the hosted connection.</p>
  ##   
                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var confirmConnection* = Call_ConfirmConnection_402656609(
    name: "confirmConnection", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.ConfirmConnection",
    validator: validate_ConfirmConnection_402656610, base: "/",
    makeUrl: url_ConfirmConnection_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmPrivateVirtualInterface_402656624 = ref object of OpenApiRestCall_402656044
proc url_ConfirmPrivateVirtualInterface_402656626(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmPrivateVirtualInterface_402656625(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Accepts ownership of a private virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the virtual interface is created and attached to the specified virtual private gateway or Direct Connect gateway, and is made available to handle traffic.</p>
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
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "OvertureService.ConfirmPrivateVirtualInterface"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
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

proc call*(call_402656636: Call_ConfirmPrivateVirtualInterface_402656624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Accepts ownership of a private virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the virtual interface is created and attached to the specified virtual private gateway or Direct Connect gateway, and is made available to handle traffic.</p>
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_ConfirmPrivateVirtualInterface_402656624;
           body: JsonNode): Recallable =
  ## confirmPrivateVirtualInterface
  ## <p>Accepts ownership of a private virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the virtual interface is created and attached to the specified virtual private gateway or Direct Connect gateway, and is made available to handle traffic.</p>
  ##   
                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var confirmPrivateVirtualInterface* = Call_ConfirmPrivateVirtualInterface_402656624(
    name: "confirmPrivateVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.ConfirmPrivateVirtualInterface",
    validator: validate_ConfirmPrivateVirtualInterface_402656625, base: "/",
    makeUrl: url_ConfirmPrivateVirtualInterface_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmPublicVirtualInterface_402656639 = ref object of OpenApiRestCall_402656044
proc url_ConfirmPublicVirtualInterface_402656641(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmPublicVirtualInterface_402656640(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Accepts ownership of a public virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the specified virtual interface is created and made available to handle traffic.</p>
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
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "OvertureService.ConfirmPublicVirtualInterface"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
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

proc call*(call_402656651: Call_ConfirmPublicVirtualInterface_402656639;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Accepts ownership of a public virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the specified virtual interface is created and made available to handle traffic.</p>
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_ConfirmPublicVirtualInterface_402656639;
           body: JsonNode): Recallable =
  ## confirmPublicVirtualInterface
  ## <p>Accepts ownership of a public virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the specified virtual interface is created and made available to handle traffic.</p>
  ##   
                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var confirmPublicVirtualInterface* = Call_ConfirmPublicVirtualInterface_402656639(
    name: "confirmPublicVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.ConfirmPublicVirtualInterface",
    validator: validate_ConfirmPublicVirtualInterface_402656640, base: "/",
    makeUrl: url_ConfirmPublicVirtualInterface_402656641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmTransitVirtualInterface_402656654 = ref object of OpenApiRestCall_402656044
proc url_ConfirmTransitVirtualInterface_402656656(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmTransitVirtualInterface_402656655(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Accepts ownership of a transit virtual interface created by another AWS account.</p> <p> After the owner of the transit virtual interface makes this call, the specified transit virtual interface is created and made available to handle traffic.</p>
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
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "OvertureService.ConfirmTransitVirtualInterface"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
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

proc call*(call_402656666: Call_ConfirmTransitVirtualInterface_402656654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Accepts ownership of a transit virtual interface created by another AWS account.</p> <p> After the owner of the transit virtual interface makes this call, the specified transit virtual interface is created and made available to handle traffic.</p>
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_ConfirmTransitVirtualInterface_402656654;
           body: JsonNode): Recallable =
  ## confirmTransitVirtualInterface
  ## <p>Accepts ownership of a transit virtual interface created by another AWS account.</p> <p> After the owner of the transit virtual interface makes this call, the specified transit virtual interface is created and made available to handle traffic.</p>
  ##   
                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var confirmTransitVirtualInterface* = Call_ConfirmTransitVirtualInterface_402656654(
    name: "confirmTransitVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.ConfirmTransitVirtualInterface",
    validator: validate_ConfirmTransitVirtualInterface_402656655, base: "/",
    makeUrl: url_ConfirmTransitVirtualInterface_402656656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBGPPeer_402656669 = ref object of OpenApiRestCall_402656044
proc url_CreateBGPPeer_402656671(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBGPPeer_402656670(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a BGP peer on the specified virtual interface.</p> <p>You must create a BGP peer for the corresponding address family (IPv4/IPv6) in order to access AWS resources that also use that address family.</p> <p>If logical redundancy is not supported by the connection, interconnect, or LAG, the BGP peer cannot be in the same address family as an existing BGP peer on the virtual interface.</p> <p>When creating a IPv6 BGP peer, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p> <p>For a public virtual interface, the Autonomous System Number (ASN) must be private or already whitelisted for the virtual interface.</p>
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
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "OvertureService.CreateBGPPeer"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
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

proc call*(call_402656681: Call_CreateBGPPeer_402656669; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a BGP peer on the specified virtual interface.</p> <p>You must create a BGP peer for the corresponding address family (IPv4/IPv6) in order to access AWS resources that also use that address family.</p> <p>If logical redundancy is not supported by the connection, interconnect, or LAG, the BGP peer cannot be in the same address family as an existing BGP peer on the virtual interface.</p> <p>When creating a IPv6 BGP peer, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p> <p>For a public virtual interface, the Autonomous System Number (ASN) must be private or already whitelisted for the virtual interface.</p>
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_CreateBGPPeer_402656669; body: JsonNode): Recallable =
  ## createBGPPeer
  ## <p>Creates a BGP peer on the specified virtual interface.</p> <p>You must create a BGP peer for the corresponding address family (IPv4/IPv6) in order to access AWS resources that also use that address family.</p> <p>If logical redundancy is not supported by the connection, interconnect, or LAG, the BGP peer cannot be in the same address family as an existing BGP peer on the virtual interface.</p> <p>When creating a IPv6 BGP peer, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p> <p>For a public virtual interface, the Autonomous System Number (ASN) must be private or already whitelisted for the virtual interface.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var createBGPPeer* = Call_CreateBGPPeer_402656669(name: "createBGPPeer",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateBGPPeer",
    validator: validate_CreateBGPPeer_402656670, base: "/",
    makeUrl: url_CreateBGPPeer_402656671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_402656684 = ref object of OpenApiRestCall_402656044
proc url_CreateConnection_402656686(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConnection_402656685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a connection between a customer network and a specific AWS Direct Connect location.</p> <p>A connection links your internal network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end of the cable is connected to your router, the other to an AWS Direct Connect router.</p> <p>To find the locations for your Region, use <a>DescribeLocations</a>.</p> <p>You can automatically add the new connection to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new connection is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no connection is created.</p>
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
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "OvertureService.CreateConnection"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
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

proc call*(call_402656696: Call_CreateConnection_402656684;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a connection between a customer network and a specific AWS Direct Connect location.</p> <p>A connection links your internal network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end of the cable is connected to your router, the other to an AWS Direct Connect router.</p> <p>To find the locations for your Region, use <a>DescribeLocations</a>.</p> <p>You can automatically add the new connection to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new connection is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no connection is created.</p>
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_CreateConnection_402656684; body: JsonNode): Recallable =
  ## createConnection
  ## <p>Creates a connection between a customer network and a specific AWS Direct Connect location.</p> <p>A connection links your internal network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end of the cable is connected to your router, the other to an AWS Direct Connect router.</p> <p>To find the locations for your Region, use <a>DescribeLocations</a>.</p> <p>You can automatically add the new connection to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new connection is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no connection is created.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var createConnection* = Call_CreateConnection_402656684(
    name: "createConnection", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateConnection",
    validator: validate_CreateConnection_402656685, base: "/",
    makeUrl: url_CreateConnection_402656686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectConnectGateway_402656699 = ref object of OpenApiRestCall_402656044
proc url_CreateDirectConnectGateway_402656701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectConnectGateway_402656700(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a Direct Connect gateway, which is an intermediate object that enables you to connect a set of virtual interfaces and virtual private gateways. A Direct Connect gateway is global and visible in any AWS Region after it is created. The virtual interfaces and virtual private gateways that are connected through a Direct Connect gateway can be in different AWS Regions. This enables you to connect to a VPC in any Region, regardless of the Region in which the virtual interfaces are located, and pass traffic between them.
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
  var valid_402656702 = header.getOrDefault("X-Amz-Target")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true, default = newJString(
      "OvertureService.CreateDirectConnectGateway"))
  if valid_402656702 != nil:
    section.add "X-Amz-Target", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
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

proc call*(call_402656711: Call_CreateDirectConnectGateway_402656699;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Direct Connect gateway, which is an intermediate object that enables you to connect a set of virtual interfaces and virtual private gateways. A Direct Connect gateway is global and visible in any AWS Region after it is created. The virtual interfaces and virtual private gateways that are connected through a Direct Connect gateway can be in different AWS Regions. This enables you to connect to a VPC in any Region, regardless of the Region in which the virtual interfaces are located, and pass traffic between them.
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_CreateDirectConnectGateway_402656699;
           body: JsonNode): Recallable =
  ## createDirectConnectGateway
  ## Creates a Direct Connect gateway, which is an intermediate object that enables you to connect a set of virtual interfaces and virtual private gateways. A Direct Connect gateway is global and visible in any AWS Region after it is created. The virtual interfaces and virtual private gateways that are connected through a Direct Connect gateway can be in different AWS Regions. This enables you to connect to a VPC in any Region, regardless of the Region in which the virtual interfaces are located, and pass traffic between them.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var createDirectConnectGateway* = Call_CreateDirectConnectGateway_402656699(
    name: "createDirectConnectGateway", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateDirectConnectGateway",
    validator: validate_CreateDirectConnectGateway_402656700, base: "/",
    makeUrl: url_CreateDirectConnectGateway_402656701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectConnectGatewayAssociation_402656714 = ref object of OpenApiRestCall_402656044
proc url_CreateDirectConnectGatewayAssociation_402656716(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectConnectGatewayAssociation_402656715(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates an association between a Direct Connect gateway and a virtual private gateway. The virtual private gateway must be attached to a VPC and must not be associated with another Direct Connect gateway.
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
  var valid_402656717 = header.getOrDefault("X-Amz-Target")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true, default = newJString(
      "OvertureService.CreateDirectConnectGatewayAssociation"))
  if valid_402656717 != nil:
    section.add "X-Amz-Target", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
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

proc call*(call_402656726: Call_CreateDirectConnectGatewayAssociation_402656714;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an association between a Direct Connect gateway and a virtual private gateway. The virtual private gateway must be attached to a VPC and must not be associated with another Direct Connect gateway.
                                                                                         ## 
  let valid = call_402656726.validator(path, query, header, formData, body, _)
  let scheme = call_402656726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656726.makeUrl(scheme.get, call_402656726.host, call_402656726.base,
                                   call_402656726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656726, uri, valid, _)

proc call*(call_402656727: Call_CreateDirectConnectGatewayAssociation_402656714;
           body: JsonNode): Recallable =
  ## createDirectConnectGatewayAssociation
  ## Creates an association between a Direct Connect gateway and a virtual private gateway. The virtual private gateway must be attached to a VPC and must not be associated with another Direct Connect gateway.
  ##   
                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656728 = newJObject()
  if body != nil:
    body_402656728 = body
  result = call_402656727.call(nil, nil, nil, nil, body_402656728)

var createDirectConnectGatewayAssociation* = Call_CreateDirectConnectGatewayAssociation_402656714(
    name: "createDirectConnectGatewayAssociation", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.CreateDirectConnectGatewayAssociation",
    validator: validate_CreateDirectConnectGatewayAssociation_402656715,
    base: "/", makeUrl: url_CreateDirectConnectGatewayAssociation_402656716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectConnectGatewayAssociationProposal_402656729 = ref object of OpenApiRestCall_402656044
proc url_CreateDirectConnectGatewayAssociationProposal_402656731(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectConnectGatewayAssociationProposal_402656730(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a proposal to associate the specified virtual private gateway or transit gateway with the specified Direct Connect gateway.</p> <p>You can only associate a Direct Connect gateway and virtual private gateway or transit gateway when the account that owns the Direct Connect gateway and the account that owns the virtual private gateway or transit gateway have the same AWS Payer ID.</p>
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
  var valid_402656732 = header.getOrDefault("X-Amz-Target")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true, default = newJString(
      "OvertureService.CreateDirectConnectGatewayAssociationProposal"))
  if valid_402656732 != nil:
    section.add "X-Amz-Target", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
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

proc call*(call_402656741: Call_CreateDirectConnectGatewayAssociationProposal_402656729;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a proposal to associate the specified virtual private gateway or transit gateway with the specified Direct Connect gateway.</p> <p>You can only associate a Direct Connect gateway and virtual private gateway or transit gateway when the account that owns the Direct Connect gateway and the account that owns the virtual private gateway or transit gateway have the same AWS Payer ID.</p>
                                                                                         ## 
  let valid = call_402656741.validator(path, query, header, formData, body, _)
  let scheme = call_402656741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656741.makeUrl(scheme.get, call_402656741.host, call_402656741.base,
                                   call_402656741.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656741, uri, valid, _)

proc call*(call_402656742: Call_CreateDirectConnectGatewayAssociationProposal_402656729;
           body: JsonNode): Recallable =
  ## createDirectConnectGatewayAssociationProposal
  ## <p>Creates a proposal to associate the specified virtual private gateway or transit gateway with the specified Direct Connect gateway.</p> <p>You can only associate a Direct Connect gateway and virtual private gateway or transit gateway when the account that owns the Direct Connect gateway and the account that owns the virtual private gateway or transit gateway have the same AWS Payer ID.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var createDirectConnectGatewayAssociationProposal* = Call_CreateDirectConnectGatewayAssociationProposal_402656729(
    name: "createDirectConnectGatewayAssociationProposal",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.CreateDirectConnectGatewayAssociationProposal",
    validator: validate_CreateDirectConnectGatewayAssociationProposal_402656730,
    base: "/", makeUrl: url_CreateDirectConnectGatewayAssociationProposal_402656731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInterconnect_402656744 = ref object of OpenApiRestCall_402656044
proc url_CreateInterconnect_402656746(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInterconnect_402656745(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an interconnect between an AWS Direct Connect Partner's network and a specific AWS Direct Connect location.</p> <p>An interconnect is a connection that is capable of hosting other connections. The AWS Direct Connect partner can use an interconnect to provide AWS Direct Connect hosted connections to customers through their own network services. Like a standard connection, an interconnect links the partner's network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end is connected to the partner's router, the other to an AWS Direct Connect router.</p> <p>You can automatically add the new interconnect to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new interconnect is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no interconnect is created.</p> <p>For each end customer, the AWS Direct Connect Partner provisions a connection on their interconnect by calling <a>AllocateHostedConnection</a>. The end customer can then connect to AWS resources by creating a virtual interface on their connection, using the VLAN assigned to them by the AWS Direct Connect Partner.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
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
  var valid_402656747 = header.getOrDefault("X-Amz-Target")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true, default = newJString(
      "OvertureService.CreateInterconnect"))
  if valid_402656747 != nil:
    section.add "X-Amz-Target", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
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

proc call*(call_402656756: Call_CreateInterconnect_402656744;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an interconnect between an AWS Direct Connect Partner's network and a specific AWS Direct Connect location.</p> <p>An interconnect is a connection that is capable of hosting other connections. The AWS Direct Connect partner can use an interconnect to provide AWS Direct Connect hosted connections to customers through their own network services. Like a standard connection, an interconnect links the partner's network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end is connected to the partner's router, the other to an AWS Direct Connect router.</p> <p>You can automatically add the new interconnect to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new interconnect is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no interconnect is created.</p> <p>For each end customer, the AWS Direct Connect Partner provisions a connection on their interconnect by calling <a>AllocateHostedConnection</a>. The end customer can then connect to AWS resources by creating a virtual interface on their connection, using the VLAN assigned to them by the AWS Direct Connect Partner.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_CreateInterconnect_402656744; body: JsonNode): Recallable =
  ## createInterconnect
  ## <p>Creates an interconnect between an AWS Direct Connect Partner's network and a specific AWS Direct Connect location.</p> <p>An interconnect is a connection that is capable of hosting other connections. The AWS Direct Connect partner can use an interconnect to provide AWS Direct Connect hosted connections to customers through their own network services. Like a standard connection, an interconnect links the partner's network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end is connected to the partner's router, the other to an AWS Direct Connect router.</p> <p>You can automatically add the new interconnect to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new interconnect is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no interconnect is created.</p> <p>For each end customer, the AWS Direct Connect Partner provisions a connection on their interconnect by calling <a>AllocateHostedConnection</a>. The end customer can then connect to AWS resources by creating a virtual interface on their connection, using the VLAN assigned to them by the AWS Direct Connect Partner.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656758 = newJObject()
  if body != nil:
    body_402656758 = body
  result = call_402656757.call(nil, nil, nil, nil, body_402656758)

var createInterconnect* = Call_CreateInterconnect_402656744(
    name: "createInterconnect", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateInterconnect",
    validator: validate_CreateInterconnect_402656745, base: "/",
    makeUrl: url_CreateInterconnect_402656746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLag_402656759 = ref object of OpenApiRestCall_402656044
proc url_CreateLag_402656761(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLag_402656760(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a link aggregation group (LAG) with the specified number of bundled physical connections between the customer network and a specific AWS Direct Connect location. A LAG is a logical interface that uses the Link Aggregation Control Protocol (LACP) to aggregate multiple interfaces, enabling you to treat them as a single interface.</p> <p>All connections in a LAG must use the same bandwidth and must terminate at the same AWS Direct Connect endpoint.</p> <p>You can have up to 10 connections per LAG. Regardless of this limit, if you request more connections for the LAG than AWS Direct Connect can allocate on a single endpoint, no LAG is created.</p> <p>You can specify an existing physical connection or interconnect to include in the LAG (which counts towards the total number of connections). Doing so interrupts the current physical connection or hosted connections, and re-establishes them as a member of the LAG. The LAG will be created on the same AWS Direct Connect endpoint to which the connection terminates. Any virtual interfaces associated with the connection are automatically disassociated and re-associated with the LAG. The connection ID does not change.</p> <p>If the AWS account used to create a LAG is a registered AWS Direct Connect Partner, the LAG is automatically enabled to host sub-connections. For a LAG owned by a partner, any associated virtual interfaces cannot be directly configured.</p>
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
  var valid_402656762 = header.getOrDefault("X-Amz-Target")
  valid_402656762 = validateParameter(valid_402656762, JString, required = true, default = newJString(
      "OvertureService.CreateLag"))
  if valid_402656762 != nil:
    section.add "X-Amz-Target", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Security-Token", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Signature")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Signature", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Algorithm", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Date")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Date", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Credential")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Credential", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656769
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

proc call*(call_402656771: Call_CreateLag_402656759; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a link aggregation group (LAG) with the specified number of bundled physical connections between the customer network and a specific AWS Direct Connect location. A LAG is a logical interface that uses the Link Aggregation Control Protocol (LACP) to aggregate multiple interfaces, enabling you to treat them as a single interface.</p> <p>All connections in a LAG must use the same bandwidth and must terminate at the same AWS Direct Connect endpoint.</p> <p>You can have up to 10 connections per LAG. Regardless of this limit, if you request more connections for the LAG than AWS Direct Connect can allocate on a single endpoint, no LAG is created.</p> <p>You can specify an existing physical connection or interconnect to include in the LAG (which counts towards the total number of connections). Doing so interrupts the current physical connection or hosted connections, and re-establishes them as a member of the LAG. The LAG will be created on the same AWS Direct Connect endpoint to which the connection terminates. Any virtual interfaces associated with the connection are automatically disassociated and re-associated with the LAG. The connection ID does not change.</p> <p>If the AWS account used to create a LAG is a registered AWS Direct Connect Partner, the LAG is automatically enabled to host sub-connections. For a LAG owned by a partner, any associated virtual interfaces cannot be directly configured.</p>
                                                                                         ## 
  let valid = call_402656771.validator(path, query, header, formData, body, _)
  let scheme = call_402656771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656771.makeUrl(scheme.get, call_402656771.host, call_402656771.base,
                                   call_402656771.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656771, uri, valid, _)

proc call*(call_402656772: Call_CreateLag_402656759; body: JsonNode): Recallable =
  ## createLag
  ## <p>Creates a link aggregation group (LAG) with the specified number of bundled physical connections between the customer network and a specific AWS Direct Connect location. A LAG is a logical interface that uses the Link Aggregation Control Protocol (LACP) to aggregate multiple interfaces, enabling you to treat them as a single interface.</p> <p>All connections in a LAG must use the same bandwidth and must terminate at the same AWS Direct Connect endpoint.</p> <p>You can have up to 10 connections per LAG. Regardless of this limit, if you request more connections for the LAG than AWS Direct Connect can allocate on a single endpoint, no LAG is created.</p> <p>You can specify an existing physical connection or interconnect to include in the LAG (which counts towards the total number of connections). Doing so interrupts the current physical connection or hosted connections, and re-establishes them as a member of the LAG. The LAG will be created on the same AWS Direct Connect endpoint to which the connection terminates. Any virtual interfaces associated with the connection are automatically disassociated and re-associated with the LAG. The connection ID does not change.</p> <p>If the AWS account used to create a LAG is a registered AWS Direct Connect Partner, the LAG is automatically enabled to host sub-connections. For a LAG owned by a partner, any associated virtual interfaces cannot be directly configured.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656773 = newJObject()
  if body != nil:
    body_402656773 = body
  result = call_402656772.call(nil, nil, nil, nil, body_402656773)

var createLag* = Call_CreateLag_402656759(name: "createLag",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateLag",
    validator: validate_CreateLag_402656760, base: "/", makeUrl: url_CreateLag_402656761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePrivateVirtualInterface_402656774 = ref object of OpenApiRestCall_402656044
proc url_CreatePrivateVirtualInterface_402656776(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePrivateVirtualInterface_402656775(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a private virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A private virtual interface can be connected to either a Direct Connect gateway or a Virtual Private Gateway (VGW). Connecting the private virtual interface to a Direct Connect gateway enables the possibility for connecting to multiple VPCs, including VPCs in different AWS Regions. Connecting the private virtual interface to a VGW only provides access to a single VPC within the same Region.
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
  var valid_402656777 = header.getOrDefault("X-Amz-Target")
  valid_402656777 = validateParameter(valid_402656777, JString, required = true, default = newJString(
      "OvertureService.CreatePrivateVirtualInterface"))
  if valid_402656777 != nil:
    section.add "X-Amz-Target", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Security-Token", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Signature")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Signature", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Algorithm", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Date")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Date", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Credential")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Credential", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656784
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

proc call*(call_402656786: Call_CreatePrivateVirtualInterface_402656774;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a private virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A private virtual interface can be connected to either a Direct Connect gateway or a Virtual Private Gateway (VGW). Connecting the private virtual interface to a Direct Connect gateway enables the possibility for connecting to multiple VPCs, including VPCs in different AWS Regions. Connecting the private virtual interface to a VGW only provides access to a single VPC within the same Region.
                                                                                         ## 
  let valid = call_402656786.validator(path, query, header, formData, body, _)
  let scheme = call_402656786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656786.makeUrl(scheme.get, call_402656786.host, call_402656786.base,
                                   call_402656786.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656786, uri, valid, _)

proc call*(call_402656787: Call_CreatePrivateVirtualInterface_402656774;
           body: JsonNode): Recallable =
  ## createPrivateVirtualInterface
  ## Creates a private virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A private virtual interface can be connected to either a Direct Connect gateway or a Virtual Private Gateway (VGW). Connecting the private virtual interface to a Direct Connect gateway enables the possibility for connecting to multiple VPCs, including VPCs in different AWS Regions. Connecting the private virtual interface to a VGW only provides access to a single VPC within the same Region.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656788 = newJObject()
  if body != nil:
    body_402656788 = body
  result = call_402656787.call(nil, nil, nil, nil, body_402656788)

var createPrivateVirtualInterface* = Call_CreatePrivateVirtualInterface_402656774(
    name: "createPrivateVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreatePrivateVirtualInterface",
    validator: validate_CreatePrivateVirtualInterface_402656775, base: "/",
    makeUrl: url_CreatePrivateVirtualInterface_402656776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicVirtualInterface_402656789 = ref object of OpenApiRestCall_402656044
proc url_CreatePublicVirtualInterface_402656791(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePublicVirtualInterface_402656790(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a public virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A public virtual interface supports sending traffic to public services of AWS such as Amazon S3.</p> <p>When creating an IPv6 public virtual interface (<code>addressFamily</code> is <code>ipv6</code>), leave the <code>customer</code> and <code>amazon</code> address fields blank to use auto-assigned IPv6 space. Custom IPv6 addresses are not supported.</p>
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
  var valid_402656792 = header.getOrDefault("X-Amz-Target")
  valid_402656792 = validateParameter(valid_402656792, JString, required = true, default = newJString(
      "OvertureService.CreatePublicVirtualInterface"))
  if valid_402656792 != nil:
    section.add "X-Amz-Target", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Security-Token", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Signature")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Signature", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Algorithm", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Date")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Date", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Credential")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Credential", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656799
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

proc call*(call_402656801: Call_CreatePublicVirtualInterface_402656789;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a public virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A public virtual interface supports sending traffic to public services of AWS such as Amazon S3.</p> <p>When creating an IPv6 public virtual interface (<code>addressFamily</code> is <code>ipv6</code>), leave the <code>customer</code> and <code>amazon</code> address fields blank to use auto-assigned IPv6 space. Custom IPv6 addresses are not supported.</p>
                                                                                         ## 
  let valid = call_402656801.validator(path, query, header, formData, body, _)
  let scheme = call_402656801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656801.makeUrl(scheme.get, call_402656801.host, call_402656801.base,
                                   call_402656801.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656801, uri, valid, _)

proc call*(call_402656802: Call_CreatePublicVirtualInterface_402656789;
           body: JsonNode): Recallable =
  ## createPublicVirtualInterface
  ## <p>Creates a public virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A public virtual interface supports sending traffic to public services of AWS such as Amazon S3.</p> <p>When creating an IPv6 public virtual interface (<code>addressFamily</code> is <code>ipv6</code>), leave the <code>customer</code> and <code>amazon</code> address fields blank to use auto-assigned IPv6 space. Custom IPv6 addresses are not supported.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656803 = newJObject()
  if body != nil:
    body_402656803 = body
  result = call_402656802.call(nil, nil, nil, nil, body_402656803)

var createPublicVirtualInterface* = Call_CreatePublicVirtualInterface_402656789(
    name: "createPublicVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreatePublicVirtualInterface",
    validator: validate_CreatePublicVirtualInterface_402656790, base: "/",
    makeUrl: url_CreatePublicVirtualInterface_402656791,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransitVirtualInterface_402656804 = ref object of OpenApiRestCall_402656044
proc url_CreateTransitVirtualInterface_402656806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTransitVirtualInterface_402656805(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a transit virtual interface. A transit virtual interface should be used to access one or more transit gateways associated with Direct Connect gateways. A transit virtual interface enables the connection of multiple VPCs attached to a transit gateway to a Direct Connect gateway.</p> <important> <p>If you associate your transit gateway with one or more Direct Connect gateways, the Autonomous System Number (ASN) used by the transit gateway and the Direct Connect gateway must be different. For example, if you use the default ASN 64512 for both your the transit gateway and Direct Connect gateway, the association request fails.</p> </important>
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
  var valid_402656807 = header.getOrDefault("X-Amz-Target")
  valid_402656807 = validateParameter(valid_402656807, JString, required = true, default = newJString(
      "OvertureService.CreateTransitVirtualInterface"))
  if valid_402656807 != nil:
    section.add "X-Amz-Target", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Security-Token", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Signature")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Signature", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Algorithm", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Date")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Date", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Credential")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Credential", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656814
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

proc call*(call_402656816: Call_CreateTransitVirtualInterface_402656804;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a transit virtual interface. A transit virtual interface should be used to access one or more transit gateways associated with Direct Connect gateways. A transit virtual interface enables the connection of multiple VPCs attached to a transit gateway to a Direct Connect gateway.</p> <important> <p>If you associate your transit gateway with one or more Direct Connect gateways, the Autonomous System Number (ASN) used by the transit gateway and the Direct Connect gateway must be different. For example, if you use the default ASN 64512 for both your the transit gateway and Direct Connect gateway, the association request fails.</p> </important>
                                                                                         ## 
  let valid = call_402656816.validator(path, query, header, formData, body, _)
  let scheme = call_402656816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656816.makeUrl(scheme.get, call_402656816.host, call_402656816.base,
                                   call_402656816.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656816, uri, valid, _)

proc call*(call_402656817: Call_CreateTransitVirtualInterface_402656804;
           body: JsonNode): Recallable =
  ## createTransitVirtualInterface
  ## <p>Creates a transit virtual interface. A transit virtual interface should be used to access one or more transit gateways associated with Direct Connect gateways. A transit virtual interface enables the connection of multiple VPCs attached to a transit gateway to a Direct Connect gateway.</p> <important> <p>If you associate your transit gateway with one or more Direct Connect gateways, the Autonomous System Number (ASN) used by the transit gateway and the Direct Connect gateway must be different. For example, if you use the default ASN 64512 for both your the transit gateway and Direct Connect gateway, the association request fails.</p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656818 = newJObject()
  if body != nil:
    body_402656818 = body
  result = call_402656817.call(nil, nil, nil, nil, body_402656818)

var createTransitVirtualInterface* = Call_CreateTransitVirtualInterface_402656804(
    name: "createTransitVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateTransitVirtualInterface",
    validator: validate_CreateTransitVirtualInterface_402656805, base: "/",
    makeUrl: url_CreateTransitVirtualInterface_402656806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBGPPeer_402656819 = ref object of OpenApiRestCall_402656044
proc url_DeleteBGPPeer_402656821(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBGPPeer_402656820(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specified BGP peer on the specified virtual interface with the specified customer address and ASN.</p> <p>You cannot delete the last BGP peer from a virtual interface.</p>
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
  var valid_402656822 = header.getOrDefault("X-Amz-Target")
  valid_402656822 = validateParameter(valid_402656822, JString, required = true, default = newJString(
      "OvertureService.DeleteBGPPeer"))
  if valid_402656822 != nil:
    section.add "X-Amz-Target", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Security-Token", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Signature")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Signature", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Algorithm", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Date")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Date", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Credential")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Credential", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656829
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

proc call*(call_402656831: Call_DeleteBGPPeer_402656819; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified BGP peer on the specified virtual interface with the specified customer address and ASN.</p> <p>You cannot delete the last BGP peer from a virtual interface.</p>
                                                                                         ## 
  let valid = call_402656831.validator(path, query, header, formData, body, _)
  let scheme = call_402656831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656831.makeUrl(scheme.get, call_402656831.host, call_402656831.base,
                                   call_402656831.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656831, uri, valid, _)

proc call*(call_402656832: Call_DeleteBGPPeer_402656819; body: JsonNode): Recallable =
  ## deleteBGPPeer
  ## <p>Deletes the specified BGP peer on the specified virtual interface with the specified customer address and ASN.</p> <p>You cannot delete the last BGP peer from a virtual interface.</p>
  ##   
                                                                                                                                                                                               ## body: JObject (required)
  var body_402656833 = newJObject()
  if body != nil:
    body_402656833 = body
  result = call_402656832.call(nil, nil, nil, nil, body_402656833)

var deleteBGPPeer* = Call_DeleteBGPPeer_402656819(name: "deleteBGPPeer",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteBGPPeer",
    validator: validate_DeleteBGPPeer_402656820, base: "/",
    makeUrl: url_DeleteBGPPeer_402656821, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_402656834 = ref object of OpenApiRestCall_402656044
proc url_DeleteConnection_402656836(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConnection_402656835(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specified connection.</p> <p>Deleting a connection only stops the AWS Direct Connect port hour and data transfer charges. If you are partnering with any third parties to connect with the AWS Direct Connect location, you must cancel your service with them separately.</p>
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
  var valid_402656837 = header.getOrDefault("X-Amz-Target")
  valid_402656837 = validateParameter(valid_402656837, JString, required = true, default = newJString(
      "OvertureService.DeleteConnection"))
  if valid_402656837 != nil:
    section.add "X-Amz-Target", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Security-Token", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Signature")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Signature", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Algorithm", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Date")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Date", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Credential")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Credential", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656844
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

proc call*(call_402656846: Call_DeleteConnection_402656834;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified connection.</p> <p>Deleting a connection only stops the AWS Direct Connect port hour and data transfer charges. If you are partnering with any third parties to connect with the AWS Direct Connect location, you must cancel your service with them separately.</p>
                                                                                         ## 
  let valid = call_402656846.validator(path, query, header, formData, body, _)
  let scheme = call_402656846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656846.makeUrl(scheme.get, call_402656846.host, call_402656846.base,
                                   call_402656846.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656846, uri, valid, _)

proc call*(call_402656847: Call_DeleteConnection_402656834; body: JsonNode): Recallable =
  ## deleteConnection
  ## <p>Deletes the specified connection.</p> <p>Deleting a connection only stops the AWS Direct Connect port hour and data transfer charges. If you are partnering with any third parties to connect with the AWS Direct Connect location, you must cancel your service with them separately.</p>
  ##   
                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656848 = newJObject()
  if body != nil:
    body_402656848 = body
  result = call_402656847.call(nil, nil, nil, nil, body_402656848)

var deleteConnection* = Call_DeleteConnection_402656834(
    name: "deleteConnection", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteConnection",
    validator: validate_DeleteConnection_402656835, base: "/",
    makeUrl: url_DeleteConnection_402656836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectConnectGateway_402656849 = ref object of OpenApiRestCall_402656044
proc url_DeleteDirectConnectGateway_402656851(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectConnectGateway_402656850(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the specified Direct Connect gateway. You must first delete all virtual interfaces that are attached to the Direct Connect gateway and disassociate all virtual private gateways associated with the Direct Connect gateway.
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
  var valid_402656852 = header.getOrDefault("X-Amz-Target")
  valid_402656852 = validateParameter(valid_402656852, JString, required = true, default = newJString(
      "OvertureService.DeleteDirectConnectGateway"))
  if valid_402656852 != nil:
    section.add "X-Amz-Target", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Security-Token", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Signature")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Signature", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Algorithm", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Date")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Date", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Credential")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Credential", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656859
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

proc call*(call_402656861: Call_DeleteDirectConnectGateway_402656849;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified Direct Connect gateway. You must first delete all virtual interfaces that are attached to the Direct Connect gateway and disassociate all virtual private gateways associated with the Direct Connect gateway.
                                                                                         ## 
  let valid = call_402656861.validator(path, query, header, formData, body, _)
  let scheme = call_402656861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656861.makeUrl(scheme.get, call_402656861.host, call_402656861.base,
                                   call_402656861.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656861, uri, valid, _)

proc call*(call_402656862: Call_DeleteDirectConnectGateway_402656849;
           body: JsonNode): Recallable =
  ## deleteDirectConnectGateway
  ## Deletes the specified Direct Connect gateway. You must first delete all virtual interfaces that are attached to the Direct Connect gateway and disassociate all virtual private gateways associated with the Direct Connect gateway.
  ##   
                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656863 = newJObject()
  if body != nil:
    body_402656863 = body
  result = call_402656862.call(nil, nil, nil, nil, body_402656863)

var deleteDirectConnectGateway* = Call_DeleteDirectConnectGateway_402656849(
    name: "deleteDirectConnectGateway", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteDirectConnectGateway",
    validator: validate_DeleteDirectConnectGateway_402656850, base: "/",
    makeUrl: url_DeleteDirectConnectGateway_402656851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectConnectGatewayAssociation_402656864 = ref object of OpenApiRestCall_402656044
proc url_DeleteDirectConnectGatewayAssociation_402656866(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectConnectGatewayAssociation_402656865(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes the association between the specified Direct Connect gateway and virtual private gateway.</p> <p>We recommend that you specify the <code>associationID</code> to delete the association. Alternatively, if you own virtual gateway and a Direct Connect gateway association, you can specify the <code>virtualGatewayId</code> and <code>directConnectGatewayId</code> to delete an association.</p>
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
  var valid_402656867 = header.getOrDefault("X-Amz-Target")
  valid_402656867 = validateParameter(valid_402656867, JString, required = true, default = newJString(
      "OvertureService.DeleteDirectConnectGatewayAssociation"))
  if valid_402656867 != nil:
    section.add "X-Amz-Target", valid_402656867
  var valid_402656868 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656868 = validateParameter(valid_402656868, JString,
                                      required = false, default = nil)
  if valid_402656868 != nil:
    section.add "X-Amz-Security-Token", valid_402656868
  var valid_402656869 = header.getOrDefault("X-Amz-Signature")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-Signature", valid_402656869
  var valid_402656870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Algorithm", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Date")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Date", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Credential")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Credential", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656874
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

proc call*(call_402656876: Call_DeleteDirectConnectGatewayAssociation_402656864;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the association between the specified Direct Connect gateway and virtual private gateway.</p> <p>We recommend that you specify the <code>associationID</code> to delete the association. Alternatively, if you own virtual gateway and a Direct Connect gateway association, you can specify the <code>virtualGatewayId</code> and <code>directConnectGatewayId</code> to delete an association.</p>
                                                                                         ## 
  let valid = call_402656876.validator(path, query, header, formData, body, _)
  let scheme = call_402656876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656876.makeUrl(scheme.get, call_402656876.host, call_402656876.base,
                                   call_402656876.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656876, uri, valid, _)

proc call*(call_402656877: Call_DeleteDirectConnectGatewayAssociation_402656864;
           body: JsonNode): Recallable =
  ## deleteDirectConnectGatewayAssociation
  ## <p>Deletes the association between the specified Direct Connect gateway and virtual private gateway.</p> <p>We recommend that you specify the <code>associationID</code> to delete the association. Alternatively, if you own virtual gateway and a Direct Connect gateway association, you can specify the <code>virtualGatewayId</code> and <code>directConnectGatewayId</code> to delete an association.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656878 = newJObject()
  if body != nil:
    body_402656878 = body
  result = call_402656877.call(nil, nil, nil, nil, body_402656878)

var deleteDirectConnectGatewayAssociation* = Call_DeleteDirectConnectGatewayAssociation_402656864(
    name: "deleteDirectConnectGatewayAssociation", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DeleteDirectConnectGatewayAssociation",
    validator: validate_DeleteDirectConnectGatewayAssociation_402656865,
    base: "/", makeUrl: url_DeleteDirectConnectGatewayAssociation_402656866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectConnectGatewayAssociationProposal_402656879 = ref object of OpenApiRestCall_402656044
proc url_DeleteDirectConnectGatewayAssociationProposal_402656881(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectConnectGatewayAssociationProposal_402656880(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the association proposal request between the specified Direct Connect gateway and virtual private gateway or transit gateway.
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
  var valid_402656882 = header.getOrDefault("X-Amz-Target")
  valid_402656882 = validateParameter(valid_402656882, JString, required = true, default = newJString(
      "OvertureService.DeleteDirectConnectGatewayAssociationProposal"))
  if valid_402656882 != nil:
    section.add "X-Amz-Target", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Security-Token", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-Signature")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Signature", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Algorithm", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Date")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Date", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Credential")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Credential", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656889
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

proc call*(call_402656891: Call_DeleteDirectConnectGatewayAssociationProposal_402656879;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the association proposal request between the specified Direct Connect gateway and virtual private gateway or transit gateway.
                                                                                         ## 
  let valid = call_402656891.validator(path, query, header, formData, body, _)
  let scheme = call_402656891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656891.makeUrl(scheme.get, call_402656891.host, call_402656891.base,
                                   call_402656891.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656891, uri, valid, _)

proc call*(call_402656892: Call_DeleteDirectConnectGatewayAssociationProposal_402656879;
           body: JsonNode): Recallable =
  ## deleteDirectConnectGatewayAssociationProposal
  ## Deletes the association proposal request between the specified Direct Connect gateway and virtual private gateway or transit gateway.
  ##   
                                                                                                                                          ## body: JObject (required)
  var body_402656893 = newJObject()
  if body != nil:
    body_402656893 = body
  result = call_402656892.call(nil, nil, nil, nil, body_402656893)

var deleteDirectConnectGatewayAssociationProposal* = Call_DeleteDirectConnectGatewayAssociationProposal_402656879(
    name: "deleteDirectConnectGatewayAssociationProposal",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DeleteDirectConnectGatewayAssociationProposal",
    validator: validate_DeleteDirectConnectGatewayAssociationProposal_402656880,
    base: "/", makeUrl: url_DeleteDirectConnectGatewayAssociationProposal_402656881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInterconnect_402656894 = ref object of OpenApiRestCall_402656044
proc url_DeleteInterconnect_402656896(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInterconnect_402656895(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
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
  var valid_402656897 = header.getOrDefault("X-Amz-Target")
  valid_402656897 = validateParameter(valid_402656897, JString, required = true, default = newJString(
      "OvertureService.DeleteInterconnect"))
  if valid_402656897 != nil:
    section.add "X-Amz-Target", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Security-Token", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-Signature")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Signature", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Algorithm", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Date")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Date", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Credential")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Credential", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656904
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

proc call*(call_402656906: Call_DeleteInterconnect_402656894;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
                                                                                         ## 
  let valid = call_402656906.validator(path, query, header, formData, body, _)
  let scheme = call_402656906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656906.makeUrl(scheme.get, call_402656906.host, call_402656906.base,
                                   call_402656906.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656906, uri, valid, _)

proc call*(call_402656907: Call_DeleteInterconnect_402656894; body: JsonNode): Recallable =
  ## deleteInterconnect
  ## <p>Deletes the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   
                                                                                                                           ## body: JObject (required)
  var body_402656908 = newJObject()
  if body != nil:
    body_402656908 = body
  result = call_402656907.call(nil, nil, nil, nil, body_402656908)

var deleteInterconnect* = Call_DeleteInterconnect_402656894(
    name: "deleteInterconnect", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteInterconnect",
    validator: validate_DeleteInterconnect_402656895, base: "/",
    makeUrl: url_DeleteInterconnect_402656896,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLag_402656909 = ref object of OpenApiRestCall_402656044
proc url_DeleteLag_402656911(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLag_402656910(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified link aggregation group (LAG). You cannot delete a LAG if it has active virtual interfaces or hosted connections.
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
  var valid_402656912 = header.getOrDefault("X-Amz-Target")
  valid_402656912 = validateParameter(valid_402656912, JString, required = true, default = newJString(
      "OvertureService.DeleteLag"))
  if valid_402656912 != nil:
    section.add "X-Amz-Target", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Security-Token", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Signature")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Signature", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Algorithm", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-Date")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Date", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Credential")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Credential", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656919
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

proc call*(call_402656921: Call_DeleteLag_402656909; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified link aggregation group (LAG). You cannot delete a LAG if it has active virtual interfaces or hosted connections.
                                                                                         ## 
  let valid = call_402656921.validator(path, query, header, formData, body, _)
  let scheme = call_402656921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656921.makeUrl(scheme.get, call_402656921.host, call_402656921.base,
                                   call_402656921.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656921, uri, valid, _)

proc call*(call_402656922: Call_DeleteLag_402656909; body: JsonNode): Recallable =
  ## deleteLag
  ## Deletes the specified link aggregation group (LAG). You cannot delete a LAG if it has active virtual interfaces or hosted connections.
  ##   
                                                                                                                                           ## body: JObject (required)
  var body_402656923 = newJObject()
  if body != nil:
    body_402656923 = body
  result = call_402656922.call(nil, nil, nil, nil, body_402656923)

var deleteLag* = Call_DeleteLag_402656909(name: "deleteLag",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteLag",
    validator: validate_DeleteLag_402656910, base: "/", makeUrl: url_DeleteLag_402656911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualInterface_402656924 = ref object of OpenApiRestCall_402656044
proc url_DeleteVirtualInterface_402656926(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteVirtualInterface_402656925(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a virtual interface.
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
  var valid_402656927 = header.getOrDefault("X-Amz-Target")
  valid_402656927 = validateParameter(valid_402656927, JString, required = true, default = newJString(
      "OvertureService.DeleteVirtualInterface"))
  if valid_402656927 != nil:
    section.add "X-Amz-Target", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-Security-Token", valid_402656928
  var valid_402656929 = header.getOrDefault("X-Amz-Signature")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Signature", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Algorithm", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-Date")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Date", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Credential")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Credential", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656934
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

proc call*(call_402656936: Call_DeleteVirtualInterface_402656924;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a virtual interface.
                                                                                         ## 
  let valid = call_402656936.validator(path, query, header, formData, body, _)
  let scheme = call_402656936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656936.makeUrl(scheme.get, call_402656936.host, call_402656936.base,
                                   call_402656936.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656936, uri, valid, _)

proc call*(call_402656937: Call_DeleteVirtualInterface_402656924; body: JsonNode): Recallable =
  ## deleteVirtualInterface
  ## Deletes a virtual interface.
  ##   body: JObject (required)
  var body_402656938 = newJObject()
  if body != nil:
    body_402656938 = body
  result = call_402656937.call(nil, nil, nil, nil, body_402656938)

var deleteVirtualInterface* = Call_DeleteVirtualInterface_402656924(
    name: "deleteVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteVirtualInterface",
    validator: validate_DeleteVirtualInterface_402656925, base: "/",
    makeUrl: url_DeleteVirtualInterface_402656926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnectionLoa_402656939 = ref object of OpenApiRestCall_402656044
proc url_DescribeConnectionLoa_402656941(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConnectionLoa_402656940(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for a connection.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that your APN partner or service provider uses when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
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
  var valid_402656942 = header.getOrDefault("X-Amz-Target")
  valid_402656942 = validateParameter(valid_402656942, JString, required = true, default = newJString(
      "OvertureService.DescribeConnectionLoa"))
  if valid_402656942 != nil:
    section.add "X-Amz-Target", valid_402656942
  var valid_402656943 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656943 = validateParameter(valid_402656943, JString,
                                      required = false, default = nil)
  if valid_402656943 != nil:
    section.add "X-Amz-Security-Token", valid_402656943
  var valid_402656944 = header.getOrDefault("X-Amz-Signature")
  valid_402656944 = validateParameter(valid_402656944, JString,
                                      required = false, default = nil)
  if valid_402656944 != nil:
    section.add "X-Amz-Signature", valid_402656944
  var valid_402656945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656945 = validateParameter(valid_402656945, JString,
                                      required = false, default = nil)
  if valid_402656945 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Algorithm", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Date")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Date", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-Credential")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-Credential", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656949
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

proc call*(call_402656951: Call_DescribeConnectionLoa_402656939;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for a connection.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that your APN partner or service provider uses when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656951.validator(path, query, header, formData, body, _)
  let scheme = call_402656951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656951.makeUrl(scheme.get, call_402656951.host, call_402656951.base,
                                   call_402656951.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656951, uri, valid, _)

proc call*(call_402656952: Call_DescribeConnectionLoa_402656939; body: JsonNode): Recallable =
  ## describeConnectionLoa
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for a connection.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that your APN partner or service provider uses when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656953 = newJObject()
  if body != nil:
    body_402656953 = body
  result = call_402656952.call(nil, nil, nil, nil, body_402656953)

var describeConnectionLoa* = Call_DescribeConnectionLoa_402656939(
    name: "describeConnectionLoa", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeConnectionLoa",
    validator: validate_DescribeConnectionLoa_402656940, base: "/",
    makeUrl: url_DescribeConnectionLoa_402656941,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnections_402656954 = ref object of OpenApiRestCall_402656044
proc url_DescribeConnections_402656956(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConnections_402656955(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Displays the specified connection or all connections in this Region.
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
  var valid_402656957 = header.getOrDefault("X-Amz-Target")
  valid_402656957 = validateParameter(valid_402656957, JString, required = true, default = newJString(
      "OvertureService.DescribeConnections"))
  if valid_402656957 != nil:
    section.add "X-Amz-Target", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Security-Token", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-Signature")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Signature", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Algorithm", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Date")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Date", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-Credential")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-Credential", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656964
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

proc call*(call_402656966: Call_DescribeConnections_402656954;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays the specified connection or all connections in this Region.
                                                                                         ## 
  let valid = call_402656966.validator(path, query, header, formData, body, _)
  let scheme = call_402656966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656966.makeUrl(scheme.get, call_402656966.host, call_402656966.base,
                                   call_402656966.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656966, uri, valid, _)

proc call*(call_402656967: Call_DescribeConnections_402656954; body: JsonNode): Recallable =
  ## describeConnections
  ## Displays the specified connection or all connections in this Region.
  ##   body: JObject 
                                                                         ## (required)
  var body_402656968 = newJObject()
  if body != nil:
    body_402656968 = body
  result = call_402656967.call(nil, nil, nil, nil, body_402656968)

var describeConnections* = Call_DescribeConnections_402656954(
    name: "describeConnections", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeConnections",
    validator: validate_DescribeConnections_402656955, base: "/",
    makeUrl: url_DescribeConnections_402656956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnectionsOnInterconnect_402656969 = ref object of OpenApiRestCall_402656044
proc url_DescribeConnectionsOnInterconnect_402656971(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConnectionsOnInterconnect_402656970(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deprecated. Use <a>DescribeHostedConnections</a> instead.</p> <p>Lists the connections that have been provisioned on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
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
  var valid_402656972 = header.getOrDefault("X-Amz-Target")
  valid_402656972 = validateParameter(valid_402656972, JString, required = true, default = newJString(
      "OvertureService.DescribeConnectionsOnInterconnect"))
  if valid_402656972 != nil:
    section.add "X-Amz-Target", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Security-Token", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Signature")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Signature", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Algorithm", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Date")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Date", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Credential")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Credential", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656979
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

proc call*(call_402656981: Call_DescribeConnectionsOnInterconnect_402656969;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deprecated. Use <a>DescribeHostedConnections</a> instead.</p> <p>Lists the connections that have been provisioned on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
                                                                                         ## 
  let valid = call_402656981.validator(path, query, header, formData, body, _)
  let scheme = call_402656981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656981.makeUrl(scheme.get, call_402656981.host, call_402656981.base,
                                   call_402656981.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656981, uri, valid, _)

proc call*(call_402656982: Call_DescribeConnectionsOnInterconnect_402656969;
           body: JsonNode): Recallable =
  ## describeConnectionsOnInterconnect
  ## <p>Deprecated. Use <a>DescribeHostedConnections</a> instead.</p> <p>Lists the connections that have been provisioned on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   
                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656983 = newJObject()
  if body != nil:
    body_402656983 = body
  result = call_402656982.call(nil, nil, nil, nil, body_402656983)

var describeConnectionsOnInterconnect* = Call_DescribeConnectionsOnInterconnect_402656969(
    name: "describeConnectionsOnInterconnect", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeConnectionsOnInterconnect",
    validator: validate_DescribeConnectionsOnInterconnect_402656970, base: "/",
    makeUrl: url_DescribeConnectionsOnInterconnect_402656971,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectConnectGatewayAssociationProposals_402656984 = ref object of OpenApiRestCall_402656044
proc url_DescribeDirectConnectGatewayAssociationProposals_402656986(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectConnectGatewayAssociationProposals_402656985(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Describes one or more association proposals for connection between a virtual private gateway or transit gateway and a Direct Connect gateway. 
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
  var valid_402656987 = header.getOrDefault("X-Amz-Target")
  valid_402656987 = validateParameter(valid_402656987, JString, required = true, default = newJString(
      "OvertureService.DescribeDirectConnectGatewayAssociationProposals"))
  if valid_402656987 != nil:
    section.add "X-Amz-Target", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-Security-Token", valid_402656988
  var valid_402656989 = header.getOrDefault("X-Amz-Signature")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-Signature", valid_402656989
  var valid_402656990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-Algorithm", valid_402656991
  var valid_402656992 = header.getOrDefault("X-Amz-Date")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "X-Amz-Date", valid_402656992
  var valid_402656993 = header.getOrDefault("X-Amz-Credential")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Credential", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656994
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

proc call*(call_402656996: Call_DescribeDirectConnectGatewayAssociationProposals_402656984;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes one or more association proposals for connection between a virtual private gateway or transit gateway and a Direct Connect gateway. 
                                                                                         ## 
  let valid = call_402656996.validator(path, query, header, formData, body, _)
  let scheme = call_402656996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656996.makeUrl(scheme.get, call_402656996.host, call_402656996.base,
                                   call_402656996.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656996, uri, valid, _)

proc call*(call_402656997: Call_DescribeDirectConnectGatewayAssociationProposals_402656984;
           body: JsonNode): Recallable =
  ## describeDirectConnectGatewayAssociationProposals
  ## Describes one or more association proposals for connection between a virtual private gateway or transit gateway and a Direct Connect gateway. 
  ##   
                                                                                                                                                   ## body: JObject (required)
  var body_402656998 = newJObject()
  if body != nil:
    body_402656998 = body
  result = call_402656997.call(nil, nil, nil, nil, body_402656998)

var describeDirectConnectGatewayAssociationProposals* = Call_DescribeDirectConnectGatewayAssociationProposals_402656984(
    name: "describeDirectConnectGatewayAssociationProposals",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DescribeDirectConnectGatewayAssociationProposals",
    validator: validate_DescribeDirectConnectGatewayAssociationProposals_402656985,
    base: "/", makeUrl: url_DescribeDirectConnectGatewayAssociationProposals_402656986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectConnectGatewayAssociations_402656999 = ref object of OpenApiRestCall_402656044
proc url_DescribeDirectConnectGatewayAssociations_402657001(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectConnectGatewayAssociations_402657000(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the associations between your Direct Connect gateways and virtual private gateways. You must specify a Direct Connect gateway, a virtual private gateway, or both. If you specify a Direct Connect gateway, the response contains all virtual private gateways associated with the Direct Connect gateway. If you specify a virtual private gateway, the response contains all Direct Connect gateways associated with the virtual private gateway. If you specify both, the response contains the association between the Direct Connect gateway and the virtual private gateway.
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
  var valid_402657002 = header.getOrDefault("X-Amz-Target")
  valid_402657002 = validateParameter(valid_402657002, JString, required = true, default = newJString(
      "OvertureService.DescribeDirectConnectGatewayAssociations"))
  if valid_402657002 != nil:
    section.add "X-Amz-Target", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-Security-Token", valid_402657003
  var valid_402657004 = header.getOrDefault("X-Amz-Signature")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "X-Amz-Signature", valid_402657004
  var valid_402657005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657005 = validateParameter(valid_402657005, JString,
                                      required = false, default = nil)
  if valid_402657005 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657005
  var valid_402657006 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657006 = validateParameter(valid_402657006, JString,
                                      required = false, default = nil)
  if valid_402657006 != nil:
    section.add "X-Amz-Algorithm", valid_402657006
  var valid_402657007 = header.getOrDefault("X-Amz-Date")
  valid_402657007 = validateParameter(valid_402657007, JString,
                                      required = false, default = nil)
  if valid_402657007 != nil:
    section.add "X-Amz-Date", valid_402657007
  var valid_402657008 = header.getOrDefault("X-Amz-Credential")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "X-Amz-Credential", valid_402657008
  var valid_402657009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657009
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

proc call*(call_402657011: Call_DescribeDirectConnectGatewayAssociations_402656999;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the associations between your Direct Connect gateways and virtual private gateways. You must specify a Direct Connect gateway, a virtual private gateway, or both. If you specify a Direct Connect gateway, the response contains all virtual private gateways associated with the Direct Connect gateway. If you specify a virtual private gateway, the response contains all Direct Connect gateways associated with the virtual private gateway. If you specify both, the response contains the association between the Direct Connect gateway and the virtual private gateway.
                                                                                         ## 
  let valid = call_402657011.validator(path, query, header, formData, body, _)
  let scheme = call_402657011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657011.makeUrl(scheme.get, call_402657011.host, call_402657011.base,
                                   call_402657011.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657011, uri, valid, _)

proc call*(call_402657012: Call_DescribeDirectConnectGatewayAssociations_402656999;
           body: JsonNode): Recallable =
  ## describeDirectConnectGatewayAssociations
  ## Lists the associations between your Direct Connect gateways and virtual private gateways. You must specify a Direct Connect gateway, a virtual private gateway, or both. If you specify a Direct Connect gateway, the response contains all virtual private gateways associated with the Direct Connect gateway. If you specify a virtual private gateway, the response contains all Direct Connect gateways associated with the virtual private gateway. If you specify both, the response contains the association between the Direct Connect gateway and the virtual private gateway.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402657013 = newJObject()
  if body != nil:
    body_402657013 = body
  result = call_402657012.call(nil, nil, nil, nil, body_402657013)

var describeDirectConnectGatewayAssociations* = Call_DescribeDirectConnectGatewayAssociations_402656999(
    name: "describeDirectConnectGatewayAssociations", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DescribeDirectConnectGatewayAssociations",
    validator: validate_DescribeDirectConnectGatewayAssociations_402657000,
    base: "/", makeUrl: url_DescribeDirectConnectGatewayAssociations_402657001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectConnectGatewayAttachments_402657014 = ref object of OpenApiRestCall_402656044
proc url_DescribeDirectConnectGatewayAttachments_402657016(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectConnectGatewayAttachments_402657015(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the attachments between your Direct Connect gateways and virtual interfaces. You must specify a Direct Connect gateway, a virtual interface, or both. If you specify a Direct Connect gateway, the response contains all virtual interfaces attached to the Direct Connect gateway. If you specify a virtual interface, the response contains all Direct Connect gateways attached to the virtual interface. If you specify both, the response contains the attachment between the Direct Connect gateway and the virtual interface.
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
  var valid_402657017 = header.getOrDefault("X-Amz-Target")
  valid_402657017 = validateParameter(valid_402657017, JString, required = true, default = newJString(
      "OvertureService.DescribeDirectConnectGatewayAttachments"))
  if valid_402657017 != nil:
    section.add "X-Amz-Target", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-Security-Token", valid_402657018
  var valid_402657019 = header.getOrDefault("X-Amz-Signature")
  valid_402657019 = validateParameter(valid_402657019, JString,
                                      required = false, default = nil)
  if valid_402657019 != nil:
    section.add "X-Amz-Signature", valid_402657019
  var valid_402657020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657020
  var valid_402657021 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "X-Amz-Algorithm", valid_402657021
  var valid_402657022 = header.getOrDefault("X-Amz-Date")
  valid_402657022 = validateParameter(valid_402657022, JString,
                                      required = false, default = nil)
  if valid_402657022 != nil:
    section.add "X-Amz-Date", valid_402657022
  var valid_402657023 = header.getOrDefault("X-Amz-Credential")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "X-Amz-Credential", valid_402657023
  var valid_402657024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657024
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

proc call*(call_402657026: Call_DescribeDirectConnectGatewayAttachments_402657014;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the attachments between your Direct Connect gateways and virtual interfaces. You must specify a Direct Connect gateway, a virtual interface, or both. If you specify a Direct Connect gateway, the response contains all virtual interfaces attached to the Direct Connect gateway. If you specify a virtual interface, the response contains all Direct Connect gateways attached to the virtual interface. If you specify both, the response contains the attachment between the Direct Connect gateway and the virtual interface.
                                                                                         ## 
  let valid = call_402657026.validator(path, query, header, formData, body, _)
  let scheme = call_402657026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657026.makeUrl(scheme.get, call_402657026.host, call_402657026.base,
                                   call_402657026.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657026, uri, valid, _)

proc call*(call_402657027: Call_DescribeDirectConnectGatewayAttachments_402657014;
           body: JsonNode): Recallable =
  ## describeDirectConnectGatewayAttachments
  ## Lists the attachments between your Direct Connect gateways and virtual interfaces. You must specify a Direct Connect gateway, a virtual interface, or both. If you specify a Direct Connect gateway, the response contains all virtual interfaces attached to the Direct Connect gateway. If you specify a virtual interface, the response contains all Direct Connect gateways attached to the virtual interface. If you specify both, the response contains the attachment between the Direct Connect gateway and the virtual interface.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402657028 = newJObject()
  if body != nil:
    body_402657028 = body
  result = call_402657027.call(nil, nil, nil, nil, body_402657028)

var describeDirectConnectGatewayAttachments* = Call_DescribeDirectConnectGatewayAttachments_402657014(
    name: "describeDirectConnectGatewayAttachments", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DescribeDirectConnectGatewayAttachments",
    validator: validate_DescribeDirectConnectGatewayAttachments_402657015,
    base: "/", makeUrl: url_DescribeDirectConnectGatewayAttachments_402657016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectConnectGateways_402657029 = ref object of OpenApiRestCall_402656044
proc url_DescribeDirectConnectGateways_402657031(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectConnectGateways_402657030(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists all your Direct Connect gateways or only the specified Direct Connect gateway. Deleted Direct Connect gateways are not returned.
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
  var valid_402657032 = header.getOrDefault("X-Amz-Target")
  valid_402657032 = validateParameter(valid_402657032, JString, required = true, default = newJString(
      "OvertureService.DescribeDirectConnectGateways"))
  if valid_402657032 != nil:
    section.add "X-Amz-Target", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-Security-Token", valid_402657033
  var valid_402657034 = header.getOrDefault("X-Amz-Signature")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-Signature", valid_402657034
  var valid_402657035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657035
  var valid_402657036 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-Algorithm", valid_402657036
  var valid_402657037 = header.getOrDefault("X-Amz-Date")
  valid_402657037 = validateParameter(valid_402657037, JString,
                                      required = false, default = nil)
  if valid_402657037 != nil:
    section.add "X-Amz-Date", valid_402657037
  var valid_402657038 = header.getOrDefault("X-Amz-Credential")
  valid_402657038 = validateParameter(valid_402657038, JString,
                                      required = false, default = nil)
  if valid_402657038 != nil:
    section.add "X-Amz-Credential", valid_402657038
  var valid_402657039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657039
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

proc call*(call_402657041: Call_DescribeDirectConnectGateways_402657029;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all your Direct Connect gateways or only the specified Direct Connect gateway. Deleted Direct Connect gateways are not returned.
                                                                                         ## 
  let valid = call_402657041.validator(path, query, header, formData, body, _)
  let scheme = call_402657041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657041.makeUrl(scheme.get, call_402657041.host, call_402657041.base,
                                   call_402657041.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657041, uri, valid, _)

proc call*(call_402657042: Call_DescribeDirectConnectGateways_402657029;
           body: JsonNode): Recallable =
  ## describeDirectConnectGateways
  ## Lists all your Direct Connect gateways or only the specified Direct Connect gateway. Deleted Direct Connect gateways are not returned.
  ##   
                                                                                                                                           ## body: JObject (required)
  var body_402657043 = newJObject()
  if body != nil:
    body_402657043 = body
  result = call_402657042.call(nil, nil, nil, nil, body_402657043)

var describeDirectConnectGateways* = Call_DescribeDirectConnectGateways_402657029(
    name: "describeDirectConnectGateways", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeDirectConnectGateways",
    validator: validate_DescribeDirectConnectGateways_402657030, base: "/",
    makeUrl: url_DescribeDirectConnectGateways_402657031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHostedConnections_402657044 = ref object of OpenApiRestCall_402656044
proc url_DescribeHostedConnections_402657046(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHostedConnections_402657045(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Lists the hosted connections that have been provisioned on the specified interconnect or link aggregation group (LAG).</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
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
  var valid_402657047 = header.getOrDefault("X-Amz-Target")
  valid_402657047 = validateParameter(valid_402657047, JString, required = true, default = newJString(
      "OvertureService.DescribeHostedConnections"))
  if valid_402657047 != nil:
    section.add "X-Amz-Target", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Security-Token", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-Signature")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-Signature", valid_402657049
  var valid_402657050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-Algorithm", valid_402657051
  var valid_402657052 = header.getOrDefault("X-Amz-Date")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Date", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-Credential")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-Credential", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657054
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

proc call*(call_402657056: Call_DescribeHostedConnections_402657044;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the hosted connections that have been provisioned on the specified interconnect or link aggregation group (LAG).</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
                                                                                         ## 
  let valid = call_402657056.validator(path, query, header, formData, body, _)
  let scheme = call_402657056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657056.makeUrl(scheme.get, call_402657056.host, call_402657056.base,
                                   call_402657056.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657056, uri, valid, _)

proc call*(call_402657057: Call_DescribeHostedConnections_402657044;
           body: JsonNode): Recallable =
  ## describeHostedConnections
  ## <p>Lists the hosted connections that have been provisioned on the specified interconnect or link aggregation group (LAG).</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   
                                                                                                                                                                                                              ## body: JObject (required)
  var body_402657058 = newJObject()
  if body != nil:
    body_402657058 = body
  result = call_402657057.call(nil, nil, nil, nil, body_402657058)

var describeHostedConnections* = Call_DescribeHostedConnections_402657044(
    name: "describeHostedConnections", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeHostedConnections",
    validator: validate_DescribeHostedConnections_402657045, base: "/",
    makeUrl: url_DescribeHostedConnections_402657046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInterconnectLoa_402657059 = ref object of OpenApiRestCall_402656044
proc url_DescribeInterconnectLoa_402657061(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInterconnectLoa_402657060(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for the specified interconnect.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
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
  var valid_402657062 = header.getOrDefault("X-Amz-Target")
  valid_402657062 = validateParameter(valid_402657062, JString, required = true, default = newJString(
      "OvertureService.DescribeInterconnectLoa"))
  if valid_402657062 != nil:
    section.add "X-Amz-Target", valid_402657062
  var valid_402657063 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-Security-Token", valid_402657063
  var valid_402657064 = header.getOrDefault("X-Amz-Signature")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-Signature", valid_402657064
  var valid_402657065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657065 = validateParameter(valid_402657065, JString,
                                      required = false, default = nil)
  if valid_402657065 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-Algorithm", valid_402657066
  var valid_402657067 = header.getOrDefault("X-Amz-Date")
  valid_402657067 = validateParameter(valid_402657067, JString,
                                      required = false, default = nil)
  if valid_402657067 != nil:
    section.add "X-Amz-Date", valid_402657067
  var valid_402657068 = header.getOrDefault("X-Amz-Credential")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "X-Amz-Credential", valid_402657068
  var valid_402657069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657069 = validateParameter(valid_402657069, JString,
                                      required = false, default = nil)
  if valid_402657069 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657069
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

proc call*(call_402657071: Call_DescribeInterconnectLoa_402657059;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for the specified interconnect.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
                                                                                         ## 
  let valid = call_402657071.validator(path, query, header, formData, body, _)
  let scheme = call_402657071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657071.makeUrl(scheme.get, call_402657071.host, call_402657071.base,
                                   call_402657071.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657071, uri, valid, _)

proc call*(call_402657072: Call_DescribeInterconnectLoa_402657059;
           body: JsonNode): Recallable =
  ## describeInterconnectLoa
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for the specified interconnect.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402657073 = newJObject()
  if body != nil:
    body_402657073 = body
  result = call_402657072.call(nil, nil, nil, nil, body_402657073)

var describeInterconnectLoa* = Call_DescribeInterconnectLoa_402657059(
    name: "describeInterconnectLoa", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeInterconnectLoa",
    validator: validate_DescribeInterconnectLoa_402657060, base: "/",
    makeUrl: url_DescribeInterconnectLoa_402657061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInterconnects_402657074 = ref object of OpenApiRestCall_402656044
proc url_DescribeInterconnects_402657076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInterconnects_402657075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the interconnects owned by the AWS account or only the specified interconnect.
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
  var valid_402657077 = header.getOrDefault("X-Amz-Target")
  valid_402657077 = validateParameter(valid_402657077, JString, required = true, default = newJString(
      "OvertureService.DescribeInterconnects"))
  if valid_402657077 != nil:
    section.add "X-Amz-Target", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-Security-Token", valid_402657078
  var valid_402657079 = header.getOrDefault("X-Amz-Signature")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Signature", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-Algorithm", valid_402657081
  var valid_402657082 = header.getOrDefault("X-Amz-Date")
  valid_402657082 = validateParameter(valid_402657082, JString,
                                      required = false, default = nil)
  if valid_402657082 != nil:
    section.add "X-Amz-Date", valid_402657082
  var valid_402657083 = header.getOrDefault("X-Amz-Credential")
  valid_402657083 = validateParameter(valid_402657083, JString,
                                      required = false, default = nil)
  if valid_402657083 != nil:
    section.add "X-Amz-Credential", valid_402657083
  var valid_402657084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657084 = validateParameter(valid_402657084, JString,
                                      required = false, default = nil)
  if valid_402657084 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657084
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

proc call*(call_402657086: Call_DescribeInterconnects_402657074;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the interconnects owned by the AWS account or only the specified interconnect.
                                                                                         ## 
  let valid = call_402657086.validator(path, query, header, formData, body, _)
  let scheme = call_402657086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657086.makeUrl(scheme.get, call_402657086.host, call_402657086.base,
                                   call_402657086.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657086, uri, valid, _)

proc call*(call_402657087: Call_DescribeInterconnects_402657074; body: JsonNode): Recallable =
  ## describeInterconnects
  ## Lists the interconnects owned by the AWS account or only the specified interconnect.
  ##   
                                                                                         ## body: JObject (required)
  var body_402657088 = newJObject()
  if body != nil:
    body_402657088 = body
  result = call_402657087.call(nil, nil, nil, nil, body_402657088)

var describeInterconnects* = Call_DescribeInterconnects_402657074(
    name: "describeInterconnects", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeInterconnects",
    validator: validate_DescribeInterconnects_402657075, base: "/",
    makeUrl: url_DescribeInterconnects_402657076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLags_402657089 = ref object of OpenApiRestCall_402656044
proc url_DescribeLags_402657091(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLags_402657090(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes all your link aggregation groups (LAG) or the specified LAG.
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
  var valid_402657092 = header.getOrDefault("X-Amz-Target")
  valid_402657092 = validateParameter(valid_402657092, JString, required = true, default = newJString(
      "OvertureService.DescribeLags"))
  if valid_402657092 != nil:
    section.add "X-Amz-Target", valid_402657092
  var valid_402657093 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "X-Amz-Security-Token", valid_402657093
  var valid_402657094 = header.getOrDefault("X-Amz-Signature")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Signature", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Algorithm", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-Date")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Date", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-Credential")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-Credential", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657099
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

proc call*(call_402657101: Call_DescribeLags_402657089; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes all your link aggregation groups (LAG) or the specified LAG.
                                                                                         ## 
  let valid = call_402657101.validator(path, query, header, formData, body, _)
  let scheme = call_402657101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657101.makeUrl(scheme.get, call_402657101.host, call_402657101.base,
                                   call_402657101.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657101, uri, valid, _)

proc call*(call_402657102: Call_DescribeLags_402657089; body: JsonNode): Recallable =
  ## describeLags
  ## Describes all your link aggregation groups (LAG) or the specified LAG.
  ##   body: 
                                                                           ## JObject (required)
  var body_402657103 = newJObject()
  if body != nil:
    body_402657103 = body
  result = call_402657102.call(nil, nil, nil, nil, body_402657103)

var describeLags* = Call_DescribeLags_402657089(name: "describeLags",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeLags",
    validator: validate_DescribeLags_402657090, base: "/",
    makeUrl: url_DescribeLags_402657091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoa_402657104 = ref object of OpenApiRestCall_402656044
proc url_DescribeLoa_402657106(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLoa_402657105(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets the LOA-CFA for a connection, interconnect, or link aggregation group (LAG).</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
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
  var valid_402657107 = header.getOrDefault("X-Amz-Target")
  valid_402657107 = validateParameter(valid_402657107, JString, required = true, default = newJString(
      "OvertureService.DescribeLoa"))
  if valid_402657107 != nil:
    section.add "X-Amz-Target", valid_402657107
  var valid_402657108 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657108 = validateParameter(valid_402657108, JString,
                                      required = false, default = nil)
  if valid_402657108 != nil:
    section.add "X-Amz-Security-Token", valid_402657108
  var valid_402657109 = header.getOrDefault("X-Amz-Signature")
  valid_402657109 = validateParameter(valid_402657109, JString,
                                      required = false, default = nil)
  if valid_402657109 != nil:
    section.add "X-Amz-Signature", valid_402657109
  var valid_402657110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657110
  var valid_402657111 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "X-Amz-Algorithm", valid_402657111
  var valid_402657112 = header.getOrDefault("X-Amz-Date")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "X-Amz-Date", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-Credential")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-Credential", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657114
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

proc call*(call_402657116: Call_DescribeLoa_402657104; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the LOA-CFA for a connection, interconnect, or link aggregation group (LAG).</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
                                                                                         ## 
  let valid = call_402657116.validator(path, query, header, formData, body, _)
  let scheme = call_402657116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657116.makeUrl(scheme.get, call_402657116.host, call_402657116.base,
                                   call_402657116.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657116, uri, valid, _)

proc call*(call_402657117: Call_DescribeLoa_402657104; body: JsonNode): Recallable =
  ## describeLoa
  ## <p>Gets the LOA-CFA for a connection, interconnect, or link aggregation group (LAG).</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657118 = newJObject()
  if body != nil:
    body_402657118 = body
  result = call_402657117.call(nil, nil, nil, nil, body_402657118)

var describeLoa* = Call_DescribeLoa_402657104(name: "describeLoa",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeLoa",
    validator: validate_DescribeLoa_402657105, base: "/",
    makeUrl: url_DescribeLoa_402657106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocations_402657119 = ref object of OpenApiRestCall_402656044
proc url_DescribeLocations_402657121(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLocations_402657120(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the AWS Direct Connect locations in the current AWS Region. These are the locations that can be selected when calling <a>CreateConnection</a> or <a>CreateInterconnect</a>.
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
  var valid_402657122 = header.getOrDefault("X-Amz-Target")
  valid_402657122 = validateParameter(valid_402657122, JString, required = true, default = newJString(
      "OvertureService.DescribeLocations"))
  if valid_402657122 != nil:
    section.add "X-Amz-Target", valid_402657122
  var valid_402657123 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657123 = validateParameter(valid_402657123, JString,
                                      required = false, default = nil)
  if valid_402657123 != nil:
    section.add "X-Amz-Security-Token", valid_402657123
  var valid_402657124 = header.getOrDefault("X-Amz-Signature")
  valid_402657124 = validateParameter(valid_402657124, JString,
                                      required = false, default = nil)
  if valid_402657124 != nil:
    section.add "X-Amz-Signature", valid_402657124
  var valid_402657125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657125 = validateParameter(valid_402657125, JString,
                                      required = false, default = nil)
  if valid_402657125 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657125
  var valid_402657126 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657126 = validateParameter(valid_402657126, JString,
                                      required = false, default = nil)
  if valid_402657126 != nil:
    section.add "X-Amz-Algorithm", valid_402657126
  var valid_402657127 = header.getOrDefault("X-Amz-Date")
  valid_402657127 = validateParameter(valid_402657127, JString,
                                      required = false, default = nil)
  if valid_402657127 != nil:
    section.add "X-Amz-Date", valid_402657127
  var valid_402657128 = header.getOrDefault("X-Amz-Credential")
  valid_402657128 = validateParameter(valid_402657128, JString,
                                      required = false, default = nil)
  if valid_402657128 != nil:
    section.add "X-Amz-Credential", valid_402657128
  var valid_402657129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657130: Call_DescribeLocations_402657119;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the AWS Direct Connect locations in the current AWS Region. These are the locations that can be selected when calling <a>CreateConnection</a> or <a>CreateInterconnect</a>.
                                                                                         ## 
  let valid = call_402657130.validator(path, query, header, formData, body, _)
  let scheme = call_402657130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657130.makeUrl(scheme.get, call_402657130.host, call_402657130.base,
                                   call_402657130.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657130, uri, valid, _)

proc call*(call_402657131: Call_DescribeLocations_402657119): Recallable =
  ## describeLocations
  ## Lists the AWS Direct Connect locations in the current AWS Region. These are the locations that can be selected when calling <a>CreateConnection</a> or <a>CreateInterconnect</a>.
  result = call_402657131.call(nil, nil, nil, nil, nil)

var describeLocations* = Call_DescribeLocations_402657119(
    name: "describeLocations", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeLocations",
    validator: validate_DescribeLocations_402657120, base: "/",
    makeUrl: url_DescribeLocations_402657121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_402657132 = ref object of OpenApiRestCall_402656044
proc url_DescribeTags_402657134(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTags_402657133(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the tags associated with the specified AWS Direct Connect resources.
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
  var valid_402657135 = header.getOrDefault("X-Amz-Target")
  valid_402657135 = validateParameter(valid_402657135, JString, required = true, default = newJString(
      "OvertureService.DescribeTags"))
  if valid_402657135 != nil:
    section.add "X-Amz-Target", valid_402657135
  var valid_402657136 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657136 = validateParameter(valid_402657136, JString,
                                      required = false, default = nil)
  if valid_402657136 != nil:
    section.add "X-Amz-Security-Token", valid_402657136
  var valid_402657137 = header.getOrDefault("X-Amz-Signature")
  valid_402657137 = validateParameter(valid_402657137, JString,
                                      required = false, default = nil)
  if valid_402657137 != nil:
    section.add "X-Amz-Signature", valid_402657137
  var valid_402657138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657138 = validateParameter(valid_402657138, JString,
                                      required = false, default = nil)
  if valid_402657138 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657138
  var valid_402657139 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657139 = validateParameter(valid_402657139, JString,
                                      required = false, default = nil)
  if valid_402657139 != nil:
    section.add "X-Amz-Algorithm", valid_402657139
  var valid_402657140 = header.getOrDefault("X-Amz-Date")
  valid_402657140 = validateParameter(valid_402657140, JString,
                                      required = false, default = nil)
  if valid_402657140 != nil:
    section.add "X-Amz-Date", valid_402657140
  var valid_402657141 = header.getOrDefault("X-Amz-Credential")
  valid_402657141 = validateParameter(valid_402657141, JString,
                                      required = false, default = nil)
  if valid_402657141 != nil:
    section.add "X-Amz-Credential", valid_402657141
  var valid_402657142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657142 = validateParameter(valid_402657142, JString,
                                      required = false, default = nil)
  if valid_402657142 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657142
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

proc call*(call_402657144: Call_DescribeTags_402657132; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the tags associated with the specified AWS Direct Connect resources.
                                                                                         ## 
  let valid = call_402657144.validator(path, query, header, formData, body, _)
  let scheme = call_402657144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657144.makeUrl(scheme.get, call_402657144.host, call_402657144.base,
                                   call_402657144.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657144, uri, valid, _)

proc call*(call_402657145: Call_DescribeTags_402657132; body: JsonNode): Recallable =
  ## describeTags
  ## Describes the tags associated with the specified AWS Direct Connect resources.
  ##   
                                                                                   ## body: JObject (required)
  var body_402657146 = newJObject()
  if body != nil:
    body_402657146 = body
  result = call_402657145.call(nil, nil, nil, nil, body_402657146)

var describeTags* = Call_DescribeTags_402657132(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeTags",
    validator: validate_DescribeTags_402657133, base: "/",
    makeUrl: url_DescribeTags_402657134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualGateways_402657147 = ref object of OpenApiRestCall_402656044
proc url_DescribeVirtualGateways_402657149(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeVirtualGateways_402657148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists the virtual private gateways owned by the AWS account.</p> <p>You can create one or more AWS Direct Connect private virtual interfaces linked to a virtual private gateway.</p>
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
  var valid_402657150 = header.getOrDefault("X-Amz-Target")
  valid_402657150 = validateParameter(valid_402657150, JString, required = true, default = newJString(
      "OvertureService.DescribeVirtualGateways"))
  if valid_402657150 != nil:
    section.add "X-Amz-Target", valid_402657150
  var valid_402657151 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657151 = validateParameter(valid_402657151, JString,
                                      required = false, default = nil)
  if valid_402657151 != nil:
    section.add "X-Amz-Security-Token", valid_402657151
  var valid_402657152 = header.getOrDefault("X-Amz-Signature")
  valid_402657152 = validateParameter(valid_402657152, JString,
                                      required = false, default = nil)
  if valid_402657152 != nil:
    section.add "X-Amz-Signature", valid_402657152
  var valid_402657153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657153 = validateParameter(valid_402657153, JString,
                                      required = false, default = nil)
  if valid_402657153 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657153
  var valid_402657154 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657154 = validateParameter(valid_402657154, JString,
                                      required = false, default = nil)
  if valid_402657154 != nil:
    section.add "X-Amz-Algorithm", valid_402657154
  var valid_402657155 = header.getOrDefault("X-Amz-Date")
  valid_402657155 = validateParameter(valid_402657155, JString,
                                      required = false, default = nil)
  if valid_402657155 != nil:
    section.add "X-Amz-Date", valid_402657155
  var valid_402657156 = header.getOrDefault("X-Amz-Credential")
  valid_402657156 = validateParameter(valid_402657156, JString,
                                      required = false, default = nil)
  if valid_402657156 != nil:
    section.add "X-Amz-Credential", valid_402657156
  var valid_402657157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657157 = validateParameter(valid_402657157, JString,
                                      required = false, default = nil)
  if valid_402657157 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657158: Call_DescribeVirtualGateways_402657147;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the virtual private gateways owned by the AWS account.</p> <p>You can create one or more AWS Direct Connect private virtual interfaces linked to a virtual private gateway.</p>
                                                                                         ## 
  let valid = call_402657158.validator(path, query, header, formData, body, _)
  let scheme = call_402657158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657158.makeUrl(scheme.get, call_402657158.host, call_402657158.base,
                                   call_402657158.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657158, uri, valid, _)

proc call*(call_402657159: Call_DescribeVirtualGateways_402657147): Recallable =
  ## describeVirtualGateways
  ## <p>Lists the virtual private gateways owned by the AWS account.</p> <p>You can create one or more AWS Direct Connect private virtual interfaces linked to a virtual private gateway.</p>
  result = call_402657159.call(nil, nil, nil, nil, nil)

var describeVirtualGateways* = Call_DescribeVirtualGateways_402657147(
    name: "describeVirtualGateways", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeVirtualGateways",
    validator: validate_DescribeVirtualGateways_402657148, base: "/",
    makeUrl: url_DescribeVirtualGateways_402657149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualInterfaces_402657160 = ref object of OpenApiRestCall_402656044
proc url_DescribeVirtualInterfaces_402657162(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeVirtualInterfaces_402657161(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Displays all virtual interfaces for an AWS account. Virtual interfaces deleted fewer than 15 minutes before you make the request are also returned. If you specify a connection ID, only the virtual interfaces associated with the connection are returned. If you specify a virtual interface ID, then only a single virtual interface is returned.</p> <p>A virtual interface (VLAN) transmits the traffic between the AWS Direct Connect location and the customer network.</p>
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
  var valid_402657163 = header.getOrDefault("X-Amz-Target")
  valid_402657163 = validateParameter(valid_402657163, JString, required = true, default = newJString(
      "OvertureService.DescribeVirtualInterfaces"))
  if valid_402657163 != nil:
    section.add "X-Amz-Target", valid_402657163
  var valid_402657164 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657164 = validateParameter(valid_402657164, JString,
                                      required = false, default = nil)
  if valid_402657164 != nil:
    section.add "X-Amz-Security-Token", valid_402657164
  var valid_402657165 = header.getOrDefault("X-Amz-Signature")
  valid_402657165 = validateParameter(valid_402657165, JString,
                                      required = false, default = nil)
  if valid_402657165 != nil:
    section.add "X-Amz-Signature", valid_402657165
  var valid_402657166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657166 = validateParameter(valid_402657166, JString,
                                      required = false, default = nil)
  if valid_402657166 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657166
  var valid_402657167 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657167 = validateParameter(valid_402657167, JString,
                                      required = false, default = nil)
  if valid_402657167 != nil:
    section.add "X-Amz-Algorithm", valid_402657167
  var valid_402657168 = header.getOrDefault("X-Amz-Date")
  valid_402657168 = validateParameter(valid_402657168, JString,
                                      required = false, default = nil)
  if valid_402657168 != nil:
    section.add "X-Amz-Date", valid_402657168
  var valid_402657169 = header.getOrDefault("X-Amz-Credential")
  valid_402657169 = validateParameter(valid_402657169, JString,
                                      required = false, default = nil)
  if valid_402657169 != nil:
    section.add "X-Amz-Credential", valid_402657169
  var valid_402657170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657170 = validateParameter(valid_402657170, JString,
                                      required = false, default = nil)
  if valid_402657170 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657170
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

proc call*(call_402657172: Call_DescribeVirtualInterfaces_402657160;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Displays all virtual interfaces for an AWS account. Virtual interfaces deleted fewer than 15 minutes before you make the request are also returned. If you specify a connection ID, only the virtual interfaces associated with the connection are returned. If you specify a virtual interface ID, then only a single virtual interface is returned.</p> <p>A virtual interface (VLAN) transmits the traffic between the AWS Direct Connect location and the customer network.</p>
                                                                                         ## 
  let valid = call_402657172.validator(path, query, header, formData, body, _)
  let scheme = call_402657172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657172.makeUrl(scheme.get, call_402657172.host, call_402657172.base,
                                   call_402657172.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657172, uri, valid, _)

proc call*(call_402657173: Call_DescribeVirtualInterfaces_402657160;
           body: JsonNode): Recallable =
  ## describeVirtualInterfaces
  ## <p>Displays all virtual interfaces for an AWS account. Virtual interfaces deleted fewer than 15 minutes before you make the request are also returned. If you specify a connection ID, only the virtual interfaces associated with the connection are returned. If you specify a virtual interface ID, then only a single virtual interface is returned.</p> <p>A virtual interface (VLAN) transmits the traffic between the AWS Direct Connect location and the customer network.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402657174 = newJObject()
  if body != nil:
    body_402657174 = body
  result = call_402657173.call(nil, nil, nil, nil, body_402657174)

var describeVirtualInterfaces* = Call_DescribeVirtualInterfaces_402657160(
    name: "describeVirtualInterfaces", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeVirtualInterfaces",
    validator: validate_DescribeVirtualInterfaces_402657161, base: "/",
    makeUrl: url_DescribeVirtualInterfaces_402657162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConnectionFromLag_402657175 = ref object of OpenApiRestCall_402656044
proc url_DisassociateConnectionFromLag_402657177(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateConnectionFromLag_402657176(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Disassociates a connection from a link aggregation group (LAG). The connection is interrupted and re-established as a standalone connection (the connection is not deleted; to delete the connection, use the <a>DeleteConnection</a> request). If the LAG has associated virtual interfaces or hosted connections, they remain associated with the LAG. A disassociated connection owned by an AWS Direct Connect Partner is automatically converted to an interconnect.</p> <p>If disassociating the connection would cause the LAG to fall below its setting for minimum number of operational connections, the request fails, except when it's the last member of the LAG. If all connections are disassociated, the LAG continues to exist as an empty LAG with no physical connections. </p>
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
  var valid_402657178 = header.getOrDefault("X-Amz-Target")
  valid_402657178 = validateParameter(valid_402657178, JString, required = true, default = newJString(
      "OvertureService.DisassociateConnectionFromLag"))
  if valid_402657178 != nil:
    section.add "X-Amz-Target", valid_402657178
  var valid_402657179 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657179 = validateParameter(valid_402657179, JString,
                                      required = false, default = nil)
  if valid_402657179 != nil:
    section.add "X-Amz-Security-Token", valid_402657179
  var valid_402657180 = header.getOrDefault("X-Amz-Signature")
  valid_402657180 = validateParameter(valid_402657180, JString,
                                      required = false, default = nil)
  if valid_402657180 != nil:
    section.add "X-Amz-Signature", valid_402657180
  var valid_402657181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657181 = validateParameter(valid_402657181, JString,
                                      required = false, default = nil)
  if valid_402657181 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657181
  var valid_402657182 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657182 = validateParameter(valid_402657182, JString,
                                      required = false, default = nil)
  if valid_402657182 != nil:
    section.add "X-Amz-Algorithm", valid_402657182
  var valid_402657183 = header.getOrDefault("X-Amz-Date")
  valid_402657183 = validateParameter(valid_402657183, JString,
                                      required = false, default = nil)
  if valid_402657183 != nil:
    section.add "X-Amz-Date", valid_402657183
  var valid_402657184 = header.getOrDefault("X-Amz-Credential")
  valid_402657184 = validateParameter(valid_402657184, JString,
                                      required = false, default = nil)
  if valid_402657184 != nil:
    section.add "X-Amz-Credential", valid_402657184
  var valid_402657185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657185 = validateParameter(valid_402657185, JString,
                                      required = false, default = nil)
  if valid_402657185 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657185
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

proc call*(call_402657187: Call_DisassociateConnectionFromLag_402657175;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disassociates a connection from a link aggregation group (LAG). The connection is interrupted and re-established as a standalone connection (the connection is not deleted; to delete the connection, use the <a>DeleteConnection</a> request). If the LAG has associated virtual interfaces or hosted connections, they remain associated with the LAG. A disassociated connection owned by an AWS Direct Connect Partner is automatically converted to an interconnect.</p> <p>If disassociating the connection would cause the LAG to fall below its setting for minimum number of operational connections, the request fails, except when it's the last member of the LAG. If all connections are disassociated, the LAG continues to exist as an empty LAG with no physical connections. </p>
                                                                                         ## 
  let valid = call_402657187.validator(path, query, header, formData, body, _)
  let scheme = call_402657187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657187.makeUrl(scheme.get, call_402657187.host, call_402657187.base,
                                   call_402657187.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657187, uri, valid, _)

proc call*(call_402657188: Call_DisassociateConnectionFromLag_402657175;
           body: JsonNode): Recallable =
  ## disassociateConnectionFromLag
  ## <p>Disassociates a connection from a link aggregation group (LAG). The connection is interrupted and re-established as a standalone connection (the connection is not deleted; to delete the connection, use the <a>DeleteConnection</a> request). If the LAG has associated virtual interfaces or hosted connections, they remain associated with the LAG. A disassociated connection owned by an AWS Direct Connect Partner is automatically converted to an interconnect.</p> <p>If disassociating the connection would cause the LAG to fall below its setting for minimum number of operational connections, the request fails, except when it's the last member of the LAG. If all connections are disassociated, the LAG continues to exist as an empty LAG with no physical connections. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402657189 = newJObject()
  if body != nil:
    body_402657189 = body
  result = call_402657188.call(nil, nil, nil, nil, body_402657189)

var disassociateConnectionFromLag* = Call_DisassociateConnectionFromLag_402657175(
    name: "disassociateConnectionFromLag", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DisassociateConnectionFromLag",
    validator: validate_DisassociateConnectionFromLag_402657176, base: "/",
    makeUrl: url_DisassociateConnectionFromLag_402657177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657190 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657192(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402657191(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds the specified tags to the specified AWS Direct Connect resource. Each resource can have a maximum of 50 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the resource, this action updates its value.</p>
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
  var valid_402657193 = header.getOrDefault("X-Amz-Target")
  valid_402657193 = validateParameter(valid_402657193, JString, required = true, default = newJString(
      "OvertureService.TagResource"))
  if valid_402657193 != nil:
    section.add "X-Amz-Target", valid_402657193
  var valid_402657194 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657194 = validateParameter(valid_402657194, JString,
                                      required = false, default = nil)
  if valid_402657194 != nil:
    section.add "X-Amz-Security-Token", valid_402657194
  var valid_402657195 = header.getOrDefault("X-Amz-Signature")
  valid_402657195 = validateParameter(valid_402657195, JString,
                                      required = false, default = nil)
  if valid_402657195 != nil:
    section.add "X-Amz-Signature", valid_402657195
  var valid_402657196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657196 = validateParameter(valid_402657196, JString,
                                      required = false, default = nil)
  if valid_402657196 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657196
  var valid_402657197 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657197 = validateParameter(valid_402657197, JString,
                                      required = false, default = nil)
  if valid_402657197 != nil:
    section.add "X-Amz-Algorithm", valid_402657197
  var valid_402657198 = header.getOrDefault("X-Amz-Date")
  valid_402657198 = validateParameter(valid_402657198, JString,
                                      required = false, default = nil)
  if valid_402657198 != nil:
    section.add "X-Amz-Date", valid_402657198
  var valid_402657199 = header.getOrDefault("X-Amz-Credential")
  valid_402657199 = validateParameter(valid_402657199, JString,
                                      required = false, default = nil)
  if valid_402657199 != nil:
    section.add "X-Amz-Credential", valid_402657199
  var valid_402657200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657200 = validateParameter(valid_402657200, JString,
                                      required = false, default = nil)
  if valid_402657200 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657200
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

proc call*(call_402657202: Call_TagResource_402657190; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified tags to the specified AWS Direct Connect resource. Each resource can have a maximum of 50 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the resource, this action updates its value.</p>
                                                                                         ## 
  let valid = call_402657202.validator(path, query, header, formData, body, _)
  let scheme = call_402657202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657202.makeUrl(scheme.get, call_402657202.host, call_402657202.base,
                                   call_402657202.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657202, uri, valid, _)

proc call*(call_402657203: Call_TagResource_402657190; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds the specified tags to the specified AWS Direct Connect resource. Each resource can have a maximum of 50 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the resource, this action updates its value.</p>
  ##   
                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402657204 = newJObject()
  if body != nil:
    body_402657204 = body
  result = call_402657203.call(nil, nil, nil, nil, body_402657204)

var tagResource* = Call_TagResource_402657190(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.TagResource",
    validator: validate_TagResource_402657191, base: "/",
    makeUrl: url_TagResource_402657192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657205 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657207(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402657206(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes one or more tags from the specified AWS Direct Connect resource.
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
  var valid_402657208 = header.getOrDefault("X-Amz-Target")
  valid_402657208 = validateParameter(valid_402657208, JString, required = true, default = newJString(
      "OvertureService.UntagResource"))
  if valid_402657208 != nil:
    section.add "X-Amz-Target", valid_402657208
  var valid_402657209 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657209 = validateParameter(valid_402657209, JString,
                                      required = false, default = nil)
  if valid_402657209 != nil:
    section.add "X-Amz-Security-Token", valid_402657209
  var valid_402657210 = header.getOrDefault("X-Amz-Signature")
  valid_402657210 = validateParameter(valid_402657210, JString,
                                      required = false, default = nil)
  if valid_402657210 != nil:
    section.add "X-Amz-Signature", valid_402657210
  var valid_402657211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657211 = validateParameter(valid_402657211, JString,
                                      required = false, default = nil)
  if valid_402657211 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657211
  var valid_402657212 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657212 = validateParameter(valid_402657212, JString,
                                      required = false, default = nil)
  if valid_402657212 != nil:
    section.add "X-Amz-Algorithm", valid_402657212
  var valid_402657213 = header.getOrDefault("X-Amz-Date")
  valid_402657213 = validateParameter(valid_402657213, JString,
                                      required = false, default = nil)
  if valid_402657213 != nil:
    section.add "X-Amz-Date", valid_402657213
  var valid_402657214 = header.getOrDefault("X-Amz-Credential")
  valid_402657214 = validateParameter(valid_402657214, JString,
                                      required = false, default = nil)
  if valid_402657214 != nil:
    section.add "X-Amz-Credential", valid_402657214
  var valid_402657215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657215 = validateParameter(valid_402657215, JString,
                                      required = false, default = nil)
  if valid_402657215 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657215
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

proc call*(call_402657217: Call_UntagResource_402657205; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags from the specified AWS Direct Connect resource.
                                                                                         ## 
  let valid = call_402657217.validator(path, query, header, formData, body, _)
  let scheme = call_402657217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657217.makeUrl(scheme.get, call_402657217.host, call_402657217.base,
                                   call_402657217.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657217, uri, valid, _)

proc call*(call_402657218: Call_UntagResource_402657205; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from the specified AWS Direct Connect resource.
  ##   
                                                                             ## body: JObject (required)
  var body_402657219 = newJObject()
  if body != nil:
    body_402657219 = body
  result = call_402657218.call(nil, nil, nil, nil, body_402657219)

var untagResource* = Call_UntagResource_402657205(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.UntagResource",
    validator: validate_UntagResource_402657206, base: "/",
    makeUrl: url_UntagResource_402657207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDirectConnectGatewayAssociation_402657220 = ref object of OpenApiRestCall_402656044
proc url_UpdateDirectConnectGatewayAssociation_402657222(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDirectConnectGatewayAssociation_402657221(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Updates the specified attributes of the Direct Connect gateway association.</p> <p>Add or remove prefixes from the association.</p>
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
  var valid_402657223 = header.getOrDefault("X-Amz-Target")
  valid_402657223 = validateParameter(valid_402657223, JString, required = true, default = newJString(
      "OvertureService.UpdateDirectConnectGatewayAssociation"))
  if valid_402657223 != nil:
    section.add "X-Amz-Target", valid_402657223
  var valid_402657224 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657224 = validateParameter(valid_402657224, JString,
                                      required = false, default = nil)
  if valid_402657224 != nil:
    section.add "X-Amz-Security-Token", valid_402657224
  var valid_402657225 = header.getOrDefault("X-Amz-Signature")
  valid_402657225 = validateParameter(valid_402657225, JString,
                                      required = false, default = nil)
  if valid_402657225 != nil:
    section.add "X-Amz-Signature", valid_402657225
  var valid_402657226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657226 = validateParameter(valid_402657226, JString,
                                      required = false, default = nil)
  if valid_402657226 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657226
  var valid_402657227 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657227 = validateParameter(valid_402657227, JString,
                                      required = false, default = nil)
  if valid_402657227 != nil:
    section.add "X-Amz-Algorithm", valid_402657227
  var valid_402657228 = header.getOrDefault("X-Amz-Date")
  valid_402657228 = validateParameter(valid_402657228, JString,
                                      required = false, default = nil)
  if valid_402657228 != nil:
    section.add "X-Amz-Date", valid_402657228
  var valid_402657229 = header.getOrDefault("X-Amz-Credential")
  valid_402657229 = validateParameter(valid_402657229, JString,
                                      required = false, default = nil)
  if valid_402657229 != nil:
    section.add "X-Amz-Credential", valid_402657229
  var valid_402657230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657230 = validateParameter(valid_402657230, JString,
                                      required = false, default = nil)
  if valid_402657230 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657230
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

proc call*(call_402657232: Call_UpdateDirectConnectGatewayAssociation_402657220;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified attributes of the Direct Connect gateway association.</p> <p>Add or remove prefixes from the association.</p>
                                                                                         ## 
  let valid = call_402657232.validator(path, query, header, formData, body, _)
  let scheme = call_402657232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657232.makeUrl(scheme.get, call_402657232.host, call_402657232.base,
                                   call_402657232.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657232, uri, valid, _)

proc call*(call_402657233: Call_UpdateDirectConnectGatewayAssociation_402657220;
           body: JsonNode): Recallable =
  ## updateDirectConnectGatewayAssociation
  ## <p>Updates the specified attributes of the Direct Connect gateway association.</p> <p>Add or remove prefixes from the association.</p>
  ##   
                                                                                                                                           ## body: JObject (required)
  var body_402657234 = newJObject()
  if body != nil:
    body_402657234 = body
  result = call_402657233.call(nil, nil, nil, nil, body_402657234)

var updateDirectConnectGatewayAssociation* = Call_UpdateDirectConnectGatewayAssociation_402657220(
    name: "updateDirectConnectGatewayAssociation", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.UpdateDirectConnectGatewayAssociation",
    validator: validate_UpdateDirectConnectGatewayAssociation_402657221,
    base: "/", makeUrl: url_UpdateDirectConnectGatewayAssociation_402657222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLag_402657235 = ref object of OpenApiRestCall_402656044
proc url_UpdateLag_402657237(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLag_402657236(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the attributes of the specified link aggregation group (LAG).</p> <p>You can update the following attributes:</p> <ul> <li> <p>The name of the LAG.</p> </li> <li> <p>The value for the minimum number of connections that must be operational for the LAG itself to be operational. </p> </li> </ul> <p>When you create a LAG, the default value for the minimum number of operational connections is zero (0). If you update this value and the number of operational connections falls below the specified value, the LAG automatically goes down to avoid over-utilization of the remaining connections. Adjust this value with care, as it could force the LAG down if it is set higher than the current number of operational connections.</p>
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
  var valid_402657238 = header.getOrDefault("X-Amz-Target")
  valid_402657238 = validateParameter(valid_402657238, JString, required = true, default = newJString(
      "OvertureService.UpdateLag"))
  if valid_402657238 != nil:
    section.add "X-Amz-Target", valid_402657238
  var valid_402657239 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657239 = validateParameter(valid_402657239, JString,
                                      required = false, default = nil)
  if valid_402657239 != nil:
    section.add "X-Amz-Security-Token", valid_402657239
  var valid_402657240 = header.getOrDefault("X-Amz-Signature")
  valid_402657240 = validateParameter(valid_402657240, JString,
                                      required = false, default = nil)
  if valid_402657240 != nil:
    section.add "X-Amz-Signature", valid_402657240
  var valid_402657241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657241 = validateParameter(valid_402657241, JString,
                                      required = false, default = nil)
  if valid_402657241 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657241
  var valid_402657242 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657242 = validateParameter(valid_402657242, JString,
                                      required = false, default = nil)
  if valid_402657242 != nil:
    section.add "X-Amz-Algorithm", valid_402657242
  var valid_402657243 = header.getOrDefault("X-Amz-Date")
  valid_402657243 = validateParameter(valid_402657243, JString,
                                      required = false, default = nil)
  if valid_402657243 != nil:
    section.add "X-Amz-Date", valid_402657243
  var valid_402657244 = header.getOrDefault("X-Amz-Credential")
  valid_402657244 = validateParameter(valid_402657244, JString,
                                      required = false, default = nil)
  if valid_402657244 != nil:
    section.add "X-Amz-Credential", valid_402657244
  var valid_402657245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657245 = validateParameter(valid_402657245, JString,
                                      required = false, default = nil)
  if valid_402657245 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657245
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

proc call*(call_402657247: Call_UpdateLag_402657235; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the attributes of the specified link aggregation group (LAG).</p> <p>You can update the following attributes:</p> <ul> <li> <p>The name of the LAG.</p> </li> <li> <p>The value for the minimum number of connections that must be operational for the LAG itself to be operational. </p> </li> </ul> <p>When you create a LAG, the default value for the minimum number of operational connections is zero (0). If you update this value and the number of operational connections falls below the specified value, the LAG automatically goes down to avoid over-utilization of the remaining connections. Adjust this value with care, as it could force the LAG down if it is set higher than the current number of operational connections.</p>
                                                                                         ## 
  let valid = call_402657247.validator(path, query, header, formData, body, _)
  let scheme = call_402657247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657247.makeUrl(scheme.get, call_402657247.host, call_402657247.base,
                                   call_402657247.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657247, uri, valid, _)

proc call*(call_402657248: Call_UpdateLag_402657235; body: JsonNode): Recallable =
  ## updateLag
  ## <p>Updates the attributes of the specified link aggregation group (LAG).</p> <p>You can update the following attributes:</p> <ul> <li> <p>The name of the LAG.</p> </li> <li> <p>The value for the minimum number of connections that must be operational for the LAG itself to be operational. </p> </li> </ul> <p>When you create a LAG, the default value for the minimum number of operational connections is zero (0). If you update this value and the number of operational connections falls below the specified value, the LAG automatically goes down to avoid over-utilization of the remaining connections. Adjust this value with care, as it could force the LAG down if it is set higher than the current number of operational connections.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402657249 = newJObject()
  if body != nil:
    body_402657249 = body
  result = call_402657248.call(nil, nil, nil, nil, body_402657249)

var updateLag* = Call_UpdateLag_402657235(name: "updateLag",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.UpdateLag",
    validator: validate_UpdateLag_402657236, base: "/", makeUrl: url_UpdateLag_402657237,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualInterfaceAttributes_402657250 = ref object of OpenApiRestCall_402656044
proc url_UpdateVirtualInterfaceAttributes_402657252(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVirtualInterfaceAttributes_402657251(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Updates the specified attributes of the specified virtual private interface.</p> <p>Setting the MTU of a virtual interface to 9001 (jumbo frames) can cause an update to the underlying physical connection if it wasn't updated to support jumbo frames. Updating the connection disrupts network connectivity for all virtual interfaces associated with the connection for up to 30 seconds. To check whether your connection supports jumbo frames, call <a>DescribeConnections</a>. To check whether your virtual interface supports jumbo frames, call <a>DescribeVirtualInterfaces</a>.</p>
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
  var valid_402657253 = header.getOrDefault("X-Amz-Target")
  valid_402657253 = validateParameter(valid_402657253, JString, required = true, default = newJString(
      "OvertureService.UpdateVirtualInterfaceAttributes"))
  if valid_402657253 != nil:
    section.add "X-Amz-Target", valid_402657253
  var valid_402657254 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657254 = validateParameter(valid_402657254, JString,
                                      required = false, default = nil)
  if valid_402657254 != nil:
    section.add "X-Amz-Security-Token", valid_402657254
  var valid_402657255 = header.getOrDefault("X-Amz-Signature")
  valid_402657255 = validateParameter(valid_402657255, JString,
                                      required = false, default = nil)
  if valid_402657255 != nil:
    section.add "X-Amz-Signature", valid_402657255
  var valid_402657256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657256 = validateParameter(valid_402657256, JString,
                                      required = false, default = nil)
  if valid_402657256 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657256
  var valid_402657257 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657257 = validateParameter(valid_402657257, JString,
                                      required = false, default = nil)
  if valid_402657257 != nil:
    section.add "X-Amz-Algorithm", valid_402657257
  var valid_402657258 = header.getOrDefault("X-Amz-Date")
  valid_402657258 = validateParameter(valid_402657258, JString,
                                      required = false, default = nil)
  if valid_402657258 != nil:
    section.add "X-Amz-Date", valid_402657258
  var valid_402657259 = header.getOrDefault("X-Amz-Credential")
  valid_402657259 = validateParameter(valid_402657259, JString,
                                      required = false, default = nil)
  if valid_402657259 != nil:
    section.add "X-Amz-Credential", valid_402657259
  var valid_402657260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657260 = validateParameter(valid_402657260, JString,
                                      required = false, default = nil)
  if valid_402657260 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657260
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

proc call*(call_402657262: Call_UpdateVirtualInterfaceAttributes_402657250;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified attributes of the specified virtual private interface.</p> <p>Setting the MTU of a virtual interface to 9001 (jumbo frames) can cause an update to the underlying physical connection if it wasn't updated to support jumbo frames. Updating the connection disrupts network connectivity for all virtual interfaces associated with the connection for up to 30 seconds. To check whether your connection supports jumbo frames, call <a>DescribeConnections</a>. To check whether your virtual interface supports jumbo frames, call <a>DescribeVirtualInterfaces</a>.</p>
                                                                                         ## 
  let valid = call_402657262.validator(path, query, header, formData, body, _)
  let scheme = call_402657262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657262.makeUrl(scheme.get, call_402657262.host, call_402657262.base,
                                   call_402657262.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657262, uri, valid, _)

proc call*(call_402657263: Call_UpdateVirtualInterfaceAttributes_402657250;
           body: JsonNode): Recallable =
  ## updateVirtualInterfaceAttributes
  ## <p>Updates the specified attributes of the specified virtual private interface.</p> <p>Setting the MTU of a virtual interface to 9001 (jumbo frames) can cause an update to the underlying physical connection if it wasn't updated to support jumbo frames. Updating the connection disrupts network connectivity for all virtual interfaces associated with the connection for up to 30 seconds. To check whether your connection supports jumbo frames, call <a>DescribeConnections</a>. To check whether your virtual interface supports jumbo frames, call <a>DescribeVirtualInterfaces</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402657264 = newJObject()
  if body != nil:
    body_402657264 = body
  result = call_402657263.call(nil, nil, nil, nil, body_402657264)

var updateVirtualInterfaceAttributes* = Call_UpdateVirtualInterfaceAttributes_402657250(
    name: "updateVirtualInterfaceAttributes", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.UpdateVirtualInterfaceAttributes",
    validator: validate_UpdateVirtualInterfaceAttributes_402657251, base: "/",
    makeUrl: url_UpdateVirtualInterfaceAttributes_402657252,
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