
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Network Manager
## version: 2019-07-05
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Transit Gateway Network Manager (Network Manager) enables you to create a global network, in which you can monitor your AWS and on-premises networks that are built around transit gateways.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/networkmanager/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "networkmanager.ap-northeast-1.amazonaws.com", "ap-southeast-1": "networkmanager.ap-southeast-1.amazonaws.com", "us-west-2": "networkmanager.us-west-2.amazonaws.com", "eu-west-2": "networkmanager.eu-west-2.amazonaws.com", "ap-northeast-3": "networkmanager.ap-northeast-3.amazonaws.com", "eu-central-1": "networkmanager.eu-central-1.amazonaws.com", "us-east-2": "networkmanager.us-east-2.amazonaws.com", "us-east-1": "networkmanager.us-east-1.amazonaws.com", "cn-northwest-1": "networkmanager.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "networkmanager.ap-south-1.amazonaws.com", "eu-north-1": "networkmanager.eu-north-1.amazonaws.com", "ap-northeast-2": "networkmanager.ap-northeast-2.amazonaws.com", "us-west-1": "networkmanager.us-west-1.amazonaws.com", "us-gov-east-1": "networkmanager.us-gov-east-1.amazonaws.com", "eu-west-3": "networkmanager.eu-west-3.amazonaws.com", "cn-north-1": "networkmanager.cn-north-1.amazonaws.com.cn", "sa-east-1": "networkmanager.sa-east-1.amazonaws.com", "eu-west-1": "networkmanager.eu-west-1.amazonaws.com", "us-gov-west-1": "networkmanager.us-gov-west-1.amazonaws.com", "ap-southeast-2": "networkmanager.ap-southeast-2.amazonaws.com", "ca-central-1": "networkmanager.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "networkmanager.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "networkmanager.ap-southeast-1.amazonaws.com",
      "us-west-2": "networkmanager.us-west-2.amazonaws.com",
      "eu-west-2": "networkmanager.eu-west-2.amazonaws.com",
      "ap-northeast-3": "networkmanager.ap-northeast-3.amazonaws.com",
      "eu-central-1": "networkmanager.eu-central-1.amazonaws.com",
      "us-east-2": "networkmanager.us-east-2.amazonaws.com",
      "us-east-1": "networkmanager.us-east-1.amazonaws.com",
      "cn-northwest-1": "networkmanager.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "networkmanager.ap-south-1.amazonaws.com",
      "eu-north-1": "networkmanager.eu-north-1.amazonaws.com",
      "ap-northeast-2": "networkmanager.ap-northeast-2.amazonaws.com",
      "us-west-1": "networkmanager.us-west-1.amazonaws.com",
      "us-gov-east-1": "networkmanager.us-gov-east-1.amazonaws.com",
      "eu-west-3": "networkmanager.eu-west-3.amazonaws.com",
      "cn-north-1": "networkmanager.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "networkmanager.sa-east-1.amazonaws.com",
      "eu-west-1": "networkmanager.eu-west-1.amazonaws.com",
      "us-gov-west-1": "networkmanager.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "networkmanager.ap-southeast-2.amazonaws.com",
      "ca-central-1": "networkmanager.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "networkmanager"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateCustomerGateway_611272 = ref object of OpenApiRestCall_610658
