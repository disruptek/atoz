
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_AssociateCustomerGateway_613272 = ref object of OpenApiRestCall_612658
proc url_AssociateCustomerGateway_613274(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateCustomerGateway_613273(path: JsonNode; query: JsonNode;
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
  var valid_613275 = path.getOrDefault("globalNetworkId")
  valid_613275 = validateParameter(valid_613275, JString, required = true,
                                 default = nil)
  if valid_613275 != nil:
    section.add "globalNetworkId", valid_613275
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
  var valid_613276 = header.getOrDefault("X-Amz-Signature")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Signature", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Content-Sha256", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Date")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Date", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Credential")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Credential", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Security-Token")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Security-Token", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-Algorithm")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-Algorithm", valid_613281
  var valid_613282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-SignedHeaders", valid_613282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613284: Call_AssociateCustomerGateway_613272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ## 
  let valid = call_613284.validator(path, query, header, formData, body)
  let scheme = call_613284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613284.url(scheme.get, call_613284.host, call_613284.base,
                         call_613284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613284, url, valid)

proc call*(call_613285: Call_AssociateCustomerGateway_613272;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## associateCustomerGateway
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_613286 = newJObject()
  var body_613287 = newJObject()
  add(path_613286, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_613287 = body
  result = call_613285.call(path_613286, nil, nil, nil, body_613287)

var associateCustomerGateway* = Call_AssociateCustomerGateway_613272(
    name: "associateCustomerGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_AssociateCustomerGateway_613273, base: "/",
    url: url_AssociateCustomerGateway_613274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCustomerGatewayAssociations_612996 = ref object of OpenApiRestCall_612658
proc url_GetCustomerGatewayAssociations_612998(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCustomerGatewayAssociations_612997(path: JsonNode;
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
  var valid_613124 = path.getOrDefault("globalNetworkId")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "globalNetworkId", valid_613124
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
  var valid_613125 = query.getOrDefault("nextToken")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "nextToken", valid_613125
  var valid_613126 = query.getOrDefault("MaxResults")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "MaxResults", valid_613126
  var valid_613127 = query.getOrDefault("NextToken")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "NextToken", valid_613127
  var valid_613128 = query.getOrDefault("customerGatewayArns")
  valid_613128 = validateParameter(valid_613128, JArray, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "customerGatewayArns", valid_613128
  var valid_613129 = query.getOrDefault("maxResults")
  valid_613129 = validateParameter(valid_613129, JInt, required = false, default = nil)
  if valid_613129 != nil:
    section.add "maxResults", valid_613129
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
  var valid_613130 = header.getOrDefault("X-Amz-Signature")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Signature", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Content-Sha256", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-Date")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-Date", valid_613132
  var valid_613133 = header.getOrDefault("X-Amz-Credential")
  valid_613133 = validateParameter(valid_613133, JString, required = false,
                                 default = nil)
  if valid_613133 != nil:
    section.add "X-Amz-Credential", valid_613133
  var valid_613134 = header.getOrDefault("X-Amz-Security-Token")
  valid_613134 = validateParameter(valid_613134, JString, required = false,
                                 default = nil)
  if valid_613134 != nil:
    section.add "X-Amz-Security-Token", valid_613134
  var valid_613135 = header.getOrDefault("X-Amz-Algorithm")
  valid_613135 = validateParameter(valid_613135, JString, required = false,
                                 default = nil)
  if valid_613135 != nil:
    section.add "X-Amz-Algorithm", valid_613135
  var valid_613136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613136 = validateParameter(valid_613136, JString, required = false,
                                 default = nil)
  if valid_613136 != nil:
    section.add "X-Amz-SignedHeaders", valid_613136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613159: Call_GetCustomerGatewayAssociations_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the association information for customer gateways that are associated with devices and links in your global network.
  ## 
  let valid = call_613159.validator(path, query, header, formData, body)
  let scheme = call_613159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613159.url(scheme.get, call_613159.host, call_613159.base,
                         call_613159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613159, url, valid)

proc call*(call_613230: Call_GetCustomerGatewayAssociations_612996;
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
  var path_613231 = newJObject()
  var query_613233 = newJObject()
  add(query_613233, "nextToken", newJString(nextToken))
  add(query_613233, "MaxResults", newJString(MaxResults))
  add(query_613233, "NextToken", newJString(NextToken))
  add(path_613231, "globalNetworkId", newJString(globalNetworkId))
  if customerGatewayArns != nil:
    query_613233.add "customerGatewayArns", customerGatewayArns
  add(query_613233, "maxResults", newJInt(maxResults))
  result = call_613230.call(path_613231, query_613233, nil, nil, nil)

var getCustomerGatewayAssociations* = Call_GetCustomerGatewayAssociations_612996(
    name: "getCustomerGatewayAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_GetCustomerGatewayAssociations_612997, base: "/",
    url: url_GetCustomerGatewayAssociations_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateLink_613309 = ref object of OpenApiRestCall_612658
proc url_AssociateLink_613311(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateLink_613310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613312 = path.getOrDefault("globalNetworkId")
  valid_613312 = validateParameter(valid_613312, JString, required = true,
                                 default = nil)
  if valid_613312 != nil:
    section.add "globalNetworkId", valid_613312
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
  var valid_613313 = header.getOrDefault("X-Amz-Signature")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Signature", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Content-Sha256", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Date")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Date", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Credential")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Credential", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Security-Token")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Security-Token", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Algorithm")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Algorithm", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-SignedHeaders", valid_613319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613321: Call_AssociateLink_613309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ## 
  let valid = call_613321.validator(path, query, header, formData, body)
  let scheme = call_613321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613321.url(scheme.get, call_613321.host, call_613321.base,
                         call_613321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613321, url, valid)

proc call*(call_613322: Call_AssociateLink_613309; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## associateLink
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_613323 = newJObject()
  var body_613324 = newJObject()
  add(path_613323, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_613324 = body
  result = call_613322.call(path_613323, nil, nil, nil, body_613324)

var associateLink* = Call_AssociateLink_613309(name: "associateLink",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_AssociateLink_613310, base: "/", url: url_AssociateLink_613311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAssociations_613288 = ref object of OpenApiRestCall_612658
proc url_GetLinkAssociations_613290(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLinkAssociations_613289(path: JsonNode; query: JsonNode;
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
  var valid_613291 = path.getOrDefault("globalNetworkId")
  valid_613291 = validateParameter(valid_613291, JString, required = true,
                                 default = nil)
  if valid_613291 != nil:
    section.add "globalNetworkId", valid_613291
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
  var valid_613292 = query.getOrDefault("nextToken")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "nextToken", valid_613292
  var valid_613293 = query.getOrDefault("MaxResults")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "MaxResults", valid_613293
  var valid_613294 = query.getOrDefault("NextToken")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "NextToken", valid_613294
  var valid_613295 = query.getOrDefault("deviceId")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "deviceId", valid_613295
  var valid_613296 = query.getOrDefault("linkId")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "linkId", valid_613296
  var valid_613297 = query.getOrDefault("maxResults")
  valid_613297 = validateParameter(valid_613297, JInt, required = false, default = nil)
  if valid_613297 != nil:
    section.add "maxResults", valid_613297
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
  var valid_613298 = header.getOrDefault("X-Amz-Signature")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Signature", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Content-Sha256", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Date")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Date", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Credential")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Credential", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Security-Token")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Security-Token", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Algorithm")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Algorithm", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-SignedHeaders", valid_613304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613305: Call_GetLinkAssociations_613288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the link associations for a device or a link. Either the device ID or the link ID must be specified.
  ## 
  let valid = call_613305.validator(path, query, header, formData, body)
  let scheme = call_613305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613305.url(scheme.get, call_613305.host, call_613305.base,
                         call_613305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613305, url, valid)

proc call*(call_613306: Call_GetLinkAssociations_613288; globalNetworkId: string;
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
  var path_613307 = newJObject()
  var query_613308 = newJObject()
  add(query_613308, "nextToken", newJString(nextToken))
  add(query_613308, "MaxResults", newJString(MaxResults))
  add(query_613308, "NextToken", newJString(NextToken))
  add(path_613307, "globalNetworkId", newJString(globalNetworkId))
  add(query_613308, "deviceId", newJString(deviceId))
  add(query_613308, "linkId", newJString(linkId))
  add(query_613308, "maxResults", newJInt(maxResults))
  result = call_613306.call(path_613307, query_613308, nil, nil, nil)

var getLinkAssociations* = Call_GetLinkAssociations_613288(
    name: "getLinkAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_GetLinkAssociations_613289, base: "/",
    url: url_GetLinkAssociations_613290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevice_613346 = ref object of OpenApiRestCall_612658
proc url_CreateDevice_613348(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDevice_613347(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613349 = path.getOrDefault("globalNetworkId")
  valid_613349 = validateParameter(valid_613349, JString, required = true,
                                 default = nil)
  if valid_613349 != nil:
    section.add "globalNetworkId", valid_613349
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
  var valid_613350 = header.getOrDefault("X-Amz-Signature")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Signature", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Content-Sha256", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Date")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Date", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Credential")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Credential", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Security-Token")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Security-Token", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Algorithm")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Algorithm", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-SignedHeaders", valid_613356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613358: Call_CreateDevice_613346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ## 
  let valid = call_613358.validator(path, query, header, formData, body)
  let scheme = call_613358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613358.url(scheme.get, call_613358.host, call_613358.base,
                         call_613358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613358, url, valid)

proc call*(call_613359: Call_CreateDevice_613346; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createDevice
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_613360 = newJObject()
  var body_613361 = newJObject()
  add(path_613360, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_613361 = body
  result = call_613359.call(path_613360, nil, nil, nil, body_613361)

var createDevice* = Call_CreateDevice_613346(name: "createDevice",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices",
    validator: validate_CreateDevice_613347, base: "/", url: url_CreateDevice_613348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevices_613325 = ref object of OpenApiRestCall_612658
proc url_GetDevices_613327(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDevices_613326(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613328 = path.getOrDefault("globalNetworkId")
  valid_613328 = validateParameter(valid_613328, JString, required = true,
                                 default = nil)
  if valid_613328 != nil:
    section.add "globalNetworkId", valid_613328
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
  var valid_613329 = query.getOrDefault("nextToken")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "nextToken", valid_613329
  var valid_613330 = query.getOrDefault("MaxResults")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "MaxResults", valid_613330
  var valid_613331 = query.getOrDefault("deviceIds")
  valid_613331 = validateParameter(valid_613331, JArray, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "deviceIds", valid_613331
  var valid_613332 = query.getOrDefault("NextToken")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "NextToken", valid_613332
  var valid_613333 = query.getOrDefault("siteId")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "siteId", valid_613333
  var valid_613334 = query.getOrDefault("maxResults")
  valid_613334 = validateParameter(valid_613334, JInt, required = false, default = nil)
  if valid_613334 != nil:
    section.add "maxResults", valid_613334
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
  var valid_613335 = header.getOrDefault("X-Amz-Signature")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Signature", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Content-Sha256", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Date")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Date", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Credential")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Credential", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Security-Token")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Security-Token", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Algorithm")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Algorithm", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-SignedHeaders", valid_613341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613342: Call_GetDevices_613325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more of your devices in a global network.
  ## 
  let valid = call_613342.validator(path, query, header, formData, body)
  let scheme = call_613342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613342.url(scheme.get, call_613342.host, call_613342.base,
                         call_613342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613342, url, valid)

proc call*(call_613343: Call_GetDevices_613325; globalNetworkId: string;
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
  var path_613344 = newJObject()
  var query_613345 = newJObject()
  add(query_613345, "nextToken", newJString(nextToken))
  add(query_613345, "MaxResults", newJString(MaxResults))
  if deviceIds != nil:
    query_613345.add "deviceIds", deviceIds
  add(query_613345, "NextToken", newJString(NextToken))
  add(path_613344, "globalNetworkId", newJString(globalNetworkId))
  add(query_613345, "siteId", newJString(siteId))
  add(query_613345, "maxResults", newJInt(maxResults))
  result = call_613343.call(path_613344, query_613345, nil, nil, nil)

var getDevices* = Call_GetDevices_613325(name: "getDevices",
                                      meth: HttpMethod.HttpGet,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/devices",
                                      validator: validate_GetDevices_613326,
                                      base: "/", url: url_GetDevices_613327,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGlobalNetwork_613380 = ref object of OpenApiRestCall_612658
proc url_CreateGlobalNetwork_613382(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGlobalNetwork_613381(path: JsonNode; query: JsonNode;
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
  var valid_613383 = header.getOrDefault("X-Amz-Signature")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Signature", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Content-Sha256", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-Date")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Date", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Credential")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Credential", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Security-Token")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Security-Token", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Algorithm")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Algorithm", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-SignedHeaders", valid_613389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613391: Call_CreateGlobalNetwork_613380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty global network.
  ## 
  let valid = call_613391.validator(path, query, header, formData, body)
  let scheme = call_613391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613391.url(scheme.get, call_613391.host, call_613391.base,
                         call_613391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613391, url, valid)

proc call*(call_613392: Call_CreateGlobalNetwork_613380; body: JsonNode): Recallable =
  ## createGlobalNetwork
  ## Creates a new, empty global network.
  ##   body: JObject (required)
  var body_613393 = newJObject()
  if body != nil:
    body_613393 = body
  result = call_613392.call(nil, nil, nil, nil, body_613393)

var createGlobalNetwork* = Call_CreateGlobalNetwork_613380(
    name: "createGlobalNetwork", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_CreateGlobalNetwork_613381, base: "/",
    url: url_CreateGlobalNetwork_613382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalNetworks_613362 = ref object of OpenApiRestCall_612658
proc url_DescribeGlobalNetworks_613364(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeGlobalNetworks_613363(path: JsonNode; query: JsonNode;
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
  var valid_613365 = query.getOrDefault("nextToken")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "nextToken", valid_613365
  var valid_613366 = query.getOrDefault("MaxResults")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "MaxResults", valid_613366
  var valid_613367 = query.getOrDefault("NextToken")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "NextToken", valid_613367
  var valid_613368 = query.getOrDefault("globalNetworkIds")
  valid_613368 = validateParameter(valid_613368, JArray, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "globalNetworkIds", valid_613368
  var valid_613369 = query.getOrDefault("maxResults")
  valid_613369 = validateParameter(valid_613369, JInt, required = false, default = nil)
  if valid_613369 != nil:
    section.add "maxResults", valid_613369
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
  var valid_613370 = header.getOrDefault("X-Amz-Signature")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Signature", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Content-Sha256", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Date")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Date", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Credential")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Credential", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Security-Token")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Security-Token", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Algorithm")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Algorithm", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-SignedHeaders", valid_613376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613377: Call_DescribeGlobalNetworks_613362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
  ## 
  let valid = call_613377.validator(path, query, header, formData, body)
  let scheme = call_613377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613377.url(scheme.get, call_613377.host, call_613377.base,
                         call_613377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613377, url, valid)

proc call*(call_613378: Call_DescribeGlobalNetworks_613362; nextToken: string = "";
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
  var query_613379 = newJObject()
  add(query_613379, "nextToken", newJString(nextToken))
  add(query_613379, "MaxResults", newJString(MaxResults))
  add(query_613379, "NextToken", newJString(NextToken))
  if globalNetworkIds != nil:
    query_613379.add "globalNetworkIds", globalNetworkIds
  add(query_613379, "maxResults", newJInt(maxResults))
  result = call_613378.call(nil, query_613379, nil, nil, nil)

var describeGlobalNetworks* = Call_DescribeGlobalNetworks_613362(
    name: "describeGlobalNetworks", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_DescribeGlobalNetworks_613363, base: "/",
    url: url_DescribeGlobalNetworks_613364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLink_613417 = ref object of OpenApiRestCall_612658
proc url_CreateLink_613419(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateLink_613418(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613420 = path.getOrDefault("globalNetworkId")
  valid_613420 = validateParameter(valid_613420, JString, required = true,
                                 default = nil)
  if valid_613420 != nil:
    section.add "globalNetworkId", valid_613420
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
  var valid_613421 = header.getOrDefault("X-Amz-Signature")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Signature", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Content-Sha256", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Date")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Date", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Credential")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Credential", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Security-Token")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Security-Token", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Algorithm")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Algorithm", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-SignedHeaders", valid_613427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613429: Call_CreateLink_613417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new link for a specified site.
  ## 
  let valid = call_613429.validator(path, query, header, formData, body)
  let scheme = call_613429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613429.url(scheme.get, call_613429.host, call_613429.base,
                         call_613429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613429, url, valid)

proc call*(call_613430: Call_CreateLink_613417; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createLink
  ## Creates a new link for a specified site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_613431 = newJObject()
  var body_613432 = newJObject()
  add(path_613431, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_613432 = body
  result = call_613430.call(path_613431, nil, nil, nil, body_613432)

var createLink* = Call_CreateLink_613417(name: "createLink",
                                      meth: HttpMethod.HttpPost,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                      validator: validate_CreateLink_613418,
                                      base: "/", url: url_CreateLink_613419,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinks_613394 = ref object of OpenApiRestCall_612658
proc url_GetLinks_613396(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLinks_613395(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613397 = path.getOrDefault("globalNetworkId")
  valid_613397 = validateParameter(valid_613397, JString, required = true,
                                 default = nil)
  if valid_613397 != nil:
    section.add "globalNetworkId", valid_613397
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
  var valid_613398 = query.getOrDefault("nextToken")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "nextToken", valid_613398
  var valid_613399 = query.getOrDefault("linkIds")
  valid_613399 = validateParameter(valid_613399, JArray, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "linkIds", valid_613399
  var valid_613400 = query.getOrDefault("MaxResults")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "MaxResults", valid_613400
  var valid_613401 = query.getOrDefault("NextToken")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "NextToken", valid_613401
  var valid_613402 = query.getOrDefault("type")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "type", valid_613402
  var valid_613403 = query.getOrDefault("provider")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "provider", valid_613403
  var valid_613404 = query.getOrDefault("siteId")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "siteId", valid_613404
  var valid_613405 = query.getOrDefault("maxResults")
  valid_613405 = validateParameter(valid_613405, JInt, required = false, default = nil)
  if valid_613405 != nil:
    section.add "maxResults", valid_613405
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
  var valid_613406 = header.getOrDefault("X-Amz-Signature")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Signature", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Content-Sha256", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Date")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Date", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Credential")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Credential", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Security-Token")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Security-Token", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Algorithm")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Algorithm", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-SignedHeaders", valid_613412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613413: Call_GetLinks_613394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about one or more links in a specified global network.</p> <p>If you specify the site ID, you cannot specify the type or provider in the same request. You can specify the type and provider in the same request.</p>
  ## 
  let valid = call_613413.validator(path, query, header, formData, body)
  let scheme = call_613413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613413.url(scheme.get, call_613413.host, call_613413.base,
                         call_613413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613413, url, valid)

proc call*(call_613414: Call_GetLinks_613394; globalNetworkId: string;
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
  var path_613415 = newJObject()
  var query_613416 = newJObject()
  add(query_613416, "nextToken", newJString(nextToken))
  if linkIds != nil:
    query_613416.add "linkIds", linkIds
  add(query_613416, "MaxResults", newJString(MaxResults))
  add(query_613416, "NextToken", newJString(NextToken))
  add(query_613416, "type", newJString(`type`))
  add(path_613415, "globalNetworkId", newJString(globalNetworkId))
  add(query_613416, "provider", newJString(provider))
  add(query_613416, "siteId", newJString(siteId))
  add(query_613416, "maxResults", newJInt(maxResults))
  result = call_613414.call(path_613415, query_613416, nil, nil, nil)

var getLinks* = Call_GetLinks_613394(name: "getLinks", meth: HttpMethod.HttpGet,
                                  host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                  validator: validate_GetLinks_613395, base: "/",
                                  url: url_GetLinks_613396,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSite_613453 = ref object of OpenApiRestCall_612658
proc url_CreateSite_613455(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSite_613454(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613456 = path.getOrDefault("globalNetworkId")
  valid_613456 = validateParameter(valid_613456, JString, required = true,
                                 default = nil)
  if valid_613456 != nil:
    section.add "globalNetworkId", valid_613456
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
  var valid_613457 = header.getOrDefault("X-Amz-Signature")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Signature", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Content-Sha256", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Date")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Date", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Credential")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Credential", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Security-Token")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Security-Token", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Algorithm")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Algorithm", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-SignedHeaders", valid_613463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613465: Call_CreateSite_613453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new site in a global network.
  ## 
  let valid = call_613465.validator(path, query, header, formData, body)
  let scheme = call_613465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613465.url(scheme.get, call_613465.host, call_613465.base,
                         call_613465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613465, url, valid)

proc call*(call_613466: Call_CreateSite_613453; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createSite
  ## Creates a new site in a global network.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_613467 = newJObject()
  var body_613468 = newJObject()
  add(path_613467, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_613468 = body
  result = call_613466.call(path_613467, nil, nil, nil, body_613468)

var createSite* = Call_CreateSite_613453(name: "createSite",
                                      meth: HttpMethod.HttpPost,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                      validator: validate_CreateSite_613454,
                                      base: "/", url: url_CreateSite_613455,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSites_613433 = ref object of OpenApiRestCall_612658
proc url_GetSites_613435(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSites_613434(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613436 = path.getOrDefault("globalNetworkId")
  valid_613436 = validateParameter(valid_613436, JString, required = true,
                                 default = nil)
  if valid_613436 != nil:
    section.add "globalNetworkId", valid_613436
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
  var valid_613437 = query.getOrDefault("nextToken")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "nextToken", valid_613437
  var valid_613438 = query.getOrDefault("MaxResults")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "MaxResults", valid_613438
  var valid_613439 = query.getOrDefault("NextToken")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "NextToken", valid_613439
  var valid_613440 = query.getOrDefault("siteIds")
  valid_613440 = validateParameter(valid_613440, JArray, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "siteIds", valid_613440
  var valid_613441 = query.getOrDefault("maxResults")
  valid_613441 = validateParameter(valid_613441, JInt, required = false, default = nil)
  if valid_613441 != nil:
    section.add "maxResults", valid_613441
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
  var valid_613442 = header.getOrDefault("X-Amz-Signature")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-Signature", valid_613442
  var valid_613443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Content-Sha256", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Date")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Date", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Credential")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Credential", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Security-Token")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Security-Token", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Algorithm")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Algorithm", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-SignedHeaders", valid_613448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613449: Call_GetSites_613433; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more of your sites in a global network.
  ## 
  let valid = call_613449.validator(path, query, header, formData, body)
  let scheme = call_613449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613449.url(scheme.get, call_613449.host, call_613449.base,
                         call_613449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613449, url, valid)

proc call*(call_613450: Call_GetSites_613433; globalNetworkId: string;
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
  var path_613451 = newJObject()
  var query_613452 = newJObject()
  add(query_613452, "nextToken", newJString(nextToken))
  add(query_613452, "MaxResults", newJString(MaxResults))
  add(query_613452, "NextToken", newJString(NextToken))
  add(path_613451, "globalNetworkId", newJString(globalNetworkId))
  if siteIds != nil:
    query_613452.add "siteIds", siteIds
  add(query_613452, "maxResults", newJInt(maxResults))
  result = call_613450.call(path_613451, query_613452, nil, nil, nil)

var getSites* = Call_GetSites_613433(name: "getSites", meth: HttpMethod.HttpGet,
                                  host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                  validator: validate_GetSites_613434, base: "/",
                                  url: url_GetSites_613435,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_613484 = ref object of OpenApiRestCall_612658
proc url_UpdateDevice_613486(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDevice_613485(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613487 = path.getOrDefault("globalNetworkId")
  valid_613487 = validateParameter(valid_613487, JString, required = true,
                                 default = nil)
  if valid_613487 != nil:
    section.add "globalNetworkId", valid_613487
  var valid_613488 = path.getOrDefault("deviceId")
  valid_613488 = validateParameter(valid_613488, JString, required = true,
                                 default = nil)
  if valid_613488 != nil:
    section.add "deviceId", valid_613488
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
  var valid_613489 = header.getOrDefault("X-Amz-Signature")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Signature", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Content-Sha256", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Date")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Date", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Credential")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Credential", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Security-Token")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Security-Token", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Algorithm")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Algorithm", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-SignedHeaders", valid_613495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613497: Call_UpdateDevice_613484; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_613497.validator(path, query, header, formData, body)
  let scheme = call_613497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613497.url(scheme.get, call_613497.host, call_613497.base,
                         call_613497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613497, url, valid)

proc call*(call_613498: Call_UpdateDevice_613484; globalNetworkId: string;
          body: JsonNode; deviceId: string): Recallable =
  ## updateDevice
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  ##   deviceId: string (required)
  ##           : The ID of the device.
  var path_613499 = newJObject()
  var body_613500 = newJObject()
  add(path_613499, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_613500 = body
  add(path_613499, "deviceId", newJString(deviceId))
  result = call_613498.call(path_613499, nil, nil, nil, body_613500)

var updateDevice* = Call_UpdateDevice_613484(name: "updateDevice",
    meth: HttpMethod.HttpPatch, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_UpdateDevice_613485, base: "/", url: url_UpdateDevice_613486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_613469 = ref object of OpenApiRestCall_612658
proc url_DeleteDevice_613471(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDevice_613470(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613472 = path.getOrDefault("globalNetworkId")
  valid_613472 = validateParameter(valid_613472, JString, required = true,
                                 default = nil)
  if valid_613472 != nil:
    section.add "globalNetworkId", valid_613472
  var valid_613473 = path.getOrDefault("deviceId")
  valid_613473 = validateParameter(valid_613473, JString, required = true,
                                 default = nil)
  if valid_613473 != nil:
    section.add "deviceId", valid_613473
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
  var valid_613474 = header.getOrDefault("X-Amz-Signature")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Signature", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Content-Sha256", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Date")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Date", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Credential")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Credential", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Security-Token")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Security-Token", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Algorithm")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Algorithm", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-SignedHeaders", valid_613480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613481: Call_DeleteDevice_613469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ## 
  let valid = call_613481.validator(path, query, header, formData, body)
  let scheme = call_613481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613481.url(scheme.get, call_613481.host, call_613481.base,
                         call_613481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613481, url, valid)

proc call*(call_613482: Call_DeleteDevice_613469; globalNetworkId: string;
          deviceId: string): Recallable =
  ## deleteDevice
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  var path_613483 = newJObject()
  add(path_613483, "globalNetworkId", newJString(globalNetworkId))
  add(path_613483, "deviceId", newJString(deviceId))
  result = call_613482.call(path_613483, nil, nil, nil, nil)

var deleteDevice* = Call_DeleteDevice_613469(name: "deleteDevice",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_DeleteDevice_613470, base: "/", url: url_DeleteDevice_613471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalNetwork_613515 = ref object of OpenApiRestCall_612658
proc url_UpdateGlobalNetwork_613517(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGlobalNetwork_613516(path: JsonNode; query: JsonNode;
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
  var valid_613518 = path.getOrDefault("globalNetworkId")
  valid_613518 = validateParameter(valid_613518, JString, required = true,
                                 default = nil)
  if valid_613518 != nil:
    section.add "globalNetworkId", valid_613518
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
  var valid_613519 = header.getOrDefault("X-Amz-Signature")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Signature", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Content-Sha256", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Date")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Date", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Credential")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Credential", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Security-Token")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Security-Token", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Algorithm")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Algorithm", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-SignedHeaders", valid_613525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613527: Call_UpdateGlobalNetwork_613515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_613527.validator(path, query, header, formData, body)
  let scheme = call_613527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613527.url(scheme.get, call_613527.host, call_613527.base,
                         call_613527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613527, url, valid)

proc call*(call_613528: Call_UpdateGlobalNetwork_613515; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## updateGlobalNetwork
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ##   globalNetworkId: string (required)
  ##                  : The ID of your global network.
  ##   body: JObject (required)
  var path_613529 = newJObject()
  var body_613530 = newJObject()
  add(path_613529, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_613530 = body
  result = call_613528.call(path_613529, nil, nil, nil, body_613530)

var updateGlobalNetwork* = Call_UpdateGlobalNetwork_613515(
    name: "updateGlobalNetwork", meth: HttpMethod.HttpPatch,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_UpdateGlobalNetwork_613516, base: "/",
    url: url_UpdateGlobalNetwork_613517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGlobalNetwork_613501 = ref object of OpenApiRestCall_612658
proc url_DeleteGlobalNetwork_613503(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGlobalNetwork_613502(path: JsonNode; query: JsonNode;
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
  var valid_613504 = path.getOrDefault("globalNetworkId")
  valid_613504 = validateParameter(valid_613504, JString, required = true,
                                 default = nil)
  if valid_613504 != nil:
    section.add "globalNetworkId", valid_613504
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
  var valid_613505 = header.getOrDefault("X-Amz-Signature")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Signature", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Content-Sha256", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Date")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Date", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-Credential")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Credential", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Security-Token")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Security-Token", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Algorithm")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Algorithm", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-SignedHeaders", valid_613511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613512: Call_DeleteGlobalNetwork_613501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ## 
  let valid = call_613512.validator(path, query, header, formData, body)
  let scheme = call_613512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613512.url(scheme.get, call_613512.host, call_613512.base,
                         call_613512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613512, url, valid)

proc call*(call_613513: Call_DeleteGlobalNetwork_613501; globalNetworkId: string): Recallable =
  ## deleteGlobalNetwork
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_613514 = newJObject()
  add(path_613514, "globalNetworkId", newJString(globalNetworkId))
  result = call_613513.call(path_613514, nil, nil, nil, nil)

var deleteGlobalNetwork* = Call_DeleteGlobalNetwork_613501(
    name: "deleteGlobalNetwork", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_DeleteGlobalNetwork_613502, base: "/",
    url: url_DeleteGlobalNetwork_613503, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLink_613546 = ref object of OpenApiRestCall_612658
proc url_UpdateLink_613548(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateLink_613547(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613549 = path.getOrDefault("linkId")
  valid_613549 = validateParameter(valid_613549, JString, required = true,
                                 default = nil)
  if valid_613549 != nil:
    section.add "linkId", valid_613549
  var valid_613550 = path.getOrDefault("globalNetworkId")
  valid_613550 = validateParameter(valid_613550, JString, required = true,
                                 default = nil)
  if valid_613550 != nil:
    section.add "globalNetworkId", valid_613550
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
  var valid_613551 = header.getOrDefault("X-Amz-Signature")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-Signature", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Content-Sha256", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Date")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Date", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Credential")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Credential", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Security-Token")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Security-Token", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Algorithm")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Algorithm", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-SignedHeaders", valid_613557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613559: Call_UpdateLink_613546; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_613559.validator(path, query, header, formData, body)
  let scheme = call_613559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613559.url(scheme.get, call_613559.host, call_613559.base,
                         call_613559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613559, url, valid)

proc call*(call_613560: Call_UpdateLink_613546; linkId: string;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateLink
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ##   linkId: string (required)
  ##         : The ID of the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_613561 = newJObject()
  var body_613562 = newJObject()
  add(path_613561, "linkId", newJString(linkId))
  add(path_613561, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_613562 = body
  result = call_613560.call(path_613561, nil, nil, nil, body_613562)

var updateLink* = Call_UpdateLink_613546(name: "updateLink",
                                      meth: HttpMethod.HttpPatch,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links/{linkId}",
                                      validator: validate_UpdateLink_613547,
                                      base: "/", url: url_UpdateLink_613548,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLink_613531 = ref object of OpenApiRestCall_612658
proc url_DeleteLink_613533(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLink_613532(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613534 = path.getOrDefault("linkId")
  valid_613534 = validateParameter(valid_613534, JString, required = true,
                                 default = nil)
  if valid_613534 != nil:
    section.add "linkId", valid_613534
  var valid_613535 = path.getOrDefault("globalNetworkId")
  valid_613535 = validateParameter(valid_613535, JString, required = true,
                                 default = nil)
  if valid_613535 != nil:
    section.add "globalNetworkId", valid_613535
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
  var valid_613536 = header.getOrDefault("X-Amz-Signature")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Signature", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Content-Sha256", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-Date")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Date", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Credential")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Credential", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Security-Token")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Security-Token", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Algorithm")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Algorithm", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-SignedHeaders", valid_613542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613543: Call_DeleteLink_613531; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ## 
  let valid = call_613543.validator(path, query, header, formData, body)
  let scheme = call_613543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613543.url(scheme.get, call_613543.host, call_613543.base,
                         call_613543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613543, url, valid)

proc call*(call_613544: Call_DeleteLink_613531; linkId: string;
          globalNetworkId: string): Recallable =
  ## deleteLink
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ##   linkId: string (required)
  ##         : The ID of the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_613545 = newJObject()
  add(path_613545, "linkId", newJString(linkId))
  add(path_613545, "globalNetworkId", newJString(globalNetworkId))
  result = call_613544.call(path_613545, nil, nil, nil, nil)

var deleteLink* = Call_DeleteLink_613531(name: "deleteLink",
                                      meth: HttpMethod.HttpDelete,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links/{linkId}",
                                      validator: validate_DeleteLink_613532,
                                      base: "/", url: url_DeleteLink_613533,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSite_613578 = ref object of OpenApiRestCall_612658
proc url_UpdateSite_613580(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateSite_613579(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613581 = path.getOrDefault("siteId")
  valid_613581 = validateParameter(valid_613581, JString, required = true,
                                 default = nil)
  if valid_613581 != nil:
    section.add "siteId", valid_613581
  var valid_613582 = path.getOrDefault("globalNetworkId")
  valid_613582 = validateParameter(valid_613582, JString, required = true,
                                 default = nil)
  if valid_613582 != nil:
    section.add "globalNetworkId", valid_613582
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
  var valid_613583 = header.getOrDefault("X-Amz-Signature")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Signature", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Content-Sha256", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Date")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Date", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Credential")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Credential", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Security-Token")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Security-Token", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Algorithm")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Algorithm", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-SignedHeaders", valid_613589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613591: Call_UpdateSite_613578; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_613591.validator(path, query, header, formData, body)
  let scheme = call_613591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613591.url(scheme.get, call_613591.host, call_613591.base,
                         call_613591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613591, url, valid)

proc call*(call_613592: Call_UpdateSite_613578; siteId: string;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateSite
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ##   siteId: string (required)
  ##         : The ID of your site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_613593 = newJObject()
  var body_613594 = newJObject()
  add(path_613593, "siteId", newJString(siteId))
  add(path_613593, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_613594 = body
  result = call_613592.call(path_613593, nil, nil, nil, body_613594)

var updateSite* = Call_UpdateSite_613578(name: "updateSite",
                                      meth: HttpMethod.HttpPatch,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites/{siteId}",
                                      validator: validate_UpdateSite_613579,
                                      base: "/", url: url_UpdateSite_613580,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSite_613563 = ref object of OpenApiRestCall_612658
proc url_DeleteSite_613565(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSite_613564(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613566 = path.getOrDefault("siteId")
  valid_613566 = validateParameter(valid_613566, JString, required = true,
                                 default = nil)
  if valid_613566 != nil:
    section.add "siteId", valid_613566
  var valid_613567 = path.getOrDefault("globalNetworkId")
  valid_613567 = validateParameter(valid_613567, JString, required = true,
                                 default = nil)
  if valid_613567 != nil:
    section.add "globalNetworkId", valid_613567
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
  var valid_613568 = header.getOrDefault("X-Amz-Signature")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Signature", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Content-Sha256", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Date")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Date", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Credential")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Credential", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Security-Token")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Security-Token", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Algorithm")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Algorithm", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-SignedHeaders", valid_613574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613575: Call_DeleteSite_613563; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ## 
  let valid = call_613575.validator(path, query, header, formData, body)
  let scheme = call_613575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613575.url(scheme.get, call_613575.host, call_613575.base,
                         call_613575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613575, url, valid)

proc call*(call_613576: Call_DeleteSite_613563; siteId: string;
          globalNetworkId: string): Recallable =
  ## deleteSite
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ##   siteId: string (required)
  ##         : The ID of the site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_613577 = newJObject()
  add(path_613577, "siteId", newJString(siteId))
  add(path_613577, "globalNetworkId", newJString(globalNetworkId))
  result = call_613576.call(path_613577, nil, nil, nil, nil)

var deleteSite* = Call_DeleteSite_613563(name: "deleteSite",
                                      meth: HttpMethod.HttpDelete,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites/{siteId}",
                                      validator: validate_DeleteSite_613564,
                                      base: "/", url: url_DeleteSite_613565,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTransitGateway_613595 = ref object of OpenApiRestCall_612658
proc url_DeregisterTransitGateway_613597(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeregisterTransitGateway_613596(path: JsonNode; query: JsonNode;
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
  var valid_613598 = path.getOrDefault("globalNetworkId")
  valid_613598 = validateParameter(valid_613598, JString, required = true,
                                 default = nil)
  if valid_613598 != nil:
    section.add "globalNetworkId", valid_613598
  var valid_613599 = path.getOrDefault("transitGatewayArn")
  valid_613599 = validateParameter(valid_613599, JString, required = true,
                                 default = nil)
  if valid_613599 != nil:
    section.add "transitGatewayArn", valid_613599
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
  var valid_613600 = header.getOrDefault("X-Amz-Signature")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Signature", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Content-Sha256", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Date")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Date", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Credential")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Credential", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Security-Token")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Security-Token", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Algorithm")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Algorithm", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-SignedHeaders", valid_613606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613607: Call_DeregisterTransitGateway_613595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ## 
  let valid = call_613607.validator(path, query, header, formData, body)
  let scheme = call_613607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613607.url(scheme.get, call_613607.host, call_613607.base,
                         call_613607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613607, url, valid)

proc call*(call_613608: Call_DeregisterTransitGateway_613595;
          globalNetworkId: string; transitGatewayArn: string): Recallable =
  ## deregisterTransitGateway
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   transitGatewayArn: string (required)
  ##                    : The Amazon Resource Name (ARN) of the transit gateway.
  var path_613609 = newJObject()
  add(path_613609, "globalNetworkId", newJString(globalNetworkId))
  add(path_613609, "transitGatewayArn", newJString(transitGatewayArn))
  result = call_613608.call(path_613609, nil, nil, nil, nil)

var deregisterTransitGateway* = Call_DeregisterTransitGateway_613595(
    name: "deregisterTransitGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/transit-gateway-registrations/{transitGatewayArn}",
    validator: validate_DeregisterTransitGateway_613596, base: "/",
    url: url_DeregisterTransitGateway_613597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCustomerGateway_613610 = ref object of OpenApiRestCall_612658
proc url_DisassociateCustomerGateway_613612(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateCustomerGateway_613611(path: JsonNode; query: JsonNode;
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
  var valid_613613 = path.getOrDefault("globalNetworkId")
  valid_613613 = validateParameter(valid_613613, JString, required = true,
                                 default = nil)
  if valid_613613 != nil:
    section.add "globalNetworkId", valid_613613
  var valid_613614 = path.getOrDefault("customerGatewayArn")
  valid_613614 = validateParameter(valid_613614, JString, required = true,
                                 default = nil)
  if valid_613614 != nil:
    section.add "customerGatewayArn", valid_613614
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
  var valid_613615 = header.getOrDefault("X-Amz-Signature")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Signature", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Content-Sha256", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Date")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Date", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Credential")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Credential", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Security-Token")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Security-Token", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Algorithm")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Algorithm", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-SignedHeaders", valid_613621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613622: Call_DisassociateCustomerGateway_613610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a customer gateway from a device and a link.
  ## 
  let valid = call_613622.validator(path, query, header, formData, body)
  let scheme = call_613622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613622.url(scheme.get, call_613622.host, call_613622.base,
                         call_613622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613622, url, valid)

proc call*(call_613623: Call_DisassociateCustomerGateway_613610;
          globalNetworkId: string; customerGatewayArn: string): Recallable =
  ## disassociateCustomerGateway
  ## Disassociates a customer gateway from a device and a link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   customerGatewayArn: string (required)
  ##                     : The Amazon Resource Name (ARN) of the customer gateway. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources Defined by Amazon EC2</a>.
  var path_613624 = newJObject()
  add(path_613624, "globalNetworkId", newJString(globalNetworkId))
  add(path_613624, "customerGatewayArn", newJString(customerGatewayArn))
  result = call_613623.call(path_613624, nil, nil, nil, nil)

var disassociateCustomerGateway* = Call_DisassociateCustomerGateway_613610(
    name: "disassociateCustomerGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/customer-gateway-associations/{customerGatewayArn}",
    validator: validate_DisassociateCustomerGateway_613611, base: "/",
    url: url_DisassociateCustomerGateway_613612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateLink_613625 = ref object of OpenApiRestCall_612658
proc url_DisassociateLink_613627(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateLink_613626(path: JsonNode; query: JsonNode;
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
  var valid_613628 = path.getOrDefault("globalNetworkId")
  valid_613628 = validateParameter(valid_613628, JString, required = true,
                                 default = nil)
  if valid_613628 != nil:
    section.add "globalNetworkId", valid_613628
  result.add "path", section
  ## parameters in `query` object:
  ##   deviceId: JString (required)
  ##           : The ID of the device.
  ##   linkId: JString (required)
  ##         : The ID of the link.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `deviceId` field"
  var valid_613629 = query.getOrDefault("deviceId")
  valid_613629 = validateParameter(valid_613629, JString, required = true,
                                 default = nil)
  if valid_613629 != nil:
    section.add "deviceId", valid_613629
  var valid_613630 = query.getOrDefault("linkId")
  valid_613630 = validateParameter(valid_613630, JString, required = true,
                                 default = nil)
  if valid_613630 != nil:
    section.add "linkId", valid_613630
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
  var valid_613631 = header.getOrDefault("X-Amz-Signature")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Signature", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Content-Sha256", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Date")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Date", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Credential")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Credential", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Security-Token")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Security-Token", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Algorithm")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Algorithm", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-SignedHeaders", valid_613637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613638: Call_DisassociateLink_613625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ## 
  let valid = call_613638.validator(path, query, header, formData, body)
  let scheme = call_613638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613638.url(scheme.get, call_613638.host, call_613638.base,
                         call_613638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613638, url, valid)

proc call*(call_613639: Call_DisassociateLink_613625; globalNetworkId: string;
          deviceId: string; linkId: string): Recallable =
  ## disassociateLink
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  ##   linkId: string (required)
  ##         : The ID of the link.
  var path_613640 = newJObject()
  var query_613641 = newJObject()
  add(path_613640, "globalNetworkId", newJString(globalNetworkId))
  add(query_613641, "deviceId", newJString(deviceId))
  add(query_613641, "linkId", newJString(linkId))
  result = call_613639.call(path_613640, query_613641, nil, nil, nil)

var disassociateLink* = Call_DisassociateLink_613625(name: "disassociateLink",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/link-associations#deviceId&linkId",
    validator: validate_DisassociateLink_613626, base: "/",
    url: url_DisassociateLink_613627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTransitGateway_613662 = ref object of OpenApiRestCall_612658
proc url_RegisterTransitGateway_613664(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegisterTransitGateway_613663(path: JsonNode; query: JsonNode;
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
  var valid_613665 = path.getOrDefault("globalNetworkId")
  valid_613665 = validateParameter(valid_613665, JString, required = true,
                                 default = nil)
  if valid_613665 != nil:
    section.add "globalNetworkId", valid_613665
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
  var valid_613666 = header.getOrDefault("X-Amz-Signature")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Signature", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Content-Sha256", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Date")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Date", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Credential")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Credential", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Security-Token")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Security-Token", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Algorithm")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Algorithm", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-SignedHeaders", valid_613672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613674: Call_RegisterTransitGateway_613662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ## 
  let valid = call_613674.validator(path, query, header, formData, body)
  let scheme = call_613674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613674.url(scheme.get, call_613674.host, call_613674.base,
                         call_613674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613674, url, valid)

proc call*(call_613675: Call_RegisterTransitGateway_613662;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## registerTransitGateway
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_613676 = newJObject()
  var body_613677 = newJObject()
  add(path_613676, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_613677 = body
  result = call_613675.call(path_613676, nil, nil, nil, body_613677)

var registerTransitGateway* = Call_RegisterTransitGateway_613662(
    name: "registerTransitGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_RegisterTransitGateway_613663, base: "/",
    url: url_RegisterTransitGateway_613664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTransitGatewayRegistrations_613642 = ref object of OpenApiRestCall_612658
proc url_GetTransitGatewayRegistrations_613644(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTransitGatewayRegistrations_613643(path: JsonNode;
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
  var valid_613645 = path.getOrDefault("globalNetworkId")
  valid_613645 = validateParameter(valid_613645, JString, required = true,
                                 default = nil)
  if valid_613645 != nil:
    section.add "globalNetworkId", valid_613645
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
  var valid_613646 = query.getOrDefault("nextToken")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "nextToken", valid_613646
  var valid_613647 = query.getOrDefault("MaxResults")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "MaxResults", valid_613647
  var valid_613648 = query.getOrDefault("transitGatewayArns")
  valid_613648 = validateParameter(valid_613648, JArray, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "transitGatewayArns", valid_613648
  var valid_613649 = query.getOrDefault("NextToken")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "NextToken", valid_613649
  var valid_613650 = query.getOrDefault("maxResults")
  valid_613650 = validateParameter(valid_613650, JInt, required = false, default = nil)
  if valid_613650 != nil:
    section.add "maxResults", valid_613650
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
  var valid_613651 = header.getOrDefault("X-Amz-Signature")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Signature", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Content-Sha256", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Date")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Date", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Credential")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Credential", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Security-Token")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Security-Token", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Algorithm")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Algorithm", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-SignedHeaders", valid_613657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613658: Call_GetTransitGatewayRegistrations_613642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the transit gateway registrations in a specified global network.
  ## 
  let valid = call_613658.validator(path, query, header, formData, body)
  let scheme = call_613658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613658.url(scheme.get, call_613658.host, call_613658.base,
                         call_613658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613658, url, valid)

proc call*(call_613659: Call_GetTransitGatewayRegistrations_613642;
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
  var path_613660 = newJObject()
  var query_613661 = newJObject()
  add(query_613661, "nextToken", newJString(nextToken))
  add(query_613661, "MaxResults", newJString(MaxResults))
  if transitGatewayArns != nil:
    query_613661.add "transitGatewayArns", transitGatewayArns
  add(query_613661, "NextToken", newJString(NextToken))
  add(path_613660, "globalNetworkId", newJString(globalNetworkId))
  add(query_613661, "maxResults", newJInt(maxResults))
  result = call_613659.call(path_613660, query_613661, nil, nil, nil)

var getTransitGatewayRegistrations* = Call_GetTransitGatewayRegistrations_613642(
    name: "getTransitGatewayRegistrations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_GetTransitGatewayRegistrations_613643, base: "/",
    url: url_GetTransitGatewayRegistrations_613644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613692 = ref object of OpenApiRestCall_612658
proc url_TagResource_613694(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_613693(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613695 = path.getOrDefault("resourceArn")
  valid_613695 = validateParameter(valid_613695, JString, required = true,
                                 default = nil)
  if valid_613695 != nil:
    section.add "resourceArn", valid_613695
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
  var valid_613696 = header.getOrDefault("X-Amz-Signature")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Signature", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Content-Sha256", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Date")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Date", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-Credential")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-Credential", valid_613699
  var valid_613700 = header.getOrDefault("X-Amz-Security-Token")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-Security-Token", valid_613700
  var valid_613701 = header.getOrDefault("X-Amz-Algorithm")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Algorithm", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-SignedHeaders", valid_613702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613704: Call_TagResource_613692; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags a specified resource.
  ## 
  let valid = call_613704.validator(path, query, header, formData, body)
  let scheme = call_613704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613704.url(scheme.get, call_613704.host, call_613704.base,
                         call_613704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613704, url, valid)

proc call*(call_613705: Call_TagResource_613692; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tags a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_613706 = newJObject()
  var body_613707 = newJObject()
  add(path_613706, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_613707 = body
  result = call_613705.call(path_613706, nil, nil, nil, body_613707)

var tagResource* = Call_TagResource_613692(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "networkmanager.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_613693,
                                        base: "/", url: url_TagResource_613694,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613678 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613680(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_613679(path: JsonNode; query: JsonNode;
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
  var valid_613681 = path.getOrDefault("resourceArn")
  valid_613681 = validateParameter(valid_613681, JString, required = true,
                                 default = nil)
  if valid_613681 != nil:
    section.add "resourceArn", valid_613681
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
  var valid_613682 = header.getOrDefault("X-Amz-Signature")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Signature", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Content-Sha256", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Date")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Date", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Credential")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Credential", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Security-Token")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Security-Token", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Algorithm")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Algorithm", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-SignedHeaders", valid_613688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613689: Call_ListTagsForResource_613678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for a specified resource.
  ## 
  let valid = call_613689.validator(path, query, header, formData, body)
  let scheme = call_613689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613689.url(scheme.get, call_613689.host, call_613689.base,
                         call_613689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613689, url, valid)

proc call*(call_613690: Call_ListTagsForResource_613678; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_613691 = newJObject()
  add(path_613691, "resourceArn", newJString(resourceArn))
  result = call_613690.call(path_613691, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613678(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_613679, base: "/",
    url: url_ListTagsForResource_613680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613708 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613710(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_613709(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613711 = path.getOrDefault("resourceArn")
  valid_613711 = validateParameter(valid_613711, JString, required = true,
                                 default = nil)
  if valid_613711 != nil:
    section.add "resourceArn", valid_613711
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the specified resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613712 = query.getOrDefault("tagKeys")
  valid_613712 = validateParameter(valid_613712, JArray, required = true, default = nil)
  if valid_613712 != nil:
    section.add "tagKeys", valid_613712
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
  var valid_613713 = header.getOrDefault("X-Amz-Signature")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Signature", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Content-Sha256", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-Date")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-Date", valid_613715
  var valid_613716 = header.getOrDefault("X-Amz-Credential")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-Credential", valid_613716
  var valid_613717 = header.getOrDefault("X-Amz-Security-Token")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Security-Token", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-Algorithm")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-Algorithm", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-SignedHeaders", valid_613719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613720: Call_UntagResource_613708; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a specified resource.
  ## 
  let valid = call_613720.validator(path, query, header, formData, body)
  let scheme = call_613720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613720.url(scheme.get, call_613720.host, call_613720.base,
                         call_613720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613720, url, valid)

proc call*(call_613721: Call_UntagResource_613708; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the specified resource.
  var path_613722 = newJObject()
  var query_613723 = newJObject()
  add(path_613722, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_613723.add "tagKeys", tagKeys
  result = call_613721.call(path_613722, query_613723, nil, nil, nil)

var untagResource* = Call_UntagResource_613708(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_613709,
    base: "/", url: url_UntagResource_613710, schemes: {Scheme.Https, Scheme.Http})
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
