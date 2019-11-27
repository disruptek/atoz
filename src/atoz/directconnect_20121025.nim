
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_AcceptDirectConnectGatewayAssociationProposal_599705 = ref object of OpenApiRestCall_599368
proc url_AcceptDirectConnectGatewayAssociationProposal_599707(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptDirectConnectGatewayAssociationProposal_599706(
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "OvertureService.AcceptDirectConnectGatewayAssociationProposal"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_AcceptDirectConnectGatewayAssociationProposal_599705;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Accepts a proposal request to attach a virtual private gateway or transit gateway to a Direct Connect gateway.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_AcceptDirectConnectGatewayAssociationProposal_599705;
          body: JsonNode): Recallable =
  ## acceptDirectConnectGatewayAssociationProposal
  ## Accepts a proposal request to attach a virtual private gateway or transit gateway to a Direct Connect gateway.
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var acceptDirectConnectGatewayAssociationProposal* = Call_AcceptDirectConnectGatewayAssociationProposal_599705(
    name: "acceptDirectConnectGatewayAssociationProposal",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.AcceptDirectConnectGatewayAssociationProposal",
    validator: validate_AcceptDirectConnectGatewayAssociationProposal_599706,
    base: "/", url: url_AcceptDirectConnectGatewayAssociationProposal_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocateConnectionOnInterconnect_599974 = ref object of OpenApiRestCall_599368
proc url_AllocateConnectionOnInterconnect_599976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocateConnectionOnInterconnect_599975(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "OvertureService.AllocateConnectionOnInterconnect"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_AllocateConnectionOnInterconnect_599974;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deprecated. Use <a>AllocateHostedConnection</a> instead.</p> <p>Creates a hosted connection on an interconnect.</p> <p>Allocates a VLAN number and a specified amount of bandwidth for use by a hosted connection on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_AllocateConnectionOnInterconnect_599974;
          body: JsonNode): Recallable =
  ## allocateConnectionOnInterconnect
  ## <p>Deprecated. Use <a>AllocateHostedConnection</a> instead.</p> <p>Creates a hosted connection on an interconnect.</p> <p>Allocates a VLAN number and a specified amount of bandwidth for use by a hosted connection on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var allocateConnectionOnInterconnect* = Call_AllocateConnectionOnInterconnect_599974(
    name: "allocateConnectionOnInterconnect", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocateConnectionOnInterconnect",
    validator: validate_AllocateConnectionOnInterconnect_599975, base: "/",
    url: url_AllocateConnectionOnInterconnect_599976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocateHostedConnection_599989 = ref object of OpenApiRestCall_599368
proc url_AllocateHostedConnection_599991(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocateHostedConnection_599990(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "OvertureService.AllocateHostedConnection"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_AllocateHostedConnection_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a hosted connection on the specified interconnect or a link aggregation group (LAG) of interconnects.</p> <p>Allocates a VLAN number and a specified amount of capacity (bandwidth) for use by a hosted connection on the specified interconnect or LAG of interconnects. AWS polices the hosted connection for the specified capacity and the AWS Direct Connect Partner must also police the hosted connection for the specified capacity.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_AllocateHostedConnection_599989; body: JsonNode): Recallable =
  ## allocateHostedConnection
  ## <p>Creates a hosted connection on the specified interconnect or a link aggregation group (LAG) of interconnects.</p> <p>Allocates a VLAN number and a specified amount of capacity (bandwidth) for use by a hosted connection on the specified interconnect or LAG of interconnects. AWS polices the hosted connection for the specified capacity and the AWS Direct Connect Partner must also police the hosted connection for the specified capacity.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var allocateHostedConnection* = Call_AllocateHostedConnection_599989(
    name: "allocateHostedConnection", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocateHostedConnection",
    validator: validate_AllocateHostedConnection_599990, base: "/",
    url: url_AllocateHostedConnection_599991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocatePrivateVirtualInterface_600004 = ref object of OpenApiRestCall_599368
proc url_AllocatePrivateVirtualInterface_600006(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocatePrivateVirtualInterface_600005(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "OvertureService.AllocatePrivateVirtualInterface"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_AllocatePrivateVirtualInterface_600004;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Provisions a private virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this action must be confirmed by the owner using <a>ConfirmPrivateVirtualInterface</a>. Until then, the virtual interface is in the <code>Confirming</code> state and is not available to handle traffic.</p>
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_AllocatePrivateVirtualInterface_600004; body: JsonNode): Recallable =
  ## allocatePrivateVirtualInterface
  ## <p>Provisions a private virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this action must be confirmed by the owner using <a>ConfirmPrivateVirtualInterface</a>. Until then, the virtual interface is in the <code>Confirming</code> state and is not available to handle traffic.</p>
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var allocatePrivateVirtualInterface* = Call_AllocatePrivateVirtualInterface_600004(
    name: "allocatePrivateVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocatePrivateVirtualInterface",
    validator: validate_AllocatePrivateVirtualInterface_600005, base: "/",
    url: url_AllocatePrivateVirtualInterface_600006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocatePublicVirtualInterface_600019 = ref object of OpenApiRestCall_599368
proc url_AllocatePublicVirtualInterface_600021(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocatePublicVirtualInterface_600020(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "OvertureService.AllocatePublicVirtualInterface"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_AllocatePublicVirtualInterface_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provisions a public virtual interface to be owned by the specified AWS account.</p> <p>The owner of a connection calls this function to provision a public virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this function must be confirmed by the owner using <a>ConfirmPublicVirtualInterface</a>. Until this step has been completed, the virtual interface is in the <code>confirming</code> state and is not available to handle traffic.</p> <p>When creating an IPv6 public virtual interface, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p>
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_AllocatePublicVirtualInterface_600019; body: JsonNode): Recallable =
  ## allocatePublicVirtualInterface
  ## <p>Provisions a public virtual interface to be owned by the specified AWS account.</p> <p>The owner of a connection calls this function to provision a public virtual interface to be owned by the specified AWS account.</p> <p>Virtual interfaces created using this function must be confirmed by the owner using <a>ConfirmPublicVirtualInterface</a>. Until this step has been completed, the virtual interface is in the <code>confirming</code> state and is not available to handle traffic.</p> <p>When creating an IPv6 public virtual interface, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p>
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var allocatePublicVirtualInterface* = Call_AllocatePublicVirtualInterface_600019(
    name: "allocatePublicVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocatePublicVirtualInterface",
    validator: validate_AllocatePublicVirtualInterface_600020, base: "/",
    url: url_AllocatePublicVirtualInterface_600021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AllocateTransitVirtualInterface_600034 = ref object of OpenApiRestCall_599368
proc url_AllocateTransitVirtualInterface_600036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AllocateTransitVirtualInterface_600035(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "OvertureService.AllocateTransitVirtualInterface"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_AllocateTransitVirtualInterface_600034;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Provisions a transit virtual interface to be owned by the specified AWS account. Use this type of interface to connect a transit gateway to your Direct Connect gateway.</p> <p>The owner of a connection provisions a transit virtual interface to be owned by the specified AWS account.</p> <p>After you create a transit virtual interface, it must be confirmed by the owner using <a>ConfirmTransitVirtualInterface</a>. Until this step has been completed, the transit virtual interface is in the <code>requested</code> state and is not available to handle traffic.</p>
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_AllocateTransitVirtualInterface_600034; body: JsonNode): Recallable =
  ## allocateTransitVirtualInterface
  ## <p>Provisions a transit virtual interface to be owned by the specified AWS account. Use this type of interface to connect a transit gateway to your Direct Connect gateway.</p> <p>The owner of a connection provisions a transit virtual interface to be owned by the specified AWS account.</p> <p>After you create a transit virtual interface, it must be confirmed by the owner using <a>ConfirmTransitVirtualInterface</a>. Until this step has been completed, the transit virtual interface is in the <code>requested</code> state and is not available to handle traffic.</p>
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var allocateTransitVirtualInterface* = Call_AllocateTransitVirtualInterface_600034(
    name: "allocateTransitVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AllocateTransitVirtualInterface",
    validator: validate_AllocateTransitVirtualInterface_600035, base: "/",
    url: url_AllocateTransitVirtualInterface_600036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateConnectionWithLag_600049 = ref object of OpenApiRestCall_599368
proc url_AssociateConnectionWithLag_600051(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateConnectionWithLag_600050(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "OvertureService.AssociateConnectionWithLag"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_AssociateConnectionWithLag_600049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an existing connection with a link aggregation group (LAG). The connection is interrupted and re-established as a member of the LAG (connectivity to AWS is interrupted). The connection must be hosted on the same AWS Direct Connect endpoint as the LAG, and its bandwidth must match the bandwidth for the LAG. You can re-associate a connection that's currently associated with a different LAG; however, if removing the connection would cause the original LAG to fall below its setting for minimum number of operational connections, the request fails.</p> <p>Any virtual interfaces that are directly associated with the connection are automatically re-associated with the LAG. If the connection was originally associated with a different LAG, the virtual interfaces remain associated with the original LAG.</p> <p>For interconnects, any hosted connections are automatically re-associated with the LAG. If the interconnect was originally associated with a different LAG, the hosted connections remain associated with the original LAG.</p>
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_AssociateConnectionWithLag_600049; body: JsonNode): Recallable =
  ## associateConnectionWithLag
  ## <p>Associates an existing connection with a link aggregation group (LAG). The connection is interrupted and re-established as a member of the LAG (connectivity to AWS is interrupted). The connection must be hosted on the same AWS Direct Connect endpoint as the LAG, and its bandwidth must match the bandwidth for the LAG. You can re-associate a connection that's currently associated with a different LAG; however, if removing the connection would cause the original LAG to fall below its setting for minimum number of operational connections, the request fails.</p> <p>Any virtual interfaces that are directly associated with the connection are automatically re-associated with the LAG. If the connection was originally associated with a different LAG, the virtual interfaces remain associated with the original LAG.</p> <p>For interconnects, any hosted connections are automatically re-associated with the LAG. If the interconnect was originally associated with a different LAG, the hosted connections remain associated with the original LAG.</p>
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var associateConnectionWithLag* = Call_AssociateConnectionWithLag_600049(
    name: "associateConnectionWithLag", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AssociateConnectionWithLag",
    validator: validate_AssociateConnectionWithLag_600050, base: "/",
    url: url_AssociateConnectionWithLag_600051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateHostedConnection_600064 = ref object of OpenApiRestCall_599368
proc url_AssociateHostedConnection_600066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateHostedConnection_600065(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "OvertureService.AssociateHostedConnection"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_AssociateHostedConnection_600064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a hosted connection and its virtual interfaces with a link aggregation group (LAG) or interconnect. If the target interconnect or LAG has an existing hosted connection with a conflicting VLAN number or IP address, the operation fails. This action temporarily interrupts the hosted connection's connectivity to AWS as it is being migrated.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_AssociateHostedConnection_600064; body: JsonNode): Recallable =
  ## associateHostedConnection
  ## <p>Associates a hosted connection and its virtual interfaces with a link aggregation group (LAG) or interconnect. If the target interconnect or LAG has an existing hosted connection with a conflicting VLAN number or IP address, the operation fails. This action temporarily interrupts the hosted connection's connectivity to AWS as it is being migrated.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var associateHostedConnection* = Call_AssociateHostedConnection_600064(
    name: "associateHostedConnection", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AssociateHostedConnection",
    validator: validate_AssociateHostedConnection_600065, base: "/",
    url: url_AssociateHostedConnection_600066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateVirtualInterface_600079 = ref object of OpenApiRestCall_599368
proc url_AssociateVirtualInterface_600081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateVirtualInterface_600080(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "OvertureService.AssociateVirtualInterface"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_AssociateVirtualInterface_600079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a virtual interface with a specified link aggregation group (LAG) or connection. Connectivity to AWS is temporarily interrupted as the virtual interface is being migrated. If the target connection or LAG has an associated virtual interface with a conflicting VLAN number or a conflicting IP address, the operation fails.</p> <p>Virtual interfaces associated with a hosted connection cannot be associated with a LAG; hosted connections must be migrated along with their virtual interfaces using <a>AssociateHostedConnection</a>.</p> <p>To reassociate a virtual interface to a new connection or LAG, the requester must own either the virtual interface itself or the connection to which the virtual interface is currently associated. Additionally, the requester must own the connection or LAG for the association.</p>
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_AssociateVirtualInterface_600079; body: JsonNode): Recallable =
  ## associateVirtualInterface
  ## <p>Associates a virtual interface with a specified link aggregation group (LAG) or connection. Connectivity to AWS is temporarily interrupted as the virtual interface is being migrated. If the target connection or LAG has an associated virtual interface with a conflicting VLAN number or a conflicting IP address, the operation fails.</p> <p>Virtual interfaces associated with a hosted connection cannot be associated with a LAG; hosted connections must be migrated along with their virtual interfaces using <a>AssociateHostedConnection</a>.</p> <p>To reassociate a virtual interface to a new connection or LAG, the requester must own either the virtual interface itself or the connection to which the virtual interface is currently associated. Additionally, the requester must own the connection or LAG for the association.</p>
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var associateVirtualInterface* = Call_AssociateVirtualInterface_600079(
    name: "associateVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.AssociateVirtualInterface",
    validator: validate_AssociateVirtualInterface_600080, base: "/",
    url: url_AssociateVirtualInterface_600081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmConnection_600094 = ref object of OpenApiRestCall_599368
proc url_ConfirmConnection_600096(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmConnection_600095(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600099 = header.getOrDefault("X-Amz-Target")
  valid_600099 = validateParameter(valid_600099, JString, required = true, default = newJString(
      "OvertureService.ConfirmConnection"))
  if valid_600099 != nil:
    section.add "X-Amz-Target", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_ConfirmConnection_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Confirms the creation of the specified hosted connection on an interconnect.</p> <p>Upon creation, the hosted connection is initially in the <code>Ordering</code> state, and remains in this state until the owner confirms creation of the hosted connection.</p>
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_ConfirmConnection_600094; body: JsonNode): Recallable =
  ## confirmConnection
  ## <p>Confirms the creation of the specified hosted connection on an interconnect.</p> <p>Upon creation, the hosted connection is initially in the <code>Ordering</code> state, and remains in this state until the owner confirms creation of the hosted connection.</p>
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var confirmConnection* = Call_ConfirmConnection_600094(name: "confirmConnection",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.ConfirmConnection",
    validator: validate_ConfirmConnection_600095, base: "/",
    url: url_ConfirmConnection_600096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmPrivateVirtualInterface_600109 = ref object of OpenApiRestCall_599368
proc url_ConfirmPrivateVirtualInterface_600111(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmPrivateVirtualInterface_600110(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600114 = header.getOrDefault("X-Amz-Target")
  valid_600114 = validateParameter(valid_600114, JString, required = true, default = newJString(
      "OvertureService.ConfirmPrivateVirtualInterface"))
  if valid_600114 != nil:
    section.add "X-Amz-Target", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_ConfirmPrivateVirtualInterface_600109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Accepts ownership of a private virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the virtual interface is created and attached to the specified virtual private gateway or Direct Connect gateway, and is made available to handle traffic.</p>
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_ConfirmPrivateVirtualInterface_600109; body: JsonNode): Recallable =
  ## confirmPrivateVirtualInterface
  ## <p>Accepts ownership of a private virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the virtual interface is created and attached to the specified virtual private gateway or Direct Connect gateway, and is made available to handle traffic.</p>
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var confirmPrivateVirtualInterface* = Call_ConfirmPrivateVirtualInterface_600109(
    name: "confirmPrivateVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.ConfirmPrivateVirtualInterface",
    validator: validate_ConfirmPrivateVirtualInterface_600110, base: "/",
    url: url_ConfirmPrivateVirtualInterface_600111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmPublicVirtualInterface_600124 = ref object of OpenApiRestCall_599368
proc url_ConfirmPublicVirtualInterface_600126(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmPublicVirtualInterface_600125(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600129 = header.getOrDefault("X-Amz-Target")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "OvertureService.ConfirmPublicVirtualInterface"))
  if valid_600129 != nil:
    section.add "X-Amz-Target", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_ConfirmPublicVirtualInterface_600124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Accepts ownership of a public virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the specified virtual interface is created and made available to handle traffic.</p>
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_ConfirmPublicVirtualInterface_600124; body: JsonNode): Recallable =
  ## confirmPublicVirtualInterface
  ## <p>Accepts ownership of a public virtual interface created by another AWS account.</p> <p>After the virtual interface owner makes this call, the specified virtual interface is created and made available to handle traffic.</p>
  ##   body: JObject (required)
  var body_600138 = newJObject()
  if body != nil:
    body_600138 = body
  result = call_600137.call(nil, nil, nil, nil, body_600138)

var confirmPublicVirtualInterface* = Call_ConfirmPublicVirtualInterface_600124(
    name: "confirmPublicVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.ConfirmPublicVirtualInterface",
    validator: validate_ConfirmPublicVirtualInterface_600125, base: "/",
    url: url_ConfirmPublicVirtualInterface_600126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConfirmTransitVirtualInterface_600139 = ref object of OpenApiRestCall_599368
proc url_ConfirmTransitVirtualInterface_600141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ConfirmTransitVirtualInterface_600140(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600144 = header.getOrDefault("X-Amz-Target")
  valid_600144 = validateParameter(valid_600144, JString, required = true, default = newJString(
      "OvertureService.ConfirmTransitVirtualInterface"))
  if valid_600144 != nil:
    section.add "X-Amz-Target", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_ConfirmTransitVirtualInterface_600139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Accepts ownership of a transit virtual interface created by another AWS account.</p> <p> After the owner of the transit virtual interface makes this call, the specified transit virtual interface is created and made available to handle traffic.</p>
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_ConfirmTransitVirtualInterface_600139; body: JsonNode): Recallable =
  ## confirmTransitVirtualInterface
  ## <p>Accepts ownership of a transit virtual interface created by another AWS account.</p> <p> After the owner of the transit virtual interface makes this call, the specified transit virtual interface is created and made available to handle traffic.</p>
  ##   body: JObject (required)
  var body_600153 = newJObject()
  if body != nil:
    body_600153 = body
  result = call_600152.call(nil, nil, nil, nil, body_600153)

var confirmTransitVirtualInterface* = Call_ConfirmTransitVirtualInterface_600139(
    name: "confirmTransitVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.ConfirmTransitVirtualInterface",
    validator: validate_ConfirmTransitVirtualInterface_600140, base: "/",
    url: url_ConfirmTransitVirtualInterface_600141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBGPPeer_600154 = ref object of OpenApiRestCall_599368
proc url_CreateBGPPeer_600156(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBGPPeer_600155(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600159 = header.getOrDefault("X-Amz-Target")
  valid_600159 = validateParameter(valid_600159, JString, required = true, default = newJString(
      "OvertureService.CreateBGPPeer"))
  if valid_600159 != nil:
    section.add "X-Amz-Target", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_CreateBGPPeer_600154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a BGP peer on the specified virtual interface.</p> <p>You must create a BGP peer for the corresponding address family (IPv4/IPv6) in order to access AWS resources that also use that address family.</p> <p>If logical redundancy is not supported by the connection, interconnect, or LAG, the BGP peer cannot be in the same address family as an existing BGP peer on the virtual interface.</p> <p>When creating a IPv6 BGP peer, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p> <p>For a public virtual interface, the Autonomous System Number (ASN) must be private or already whitelisted for the virtual interface.</p>
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_CreateBGPPeer_600154; body: JsonNode): Recallable =
  ## createBGPPeer
  ## <p>Creates a BGP peer on the specified virtual interface.</p> <p>You must create a BGP peer for the corresponding address family (IPv4/IPv6) in order to access AWS resources that also use that address family.</p> <p>If logical redundancy is not supported by the connection, interconnect, or LAG, the BGP peer cannot be in the same address family as an existing BGP peer on the virtual interface.</p> <p>When creating a IPv6 BGP peer, omit the Amazon address and customer address. IPv6 addresses are automatically assigned from the Amazon pool of IPv6 addresses; you cannot specify custom IPv6 addresses.</p> <p>For a public virtual interface, the Autonomous System Number (ASN) must be private or already whitelisted for the virtual interface.</p>
  ##   body: JObject (required)
  var body_600168 = newJObject()
  if body != nil:
    body_600168 = body
  result = call_600167.call(nil, nil, nil, nil, body_600168)

var createBGPPeer* = Call_CreateBGPPeer_600154(name: "createBGPPeer",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateBGPPeer",
    validator: validate_CreateBGPPeer_600155, base: "/", url: url_CreateBGPPeer_600156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_600169 = ref object of OpenApiRestCall_599368
proc url_CreateConnection_600171(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConnection_600170(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600172 = header.getOrDefault("X-Amz-Date")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Date", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Security-Token")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Security-Token", valid_600173
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600174 = header.getOrDefault("X-Amz-Target")
  valid_600174 = validateParameter(valid_600174, JString, required = true, default = newJString(
      "OvertureService.CreateConnection"))
  if valid_600174 != nil:
    section.add "X-Amz-Target", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Content-Sha256", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Algorithm")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Algorithm", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Signature")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Signature", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-SignedHeaders", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Credential")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Credential", valid_600179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600181: Call_CreateConnection_600169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a connection between a customer network and a specific AWS Direct Connect location.</p> <p>A connection links your internal network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end of the cable is connected to your router, the other to an AWS Direct Connect router.</p> <p>To find the locations for your Region, use <a>DescribeLocations</a>.</p> <p>You can automatically add the new connection to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new connection is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no connection is created.</p>
  ## 
  let valid = call_600181.validator(path, query, header, formData, body)
  let scheme = call_600181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600181.url(scheme.get, call_600181.host, call_600181.base,
                         call_600181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600181, url, valid)

proc call*(call_600182: Call_CreateConnection_600169; body: JsonNode): Recallable =
  ## createConnection
  ## <p>Creates a connection between a customer network and a specific AWS Direct Connect location.</p> <p>A connection links your internal network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end of the cable is connected to your router, the other to an AWS Direct Connect router.</p> <p>To find the locations for your Region, use <a>DescribeLocations</a>.</p> <p>You can automatically add the new connection to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new connection is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no connection is created.</p>
  ##   body: JObject (required)
  var body_600183 = newJObject()
  if body != nil:
    body_600183 = body
  result = call_600182.call(nil, nil, nil, nil, body_600183)

var createConnection* = Call_CreateConnection_600169(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateConnection",
    validator: validate_CreateConnection_600170, base: "/",
    url: url_CreateConnection_600171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectConnectGateway_600184 = ref object of OpenApiRestCall_599368
proc url_CreateDirectConnectGateway_600186(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectConnectGateway_600185(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600187 = header.getOrDefault("X-Amz-Date")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Date", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Security-Token")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Security-Token", valid_600188
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600189 = header.getOrDefault("X-Amz-Target")
  valid_600189 = validateParameter(valid_600189, JString, required = true, default = newJString(
      "OvertureService.CreateDirectConnectGateway"))
  if valid_600189 != nil:
    section.add "X-Amz-Target", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Content-Sha256", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Algorithm")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Algorithm", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Signature")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Signature", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-SignedHeaders", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Credential")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Credential", valid_600194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600196: Call_CreateDirectConnectGateway_600184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Direct Connect gateway, which is an intermediate object that enables you to connect a set of virtual interfaces and virtual private gateways. A Direct Connect gateway is global and visible in any AWS Region after it is created. The virtual interfaces and virtual private gateways that are connected through a Direct Connect gateway can be in different AWS Regions. This enables you to connect to a VPC in any Region, regardless of the Region in which the virtual interfaces are located, and pass traffic between them.
  ## 
  let valid = call_600196.validator(path, query, header, formData, body)
  let scheme = call_600196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600196.url(scheme.get, call_600196.host, call_600196.base,
                         call_600196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600196, url, valid)

proc call*(call_600197: Call_CreateDirectConnectGateway_600184; body: JsonNode): Recallable =
  ## createDirectConnectGateway
  ## Creates a Direct Connect gateway, which is an intermediate object that enables you to connect a set of virtual interfaces and virtual private gateways. A Direct Connect gateway is global and visible in any AWS Region after it is created. The virtual interfaces and virtual private gateways that are connected through a Direct Connect gateway can be in different AWS Regions. This enables you to connect to a VPC in any Region, regardless of the Region in which the virtual interfaces are located, and pass traffic between them.
  ##   body: JObject (required)
  var body_600198 = newJObject()
  if body != nil:
    body_600198 = body
  result = call_600197.call(nil, nil, nil, nil, body_600198)

var createDirectConnectGateway* = Call_CreateDirectConnectGateway_600184(
    name: "createDirectConnectGateway", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateDirectConnectGateway",
    validator: validate_CreateDirectConnectGateway_600185, base: "/",
    url: url_CreateDirectConnectGateway_600186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectConnectGatewayAssociation_600199 = ref object of OpenApiRestCall_599368
proc url_CreateDirectConnectGatewayAssociation_600201(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectConnectGatewayAssociation_600200(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600202 = header.getOrDefault("X-Amz-Date")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Date", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Security-Token")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Security-Token", valid_600203
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600204 = header.getOrDefault("X-Amz-Target")
  valid_600204 = validateParameter(valid_600204, JString, required = true, default = newJString(
      "OvertureService.CreateDirectConnectGatewayAssociation"))
  if valid_600204 != nil:
    section.add "X-Amz-Target", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Content-Sha256", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Algorithm")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Algorithm", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Signature")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Signature", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-SignedHeaders", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Credential")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Credential", valid_600209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600211: Call_CreateDirectConnectGatewayAssociation_600199;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates an association between a Direct Connect gateway and a virtual private gateway. The virtual private gateway must be attached to a VPC and must not be associated with another Direct Connect gateway.
  ## 
  let valid = call_600211.validator(path, query, header, formData, body)
  let scheme = call_600211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600211.url(scheme.get, call_600211.host, call_600211.base,
                         call_600211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600211, url, valid)

proc call*(call_600212: Call_CreateDirectConnectGatewayAssociation_600199;
          body: JsonNode): Recallable =
  ## createDirectConnectGatewayAssociation
  ## Creates an association between a Direct Connect gateway and a virtual private gateway. The virtual private gateway must be attached to a VPC and must not be associated with another Direct Connect gateway.
  ##   body: JObject (required)
  var body_600213 = newJObject()
  if body != nil:
    body_600213 = body
  result = call_600212.call(nil, nil, nil, nil, body_600213)

var createDirectConnectGatewayAssociation* = Call_CreateDirectConnectGatewayAssociation_600199(
    name: "createDirectConnectGatewayAssociation", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.CreateDirectConnectGatewayAssociation",
    validator: validate_CreateDirectConnectGatewayAssociation_600200, base: "/",
    url: url_CreateDirectConnectGatewayAssociation_600201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectConnectGatewayAssociationProposal_600214 = ref object of OpenApiRestCall_599368
proc url_CreateDirectConnectGatewayAssociationProposal_600216(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectConnectGatewayAssociationProposal_600215(
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600217 = header.getOrDefault("X-Amz-Date")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Date", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Security-Token")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Security-Token", valid_600218
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600219 = header.getOrDefault("X-Amz-Target")
  valid_600219 = validateParameter(valid_600219, JString, required = true, default = newJString(
      "OvertureService.CreateDirectConnectGatewayAssociationProposal"))
  if valid_600219 != nil:
    section.add "X-Amz-Target", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Content-Sha256", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Algorithm")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Algorithm", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Signature")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Signature", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-SignedHeaders", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Credential")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Credential", valid_600224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600226: Call_CreateDirectConnectGatewayAssociationProposal_600214;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a proposal to associate the specified virtual private gateway or transit gateway with the specified Direct Connect gateway.</p> <p>You can only associate a Direct Connect gateway and virtual private gateway or transit gateway when the account that owns the Direct Connect gateway and the account that owns the virtual private gateway or transit gateway have the same AWS Payer ID.</p>
  ## 
  let valid = call_600226.validator(path, query, header, formData, body)
  let scheme = call_600226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600226.url(scheme.get, call_600226.host, call_600226.base,
                         call_600226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600226, url, valid)

proc call*(call_600227: Call_CreateDirectConnectGatewayAssociationProposal_600214;
          body: JsonNode): Recallable =
  ## createDirectConnectGatewayAssociationProposal
  ## <p>Creates a proposal to associate the specified virtual private gateway or transit gateway with the specified Direct Connect gateway.</p> <p>You can only associate a Direct Connect gateway and virtual private gateway or transit gateway when the account that owns the Direct Connect gateway and the account that owns the virtual private gateway or transit gateway have the same AWS Payer ID.</p>
  ##   body: JObject (required)
  var body_600228 = newJObject()
  if body != nil:
    body_600228 = body
  result = call_600227.call(nil, nil, nil, nil, body_600228)

var createDirectConnectGatewayAssociationProposal* = Call_CreateDirectConnectGatewayAssociationProposal_600214(
    name: "createDirectConnectGatewayAssociationProposal",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.CreateDirectConnectGatewayAssociationProposal",
    validator: validate_CreateDirectConnectGatewayAssociationProposal_600215,
    base: "/", url: url_CreateDirectConnectGatewayAssociationProposal_600216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInterconnect_600229 = ref object of OpenApiRestCall_599368
proc url_CreateInterconnect_600231(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInterconnect_600230(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600232 = header.getOrDefault("X-Amz-Date")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Date", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Security-Token")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Security-Token", valid_600233
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600234 = header.getOrDefault("X-Amz-Target")
  valid_600234 = validateParameter(valid_600234, JString, required = true, default = newJString(
      "OvertureService.CreateInterconnect"))
  if valid_600234 != nil:
    section.add "X-Amz-Target", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Content-Sha256", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Algorithm")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Algorithm", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Signature")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Signature", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-SignedHeaders", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Credential")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Credential", valid_600239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600241: Call_CreateInterconnect_600229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an interconnect between an AWS Direct Connect Partner's network and a specific AWS Direct Connect location.</p> <p>An interconnect is a connection that is capable of hosting other connections. The AWS Direct Connect partner can use an interconnect to provide AWS Direct Connect hosted connections to customers through their own network services. Like a standard connection, an interconnect links the partner's network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end is connected to the partner's router, the other to an AWS Direct Connect router.</p> <p>You can automatically add the new interconnect to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new interconnect is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no interconnect is created.</p> <p>For each end customer, the AWS Direct Connect Partner provisions a connection on their interconnect by calling <a>AllocateHostedConnection</a>. The end customer can then connect to AWS resources by creating a virtual interface on their connection, using the VLAN assigned to them by the AWS Direct Connect Partner.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_600241.validator(path, query, header, formData, body)
  let scheme = call_600241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600241.url(scheme.get, call_600241.host, call_600241.base,
                         call_600241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600241, url, valid)

proc call*(call_600242: Call_CreateInterconnect_600229; body: JsonNode): Recallable =
  ## createInterconnect
  ## <p>Creates an interconnect between an AWS Direct Connect Partner's network and a specific AWS Direct Connect location.</p> <p>An interconnect is a connection that is capable of hosting other connections. The AWS Direct Connect partner can use an interconnect to provide AWS Direct Connect hosted connections to customers through their own network services. Like a standard connection, an interconnect links the partner's network to an AWS Direct Connect location over a standard Ethernet fiber-optic cable. One end is connected to the partner's router, the other to an AWS Direct Connect router.</p> <p>You can automatically add the new interconnect to a link aggregation group (LAG) by specifying a LAG ID in the request. This ensures that the new interconnect is allocated on the same AWS Direct Connect endpoint that hosts the specified LAG. If there are no available ports on the endpoint, the request fails and no interconnect is created.</p> <p>For each end customer, the AWS Direct Connect Partner provisions a connection on their interconnect by calling <a>AllocateHostedConnection</a>. The end customer can then connect to AWS resources by creating a virtual interface on their connection, using the VLAN assigned to them by the AWS Direct Connect Partner.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_600243 = newJObject()
  if body != nil:
    body_600243 = body
  result = call_600242.call(nil, nil, nil, nil, body_600243)

var createInterconnect* = Call_CreateInterconnect_600229(
    name: "createInterconnect", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateInterconnect",
    validator: validate_CreateInterconnect_600230, base: "/",
    url: url_CreateInterconnect_600231, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLag_600244 = ref object of OpenApiRestCall_599368
proc url_CreateLag_600246(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLag_600245(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600247 = header.getOrDefault("X-Amz-Date")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Date", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Security-Token")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Security-Token", valid_600248
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600249 = header.getOrDefault("X-Amz-Target")
  valid_600249 = validateParameter(valid_600249, JString, required = true, default = newJString(
      "OvertureService.CreateLag"))
  if valid_600249 != nil:
    section.add "X-Amz-Target", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Content-Sha256", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Algorithm")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Algorithm", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Signature")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Signature", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-SignedHeaders", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Credential")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Credential", valid_600254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600256: Call_CreateLag_600244; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a link aggregation group (LAG) with the specified number of bundled physical connections between the customer network and a specific AWS Direct Connect location. A LAG is a logical interface that uses the Link Aggregation Control Protocol (LACP) to aggregate multiple interfaces, enabling you to treat them as a single interface.</p> <p>All connections in a LAG must use the same bandwidth and must terminate at the same AWS Direct Connect endpoint.</p> <p>You can have up to 10 connections per LAG. Regardless of this limit, if you request more connections for the LAG than AWS Direct Connect can allocate on a single endpoint, no LAG is created.</p> <p>You can specify an existing physical connection or interconnect to include in the LAG (which counts towards the total number of connections). Doing so interrupts the current physical connection or hosted connections, and re-establishes them as a member of the LAG. The LAG will be created on the same AWS Direct Connect endpoint to which the connection terminates. Any virtual interfaces associated with the connection are automatically disassociated and re-associated with the LAG. The connection ID does not change.</p> <p>If the AWS account used to create a LAG is a registered AWS Direct Connect Partner, the LAG is automatically enabled to host sub-connections. For a LAG owned by a partner, any associated virtual interfaces cannot be directly configured.</p>
  ## 
  let valid = call_600256.validator(path, query, header, formData, body)
  let scheme = call_600256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600256.url(scheme.get, call_600256.host, call_600256.base,
                         call_600256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600256, url, valid)

proc call*(call_600257: Call_CreateLag_600244; body: JsonNode): Recallable =
  ## createLag
  ## <p>Creates a link aggregation group (LAG) with the specified number of bundled physical connections between the customer network and a specific AWS Direct Connect location. A LAG is a logical interface that uses the Link Aggregation Control Protocol (LACP) to aggregate multiple interfaces, enabling you to treat them as a single interface.</p> <p>All connections in a LAG must use the same bandwidth and must terminate at the same AWS Direct Connect endpoint.</p> <p>You can have up to 10 connections per LAG. Regardless of this limit, if you request more connections for the LAG than AWS Direct Connect can allocate on a single endpoint, no LAG is created.</p> <p>You can specify an existing physical connection or interconnect to include in the LAG (which counts towards the total number of connections). Doing so interrupts the current physical connection or hosted connections, and re-establishes them as a member of the LAG. The LAG will be created on the same AWS Direct Connect endpoint to which the connection terminates. Any virtual interfaces associated with the connection are automatically disassociated and re-associated with the LAG. The connection ID does not change.</p> <p>If the AWS account used to create a LAG is a registered AWS Direct Connect Partner, the LAG is automatically enabled to host sub-connections. For a LAG owned by a partner, any associated virtual interfaces cannot be directly configured.</p>
  ##   body: JObject (required)
  var body_600258 = newJObject()
  if body != nil:
    body_600258 = body
  result = call_600257.call(nil, nil, nil, nil, body_600258)

var createLag* = Call_CreateLag_600244(name: "createLag", meth: HttpMethod.HttpPost,
                                    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.CreateLag",
                                    validator: validate_CreateLag_600245,
                                    base: "/", url: url_CreateLag_600246,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePrivateVirtualInterface_600259 = ref object of OpenApiRestCall_599368
proc url_CreatePrivateVirtualInterface_600261(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePrivateVirtualInterface_600260(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600262 = header.getOrDefault("X-Amz-Date")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Date", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Security-Token")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Security-Token", valid_600263
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600264 = header.getOrDefault("X-Amz-Target")
  valid_600264 = validateParameter(valid_600264, JString, required = true, default = newJString(
      "OvertureService.CreatePrivateVirtualInterface"))
  if valid_600264 != nil:
    section.add "X-Amz-Target", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Content-Sha256", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Algorithm")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Algorithm", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Signature")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Signature", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-SignedHeaders", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Credential")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Credential", valid_600269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600271: Call_CreatePrivateVirtualInterface_600259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a private virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A private virtual interface can be connected to either a Direct Connect gateway or a Virtual Private Gateway (VGW). Connecting the private virtual interface to a Direct Connect gateway enables the possibility for connecting to multiple VPCs, including VPCs in different AWS Regions. Connecting the private virtual interface to a VGW only provides access to a single VPC within the same Region.
  ## 
  let valid = call_600271.validator(path, query, header, formData, body)
  let scheme = call_600271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600271.url(scheme.get, call_600271.host, call_600271.base,
                         call_600271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600271, url, valid)

proc call*(call_600272: Call_CreatePrivateVirtualInterface_600259; body: JsonNode): Recallable =
  ## createPrivateVirtualInterface
  ## Creates a private virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A private virtual interface can be connected to either a Direct Connect gateway or a Virtual Private Gateway (VGW). Connecting the private virtual interface to a Direct Connect gateway enables the possibility for connecting to multiple VPCs, including VPCs in different AWS Regions. Connecting the private virtual interface to a VGW only provides access to a single VPC within the same Region.
  ##   body: JObject (required)
  var body_600273 = newJObject()
  if body != nil:
    body_600273 = body
  result = call_600272.call(nil, nil, nil, nil, body_600273)

var createPrivateVirtualInterface* = Call_CreatePrivateVirtualInterface_600259(
    name: "createPrivateVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreatePrivateVirtualInterface",
    validator: validate_CreatePrivateVirtualInterface_600260, base: "/",
    url: url_CreatePrivateVirtualInterface_600261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicVirtualInterface_600274 = ref object of OpenApiRestCall_599368
proc url_CreatePublicVirtualInterface_600276(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePublicVirtualInterface_600275(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600277 = header.getOrDefault("X-Amz-Date")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Date", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Security-Token")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Security-Token", valid_600278
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600279 = header.getOrDefault("X-Amz-Target")
  valid_600279 = validateParameter(valid_600279, JString, required = true, default = newJString(
      "OvertureService.CreatePublicVirtualInterface"))
  if valid_600279 != nil:
    section.add "X-Amz-Target", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600286: Call_CreatePublicVirtualInterface_600274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a public virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A public virtual interface supports sending traffic to public services of AWS such as Amazon S3.</p> <p>When creating an IPv6 public virtual interface (<code>addressFamily</code> is <code>ipv6</code>), leave the <code>customer</code> and <code>amazon</code> address fields blank to use auto-assigned IPv6 space. Custom IPv6 addresses are not supported.</p>
  ## 
  let valid = call_600286.validator(path, query, header, formData, body)
  let scheme = call_600286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600286.url(scheme.get, call_600286.host, call_600286.base,
                         call_600286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600286, url, valid)

proc call*(call_600287: Call_CreatePublicVirtualInterface_600274; body: JsonNode): Recallable =
  ## createPublicVirtualInterface
  ## <p>Creates a public virtual interface. A virtual interface is the VLAN that transports AWS Direct Connect traffic. A public virtual interface supports sending traffic to public services of AWS such as Amazon S3.</p> <p>When creating an IPv6 public virtual interface (<code>addressFamily</code> is <code>ipv6</code>), leave the <code>customer</code> and <code>amazon</code> address fields blank to use auto-assigned IPv6 space. Custom IPv6 addresses are not supported.</p>
  ##   body: JObject (required)
  var body_600288 = newJObject()
  if body != nil:
    body_600288 = body
  result = call_600287.call(nil, nil, nil, nil, body_600288)

var createPublicVirtualInterface* = Call_CreatePublicVirtualInterface_600274(
    name: "createPublicVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreatePublicVirtualInterface",
    validator: validate_CreatePublicVirtualInterface_600275, base: "/",
    url: url_CreatePublicVirtualInterface_600276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransitVirtualInterface_600289 = ref object of OpenApiRestCall_599368
proc url_CreateTransitVirtualInterface_600291(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTransitVirtualInterface_600290(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600292 = header.getOrDefault("X-Amz-Date")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Date", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Security-Token")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Security-Token", valid_600293
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600294 = header.getOrDefault("X-Amz-Target")
  valid_600294 = validateParameter(valid_600294, JString, required = true, default = newJString(
      "OvertureService.CreateTransitVirtualInterface"))
  if valid_600294 != nil:
    section.add "X-Amz-Target", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Content-Sha256", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Algorithm")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Algorithm", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Signature")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Signature", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-SignedHeaders", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Credential")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Credential", valid_600299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600301: Call_CreateTransitVirtualInterface_600289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a transit virtual interface. A transit virtual interface should be used to access one or more transit gateways associated with Direct Connect gateways. A transit virtual interface enables the connection of multiple VPCs attached to a transit gateway to a Direct Connect gateway.</p> <important> <p>If you associate your transit gateway with one or more Direct Connect gateways, the Autonomous System Number (ASN) used by the transit gateway and the Direct Connect gateway must be different. For example, if you use the default ASN 64512 for both your the transit gateway and Direct Connect gateway, the association request fails.</p> </important>
  ## 
  let valid = call_600301.validator(path, query, header, formData, body)
  let scheme = call_600301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600301.url(scheme.get, call_600301.host, call_600301.base,
                         call_600301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600301, url, valid)

proc call*(call_600302: Call_CreateTransitVirtualInterface_600289; body: JsonNode): Recallable =
  ## createTransitVirtualInterface
  ## <p>Creates a transit virtual interface. A transit virtual interface should be used to access one or more transit gateways associated with Direct Connect gateways. A transit virtual interface enables the connection of multiple VPCs attached to a transit gateway to a Direct Connect gateway.</p> <important> <p>If you associate your transit gateway with one or more Direct Connect gateways, the Autonomous System Number (ASN) used by the transit gateway and the Direct Connect gateway must be different. For example, if you use the default ASN 64512 for both your the transit gateway and Direct Connect gateway, the association request fails.</p> </important>
  ##   body: JObject (required)
  var body_600303 = newJObject()
  if body != nil:
    body_600303 = body
  result = call_600302.call(nil, nil, nil, nil, body_600303)

var createTransitVirtualInterface* = Call_CreateTransitVirtualInterface_600289(
    name: "createTransitVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.CreateTransitVirtualInterface",
    validator: validate_CreateTransitVirtualInterface_600290, base: "/",
    url: url_CreateTransitVirtualInterface_600291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBGPPeer_600304 = ref object of OpenApiRestCall_599368
proc url_DeleteBGPPeer_600306(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBGPPeer_600305(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600307 = header.getOrDefault("X-Amz-Date")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Date", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Security-Token")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Security-Token", valid_600308
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600309 = header.getOrDefault("X-Amz-Target")
  valid_600309 = validateParameter(valid_600309, JString, required = true, default = newJString(
      "OvertureService.DeleteBGPPeer"))
  if valid_600309 != nil:
    section.add "X-Amz-Target", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Content-Sha256", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Algorithm")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Algorithm", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Signature")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Signature", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-SignedHeaders", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Credential")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Credential", valid_600314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600316: Call_DeleteBGPPeer_600304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified BGP peer on the specified virtual interface with the specified customer address and ASN.</p> <p>You cannot delete the last BGP peer from a virtual interface.</p>
  ## 
  let valid = call_600316.validator(path, query, header, formData, body)
  let scheme = call_600316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600316.url(scheme.get, call_600316.host, call_600316.base,
                         call_600316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600316, url, valid)

proc call*(call_600317: Call_DeleteBGPPeer_600304; body: JsonNode): Recallable =
  ## deleteBGPPeer
  ## <p>Deletes the specified BGP peer on the specified virtual interface with the specified customer address and ASN.</p> <p>You cannot delete the last BGP peer from a virtual interface.</p>
  ##   body: JObject (required)
  var body_600318 = newJObject()
  if body != nil:
    body_600318 = body
  result = call_600317.call(nil, nil, nil, nil, body_600318)

var deleteBGPPeer* = Call_DeleteBGPPeer_600304(name: "deleteBGPPeer",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteBGPPeer",
    validator: validate_DeleteBGPPeer_600305, base: "/", url: url_DeleteBGPPeer_600306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_600319 = ref object of OpenApiRestCall_599368
proc url_DeleteConnection_600321(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConnection_600320(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600322 = header.getOrDefault("X-Amz-Date")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Date", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Security-Token")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Security-Token", valid_600323
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600324 = header.getOrDefault("X-Amz-Target")
  valid_600324 = validateParameter(valid_600324, JString, required = true, default = newJString(
      "OvertureService.DeleteConnection"))
  if valid_600324 != nil:
    section.add "X-Amz-Target", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Content-Sha256", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Algorithm")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Algorithm", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Signature")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Signature", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-SignedHeaders", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Credential")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Credential", valid_600329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600331: Call_DeleteConnection_600319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified connection.</p> <p>Deleting a connection only stops the AWS Direct Connect port hour and data transfer charges. If you are partnering with any third parties to connect with the AWS Direct Connect location, you must cancel your service with them separately.</p>
  ## 
  let valid = call_600331.validator(path, query, header, formData, body)
  let scheme = call_600331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600331.url(scheme.get, call_600331.host, call_600331.base,
                         call_600331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600331, url, valid)

proc call*(call_600332: Call_DeleteConnection_600319; body: JsonNode): Recallable =
  ## deleteConnection
  ## <p>Deletes the specified connection.</p> <p>Deleting a connection only stops the AWS Direct Connect port hour and data transfer charges. If you are partnering with any third parties to connect with the AWS Direct Connect location, you must cancel your service with them separately.</p>
  ##   body: JObject (required)
  var body_600333 = newJObject()
  if body != nil:
    body_600333 = body
  result = call_600332.call(nil, nil, nil, nil, body_600333)

var deleteConnection* = Call_DeleteConnection_600319(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteConnection",
    validator: validate_DeleteConnection_600320, base: "/",
    url: url_DeleteConnection_600321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectConnectGateway_600334 = ref object of OpenApiRestCall_599368
proc url_DeleteDirectConnectGateway_600336(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectConnectGateway_600335(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600337 = header.getOrDefault("X-Amz-Date")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Date", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Security-Token")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Security-Token", valid_600338
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600339 = header.getOrDefault("X-Amz-Target")
  valid_600339 = validateParameter(valid_600339, JString, required = true, default = newJString(
      "OvertureService.DeleteDirectConnectGateway"))
  if valid_600339 != nil:
    section.add "X-Amz-Target", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Content-Sha256", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Algorithm")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Algorithm", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Signature")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Signature", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-SignedHeaders", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Credential")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Credential", valid_600344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600346: Call_DeleteDirectConnectGateway_600334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Direct Connect gateway. You must first delete all virtual interfaces that are attached to the Direct Connect gateway and disassociate all virtual private gateways associated with the Direct Connect gateway.
  ## 
  let valid = call_600346.validator(path, query, header, formData, body)
  let scheme = call_600346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600346.url(scheme.get, call_600346.host, call_600346.base,
                         call_600346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600346, url, valid)

proc call*(call_600347: Call_DeleteDirectConnectGateway_600334; body: JsonNode): Recallable =
  ## deleteDirectConnectGateway
  ## Deletes the specified Direct Connect gateway. You must first delete all virtual interfaces that are attached to the Direct Connect gateway and disassociate all virtual private gateways associated with the Direct Connect gateway.
  ##   body: JObject (required)
  var body_600348 = newJObject()
  if body != nil:
    body_600348 = body
  result = call_600347.call(nil, nil, nil, nil, body_600348)

var deleteDirectConnectGateway* = Call_DeleteDirectConnectGateway_600334(
    name: "deleteDirectConnectGateway", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteDirectConnectGateway",
    validator: validate_DeleteDirectConnectGateway_600335, base: "/",
    url: url_DeleteDirectConnectGateway_600336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectConnectGatewayAssociation_600349 = ref object of OpenApiRestCall_599368
proc url_DeleteDirectConnectGatewayAssociation_600351(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectConnectGatewayAssociation_600350(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600352 = header.getOrDefault("X-Amz-Date")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Date", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Security-Token")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Security-Token", valid_600353
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600354 = header.getOrDefault("X-Amz-Target")
  valid_600354 = validateParameter(valid_600354, JString, required = true, default = newJString(
      "OvertureService.DeleteDirectConnectGatewayAssociation"))
  if valid_600354 != nil:
    section.add "X-Amz-Target", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Content-Sha256", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Algorithm")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Algorithm", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Signature")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Signature", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-SignedHeaders", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Credential")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Credential", valid_600359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600361: Call_DeleteDirectConnectGatewayAssociation_600349;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the association between the specified Direct Connect gateway and virtual private gateway.</p> <p>We recommend that you specify the <code>associationID</code> to delete the association. Alternatively, if you own virtual gateway and a Direct Connect gateway association, you can specify the <code>virtualGatewayId</code> and <code>directConnectGatewayId</code> to delete an association.</p>
  ## 
  let valid = call_600361.validator(path, query, header, formData, body)
  let scheme = call_600361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600361.url(scheme.get, call_600361.host, call_600361.base,
                         call_600361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600361, url, valid)

proc call*(call_600362: Call_DeleteDirectConnectGatewayAssociation_600349;
          body: JsonNode): Recallable =
  ## deleteDirectConnectGatewayAssociation
  ## <p>Deletes the association between the specified Direct Connect gateway and virtual private gateway.</p> <p>We recommend that you specify the <code>associationID</code> to delete the association. Alternatively, if you own virtual gateway and a Direct Connect gateway association, you can specify the <code>virtualGatewayId</code> and <code>directConnectGatewayId</code> to delete an association.</p>
  ##   body: JObject (required)
  var body_600363 = newJObject()
  if body != nil:
    body_600363 = body
  result = call_600362.call(nil, nil, nil, nil, body_600363)

var deleteDirectConnectGatewayAssociation* = Call_DeleteDirectConnectGatewayAssociation_600349(
    name: "deleteDirectConnectGatewayAssociation", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DeleteDirectConnectGatewayAssociation",
    validator: validate_DeleteDirectConnectGatewayAssociation_600350, base: "/",
    url: url_DeleteDirectConnectGatewayAssociation_600351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectConnectGatewayAssociationProposal_600364 = ref object of OpenApiRestCall_599368
proc url_DeleteDirectConnectGatewayAssociationProposal_600366(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectConnectGatewayAssociationProposal_600365(
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600367 = header.getOrDefault("X-Amz-Date")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Date", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Security-Token")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Security-Token", valid_600368
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600369 = header.getOrDefault("X-Amz-Target")
  valid_600369 = validateParameter(valid_600369, JString, required = true, default = newJString(
      "OvertureService.DeleteDirectConnectGatewayAssociationProposal"))
  if valid_600369 != nil:
    section.add "X-Amz-Target", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Content-Sha256", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Algorithm")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Algorithm", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Signature")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Signature", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-SignedHeaders", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Credential")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Credential", valid_600374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600376: Call_DeleteDirectConnectGatewayAssociationProposal_600364;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the association proposal request between the specified Direct Connect gateway and virtual private gateway or transit gateway.
  ## 
  let valid = call_600376.validator(path, query, header, formData, body)
  let scheme = call_600376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600376.url(scheme.get, call_600376.host, call_600376.base,
                         call_600376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600376, url, valid)

proc call*(call_600377: Call_DeleteDirectConnectGatewayAssociationProposal_600364;
          body: JsonNode): Recallable =
  ## deleteDirectConnectGatewayAssociationProposal
  ## Deletes the association proposal request between the specified Direct Connect gateway and virtual private gateway or transit gateway.
  ##   body: JObject (required)
  var body_600378 = newJObject()
  if body != nil:
    body_600378 = body
  result = call_600377.call(nil, nil, nil, nil, body_600378)

var deleteDirectConnectGatewayAssociationProposal* = Call_DeleteDirectConnectGatewayAssociationProposal_600364(
    name: "deleteDirectConnectGatewayAssociationProposal",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DeleteDirectConnectGatewayAssociationProposal",
    validator: validate_DeleteDirectConnectGatewayAssociationProposal_600365,
    base: "/", url: url_DeleteDirectConnectGatewayAssociationProposal_600366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInterconnect_600379 = ref object of OpenApiRestCall_599368
proc url_DeleteInterconnect_600381(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInterconnect_600380(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600382 = header.getOrDefault("X-Amz-Date")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Date", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Security-Token")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Security-Token", valid_600383
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600384 = header.getOrDefault("X-Amz-Target")
  valid_600384 = validateParameter(valid_600384, JString, required = true, default = newJString(
      "OvertureService.DeleteInterconnect"))
  if valid_600384 != nil:
    section.add "X-Amz-Target", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Content-Sha256", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Algorithm")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Algorithm", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Signature")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Signature", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-SignedHeaders", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Credential")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Credential", valid_600389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600391: Call_DeleteInterconnect_600379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_600391.validator(path, query, header, formData, body)
  let scheme = call_600391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600391.url(scheme.get, call_600391.host, call_600391.base,
                         call_600391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600391, url, valid)

proc call*(call_600392: Call_DeleteInterconnect_600379; body: JsonNode): Recallable =
  ## deleteInterconnect
  ## <p>Deletes the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_600393 = newJObject()
  if body != nil:
    body_600393 = body
  result = call_600392.call(nil, nil, nil, nil, body_600393)

var deleteInterconnect* = Call_DeleteInterconnect_600379(
    name: "deleteInterconnect", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteInterconnect",
    validator: validate_DeleteInterconnect_600380, base: "/",
    url: url_DeleteInterconnect_600381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLag_600394 = ref object of OpenApiRestCall_599368
proc url_DeleteLag_600396(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLag_600395(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600397 = header.getOrDefault("X-Amz-Date")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Date", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Security-Token")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Security-Token", valid_600398
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600399 = header.getOrDefault("X-Amz-Target")
  valid_600399 = validateParameter(valid_600399, JString, required = true, default = newJString(
      "OvertureService.DeleteLag"))
  if valid_600399 != nil:
    section.add "X-Amz-Target", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Content-Sha256", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Algorithm")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Algorithm", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Signature")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Signature", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-SignedHeaders", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Credential")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Credential", valid_600404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600406: Call_DeleteLag_600394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified link aggregation group (LAG). You cannot delete a LAG if it has active virtual interfaces or hosted connections.
  ## 
  let valid = call_600406.validator(path, query, header, formData, body)
  let scheme = call_600406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600406.url(scheme.get, call_600406.host, call_600406.base,
                         call_600406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600406, url, valid)

proc call*(call_600407: Call_DeleteLag_600394; body: JsonNode): Recallable =
  ## deleteLag
  ## Deletes the specified link aggregation group (LAG). You cannot delete a LAG if it has active virtual interfaces or hosted connections.
  ##   body: JObject (required)
  var body_600408 = newJObject()
  if body != nil:
    body_600408 = body
  result = call_600407.call(nil, nil, nil, nil, body_600408)

var deleteLag* = Call_DeleteLag_600394(name: "deleteLag", meth: HttpMethod.HttpPost,
                                    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DeleteLag",
                                    validator: validate_DeleteLag_600395,
                                    base: "/", url: url_DeleteLag_600396,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVirtualInterface_600409 = ref object of OpenApiRestCall_599368
proc url_DeleteVirtualInterface_600411(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteVirtualInterface_600410(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600412 = header.getOrDefault("X-Amz-Date")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Date", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-Security-Token")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Security-Token", valid_600413
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600414 = header.getOrDefault("X-Amz-Target")
  valid_600414 = validateParameter(valid_600414, JString, required = true, default = newJString(
      "OvertureService.DeleteVirtualInterface"))
  if valid_600414 != nil:
    section.add "X-Amz-Target", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Content-Sha256", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Algorithm")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Algorithm", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Signature")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Signature", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-SignedHeaders", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Credential")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Credential", valid_600419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600421: Call_DeleteVirtualInterface_600409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a virtual interface.
  ## 
  let valid = call_600421.validator(path, query, header, formData, body)
  let scheme = call_600421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600421.url(scheme.get, call_600421.host, call_600421.base,
                         call_600421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600421, url, valid)

proc call*(call_600422: Call_DeleteVirtualInterface_600409; body: JsonNode): Recallable =
  ## deleteVirtualInterface
  ## Deletes a virtual interface.
  ##   body: JObject (required)
  var body_600423 = newJObject()
  if body != nil:
    body_600423 = body
  result = call_600422.call(nil, nil, nil, nil, body_600423)

var deleteVirtualInterface* = Call_DeleteVirtualInterface_600409(
    name: "deleteVirtualInterface", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DeleteVirtualInterface",
    validator: validate_DeleteVirtualInterface_600410, base: "/",
    url: url_DeleteVirtualInterface_600411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnectionLoa_600424 = ref object of OpenApiRestCall_599368
proc url_DescribeConnectionLoa_600426(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConnectionLoa_600425(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600427 = header.getOrDefault("X-Amz-Date")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "X-Amz-Date", valid_600427
  var valid_600428 = header.getOrDefault("X-Amz-Security-Token")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Security-Token", valid_600428
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600429 = header.getOrDefault("X-Amz-Target")
  valid_600429 = validateParameter(valid_600429, JString, required = true, default = newJString(
      "OvertureService.DescribeConnectionLoa"))
  if valid_600429 != nil:
    section.add "X-Amz-Target", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Content-Sha256", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Algorithm")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Algorithm", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Signature")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Signature", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-SignedHeaders", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Credential")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Credential", valid_600434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600436: Call_DescribeConnectionLoa_600424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for a connection.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that your APN partner or service provider uses when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ## 
  let valid = call_600436.validator(path, query, header, formData, body)
  let scheme = call_600436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600436.url(scheme.get, call_600436.host, call_600436.base,
                         call_600436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600436, url, valid)

proc call*(call_600437: Call_DescribeConnectionLoa_600424; body: JsonNode): Recallable =
  ## describeConnectionLoa
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for a connection.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that your APN partner or service provider uses when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ##   body: JObject (required)
  var body_600438 = newJObject()
  if body != nil:
    body_600438 = body
  result = call_600437.call(nil, nil, nil, nil, body_600438)

var describeConnectionLoa* = Call_DescribeConnectionLoa_600424(
    name: "describeConnectionLoa", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeConnectionLoa",
    validator: validate_DescribeConnectionLoa_600425, base: "/",
    url: url_DescribeConnectionLoa_600426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnections_600439 = ref object of OpenApiRestCall_599368
proc url_DescribeConnections_600441(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConnections_600440(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600442 = header.getOrDefault("X-Amz-Date")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-Date", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-Security-Token")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Security-Token", valid_600443
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600444 = header.getOrDefault("X-Amz-Target")
  valid_600444 = validateParameter(valid_600444, JString, required = true, default = newJString(
      "OvertureService.DescribeConnections"))
  if valid_600444 != nil:
    section.add "X-Amz-Target", valid_600444
  var valid_600445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "X-Amz-Content-Sha256", valid_600445
  var valid_600446 = header.getOrDefault("X-Amz-Algorithm")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Algorithm", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Signature")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Signature", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-SignedHeaders", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Credential")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Credential", valid_600449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600451: Call_DescribeConnections_600439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the specified connection or all connections in this Region.
  ## 
  let valid = call_600451.validator(path, query, header, formData, body)
  let scheme = call_600451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600451.url(scheme.get, call_600451.host, call_600451.base,
                         call_600451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600451, url, valid)

proc call*(call_600452: Call_DescribeConnections_600439; body: JsonNode): Recallable =
  ## describeConnections
  ## Displays the specified connection or all connections in this Region.
  ##   body: JObject (required)
  var body_600453 = newJObject()
  if body != nil:
    body_600453 = body
  result = call_600452.call(nil, nil, nil, nil, body_600453)

var describeConnections* = Call_DescribeConnections_600439(
    name: "describeConnections", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeConnections",
    validator: validate_DescribeConnections_600440, base: "/",
    url: url_DescribeConnections_600441, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnectionsOnInterconnect_600454 = ref object of OpenApiRestCall_599368
proc url_DescribeConnectionsOnInterconnect_600456(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConnectionsOnInterconnect_600455(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600457 = header.getOrDefault("X-Amz-Date")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Date", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Security-Token")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Security-Token", valid_600458
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600459 = header.getOrDefault("X-Amz-Target")
  valid_600459 = validateParameter(valid_600459, JString, required = true, default = newJString(
      "OvertureService.DescribeConnectionsOnInterconnect"))
  if valid_600459 != nil:
    section.add "X-Amz-Target", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Content-Sha256", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Algorithm")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Algorithm", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Signature")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Signature", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-SignedHeaders", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-Credential")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Credential", valid_600464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600466: Call_DescribeConnectionsOnInterconnect_600454;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deprecated. Use <a>DescribeHostedConnections</a> instead.</p> <p>Lists the connections that have been provisioned on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_600466.validator(path, query, header, formData, body)
  let scheme = call_600466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600466.url(scheme.get, call_600466.host, call_600466.base,
                         call_600466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600466, url, valid)

proc call*(call_600467: Call_DescribeConnectionsOnInterconnect_600454;
          body: JsonNode): Recallable =
  ## describeConnectionsOnInterconnect
  ## <p>Deprecated. Use <a>DescribeHostedConnections</a> instead.</p> <p>Lists the connections that have been provisioned on the specified interconnect.</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_600468 = newJObject()
  if body != nil:
    body_600468 = body
  result = call_600467.call(nil, nil, nil, nil, body_600468)

var describeConnectionsOnInterconnect* = Call_DescribeConnectionsOnInterconnect_600454(
    name: "describeConnectionsOnInterconnect", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeConnectionsOnInterconnect",
    validator: validate_DescribeConnectionsOnInterconnect_600455, base: "/",
    url: url_DescribeConnectionsOnInterconnect_600456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectConnectGatewayAssociationProposals_600469 = ref object of OpenApiRestCall_599368
proc url_DescribeDirectConnectGatewayAssociationProposals_600471(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectConnectGatewayAssociationProposals_600470(
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600472 = header.getOrDefault("X-Amz-Date")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-Date", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Security-Token")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Security-Token", valid_600473
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600474 = header.getOrDefault("X-Amz-Target")
  valid_600474 = validateParameter(valid_600474, JString, required = true, default = newJString(
      "OvertureService.DescribeDirectConnectGatewayAssociationProposals"))
  if valid_600474 != nil:
    section.add "X-Amz-Target", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Content-Sha256", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-Algorithm")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Algorithm", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Signature")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Signature", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-SignedHeaders", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Credential")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Credential", valid_600479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600481: Call_DescribeDirectConnectGatewayAssociationProposals_600469;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes one or more association proposals for connection between a virtual private gateway or transit gateway and a Direct Connect gateway. 
  ## 
  let valid = call_600481.validator(path, query, header, formData, body)
  let scheme = call_600481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600481.url(scheme.get, call_600481.host, call_600481.base,
                         call_600481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600481, url, valid)

proc call*(call_600482: Call_DescribeDirectConnectGatewayAssociationProposals_600469;
          body: JsonNode): Recallable =
  ## describeDirectConnectGatewayAssociationProposals
  ## Describes one or more association proposals for connection between a virtual private gateway or transit gateway and a Direct Connect gateway. 
  ##   body: JObject (required)
  var body_600483 = newJObject()
  if body != nil:
    body_600483 = body
  result = call_600482.call(nil, nil, nil, nil, body_600483)

var describeDirectConnectGatewayAssociationProposals* = Call_DescribeDirectConnectGatewayAssociationProposals_600469(
    name: "describeDirectConnectGatewayAssociationProposals",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DescribeDirectConnectGatewayAssociationProposals",
    validator: validate_DescribeDirectConnectGatewayAssociationProposals_600470,
    base: "/", url: url_DescribeDirectConnectGatewayAssociationProposals_600471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectConnectGatewayAssociations_600484 = ref object of OpenApiRestCall_599368
proc url_DescribeDirectConnectGatewayAssociations_600486(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectConnectGatewayAssociations_600485(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600487 = header.getOrDefault("X-Amz-Date")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Date", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Security-Token")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Security-Token", valid_600488
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600489 = header.getOrDefault("X-Amz-Target")
  valid_600489 = validateParameter(valid_600489, JString, required = true, default = newJString(
      "OvertureService.DescribeDirectConnectGatewayAssociations"))
  if valid_600489 != nil:
    section.add "X-Amz-Target", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Content-Sha256", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Algorithm")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Algorithm", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Signature")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Signature", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-SignedHeaders", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-Credential")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Credential", valid_600494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600496: Call_DescribeDirectConnectGatewayAssociations_600484;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the associations between your Direct Connect gateways and virtual private gateways. You must specify a Direct Connect gateway, a virtual private gateway, or both. If you specify a Direct Connect gateway, the response contains all virtual private gateways associated with the Direct Connect gateway. If you specify a virtual private gateway, the response contains all Direct Connect gateways associated with the virtual private gateway. If you specify both, the response contains the association between the Direct Connect gateway and the virtual private gateway.
  ## 
  let valid = call_600496.validator(path, query, header, formData, body)
  let scheme = call_600496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600496.url(scheme.get, call_600496.host, call_600496.base,
                         call_600496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600496, url, valid)

proc call*(call_600497: Call_DescribeDirectConnectGatewayAssociations_600484;
          body: JsonNode): Recallable =
  ## describeDirectConnectGatewayAssociations
  ## Lists the associations between your Direct Connect gateways and virtual private gateways. You must specify a Direct Connect gateway, a virtual private gateway, or both. If you specify a Direct Connect gateway, the response contains all virtual private gateways associated with the Direct Connect gateway. If you specify a virtual private gateway, the response contains all Direct Connect gateways associated with the virtual private gateway. If you specify both, the response contains the association between the Direct Connect gateway and the virtual private gateway.
  ##   body: JObject (required)
  var body_600498 = newJObject()
  if body != nil:
    body_600498 = body
  result = call_600497.call(nil, nil, nil, nil, body_600498)

var describeDirectConnectGatewayAssociations* = Call_DescribeDirectConnectGatewayAssociations_600484(
    name: "describeDirectConnectGatewayAssociations", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DescribeDirectConnectGatewayAssociations",
    validator: validate_DescribeDirectConnectGatewayAssociations_600485,
    base: "/", url: url_DescribeDirectConnectGatewayAssociations_600486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectConnectGatewayAttachments_600499 = ref object of OpenApiRestCall_599368
proc url_DescribeDirectConnectGatewayAttachments_600501(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectConnectGatewayAttachments_600500(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600502 = header.getOrDefault("X-Amz-Date")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Date", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Security-Token")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Security-Token", valid_600503
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600504 = header.getOrDefault("X-Amz-Target")
  valid_600504 = validateParameter(valid_600504, JString, required = true, default = newJString(
      "OvertureService.DescribeDirectConnectGatewayAttachments"))
  if valid_600504 != nil:
    section.add "X-Amz-Target", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Content-Sha256", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Algorithm")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Algorithm", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Signature")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Signature", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-SignedHeaders", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-Credential")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-Credential", valid_600509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600511: Call_DescribeDirectConnectGatewayAttachments_600499;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the attachments between your Direct Connect gateways and virtual interfaces. You must specify a Direct Connect gateway, a virtual interface, or both. If you specify a Direct Connect gateway, the response contains all virtual interfaces attached to the Direct Connect gateway. If you specify a virtual interface, the response contains all Direct Connect gateways attached to the virtual interface. If you specify both, the response contains the attachment between the Direct Connect gateway and the virtual interface.
  ## 
  let valid = call_600511.validator(path, query, header, formData, body)
  let scheme = call_600511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600511.url(scheme.get, call_600511.host, call_600511.base,
                         call_600511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600511, url, valid)

proc call*(call_600512: Call_DescribeDirectConnectGatewayAttachments_600499;
          body: JsonNode): Recallable =
  ## describeDirectConnectGatewayAttachments
  ## Lists the attachments between your Direct Connect gateways and virtual interfaces. You must specify a Direct Connect gateway, a virtual interface, or both. If you specify a Direct Connect gateway, the response contains all virtual interfaces attached to the Direct Connect gateway. If you specify a virtual interface, the response contains all Direct Connect gateways attached to the virtual interface. If you specify both, the response contains the attachment between the Direct Connect gateway and the virtual interface.
  ##   body: JObject (required)
  var body_600513 = newJObject()
  if body != nil:
    body_600513 = body
  result = call_600512.call(nil, nil, nil, nil, body_600513)

var describeDirectConnectGatewayAttachments* = Call_DescribeDirectConnectGatewayAttachments_600499(
    name: "describeDirectConnectGatewayAttachments", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DescribeDirectConnectGatewayAttachments",
    validator: validate_DescribeDirectConnectGatewayAttachments_600500, base: "/",
    url: url_DescribeDirectConnectGatewayAttachments_600501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectConnectGateways_600514 = ref object of OpenApiRestCall_599368
proc url_DescribeDirectConnectGateways_600516(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDirectConnectGateways_600515(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600517 = header.getOrDefault("X-Amz-Date")
  valid_600517 = validateParameter(valid_600517, JString, required = false,
                                 default = nil)
  if valid_600517 != nil:
    section.add "X-Amz-Date", valid_600517
  var valid_600518 = header.getOrDefault("X-Amz-Security-Token")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-Security-Token", valid_600518
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600519 = header.getOrDefault("X-Amz-Target")
  valid_600519 = validateParameter(valid_600519, JString, required = true, default = newJString(
      "OvertureService.DescribeDirectConnectGateways"))
  if valid_600519 != nil:
    section.add "X-Amz-Target", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Content-Sha256", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Algorithm")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Algorithm", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Signature")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Signature", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-SignedHeaders", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-Credential")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Credential", valid_600524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600526: Call_DescribeDirectConnectGateways_600514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all your Direct Connect gateways or only the specified Direct Connect gateway. Deleted Direct Connect gateways are not returned.
  ## 
  let valid = call_600526.validator(path, query, header, formData, body)
  let scheme = call_600526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600526.url(scheme.get, call_600526.host, call_600526.base,
                         call_600526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600526, url, valid)

proc call*(call_600527: Call_DescribeDirectConnectGateways_600514; body: JsonNode): Recallable =
  ## describeDirectConnectGateways
  ## Lists all your Direct Connect gateways or only the specified Direct Connect gateway. Deleted Direct Connect gateways are not returned.
  ##   body: JObject (required)
  var body_600528 = newJObject()
  if body != nil:
    body_600528 = body
  result = call_600527.call(nil, nil, nil, nil, body_600528)

var describeDirectConnectGateways* = Call_DescribeDirectConnectGateways_600514(
    name: "describeDirectConnectGateways", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeDirectConnectGateways",
    validator: validate_DescribeDirectConnectGateways_600515, base: "/",
    url: url_DescribeDirectConnectGateways_600516,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHostedConnections_600529 = ref object of OpenApiRestCall_599368
proc url_DescribeHostedConnections_600531(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHostedConnections_600530(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600532 = header.getOrDefault("X-Amz-Date")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-Date", valid_600532
  var valid_600533 = header.getOrDefault("X-Amz-Security-Token")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-Security-Token", valid_600533
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600534 = header.getOrDefault("X-Amz-Target")
  valid_600534 = validateParameter(valid_600534, JString, required = true, default = newJString(
      "OvertureService.DescribeHostedConnections"))
  if valid_600534 != nil:
    section.add "X-Amz-Target", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Content-Sha256", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-Algorithm")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Algorithm", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-Signature")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Signature", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-SignedHeaders", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-Credential")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Credential", valid_600539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600541: Call_DescribeHostedConnections_600529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the hosted connections that have been provisioned on the specified interconnect or link aggregation group (LAG).</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ## 
  let valid = call_600541.validator(path, query, header, formData, body)
  let scheme = call_600541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600541.url(scheme.get, call_600541.host, call_600541.base,
                         call_600541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600541, url, valid)

proc call*(call_600542: Call_DescribeHostedConnections_600529; body: JsonNode): Recallable =
  ## describeHostedConnections
  ## <p>Lists the hosted connections that have been provisioned on the specified interconnect or link aggregation group (LAG).</p> <note> <p>Intended for use by AWS Direct Connect Partners only.</p> </note>
  ##   body: JObject (required)
  var body_600543 = newJObject()
  if body != nil:
    body_600543 = body
  result = call_600542.call(nil, nil, nil, nil, body_600543)

var describeHostedConnections* = Call_DescribeHostedConnections_600529(
    name: "describeHostedConnections", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeHostedConnections",
    validator: validate_DescribeHostedConnections_600530, base: "/",
    url: url_DescribeHostedConnections_600531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInterconnectLoa_600544 = ref object of OpenApiRestCall_599368
proc url_DescribeInterconnectLoa_600546(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInterconnectLoa_600545(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600547 = header.getOrDefault("X-Amz-Date")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "X-Amz-Date", valid_600547
  var valid_600548 = header.getOrDefault("X-Amz-Security-Token")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Security-Token", valid_600548
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600549 = header.getOrDefault("X-Amz-Target")
  valid_600549 = validateParameter(valid_600549, JString, required = true, default = newJString(
      "OvertureService.DescribeInterconnectLoa"))
  if valid_600549 != nil:
    section.add "X-Amz-Target", valid_600549
  var valid_600550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600550 = validateParameter(valid_600550, JString, required = false,
                                 default = nil)
  if valid_600550 != nil:
    section.add "X-Amz-Content-Sha256", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-Algorithm")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-Algorithm", valid_600551
  var valid_600552 = header.getOrDefault("X-Amz-Signature")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Signature", valid_600552
  var valid_600553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-SignedHeaders", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-Credential")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Credential", valid_600554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600556: Call_DescribeInterconnectLoa_600544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for the specified interconnect.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ## 
  let valid = call_600556.validator(path, query, header, formData, body)
  let scheme = call_600556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600556.url(scheme.get, call_600556.host, call_600556.base,
                         call_600556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600556, url, valid)

proc call*(call_600557: Call_DescribeInterconnectLoa_600544; body: JsonNode): Recallable =
  ## describeInterconnectLoa
  ## <p>Deprecated. Use <a>DescribeLoa</a> instead.</p> <p>Gets the LOA-CFA for the specified interconnect.</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ##   body: JObject (required)
  var body_600558 = newJObject()
  if body != nil:
    body_600558 = body
  result = call_600557.call(nil, nil, nil, nil, body_600558)

var describeInterconnectLoa* = Call_DescribeInterconnectLoa_600544(
    name: "describeInterconnectLoa", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeInterconnectLoa",
    validator: validate_DescribeInterconnectLoa_600545, base: "/",
    url: url_DescribeInterconnectLoa_600546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInterconnects_600559 = ref object of OpenApiRestCall_599368
proc url_DescribeInterconnects_600561(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInterconnects_600560(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600562 = header.getOrDefault("X-Amz-Date")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-Date", valid_600562
  var valid_600563 = header.getOrDefault("X-Amz-Security-Token")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-Security-Token", valid_600563
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600564 = header.getOrDefault("X-Amz-Target")
  valid_600564 = validateParameter(valid_600564, JString, required = true, default = newJString(
      "OvertureService.DescribeInterconnects"))
  if valid_600564 != nil:
    section.add "X-Amz-Target", valid_600564
  var valid_600565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "X-Amz-Content-Sha256", valid_600565
  var valid_600566 = header.getOrDefault("X-Amz-Algorithm")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-Algorithm", valid_600566
  var valid_600567 = header.getOrDefault("X-Amz-Signature")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Signature", valid_600567
  var valid_600568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "X-Amz-SignedHeaders", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-Credential")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-Credential", valid_600569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600571: Call_DescribeInterconnects_600559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the interconnects owned by the AWS account or only the specified interconnect.
  ## 
  let valid = call_600571.validator(path, query, header, formData, body)
  let scheme = call_600571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600571.url(scheme.get, call_600571.host, call_600571.base,
                         call_600571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600571, url, valid)

proc call*(call_600572: Call_DescribeInterconnects_600559; body: JsonNode): Recallable =
  ## describeInterconnects
  ## Lists the interconnects owned by the AWS account or only the specified interconnect.
  ##   body: JObject (required)
  var body_600573 = newJObject()
  if body != nil:
    body_600573 = body
  result = call_600572.call(nil, nil, nil, nil, body_600573)

var describeInterconnects* = Call_DescribeInterconnects_600559(
    name: "describeInterconnects", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeInterconnects",
    validator: validate_DescribeInterconnects_600560, base: "/",
    url: url_DescribeInterconnects_600561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLags_600574 = ref object of OpenApiRestCall_599368
proc url_DescribeLags_600576(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLags_600575(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600577 = header.getOrDefault("X-Amz-Date")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-Date", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-Security-Token")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Security-Token", valid_600578
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600579 = header.getOrDefault("X-Amz-Target")
  valid_600579 = validateParameter(valid_600579, JString, required = true, default = newJString(
      "OvertureService.DescribeLags"))
  if valid_600579 != nil:
    section.add "X-Amz-Target", valid_600579
  var valid_600580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "X-Amz-Content-Sha256", valid_600580
  var valid_600581 = header.getOrDefault("X-Amz-Algorithm")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "X-Amz-Algorithm", valid_600581
  var valid_600582 = header.getOrDefault("X-Amz-Signature")
  valid_600582 = validateParameter(valid_600582, JString, required = false,
                                 default = nil)
  if valid_600582 != nil:
    section.add "X-Amz-Signature", valid_600582
  var valid_600583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-SignedHeaders", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-Credential")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Credential", valid_600584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600586: Call_DescribeLags_600574; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes all your link aggregation groups (LAG) or the specified LAG.
  ## 
  let valid = call_600586.validator(path, query, header, formData, body)
  let scheme = call_600586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600586.url(scheme.get, call_600586.host, call_600586.base,
                         call_600586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600586, url, valid)

proc call*(call_600587: Call_DescribeLags_600574; body: JsonNode): Recallable =
  ## describeLags
  ## Describes all your link aggregation groups (LAG) or the specified LAG.
  ##   body: JObject (required)
  var body_600588 = newJObject()
  if body != nil:
    body_600588 = body
  result = call_600587.call(nil, nil, nil, nil, body_600588)

var describeLags* = Call_DescribeLags_600574(name: "describeLags",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeLags",
    validator: validate_DescribeLags_600575, base: "/", url: url_DescribeLags_600576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLoa_600589 = ref object of OpenApiRestCall_599368
proc url_DescribeLoa_600591(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLoa_600590(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600592 = header.getOrDefault("X-Amz-Date")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Date", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Security-Token")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Security-Token", valid_600593
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600594 = header.getOrDefault("X-Amz-Target")
  valid_600594 = validateParameter(valid_600594, JString, required = true, default = newJString(
      "OvertureService.DescribeLoa"))
  if valid_600594 != nil:
    section.add "X-Amz-Target", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Content-Sha256", valid_600595
  var valid_600596 = header.getOrDefault("X-Amz-Algorithm")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-Algorithm", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Signature")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Signature", valid_600597
  var valid_600598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-SignedHeaders", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Credential")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Credential", valid_600599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600601: Call_DescribeLoa_600589; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the LOA-CFA for a connection, interconnect, or link aggregation group (LAG).</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ## 
  let valid = call_600601.validator(path, query, header, formData, body)
  let scheme = call_600601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600601.url(scheme.get, call_600601.host, call_600601.base,
                         call_600601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600601, url, valid)

proc call*(call_600602: Call_DescribeLoa_600589; body: JsonNode): Recallable =
  ## describeLoa
  ## <p>Gets the LOA-CFA for a connection, interconnect, or link aggregation group (LAG).</p> <p>The Letter of Authorization - Connecting Facility Assignment (LOA-CFA) is a document that is used when establishing your cross connect to AWS at the colocation facility. For more information, see <a href="https://docs.aws.amazon.com/directconnect/latest/UserGuide/Colocation.html">Requesting Cross Connects at AWS Direct Connect Locations</a> in the <i>AWS Direct Connect User Guide</i>.</p>
  ##   body: JObject (required)
  var body_600603 = newJObject()
  if body != nil:
    body_600603 = body
  result = call_600602.call(nil, nil, nil, nil, body_600603)

var describeLoa* = Call_DescribeLoa_600589(name: "describeLoa",
                                        meth: HttpMethod.HttpPost,
                                        host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.DescribeLoa",
                                        validator: validate_DescribeLoa_600590,
                                        base: "/", url: url_DescribeLoa_600591,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocations_600604 = ref object of OpenApiRestCall_599368
proc url_DescribeLocations_600606(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLocations_600605(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600607 = header.getOrDefault("X-Amz-Date")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Date", valid_600607
  var valid_600608 = header.getOrDefault("X-Amz-Security-Token")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Security-Token", valid_600608
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600609 = header.getOrDefault("X-Amz-Target")
  valid_600609 = validateParameter(valid_600609, JString, required = true, default = newJString(
      "OvertureService.DescribeLocations"))
  if valid_600609 != nil:
    section.add "X-Amz-Target", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Content-Sha256", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-Algorithm")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Algorithm", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Signature")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Signature", valid_600612
  var valid_600613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "X-Amz-SignedHeaders", valid_600613
  var valid_600614 = header.getOrDefault("X-Amz-Credential")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-Credential", valid_600614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600615: Call_DescribeLocations_600604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS Direct Connect locations in the current AWS Region. These are the locations that can be selected when calling <a>CreateConnection</a> or <a>CreateInterconnect</a>.
  ## 
  let valid = call_600615.validator(path, query, header, formData, body)
  let scheme = call_600615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600615.url(scheme.get, call_600615.host, call_600615.base,
                         call_600615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600615, url, valid)

proc call*(call_600616: Call_DescribeLocations_600604): Recallable =
  ## describeLocations
  ## Lists the AWS Direct Connect locations in the current AWS Region. These are the locations that can be selected when calling <a>CreateConnection</a> or <a>CreateInterconnect</a>.
  result = call_600616.call(nil, nil, nil, nil, nil)

var describeLocations* = Call_DescribeLocations_600604(name: "describeLocations",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeLocations",
    validator: validate_DescribeLocations_600605, base: "/",
    url: url_DescribeLocations_600606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_600617 = ref object of OpenApiRestCall_599368
proc url_DescribeTags_600619(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTags_600618(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600620 = header.getOrDefault("X-Amz-Date")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-Date", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Security-Token")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Security-Token", valid_600621
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600622 = header.getOrDefault("X-Amz-Target")
  valid_600622 = validateParameter(valid_600622, JString, required = true, default = newJString(
      "OvertureService.DescribeTags"))
  if valid_600622 != nil:
    section.add "X-Amz-Target", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Content-Sha256", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-Algorithm")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Algorithm", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Signature")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Signature", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-SignedHeaders", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Credential")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Credential", valid_600627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600629: Call_DescribeTags_600617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified AWS Direct Connect resources.
  ## 
  let valid = call_600629.validator(path, query, header, formData, body)
  let scheme = call_600629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600629.url(scheme.get, call_600629.host, call_600629.base,
                         call_600629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600629, url, valid)

proc call*(call_600630: Call_DescribeTags_600617; body: JsonNode): Recallable =
  ## describeTags
  ## Describes the tags associated with the specified AWS Direct Connect resources.
  ##   body: JObject (required)
  var body_600631 = newJObject()
  if body != nil:
    body_600631 = body
  result = call_600630.call(nil, nil, nil, nil, body_600631)

var describeTags* = Call_DescribeTags_600617(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeTags",
    validator: validate_DescribeTags_600618, base: "/", url: url_DescribeTags_600619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualGateways_600632 = ref object of OpenApiRestCall_599368
proc url_DescribeVirtualGateways_600634(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeVirtualGateways_600633(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600635 = header.getOrDefault("X-Amz-Date")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-Date", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-Security-Token")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Security-Token", valid_600636
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600637 = header.getOrDefault("X-Amz-Target")
  valid_600637 = validateParameter(valid_600637, JString, required = true, default = newJString(
      "OvertureService.DescribeVirtualGateways"))
  if valid_600637 != nil:
    section.add "X-Amz-Target", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Content-Sha256", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-Algorithm")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Algorithm", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Signature")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Signature", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-SignedHeaders", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Credential")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Credential", valid_600642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600643: Call_DescribeVirtualGateways_600632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the virtual private gateways owned by the AWS account.</p> <p>You can create one or more AWS Direct Connect private virtual interfaces linked to a virtual private gateway.</p>
  ## 
  let valid = call_600643.validator(path, query, header, formData, body)
  let scheme = call_600643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600643.url(scheme.get, call_600643.host, call_600643.base,
                         call_600643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600643, url, valid)

proc call*(call_600644: Call_DescribeVirtualGateways_600632): Recallable =
  ## describeVirtualGateways
  ## <p>Lists the virtual private gateways owned by the AWS account.</p> <p>You can create one or more AWS Direct Connect private virtual interfaces linked to a virtual private gateway.</p>
  result = call_600644.call(nil, nil, nil, nil, nil)

var describeVirtualGateways* = Call_DescribeVirtualGateways_600632(
    name: "describeVirtualGateways", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeVirtualGateways",
    validator: validate_DescribeVirtualGateways_600633, base: "/",
    url: url_DescribeVirtualGateways_600634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVirtualInterfaces_600645 = ref object of OpenApiRestCall_599368
proc url_DescribeVirtualInterfaces_600647(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeVirtualInterfaces_600646(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600648 = header.getOrDefault("X-Amz-Date")
  valid_600648 = validateParameter(valid_600648, JString, required = false,
                                 default = nil)
  if valid_600648 != nil:
    section.add "X-Amz-Date", valid_600648
  var valid_600649 = header.getOrDefault("X-Amz-Security-Token")
  valid_600649 = validateParameter(valid_600649, JString, required = false,
                                 default = nil)
  if valid_600649 != nil:
    section.add "X-Amz-Security-Token", valid_600649
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600650 = header.getOrDefault("X-Amz-Target")
  valid_600650 = validateParameter(valid_600650, JString, required = true, default = newJString(
      "OvertureService.DescribeVirtualInterfaces"))
  if valid_600650 != nil:
    section.add "X-Amz-Target", valid_600650
  var valid_600651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Content-Sha256", valid_600651
  var valid_600652 = header.getOrDefault("X-Amz-Algorithm")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Algorithm", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Signature")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Signature", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-SignedHeaders", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Credential")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Credential", valid_600655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600657: Call_DescribeVirtualInterfaces_600645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays all virtual interfaces for an AWS account. Virtual interfaces deleted fewer than 15 minutes before you make the request are also returned. If you specify a connection ID, only the virtual interfaces associated with the connection are returned. If you specify a virtual interface ID, then only a single virtual interface is returned.</p> <p>A virtual interface (VLAN) transmits the traffic between the AWS Direct Connect location and the customer network.</p>
  ## 
  let valid = call_600657.validator(path, query, header, formData, body)
  let scheme = call_600657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600657.url(scheme.get, call_600657.host, call_600657.base,
                         call_600657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600657, url, valid)

proc call*(call_600658: Call_DescribeVirtualInterfaces_600645; body: JsonNode): Recallable =
  ## describeVirtualInterfaces
  ## <p>Displays all virtual interfaces for an AWS account. Virtual interfaces deleted fewer than 15 minutes before you make the request are also returned. If you specify a connection ID, only the virtual interfaces associated with the connection are returned. If you specify a virtual interface ID, then only a single virtual interface is returned.</p> <p>A virtual interface (VLAN) transmits the traffic between the AWS Direct Connect location and the customer network.</p>
  ##   body: JObject (required)
  var body_600659 = newJObject()
  if body != nil:
    body_600659 = body
  result = call_600658.call(nil, nil, nil, nil, body_600659)

var describeVirtualInterfaces* = Call_DescribeVirtualInterfaces_600645(
    name: "describeVirtualInterfaces", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DescribeVirtualInterfaces",
    validator: validate_DescribeVirtualInterfaces_600646, base: "/",
    url: url_DescribeVirtualInterfaces_600647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConnectionFromLag_600660 = ref object of OpenApiRestCall_599368
proc url_DisassociateConnectionFromLag_600662(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateConnectionFromLag_600661(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600663 = header.getOrDefault("X-Amz-Date")
  valid_600663 = validateParameter(valid_600663, JString, required = false,
                                 default = nil)
  if valid_600663 != nil:
    section.add "X-Amz-Date", valid_600663
  var valid_600664 = header.getOrDefault("X-Amz-Security-Token")
  valid_600664 = validateParameter(valid_600664, JString, required = false,
                                 default = nil)
  if valid_600664 != nil:
    section.add "X-Amz-Security-Token", valid_600664
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600665 = header.getOrDefault("X-Amz-Target")
  valid_600665 = validateParameter(valid_600665, JString, required = true, default = newJString(
      "OvertureService.DisassociateConnectionFromLag"))
  if valid_600665 != nil:
    section.add "X-Amz-Target", valid_600665
  var valid_600666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "X-Amz-Content-Sha256", valid_600666
  var valid_600667 = header.getOrDefault("X-Amz-Algorithm")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Algorithm", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-Signature")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Signature", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-SignedHeaders", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-Credential")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-Credential", valid_600670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600672: Call_DisassociateConnectionFromLag_600660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates a connection from a link aggregation group (LAG). The connection is interrupted and re-established as a standalone connection (the connection is not deleted; to delete the connection, use the <a>DeleteConnection</a> request). If the LAG has associated virtual interfaces or hosted connections, they remain associated with the LAG. A disassociated connection owned by an AWS Direct Connect Partner is automatically converted to an interconnect.</p> <p>If disassociating the connection would cause the LAG to fall below its setting for minimum number of operational connections, the request fails, except when it's the last member of the LAG. If all connections are disassociated, the LAG continues to exist as an empty LAG with no physical connections. </p>
  ## 
  let valid = call_600672.validator(path, query, header, formData, body)
  let scheme = call_600672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600672.url(scheme.get, call_600672.host, call_600672.base,
                         call_600672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600672, url, valid)

proc call*(call_600673: Call_DisassociateConnectionFromLag_600660; body: JsonNode): Recallable =
  ## disassociateConnectionFromLag
  ## <p>Disassociates a connection from a link aggregation group (LAG). The connection is interrupted and re-established as a standalone connection (the connection is not deleted; to delete the connection, use the <a>DeleteConnection</a> request). If the LAG has associated virtual interfaces or hosted connections, they remain associated with the LAG. A disassociated connection owned by an AWS Direct Connect Partner is automatically converted to an interconnect.</p> <p>If disassociating the connection would cause the LAG to fall below its setting for minimum number of operational connections, the request fails, except when it's the last member of the LAG. If all connections are disassociated, the LAG continues to exist as an empty LAG with no physical connections. </p>
  ##   body: JObject (required)
  var body_600674 = newJObject()
  if body != nil:
    body_600674 = body
  result = call_600673.call(nil, nil, nil, nil, body_600674)

var disassociateConnectionFromLag* = Call_DisassociateConnectionFromLag_600660(
    name: "disassociateConnectionFromLag", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.DisassociateConnectionFromLag",
    validator: validate_DisassociateConnectionFromLag_600661, base: "/",
    url: url_DisassociateConnectionFromLag_600662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600675 = ref object of OpenApiRestCall_599368
proc url_TagResource_600677(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600676(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600678 = header.getOrDefault("X-Amz-Date")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Date", valid_600678
  var valid_600679 = header.getOrDefault("X-Amz-Security-Token")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "X-Amz-Security-Token", valid_600679
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600680 = header.getOrDefault("X-Amz-Target")
  valid_600680 = validateParameter(valid_600680, JString, required = true, default = newJString(
      "OvertureService.TagResource"))
  if valid_600680 != nil:
    section.add "X-Amz-Target", valid_600680
  var valid_600681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600681 = validateParameter(valid_600681, JString, required = false,
                                 default = nil)
  if valid_600681 != nil:
    section.add "X-Amz-Content-Sha256", valid_600681
  var valid_600682 = header.getOrDefault("X-Amz-Algorithm")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Algorithm", valid_600682
  var valid_600683 = header.getOrDefault("X-Amz-Signature")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "X-Amz-Signature", valid_600683
  var valid_600684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "X-Amz-SignedHeaders", valid_600684
  var valid_600685 = header.getOrDefault("X-Amz-Credential")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "X-Amz-Credential", valid_600685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600687: Call_TagResource_600675; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified AWS Direct Connect resource. Each resource can have a maximum of 50 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the resource, this action updates its value.</p>
  ## 
  let valid = call_600687.validator(path, query, header, formData, body)
  let scheme = call_600687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600687.url(scheme.get, call_600687.host, call_600687.base,
                         call_600687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600687, url, valid)

proc call*(call_600688: Call_TagResource_600675; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds the specified tags to the specified AWS Direct Connect resource. Each resource can have a maximum of 50 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the resource, this action updates its value.</p>
  ##   body: JObject (required)
  var body_600689 = newJObject()
  if body != nil:
    body_600689 = body
  result = call_600688.call(nil, nil, nil, nil, body_600689)

var tagResource* = Call_TagResource_600675(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.TagResource",
                                        validator: validate_TagResource_600676,
                                        base: "/", url: url_TagResource_600677,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600690 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600692(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600691(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600693 = header.getOrDefault("X-Amz-Date")
  valid_600693 = validateParameter(valid_600693, JString, required = false,
                                 default = nil)
  if valid_600693 != nil:
    section.add "X-Amz-Date", valid_600693
  var valid_600694 = header.getOrDefault("X-Amz-Security-Token")
  valid_600694 = validateParameter(valid_600694, JString, required = false,
                                 default = nil)
  if valid_600694 != nil:
    section.add "X-Amz-Security-Token", valid_600694
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600695 = header.getOrDefault("X-Amz-Target")
  valid_600695 = validateParameter(valid_600695, JString, required = true, default = newJString(
      "OvertureService.UntagResource"))
  if valid_600695 != nil:
    section.add "X-Amz-Target", valid_600695
  var valid_600696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600696 = validateParameter(valid_600696, JString, required = false,
                                 default = nil)
  if valid_600696 != nil:
    section.add "X-Amz-Content-Sha256", valid_600696
  var valid_600697 = header.getOrDefault("X-Amz-Algorithm")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-Algorithm", valid_600697
  var valid_600698 = header.getOrDefault("X-Amz-Signature")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Signature", valid_600698
  var valid_600699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-SignedHeaders", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-Credential")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Credential", valid_600700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600702: Call_UntagResource_600690; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified AWS Direct Connect resource.
  ## 
  let valid = call_600702.validator(path, query, header, formData, body)
  let scheme = call_600702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600702.url(scheme.get, call_600702.host, call_600702.base,
                         call_600702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600702, url, valid)

proc call*(call_600703: Call_UntagResource_600690; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from the specified AWS Direct Connect resource.
  ##   body: JObject (required)
  var body_600704 = newJObject()
  if body != nil:
    body_600704 = body
  result = call_600703.call(nil, nil, nil, nil, body_600704)

var untagResource* = Call_UntagResource_600690(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.UntagResource",
    validator: validate_UntagResource_600691, base: "/", url: url_UntagResource_600692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDirectConnectGatewayAssociation_600705 = ref object of OpenApiRestCall_599368
proc url_UpdateDirectConnectGatewayAssociation_600707(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDirectConnectGatewayAssociation_600706(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600708 = header.getOrDefault("X-Amz-Date")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "X-Amz-Date", valid_600708
  var valid_600709 = header.getOrDefault("X-Amz-Security-Token")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "X-Amz-Security-Token", valid_600709
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600710 = header.getOrDefault("X-Amz-Target")
  valid_600710 = validateParameter(valid_600710, JString, required = true, default = newJString(
      "OvertureService.UpdateDirectConnectGatewayAssociation"))
  if valid_600710 != nil:
    section.add "X-Amz-Target", valid_600710
  var valid_600711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600711 = validateParameter(valid_600711, JString, required = false,
                                 default = nil)
  if valid_600711 != nil:
    section.add "X-Amz-Content-Sha256", valid_600711
  var valid_600712 = header.getOrDefault("X-Amz-Algorithm")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "X-Amz-Algorithm", valid_600712
  var valid_600713 = header.getOrDefault("X-Amz-Signature")
  valid_600713 = validateParameter(valid_600713, JString, required = false,
                                 default = nil)
  if valid_600713 != nil:
    section.add "X-Amz-Signature", valid_600713
  var valid_600714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600714 = validateParameter(valid_600714, JString, required = false,
                                 default = nil)
  if valid_600714 != nil:
    section.add "X-Amz-SignedHeaders", valid_600714
  var valid_600715 = header.getOrDefault("X-Amz-Credential")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "X-Amz-Credential", valid_600715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600717: Call_UpdateDirectConnectGatewayAssociation_600705;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified attributes of the Direct Connect gateway association.</p> <p>Add or remove prefixes from the association.</p>
  ## 
  let valid = call_600717.validator(path, query, header, formData, body)
  let scheme = call_600717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600717.url(scheme.get, call_600717.host, call_600717.base,
                         call_600717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600717, url, valid)

proc call*(call_600718: Call_UpdateDirectConnectGatewayAssociation_600705;
          body: JsonNode): Recallable =
  ## updateDirectConnectGatewayAssociation
  ## <p>Updates the specified attributes of the Direct Connect gateway association.</p> <p>Add or remove prefixes from the association.</p>
  ##   body: JObject (required)
  var body_600719 = newJObject()
  if body != nil:
    body_600719 = body
  result = call_600718.call(nil, nil, nil, nil, body_600719)

var updateDirectConnectGatewayAssociation* = Call_UpdateDirectConnectGatewayAssociation_600705(
    name: "updateDirectConnectGatewayAssociation", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.UpdateDirectConnectGatewayAssociation",
    validator: validate_UpdateDirectConnectGatewayAssociation_600706, base: "/",
    url: url_UpdateDirectConnectGatewayAssociation_600707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLag_600720 = ref object of OpenApiRestCall_599368
proc url_UpdateLag_600722(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLag_600721(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600723 = header.getOrDefault("X-Amz-Date")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Date", valid_600723
  var valid_600724 = header.getOrDefault("X-Amz-Security-Token")
  valid_600724 = validateParameter(valid_600724, JString, required = false,
                                 default = nil)
  if valid_600724 != nil:
    section.add "X-Amz-Security-Token", valid_600724
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600725 = header.getOrDefault("X-Amz-Target")
  valid_600725 = validateParameter(valid_600725, JString, required = true, default = newJString(
      "OvertureService.UpdateLag"))
  if valid_600725 != nil:
    section.add "X-Amz-Target", valid_600725
  var valid_600726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600726 = validateParameter(valid_600726, JString, required = false,
                                 default = nil)
  if valid_600726 != nil:
    section.add "X-Amz-Content-Sha256", valid_600726
  var valid_600727 = header.getOrDefault("X-Amz-Algorithm")
  valid_600727 = validateParameter(valid_600727, JString, required = false,
                                 default = nil)
  if valid_600727 != nil:
    section.add "X-Amz-Algorithm", valid_600727
  var valid_600728 = header.getOrDefault("X-Amz-Signature")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-Signature", valid_600728
  var valid_600729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600729 = validateParameter(valid_600729, JString, required = false,
                                 default = nil)
  if valid_600729 != nil:
    section.add "X-Amz-SignedHeaders", valid_600729
  var valid_600730 = header.getOrDefault("X-Amz-Credential")
  valid_600730 = validateParameter(valid_600730, JString, required = false,
                                 default = nil)
  if valid_600730 != nil:
    section.add "X-Amz-Credential", valid_600730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600732: Call_UpdateLag_600720; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the attributes of the specified link aggregation group (LAG).</p> <p>You can update the following attributes:</p> <ul> <li> <p>The name of the LAG.</p> </li> <li> <p>The value for the minimum number of connections that must be operational for the LAG itself to be operational. </p> </li> </ul> <p>When you create a LAG, the default value for the minimum number of operational connections is zero (0). If you update this value and the number of operational connections falls below the specified value, the LAG automatically goes down to avoid over-utilization of the remaining connections. Adjust this value with care, as it could force the LAG down if it is set higher than the current number of operational connections.</p>
  ## 
  let valid = call_600732.validator(path, query, header, formData, body)
  let scheme = call_600732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600732.url(scheme.get, call_600732.host, call_600732.base,
                         call_600732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600732, url, valid)

proc call*(call_600733: Call_UpdateLag_600720; body: JsonNode): Recallable =
  ## updateLag
  ## <p>Updates the attributes of the specified link aggregation group (LAG).</p> <p>You can update the following attributes:</p> <ul> <li> <p>The name of the LAG.</p> </li> <li> <p>The value for the minimum number of connections that must be operational for the LAG itself to be operational. </p> </li> </ul> <p>When you create a LAG, the default value for the minimum number of operational connections is zero (0). If you update this value and the number of operational connections falls below the specified value, the LAG automatically goes down to avoid over-utilization of the remaining connections. Adjust this value with care, as it could force the LAG down if it is set higher than the current number of operational connections.</p>
  ##   body: JObject (required)
  var body_600734 = newJObject()
  if body != nil:
    body_600734 = body
  result = call_600733.call(nil, nil, nil, nil, body_600734)

var updateLag* = Call_UpdateLag_600720(name: "updateLag", meth: HttpMethod.HttpPost,
                                    host: "directconnect.amazonaws.com", route: "/#X-Amz-Target=OvertureService.UpdateLag",
                                    validator: validate_UpdateLag_600721,
                                    base: "/", url: url_UpdateLag_600722,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVirtualInterfaceAttributes_600735 = ref object of OpenApiRestCall_599368
proc url_UpdateVirtualInterfaceAttributes_600737(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVirtualInterfaceAttributes_600736(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600738 = header.getOrDefault("X-Amz-Date")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Date", valid_600738
  var valid_600739 = header.getOrDefault("X-Amz-Security-Token")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "X-Amz-Security-Token", valid_600739
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600740 = header.getOrDefault("X-Amz-Target")
  valid_600740 = validateParameter(valid_600740, JString, required = true, default = newJString(
      "OvertureService.UpdateVirtualInterfaceAttributes"))
  if valid_600740 != nil:
    section.add "X-Amz-Target", valid_600740
  var valid_600741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600741 = validateParameter(valid_600741, JString, required = false,
                                 default = nil)
  if valid_600741 != nil:
    section.add "X-Amz-Content-Sha256", valid_600741
  var valid_600742 = header.getOrDefault("X-Amz-Algorithm")
  valid_600742 = validateParameter(valid_600742, JString, required = false,
                                 default = nil)
  if valid_600742 != nil:
    section.add "X-Amz-Algorithm", valid_600742
  var valid_600743 = header.getOrDefault("X-Amz-Signature")
  valid_600743 = validateParameter(valid_600743, JString, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "X-Amz-Signature", valid_600743
  var valid_600744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600744 = validateParameter(valid_600744, JString, required = false,
                                 default = nil)
  if valid_600744 != nil:
    section.add "X-Amz-SignedHeaders", valid_600744
  var valid_600745 = header.getOrDefault("X-Amz-Credential")
  valid_600745 = validateParameter(valid_600745, JString, required = false,
                                 default = nil)
  if valid_600745 != nil:
    section.add "X-Amz-Credential", valid_600745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600747: Call_UpdateVirtualInterfaceAttributes_600735;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified attributes of the specified virtual private interface.</p> <p>Setting the MTU of a virtual interface to 9001 (jumbo frames) can cause an update to the underlying physical connection if it wasn't updated to support jumbo frames. Updating the connection disrupts network connectivity for all virtual interfaces associated with the connection for up to 30 seconds. To check whether your connection supports jumbo frames, call <a>DescribeConnections</a>. To check whether your virtual interface supports jumbo frames, call <a>DescribeVirtualInterfaces</a>.</p>
  ## 
  let valid = call_600747.validator(path, query, header, formData, body)
  let scheme = call_600747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600747.url(scheme.get, call_600747.host, call_600747.base,
                         call_600747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600747, url, valid)

proc call*(call_600748: Call_UpdateVirtualInterfaceAttributes_600735;
          body: JsonNode): Recallable =
  ## updateVirtualInterfaceAttributes
  ## <p>Updates the specified attributes of the specified virtual private interface.</p> <p>Setting the MTU of a virtual interface to 9001 (jumbo frames) can cause an update to the underlying physical connection if it wasn't updated to support jumbo frames. Updating the connection disrupts network connectivity for all virtual interfaces associated with the connection for up to 30 seconds. To check whether your connection supports jumbo frames, call <a>DescribeConnections</a>. To check whether your virtual interface supports jumbo frames, call <a>DescribeVirtualInterfaces</a>.</p>
  ##   body: JObject (required)
  var body_600749 = newJObject()
  if body != nil:
    body_600749 = body
  result = call_600748.call(nil, nil, nil, nil, body_600749)

var updateVirtualInterfaceAttributes* = Call_UpdateVirtualInterfaceAttributes_600735(
    name: "updateVirtualInterfaceAttributes", meth: HttpMethod.HttpPost,
    host: "directconnect.amazonaws.com",
    route: "/#X-Amz-Target=OvertureService.UpdateVirtualInterfaceAttributes",
    validator: validate_UpdateVirtualInterfaceAttributes_600736, base: "/",
    url: url_UpdateVirtualInterfaceAttributes_600737,
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