proc url_AssociateCustomerGateway_611274(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/customer-gateway-associations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateCustomerGateway_611273(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611275 = path.getOrDefault("globalNetworkId")
  valid_611275 = validateParameter(valid_611275, JString, required = true,
                                 default = nil)
  if valid_611275 != nil:
    section.add "globalNetworkId", valid_611275
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
  var valid_611276 = header.getOrDefault("X-Amz-Signature")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Signature", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Content-Sha256", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Date")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Date", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Credential")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Credential", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-Security-Token")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-Security-Token", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-Algorithm")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-Algorithm", valid_611281
  var valid_611282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "X-Amz-SignedHeaders", valid_611282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611284: Call_AssociateCustomerGateway_611272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ## 
  let valid = call_611284.validator(path, query, header, formData, body)
  let scheme = call_611284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611284.url(scheme.get, call_611284.host, call_611284.base,
                         call_611284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611284, url, valid)

proc call*(call_611285: Call_AssociateCustomerGateway_611272;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## associateCustomerGateway
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_611286 = newJObject()
  var body_611287 = newJObject()
  add(path_611286, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_611287 = body
  result = call_611285.call(path_611286, nil, nil, nil, body_611287)

var associateCustomerGateway* = Call_AssociateCustomerGateway_611272(
    name: "associateCustomerGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_AssociateCustomerGateway_611273, base: "/",
    url: url_AssociateCustomerGateway_611274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCustomerGatewayAssociations_610996 = ref object of OpenApiRestCall_610658
proc url_GetCustomerGatewayAssociations_610998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/customer-gateway-associations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCustomerGatewayAssociations_610997(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the association information for customer gateways that are associated with devices and links in your global network.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611124 = path.getOrDefault("globalNetworkId")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "globalNetworkId", valid_611124
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   customerGatewayArns: JArray
  ##                      : One or more customer gateway Amazon Resource Names (ARNs). For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources Defined by Amazon EC2</a>. The maximum is 10.
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  section = newJObject()
  var valid_611125 = query.getOrDefault("nextToken")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "nextToken", valid_611125
  var valid_611126 = query.getOrDefault("MaxResults")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "MaxResults", valid_611126
  var valid_611127 = query.getOrDefault("NextToken")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "NextToken", valid_611127
  var valid_611128 = query.getOrDefault("customerGatewayArns")
  valid_611128 = validateParameter(valid_611128, JArray, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "customerGatewayArns", valid_611128
  var valid_611129 = query.getOrDefault("maxResults")
  valid_611129 = validateParameter(valid_611129, JInt, required = false, default = nil)
  if valid_611129 != nil:
    section.add "maxResults", valid_611129
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
  var valid_611130 = header.getOrDefault("X-Amz-Signature")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Signature", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-Content-Sha256", valid_611131
  var valid_611132 = header.getOrDefault("X-Amz-Date")
  valid_611132 = validateParameter(valid_611132, JString, required = false,
                                 default = nil)
  if valid_611132 != nil:
    section.add "X-Amz-Date", valid_611132
  var valid_611133 = header.getOrDefault("X-Amz-Credential")
  valid_611133 = validateParameter(valid_611133, JString, required = false,
                                 default = nil)
  if valid_611133 != nil:
    section.add "X-Amz-Credential", valid_611133
  var valid_611134 = header.getOrDefault("X-Amz-Security-Token")
  valid_611134 = validateParameter(valid_611134, JString, required = false,
                                 default = nil)
  if valid_611134 != nil:
    section.add "X-Amz-Security-Token", valid_611134
  var valid_611135 = header.getOrDefault("X-Amz-Algorithm")
  valid_611135 = validateParameter(valid_611135, JString, required = false,
                                 default = nil)
  if valid_611135 != nil:
    section.add "X-Amz-Algorithm", valid_611135
  var valid_611136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611136 = validateParameter(valid_611136, JString, required = false,
                                 default = nil)
  if valid_611136 != nil:
    section.add "X-Amz-SignedHeaders", valid_611136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611159: Call_GetCustomerGatewayAssociations_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the association information for customer gateways that are associated with devices and links in your global network.
  ## 
  let valid = call_611159.validator(path, query, header, formData, body)
  let scheme = call_611159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611159.url(scheme.get, call_611159.host, call_611159.base,
                         call_611159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611159, url, valid)

proc call*(call_611230: Call_GetCustomerGatewayAssociations_610996;
          globalNetworkId: string; nextToken: string = ""; MaxResults: string = "";
          NextToken: string = ""; customerGatewayArns: JsonNode = nil;
          maxResults: int = 0): Recallable =
  ## getCustomerGatewayAssociations
  ## Gets the association information for customer gateways that are associated with devices and links in your global network.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   customerGatewayArns: JArray
  ##                      : One or more customer gateway Amazon Resource Names (ARNs). For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources Defined by Amazon EC2</a>. The maximum is 10.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  var path_611231 = newJObject()
  var query_611233 = newJObject()
  add(query_611233, "nextToken", newJString(nextToken))
  add(query_611233, "MaxResults", newJString(MaxResults))
  add(query_611233, "NextToken", newJString(NextToken))
  add(path_611231, "globalNetworkId", newJString(globalNetworkId))
  if customerGatewayArns != nil:
    query_611233.add "customerGatewayArns", customerGatewayArns
  add(query_611233, "maxResults", newJInt(maxResults))
  result = call_611230.call(path_611231, query_611233, nil, nil, nil)

var getCustomerGatewayAssociations* = Call_GetCustomerGatewayAssociations_610996(
    name: "getCustomerGatewayAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_GetCustomerGatewayAssociations_610997, base: "/",
    url: url_GetCustomerGatewayAssociations_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateLink_611309 = ref object of OpenApiRestCall_610658
proc url_AssociateLink_611311(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/link-associations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateLink_611310(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611312 = path.getOrDefault("globalNetworkId")
  valid_611312 = validateParameter(valid_611312, JString, required = true,
                                 default = nil)
  if valid_611312 != nil:
    section.add "globalNetworkId", valid_611312
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
  var valid_611313 = header.getOrDefault("X-Amz-Signature")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Signature", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Content-Sha256", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Date")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Date", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Credential")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Credential", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Security-Token")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Security-Token", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Algorithm")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Algorithm", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-SignedHeaders", valid_611319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611321: Call_AssociateLink_611309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ## 
  let valid = call_611321.validator(path, query, header, formData, body)
  let scheme = call_611321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611321.url(scheme.get, call_611321.host, call_611321.base,
                         call_611321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611321, url, valid)

proc call*(call_611322: Call_AssociateLink_611309; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## associateLink
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_611323 = newJObject()
  var body_611324 = newJObject()
  add(path_611323, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_611324 = body
  result = call_611322.call(path_611323, nil, nil, nil, body_611324)

var associateLink* = Call_AssociateLink_611309(name: "associateLink",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_AssociateLink_611310, base: "/", url: url_AssociateLink_611311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAssociations_611288 = ref object of OpenApiRestCall_610658
proc url_GetLinkAssociations_611290(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/link-associations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLinkAssociations_611289(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets the link associations for a device or a link. Either the device ID or the link ID must be specified.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611291 = path.getOrDefault("globalNetworkId")
  valid_611291 = validateParameter(valid_611291, JString, required = true,
                                 default = nil)
  if valid_611291 != nil:
    section.add "globalNetworkId", valid_611291
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   deviceId: JString
  ##           : The ID of the device.
  ##   linkId: JString
  ##         : The ID of the link.
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  section = newJObject()
  var valid_611292 = query.getOrDefault("nextToken")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "nextToken", valid_611292
  var valid_611293 = query.getOrDefault("MaxResults")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "MaxResults", valid_611293
  var valid_611294 = query.getOrDefault("NextToken")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "NextToken", valid_611294
  var valid_611295 = query.getOrDefault("deviceId")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "deviceId", valid_611295
  var valid_611296 = query.getOrDefault("linkId")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "linkId", valid_611296
  var valid_611297 = query.getOrDefault("maxResults")
  valid_611297 = validateParameter(valid_611297, JInt, required = false, default = nil)
  if valid_611297 != nil:
    section.add "maxResults", valid_611297
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
  var valid_611298 = header.getOrDefault("X-Amz-Signature")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Signature", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Content-Sha256", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Date")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Date", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Credential")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Credential", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Security-Token")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Security-Token", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Algorithm")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Algorithm", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-SignedHeaders", valid_611304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611305: Call_GetLinkAssociations_611288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the link associations for a device or a link. Either the device ID or the link ID must be specified.
  ## 
  let valid = call_611305.validator(path, query, header, formData, body)
  let scheme = call_611305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611305.url(scheme.get, call_611305.host, call_611305.base,
                         call_611305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611305, url, valid)

proc call*(call_611306: Call_GetLinkAssociations_611288; globalNetworkId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          deviceId: string = ""; linkId: string = ""; maxResults: int = 0): Recallable =
  ## getLinkAssociations
  ## Gets the link associations for a device or a link. Either the device ID or the link ID must be specified.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   deviceId: string
  ##           : The ID of the device.
  ##   linkId: string
  ##         : The ID of the link.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  var path_611307 = newJObject()
  var query_611308 = newJObject()
  add(query_611308, "nextToken", newJString(nextToken))
  add(query_611308, "MaxResults", newJString(MaxResults))
  add(query_611308, "NextToken", newJString(NextToken))
  add(path_611307, "globalNetworkId", newJString(globalNetworkId))
  add(query_611308, "deviceId", newJString(deviceId))
  add(query_611308, "linkId", newJString(linkId))
  add(query_611308, "maxResults", newJInt(maxResults))
  result = call_611306.call(path_611307, query_611308, nil, nil, nil)

var getLinkAssociations* = Call_GetLinkAssociations_611288(
    name: "getLinkAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_GetLinkAssociations_611289, base: "/",
    url: url_GetLinkAssociations_611290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevice_611346 = ref object of OpenApiRestCall_610658
proc url_CreateDevice_611348(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/devices")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDevice_611347(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611349 = path.getOrDefault("globalNetworkId")
  valid_611349 = validateParameter(valid_611349, JString, required = true,
                                 default = nil)
  if valid_611349 != nil:
    section.add "globalNetworkId", valid_611349
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
  var valid_611350 = header.getOrDefault("X-Amz-Signature")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Signature", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Content-Sha256", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Date")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Date", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Credential")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Credential", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Security-Token")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Security-Token", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Algorithm")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Algorithm", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-SignedHeaders", valid_611356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611358: Call_CreateDevice_611346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ## 
  let valid = call_611358.validator(path, query, header, formData, body)
  let scheme = call_611358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611358.url(scheme.get, call_611358.host, call_611358.base,
                         call_611358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611358, url, valid)

proc call*(call_611359: Call_CreateDevice_611346; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createDevice
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_611360 = newJObject()
  var body_611361 = newJObject()
  add(path_611360, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_611361 = body
  result = call_611359.call(path_611360, nil, nil, nil, body_611361)

var createDevice* = Call_CreateDevice_611346(name: "createDevice",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices",
    validator: validate_CreateDevice_611347, base: "/", url: url_CreateDevice_611348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevices_611325 = ref object of OpenApiRestCall_610658
proc url_GetDevices_611327(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/devices")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDevices_611326(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more of your devices in a global network.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611328 = path.getOrDefault("globalNetworkId")
  valid_611328 = validateParameter(valid_611328, JString, required = true,
                                 default = nil)
  if valid_611328 != nil:
    section.add "globalNetworkId", valid_611328
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   deviceIds: JArray
  ##            : One or more device IDs. The maximum is 10.
  ##   NextToken: JString
  ##            : Pagination token
  ##   siteId: JString
  ##         : The ID of the site.
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  section = newJObject()
  var valid_611329 = query.getOrDefault("nextToken")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "nextToken", valid_611329
  var valid_611330 = query.getOrDefault("MaxResults")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "MaxResults", valid_611330
  var valid_611331 = query.getOrDefault("deviceIds")
  valid_611331 = validateParameter(valid_611331, JArray, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "deviceIds", valid_611331
  var valid_611332 = query.getOrDefault("NextToken")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "NextToken", valid_611332
  var valid_611333 = query.getOrDefault("siteId")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "siteId", valid_611333
  var valid_611334 = query.getOrDefault("maxResults")
  valid_611334 = validateParameter(valid_611334, JInt, required = false, default = nil)
  if valid_611334 != nil:
    section.add "maxResults", valid_611334
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
  var valid_611335 = header.getOrDefault("X-Amz-Signature")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Signature", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Content-Sha256", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-Date")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Date", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Credential")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Credential", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Security-Token")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Security-Token", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Algorithm")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Algorithm", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-SignedHeaders", valid_611341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611342: Call_GetDevices_611325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more of your devices in a global network.
  ## 
  let valid = call_611342.validator(path, query, header, formData, body)
  let scheme = call_611342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611342.url(scheme.get, call_611342.host, call_611342.base,
                         call_611342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611342, url, valid)

proc call*(call_611343: Call_GetDevices_611325; globalNetworkId: string;
          nextToken: string = ""; MaxResults: string = ""; deviceIds: JsonNode = nil;
          NextToken: string = ""; siteId: string = ""; maxResults: int = 0): Recallable =
  ## getDevices
  ## Gets information about one or more of your devices in a global network.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   deviceIds: JArray
  ##            : One or more device IDs. The maximum is 10.
  ##   NextToken: string
  ##            : Pagination token
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   siteId: string
  ##         : The ID of the site.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  var path_611344 = newJObject()
  var query_611345 = newJObject()
  add(query_611345, "nextToken", newJString(nextToken))
  add(query_611345, "MaxResults", newJString(MaxResults))
  if deviceIds != nil:
    query_611345.add "deviceIds", deviceIds
  add(query_611345, "NextToken", newJString(NextToken))
  add(path_611344, "globalNetworkId", newJString(globalNetworkId))
  add(query_611345, "siteId", newJString(siteId))
  add(query_611345, "maxResults", newJInt(maxResults))
  result = call_611343.call(path_611344, query_611345, nil, nil, nil)

var getDevices* = Call_GetDevices_611325(name: "getDevices",
                                      meth: HttpMethod.HttpGet,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/devices",
                                      validator: validate_GetDevices_611326,
                                      base: "/", url: url_GetDevices_611327,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGlobalNetwork_611380 = ref object of OpenApiRestCall_610658
proc url_CreateGlobalNetwork_611382(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGlobalNetwork_611381(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a new, empty global network.
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
  var valid_611383 = header.getOrDefault("X-Amz-Signature")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Signature", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Content-Sha256", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Date")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Date", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Credential")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Credential", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Security-Token")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Security-Token", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Algorithm")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Algorithm", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-SignedHeaders", valid_611389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611391: Call_CreateGlobalNetwork_611380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty global network.
  ## 
  let valid = call_611391.validator(path, query, header, formData, body)
  let scheme = call_611391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611391.url(scheme.get, call_611391.host, call_611391.base,
                         call_611391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611391, url, valid)

proc call*(call_611392: Call_CreateGlobalNetwork_611380; body: JsonNode): Recallable =
  ## createGlobalNetwork
  ## Creates a new, empty global network.
  ##   body: JObject (required)
  var body_611393 = newJObject()
  if body != nil:
    body_611393 = body
  result = call_611392.call(nil, nil, nil, nil, body_611393)

var createGlobalNetwork* = Call_CreateGlobalNetwork_611380(
    name: "createGlobalNetwork", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_CreateGlobalNetwork_611381, base: "/",
    url: url_CreateGlobalNetwork_611382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalNetworks_611362 = ref object of OpenApiRestCall_610658
proc url_DescribeGlobalNetworks_611364(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeGlobalNetworks_611363(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   globalNetworkIds: JArray
  ##                   : The IDs of one or more global networks. The maximum is 10.
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  section = newJObject()
  var valid_611365 = query.getOrDefault("nextToken")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "nextToken", valid_611365
  var valid_611366 = query.getOrDefault("MaxResults")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "MaxResults", valid_611366
  var valid_611367 = query.getOrDefault("NextToken")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "NextToken", valid_611367
  var valid_611368 = query.getOrDefault("globalNetworkIds")
  valid_611368 = validateParameter(valid_611368, JArray, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "globalNetworkIds", valid_611368
  var valid_611369 = query.getOrDefault("maxResults")
  valid_611369 = validateParameter(valid_611369, JInt, required = false, default = nil)
  if valid_611369 != nil:
    section.add "maxResults", valid_611369
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
  var valid_611370 = header.getOrDefault("X-Amz-Signature")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Signature", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Content-Sha256", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Date")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Date", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Credential")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Credential", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Security-Token")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Security-Token", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Algorithm")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Algorithm", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-SignedHeaders", valid_611376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611377: Call_DescribeGlobalNetworks_611362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
  ## 
  let valid = call_611377.validator(path, query, header, formData, body)
  let scheme = call_611377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611377.url(scheme.get, call_611377.host, call_611377.base,
                         call_611377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611377, url, valid)

proc call*(call_611378: Call_DescribeGlobalNetworks_611362; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = "";
          globalNetworkIds: JsonNode = nil; maxResults: int = 0): Recallable =
  ## describeGlobalNetworks
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   globalNetworkIds: JArray
  ##                   : The IDs of one or more global networks. The maximum is 10.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  var query_611379 = newJObject()
  add(query_611379, "nextToken", newJString(nextToken))
  add(query_611379, "MaxResults", newJString(MaxResults))
  add(query_611379, "NextToken", newJString(NextToken))
  if globalNetworkIds != nil:
    query_611379.add "globalNetworkIds", globalNetworkIds
  add(query_611379, "maxResults", newJInt(maxResults))
  result = call_611378.call(nil, query_611379, nil, nil, nil)

var describeGlobalNetworks* = Call_DescribeGlobalNetworks_611362(
    name: "describeGlobalNetworks", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_DescribeGlobalNetworks_611363, base: "/",
    url: url_DescribeGlobalNetworks_611364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLink_611417 = ref object of OpenApiRestCall_610658
proc url_CreateLink_611419(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/links")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateLink_611418(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new link for a specified site.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611420 = path.getOrDefault("globalNetworkId")
  valid_611420 = validateParameter(valid_611420, JString, required = true,
                                 default = nil)
  if valid_611420 != nil:
    section.add "globalNetworkId", valid_611420
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
  var valid_611421 = header.getOrDefault("X-Amz-Signature")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Signature", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Content-Sha256", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Date")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Date", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Credential")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Credential", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Security-Token")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Security-Token", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Algorithm")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Algorithm", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-SignedHeaders", valid_611427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611429: Call_CreateLink_611417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new link for a specified site.
  ## 
  let valid = call_611429.validator(path, query, header, formData, body)
  let scheme = call_611429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611429.url(scheme.get, call_611429.host, call_611429.base,
                         call_611429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611429, url, valid)

proc call*(call_611430: Call_CreateLink_611417; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createLink
  ## Creates a new link for a specified site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_611431 = newJObject()
  var body_611432 = newJObject()
  add(path_611431, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_611432 = body
  result = call_611430.call(path_611431, nil, nil, nil, body_611432)

var createLink* = Call_CreateLink_611417(name: "createLink",
                                      meth: HttpMethod.HttpPost,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                      validator: validate_CreateLink_611418,
                                      base: "/", url: url_CreateLink_611419,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinks_611394 = ref object of OpenApiRestCall_610658
proc url_GetLinks_611396(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/links")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLinks_611395(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about one or more links in a specified global network.</p> <p>If you specify the site ID, you cannot specify the type or provider in the same request. You can specify the type and provider in the same request.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611397 = path.getOrDefault("globalNetworkId")
  valid_611397 = validateParameter(valid_611397, JString, required = true,
                                 default = nil)
  if valid_611397 != nil:
    section.add "globalNetworkId", valid_611397
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   linkIds: JArray
  ##          : One or more link IDs. The maximum is 10.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   type: JString
  ##       : The link type.
  ##   provider: JString
  ##           : The link provider.
  ##   siteId: JString
  ##         : The ID of the site.
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  section = newJObject()
  var valid_611398 = query.getOrDefault("nextToken")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "nextToken", valid_611398
  var valid_611399 = query.getOrDefault("linkIds")
  valid_611399 = validateParameter(valid_611399, JArray, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "linkIds", valid_611399
  var valid_611400 = query.getOrDefault("MaxResults")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "MaxResults", valid_611400
  var valid_611401 = query.getOrDefault("NextToken")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "NextToken", valid_611401
  var valid_611402 = query.getOrDefault("type")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "type", valid_611402
  var valid_611403 = query.getOrDefault("provider")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "provider", valid_611403
  var valid_611404 = query.getOrDefault("siteId")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "siteId", valid_611404
  var valid_611405 = query.getOrDefault("maxResults")
  valid_611405 = validateParameter(valid_611405, JInt, required = false, default = nil)
  if valid_611405 != nil:
    section.add "maxResults", valid_611405
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
  var valid_611406 = header.getOrDefault("X-Amz-Signature")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Signature", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Content-Sha256", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Date")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Date", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Credential")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Credential", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Security-Token")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Security-Token", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Algorithm")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Algorithm", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-SignedHeaders", valid_611412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611413: Call_GetLinks_611394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about one or more links in a specified global network.</p> <p>If you specify the site ID, you cannot specify the type or provider in the same request. You can specify the type and provider in the same request.</p>
  ## 
  let valid = call_611413.validator(path, query, header, formData, body)
  let scheme = call_611413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611413.url(scheme.get, call_611413.host, call_611413.base,
                         call_611413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611413, url, valid)

proc call*(call_611414: Call_GetLinks_611394; globalNetworkId: string;
          nextToken: string = ""; linkIds: JsonNode = nil; MaxResults: string = "";
          NextToken: string = ""; `type`: string = ""; provider: string = "";
          siteId: string = ""; maxResults: int = 0): Recallable =
  ## getLinks
  ## <p>Gets information about one or more links in a specified global network.</p> <p>If you specify the site ID, you cannot specify the type or provider in the same request. You can specify the type and provider in the same request.</p>
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   linkIds: JArray
  ##          : One or more link IDs. The maximum is 10.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   type: string
  ##       : The link type.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   provider: string
  ##           : The link provider.
  ##   siteId: string
  ##         : The ID of the site.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  var path_611415 = newJObject()
  var query_611416 = newJObject()
  add(query_611416, "nextToken", newJString(nextToken))
  if linkIds != nil:
    query_611416.add "linkIds", linkIds
  add(query_611416, "MaxResults", newJString(MaxResults))
  add(query_611416, "NextToken", newJString(NextToken))
  add(query_611416, "type", newJString(`type`))
  add(path_611415, "globalNetworkId", newJString(globalNetworkId))
  add(query_611416, "provider", newJString(provider))
  add(query_611416, "siteId", newJString(siteId))
  add(query_611416, "maxResults", newJInt(maxResults))
  result = call_611414.call(path_611415, query_611416, nil, nil, nil)

var getLinks* = Call_GetLinks_611394(name: "getLinks", meth: HttpMethod.HttpGet,
                                  host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                  validator: validate_GetLinks_611395, base: "/",
                                  url: url_GetLinks_611396,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSite_611453 = ref object of OpenApiRestCall_610658
proc url_CreateSite_611455(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/sites")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSite_611454(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new site in a global network.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611456 = path.getOrDefault("globalNetworkId")
  valid_611456 = validateParameter(valid_611456, JString, required = true,
                                 default = nil)
  if valid_611456 != nil:
    section.add "globalNetworkId", valid_611456
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
  var valid_611457 = header.getOrDefault("X-Amz-Signature")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Signature", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Content-Sha256", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Date")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Date", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Credential")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Credential", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-Security-Token")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Security-Token", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-Algorithm")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Algorithm", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-SignedHeaders", valid_611463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611465: Call_CreateSite_611453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new site in a global network.
  ## 
  let valid = call_611465.validator(path, query, header, formData, body)
  let scheme = call_611465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611465.url(scheme.get, call_611465.host, call_611465.base,
                         call_611465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611465, url, valid)

proc call*(call_611466: Call_CreateSite_611453; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createSite
  ## Creates a new site in a global network.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_611467 = newJObject()
  var body_611468 = newJObject()
  add(path_611467, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_611468 = body
  result = call_611466.call(path_611467, nil, nil, nil, body_611468)

var createSite* = Call_CreateSite_611453(name: "createSite",
                                      meth: HttpMethod.HttpPost,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                      validator: validate_CreateSite_611454,
                                      base: "/", url: url_CreateSite_611455,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSites_611433 = ref object of OpenApiRestCall_610658
proc url_GetSites_611435(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/sites")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSites_611434(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more of your sites in a global network.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611436 = path.getOrDefault("globalNetworkId")
  valid_611436 = validateParameter(valid_611436, JString, required = true,
                                 default = nil)
  if valid_611436 != nil:
    section.add "globalNetworkId", valid_611436
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   siteIds: JArray
  ##          : One or more site IDs. The maximum is 10.
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  section = newJObject()
  var valid_611437 = query.getOrDefault("nextToken")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "nextToken", valid_611437
  var valid_611438 = query.getOrDefault("MaxResults")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "MaxResults", valid_611438
  var valid_611439 = query.getOrDefault("NextToken")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "NextToken", valid_611439
  var valid_611440 = query.getOrDefault("siteIds")
  valid_611440 = validateParameter(valid_611440, JArray, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "siteIds", valid_611440
  var valid_611441 = query.getOrDefault("maxResults")
  valid_611441 = validateParameter(valid_611441, JInt, required = false, default = nil)
  if valid_611441 != nil:
    section.add "maxResults", valid_611441
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
  var valid_611442 = header.getOrDefault("X-Amz-Signature")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-Signature", valid_611442
  var valid_611443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Content-Sha256", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Date")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Date", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Credential")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Credential", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Security-Token")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Security-Token", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Algorithm")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Algorithm", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-SignedHeaders", valid_611448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611449: Call_GetSites_611433; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more of your sites in a global network.
  ## 
  let valid = call_611449.validator(path, query, header, formData, body)
  let scheme = call_611449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611449.url(scheme.get, call_611449.host, call_611449.base,
                         call_611449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611449, url, valid)

proc call*(call_611450: Call_GetSites_611433; globalNetworkId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          siteIds: JsonNode = nil; maxResults: int = 0): Recallable =
  ## getSites
  ## Gets information about one or more of your sites in a global network.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   siteIds: JArray
  ##          : One or more site IDs. The maximum is 10.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  var path_611451 = newJObject()
  var query_611452 = newJObject()
  add(query_611452, "nextToken", newJString(nextToken))
  add(query_611452, "MaxResults", newJString(MaxResults))
  add(query_611452, "NextToken", newJString(NextToken))
  add(path_611451, "globalNetworkId", newJString(globalNetworkId))
  if siteIds != nil:
    query_611452.add "siteIds", siteIds
  add(query_611452, "maxResults", newJInt(maxResults))
  result = call_611450.call(path_611451, query_611452, nil, nil, nil)

var getSites* = Call_GetSites_611433(name: "getSites", meth: HttpMethod.HttpGet,
                                  host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                  validator: validate_GetSites_611434, base: "/",
                                  url: url_GetSites_611435,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_611484 = ref object of OpenApiRestCall_610658
proc url_UpdateDevice_611486(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  assert "deviceId" in path, "`deviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/devices/"),
               (kind: VariableSegment, value: "deviceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDevice_611485(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  ##   deviceId: JString (required)
  ##           : The ID of the device.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611487 = path.getOrDefault("globalNetworkId")
  valid_611487 = validateParameter(valid_611487, JString, required = true,
                                 default = nil)
  if valid_611487 != nil:
    section.add "globalNetworkId", valid_611487
  var valid_611488 = path.getOrDefault("deviceId")
  valid_611488 = validateParameter(valid_611488, JString, required = true,
                                 default = nil)
  if valid_611488 != nil:
    section.add "deviceId", valid_611488
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
  var valid_611489 = header.getOrDefault("X-Amz-Signature")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Signature", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Content-Sha256", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-Date")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-Date", valid_611491
  var valid_611492 = header.getOrDefault("X-Amz-Credential")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-Credential", valid_611492
  var valid_611493 = header.getOrDefault("X-Amz-Security-Token")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-Security-Token", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Algorithm")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Algorithm", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-SignedHeaders", valid_611495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611497: Call_UpdateDevice_611484; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_611497.validator(path, query, header, formData, body)
  let scheme = call_611497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611497.url(scheme.get, call_611497.host, call_611497.base,
                         call_611497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611497, url, valid)

proc call*(call_611498: Call_UpdateDevice_611484; globalNetworkId: string;
          body: JsonNode; deviceId: string): Recallable =
  ## updateDevice
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  ##   deviceId: string (required)
  ##           : The ID of the device.
  var path_611499 = newJObject()
  var body_611500 = newJObject()
  add(path_611499, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_611500 = body
  add(path_611499, "deviceId", newJString(deviceId))
  result = call_611498.call(path_611499, nil, nil, nil, body_611500)

var updateDevice* = Call_UpdateDevice_611484(name: "updateDevice",
    meth: HttpMethod.HttpPatch, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_UpdateDevice_611485, base: "/", url: url_UpdateDevice_611486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_611469 = ref object of OpenApiRestCall_610658
proc url_DeleteDevice_611471(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  assert "deviceId" in path, "`deviceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/devices/"),
               (kind: VariableSegment, value: "deviceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDevice_611470(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  ##   deviceId: JString (required)
  ##           : The ID of the device.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611472 = path.getOrDefault("globalNetworkId")
  valid_611472 = validateParameter(valid_611472, JString, required = true,
                                 default = nil)
  if valid_611472 != nil:
    section.add "globalNetworkId", valid_611472
  var valid_611473 = path.getOrDefault("deviceId")
  valid_611473 = validateParameter(valid_611473, JString, required = true,
                                 default = nil)
  if valid_611473 != nil:
    section.add "deviceId", valid_611473
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
  var valid_611474 = header.getOrDefault("X-Amz-Signature")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Signature", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Content-Sha256", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Date")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Date", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Credential")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Credential", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Security-Token")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Security-Token", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Algorithm")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Algorithm", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-SignedHeaders", valid_611480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611481: Call_DeleteDevice_611469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ## 
  let valid = call_611481.validator(path, query, header, formData, body)
  let scheme = call_611481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611481.url(scheme.get, call_611481.host, call_611481.base,
                         call_611481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611481, url, valid)

proc call*(call_611482: Call_DeleteDevice_611469; globalNetworkId: string;
          deviceId: string): Recallable =
  ## deleteDevice
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  var path_611483 = newJObject()
  add(path_611483, "globalNetworkId", newJString(globalNetworkId))
  add(path_611483, "deviceId", newJString(deviceId))
  result = call_611482.call(path_611483, nil, nil, nil, nil)

var deleteDevice* = Call_DeleteDevice_611469(name: "deleteDevice",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_DeleteDevice_611470, base: "/", url: url_DeleteDevice_611471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalNetwork_611515 = ref object of OpenApiRestCall_610658
proc url_UpdateGlobalNetwork_611517(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGlobalNetwork_611516(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of your global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611518 = path.getOrDefault("globalNetworkId")
  valid_611518 = validateParameter(valid_611518, JString, required = true,
                                 default = nil)
  if valid_611518 != nil:
    section.add "globalNetworkId", valid_611518
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
  var valid_611519 = header.getOrDefault("X-Amz-Signature")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Signature", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Content-Sha256", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Date")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Date", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Credential")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Credential", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-Security-Token")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Security-Token", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Algorithm")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Algorithm", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-SignedHeaders", valid_611525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611527: Call_UpdateGlobalNetwork_611515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_611527.validator(path, query, header, formData, body)
  let scheme = call_611527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611527.url(scheme.get, call_611527.host, call_611527.base,
                         call_611527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611527, url, valid)

proc call*(call_611528: Call_UpdateGlobalNetwork_611515; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## updateGlobalNetwork
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ##   globalNetworkId: string (required)
  ##                  : The ID of your global network.
  ##   body: JObject (required)
  var path_611529 = newJObject()
  var body_611530 = newJObject()
  add(path_611529, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_611530 = body
  result = call_611528.call(path_611529, nil, nil, nil, body_611530)

var updateGlobalNetwork* = Call_UpdateGlobalNetwork_611515(
    name: "updateGlobalNetwork", meth: HttpMethod.HttpPatch,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_UpdateGlobalNetwork_611516, base: "/",
    url: url_UpdateGlobalNetwork_611517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGlobalNetwork_611501 = ref object of OpenApiRestCall_610658
proc url_DeleteGlobalNetwork_611503(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGlobalNetwork_611502(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611504 = path.getOrDefault("globalNetworkId")
  valid_611504 = validateParameter(valid_611504, JString, required = true,
                                 default = nil)
  if valid_611504 != nil:
    section.add "globalNetworkId", valid_611504
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
  var valid_611505 = header.getOrDefault("X-Amz-Signature")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Signature", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Content-Sha256", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Date")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Date", valid_611507
  var valid_611508 = header.getOrDefault("X-Amz-Credential")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Credential", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Security-Token")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Security-Token", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Algorithm")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Algorithm", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-SignedHeaders", valid_611511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611512: Call_DeleteGlobalNetwork_611501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ## 
  let valid = call_611512.validator(path, query, header, formData, body)
  let scheme = call_611512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611512.url(scheme.get, call_611512.host, call_611512.base,
                         call_611512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611512, url, valid)

proc call*(call_611513: Call_DeleteGlobalNetwork_611501; globalNetworkId: string): Recallable =
  ## deleteGlobalNetwork
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_611514 = newJObject()
  add(path_611514, "globalNetworkId", newJString(globalNetworkId))
  result = call_611513.call(path_611514, nil, nil, nil, nil)

var deleteGlobalNetwork* = Call_DeleteGlobalNetwork_611501(
    name: "deleteGlobalNetwork", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_DeleteGlobalNetwork_611502, base: "/",
    url: url_DeleteGlobalNetwork_611503, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLink_611546 = ref object of OpenApiRestCall_610658
proc url_UpdateLink_611548(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  assert "linkId" in path, "`linkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/links/"),
               (kind: VariableSegment, value: "linkId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateLink_611547(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   linkId: JString (required)
  ##         : The ID of the link.
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `linkId` field"
  var valid_611549 = path.getOrDefault("linkId")
  valid_611549 = validateParameter(valid_611549, JString, required = true,
                                 default = nil)
  if valid_611549 != nil:
    section.add "linkId", valid_611549
  var valid_611550 = path.getOrDefault("globalNetworkId")
  valid_611550 = validateParameter(valid_611550, JString, required = true,
                                 default = nil)
  if valid_611550 != nil:
    section.add "globalNetworkId", valid_611550
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
  var valid_611551 = header.getOrDefault("X-Amz-Signature")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Signature", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Content-Sha256", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Date")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Date", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Credential")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Credential", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Security-Token")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Security-Token", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Algorithm")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Algorithm", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-SignedHeaders", valid_611557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611559: Call_UpdateLink_611546; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_611559.validator(path, query, header, formData, body)
  let scheme = call_611559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611559.url(scheme.get, call_611559.host, call_611559.base,
                         call_611559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611559, url, valid)

proc call*(call_611560: Call_UpdateLink_611546; linkId: string;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateLink
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ##   linkId: string (required)
  ##         : The ID of the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_611561 = newJObject()
  var body_611562 = newJObject()
  add(path_611561, "linkId", newJString(linkId))
  add(path_611561, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_611562 = body
  result = call_611560.call(path_611561, nil, nil, nil, body_611562)

var updateLink* = Call_UpdateLink_611546(name: "updateLink",
                                      meth: HttpMethod.HttpPatch,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links/{linkId}",
                                      validator: validate_UpdateLink_611547,
                                      base: "/", url: url_UpdateLink_611548,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLink_611531 = ref object of OpenApiRestCall_610658
proc url_DeleteLink_611533(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  assert "linkId" in path, "`linkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/links/"),
               (kind: VariableSegment, value: "linkId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLink_611532(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   linkId: JString (required)
  ##         : The ID of the link.
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `linkId` field"
  var valid_611534 = path.getOrDefault("linkId")
  valid_611534 = validateParameter(valid_611534, JString, required = true,
                                 default = nil)
  if valid_611534 != nil:
    section.add "linkId", valid_611534
  var valid_611535 = path.getOrDefault("globalNetworkId")
  valid_611535 = validateParameter(valid_611535, JString, required = true,
                                 default = nil)
  if valid_611535 != nil:
    section.add "globalNetworkId", valid_611535
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
  var valid_611536 = header.getOrDefault("X-Amz-Signature")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Signature", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Content-Sha256", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-Date")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Date", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Credential")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Credential", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Security-Token")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Security-Token", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Algorithm")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Algorithm", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-SignedHeaders", valid_611542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611543: Call_DeleteLink_611531; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ## 
  let valid = call_611543.validator(path, query, header, formData, body)
  let scheme = call_611543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611543.url(scheme.get, call_611543.host, call_611543.base,
                         call_611543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611543, url, valid)

proc call*(call_611544: Call_DeleteLink_611531; linkId: string;
          globalNetworkId: string): Recallable =
  ## deleteLink
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ##   linkId: string (required)
  ##         : The ID of the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_611545 = newJObject()
  add(path_611545, "linkId", newJString(linkId))
  add(path_611545, "globalNetworkId", newJString(globalNetworkId))
  result = call_611544.call(path_611545, nil, nil, nil, nil)

var deleteLink* = Call_DeleteLink_611531(name: "deleteLink",
                                      meth: HttpMethod.HttpDelete,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links/{linkId}",
                                      validator: validate_DeleteLink_611532,
                                      base: "/", url: url_DeleteLink_611533,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSite_611578 = ref object of OpenApiRestCall_610658
proc url_UpdateSite_611580(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  assert "siteId" in path, "`siteId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/sites/"),
               (kind: VariableSegment, value: "siteId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateSite_611579(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   siteId: JString (required)
  ##         : The ID of your site.
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `siteId` field"
  var valid_611581 = path.getOrDefault("siteId")
  valid_611581 = validateParameter(valid_611581, JString, required = true,
                                 default = nil)
  if valid_611581 != nil:
    section.add "siteId", valid_611581
  var valid_611582 = path.getOrDefault("globalNetworkId")
  valid_611582 = validateParameter(valid_611582, JString, required = true,
                                 default = nil)
  if valid_611582 != nil:
    section.add "globalNetworkId", valid_611582
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
  var valid_611583 = header.getOrDefault("X-Amz-Signature")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Signature", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Content-Sha256", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Date")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Date", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Credential")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Credential", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Security-Token")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Security-Token", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Algorithm")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Algorithm", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-SignedHeaders", valid_611589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611591: Call_UpdateSite_611578; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_611591.validator(path, query, header, formData, body)
  let scheme = call_611591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611591.url(scheme.get, call_611591.host, call_611591.base,
                         call_611591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611591, url, valid)

proc call*(call_611592: Call_UpdateSite_611578; siteId: string;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateSite
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ##   siteId: string (required)
  ##         : The ID of your site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_611593 = newJObject()
  var body_611594 = newJObject()
  add(path_611593, "siteId", newJString(siteId))
  add(path_611593, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_611594 = body
  result = call_611592.call(path_611593, nil, nil, nil, body_611594)

var updateSite* = Call_UpdateSite_611578(name: "updateSite",
                                      meth: HttpMethod.HttpPatch,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites/{siteId}",
                                      validator: validate_UpdateSite_611579,
                                      base: "/", url: url_UpdateSite_611580,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSite_611563 = ref object of OpenApiRestCall_610658
proc url_DeleteSite_611565(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  assert "siteId" in path, "`siteId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/sites/"),
               (kind: VariableSegment, value: "siteId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSite_611564(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   siteId: JString (required)
  ##         : The ID of the site.
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `siteId` field"
  var valid_611566 = path.getOrDefault("siteId")
  valid_611566 = validateParameter(valid_611566, JString, required = true,
                                 default = nil)
  if valid_611566 != nil:
    section.add "siteId", valid_611566
  var valid_611567 = path.getOrDefault("globalNetworkId")
  valid_611567 = validateParameter(valid_611567, JString, required = true,
                                 default = nil)
  if valid_611567 != nil:
    section.add "globalNetworkId", valid_611567
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
  var valid_611568 = header.getOrDefault("X-Amz-Signature")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Signature", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Content-Sha256", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Date")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Date", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Credential")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Credential", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Security-Token")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Security-Token", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Algorithm")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Algorithm", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-SignedHeaders", valid_611574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611575: Call_DeleteSite_611563; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ## 
  let valid = call_611575.validator(path, query, header, formData, body)
  let scheme = call_611575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611575.url(scheme.get, call_611575.host, call_611575.base,
                         call_611575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611575, url, valid)

proc call*(call_611576: Call_DeleteSite_611563; siteId: string;
          globalNetworkId: string): Recallable =
  ## deleteSite
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ##   siteId: string (required)
  ##         : The ID of the site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_611577 = newJObject()
  add(path_611577, "siteId", newJString(siteId))
  add(path_611577, "globalNetworkId", newJString(globalNetworkId))
  result = call_611576.call(path_611577, nil, nil, nil, nil)

var deleteSite* = Call_DeleteSite_611563(name: "deleteSite",
                                      meth: HttpMethod.HttpDelete,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites/{siteId}",
                                      validator: validate_DeleteSite_611564,
                                      base: "/", url: url_DeleteSite_611565,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTransitGateway_611595 = ref object of OpenApiRestCall_610658
proc url_DeregisterTransitGateway_611597(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  assert "transitGatewayArn" in path,
        "`transitGatewayArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"), (
        kind: ConstantSegment, value: "/transit-gateway-registrations/"),
               (kind: VariableSegment, value: "transitGatewayArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeregisterTransitGateway_611596(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  ##   transitGatewayArn: JString (required)
  ##                    : The Amazon Resource Name (ARN) of the transit gateway.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611598 = path.getOrDefault("globalNetworkId")
  valid_611598 = validateParameter(valid_611598, JString, required = true,
                                 default = nil)
  if valid_611598 != nil:
    section.add "globalNetworkId", valid_611598
  var valid_611599 = path.getOrDefault("transitGatewayArn")
  valid_611599 = validateParameter(valid_611599, JString, required = true,
                                 default = nil)
  if valid_611599 != nil:
    section.add "transitGatewayArn", valid_611599
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
  var valid_611600 = header.getOrDefault("X-Amz-Signature")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Signature", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Content-Sha256", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Date")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Date", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Credential")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Credential", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Security-Token")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Security-Token", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Algorithm")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Algorithm", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-SignedHeaders", valid_611606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611607: Call_DeregisterTransitGateway_611595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ## 
  let valid = call_611607.validator(path, query, header, formData, body)
  let scheme = call_611607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611607.url(scheme.get, call_611607.host, call_611607.base,
                         call_611607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611607, url, valid)

proc call*(call_611608: Call_DeregisterTransitGateway_611595;
          globalNetworkId: string; transitGatewayArn: string): Recallable =
  ## deregisterTransitGateway
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   transitGatewayArn: string (required)
  ##                    : The Amazon Resource Name (ARN) of the transit gateway.
  var path_611609 = newJObject()
  add(path_611609, "globalNetworkId", newJString(globalNetworkId))
  add(path_611609, "transitGatewayArn", newJString(transitGatewayArn))
  result = call_611608.call(path_611609, nil, nil, nil, nil)

var deregisterTransitGateway* = Call_DeregisterTransitGateway_611595(
    name: "deregisterTransitGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/transit-gateway-registrations/{transitGatewayArn}",
    validator: validate_DeregisterTransitGateway_611596, base: "/",
    url: url_DeregisterTransitGateway_611597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCustomerGateway_611610 = ref object of OpenApiRestCall_610658
proc url_DisassociateCustomerGateway_611612(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  assert "customerGatewayArn" in path,
        "`customerGatewayArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"), (
        kind: ConstantSegment, value: "/customer-gateway-associations/"),
               (kind: VariableSegment, value: "customerGatewayArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateCustomerGateway_611611(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates a customer gateway from a device and a link.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  ##   customerGatewayArn: JString (required)
  ##                     : The Amazon Resource Name (ARN) of the customer gateway. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources Defined by Amazon EC2</a>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611613 = path.getOrDefault("globalNetworkId")
  valid_611613 = validateParameter(valid_611613, JString, required = true,
                                 default = nil)
  if valid_611613 != nil:
    section.add "globalNetworkId", valid_611613
  var valid_611614 = path.getOrDefault("customerGatewayArn")
  valid_611614 = validateParameter(valid_611614, JString, required = true,
                                 default = nil)
  if valid_611614 != nil:
    section.add "customerGatewayArn", valid_611614
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
  var valid_611615 = header.getOrDefault("X-Amz-Signature")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Signature", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Content-Sha256", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Date")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Date", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Credential")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Credential", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Security-Token")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Security-Token", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-Algorithm")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Algorithm", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-SignedHeaders", valid_611621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611622: Call_DisassociateCustomerGateway_611610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a customer gateway from a device and a link.
  ## 
  let valid = call_611622.validator(path, query, header, formData, body)
  let scheme = call_611622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611622.url(scheme.get, call_611622.host, call_611622.base,
                         call_611622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611622, url, valid)

proc call*(call_611623: Call_DisassociateCustomerGateway_611610;
          globalNetworkId: string; customerGatewayArn: string): Recallable =
  ## disassociateCustomerGateway
  ## Disassociates a customer gateway from a device and a link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   customerGatewayArn: string (required)
  ##                     : The Amazon Resource Name (ARN) of the customer gateway. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources Defined by Amazon EC2</a>.
  var path_611624 = newJObject()
  add(path_611624, "globalNetworkId", newJString(globalNetworkId))
  add(path_611624, "customerGatewayArn", newJString(customerGatewayArn))
  result = call_611623.call(path_611624, nil, nil, nil, nil)

var disassociateCustomerGateway* = Call_DisassociateCustomerGateway_611610(
    name: "disassociateCustomerGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/customer-gateway-associations/{customerGatewayArn}",
    validator: validate_DisassociateCustomerGateway_611611, base: "/",
    url: url_DisassociateCustomerGateway_611612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateLink_611625 = ref object of OpenApiRestCall_610658
proc url_DisassociateLink_611627(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"), (
        kind: ConstantSegment, value: "/link-associations#deviceId&linkId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateLink_611626(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611628 = path.getOrDefault("globalNetworkId")
  valid_611628 = validateParameter(valid_611628, JString, required = true,
                                 default = nil)
  if valid_611628 != nil:
    section.add "globalNetworkId", valid_611628
  result.add "path", section
  ## parameters in `query` object:
  ##   deviceId: JString (required)
  ##           : The ID of the device.
  ##   linkId: JString (required)
  ##         : The ID of the link.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `deviceId` field"
  var valid_611629 = query.getOrDefault("deviceId")
  valid_611629 = validateParameter(valid_611629, JString, required = true,
                                 default = nil)
  if valid_611629 != nil:
    section.add "deviceId", valid_611629
  var valid_611630 = query.getOrDefault("linkId")
  valid_611630 = validateParameter(valid_611630, JString, required = true,
                                 default = nil)
  if valid_611630 != nil:
    section.add "linkId", valid_611630
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
  var valid_611631 = header.getOrDefault("X-Amz-Signature")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Signature", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Content-Sha256", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Date")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Date", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Credential")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Credential", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Security-Token")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Security-Token", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Algorithm")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Algorithm", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-SignedHeaders", valid_611637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611638: Call_DisassociateLink_611625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ## 
  let valid = call_611638.validator(path, query, header, formData, body)
  let scheme = call_611638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611638.url(scheme.get, call_611638.host, call_611638.base,
                         call_611638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611638, url, valid)

proc call*(call_611639: Call_DisassociateLink_611625; globalNetworkId: string;
          deviceId: string; linkId: string): Recallable =
  ## disassociateLink
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  ##   linkId: string (required)
  ##         : The ID of the link.
  var path_611640 = newJObject()
  var query_611641 = newJObject()
  add(path_611640, "globalNetworkId", newJString(globalNetworkId))
  add(query_611641, "deviceId", newJString(deviceId))
  add(query_611641, "linkId", newJString(linkId))
  result = call_611639.call(path_611640, query_611641, nil, nil, nil)

var disassociateLink* = Call_DisassociateLink_611625(name: "disassociateLink",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/link-associations#deviceId&linkId",
    validator: validate_DisassociateLink_611626, base: "/",
    url: url_DisassociateLink_611627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTransitGateway_611662 = ref object of OpenApiRestCall_610658
proc url_RegisterTransitGateway_611664(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/transit-gateway-registrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegisterTransitGateway_611663(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611665 = path.getOrDefault("globalNetworkId")
  valid_611665 = validateParameter(valid_611665, JString, required = true,
                                 default = nil)
  if valid_611665 != nil:
    section.add "globalNetworkId", valid_611665
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
  var valid_611666 = header.getOrDefault("X-Amz-Signature")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Signature", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Content-Sha256", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Date")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Date", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-Credential")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Credential", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Security-Token")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Security-Token", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Algorithm")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Algorithm", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-SignedHeaders", valid_611672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611674: Call_RegisterTransitGateway_611662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ## 
  let valid = call_611674.validator(path, query, header, formData, body)
  let scheme = call_611674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611674.url(scheme.get, call_611674.host, call_611674.base,
                         call_611674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611674, url, valid)

proc call*(call_611675: Call_RegisterTransitGateway_611662;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## registerTransitGateway
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_611676 = newJObject()
  var body_611677 = newJObject()
  add(path_611676, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_611677 = body
  result = call_611675.call(path_611676, nil, nil, nil, body_611677)

var registerTransitGateway* = Call_RegisterTransitGateway_611662(
    name: "registerTransitGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_RegisterTransitGateway_611663, base: "/",
    url: url_RegisterTransitGateway_611664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTransitGatewayRegistrations_611642 = ref object of OpenApiRestCall_610658
proc url_GetTransitGatewayRegistrations_611644(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path, "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
               (kind: VariableSegment, value: "globalNetworkId"),
               (kind: ConstantSegment, value: "/transit-gateway-registrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTransitGatewayRegistrations_611643(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the transit gateway registrations in a specified global network.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_611645 = path.getOrDefault("globalNetworkId")
  valid_611645 = validateParameter(valid_611645, JString, required = true,
                                 default = nil)
  if valid_611645 != nil:
    section.add "globalNetworkId", valid_611645
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   transitGatewayArns: JArray
  ##                     : The Amazon Resource Names (ARNs) of one or more transit gateways. The maximum is 10.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  section = newJObject()
  var valid_611646 = query.getOrDefault("nextToken")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "nextToken", valid_611646
  var valid_611647 = query.getOrDefault("MaxResults")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "MaxResults", valid_611647
  var valid_611648 = query.getOrDefault("transitGatewayArns")
  valid_611648 = validateParameter(valid_611648, JArray, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "transitGatewayArns", valid_611648
  var valid_611649 = query.getOrDefault("NextToken")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "NextToken", valid_611649
  var valid_611650 = query.getOrDefault("maxResults")
  valid_611650 = validateParameter(valid_611650, JInt, required = false, default = nil)
  if valid_611650 != nil:
    section.add "maxResults", valid_611650
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
  var valid_611651 = header.getOrDefault("X-Amz-Signature")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Signature", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Content-Sha256", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Date")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Date", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-Credential")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Credential", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-Security-Token")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-Security-Token", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-Algorithm")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Algorithm", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-SignedHeaders", valid_611657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611658: Call_GetTransitGatewayRegistrations_611642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the transit gateway registrations in a specified global network.
  ## 
  let valid = call_611658.validator(path, query, header, formData, body)
  let scheme = call_611658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611658.url(scheme.get, call_611658.host, call_611658.base,
                         call_611658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611658, url, valid)

proc call*(call_611659: Call_GetTransitGatewayRegistrations_611642;
          globalNetworkId: string; nextToken: string = ""; MaxResults: string = "";
          transitGatewayArns: JsonNode = nil; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## getTransitGatewayRegistrations
  ## Gets information about the transit gateway registrations in a specified global network.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   transitGatewayArns: JArray
  ##                     : The Amazon Resource Names (ARNs) of one or more transit gateways. The maximum is 10.
  ##   NextToken: string
  ##            : Pagination token
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  var path_611660 = newJObject()
  var query_611661 = newJObject()
  add(query_611661, "nextToken", newJString(nextToken))
  add(query_611661, "MaxResults", newJString(MaxResults))
  if transitGatewayArns != nil:
    query_611661.add "transitGatewayArns", transitGatewayArns
  add(query_611661, "NextToken", newJString(NextToken))
  add(path_611660, "globalNetworkId", newJString(globalNetworkId))
  add(query_611661, "maxResults", newJInt(maxResults))
  result = call_611659.call(path_611660, query_611661, nil, nil, nil)

var getTransitGatewayRegistrations* = Call_GetTransitGatewayRegistrations_611642(
    name: "getTransitGatewayRegistrations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_GetTransitGatewayRegistrations_611643, base: "/",
    url: url_GetTransitGatewayRegistrations_611644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611692 = ref object of OpenApiRestCall_610658
proc url_TagResource_611694(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_611693(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Tags a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611695 = path.getOrDefault("resourceArn")
  valid_611695 = validateParameter(valid_611695, JString, required = true,
                                 default = nil)
  if valid_611695 != nil:
    section.add "resourceArn", valid_611695
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
  var valid_611696 = header.getOrDefault("X-Amz-Signature")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Signature", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Content-Sha256", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-Date")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-Date", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-Credential")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-Credential", valid_611699
  var valid_611700 = header.getOrDefault("X-Amz-Security-Token")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-Security-Token", valid_611700
  var valid_611701 = header.getOrDefault("X-Amz-Algorithm")
  valid_611701 = validateParameter(valid_611701, JString, required = false,
                                 default = nil)
  if valid_611701 != nil:
    section.add "X-Amz-Algorithm", valid_611701
  var valid_611702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-SignedHeaders", valid_611702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611704: Call_TagResource_611692; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags a specified resource.
  ## 
  let valid = call_611704.validator(path, query, header, formData, body)
  let scheme = call_611704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611704.url(scheme.get, call_611704.host, call_611704.base,
                         call_611704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611704, url, valid)

proc call*(call_611705: Call_TagResource_611692; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tags a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_611706 = newJObject()
  var body_611707 = newJObject()
  add(path_611706, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_611707 = body
  result = call_611705.call(path_611706, nil, nil, nil, body_611707)

var tagResource* = Call_TagResource_611692(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "networkmanager.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_611693,
                                        base: "/", url: url_TagResource_611694,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611678 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611680(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_611679(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags for a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611681 = path.getOrDefault("resourceArn")
  valid_611681 = validateParameter(valid_611681, JString, required = true,
                                 default = nil)
  if valid_611681 != nil:
    section.add "resourceArn", valid_611681
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
  var valid_611682 = header.getOrDefault("X-Amz-Signature")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Signature", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Content-Sha256", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Date")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Date", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-Credential")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Credential", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Security-Token")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Security-Token", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-Algorithm")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-Algorithm", valid_611687
  var valid_611688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611688 = validateParameter(valid_611688, JString, required = false,
                                 default = nil)
  if valid_611688 != nil:
    section.add "X-Amz-SignedHeaders", valid_611688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611689: Call_ListTagsForResource_611678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for a specified resource.
  ## 
  let valid = call_611689.validator(path, query, header, formData, body)
  let scheme = call_611689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611689.url(scheme.get, call_611689.host, call_611689.base,
                         call_611689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611689, url, valid)

proc call*(call_611690: Call_ListTagsForResource_611678; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_611691 = newJObject()
  add(path_611691, "resourceArn", newJString(resourceArn))
  result = call_611690.call(path_611691, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611678(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_611679, base: "/",
    url: url_ListTagsForResource_611680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611708 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611710(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_611709(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags from a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611711 = path.getOrDefault("resourceArn")
  valid_611711 = validateParameter(valid_611711, JString, required = true,
                                 default = nil)
  if valid_611711 != nil:
    section.add "resourceArn", valid_611711
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the specified resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611712 = query.getOrDefault("tagKeys")
  valid_611712 = validateParameter(valid_611712, JArray, required = true, default = nil)
  if valid_611712 != nil:
    section.add "tagKeys", valid_611712
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
  var valid_611713 = header.getOrDefault("X-Amz-Signature")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Signature", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Content-Sha256", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-Date")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-Date", valid_611715
  var valid_611716 = header.getOrDefault("X-Amz-Credential")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-Credential", valid_611716
  var valid_611717 = header.getOrDefault("X-Amz-Security-Token")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-Security-Token", valid_611717
  var valid_611718 = header.getOrDefault("X-Amz-Algorithm")
  valid_611718 = validateParameter(valid_611718, JString, required = false,
                                 default = nil)
  if valid_611718 != nil:
    section.add "X-Amz-Algorithm", valid_611718
  var valid_611719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-SignedHeaders", valid_611719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611720: Call_UntagResource_611708; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a specified resource.
  ## 
  let valid = call_611720.validator(path, query, header, formData, body)
  let scheme = call_611720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611720.url(scheme.get, call_611720.host, call_611720.base,
                         call_611720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611720, url, valid)

proc call*(call_611721: Call_UntagResource_611708; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the specified resource.
  var path_611722 = newJObject()
  var query_611723 = newJObject()
  add(path_611722, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_611723.add "tagKeys", tagKeys
  result = call_611721.call(path_611722, query_611723, nil, nil, nil)

var untagResource* = Call_UntagResource_611708(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_611709,
    base: "/", url: url_UntagResource_611710, schemes: {Scheme.Https, Scheme.Http})
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
