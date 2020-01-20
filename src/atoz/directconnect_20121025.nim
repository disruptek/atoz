
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "directconnect.ap-northeast-1.amazonaws.com", "ap-southeast-1": "directconnect.ap-southeast-1.amazonaws.com", "us-west-2": "directconnect.us-west-2.amazonaws.com", "eu-west-2": "directconnect.eu-west-2.amazonaws.com", "ap-northeast-3": "directconnect.ap-northeast-3.amazonaws.com", "eu-central-1": "directconnect.eu-central-1.amazonaws.com", "us-east-2": "directconnect.us-east-2.amazonaws.com", "us-east-1": "directconnect.us-east-1.amazonaws.com", "cn-northwest-1": "directconnect.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "directconnect.ap-south-1.amazonaws.com", "eu-north-1": "directconnect.eu-north-1.amazonaws.com", "ap-northeast-2": "directconnect.ap-northeast-2.amazonaws.com", "us-west-1": "directconnect.us-west-1.amazonaws.com", "us-gov-east-1": "directconnect.us-gov-east-1.amazonaws.com", "eu-west-3": "directconnect.eu-west-3.amazonaws.com", "cn-north-1": "directconnect.cn-north-1.amazonaws.com.cn", "sa-east-1": "directconnect.sa-east-1.amazonaws.com", "eu-west-1": "directconnect.eu-west-1.amazonaws.com", "us-gov-west-1": "directconnect.us-gov-west-1.amazonaws.com", "ap-southeast-2": "directconnect.ap-southeast-2.amazonaws.com", "ca-central-1": "directconnect.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptDirectConnectGatewayAssociationProposal_605927 = ref object of OpenApiRestCall_605589
proc url_AcceptDirectConnectGatewayAssociationProposal_605929(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptDirectConnectGatewayAssociationProposal_605928(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
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
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "OvertureService.AcceptDirectConnectGatewayAssociationProposal"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_AcceptDirectConnectGatewayAssociationProposal_605927;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Accepts a proposal request to attach a virtual private gateway or transit gateway to a Direct Connect gateway.
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AcceptDirectConnectGatewayAssociationProposal_605927;
          body: JsonNode): Recallable =
  ## acceptDirectConnectGatewayAssociationProposal
  ## Accepts a proposal request to attach a virtual private gateway or transit gateway to a Direct Connect gateway.
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var acceptDirectConnectGatewayAssociationProposal* = Call_AcceptDirectConnectGatewayAssociationProposal_605927(
    name: "acceptDirectConnectGatewayAssociationProposal",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.AcceptDirectConnectGatewayAssociationProposal",
    validator: validate_AcceptDirectConnectGatewayAssociationProposal_605928,
    base: "/", url: url_AcceptDirectConnectGatewayAssociationProposal_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocateConnectionOnInterconnect_606196 = ref object of OpenApiRestCall_605589
proc url_AllocateConnectionOnInterconnect_606198(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocateConnectionOnInterconnect_606197(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "OvertureService.AllocateConnectionOnInterconnect"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_AllocateConnectionOnInterconnect_606196;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deprecated. Use <a>AllocateHostedConnection</a> instead.</p> <p>Creates a hosted connection on an interconnect.</p> <p>Allocates a VLAN number and a specified amount of bandwidth for use by a hosted connection on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_AllocateConnectionOnInterconnect_606196;
          body: JsonNode): Recallable =
  ## allocateConnectionOnInterconnect
  ## <p>Deprecated. Use <a>AllocateHostedConnection</a> instead.</p> <p>Creates a hosted connection on an interconnect.</p> <p>Allocates a VLAN number and a specified amount of bandwidth for use by a hosted connection on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var allocateConnectionOnInterconnect* = Call_AllocateConnectionOnInterconnect_606196(
    name: "allocateConnectionOnInterconnect", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocateConnectionOnInterconnect",
    validator: validate_AllocateConnectionOnInterconnect_606197, base: "/",
    url: url_AllocateConnectionOnInterconnect_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocateHostedConnection_606211 = ref object of OpenApiRestCall_605589
proc url_AllocateHostedConnection_606213(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocateHostedConnection_606212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "OvertureService.AllocateHostedConnection"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_AllocateHostedConnection_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a hosted connection on the specified interconnect or a link aggregation group (LAG) of interconnects.</p> <p>Allocates a VLAN number and a specified amount of capacity (bandwidth) for use by a hosted connection on the specified interconnect or LAG of interconnects. AWS polices the hosted connection for the specified capacity and the AWS Direct Connect Partner must also police the hosted connection for the specified capacity.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_AllocateHostedConnection_606211; body: JsonNode): Recallable =
  ## allocateHostedConnection
  ## <p>Creates a hosted connection on the specified interconnect or a link aggregation group (LAG) of interconnects.</p> <p>Allocates a VLAN number and a specified amount of capacity (bandwidth) for use by a hosted connection on the specified interconnect or LAG of interconnects. AWS polices the hosted connection for the specified capacity and the AWS Direct Connect Partner must also police the hosted connection for the specified capacity.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var allocateHostedConnection* = Call_AllocateHostedConnection_606211(
    name: "allocateHostedConnection", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocateHostedConnection",
    validator: validate_AllocateHostedConnection_606212, base: "/",
    url: url_AllocateHostedConnection_606213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocatePrivateVirtualInterface_606226 = ref object of OpenApiRestCall_605589
proc url_AllocatePrivateVirtualInterface_606228(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocatePrivateVirtualInterface_606227(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "OvertureService.AllocatePrivateVirtualInterface"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_AllocatePrivateVirtualInterface_606226;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Provisions a private virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this action must be confirmed by the owner using <a>ConfirmPrivateVirtualInterface</a>. Until then, the virtual interface is in the <code>Confirming</code> state and is not available to handle traffic.</p>
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_AllocatePrivateVirtualInterface_606226; body: JsonNode): Recallable =
  ## allocatePrivateVirtualInterface
  ## <p>Provisions a private virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this action must be confirmed by the owner using <a>ConfirmPrivateVirtualInterface</a>. Until then, the virtual interface is in the <code>Confirming</code> state and is not available to handle traffic.</p>
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var allocatePrivateVirtualInterface* = Call_AllocatePrivateVirtualInterface_606226(
    name: "allocatePrivateVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocatePrivateVirtualInterface",
    validator: validate_AllocatePrivateVirtualInterface_606227, base: "/",
    url: url_AllocatePrivateVirtualInterface_606228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocatePublicVirtualInterface_606241 = ref object of OpenApiRestCall_605589
proc url_AllocatePublicVirtualInterface_606243(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocatePublicVirtualInterface_606242(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "OvertureService.AllocatePublicVirtualInterface"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_AllocatePublicVirtualInterface_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provisions a public virtual interface to be owned by the specified AWS account.</p> <p>The owner of a connection calls this function to provision a public virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this function must be confirmed by the owner using <a>ConfirmPublicVirtualInterface</a>. Until this step has been completed, the virtual interface is in the <code>confirming</code> state and is not available to handle traffic.</p> <p>When creating an IPv6 public virtual interface, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p>
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_AllocatePublicVirtualInterface_606241; body: JsonNode): Recallable =
  ## allocatePublicVirtualInterface
  ## <p>Provisions a public virtual interface to be owned by the specified AWS account.</p> <p>The owner of a connection calls this function to provision a public virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this function must be confirmed by the owner using <a>ConfirmPublicVirtualInterface</a>. Until this step has been completed, the virtual interface is in the <code>confirming</code> state and is not available to handle traffic.</p> <p>When creating an IPv6 public virtual interface, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p>
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var allocatePublicVirtualInterface* = Call_AllocatePublicVirtualInterface_606241(
    name: "allocatePublicVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocatePublicVirtualInterface",
    validator: validate_AllocatePublicVirtualInterface_606242, base: "/",
    url: url_AllocatePublicVirtualInterface_606243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocateTransitVirtualInterface_606256 = ref object of OpenApiRestCall_605589
proc url_AllocateTransitVirtualInterface_606258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocateTransitVirtualInterface_606257(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "OvertureService.AllocateTransitVirtualInterface"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_AllocateTransitVirtualInterface_606256;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Provisions a transit virtual interface to be owned by the specified AWS account. Use this type of interface to connect a transit gateway to your Direct Connect gateway.</p> <p>The owner of a connection provisions a transit virtual interface to be owned by the specified AWS account.</p> <p>After you create a transit virtual interface, it must be confirmed by the owner using <a>ConfirmTransitVirtualInterface</a>. Until this step has been completed, the transit virtual interface is in the <code>requested</code> state and is not available to handle traffic.</p>
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_AllocateTransitVirtualInterface_606256; body: JsonNode): Recallable =
  ## allocateTransitVirtualInterface
  ## <p>Provisions a transit virtual interface to be owned by the specified AWS account. Use this type of interface to connect a transit gateway to your Direct Connect gateway.</p> <p>The owner of a connection provisions a transit virtual interface to be owned by the specified AWS account.</p> <p>After you create a transit virtual interface, it must be confirmed by the owner using <a>ConfirmTransitVirtualInterface</a>. Until this step has been completed, the transit virtual interface is in the <code>requested</code> state and is not available to handle traffic.</p>
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var allocateTransitVirtualInterface* = Call_AllocateTransitVirtualInterface_606256(
    name: "allocateTransitVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocateTransitVirtualInterface",
    validator: validate_AllocateTransitVirtualInterface_606257, base: "/",
    url: url_AllocateTransitVirtualInterface_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateConnectionWithLag_606271 = ref object of OpenApiRestCall_605589
proc url_AssociateConnectionWithLag_606273(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateConnectionWithLag_606272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "OvertureService.AssociateConnectionWithLag"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_AssociateConnectionWithLag_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an existing connection with a link aggregation group (LAG). The connection is interrupted and re-established as a member of the LAG (connectivity to AWS is interrupted). The connection must be hosted on the same AWS Direct Connect endpoint as the LAG, and its bandwidth must match the bandwidth for the LAG. You can re-associate a connection that's currently associated with a different LAG; however, if removing the connection would cause the original LAG to fall below its setting for minimum number of operational connections, the request fails.</p> <p>Any virtual interfaces that are directly associated with the connection are automatically re-associated with the LAG. If the connection was originally associated with a different LAG, the virtual interfaces remain associated with the original LAG.</p> <p>For interconnects, any hosted connections are automatically re-associated with the LAG. If the interconnect was originally associated with a different LAG, the hosted connections remain associated with the original LAG.</p>
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_AssociateConnectionWithLag_606271; body: JsonNode): Recallable =
  ## associateConnectionWithLag
  ## <p>Associates an existing connection with a link aggregation group (LAG). The connection is interrupted and re-established as a member of the LAG (connectivity to AWS is interrupted). The connection must be hosted on the same AWS Direct Connect endpoint as the LAG, and its bandwidth must match the bandwidth for the LAG. You can re-associate a connection that's currently associated with a different LAG; however, if removing the connection would cause the original LAG to fall below its setting for minimum number of operational connections, the request fails.</p> <p>Any virtual interfaces that are directly associated with the connection are automatically re-associated with the LAG. If the connection was originally associated with a different LAG, the virtual interfaces remain associated with the original LAG.</p> <p>For interconnects, any hosted connections are automatically re-associated with the LAG. If the interconnect was originally associated with a different LAG, the hosted connections remain associated with the original LAG.</p>
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var associateConnectionWithLag* = Call_AssociateConnectionWithLag_606271(
    name: "associateConnectionWithLag", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AssociateConnectionWithLag",
    validator: validate_AssociateConnectionWithLag_606272, base: "/",
    url: url_AssociateConnectionWithLag_606273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateHostedConnection_606286 = ref object of OpenApiRestCall_605589
proc url_AssociateHostedConnection_606288(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateHostedConnection_606287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "OvertureService.AssociateHostedConnection"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_AssociateHostedConnection_606286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a hosted connection and its virtual interfaces with a link aggregation group (LAG) or interconnect. If the target interconnect or LAG has an existing hosted connection with a conflicting VLAN number or IP address, the operation fails. This action temporarily interrupts the hosted connection's connectivity to AWS as it is being migrated.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_AssociateHostedConnection_606286; body: JsonNode): Recallable =
  ## associateHostedConnection
  ## <p>Associates a hosted connection and its virtual interfaces with a link aggregation group (LAG) or interconnect. If the target interconnect or LAG has an existing hosted connection with a conflicting VLAN number or IP address, the operation fails. This action temporarily interrupts the hosted connection's connectivity to AWS as it is being migrated.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var associateHostedConnection* = Call_AssociateHostedConnection_606286(
    name: "associateHostedConnection", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AssociateHostedConnection",
    validator: validate_AssociateHostedConnection_606287, base: "/",
    url: url_AssociateHostedConnection_606288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateVirtualInterface_606301 = ref object of OpenApiRestCall_605589
proc url_AssociateVirtualInterface_606303(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateVirtualInterface_606302(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "OvertureService.AssociateVirtualInterface"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_AssociateVirtualInterface_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a virtual interface with a specified link aggregation group (LAG) or connection. Connectivity to AWS is temporarily interrupted as the virtual interface is being migrated. If the target connection or LAG has an associated virtual interface with a conflicting VLAN number or a conflicting IP address, the operation fails.</p> <p>Virtual interfaces associated with a hosted connection cannot be associated with a LAG; hosted connections must be migrated along with their virtual interfaces using <a>AssociateHostedConnection</a>.</p> <p>To reassociate a virtual interface to a new connection or LAG, the requester must own either the virtual interface itself or the connection to which the virtual interface is currently associated. Additionally, the requester must own the connection or LAG for the association.</p>
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_AssociateVirtualInterface_606301; body: JsonNode): Recallable =
  ## associateVirtualInterface
  ## <p>Associates a virtual interface with a specified link aggregation group (LAG) or connection. Connectivity to AWS is temporarily interrupted as the virtual interface is being migrated. If the target connection or LAG has an associated virtual interface with a conflicting VLAN number or a conflicting IP address, the operation fails.</p> <p>Virtual interfaces associated with a hosted connection cannot be associated with a LAG; hosted connections must be migrated along with their virtual interfaces using <a>AssociateHostedConnection</a>.</p> <p>To reassociate a virtual interface to a new connection or LAG, the requester must own either the virtual interface itself or the connection to which the virtual interface is currently associated. Additionally, the requester must own the connection or LAG for the association.</p>
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var associateVirtualInterface* = Call_AssociateVirtualInterface_606301(
    name: "associateVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AssociateVirtualInterface",
    validator: validate_AssociateVirtualInterface_606302, base: "/",
    url: url_AssociateVirtualInterface_606303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmConnection_606316 = ref object of OpenApiRestCall_605589
proc url_ConfirmConnection_606318(protocol: Scheme; host: string; base: string;
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

proc validate_ConfirmConnection_606317(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "OvertureService.ConfirmConnection"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_ConfirmConnection_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Confirms the creation of the specified hosted connection on an interconnect.</p> <p>Upon creation, the hosted connection is initially in the <code>Ordering</code> state, and remains in this state until the owner confirms creation of the hosted connection.</p>
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_ConfirmConnection_606316; body: JsonNode): Recallable =
  ## confirmConnection
  ## <p>Confirms the creation of the specified hosted connection on an interconnect.</p> <p>Upon creation, the hosted connection is initially in the <code>Ordering</code> state, and remains in this state until the owner confirms creation of the hosted connection.</p>
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var confirmConnection* = Call_ConfirmConnection_606316(name: "confirmConnection",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.ConfirmConnection",
    validator: validate_ConfirmConnection_606317, base: "/",
    url: url_ConfirmConnection_606318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmPrivateVirtualInterface_606331 = ref object of OpenApiRestCall_605589
proc url_ConfirmPrivateVirtualInterface_606333(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmPrivateVirtualInterface_606332(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "OvertureService.ConfirmPrivateVirtualInterface"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_ConfirmPrivateVirtualInterface_606331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Accepts ownership of a private virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the virtual interface is created and attached to the specified virtual private gateway or Direct Connect gateway, and is made available to handle traffic.</p>
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_ConfirmPrivateVirtualInterface_606331; body: JsonNode): Recallable =
  ## confirmPrivateVirtualInterface
  ## <p>Accepts ownership of a private virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the virtual interface is created and attached to the specified virtual private gateway or Direct Connect gateway, and is made available to handle traffic.</p>
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var confirmPrivateVirtualInterface* = Call_ConfirmPrivateVirtualInterface_606331(
    name: "confirmPrivateVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.ConfirmPrivateVirtualInterface",
    validator: validate_ConfirmPrivateVirtualInterface_606332, base: "/",
    url: url_ConfirmPrivateVirtualInterface_606333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmPublicVirtualInterface_606346 = ref object of OpenApiRestCall_605589
proc url_ConfirmPublicVirtualInterface_606348(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmPublicVirtualInterface_606347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "OvertureService.ConfirmPublicVirtualInterface"))
  if valid_606349 != nil:
    section.add "X-Amz-Target", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_ConfirmPublicVirtualInterface_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Accepts ownership of a public virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the specified virtual interface is created and made available to handle traffic.</p>
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_ConfirmPublicVirtualInterface_606346; body: JsonNode): Recallable =
  ## confirmPublicVirtualInterface
  ## <p>Accepts ownership of a public virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the specified virtual interface is created and made available to handle traffic.</p>
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var confirmPublicVirtualInterface* = Call_ConfirmPublicVirtualInterface_606346(
    name: "confirmPublicVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.ConfirmPublicVirtualInterface",
    validator: validate_ConfirmPublicVirtualInterface_606347, base: "/",
    url: url_ConfirmPublicVirtualInterface_606348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmTransitVirtualInterface_606361 = ref object of OpenApiRestCall_605589
proc url_ConfirmTransitVirtualInterface_606363(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmTransitVirtualInterface_606362(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606364 = header.getOrDefault("X-Amz-Target")
  valid_606364 = validateParameter(valid_606364, JString, required = true, default = newJString(
      "OvertureService.ConfirmTransitVirtualInterface"))
  if valid_606364 != nil:
    section.add "X-Amz-Target", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_ConfirmTransitVirtualInterface_606361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Accepts ownership of a transit virtual interface created by another AWS account.</p> <p> After the owner of the transit virtual interface makes this call, the specified transit virtual interface is created and made available to handle traffic.</p>
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_ConfirmTransitVirtualInterface_606361; body: JsonNode): Recallable =
  ## confirmTransitVirtualInterface
  ## <p>Accepts ownership of a transit virtual interface created by another AWS account.</p> <p> After the owner of the transit virtual interface makes this call, the specified transit virtual interface is created and made available to handle traffic.</p>
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var confirmTransitVirtualInterface* = Call_ConfirmTransitVirtualInterface_606361(
    name: "confirmTransitVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.ConfirmTransitVirtualInterface",
    validator: validate_ConfirmTransitVirtualInterface_606362, base: "/",
    url: url_ConfirmTransitVirtualInterface_606363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBGPPeer_606376 = ref object of OpenApiRestCall_605589
proc url_CreateBGPPeer_606378(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBGPPeer_606377(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "OvertureService.CreateBGPPeer"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_CreateBGPPeer_606376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a BGP peer on the specified virtual interface.</p> <p>You must create a BGP peer for the corresponding address family (IPv4/IPv6) in order to access AWS resources that also use that address family.</p> <p>If logical redundancy is not supported by the connection, interconnect, or LAG, the BGP peer cannot be in the same address family as an existing BGP peer on the virtual interface.</p> <p>When creating a IPv6 BGP peer, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p> <p>For a public virtual interface, the Autonomous System Number (ASN) must be private or already whitelisted for the virtual interface.</p>
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_CreateBGPPeer_606376; body: JsonNode): Recallable =
  ## createBGPPeer
  ## <p>Creates a BGP peer on the specified virtual interface.</p> <p>You must create a BGP peer for the corresponding address family (IPv4/IPv6) in order to access AWS resources that also use that address family.</p> <p>If logical redundancy is not supported by the connection, interconnect, or LAG, the BGP peer cannot be in the same address family as an existing BGP peer on the virtual interface.</p> <p>When creating a IPv6 BGP peer, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p> <p>For a public virtual interface, the Autonomous System Number (ASN) must be private or already whitelisted for the virtual interface.</p>
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var createBGPPeer* = Call_CreateBGPPeer_606376(name: "createBGPPeer",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateBGPPeer",
    validator: validate_CreateBGPPeer_606377, base: "/", url: url_CreateBGPPeer_606378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_606391 = ref object of OpenApiRestCall_605589
proc url_CreateConnection_606393(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConnection_606392(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_606394 = header.getOrDefault("X-Amz-Target")
  valid_606394 = validateParameter(valid_606394, JString, required = true, default = newJString(
      "OvertureService.CreateConnection"))
  if valid_606394 != nil:
    section.add "X-Amz-Target", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_CreateConnection_606391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a connection between a customer network and a specific AWS Direct Connect location.</p> <p>A connection links your internal network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end of the cable is connected to your router, the other to an AWS Direct Connect router.</p> <p>To find the locations for your Region, use <a>DescribeLocations</a>.</p> <p>You can automatically add the new connection to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new connection is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no connection is created.</p>
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_CreateConnection_606391; body: JsonNode): Recallable =
  ## createConnection
  ## <p>Creates a connection between a customer network and a specific AWS Direct Connect location.</p> <p>A connection links your internal network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end of the cable is connected to your router, the other to an AWS Direct Connect router.</p> <p>To find the locations for your Region, use <a>DescribeLocations</a>.</p> <p>You can automatically add the new connection to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new connection is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no connection is created.</p>
  ##   body: JObject (required)
  var body_606405 = newJObject()
  if body != nil:
    body_606405 = body
  result = call_606404.call(nil, nil, nil, nil, body_606405)

var createConnection* = Call_CreateConnection_606391(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateConnection",
    validator: validate_CreateConnection_606392, base: "/",
    url: url_CreateConnection_606393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectConnectGateway_606406 = ref object of OpenApiRestCall_605589
proc url_CreateDirectConnectGateway_606408(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectConnectGateway_606407(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606409 = header.getOrDefault("X-Amz-Target")
  valid_606409 = validateParameter(valid_606409, JString, required = true, default = newJString(
      "OvertureService.CreateDirectConnectGateway"))
  if valid_606409 != nil:
    section.add "X-Amz-Target", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Signature")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Signature", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Content-Sha256", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Date")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Date", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Credential")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Credential", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Security-Token")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Security-Token", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Algorithm")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Algorithm", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-SignedHeaders", valid_606416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_CreateDirectConnectGateway_606406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Direct Connect gateway, which is an intermediate object that enables you to connect a set of virtual interfaces and virtual private gateways. A Direct Connect gateway is global and visible in any AWS Region after it is created. The virtual interfaces and virtual private gateways that are connected through a Direct Connect gateway can be in different AWS Regions. This enables you to connect to a VPC in any Region, regardless of the Region in which the virtual interfaces are located, and pass traffic between them.
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_CreateDirectConnectGateway_606406; body: JsonNode): Recallable =
  ## createDirectConnectGateway
  ## Creates a Direct Connect gateway, which is an intermediate object that enables you to connect a set of virtual interfaces and virtual private gateways. A Direct Connect gateway is global and visible in any AWS Region after it is created. The virtual interfaces and virtual private gateways that are connected through a Direct Connect gateway can be in different AWS Regions. This enables you to connect to a VPC in any Region, regardless of the Region in which the virtual interfaces are located, and pass traffic between them.
  ##   body: JObject (required)
  var body_606420 = newJObject()
  if body != nil:
    body_606420 = body
  result = call_606419.call(nil, nil, nil, nil, body_606420)

var createDirectConnectGateway* = Call_CreateDirectConnectGateway_606406(
    name: "createDirectConnectGateway", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateDirectConnectGateway",
    validator: validate_CreateDirectConnectGateway_606407, base: "/",
    url: url_CreateDirectConnectGateway_606408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectConnectGatewayAssociation_606421 = ref object of OpenApiRestCall_605589
proc url_CreateDirectConnectGatewayAssociation_606423(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectConnectGatewayAssociation_606422(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606424 = header.getOrDefault("X-Amz-Target")
  valid_606424 = validateParameter(valid_606424, JString, required = true, default = newJString(
      "OvertureService.CreateDirectConnectGatewayAssociation"))
  if valid_606424 != nil:
    section.add "X-Amz-Target", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606433: Call_CreateDirectConnectGatewayAssociation_606421;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates an association between a Direct Connect gateway and a virtual private gateway. The virtual private gateway must be attached to a VPC and must not be associated with another Direct Connect gateway.
  ## 
  let valid = call_606433.validator(path, query, header, formData, body)
  let scheme = call_606433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606433.url(scheme.get, call_606433.host, call_606433.base,
                         call_606433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606433, url, valid)

proc call*(call_606434: Call_CreateDirectConnectGatewayAssociation_606421;
          body: JsonNode): Recallable =
  ## createDirectConnectGatewayAssociation
  ## Creates an association between a Direct Connect gateway and a virtual private gateway. The virtual private gateway must be attached to a VPC and must not be associated with another Direct Connect gateway.
  ##   body: JObject (required)
  var body_606435 = newJObject()
  if body != nil:
    body_606435 = body
  result = call_606434.call(nil, nil, nil, nil, body_606435)

var createDirectConnectGatewayAssociation* = Call_CreateDirectConnectGatewayAssociation_606421(
    name: "createDirectConnectGatewayAssociation", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.CreateDirectConnectGatewayAssociation",
    validator: validate_CreateDirectConnectGatewayAssociation_606422, base: "/",
    url: url_CreateDirectConnectGatewayAssociation_606423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectConnectGatewayAssociationProposal_606436 = ref object of OpenApiRestCall_605589
proc url_CreateDirectConnectGatewayAssociationProposal_606438(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectConnectGatewayAssociationProposal_606437(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
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
  var valid_606439 = header.getOrDefault("X-Amz-Target")
  valid_606439 = validateParameter(valid_606439, JString, required = true, default = newJString(
      "OvertureService.CreateDirectConnectGatewayAssociationProposal"))
  if valid_606439 != nil:
    section.add "X-Amz-Target", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606448: Call_CreateDirectConnectGatewayAssociationProposal_606436;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a proposal to associate the specified virtual private gateway or transit gateway with the specified Direct Connect gateway.</p> <p>You can only associate a Direct Connect gateway and virtual private gateway or transit gateway when the account that owns the Direct Connect gateway and the account that owns the virtual private gateway or transit gateway have the same AWS Payer ID.</p>
  ## 
  let valid = call_606448.validator(path, query, header, formData, body)
  let scheme = call_606448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606448.url(scheme.get, call_606448.host, call_606448.base,
                         call_606448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606448, url, valid)

proc call*(call_606449: Call_CreateDirectConnectGatewayAssociationProposal_606436;
          body: JsonNode): Recallable =
  ## createDirectConnectGatewayAssociationProposal
  ## <p>Creates a proposal to associate the specified virtual private gateway or transit gateway with the specified Direct Connect gateway.</p> <p>You can only associate a Direct Connect gateway and virtual private gateway or transit gateway when the account that owns the Direct Connect gateway and the account that owns the virtual private gateway or transit gateway have the same AWS Payer ID.</p>
  ##   body: JObject (required)
  var body_606450 = newJObject()
  if body != nil:
    body_606450 = body
  result = call_606449.call(nil, nil, nil, nil, body_606450)

var createDirectConnectGatewayAssociationProposal* = Call_CreateDirectConnectGatewayAssociationProposal_606436(
    name: "createDirectConnectGatewayAssociationProposal",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.CreateDirectConnectGatewayAssociationProposal",
    validator: validate_CreateDirectConnectGatewayAssociationProposal_606437,
    base: "/", url: url_CreateDirectConnectGatewayAssociationProposal_606438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInterconnect_606451 = ref object of OpenApiRestCall_605589
proc url_CreateInterconnect_606453(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInterconnect_606452(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_606454 = header.getOrDefault("X-Amz-Target")
  valid_606454 = validateParameter(valid_606454, JString, required = true, default = newJString(
      "OvertureService.CreateInterconnect"))
  if valid_606454 != nil:
    section.add "X-Amz-Target", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_CreateInterconnect_606451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an interconnect between an AWS Direct Connect Partner's network and a specific AWS Direct Connect location.</p> <p>An interconnect is a connection that is capable of hosting other connections. The AWS Direct Connect partner can use an interconnect to provide AWS Direct Connect hosted connections to customers through their own network services. Like a standard connection, an interconnect links the partner's network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end is connected to the partner's router, the other to an AWS Direct Connect router.</p> <p>You can automatically add the new interconnect to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new interconnect is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no interconnect is created.</p> <p>For each end customer, the AWS Direct Connect Partner provisions a connection on their interconnect by calling <a>AllocateHostedConnection</a>. The end customer can then connect to AWS resources by creating a virtual interface on their connection, using the VLAN assigned to them by the AWS Direct Connect Partner.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_CreateInterconnect_606451; body: JsonNode): Recallable =
  ## createInterconnect
  ## <p>Creates an interconnect between an AWS Direct Connect Partner's network and a specific AWS Direct Connect location.</p> <p>An interconnect is a connection that is capable of hosting other connections. The AWS Direct Connect partner can use an interconnect to provide AWS Direct Connect hosted connections to customers through their own network services. Like a standard connection, an interconnect links the partner's network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end is connected to the partner's router, the other to an AWS Direct Connect router.</p> <p>You can automatically add the new interconnect to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new interconnect is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no interconnect is created.</p> <p>For each end customer, the AWS Direct Connect Partner provisions a connection on their interconnect by calling <a>AllocateHostedConnection</a>. The end customer can then connect to AWS resources by creating a virtual interface on their connection, using the VLAN assigned to them by the AWS Direct Connect Partner.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_606465 = newJObject()
  if body != nil:
    body_606465 = body
  result = call_606464.call(nil, nil, nil, nil, body_606465)

var createInterconnect* = Call_CreateInterconnect_606451(
    name: "createInterconnect", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateInterconnect",
    validator: validate_CreateInterconnect_606452, base: "/",
    url: url_CreateInterconnect_606453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLag_606466 = ref object of OpenApiRestCall_605589
proc url_CreateLag_606468(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateLag_606467(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606469 = header.getOrDefault("X-Amz-Target")
  valid_606469 = validateParameter(valid_606469, JString, required = true, default = newJString(
      "OvertureService.CreateLag"))
  if valid_606469 != nil:
    section.add "X-Amz-Target", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Signature")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Signature", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Content-Sha256", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Date")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Date", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Credential")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Credential", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Security-Token")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Security-Token", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Algorithm")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Algorithm", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-SignedHeaders", valid_606476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606478: Call_CreateLag_606466; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a link aggregation group (LAG) with the specified number of bundled physical connections between the customer network and a specific AWS Direct Connect location. A LAG is a logical interface that uses the Link Aggregation Control Protocol (LACP) to aggregate multiple interfaces, enabling you to treat them as a single interface.</p> <p>All connections in a LAG must use the same bandwidth and must terminate at the same AWS Direct Connect endpoint.</p> <p>You can have up to 10 connections per LAG. Regardless of this limit, if you request more connections for the LAG than AWS Direct Connect can allocate on a single endpoint, no LAG is created.</p> <p>You can specify an existing physical connection or interconnect to include in the LAG (which counts towards the total number of connections). Doing so interrupts the current physical connection or hosted connections, and re-establishes them as a member of the LAG. The LAG will be created on the same AWS Direct Connect endpoint to which the connection terminates. Any virtual interfaces associated with the connection are automatically disassociated and re-associated with the LAG. The connection ID does not change.</p> <p>If the AWS account used to create a LAG is a registered AWS Direct Connect Partner, the LAG is automatically enabled to host sub-connections. For a LAG owned by a partner, any associated virtual interfaces cannot be directly configured.</p>
  ## 
  let valid = call_606478.validator(path, query, header, formData, body)
  let scheme = call_606478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606478.url(scheme.get, call_606478.host, call_606478.base,
                         call_606478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606478, url, valid)

proc call*(call_606479: Call_CreateLag_606466; body: JsonNode): Recallable =
  ## createLag
  ## <p>Creates a link aggregation group (LAG) with the specified number of bundled physical connections between the customer network and a specific AWS Direct Connect location. A LAG is a logical interface that uses the Link Aggregation Control Protocol (LACP) to aggregate multiple interfaces, enabling you to treat them as a single interface.</p> <p>All connections in a LAG must use the same bandwidth and must terminate at the same AWS Direct Connect endpoint.</p> <p>You can have up to 10 connections per LAG. Regardless of this limit, if you request more connections for the LAG than AWS Direct Connect can allocate on a single endpoint, no LAG is created.</p> <p>You can specify an existing physical connection or interconnect to include in the LAG (which counts towards the total number of connections). Doing so interrupts the current physical connection or hosted connections, and re-establishes them as a member of the LAG. The LAG will be created on the same AWS Direct Connect endpoint to which the connection terminates. Any virtual interfaces associated with the connection are automatically disassociated and re-associated with the LAG. The connection ID does not change.</p> <p>If the AWS account used to create a LAG is a registered AWS Direct Connect Partner, the LAG is automatically enabled to host sub-connections. For a LAG owned by a partner, any associated virtual interfaces cannot be directly configured.</p>
  ##   body: JObject (required)
  var body_606480 = newJObject()
  if body != nil:
    body_606480 = body
  result = call_606479.call(nil, nil, nil, nil, body_606480)

var createLag* = Call_CreateLag_606466(name: "createLag", meth: HttpMethod.HttpPost,
                                    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.CreateLag",
                                    validator: validate_CreateLag_606467,
                                    base: "/", url: url_CreateLag_606468,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePrivateVirtualInterface_606481 = ref object of OpenApiRestCall_605589
proc url_CreatePrivateVirtualInterface_606483(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePrivateVirtualInterface_606482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606484 = header.getOrDefault("X-Amz-Target")
  valid_606484 = validateParameter(valid_606484, JString, required = true, default = newJString(
      "OvertureService.CreatePrivateVirtualInterface"))
  if valid_606484 != nil:
    section.add "X-Amz-Target", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Signature")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Signature", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Content-Sha256", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Date")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Date", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Credential")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Credential", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Security-Token")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Security-Token", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Algorithm")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Algorithm", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-SignedHeaders", valid_606491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606493: Call_CreatePrivateVirtualInterface_606481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a private virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A private virtual interface can be connected to either a Direct Connect gateway or a Virtual Private Gateway (VGW). Connecting the private virtual interface to a Direct Connect gateway enables the possibility for connecting to multiple VPCs, including VPCs in different AWS Regions. Connecting the private virtual interface to a VGW only provides access to a single VPC within the same Region.
  ## 
  let valid = call_606493.validator(path, query, header, formData, body)
  let scheme = call_606493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606493.url(scheme.get, call_606493.host, call_606493.base,
                         call_606493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606493, url, valid)

proc call*(call_606494: Call_CreatePrivateVirtualInterface_606481; body: JsonNode): Recallable =
  ## createPrivateVirtualInterface
  ## Creates a private virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A private virtual interface can be connected to either a Direct Connect gateway or a Virtual Private Gateway (VGW). Connecting the private virtual interface to a Direct Connect gateway enables the possibility for connecting to multiple VPCs, including VPCs in different AWS Regions. Connecting the private virtual interface to a VGW only provides access to a single VPC within the same Region.
  ##   body: JObject (required)
  var body_606495 = newJObject()
  if body != nil:
    body_606495 = body
  result = call_606494.call(nil, nil, nil, nil, body_606495)

var createPrivateVirtualInterface* = Call_CreatePrivateVirtualInterface_606481(
    name: "createPrivateVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreatePrivateVirtualInterface",
    validator: validate_CreatePrivateVirtualInterface_606482, base: "/",
    url: url_CreatePrivateVirtualInterface_606483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicVirtualInterface_606496 = ref object of OpenApiRestCall_605589
proc url_CreatePublicVirtualInterface_606498(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePublicVirtualInterface_606497(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606499 = header.getOrDefault("X-Amz-Target")
  valid_606499 = validateParameter(valid_606499, JString, required = true, default = newJString(
      "OvertureService.CreatePublicVirtualInterface"))
  if valid_606499 != nil:
    section.add "X-Amz-Target", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606508: Call_CreatePublicVirtualInterface_606496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a public virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A public virtual interface supports sending traffic to public services of AWS such as Amazon S3.</p> <p>When creating an IPv6 public virtual interface (<code>addressFamily</code> is <code>ipv6</code>), leave the <code>customer</code> and <code>amazon</code> address fields blank to use auto-assigned IPv6 space. Custom IPv6 addresses are not supported.</p>
  ## 
  let valid = call_606508.validator(path, query, header, formData, body)
  let scheme = call_606508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606508.url(scheme.get, call_606508.host, call_606508.base,
                         call_606508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606508, url, valid)

proc call*(call_606509: Call_CreatePublicVirtualInterface_606496; body: JsonNode): Recallable =
  ## createPublicVirtualInterface
  ## <p>Creates a public virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A public virtual interface supports sending traffic to public services of AWS such as Amazon S3.</p> <p>When creating an IPv6 public virtual interface (<code>addressFamily</code> is <code>ipv6</code>), leave the <code>customer</code> and <code>amazon</code> address fields blank to use auto-assigned IPv6 space. Custom IPv6 addresses are not supported.</p>
  ##   body: JObject (required)
  var body_606510 = newJObject()
  if body != nil:
    body_606510 = body
  result = call_606509.call(nil, nil, nil, nil, body_606510)

var createPublicVirtualInterface* = Call_CreatePublicVirtualInterface_606496(
    name: "createPublicVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreatePublicVirtualInterface",
    validator: validate_CreatePublicVirtualInterface_606497, base: "/",
    url: url_CreatePublicVirtualInterface_606498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransitVirtualInterface_606511 = ref object of OpenApiRestCall_605589
proc url_CreateTransitVirtualInterface_606513(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTransitVirtualInterface_606512(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606514 = header.getOrDefault("X-Amz-Target")
  valid_606514 = validateParameter(valid_606514, JString, required = true, default = newJString(
      "OvertureService.CreateTransitVirtualInterface"))
  if valid_606514 != nil:
    section.add "X-Amz-Target", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Signature")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Signature", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Content-Sha256", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Date")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Date", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Credential")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Credential", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Security-Token")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Security-Token", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Algorithm")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Algorithm", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-SignedHeaders", valid_606521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606523: Call_CreateTransitVirtualInterface_606511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a transit virtual interface. A transit virtual interface should be used to access one or more transit gateways associated with Direct Connect gateways. A transit virtual interface enables the connection of multiple VPCs attached to a transit gateway to a Direct Connect gateway.</p> <important> <p>If you associate your transit gateway with one or more Direct Connect gateways, the Autonomous System Number (ASN) used by the transit gateway and the Direct Connect gateway must be different. For example, if you use the default ASN 64512 for both your the transit gateway and Direct Connect gateway, the association request fails.</p> </important>
  ## 
  let valid = call_606523.validator(path, query, header, formData, body)
  let scheme = call_606523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606523.url(scheme.get, call_606523.host, call_606523.base,
                         call_606523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606523, url, valid)

proc call*(call_606524: Call_CreateTransitVirtualInterface_606511; body: JsonNode): Recallable =
  ## createTransitVirtualInterface
  ## <p>Creates a transit virtual interface. A transit virtual interface should be used to access one or more transit gateways associated with Direct Connect gateways. A transit virtual interface enables the connection of multiple VPCs attached to a transit gateway to a Direct Connect gateway.</p> <important> <p>If you associate your transit gateway with one or more Direct Connect gateways, the Autonomous System Number (ASN) used by the transit gateway and the Direct Connect gateway must be different. For example, if you use the default ASN 64512 for both your the transit gateway and Direct Connect gateway, the association request fails.</p> </important>
  ##   body: JObject (required)
  var body_606525 = newJObject()
  if body != nil:
    body_606525 = body
  result = call_606524.call(nil, nil, nil, nil, body_606525)

var createTransitVirtualInterface* = Call_CreateTransitVirtualInterface_606511(
    name: "createTransitVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateTransitVirtualInterface",
    validator: validate_CreateTransitVirtualInterface_606512, base: "/",
    url: url_CreateTransitVirtualInterface_606513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBGPPeer_606526 = ref object of OpenApiRestCall_605589
proc url_DeleteBGPPeer_606528(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBGPPeer_606527(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606529 = header.getOrDefault("X-Amz-Target")
  valid_606529 = validateParameter(valid_606529, JString, required = true, default = newJString(
      "OvertureService.DeleteBGPPeer"))
  if valid_606529 != nil:
    section.add "X-Amz-Target", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Signature")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Signature", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Content-Sha256", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Date")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Date", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Credential")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Credential", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Security-Token")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Security-Token", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Algorithm")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Algorithm", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-SignedHeaders", valid_606536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606538: Call_DeleteBGPPeer_606526; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified BGP peer on the specified virtual interface with the specified customer address and ASN.</p> <p>You cannot delete the last BGP peer from a virtual interface.</p>
  ## 
  let valid = call_606538.validator(path, query, header, formData, body)
  let scheme = call_606538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606538.url(scheme.get, call_606538.host, call_606538.base,
                         call_606538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606538, url, valid)

proc call*(call_606539: Call_DeleteBGPPeer_606526; body: JsonNode): Recallable =
  ## deleteBGPPeer
  ## <p>Deletes the specified BGP peer on the specified virtual interface with the specified customer address and ASN.</p> <p>You cannot delete the last BGP peer from a virtual interface.</p>
  ##   body: JObject (required)
  var body_606540 = newJObject()
  if body != nil:
    body_606540 = body
  result = call_606539.call(nil, nil, nil, nil, body_606540)

var deleteBGPPeer* = Call_DeleteBGPPeer_606526(name: "deleteBGPPeer",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteBGPPeer",
    validator: validate_DeleteBGPPeer_606527, base: "/", url: url_DeleteBGPPeer_606528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_606541 = ref object of OpenApiRestCall_605589
proc url_DeleteConnection_606543(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConnection_606542(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_606544 = header.getOrDefault("X-Amz-Target")
  valid_606544 = validateParameter(valid_606544, JString, required = true, default = newJString(
      "OvertureService.DeleteConnection"))
  if valid_606544 != nil:
    section.add "X-Amz-Target", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Signature")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Signature", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Content-Sha256", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Date")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Date", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Credential")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Credential", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Security-Token")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Security-Token", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Algorithm")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Algorithm", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-SignedHeaders", valid_606551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606553: Call_DeleteConnection_606541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified connection.</p> <p>Deleting a connection only stops the AWS Direct Connect port hour and data transfer charges. If you are partnering with any third parties to connect with the AWS Direct Connect location, you must cancel your service with them separately.</p>
  ## 
  let valid = call_606553.validator(path, query, header, formData, body)
  let scheme = call_606553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606553.url(scheme.get, call_606553.host, call_606553.base,
                         call_606553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606553, url, valid)

proc call*(call_606554: Call_DeleteConnection_606541; body: JsonNode): Recallable =
  ## deleteConnection
  ## <p>Deletes the specified connection.</p> <p>Deleting a connection only stops the AWS Direct Connect port hour and data transfer charges. If you are partnering with any third parties to connect with the AWS Direct Connect location, you must cancel your service with them separately.</p>
  ##   body: JObject (required)
  var body_606555 = newJObject()
  if body != nil:
    body_606555 = body
  result = call_606554.call(nil, nil, nil, nil, body_606555)

var deleteConnection* = Call_DeleteConnection_606541(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteConnection",
    validator: validate_DeleteConnection_606542, base: "/",
    url: url_DeleteConnection_606543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectConnectGateway_606556 = ref object of OpenApiRestCall_605589
proc url_DeleteDirectConnectGateway_606558(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectConnectGateway_606557(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606559 = header.getOrDefault("X-Amz-Target")
  valid_606559 = validateParameter(valid_606559, JString, required = true, default = newJString(
      "OvertureService.DeleteDirectConnectGateway"))
  if valid_606559 != nil:
    section.add "X-Amz-Target", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Signature")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Signature", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Content-Sha256", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Date")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Date", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Credential")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Credential", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Security-Token")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Security-Token", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Algorithm")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Algorithm", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-SignedHeaders", valid_606566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606568: Call_DeleteDirectConnectGateway_606556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Direct Connect gateway. You must first delete all virtual interfaces that are attached to the Direct Connect gateway and disassociate all virtual private gateways associated with the Direct Connect gateway.
  ## 
  let valid = call_606568.validator(path, query, header, formData, body)
  let scheme = call_606568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606568.url(scheme.get, call_606568.host, call_606568.base,
                         call_606568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606568, url, valid)

proc call*(call_606569: Call_DeleteDirectConnectGateway_606556; body: JsonNode): Recallable =
  ## deleteDirectConnectGateway
  ## Deletes the specified Direct Connect gateway. You must first delete all virtual interfaces that are attached to the Direct Connect gateway and disassociate all virtual private gateways associated with the Direct Connect gateway.
  ##   body: JObject (required)
  var body_606570 = newJObject()
  if body != nil:
    body_606570 = body
  result = call_606569.call(nil, nil, nil, nil, body_606570)

var deleteDirectConnectGateway* = Call_DeleteDirectConnectGateway_606556(
    name: "deleteDirectConnectGateway", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteDirectConnectGateway",
    validator: validate_DeleteDirectConnectGateway_606557, base: "/",
    url: url_DeleteDirectConnectGateway_606558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectConnectGatewayAssociation_606571 = ref object of OpenApiRestCall_605589
proc url_DeleteDirectConnectGatewayAssociation_606573(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectConnectGatewayAssociation_606572(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606574 = header.getOrDefault("X-Amz-Target")
  valid_606574 = validateParameter(valid_606574, JString, required = true, default = newJString(
      "OvertureService.DeleteDirectConnectGatewayAssociation"))
  if valid_606574 != nil:
    section.add "X-Amz-Target", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Signature")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Signature", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Content-Sha256", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Date")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Date", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Credential")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Credential", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Security-Token")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Security-Token", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Algorithm")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Algorithm", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-SignedHeaders", valid_606581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606583: Call_DeleteDirectConnectGatewayAssociation_606571;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the association between the specified Direct Connect gateway and virtual private gateway.</p> <p>We recommend that you specify the <code>associationID</code> to delete the association. Alternatively, if you own virtual gateway and a Direct Connect gateway association, you can specify the <code>virtualGatewayId</code> and <code>directConnectGatewayId</code> to delete an association.</p>
  ## 
  let valid = call_606583.validator(path, query, header, formData, body)
  let scheme = call_606583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606583.url(scheme.get, call_606583.host, call_606583.base,
                         call_606583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606583, url, valid)

proc call*(call_606584: Call_DeleteDirectConnectGatewayAssociation_606571;
          body: JsonNode): Recallable =
  ## deleteDirectConnectGatewayAssociation
  ## <p>Deletes the association between the specified Direct Connect gateway and virtual private gateway.</p> <p>We recommend that you specify the <code>associationID</code> to delete the association. Alternatively, if you own virtual gateway and a Direct Connect gateway association, you can specify the <code>virtualGatewayId</code> and <code>directConnectGatewayId</code> to delete an association.</p>
  ##   body: JObject (required)
  var body_606585 = newJObject()
  if body != nil:
    body_606585 = body
  result = call_606584.call(nil, nil, nil, nil, body_606585)

var deleteDirectConnectGatewayAssociation* = Call_DeleteDirectConnectGatewayAssociation_606571(
    name: "deleteDirectConnectGatewayAssociation", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DeleteDirectConnectGatewayAssociation",
    validator: validate_DeleteDirectConnectGatewayAssociation_606572, base: "/",
    url: url_DeleteDirectConnectGatewayAssociation_606573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectConnectGatewayAssociationProposal_606586 = ref object of OpenApiRestCall_605589
proc url_DeleteDirectConnectGatewayAssociationProposal_606588(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectConnectGatewayAssociationProposal_606587(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
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
  var valid_606589 = header.getOrDefault("X-Amz-Target")
  valid_606589 = validateParameter(valid_606589, JString, required = true, default = newJString(
      "OvertureService.DeleteDirectConnectGatewayAssociationProposal"))
  if valid_606589 != nil:
    section.add "X-Amz-Target", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Signature")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Signature", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Content-Sha256", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Date")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Date", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Credential")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Credential", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Security-Token")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Security-Token", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Algorithm")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Algorithm", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-SignedHeaders", valid_606596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606598: Call_DeleteDirectConnectGatewayAssociationProposal_606586;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the association proposal request between the specified Direct Connect gateway and virtual private gateway or transit gateway.
  ## 
  let valid = call_606598.validator(path, query, header, formData, body)
  let scheme = call_606598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606598.url(scheme.get, call_606598.host, call_606598.base,
                         call_606598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606598, url, valid)

proc call*(call_606599: Call_DeleteDirectConnectGatewayAssociationProposal_606586;
          body: JsonNode): Recallable =
  ## deleteDirectConnectGatewayAssociationProposal
  ## Deletes the association proposal request between the specified Direct Connect gateway and virtual private gateway or transit gateway.
  ##   body: JObject (required)
  var body_606600 = newJObject()
  if body != nil:
    body_606600 = body
  result = call_606599.call(nil, nil, nil, nil, body_606600)

var deleteDirectConnectGatewayAssociationProposal* = Call_DeleteDirectConnectGatewayAssociationProposal_606586(
    name: "deleteDirectConnectGatewayAssociationProposal",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DeleteDirectConnectGatewayAssociationProposal",
    validator: validate_DeleteDirectConnectGatewayAssociationProposal_606587,
    base: "/", url: url_DeleteDirectConnectGatewayAssociationProposal_606588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInterconnect_606601 = ref object of OpenApiRestCall_605589
proc url_DeleteInterconnect_606603(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInterconnect_606602(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_606604 = header.getOrDefault("X-Amz-Target")
  valid_606604 = validateParameter(valid_606604, JString, required = true, default = newJString(
      "OvertureService.DeleteInterconnect"))
  if valid_606604 != nil:
    section.add "X-Amz-Target", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Signature")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Signature", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Content-Sha256", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Date")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Date", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Credential")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Credential", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Security-Token")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Security-Token", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Algorithm")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Algorithm", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-SignedHeaders", valid_606611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606613: Call_DeleteInterconnect_606601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_606613.validator(path, query, header, formData, body)
  let scheme = call_606613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606613.url(scheme.get, call_606613.host, call_606613.base,
                         call_606613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606613, url, valid)

proc call*(call_606614: Call_DeleteInterconnect_606601; body: JsonNode): Recallable =
  ## deleteInterconnect
  ## <p>Deletes the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_606615 = newJObject()
  if body != nil:
    body_606615 = body
  result = call_606614.call(nil, nil, nil, nil, body_606615)

var deleteInterconnect* = Call_DeleteInterconnect_606601(
    name: "deleteInterconnect", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteInterconnect",
    validator: validate_DeleteInterconnect_606602, base: "/",
    url: url_DeleteInterconnect_606603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLag_606616 = ref object of OpenApiRestCall_605589
proc url_DeleteLag_606618(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteLag_606617(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606619 = header.getOrDefault("X-Amz-Target")
  valid_606619 = validateParameter(valid_606619, JString, required = true, default = newJString(
      "OvertureService.DeleteLag"))
  if valid_606619 != nil:
    section.add "X-Amz-Target", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Signature")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Signature", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Content-Sha256", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Date")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Date", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Credential")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Credential", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Security-Token")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Security-Token", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Algorithm")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Algorithm", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-SignedHeaders", valid_606626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606628: Call_DeleteLag_606616; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified link aggregation group (LAG). You cannot delete a LAG if it has active virtual interfaces or hosted connections.
  ## 
  let valid = call_606628.validator(path, query, header, formData, body)
  let scheme = call_606628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606628.url(scheme.get, call_606628.host, call_606628.base,
                         call_606628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606628, url, valid)

proc call*(call_606629: Call_DeleteLag_606616; body: JsonNode): Recallable =
  ## deleteLag
  ## Deletes the specified link aggregation group (LAG). You cannot delete a LAG if it has active virtual interfaces or hosted connections.
  ##   body: JObject (required)
  var body_606630 = newJObject()
  if body != nil:
    body_606630 = body
  result = call_606629.call(nil, nil, nil, nil, body_606630)

var deleteLag* = Call_DeleteLag_606616(name: "deleteLag", meth: HttpMethod.HttpPost,
                                    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DeleteLag",
                                    validator: validate_DeleteLag_606617,
                                    base: "/", url: url_DeleteLag_606618,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualInterface_606631 = ref object of OpenApiRestCall_605589
proc url_DeleteVirtualInterface_606633(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteVirtualInterface_606632(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606634 = header.getOrDefault("X-Amz-Target")
  valid_606634 = validateParameter(valid_606634, JString, required = true, default = newJString(
      "OvertureService.DeleteVirtualInterface"))
  if valid_606634 != nil:
    section.add "X-Amz-Target", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Signature")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Signature", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Content-Sha256", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Date")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Date", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Credential")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Credential", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Security-Token")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Security-Token", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Algorithm")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Algorithm", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-SignedHeaders", valid_606641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606643: Call_DeleteVirtualInterface_606631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a virtual interface.
  ## 
  let valid = call_606643.validator(path, query, header, formData, body)
  let scheme = call_606643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606643.url(scheme.get, call_606643.host, call_606643.base,
                         call_606643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606643, url, valid)

proc call*(call_606644: Call_DeleteVirtualInterface_606631; body: JsonNode): Recallable =
  ## deleteVirtualInterface
  ## Deletes a virtual interface.
  ##   body: JObject (required)
  var body_606645 = newJObject()
  if body != nil:
    body_606645 = body
  result = call_606644.call(nil, nil, nil, nil, body_606645)

var deleteVirtualInterface* = Call_DeleteVirtualInterface_606631(
    name: "deleteVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteVirtualInterface",
    validator: validate_DeleteVirtualInterface_606632, base: "/",
    url: url_DeleteVirtualInterface_606633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnectionLoa_606646 = ref object of OpenApiRestCall_605589
proc url_DescribeConnectionLoa_606648(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeConnectionLoa_606647(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606649 = header.getOrDefault("X-Amz-Target")
  valid_606649 = validateParameter(valid_606649, JString, required = true, default = newJString(
      "OvertureService.DescribeConnectionLoa"))
  if valid_606649 != nil:
    section.add "X-Amz-Target", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Signature")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Signature", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Content-Sha256", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Date")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Date", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Credential")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Credential", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Security-Token")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Security-Token", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Algorithm")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Algorithm", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-SignedHeaders", valid_606656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606658: Call_DescribeConnectionLoa_606646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for a connection.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that your APN partner or service provider uses when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ## 
  let valid = call_606658.validator(path, query, header, formData, body)
  let scheme = call_606658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606658.url(scheme.get, call_606658.host, call_606658.base,
                         call_606658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606658, url, valid)

proc call*(call_606659: Call_DescribeConnectionLoa_606646; body: JsonNode): Recallable =
  ## describeConnectionLoa
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for a connection.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that your APN partner or service provider uses when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ##   body: JObject (required)
  var body_606660 = newJObject()
  if body != nil:
    body_606660 = body
  result = call_606659.call(nil, nil, nil, nil, body_606660)

var describeConnectionLoa* = Call_DescribeConnectionLoa_606646(
    name: "describeConnectionLoa", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeConnectionLoa",
    validator: validate_DescribeConnectionLoa_606647, base: "/",
    url: url_DescribeConnectionLoa_606648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnections_606661 = ref object of OpenApiRestCall_605589
proc url_DescribeConnections_606663(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeConnections_606662(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_606664 = header.getOrDefault("X-Amz-Target")
  valid_606664 = validateParameter(valid_606664, JString, required = true, default = newJString(
      "OvertureService.DescribeConnections"))
  if valid_606664 != nil:
    section.add "X-Amz-Target", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Signature")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Signature", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Content-Sha256", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Date")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Date", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Credential")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Credential", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Security-Token")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Security-Token", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Algorithm")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Algorithm", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-SignedHeaders", valid_606671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606673: Call_DescribeConnections_606661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the specified connection or all connections in this Region.
  ## 
  let valid = call_606673.validator(path, query, header, formData, body)
  let scheme = call_606673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606673.url(scheme.get, call_606673.host, call_606673.base,
                         call_606673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606673, url, valid)

proc call*(call_606674: Call_DescribeConnections_606661; body: JsonNode): Recallable =
  ## describeConnections
  ## Displays the specified connection or all connections in this Region.
  ##   body: JObject (required)
  var body_606675 = newJObject()
  if body != nil:
    body_606675 = body
  result = call_606674.call(nil, nil, nil, nil, body_606675)

var describeConnections* = Call_DescribeConnections_606661(
    name: "describeConnections", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeConnections",
    validator: validate_DescribeConnections_606662, base: "/",
    url: url_DescribeConnections_606663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnectionsOnInterconnect_606676 = ref object of OpenApiRestCall_605589
proc url_DescribeConnectionsOnInterconnect_606678(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConnectionsOnInterconnect_606677(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606679 = header.getOrDefault("X-Amz-Target")
  valid_606679 = validateParameter(valid_606679, JString, required = true, default = newJString(
      "OvertureService.DescribeConnectionsOnInterconnect"))
  if valid_606679 != nil:
    section.add "X-Amz-Target", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Signature")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Signature", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Content-Sha256", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Date")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Date", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Credential")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Credential", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Security-Token")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Security-Token", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Algorithm")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Algorithm", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-SignedHeaders", valid_606686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606688: Call_DescribeConnectionsOnInterconnect_606676;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deprecated. Use <a>DescribeHostedConnections</a> instead.</p> <p>Lists the connections that have been provisioned on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_606688.validator(path, query, header, formData, body)
  let scheme = call_606688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606688.url(scheme.get, call_606688.host, call_606688.base,
                         call_606688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606688, url, valid)

proc call*(call_606689: Call_DescribeConnectionsOnInterconnect_606676;
          body: JsonNode): Recallable =
  ## describeConnectionsOnInterconnect
  ## <p>Deprecated. Use <a>DescribeHostedConnections</a> instead.</p> <p>Lists the connections that have been provisioned on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_606690 = newJObject()
  if body != nil:
    body_606690 = body
  result = call_606689.call(nil, nil, nil, nil, body_606690)

var describeConnectionsOnInterconnect* = Call_DescribeConnectionsOnInterconnect_606676(
    name: "describeConnectionsOnInterconnect", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeConnectionsOnInterconnect",
    validator: validate_DescribeConnectionsOnInterconnect_606677, base: "/",
    url: url_DescribeConnectionsOnInterconnect_606678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectConnectGatewayAssociationProposals_606691 = ref object of OpenApiRestCall_605589
proc url_DescribeDirectConnectGatewayAssociationProposals_606693(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectConnectGatewayAssociationProposals_606692(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
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
  var valid_606694 = header.getOrDefault("X-Amz-Target")
  valid_606694 = validateParameter(valid_606694, JString, required = true, default = newJString(
      "OvertureService.DescribeDirectConnectGatewayAssociationProposals"))
  if valid_606694 != nil:
    section.add "X-Amz-Target", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-Signature")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Signature", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Content-Sha256", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Date")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Date", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Credential")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Credential", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Security-Token")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Security-Token", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Algorithm")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Algorithm", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-SignedHeaders", valid_606701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606703: Call_DescribeDirectConnectGatewayAssociationProposals_606691;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes one or more association proposals for connection between a virtual private gateway or transit gateway and a Direct Connect gateway. 
  ## 
  let valid = call_606703.validator(path, query, header, formData, body)
  let scheme = call_606703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606703.url(scheme.get, call_606703.host, call_606703.base,
                         call_606703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606703, url, valid)

proc call*(call_606704: Call_DescribeDirectConnectGatewayAssociationProposals_606691;
          body: JsonNode): Recallable =
  ## describeDirectConnectGatewayAssociationProposals
  ## Describes one or more association proposals for connection between a virtual private gateway or transit gateway and a Direct Connect gateway. 
  ##   body: JObject (required)
  var body_606705 = newJObject()
  if body != nil:
    body_606705 = body
  result = call_606704.call(nil, nil, nil, nil, body_606705)

var describeDirectConnectGatewayAssociationProposals* = Call_DescribeDirectConnectGatewayAssociationProposals_606691(
    name: "describeDirectConnectGatewayAssociationProposals",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DescribeDirectConnectGatewayAssociationProposals",
    validator: validate_DescribeDirectConnectGatewayAssociationProposals_606692,
    base: "/", url: url_DescribeDirectConnectGatewayAssociationProposals_606693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectConnectGatewayAssociations_606706 = ref object of OpenApiRestCall_605589
proc url_DescribeDirectConnectGatewayAssociations_606708(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectConnectGatewayAssociations_606707(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606709 = header.getOrDefault("X-Amz-Target")
  valid_606709 = validateParameter(valid_606709, JString, required = true, default = newJString(
      "OvertureService.DescribeDirectConnectGatewayAssociations"))
  if valid_606709 != nil:
    section.add "X-Amz-Target", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Signature")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Signature", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Content-Sha256", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Date")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Date", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Credential")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Credential", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Security-Token")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Security-Token", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-Algorithm")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-Algorithm", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-SignedHeaders", valid_606716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606718: Call_DescribeDirectConnectGatewayAssociations_606706;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the associations between your Direct Connect gateways and virtual private gateways. You must specify a Direct Connect gateway, a virtual private gateway, or both. If you specify a Direct Connect gateway, the response contains all virtual private gateways associated with the Direct Connect gateway. If you specify a virtual private gateway, the response contains all Direct Connect gateways associated with the virtual private gateway. If you specify both, the response contains the association between the Direct Connect gateway and the virtual private gateway.
  ## 
  let valid = call_606718.validator(path, query, header, formData, body)
  let scheme = call_606718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606718.url(scheme.get, call_606718.host, call_606718.base,
                         call_606718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606718, url, valid)

proc call*(call_606719: Call_DescribeDirectConnectGatewayAssociations_606706;
          body: JsonNode): Recallable =
  ## describeDirectConnectGatewayAssociations
  ## Lists the associations between your Direct Connect gateways and virtual private gateways. You must specify a Direct Connect gateway, a virtual private gateway, or both. If you specify a Direct Connect gateway, the response contains all virtual private gateways associated with the Direct Connect gateway. If you specify a virtual private gateway, the response contains all Direct Connect gateways associated with the virtual private gateway. If you specify both, the response contains the association between the Direct Connect gateway and the virtual private gateway.
  ##   body: JObject (required)
  var body_606720 = newJObject()
  if body != nil:
    body_606720 = body
  result = call_606719.call(nil, nil, nil, nil, body_606720)

var describeDirectConnectGatewayAssociations* = Call_DescribeDirectConnectGatewayAssociations_606706(
    name: "describeDirectConnectGatewayAssociations", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DescribeDirectConnectGatewayAssociations",
    validator: validate_DescribeDirectConnectGatewayAssociations_606707,
    base: "/", url: url_DescribeDirectConnectGatewayAssociations_606708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectConnectGatewayAttachments_606721 = ref object of OpenApiRestCall_605589
proc url_DescribeDirectConnectGatewayAttachments_606723(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectConnectGatewayAttachments_606722(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606724 = header.getOrDefault("X-Amz-Target")
  valid_606724 = validateParameter(valid_606724, JString, required = true, default = newJString(
      "OvertureService.DescribeDirectConnectGatewayAttachments"))
  if valid_606724 != nil:
    section.add "X-Amz-Target", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Signature")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Signature", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Content-Sha256", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Date")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Date", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Credential")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Credential", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Security-Token")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Security-Token", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-Algorithm")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Algorithm", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-SignedHeaders", valid_606731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606733: Call_DescribeDirectConnectGatewayAttachments_606721;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the attachments between your Direct Connect gateways and virtual interfaces. You must specify a Direct Connect gateway, a virtual interface, or both. If you specify a Direct Connect gateway, the response contains all virtual interfaces attached to the Direct Connect gateway. If you specify a virtual interface, the response contains all Direct Connect gateways attached to the virtual interface. If you specify both, the response contains the attachment between the Direct Connect gateway and the virtual interface.
  ## 
  let valid = call_606733.validator(path, query, header, formData, body)
  let scheme = call_606733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606733.url(scheme.get, call_606733.host, call_606733.base,
                         call_606733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606733, url, valid)

proc call*(call_606734: Call_DescribeDirectConnectGatewayAttachments_606721;
          body: JsonNode): Recallable =
  ## describeDirectConnectGatewayAttachments
  ## Lists the attachments between your Direct Connect gateways and virtual interfaces. You must specify a Direct Connect gateway, a virtual interface, or both. If you specify a Direct Connect gateway, the response contains all virtual interfaces attached to the Direct Connect gateway. If you specify a virtual interface, the response contains all Direct Connect gateways attached to the virtual interface. If you specify both, the response contains the attachment between the Direct Connect gateway and the virtual interface.
  ##   body: JObject (required)
  var body_606735 = newJObject()
  if body != nil:
    body_606735 = body
  result = call_606734.call(nil, nil, nil, nil, body_606735)

var describeDirectConnectGatewayAttachments* = Call_DescribeDirectConnectGatewayAttachments_606721(
    name: "describeDirectConnectGatewayAttachments", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DescribeDirectConnectGatewayAttachments",
    validator: validate_DescribeDirectConnectGatewayAttachments_606722, base: "/",
    url: url_DescribeDirectConnectGatewayAttachments_606723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectConnectGateways_606736 = ref object of OpenApiRestCall_605589
proc url_DescribeDirectConnectGateways_606738(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectConnectGateways_606737(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606739 = header.getOrDefault("X-Amz-Target")
  valid_606739 = validateParameter(valid_606739, JString, required = true, default = newJString(
      "OvertureService.DescribeDirectConnectGateways"))
  if valid_606739 != nil:
    section.add "X-Amz-Target", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Signature")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Signature", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Content-Sha256", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Date")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Date", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Credential")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Credential", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Security-Token")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Security-Token", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Algorithm")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Algorithm", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-SignedHeaders", valid_606746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606748: Call_DescribeDirectConnectGateways_606736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all your Direct Connect gateways or only the specified Direct Connect gateway. Deleted Direct Connect gateways are not returned.
  ## 
  let valid = call_606748.validator(path, query, header, formData, body)
  let scheme = call_606748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606748.url(scheme.get, call_606748.host, call_606748.base,
                         call_606748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606748, url, valid)

proc call*(call_606749: Call_DescribeDirectConnectGateways_606736; body: JsonNode): Recallable =
  ## describeDirectConnectGateways
  ## Lists all your Direct Connect gateways or only the specified Direct Connect gateway. Deleted Direct Connect gateways are not returned.
  ##   body: JObject (required)
  var body_606750 = newJObject()
  if body != nil:
    body_606750 = body
  result = call_606749.call(nil, nil, nil, nil, body_606750)

var describeDirectConnectGateways* = Call_DescribeDirectConnectGateways_606736(
    name: "describeDirectConnectGateways", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeDirectConnectGateways",
    validator: validate_DescribeDirectConnectGateways_606737, base: "/",
    url: url_DescribeDirectConnectGateways_606738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHostedConnections_606751 = ref object of OpenApiRestCall_605589
proc url_DescribeHostedConnections_606753(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHostedConnections_606752(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606754 = header.getOrDefault("X-Amz-Target")
  valid_606754 = validateParameter(valid_606754, JString, required = true, default = newJString(
      "OvertureService.DescribeHostedConnections"))
  if valid_606754 != nil:
    section.add "X-Amz-Target", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Signature")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Signature", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Content-Sha256", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Date")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Date", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Credential")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Credential", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Security-Token")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Security-Token", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Algorithm")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Algorithm", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-SignedHeaders", valid_606761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606763: Call_DescribeHostedConnections_606751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the hosted connections that have been provisioned on the specified interconnect or link aggregation group (LAG).</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_606763.validator(path, query, header, formData, body)
  let scheme = call_606763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606763.url(scheme.get, call_606763.host, call_606763.base,
                         call_606763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606763, url, valid)

proc call*(call_606764: Call_DescribeHostedConnections_606751; body: JsonNode): Recallable =
  ## describeHostedConnections
  ## <p>Lists the hosted connections that have been provisioned on the specified interconnect or link aggregation group (LAG).</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_606765 = newJObject()
  if body != nil:
    body_606765 = body
  result = call_606764.call(nil, nil, nil, nil, body_606765)

var describeHostedConnections* = Call_DescribeHostedConnections_606751(
    name: "describeHostedConnections", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeHostedConnections",
    validator: validate_DescribeHostedConnections_606752, base: "/",
    url: url_DescribeHostedConnections_606753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInterconnectLoa_606766 = ref object of OpenApiRestCall_605589
proc url_DescribeInterconnectLoa_606768(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInterconnectLoa_606767(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606769 = header.getOrDefault("X-Amz-Target")
  valid_606769 = validateParameter(valid_606769, JString, required = true, default = newJString(
      "OvertureService.DescribeInterconnectLoa"))
  if valid_606769 != nil:
    section.add "X-Amz-Target", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-Signature")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-Signature", valid_606770
  var valid_606771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-Content-Sha256", valid_606771
  var valid_606772 = header.getOrDefault("X-Amz-Date")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-Date", valid_606772
  var valid_606773 = header.getOrDefault("X-Amz-Credential")
  valid_606773 = validateParameter(valid_606773, JString, required = false,
                                 default = nil)
  if valid_606773 != nil:
    section.add "X-Amz-Credential", valid_606773
  var valid_606774 = header.getOrDefault("X-Amz-Security-Token")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-Security-Token", valid_606774
  var valid_606775 = header.getOrDefault("X-Amz-Algorithm")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Algorithm", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-SignedHeaders", valid_606776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606778: Call_DescribeInterconnectLoa_606766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for the specified interconnect.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ## 
  let valid = call_606778.validator(path, query, header, formData, body)
  let scheme = call_606778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606778.url(scheme.get, call_606778.host, call_606778.base,
                         call_606778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606778, url, valid)

proc call*(call_606779: Call_DescribeInterconnectLoa_606766; body: JsonNode): Recallable =
  ## describeInterconnectLoa
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for the specified interconnect.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ##   body: JObject (required)
  var body_606780 = newJObject()
  if body != nil:
    body_606780 = body
  result = call_606779.call(nil, nil, nil, nil, body_606780)

var describeInterconnectLoa* = Call_DescribeInterconnectLoa_606766(
    name: "describeInterconnectLoa", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeInterconnectLoa",
    validator: validate_DescribeInterconnectLoa_606767, base: "/",
    url: url_DescribeInterconnectLoa_606768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInterconnects_606781 = ref object of OpenApiRestCall_605589
proc url_DescribeInterconnects_606783(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeInterconnects_606782(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606784 = header.getOrDefault("X-Amz-Target")
  valid_606784 = validateParameter(valid_606784, JString, required = true, default = newJString(
      "OvertureService.DescribeInterconnects"))
  if valid_606784 != nil:
    section.add "X-Amz-Target", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-Signature")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-Signature", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Content-Sha256", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-Date")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Date", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-Credential")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-Credential", valid_606788
  var valid_606789 = header.getOrDefault("X-Amz-Security-Token")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-Security-Token", valid_606789
  var valid_606790 = header.getOrDefault("X-Amz-Algorithm")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Algorithm", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-SignedHeaders", valid_606791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606793: Call_DescribeInterconnects_606781; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the interconnects owned by the AWS account or only the specified interconnect.
  ## 
  let valid = call_606793.validator(path, query, header, formData, body)
  let scheme = call_606793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606793.url(scheme.get, call_606793.host, call_606793.base,
                         call_606793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606793, url, valid)

proc call*(call_606794: Call_DescribeInterconnects_606781; body: JsonNode): Recallable =
  ## describeInterconnects
  ## Lists the interconnects owned by the AWS account or only the specified interconnect.
  ##   body: JObject (required)
  var body_606795 = newJObject()
  if body != nil:
    body_606795 = body
  result = call_606794.call(nil, nil, nil, nil, body_606795)

var describeInterconnects* = Call_DescribeInterconnects_606781(
    name: "describeInterconnects", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeInterconnects",
    validator: validate_DescribeInterconnects_606782, base: "/",
    url: url_DescribeInterconnects_606783, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLags_606796 = ref object of OpenApiRestCall_605589
proc url_DescribeLags_606798(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLags_606797(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606799 = header.getOrDefault("X-Amz-Target")
  valid_606799 = validateParameter(valid_606799, JString, required = true, default = newJString(
      "OvertureService.DescribeLags"))
  if valid_606799 != nil:
    section.add "X-Amz-Target", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Signature")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Signature", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-Content-Sha256", valid_606801
  var valid_606802 = header.getOrDefault("X-Amz-Date")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "X-Amz-Date", valid_606802
  var valid_606803 = header.getOrDefault("X-Amz-Credential")
  valid_606803 = validateParameter(valid_606803, JString, required = false,
                                 default = nil)
  if valid_606803 != nil:
    section.add "X-Amz-Credential", valid_606803
  var valid_606804 = header.getOrDefault("X-Amz-Security-Token")
  valid_606804 = validateParameter(valid_606804, JString, required = false,
                                 default = nil)
  if valid_606804 != nil:
    section.add "X-Amz-Security-Token", valid_606804
  var valid_606805 = header.getOrDefault("X-Amz-Algorithm")
  valid_606805 = validateParameter(valid_606805, JString, required = false,
                                 default = nil)
  if valid_606805 != nil:
    section.add "X-Amz-Algorithm", valid_606805
  var valid_606806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606806 = validateParameter(valid_606806, JString, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "X-Amz-SignedHeaders", valid_606806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606808: Call_DescribeLags_606796; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes all your link aggregation groups (LAG) or the specified LAG.
  ## 
  let valid = call_606808.validator(path, query, header, formData, body)
  let scheme = call_606808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606808.url(scheme.get, call_606808.host, call_606808.base,
                         call_606808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606808, url, valid)

proc call*(call_606809: Call_DescribeLags_606796; body: JsonNode): Recallable =
  ## describeLags
  ## Describes all your link aggregation groups (LAG) or the specified LAG.
  ##   body: JObject (required)
  var body_606810 = newJObject()
  if body != nil:
    body_606810 = body
  result = call_606809.call(nil, nil, nil, nil, body_606810)

var describeLags* = Call_DescribeLags_606796(name: "describeLags",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeLags",
    validator: validate_DescribeLags_606797, base: "/", url: url_DescribeLags_606798,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoa_606811 = ref object of OpenApiRestCall_605589
proc url_DescribeLoa_606813(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLoa_606812(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606814 = header.getOrDefault("X-Amz-Target")
  valid_606814 = validateParameter(valid_606814, JString, required = true, default = newJString(
      "OvertureService.DescribeLoa"))
  if valid_606814 != nil:
    section.add "X-Amz-Target", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Signature")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Signature", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Content-Sha256", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-Date")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-Date", valid_606817
  var valid_606818 = header.getOrDefault("X-Amz-Credential")
  valid_606818 = validateParameter(valid_606818, JString, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "X-Amz-Credential", valid_606818
  var valid_606819 = header.getOrDefault("X-Amz-Security-Token")
  valid_606819 = validateParameter(valid_606819, JString, required = false,
                                 default = nil)
  if valid_606819 != nil:
    section.add "X-Amz-Security-Token", valid_606819
  var valid_606820 = header.getOrDefault("X-Amz-Algorithm")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "X-Amz-Algorithm", valid_606820
  var valid_606821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "X-Amz-SignedHeaders", valid_606821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606823: Call_DescribeLoa_606811; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the LOA-CFA for a connection, interconnect, or link aggregation group (LAG).</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ## 
  let valid = call_606823.validator(path, query, header, formData, body)
  let scheme = call_606823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606823.url(scheme.get, call_606823.host, call_606823.base,
                         call_606823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606823, url, valid)

proc call*(call_606824: Call_DescribeLoa_606811; body: JsonNode): Recallable =
  ## describeLoa
  ## <p>Gets the LOA-CFA for a connection, interconnect, or link aggregation group (LAG).</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ##   body: JObject (required)
  var body_606825 = newJObject()
  if body != nil:
    body_606825 = body
  result = call_606824.call(nil, nil, nil, nil, body_606825)

var describeLoa* = Call_DescribeLoa_606811(name: "describeLoa",
                                        meth: HttpMethod.HttpPost,
                                        host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DescribeLoa",
                                        validator: validate_DescribeLoa_606812,
                                        base: "/", url: url_DescribeLoa_606813,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocations_606826 = ref object of OpenApiRestCall_605589
proc url_DescribeLocations_606828(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLocations_606827(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_606829 = header.getOrDefault("X-Amz-Target")
  valid_606829 = validateParameter(valid_606829, JString, required = true, default = newJString(
      "OvertureService.DescribeLocations"))
  if valid_606829 != nil:
    section.add "X-Amz-Target", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Signature")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Signature", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Content-Sha256", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-Date")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Date", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-Credential")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-Credential", valid_606833
  var valid_606834 = header.getOrDefault("X-Amz-Security-Token")
  valid_606834 = validateParameter(valid_606834, JString, required = false,
                                 default = nil)
  if valid_606834 != nil:
    section.add "X-Amz-Security-Token", valid_606834
  var valid_606835 = header.getOrDefault("X-Amz-Algorithm")
  valid_606835 = validateParameter(valid_606835, JString, required = false,
                                 default = nil)
  if valid_606835 != nil:
    section.add "X-Amz-Algorithm", valid_606835
  var valid_606836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606836 = validateParameter(valid_606836, JString, required = false,
                                 default = nil)
  if valid_606836 != nil:
    section.add "X-Amz-SignedHeaders", valid_606836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606837: Call_DescribeLocations_606826; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS Direct Connect locations in the current AWS Region. These are the locations that can be selected when calling <a>CreateConnection</a> or <a>CreateInterconnect</a>.
  ## 
  let valid = call_606837.validator(path, query, header, formData, body)
  let scheme = call_606837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606837.url(scheme.get, call_606837.host, call_606837.base,
                         call_606837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606837, url, valid)

proc call*(call_606838: Call_DescribeLocations_606826): Recallable =
  ## describeLocations
  ## Lists the AWS Direct Connect locations in the current AWS Region. These are the locations that can be selected when calling <a>CreateConnection</a> or <a>CreateInterconnect</a>.
  result = call_606838.call(nil, nil, nil, nil, nil)

var describeLocations* = Call_DescribeLocations_606826(name: "describeLocations",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeLocations",
    validator: validate_DescribeLocations_606827, base: "/",
    url: url_DescribeLocations_606828, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_606839 = ref object of OpenApiRestCall_605589
proc url_DescribeTags_606841(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTags_606840(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606842 = header.getOrDefault("X-Amz-Target")
  valid_606842 = validateParameter(valid_606842, JString, required = true, default = newJString(
      "OvertureService.DescribeTags"))
  if valid_606842 != nil:
    section.add "X-Amz-Target", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Signature")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Signature", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Content-Sha256", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Date")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Date", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Credential")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Credential", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Security-Token")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Security-Token", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Algorithm")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Algorithm", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-SignedHeaders", valid_606849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606851: Call_DescribeTags_606839; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified AWS Direct Connect resources.
  ## 
  let valid = call_606851.validator(path, query, header, formData, body)
  let scheme = call_606851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606851.url(scheme.get, call_606851.host, call_606851.base,
                         call_606851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606851, url, valid)

proc call*(call_606852: Call_DescribeTags_606839; body: JsonNode): Recallable =
  ## describeTags
  ## Describes the tags associated with the specified AWS Direct Connect resources.
  ##   body: JObject (required)
  var body_606853 = newJObject()
  if body != nil:
    body_606853 = body
  result = call_606852.call(nil, nil, nil, nil, body_606853)

var describeTags* = Call_DescribeTags_606839(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeTags",
    validator: validate_DescribeTags_606840, base: "/", url: url_DescribeTags_606841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualGateways_606854 = ref object of OpenApiRestCall_605589
proc url_DescribeVirtualGateways_606856(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeVirtualGateways_606855(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606857 = header.getOrDefault("X-Amz-Target")
  valid_606857 = validateParameter(valid_606857, JString, required = true, default = newJString(
      "OvertureService.DescribeVirtualGateways"))
  if valid_606857 != nil:
    section.add "X-Amz-Target", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Signature")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Signature", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Content-Sha256", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Date")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Date", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Credential")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Credential", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-Security-Token")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Security-Token", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-Algorithm")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-Algorithm", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-SignedHeaders", valid_606864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606865: Call_DescribeVirtualGateways_606854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the virtual private gateways owned by the AWS account.</p> <p>You can create one or more AWS Direct Connect private virtual interfaces linked to a virtual private gateway.</p>
  ## 
  let valid = call_606865.validator(path, query, header, formData, body)
  let scheme = call_606865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606865.url(scheme.get, call_606865.host, call_606865.base,
                         call_606865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606865, url, valid)

proc call*(call_606866: Call_DescribeVirtualGateways_606854): Recallable =
  ## describeVirtualGateways
  ## <p>Lists the virtual private gateways owned by the AWS account.</p> <p>You can create one or more AWS Direct Connect private virtual interfaces linked to a virtual private gateway.</p>
  result = call_606866.call(nil, nil, nil, nil, nil)

var describeVirtualGateways* = Call_DescribeVirtualGateways_606854(
    name: "describeVirtualGateways", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeVirtualGateways",
    validator: validate_DescribeVirtualGateways_606855, base: "/",
    url: url_DescribeVirtualGateways_606856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualInterfaces_606867 = ref object of OpenApiRestCall_605589
proc url_DescribeVirtualInterfaces_606869(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeVirtualInterfaces_606868(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606870 = header.getOrDefault("X-Amz-Target")
  valid_606870 = validateParameter(valid_606870, JString, required = true, default = newJString(
      "OvertureService.DescribeVirtualInterfaces"))
  if valid_606870 != nil:
    section.add "X-Amz-Target", valid_606870
  var valid_606871 = header.getOrDefault("X-Amz-Signature")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "X-Amz-Signature", valid_606871
  var valid_606872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Content-Sha256", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-Date")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Date", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-Credential")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Credential", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Security-Token")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Security-Token", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Algorithm")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Algorithm", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-SignedHeaders", valid_606877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606879: Call_DescribeVirtualInterfaces_606867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays all virtual interfaces for an AWS account. Virtual interfaces deleted fewer than 15 minutes before you make the request are also returned. If you specify a connection ID, only the virtual interfaces associated with the connection are returned. If you specify a virtual interface ID, then only a single virtual interface is returned.</p> <p>A virtual interface (VLAN) transmits the traffic between the AWS Direct Connect location and the customer network.</p>
  ## 
  let valid = call_606879.validator(path, query, header, formData, body)
  let scheme = call_606879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606879.url(scheme.get, call_606879.host, call_606879.base,
                         call_606879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606879, url, valid)

proc call*(call_606880: Call_DescribeVirtualInterfaces_606867; body: JsonNode): Recallable =
  ## describeVirtualInterfaces
  ## <p>Displays all virtual interfaces for an AWS account. Virtual interfaces deleted fewer than 15 minutes before you make the request are also returned. If you specify a connection ID, only the virtual interfaces associated with the connection are returned. If you specify a virtual interface ID, then only a single virtual interface is returned.</p> <p>A virtual interface (VLAN) transmits the traffic between the AWS Direct Connect location and the customer network.</p>
  ##   body: JObject (required)
  var body_606881 = newJObject()
  if body != nil:
    body_606881 = body
  result = call_606880.call(nil, nil, nil, nil, body_606881)

var describeVirtualInterfaces* = Call_DescribeVirtualInterfaces_606867(
    name: "describeVirtualInterfaces", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeVirtualInterfaces",
    validator: validate_DescribeVirtualInterfaces_606868, base: "/",
    url: url_DescribeVirtualInterfaces_606869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConnectionFromLag_606882 = ref object of OpenApiRestCall_605589
proc url_DisassociateConnectionFromLag_606884(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateConnectionFromLag_606883(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606885 = header.getOrDefault("X-Amz-Target")
  valid_606885 = validateParameter(valid_606885, JString, required = true, default = newJString(
      "OvertureService.DisassociateConnectionFromLag"))
  if valid_606885 != nil:
    section.add "X-Amz-Target", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Signature")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Signature", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-Content-Sha256", valid_606887
  var valid_606888 = header.getOrDefault("X-Amz-Date")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-Date", valid_606888
  var valid_606889 = header.getOrDefault("X-Amz-Credential")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-Credential", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Security-Token")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Security-Token", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Algorithm")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Algorithm", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-SignedHeaders", valid_606892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606894: Call_DisassociateConnectionFromLag_606882; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates a connection from a link aggregation group (LAG). The connection is interrupted and re-established as a standalone connection (the connection is not deleted; to delete the connection, use the <a>DeleteConnection</a> request). If the LAG has associated virtual interfaces or hosted connections, they remain associated with the LAG. A disassociated connection owned by an AWS Direct Connect Partner is automatically converted to an interconnect.</p> <p>If disassociating the connection would cause the LAG to fall below its setting for minimum number of operational connections, the request fails, except when it's the last member of the LAG. If all connections are disassociated, the LAG continues to exist as an empty LAG with no physical connections. </p>
  ## 
  let valid = call_606894.validator(path, query, header, formData, body)
  let scheme = call_606894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606894.url(scheme.get, call_606894.host, call_606894.base,
                         call_606894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606894, url, valid)

proc call*(call_606895: Call_DisassociateConnectionFromLag_606882; body: JsonNode): Recallable =
  ## disassociateConnectionFromLag
  ## <p>Disassociates a connection from a link aggregation group (LAG). The connection is interrupted and re-established as a standalone connection (the connection is not deleted; to delete the connection, use the <a>DeleteConnection</a> request). If the LAG has associated virtual interfaces or hosted connections, they remain associated with the LAG. A disassociated connection owned by an AWS Direct Connect Partner is automatically converted to an interconnect.</p> <p>If disassociating the connection would cause the LAG to fall below its setting for minimum number of operational connections, the request fails, except when it's the last member of the LAG. If all connections are disassociated, the LAG continues to exist as an empty LAG with no physical connections. </p>
  ##   body: JObject (required)
  var body_606896 = newJObject()
  if body != nil:
    body_606896 = body
  result = call_606895.call(nil, nil, nil, nil, body_606896)

var disassociateConnectionFromLag* = Call_DisassociateConnectionFromLag_606882(
    name: "disassociateConnectionFromLag", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DisassociateConnectionFromLag",
    validator: validate_DisassociateConnectionFromLag_606883, base: "/",
    url: url_DisassociateConnectionFromLag_606884,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606897 = ref object of OpenApiRestCall_605589
proc url_TagResource_606899(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606898(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606900 = header.getOrDefault("X-Amz-Target")
  valid_606900 = validateParameter(valid_606900, JString, required = true, default = newJString(
      "OvertureService.TagResource"))
  if valid_606900 != nil:
    section.add "X-Amz-Target", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Signature")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Signature", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-Content-Sha256", valid_606902
  var valid_606903 = header.getOrDefault("X-Amz-Date")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-Date", valid_606903
  var valid_606904 = header.getOrDefault("X-Amz-Credential")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-Credential", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-Security-Token")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-Security-Token", valid_606905
  var valid_606906 = header.getOrDefault("X-Amz-Algorithm")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-Algorithm", valid_606906
  var valid_606907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-SignedHeaders", valid_606907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606909: Call_TagResource_606897; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified AWS Direct Connect resource. Each resource can have a maximum of 50 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the resource, this action updates its value.</p>
  ## 
  let valid = call_606909.validator(path, query, header, formData, body)
  let scheme = call_606909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606909.url(scheme.get, call_606909.host, call_606909.base,
                         call_606909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606909, url, valid)

proc call*(call_606910: Call_TagResource_606897; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds the specified tags to the specified AWS Direct Connect resource. Each resource can have a maximum of 50 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the resource, this action updates its value.</p>
  ##   body: JObject (required)
  var body_606911 = newJObject()
  if body != nil:
    body_606911 = body
  result = call_606910.call(nil, nil, nil, nil, body_606911)

var tagResource* = Call_TagResource_606897(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.TagResource",
                                        validator: validate_TagResource_606898,
                                        base: "/", url: url_TagResource_606899,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606912 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606914(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606913(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606915 = header.getOrDefault("X-Amz-Target")
  valid_606915 = validateParameter(valid_606915, JString, required = true, default = newJString(
      "OvertureService.UntagResource"))
  if valid_606915 != nil:
    section.add "X-Amz-Target", valid_606915
  var valid_606916 = header.getOrDefault("X-Amz-Signature")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "X-Amz-Signature", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Content-Sha256", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-Date")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-Date", valid_606918
  var valid_606919 = header.getOrDefault("X-Amz-Credential")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "X-Amz-Credential", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-Security-Token")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-Security-Token", valid_606920
  var valid_606921 = header.getOrDefault("X-Amz-Algorithm")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Algorithm", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-SignedHeaders", valid_606922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606924: Call_UntagResource_606912; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified AWS Direct Connect resource.
  ## 
  let valid = call_606924.validator(path, query, header, formData, body)
  let scheme = call_606924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606924.url(scheme.get, call_606924.host, call_606924.base,
                         call_606924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606924, url, valid)

proc call*(call_606925: Call_UntagResource_606912; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from the specified AWS Direct Connect resource.
  ##   body: JObject (required)
  var body_606926 = newJObject()
  if body != nil:
    body_606926 = body
  result = call_606925.call(nil, nil, nil, nil, body_606926)

var untagResource* = Call_UntagResource_606912(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.UntagResource",
    validator: validate_UntagResource_606913, base: "/", url: url_UntagResource_606914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDirectConnectGatewayAssociation_606927 = ref object of OpenApiRestCall_605589
proc url_UpdateDirectConnectGatewayAssociation_606929(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDirectConnectGatewayAssociation_606928(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606930 = header.getOrDefault("X-Amz-Target")
  valid_606930 = validateParameter(valid_606930, JString, required = true, default = newJString(
      "OvertureService.UpdateDirectConnectGatewayAssociation"))
  if valid_606930 != nil:
    section.add "X-Amz-Target", valid_606930
  var valid_606931 = header.getOrDefault("X-Amz-Signature")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "X-Amz-Signature", valid_606931
  var valid_606932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606932 = validateParameter(valid_606932, JString, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "X-Amz-Content-Sha256", valid_606932
  var valid_606933 = header.getOrDefault("X-Amz-Date")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "X-Amz-Date", valid_606933
  var valid_606934 = header.getOrDefault("X-Amz-Credential")
  valid_606934 = validateParameter(valid_606934, JString, required = false,
                                 default = nil)
  if valid_606934 != nil:
    section.add "X-Amz-Credential", valid_606934
  var valid_606935 = header.getOrDefault("X-Amz-Security-Token")
  valid_606935 = validateParameter(valid_606935, JString, required = false,
                                 default = nil)
  if valid_606935 != nil:
    section.add "X-Amz-Security-Token", valid_606935
  var valid_606936 = header.getOrDefault("X-Amz-Algorithm")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "X-Amz-Algorithm", valid_606936
  var valid_606937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-SignedHeaders", valid_606937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606939: Call_UpdateDirectConnectGatewayAssociation_606927;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified attributes of the Direct Connect gateway association.</p> <p>Add or remove prefixes from the association.</p>
  ## 
  let valid = call_606939.validator(path, query, header, formData, body)
  let scheme = call_606939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606939.url(scheme.get, call_606939.host, call_606939.base,
                         call_606939.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606939, url, valid)

proc call*(call_606940: Call_UpdateDirectConnectGatewayAssociation_606927;
          body: JsonNode): Recallable =
  ## updateDirectConnectGatewayAssociation
  ## <p>Updates the specified attributes of the Direct Connect gateway association.</p> <p>Add or remove prefixes from the association.</p>
  ##   body: JObject (required)
  var body_606941 = newJObject()
  if body != nil:
    body_606941 = body
  result = call_606940.call(nil, nil, nil, nil, body_606941)

var updateDirectConnectGatewayAssociation* = Call_UpdateDirectConnectGatewayAssociation_606927(
    name: "updateDirectConnectGatewayAssociation", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.UpdateDirectConnectGatewayAssociation",
    validator: validate_UpdateDirectConnectGatewayAssociation_606928, base: "/",
    url: url_UpdateDirectConnectGatewayAssociation_606929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLag_606942 = ref object of OpenApiRestCall_605589
proc url_UpdateLag_606944(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateLag_606943(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606945 = header.getOrDefault("X-Amz-Target")
  valid_606945 = validateParameter(valid_606945, JString, required = true, default = newJString(
      "OvertureService.UpdateLag"))
  if valid_606945 != nil:
    section.add "X-Amz-Target", valid_606945
  var valid_606946 = header.getOrDefault("X-Amz-Signature")
  valid_606946 = validateParameter(valid_606946, JString, required = false,
                                 default = nil)
  if valid_606946 != nil:
    section.add "X-Amz-Signature", valid_606946
  var valid_606947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Content-Sha256", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-Date")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-Date", valid_606948
  var valid_606949 = header.getOrDefault("X-Amz-Credential")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "X-Amz-Credential", valid_606949
  var valid_606950 = header.getOrDefault("X-Amz-Security-Token")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-Security-Token", valid_606950
  var valid_606951 = header.getOrDefault("X-Amz-Algorithm")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "X-Amz-Algorithm", valid_606951
  var valid_606952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606952 = validateParameter(valid_606952, JString, required = false,
                                 default = nil)
  if valid_606952 != nil:
    section.add "X-Amz-SignedHeaders", valid_606952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606954: Call_UpdateLag_606942; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the attributes of the specified link aggregation group (LAG).</p> <p>You can update the following attributes:</p> <ul> <li> <p>The name of the LAG.</p> </li> <li> <p>The value for the minimum number of connections that must be operational for the LAG itself to be operational. </p> </li> </ul> <p>When you create a LAG, the default value for the minimum number of operational connections is zero (0). If you update this value and the number of operational connections falls below the specified value, the LAG automatically goes down to avoid over-utilization of the remaining connections. Adjust this value with care, as it could force the LAG down if it is set higher than the current number of operational connections.</p>
  ## 
  let valid = call_606954.validator(path, query, header, formData, body)
  let scheme = call_606954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606954.url(scheme.get, call_606954.host, call_606954.base,
                         call_606954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606954, url, valid)

proc call*(call_606955: Call_UpdateLag_606942; body: JsonNode): Recallable =
  ## updateLag
  ## <p>Updates the attributes of the specified link aggregation group (LAG).</p> <p>You can update the following attributes:</p> <ul> <li> <p>The name of the LAG.</p> </li> <li> <p>The value for the minimum number of connections that must be operational for the LAG itself to be operational. </p> </li> </ul> <p>When you create a LAG, the default value for the minimum number of operational connections is zero (0). If you update this value and the number of operational connections falls below the specified value, the LAG automatically goes down to avoid over-utilization of the remaining connections. Adjust this value with care, as it could force the LAG down if it is set higher than the current number of operational connections.</p>
  ##   body: JObject (required)
  var body_606956 = newJObject()
  if body != nil:
    body_606956 = body
  result = call_606955.call(nil, nil, nil, nil, body_606956)

var updateLag* = Call_UpdateLag_606942(name: "updateLag", meth: HttpMethod.HttpPost,
                                    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.UpdateLag",
                                    validator: validate_UpdateLag_606943,
                                    base: "/", url: url_UpdateLag_606944,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualInterfaceAttributes_606957 = ref object of OpenApiRestCall_605589
proc url_UpdateVirtualInterfaceAttributes_606959(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVirtualInterfaceAttributes_606958(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606960 = header.getOrDefault("X-Amz-Target")
  valid_606960 = validateParameter(valid_606960, JString, required = true, default = newJString(
      "OvertureService.UpdateVirtualInterfaceAttributes"))
  if valid_606960 != nil:
    section.add "X-Amz-Target", valid_606960
  var valid_606961 = header.getOrDefault("X-Amz-Signature")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Signature", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-Content-Sha256", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-Date")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-Date", valid_606963
  var valid_606964 = header.getOrDefault("X-Amz-Credential")
  valid_606964 = validateParameter(valid_606964, JString, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "X-Amz-Credential", valid_606964
  var valid_606965 = header.getOrDefault("X-Amz-Security-Token")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-Security-Token", valid_606965
  var valid_606966 = header.getOrDefault("X-Amz-Algorithm")
  valid_606966 = validateParameter(valid_606966, JString, required = false,
                                 default = nil)
  if valid_606966 != nil:
    section.add "X-Amz-Algorithm", valid_606966
  var valid_606967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606967 = validateParameter(valid_606967, JString, required = false,
                                 default = nil)
  if valid_606967 != nil:
    section.add "X-Amz-SignedHeaders", valid_606967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606969: Call_UpdateVirtualInterfaceAttributes_606957;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified attributes of the specified virtual private interface.</p> <p>Setting the MTU of a virtual interface to 9001 (jumbo frames) can cause an update to the underlying physical connection if it wasn't updated to support jumbo frames. Updating the connection disrupts network connectivity for all virtual interfaces associated with the connection for up to 30 seconds. To check whether your connection supports jumbo frames, call <a>DescribeConnections</a>. To check whether your virtual interface supports jumbo frames, call <a>DescribeVirtualInterfaces</a>.</p>
  ## 
  let valid = call_606969.validator(path, query, header, formData, body)
  let scheme = call_606969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606969.url(scheme.get, call_606969.host, call_606969.base,
                         call_606969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606969, url, valid)

proc call*(call_606970: Call_UpdateVirtualInterfaceAttributes_606957;
          body: JsonNode): Recallable =
  ## updateVirtualInterfaceAttributes
  ## <p>Updates the specified attributes of the specified virtual private interface.</p> <p>Setting the MTU of a virtual interface to 9001 (jumbo frames) can cause an update to the underlying physical connection if it wasn't updated to support jumbo frames. Updating the connection disrupts network connectivity for all virtual interfaces associated with the connection for up to 30 seconds. To check whether your connection supports jumbo frames, call <a>DescribeConnections</a>. To check whether your virtual interface supports jumbo frames, call <a>DescribeVirtualInterfaces</a>.</p>
  ##   body: JObject (required)
  var body_606971 = newJObject()
  if body != nil:
    body_606971 = body
  result = call_606970.call(nil, nil, nil, nil, body_606971)

var updateVirtualInterfaceAttributes* = Call_UpdateVirtualInterfaceAttributes_606957(
    name: "updateVirtualInterfaceAttributes", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.UpdateVirtualInterfaceAttributes",
    validator: validate_UpdateVirtualInterfaceAttributes_606958, base: "/",
    url: url_UpdateVirtualInterfaceAttributes_606959,
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
