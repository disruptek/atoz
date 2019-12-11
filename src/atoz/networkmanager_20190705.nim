
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  Call_AssociateCustomerGateway_598003 = ref object of OpenApiRestCall_597389
proc url_AssociateCustomerGateway_598005(protocol: Scheme; host: string;
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

proc validate_AssociateCustomerGateway_598004(path: JsonNode; query: JsonNode;
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
  var valid_598006 = path.getOrDefault("globalNetworkId")
  valid_598006 = validateParameter(valid_598006, JString, required = true,
                                 default = nil)
  if valid_598006 != nil:
    section.add "globalNetworkId", valid_598006
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
  var valid_598007 = header.getOrDefault("X-Amz-Signature")
  valid_598007 = validateParameter(valid_598007, JString, required = false,
                                 default = nil)
  if valid_598007 != nil:
    section.add "X-Amz-Signature", valid_598007
  var valid_598008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598008 = validateParameter(valid_598008, JString, required = false,
                                 default = nil)
  if valid_598008 != nil:
    section.add "X-Amz-Content-Sha256", valid_598008
  var valid_598009 = header.getOrDefault("X-Amz-Date")
  valid_598009 = validateParameter(valid_598009, JString, required = false,
                                 default = nil)
  if valid_598009 != nil:
    section.add "X-Amz-Date", valid_598009
  var valid_598010 = header.getOrDefault("X-Amz-Credential")
  valid_598010 = validateParameter(valid_598010, JString, required = false,
                                 default = nil)
  if valid_598010 != nil:
    section.add "X-Amz-Credential", valid_598010
  var valid_598011 = header.getOrDefault("X-Amz-Security-Token")
  valid_598011 = validateParameter(valid_598011, JString, required = false,
                                 default = nil)
  if valid_598011 != nil:
    section.add "X-Amz-Security-Token", valid_598011
  var valid_598012 = header.getOrDefault("X-Amz-Algorithm")
  valid_598012 = validateParameter(valid_598012, JString, required = false,
                                 default = nil)
  if valid_598012 != nil:
    section.add "X-Amz-Algorithm", valid_598012
  var valid_598013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598013 = validateParameter(valid_598013, JString, required = false,
                                 default = nil)
  if valid_598013 != nil:
    section.add "X-Amz-SignedHeaders", valid_598013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598015: Call_AssociateCustomerGateway_598003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ## 
  let valid = call_598015.validator(path, query, header, formData, body)
  let scheme = call_598015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598015.url(scheme.get, call_598015.host, call_598015.base,
                         call_598015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598015, url, valid)

proc call*(call_598016: Call_AssociateCustomerGateway_598003;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## associateCustomerGateway
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_598017 = newJObject()
  var body_598018 = newJObject()
  add(path_598017, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_598018 = body
  result = call_598016.call(path_598017, nil, nil, nil, body_598018)

var associateCustomerGateway* = Call_AssociateCustomerGateway_598003(
    name: "associateCustomerGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_AssociateCustomerGateway_598004, base: "/",
    url: url_AssociateCustomerGateway_598005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCustomerGatewayAssociations_597727 = ref object of OpenApiRestCall_597389
proc url_GetCustomerGatewayAssociations_597729(protocol: Scheme; host: string;
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

proc validate_GetCustomerGatewayAssociations_597728(path: JsonNode;
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
  var valid_597855 = path.getOrDefault("globalNetworkId")
  valid_597855 = validateParameter(valid_597855, JString, required = true,
                                 default = nil)
  if valid_597855 != nil:
    section.add "globalNetworkId", valid_597855
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
  var valid_597856 = query.getOrDefault("nextToken")
  valid_597856 = validateParameter(valid_597856, JString, required = false,
                                 default = nil)
  if valid_597856 != nil:
    section.add "nextToken", valid_597856
  var valid_597857 = query.getOrDefault("MaxResults")
  valid_597857 = validateParameter(valid_597857, JString, required = false,
                                 default = nil)
  if valid_597857 != nil:
    section.add "MaxResults", valid_597857
  var valid_597858 = query.getOrDefault("NextToken")
  valid_597858 = validateParameter(valid_597858, JString, required = false,
                                 default = nil)
  if valid_597858 != nil:
    section.add "NextToken", valid_597858
  var valid_597859 = query.getOrDefault("customerGatewayArns")
  valid_597859 = validateParameter(valid_597859, JArray, required = false,
                                 default = nil)
  if valid_597859 != nil:
    section.add "customerGatewayArns", valid_597859
  var valid_597860 = query.getOrDefault("maxResults")
  valid_597860 = validateParameter(valid_597860, JInt, required = false, default = nil)
  if valid_597860 != nil:
    section.add "maxResults", valid_597860
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
  var valid_597861 = header.getOrDefault("X-Amz-Signature")
  valid_597861 = validateParameter(valid_597861, JString, required = false,
                                 default = nil)
  if valid_597861 != nil:
    section.add "X-Amz-Signature", valid_597861
  var valid_597862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597862 = validateParameter(valid_597862, JString, required = false,
                                 default = nil)
  if valid_597862 != nil:
    section.add "X-Amz-Content-Sha256", valid_597862
  var valid_597863 = header.getOrDefault("X-Amz-Date")
  valid_597863 = validateParameter(valid_597863, JString, required = false,
                                 default = nil)
  if valid_597863 != nil:
    section.add "X-Amz-Date", valid_597863
  var valid_597864 = header.getOrDefault("X-Amz-Credential")
  valid_597864 = validateParameter(valid_597864, JString, required = false,
                                 default = nil)
  if valid_597864 != nil:
    section.add "X-Amz-Credential", valid_597864
  var valid_597865 = header.getOrDefault("X-Amz-Security-Token")
  valid_597865 = validateParameter(valid_597865, JString, required = false,
                                 default = nil)
  if valid_597865 != nil:
    section.add "X-Amz-Security-Token", valid_597865
  var valid_597866 = header.getOrDefault("X-Amz-Algorithm")
  valid_597866 = validateParameter(valid_597866, JString, required = false,
                                 default = nil)
  if valid_597866 != nil:
    section.add "X-Amz-Algorithm", valid_597866
  var valid_597867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597867 = validateParameter(valid_597867, JString, required = false,
                                 default = nil)
  if valid_597867 != nil:
    section.add "X-Amz-SignedHeaders", valid_597867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_597890: Call_GetCustomerGatewayAssociations_597727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the association information for customer gateways that are associated with devices and links in your global network.
  ## 
  let valid = call_597890.validator(path, query, header, formData, body)
  let scheme = call_597890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597890.url(scheme.get, call_597890.host, call_597890.base,
                         call_597890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597890, url, valid)

proc call*(call_597961: Call_GetCustomerGatewayAssociations_597727;
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
  var path_597962 = newJObject()
  var query_597964 = newJObject()
  add(query_597964, "nextToken", newJString(nextToken))
  add(query_597964, "MaxResults", newJString(MaxResults))
  add(query_597964, "NextToken", newJString(NextToken))
  add(path_597962, "globalNetworkId", newJString(globalNetworkId))
  if customerGatewayArns != nil:
    query_597964.add "customerGatewayArns", customerGatewayArns
  add(query_597964, "maxResults", newJInt(maxResults))
  result = call_597961.call(path_597962, query_597964, nil, nil, nil)

var getCustomerGatewayAssociations* = Call_GetCustomerGatewayAssociations_597727(
    name: "getCustomerGatewayAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_GetCustomerGatewayAssociations_597728, base: "/",
    url: url_GetCustomerGatewayAssociations_597729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateLink_598040 = ref object of OpenApiRestCall_597389
proc url_AssociateLink_598042(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateLink_598041(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598043 = path.getOrDefault("globalNetworkId")
  valid_598043 = validateParameter(valid_598043, JString, required = true,
                                 default = nil)
  if valid_598043 != nil:
    section.add "globalNetworkId", valid_598043
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
  var valid_598044 = header.getOrDefault("X-Amz-Signature")
  valid_598044 = validateParameter(valid_598044, JString, required = false,
                                 default = nil)
  if valid_598044 != nil:
    section.add "X-Amz-Signature", valid_598044
  var valid_598045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598045 = validateParameter(valid_598045, JString, required = false,
                                 default = nil)
  if valid_598045 != nil:
    section.add "X-Amz-Content-Sha256", valid_598045
  var valid_598046 = header.getOrDefault("X-Amz-Date")
  valid_598046 = validateParameter(valid_598046, JString, required = false,
                                 default = nil)
  if valid_598046 != nil:
    section.add "X-Amz-Date", valid_598046
  var valid_598047 = header.getOrDefault("X-Amz-Credential")
  valid_598047 = validateParameter(valid_598047, JString, required = false,
                                 default = nil)
  if valid_598047 != nil:
    section.add "X-Amz-Credential", valid_598047
  var valid_598048 = header.getOrDefault("X-Amz-Security-Token")
  valid_598048 = validateParameter(valid_598048, JString, required = false,
                                 default = nil)
  if valid_598048 != nil:
    section.add "X-Amz-Security-Token", valid_598048
  var valid_598049 = header.getOrDefault("X-Amz-Algorithm")
  valid_598049 = validateParameter(valid_598049, JString, required = false,
                                 default = nil)
  if valid_598049 != nil:
    section.add "X-Amz-Algorithm", valid_598049
  var valid_598050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-SignedHeaders", valid_598050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598052: Call_AssociateLink_598040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ## 
  let valid = call_598052.validator(path, query, header, formData, body)
  let scheme = call_598052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598052.url(scheme.get, call_598052.host, call_598052.base,
                         call_598052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598052, url, valid)

proc call*(call_598053: Call_AssociateLink_598040; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## associateLink
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_598054 = newJObject()
  var body_598055 = newJObject()
  add(path_598054, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_598055 = body
  result = call_598053.call(path_598054, nil, nil, nil, body_598055)

var associateLink* = Call_AssociateLink_598040(name: "associateLink",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_AssociateLink_598041, base: "/", url: url_AssociateLink_598042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAssociations_598019 = ref object of OpenApiRestCall_597389
proc url_GetLinkAssociations_598021(protocol: Scheme; host: string; base: string;
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

proc validate_GetLinkAssociations_598020(path: JsonNode; query: JsonNode;
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
  var valid_598022 = path.getOrDefault("globalNetworkId")
  valid_598022 = validateParameter(valid_598022, JString, required = true,
                                 default = nil)
  if valid_598022 != nil:
    section.add "globalNetworkId", valid_598022
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
  var valid_598023 = query.getOrDefault("nextToken")
  valid_598023 = validateParameter(valid_598023, JString, required = false,
                                 default = nil)
  if valid_598023 != nil:
    section.add "nextToken", valid_598023
  var valid_598024 = query.getOrDefault("MaxResults")
  valid_598024 = validateParameter(valid_598024, JString, required = false,
                                 default = nil)
  if valid_598024 != nil:
    section.add "MaxResults", valid_598024
  var valid_598025 = query.getOrDefault("NextToken")
  valid_598025 = validateParameter(valid_598025, JString, required = false,
                                 default = nil)
  if valid_598025 != nil:
    section.add "NextToken", valid_598025
  var valid_598026 = query.getOrDefault("deviceId")
  valid_598026 = validateParameter(valid_598026, JString, required = false,
                                 default = nil)
  if valid_598026 != nil:
    section.add "deviceId", valid_598026
  var valid_598027 = query.getOrDefault("linkId")
  valid_598027 = validateParameter(valid_598027, JString, required = false,
                                 default = nil)
  if valid_598027 != nil:
    section.add "linkId", valid_598027
  var valid_598028 = query.getOrDefault("maxResults")
  valid_598028 = validateParameter(valid_598028, JInt, required = false, default = nil)
  if valid_598028 != nil:
    section.add "maxResults", valid_598028
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
  var valid_598029 = header.getOrDefault("X-Amz-Signature")
  valid_598029 = validateParameter(valid_598029, JString, required = false,
                                 default = nil)
  if valid_598029 != nil:
    section.add "X-Amz-Signature", valid_598029
  var valid_598030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598030 = validateParameter(valid_598030, JString, required = false,
                                 default = nil)
  if valid_598030 != nil:
    section.add "X-Amz-Content-Sha256", valid_598030
  var valid_598031 = header.getOrDefault("X-Amz-Date")
  valid_598031 = validateParameter(valid_598031, JString, required = false,
                                 default = nil)
  if valid_598031 != nil:
    section.add "X-Amz-Date", valid_598031
  var valid_598032 = header.getOrDefault("X-Amz-Credential")
  valid_598032 = validateParameter(valid_598032, JString, required = false,
                                 default = nil)
  if valid_598032 != nil:
    section.add "X-Amz-Credential", valid_598032
  var valid_598033 = header.getOrDefault("X-Amz-Security-Token")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "X-Amz-Security-Token", valid_598033
  var valid_598034 = header.getOrDefault("X-Amz-Algorithm")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "X-Amz-Algorithm", valid_598034
  var valid_598035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-SignedHeaders", valid_598035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598036: Call_GetLinkAssociations_598019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the link associations for a device or a link. Either the device ID or the link ID must be specified.
  ## 
  let valid = call_598036.validator(path, query, header, formData, body)
  let scheme = call_598036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598036.url(scheme.get, call_598036.host, call_598036.base,
                         call_598036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598036, url, valid)

proc call*(call_598037: Call_GetLinkAssociations_598019; globalNetworkId: string;
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
  var path_598038 = newJObject()
  var query_598039 = newJObject()
  add(query_598039, "nextToken", newJString(nextToken))
  add(query_598039, "MaxResults", newJString(MaxResults))
  add(query_598039, "NextToken", newJString(NextToken))
  add(path_598038, "globalNetworkId", newJString(globalNetworkId))
  add(query_598039, "deviceId", newJString(deviceId))
  add(query_598039, "linkId", newJString(linkId))
  add(query_598039, "maxResults", newJInt(maxResults))
  result = call_598037.call(path_598038, query_598039, nil, nil, nil)

var getLinkAssociations* = Call_GetLinkAssociations_598019(
    name: "getLinkAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_GetLinkAssociations_598020, base: "/",
    url: url_GetLinkAssociations_598021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevice_598077 = ref object of OpenApiRestCall_597389
proc url_CreateDevice_598079(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDevice_598078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598080 = path.getOrDefault("globalNetworkId")
  valid_598080 = validateParameter(valid_598080, JString, required = true,
                                 default = nil)
  if valid_598080 != nil:
    section.add "globalNetworkId", valid_598080
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
  var valid_598081 = header.getOrDefault("X-Amz-Signature")
  valid_598081 = validateParameter(valid_598081, JString, required = false,
                                 default = nil)
  if valid_598081 != nil:
    section.add "X-Amz-Signature", valid_598081
  var valid_598082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598082 = validateParameter(valid_598082, JString, required = false,
                                 default = nil)
  if valid_598082 != nil:
    section.add "X-Amz-Content-Sha256", valid_598082
  var valid_598083 = header.getOrDefault("X-Amz-Date")
  valid_598083 = validateParameter(valid_598083, JString, required = false,
                                 default = nil)
  if valid_598083 != nil:
    section.add "X-Amz-Date", valid_598083
  var valid_598084 = header.getOrDefault("X-Amz-Credential")
  valid_598084 = validateParameter(valid_598084, JString, required = false,
                                 default = nil)
  if valid_598084 != nil:
    section.add "X-Amz-Credential", valid_598084
  var valid_598085 = header.getOrDefault("X-Amz-Security-Token")
  valid_598085 = validateParameter(valid_598085, JString, required = false,
                                 default = nil)
  if valid_598085 != nil:
    section.add "X-Amz-Security-Token", valid_598085
  var valid_598086 = header.getOrDefault("X-Amz-Algorithm")
  valid_598086 = validateParameter(valid_598086, JString, required = false,
                                 default = nil)
  if valid_598086 != nil:
    section.add "X-Amz-Algorithm", valid_598086
  var valid_598087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598087 = validateParameter(valid_598087, JString, required = false,
                                 default = nil)
  if valid_598087 != nil:
    section.add "X-Amz-SignedHeaders", valid_598087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598089: Call_CreateDevice_598077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ## 
  let valid = call_598089.validator(path, query, header, formData, body)
  let scheme = call_598089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598089.url(scheme.get, call_598089.host, call_598089.base,
                         call_598089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598089, url, valid)

proc call*(call_598090: Call_CreateDevice_598077; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createDevice
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_598091 = newJObject()
  var body_598092 = newJObject()
  add(path_598091, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_598092 = body
  result = call_598090.call(path_598091, nil, nil, nil, body_598092)

var createDevice* = Call_CreateDevice_598077(name: "createDevice",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices",
    validator: validate_CreateDevice_598078, base: "/", url: url_CreateDevice_598079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevices_598056 = ref object of OpenApiRestCall_597389
proc url_GetDevices_598058(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDevices_598057(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598059 = path.getOrDefault("globalNetworkId")
  valid_598059 = validateParameter(valid_598059, JString, required = true,
                                 default = nil)
  if valid_598059 != nil:
    section.add "globalNetworkId", valid_598059
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
  var valid_598060 = query.getOrDefault("nextToken")
  valid_598060 = validateParameter(valid_598060, JString, required = false,
                                 default = nil)
  if valid_598060 != nil:
    section.add "nextToken", valid_598060
  var valid_598061 = query.getOrDefault("MaxResults")
  valid_598061 = validateParameter(valid_598061, JString, required = false,
                                 default = nil)
  if valid_598061 != nil:
    section.add "MaxResults", valid_598061
  var valid_598062 = query.getOrDefault("deviceIds")
  valid_598062 = validateParameter(valid_598062, JArray, required = false,
                                 default = nil)
  if valid_598062 != nil:
    section.add "deviceIds", valid_598062
  var valid_598063 = query.getOrDefault("NextToken")
  valid_598063 = validateParameter(valid_598063, JString, required = false,
                                 default = nil)
  if valid_598063 != nil:
    section.add "NextToken", valid_598063
  var valid_598064 = query.getOrDefault("siteId")
  valid_598064 = validateParameter(valid_598064, JString, required = false,
                                 default = nil)
  if valid_598064 != nil:
    section.add "siteId", valid_598064
  var valid_598065 = query.getOrDefault("maxResults")
  valid_598065 = validateParameter(valid_598065, JInt, required = false, default = nil)
  if valid_598065 != nil:
    section.add "maxResults", valid_598065
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
  var valid_598066 = header.getOrDefault("X-Amz-Signature")
  valid_598066 = validateParameter(valid_598066, JString, required = false,
                                 default = nil)
  if valid_598066 != nil:
    section.add "X-Amz-Signature", valid_598066
  var valid_598067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598067 = validateParameter(valid_598067, JString, required = false,
                                 default = nil)
  if valid_598067 != nil:
    section.add "X-Amz-Content-Sha256", valid_598067
  var valid_598068 = header.getOrDefault("X-Amz-Date")
  valid_598068 = validateParameter(valid_598068, JString, required = false,
                                 default = nil)
  if valid_598068 != nil:
    section.add "X-Amz-Date", valid_598068
  var valid_598069 = header.getOrDefault("X-Amz-Credential")
  valid_598069 = validateParameter(valid_598069, JString, required = false,
                                 default = nil)
  if valid_598069 != nil:
    section.add "X-Amz-Credential", valid_598069
  var valid_598070 = header.getOrDefault("X-Amz-Security-Token")
  valid_598070 = validateParameter(valid_598070, JString, required = false,
                                 default = nil)
  if valid_598070 != nil:
    section.add "X-Amz-Security-Token", valid_598070
  var valid_598071 = header.getOrDefault("X-Amz-Algorithm")
  valid_598071 = validateParameter(valid_598071, JString, required = false,
                                 default = nil)
  if valid_598071 != nil:
    section.add "X-Amz-Algorithm", valid_598071
  var valid_598072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598072 = validateParameter(valid_598072, JString, required = false,
                                 default = nil)
  if valid_598072 != nil:
    section.add "X-Amz-SignedHeaders", valid_598072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598073: Call_GetDevices_598056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more of your devices in a global network.
  ## 
  let valid = call_598073.validator(path, query, header, formData, body)
  let scheme = call_598073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598073.url(scheme.get, call_598073.host, call_598073.base,
                         call_598073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598073, url, valid)

proc call*(call_598074: Call_GetDevices_598056; globalNetworkId: string;
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
  var path_598075 = newJObject()
  var query_598076 = newJObject()
  add(query_598076, "nextToken", newJString(nextToken))
  add(query_598076, "MaxResults", newJString(MaxResults))
  if deviceIds != nil:
    query_598076.add "deviceIds", deviceIds
  add(query_598076, "NextToken", newJString(NextToken))
  add(path_598075, "globalNetworkId", newJString(globalNetworkId))
  add(query_598076, "siteId", newJString(siteId))
  add(query_598076, "maxResults", newJInt(maxResults))
  result = call_598074.call(path_598075, query_598076, nil, nil, nil)

var getDevices* = Call_GetDevices_598056(name: "getDevices",
                                      meth: HttpMethod.HttpGet,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/devices",
                                      validator: validate_GetDevices_598057,
                                      base: "/", url: url_GetDevices_598058,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGlobalNetwork_598111 = ref object of OpenApiRestCall_597389
proc url_CreateGlobalNetwork_598113(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGlobalNetwork_598112(path: JsonNode; query: JsonNode;
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
  var valid_598114 = header.getOrDefault("X-Amz-Signature")
  valid_598114 = validateParameter(valid_598114, JString, required = false,
                                 default = nil)
  if valid_598114 != nil:
    section.add "X-Amz-Signature", valid_598114
  var valid_598115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598115 = validateParameter(valid_598115, JString, required = false,
                                 default = nil)
  if valid_598115 != nil:
    section.add "X-Amz-Content-Sha256", valid_598115
  var valid_598116 = header.getOrDefault("X-Amz-Date")
  valid_598116 = validateParameter(valid_598116, JString, required = false,
                                 default = nil)
  if valid_598116 != nil:
    section.add "X-Amz-Date", valid_598116
  var valid_598117 = header.getOrDefault("X-Amz-Credential")
  valid_598117 = validateParameter(valid_598117, JString, required = false,
                                 default = nil)
  if valid_598117 != nil:
    section.add "X-Amz-Credential", valid_598117
  var valid_598118 = header.getOrDefault("X-Amz-Security-Token")
  valid_598118 = validateParameter(valid_598118, JString, required = false,
                                 default = nil)
  if valid_598118 != nil:
    section.add "X-Amz-Security-Token", valid_598118
  var valid_598119 = header.getOrDefault("X-Amz-Algorithm")
  valid_598119 = validateParameter(valid_598119, JString, required = false,
                                 default = nil)
  if valid_598119 != nil:
    section.add "X-Amz-Algorithm", valid_598119
  var valid_598120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "X-Amz-SignedHeaders", valid_598120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598122: Call_CreateGlobalNetwork_598111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty global network.
  ## 
  let valid = call_598122.validator(path, query, header, formData, body)
  let scheme = call_598122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598122.url(scheme.get, call_598122.host, call_598122.base,
                         call_598122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598122, url, valid)

proc call*(call_598123: Call_CreateGlobalNetwork_598111; body: JsonNode): Recallable =
  ## createGlobalNetwork
  ## Creates a new, empty global network.
  ##   body: JObject (required)
  var body_598124 = newJObject()
  if body != nil:
    body_598124 = body
  result = call_598123.call(nil, nil, nil, nil, body_598124)

var createGlobalNetwork* = Call_CreateGlobalNetwork_598111(
    name: "createGlobalNetwork", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_CreateGlobalNetwork_598112, base: "/",
    url: url_CreateGlobalNetwork_598113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalNetworks_598093 = ref object of OpenApiRestCall_597389
proc url_DescribeGlobalNetworks_598095(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeGlobalNetworks_598094(path: JsonNode; query: JsonNode;
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
  var valid_598096 = query.getOrDefault("nextToken")
  valid_598096 = validateParameter(valid_598096, JString, required = false,
                                 default = nil)
  if valid_598096 != nil:
    section.add "nextToken", valid_598096
  var valid_598097 = query.getOrDefault("MaxResults")
  valid_598097 = validateParameter(valid_598097, JString, required = false,
                                 default = nil)
  if valid_598097 != nil:
    section.add "MaxResults", valid_598097
  var valid_598098 = query.getOrDefault("NextToken")
  valid_598098 = validateParameter(valid_598098, JString, required = false,
                                 default = nil)
  if valid_598098 != nil:
    section.add "NextToken", valid_598098
  var valid_598099 = query.getOrDefault("globalNetworkIds")
  valid_598099 = validateParameter(valid_598099, JArray, required = false,
                                 default = nil)
  if valid_598099 != nil:
    section.add "globalNetworkIds", valid_598099
  var valid_598100 = query.getOrDefault("maxResults")
  valid_598100 = validateParameter(valid_598100, JInt, required = false, default = nil)
  if valid_598100 != nil:
    section.add "maxResults", valid_598100
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
  var valid_598101 = header.getOrDefault("X-Amz-Signature")
  valid_598101 = validateParameter(valid_598101, JString, required = false,
                                 default = nil)
  if valid_598101 != nil:
    section.add "X-Amz-Signature", valid_598101
  var valid_598102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598102 = validateParameter(valid_598102, JString, required = false,
                                 default = nil)
  if valid_598102 != nil:
    section.add "X-Amz-Content-Sha256", valid_598102
  var valid_598103 = header.getOrDefault("X-Amz-Date")
  valid_598103 = validateParameter(valid_598103, JString, required = false,
                                 default = nil)
  if valid_598103 != nil:
    section.add "X-Amz-Date", valid_598103
  var valid_598104 = header.getOrDefault("X-Amz-Credential")
  valid_598104 = validateParameter(valid_598104, JString, required = false,
                                 default = nil)
  if valid_598104 != nil:
    section.add "X-Amz-Credential", valid_598104
  var valid_598105 = header.getOrDefault("X-Amz-Security-Token")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-Security-Token", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Algorithm")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Algorithm", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-SignedHeaders", valid_598107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598108: Call_DescribeGlobalNetworks_598093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
  ## 
  let valid = call_598108.validator(path, query, header, formData, body)
  let scheme = call_598108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598108.url(scheme.get, call_598108.host, call_598108.base,
                         call_598108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598108, url, valid)

proc call*(call_598109: Call_DescribeGlobalNetworks_598093; nextToken: string = "";
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
  var query_598110 = newJObject()
  add(query_598110, "nextToken", newJString(nextToken))
  add(query_598110, "MaxResults", newJString(MaxResults))
  add(query_598110, "NextToken", newJString(NextToken))
  if globalNetworkIds != nil:
    query_598110.add "globalNetworkIds", globalNetworkIds
  add(query_598110, "maxResults", newJInt(maxResults))
  result = call_598109.call(nil, query_598110, nil, nil, nil)

var describeGlobalNetworks* = Call_DescribeGlobalNetworks_598093(
    name: "describeGlobalNetworks", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_DescribeGlobalNetworks_598094, base: "/",
    url: url_DescribeGlobalNetworks_598095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLink_598148 = ref object of OpenApiRestCall_597389
proc url_CreateLink_598150(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateLink_598149(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598151 = path.getOrDefault("globalNetworkId")
  valid_598151 = validateParameter(valid_598151, JString, required = true,
                                 default = nil)
  if valid_598151 != nil:
    section.add "globalNetworkId", valid_598151
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
  var valid_598152 = header.getOrDefault("X-Amz-Signature")
  valid_598152 = validateParameter(valid_598152, JString, required = false,
                                 default = nil)
  if valid_598152 != nil:
    section.add "X-Amz-Signature", valid_598152
  var valid_598153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598153 = validateParameter(valid_598153, JString, required = false,
                                 default = nil)
  if valid_598153 != nil:
    section.add "X-Amz-Content-Sha256", valid_598153
  var valid_598154 = header.getOrDefault("X-Amz-Date")
  valid_598154 = validateParameter(valid_598154, JString, required = false,
                                 default = nil)
  if valid_598154 != nil:
    section.add "X-Amz-Date", valid_598154
  var valid_598155 = header.getOrDefault("X-Amz-Credential")
  valid_598155 = validateParameter(valid_598155, JString, required = false,
                                 default = nil)
  if valid_598155 != nil:
    section.add "X-Amz-Credential", valid_598155
  var valid_598156 = header.getOrDefault("X-Amz-Security-Token")
  valid_598156 = validateParameter(valid_598156, JString, required = false,
                                 default = nil)
  if valid_598156 != nil:
    section.add "X-Amz-Security-Token", valid_598156
  var valid_598157 = header.getOrDefault("X-Amz-Algorithm")
  valid_598157 = validateParameter(valid_598157, JString, required = false,
                                 default = nil)
  if valid_598157 != nil:
    section.add "X-Amz-Algorithm", valid_598157
  var valid_598158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598158 = validateParameter(valid_598158, JString, required = false,
                                 default = nil)
  if valid_598158 != nil:
    section.add "X-Amz-SignedHeaders", valid_598158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598160: Call_CreateLink_598148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new link for a specified site.
  ## 
  let valid = call_598160.validator(path, query, header, formData, body)
  let scheme = call_598160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598160.url(scheme.get, call_598160.host, call_598160.base,
                         call_598160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598160, url, valid)

proc call*(call_598161: Call_CreateLink_598148; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createLink
  ## Creates a new link for a specified site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_598162 = newJObject()
  var body_598163 = newJObject()
  add(path_598162, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_598163 = body
  result = call_598161.call(path_598162, nil, nil, nil, body_598163)

var createLink* = Call_CreateLink_598148(name: "createLink",
                                      meth: HttpMethod.HttpPost,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                      validator: validate_CreateLink_598149,
                                      base: "/", url: url_CreateLink_598150,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinks_598125 = ref object of OpenApiRestCall_597389
proc url_GetLinks_598127(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetLinks_598126(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598128 = path.getOrDefault("globalNetworkId")
  valid_598128 = validateParameter(valid_598128, JString, required = true,
                                 default = nil)
  if valid_598128 != nil:
    section.add "globalNetworkId", valid_598128
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
  var valid_598129 = query.getOrDefault("nextToken")
  valid_598129 = validateParameter(valid_598129, JString, required = false,
                                 default = nil)
  if valid_598129 != nil:
    section.add "nextToken", valid_598129
  var valid_598130 = query.getOrDefault("linkIds")
  valid_598130 = validateParameter(valid_598130, JArray, required = false,
                                 default = nil)
  if valid_598130 != nil:
    section.add "linkIds", valid_598130
  var valid_598131 = query.getOrDefault("MaxResults")
  valid_598131 = validateParameter(valid_598131, JString, required = false,
                                 default = nil)
  if valid_598131 != nil:
    section.add "MaxResults", valid_598131
  var valid_598132 = query.getOrDefault("NextToken")
  valid_598132 = validateParameter(valid_598132, JString, required = false,
                                 default = nil)
  if valid_598132 != nil:
    section.add "NextToken", valid_598132
  var valid_598133 = query.getOrDefault("type")
  valid_598133 = validateParameter(valid_598133, JString, required = false,
                                 default = nil)
  if valid_598133 != nil:
    section.add "type", valid_598133
  var valid_598134 = query.getOrDefault("provider")
  valid_598134 = validateParameter(valid_598134, JString, required = false,
                                 default = nil)
  if valid_598134 != nil:
    section.add "provider", valid_598134
  var valid_598135 = query.getOrDefault("siteId")
  valid_598135 = validateParameter(valid_598135, JString, required = false,
                                 default = nil)
  if valid_598135 != nil:
    section.add "siteId", valid_598135
  var valid_598136 = query.getOrDefault("maxResults")
  valid_598136 = validateParameter(valid_598136, JInt, required = false, default = nil)
  if valid_598136 != nil:
    section.add "maxResults", valid_598136
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
  var valid_598137 = header.getOrDefault("X-Amz-Signature")
  valid_598137 = validateParameter(valid_598137, JString, required = false,
                                 default = nil)
  if valid_598137 != nil:
    section.add "X-Amz-Signature", valid_598137
  var valid_598138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598138 = validateParameter(valid_598138, JString, required = false,
                                 default = nil)
  if valid_598138 != nil:
    section.add "X-Amz-Content-Sha256", valid_598138
  var valid_598139 = header.getOrDefault("X-Amz-Date")
  valid_598139 = validateParameter(valid_598139, JString, required = false,
                                 default = nil)
  if valid_598139 != nil:
    section.add "X-Amz-Date", valid_598139
  var valid_598140 = header.getOrDefault("X-Amz-Credential")
  valid_598140 = validateParameter(valid_598140, JString, required = false,
                                 default = nil)
  if valid_598140 != nil:
    section.add "X-Amz-Credential", valid_598140
  var valid_598141 = header.getOrDefault("X-Amz-Security-Token")
  valid_598141 = validateParameter(valid_598141, JString, required = false,
                                 default = nil)
  if valid_598141 != nil:
    section.add "X-Amz-Security-Token", valid_598141
  var valid_598142 = header.getOrDefault("X-Amz-Algorithm")
  valid_598142 = validateParameter(valid_598142, JString, required = false,
                                 default = nil)
  if valid_598142 != nil:
    section.add "X-Amz-Algorithm", valid_598142
  var valid_598143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598143 = validateParameter(valid_598143, JString, required = false,
                                 default = nil)
  if valid_598143 != nil:
    section.add "X-Amz-SignedHeaders", valid_598143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598144: Call_GetLinks_598125; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about one or more links in a specified global network.</p> <p>If you specify the site ID, you cannot specify the type or provider in the same request. You can specify the type and provider in the same request.</p>
  ## 
  let valid = call_598144.validator(path, query, header, formData, body)
  let scheme = call_598144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598144.url(scheme.get, call_598144.host, call_598144.base,
                         call_598144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598144, url, valid)

proc call*(call_598145: Call_GetLinks_598125; globalNetworkId: string;
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
  var path_598146 = newJObject()
  var query_598147 = newJObject()
  add(query_598147, "nextToken", newJString(nextToken))
  if linkIds != nil:
    query_598147.add "linkIds", linkIds
  add(query_598147, "MaxResults", newJString(MaxResults))
  add(query_598147, "NextToken", newJString(NextToken))
  add(query_598147, "type", newJString(`type`))
  add(path_598146, "globalNetworkId", newJString(globalNetworkId))
  add(query_598147, "provider", newJString(provider))
  add(query_598147, "siteId", newJString(siteId))
  add(query_598147, "maxResults", newJInt(maxResults))
  result = call_598145.call(path_598146, query_598147, nil, nil, nil)

var getLinks* = Call_GetLinks_598125(name: "getLinks", meth: HttpMethod.HttpGet,
                                  host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                  validator: validate_GetLinks_598126, base: "/",
                                  url: url_GetLinks_598127,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSite_598184 = ref object of OpenApiRestCall_597389
proc url_CreateSite_598186(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateSite_598185(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598187 = path.getOrDefault("globalNetworkId")
  valid_598187 = validateParameter(valid_598187, JString, required = true,
                                 default = nil)
  if valid_598187 != nil:
    section.add "globalNetworkId", valid_598187
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
  var valid_598188 = header.getOrDefault("X-Amz-Signature")
  valid_598188 = validateParameter(valid_598188, JString, required = false,
                                 default = nil)
  if valid_598188 != nil:
    section.add "X-Amz-Signature", valid_598188
  var valid_598189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598189 = validateParameter(valid_598189, JString, required = false,
                                 default = nil)
  if valid_598189 != nil:
    section.add "X-Amz-Content-Sha256", valid_598189
  var valid_598190 = header.getOrDefault("X-Amz-Date")
  valid_598190 = validateParameter(valid_598190, JString, required = false,
                                 default = nil)
  if valid_598190 != nil:
    section.add "X-Amz-Date", valid_598190
  var valid_598191 = header.getOrDefault("X-Amz-Credential")
  valid_598191 = validateParameter(valid_598191, JString, required = false,
                                 default = nil)
  if valid_598191 != nil:
    section.add "X-Amz-Credential", valid_598191
  var valid_598192 = header.getOrDefault("X-Amz-Security-Token")
  valid_598192 = validateParameter(valid_598192, JString, required = false,
                                 default = nil)
  if valid_598192 != nil:
    section.add "X-Amz-Security-Token", valid_598192
  var valid_598193 = header.getOrDefault("X-Amz-Algorithm")
  valid_598193 = validateParameter(valid_598193, JString, required = false,
                                 default = nil)
  if valid_598193 != nil:
    section.add "X-Amz-Algorithm", valid_598193
  var valid_598194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598194 = validateParameter(valid_598194, JString, required = false,
                                 default = nil)
  if valid_598194 != nil:
    section.add "X-Amz-SignedHeaders", valid_598194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598196: Call_CreateSite_598184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new site in a global network.
  ## 
  let valid = call_598196.validator(path, query, header, formData, body)
  let scheme = call_598196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598196.url(scheme.get, call_598196.host, call_598196.base,
                         call_598196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598196, url, valid)

proc call*(call_598197: Call_CreateSite_598184; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createSite
  ## Creates a new site in a global network.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_598198 = newJObject()
  var body_598199 = newJObject()
  add(path_598198, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_598199 = body
  result = call_598197.call(path_598198, nil, nil, nil, body_598199)

var createSite* = Call_CreateSite_598184(name: "createSite",
                                      meth: HttpMethod.HttpPost,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                      validator: validate_CreateSite_598185,
                                      base: "/", url: url_CreateSite_598186,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSites_598164 = ref object of OpenApiRestCall_597389
proc url_GetSites_598166(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSites_598165(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598167 = path.getOrDefault("globalNetworkId")
  valid_598167 = validateParameter(valid_598167, JString, required = true,
                                 default = nil)
  if valid_598167 != nil:
    section.add "globalNetworkId", valid_598167
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
  var valid_598168 = query.getOrDefault("nextToken")
  valid_598168 = validateParameter(valid_598168, JString, required = false,
                                 default = nil)
  if valid_598168 != nil:
    section.add "nextToken", valid_598168
  var valid_598169 = query.getOrDefault("MaxResults")
  valid_598169 = validateParameter(valid_598169, JString, required = false,
                                 default = nil)
  if valid_598169 != nil:
    section.add "MaxResults", valid_598169
  var valid_598170 = query.getOrDefault("NextToken")
  valid_598170 = validateParameter(valid_598170, JString, required = false,
                                 default = nil)
  if valid_598170 != nil:
    section.add "NextToken", valid_598170
  var valid_598171 = query.getOrDefault("siteIds")
  valid_598171 = validateParameter(valid_598171, JArray, required = false,
                                 default = nil)
  if valid_598171 != nil:
    section.add "siteIds", valid_598171
  var valid_598172 = query.getOrDefault("maxResults")
  valid_598172 = validateParameter(valid_598172, JInt, required = false, default = nil)
  if valid_598172 != nil:
    section.add "maxResults", valid_598172
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
  var valid_598173 = header.getOrDefault("X-Amz-Signature")
  valid_598173 = validateParameter(valid_598173, JString, required = false,
                                 default = nil)
  if valid_598173 != nil:
    section.add "X-Amz-Signature", valid_598173
  var valid_598174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598174 = validateParameter(valid_598174, JString, required = false,
                                 default = nil)
  if valid_598174 != nil:
    section.add "X-Amz-Content-Sha256", valid_598174
  var valid_598175 = header.getOrDefault("X-Amz-Date")
  valid_598175 = validateParameter(valid_598175, JString, required = false,
                                 default = nil)
  if valid_598175 != nil:
    section.add "X-Amz-Date", valid_598175
  var valid_598176 = header.getOrDefault("X-Amz-Credential")
  valid_598176 = validateParameter(valid_598176, JString, required = false,
                                 default = nil)
  if valid_598176 != nil:
    section.add "X-Amz-Credential", valid_598176
  var valid_598177 = header.getOrDefault("X-Amz-Security-Token")
  valid_598177 = validateParameter(valid_598177, JString, required = false,
                                 default = nil)
  if valid_598177 != nil:
    section.add "X-Amz-Security-Token", valid_598177
  var valid_598178 = header.getOrDefault("X-Amz-Algorithm")
  valid_598178 = validateParameter(valid_598178, JString, required = false,
                                 default = nil)
  if valid_598178 != nil:
    section.add "X-Amz-Algorithm", valid_598178
  var valid_598179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598179 = validateParameter(valid_598179, JString, required = false,
                                 default = nil)
  if valid_598179 != nil:
    section.add "X-Amz-SignedHeaders", valid_598179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598180: Call_GetSites_598164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more of your sites in a global network.
  ## 
  let valid = call_598180.validator(path, query, header, formData, body)
  let scheme = call_598180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598180.url(scheme.get, call_598180.host, call_598180.base,
                         call_598180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598180, url, valid)

proc call*(call_598181: Call_GetSites_598164; globalNetworkId: string;
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
  var path_598182 = newJObject()
  var query_598183 = newJObject()
  add(query_598183, "nextToken", newJString(nextToken))
  add(query_598183, "MaxResults", newJString(MaxResults))
  add(query_598183, "NextToken", newJString(NextToken))
  add(path_598182, "globalNetworkId", newJString(globalNetworkId))
  if siteIds != nil:
    query_598183.add "siteIds", siteIds
  add(query_598183, "maxResults", newJInt(maxResults))
  result = call_598181.call(path_598182, query_598183, nil, nil, nil)

var getSites* = Call_GetSites_598164(name: "getSites", meth: HttpMethod.HttpGet,
                                  host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                  validator: validate_GetSites_598165, base: "/",
                                  url: url_GetSites_598166,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_598215 = ref object of OpenApiRestCall_597389
proc url_UpdateDevice_598217(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDevice_598216(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598218 = path.getOrDefault("globalNetworkId")
  valid_598218 = validateParameter(valid_598218, JString, required = true,
                                 default = nil)
  if valid_598218 != nil:
    section.add "globalNetworkId", valid_598218
  var valid_598219 = path.getOrDefault("deviceId")
  valid_598219 = validateParameter(valid_598219, JString, required = true,
                                 default = nil)
  if valid_598219 != nil:
    section.add "deviceId", valid_598219
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
  var valid_598220 = header.getOrDefault("X-Amz-Signature")
  valid_598220 = validateParameter(valid_598220, JString, required = false,
                                 default = nil)
  if valid_598220 != nil:
    section.add "X-Amz-Signature", valid_598220
  var valid_598221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598221 = validateParameter(valid_598221, JString, required = false,
                                 default = nil)
  if valid_598221 != nil:
    section.add "X-Amz-Content-Sha256", valid_598221
  var valid_598222 = header.getOrDefault("X-Amz-Date")
  valid_598222 = validateParameter(valid_598222, JString, required = false,
                                 default = nil)
  if valid_598222 != nil:
    section.add "X-Amz-Date", valid_598222
  var valid_598223 = header.getOrDefault("X-Amz-Credential")
  valid_598223 = validateParameter(valid_598223, JString, required = false,
                                 default = nil)
  if valid_598223 != nil:
    section.add "X-Amz-Credential", valid_598223
  var valid_598224 = header.getOrDefault("X-Amz-Security-Token")
  valid_598224 = validateParameter(valid_598224, JString, required = false,
                                 default = nil)
  if valid_598224 != nil:
    section.add "X-Amz-Security-Token", valid_598224
  var valid_598225 = header.getOrDefault("X-Amz-Algorithm")
  valid_598225 = validateParameter(valid_598225, JString, required = false,
                                 default = nil)
  if valid_598225 != nil:
    section.add "X-Amz-Algorithm", valid_598225
  var valid_598226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598226 = validateParameter(valid_598226, JString, required = false,
                                 default = nil)
  if valid_598226 != nil:
    section.add "X-Amz-SignedHeaders", valid_598226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598228: Call_UpdateDevice_598215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_598228.validator(path, query, header, formData, body)
  let scheme = call_598228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598228.url(scheme.get, call_598228.host, call_598228.base,
                         call_598228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598228, url, valid)

proc call*(call_598229: Call_UpdateDevice_598215; globalNetworkId: string;
          body: JsonNode; deviceId: string): Recallable =
  ## updateDevice
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  ##   deviceId: string (required)
  ##           : The ID of the device.
  var path_598230 = newJObject()
  var body_598231 = newJObject()
  add(path_598230, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_598231 = body
  add(path_598230, "deviceId", newJString(deviceId))
  result = call_598229.call(path_598230, nil, nil, nil, body_598231)

var updateDevice* = Call_UpdateDevice_598215(name: "updateDevice",
    meth: HttpMethod.HttpPatch, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_UpdateDevice_598216, base: "/", url: url_UpdateDevice_598217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_598200 = ref object of OpenApiRestCall_597389
proc url_DeleteDevice_598202(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDevice_598201(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598203 = path.getOrDefault("globalNetworkId")
  valid_598203 = validateParameter(valid_598203, JString, required = true,
                                 default = nil)
  if valid_598203 != nil:
    section.add "globalNetworkId", valid_598203
  var valid_598204 = path.getOrDefault("deviceId")
  valid_598204 = validateParameter(valid_598204, JString, required = true,
                                 default = nil)
  if valid_598204 != nil:
    section.add "deviceId", valid_598204
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
  var valid_598205 = header.getOrDefault("X-Amz-Signature")
  valid_598205 = validateParameter(valid_598205, JString, required = false,
                                 default = nil)
  if valid_598205 != nil:
    section.add "X-Amz-Signature", valid_598205
  var valid_598206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598206 = validateParameter(valid_598206, JString, required = false,
                                 default = nil)
  if valid_598206 != nil:
    section.add "X-Amz-Content-Sha256", valid_598206
  var valid_598207 = header.getOrDefault("X-Amz-Date")
  valid_598207 = validateParameter(valid_598207, JString, required = false,
                                 default = nil)
  if valid_598207 != nil:
    section.add "X-Amz-Date", valid_598207
  var valid_598208 = header.getOrDefault("X-Amz-Credential")
  valid_598208 = validateParameter(valid_598208, JString, required = false,
                                 default = nil)
  if valid_598208 != nil:
    section.add "X-Amz-Credential", valid_598208
  var valid_598209 = header.getOrDefault("X-Amz-Security-Token")
  valid_598209 = validateParameter(valid_598209, JString, required = false,
                                 default = nil)
  if valid_598209 != nil:
    section.add "X-Amz-Security-Token", valid_598209
  var valid_598210 = header.getOrDefault("X-Amz-Algorithm")
  valid_598210 = validateParameter(valid_598210, JString, required = false,
                                 default = nil)
  if valid_598210 != nil:
    section.add "X-Amz-Algorithm", valid_598210
  var valid_598211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598211 = validateParameter(valid_598211, JString, required = false,
                                 default = nil)
  if valid_598211 != nil:
    section.add "X-Amz-SignedHeaders", valid_598211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598212: Call_DeleteDevice_598200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ## 
  let valid = call_598212.validator(path, query, header, formData, body)
  let scheme = call_598212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598212.url(scheme.get, call_598212.host, call_598212.base,
                         call_598212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598212, url, valid)

proc call*(call_598213: Call_DeleteDevice_598200; globalNetworkId: string;
          deviceId: string): Recallable =
  ## deleteDevice
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  var path_598214 = newJObject()
  add(path_598214, "globalNetworkId", newJString(globalNetworkId))
  add(path_598214, "deviceId", newJString(deviceId))
  result = call_598213.call(path_598214, nil, nil, nil, nil)

var deleteDevice* = Call_DeleteDevice_598200(name: "deleteDevice",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_DeleteDevice_598201, base: "/", url: url_DeleteDevice_598202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalNetwork_598246 = ref object of OpenApiRestCall_597389
proc url_UpdateGlobalNetwork_598248(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGlobalNetwork_598247(path: JsonNode; query: JsonNode;
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
  var valid_598249 = path.getOrDefault("globalNetworkId")
  valid_598249 = validateParameter(valid_598249, JString, required = true,
                                 default = nil)
  if valid_598249 != nil:
    section.add "globalNetworkId", valid_598249
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
  var valid_598250 = header.getOrDefault("X-Amz-Signature")
  valid_598250 = validateParameter(valid_598250, JString, required = false,
                                 default = nil)
  if valid_598250 != nil:
    section.add "X-Amz-Signature", valid_598250
  var valid_598251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598251 = validateParameter(valid_598251, JString, required = false,
                                 default = nil)
  if valid_598251 != nil:
    section.add "X-Amz-Content-Sha256", valid_598251
  var valid_598252 = header.getOrDefault("X-Amz-Date")
  valid_598252 = validateParameter(valid_598252, JString, required = false,
                                 default = nil)
  if valid_598252 != nil:
    section.add "X-Amz-Date", valid_598252
  var valid_598253 = header.getOrDefault("X-Amz-Credential")
  valid_598253 = validateParameter(valid_598253, JString, required = false,
                                 default = nil)
  if valid_598253 != nil:
    section.add "X-Amz-Credential", valid_598253
  var valid_598254 = header.getOrDefault("X-Amz-Security-Token")
  valid_598254 = validateParameter(valid_598254, JString, required = false,
                                 default = nil)
  if valid_598254 != nil:
    section.add "X-Amz-Security-Token", valid_598254
  var valid_598255 = header.getOrDefault("X-Amz-Algorithm")
  valid_598255 = validateParameter(valid_598255, JString, required = false,
                                 default = nil)
  if valid_598255 != nil:
    section.add "X-Amz-Algorithm", valid_598255
  var valid_598256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598256 = validateParameter(valid_598256, JString, required = false,
                                 default = nil)
  if valid_598256 != nil:
    section.add "X-Amz-SignedHeaders", valid_598256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598258: Call_UpdateGlobalNetwork_598246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_598258.validator(path, query, header, formData, body)
  let scheme = call_598258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598258.url(scheme.get, call_598258.host, call_598258.base,
                         call_598258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598258, url, valid)

proc call*(call_598259: Call_UpdateGlobalNetwork_598246; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## updateGlobalNetwork
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ##   globalNetworkId: string (required)
  ##                  : The ID of your global network.
  ##   body: JObject (required)
  var path_598260 = newJObject()
  var body_598261 = newJObject()
  add(path_598260, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_598261 = body
  result = call_598259.call(path_598260, nil, nil, nil, body_598261)

var updateGlobalNetwork* = Call_UpdateGlobalNetwork_598246(
    name: "updateGlobalNetwork", meth: HttpMethod.HttpPatch,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_UpdateGlobalNetwork_598247, base: "/",
    url: url_UpdateGlobalNetwork_598248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGlobalNetwork_598232 = ref object of OpenApiRestCall_597389
proc url_DeleteGlobalNetwork_598234(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGlobalNetwork_598233(path: JsonNode; query: JsonNode;
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
  var valid_598235 = path.getOrDefault("globalNetworkId")
  valid_598235 = validateParameter(valid_598235, JString, required = true,
                                 default = nil)
  if valid_598235 != nil:
    section.add "globalNetworkId", valid_598235
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
  var valid_598236 = header.getOrDefault("X-Amz-Signature")
  valid_598236 = validateParameter(valid_598236, JString, required = false,
                                 default = nil)
  if valid_598236 != nil:
    section.add "X-Amz-Signature", valid_598236
  var valid_598237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598237 = validateParameter(valid_598237, JString, required = false,
                                 default = nil)
  if valid_598237 != nil:
    section.add "X-Amz-Content-Sha256", valid_598237
  var valid_598238 = header.getOrDefault("X-Amz-Date")
  valid_598238 = validateParameter(valid_598238, JString, required = false,
                                 default = nil)
  if valid_598238 != nil:
    section.add "X-Amz-Date", valid_598238
  var valid_598239 = header.getOrDefault("X-Amz-Credential")
  valid_598239 = validateParameter(valid_598239, JString, required = false,
                                 default = nil)
  if valid_598239 != nil:
    section.add "X-Amz-Credential", valid_598239
  var valid_598240 = header.getOrDefault("X-Amz-Security-Token")
  valid_598240 = validateParameter(valid_598240, JString, required = false,
                                 default = nil)
  if valid_598240 != nil:
    section.add "X-Amz-Security-Token", valid_598240
  var valid_598241 = header.getOrDefault("X-Amz-Algorithm")
  valid_598241 = validateParameter(valid_598241, JString, required = false,
                                 default = nil)
  if valid_598241 != nil:
    section.add "X-Amz-Algorithm", valid_598241
  var valid_598242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598242 = validateParameter(valid_598242, JString, required = false,
                                 default = nil)
  if valid_598242 != nil:
    section.add "X-Amz-SignedHeaders", valid_598242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598243: Call_DeleteGlobalNetwork_598232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ## 
  let valid = call_598243.validator(path, query, header, formData, body)
  let scheme = call_598243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598243.url(scheme.get, call_598243.host, call_598243.base,
                         call_598243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598243, url, valid)

proc call*(call_598244: Call_DeleteGlobalNetwork_598232; globalNetworkId: string): Recallable =
  ## deleteGlobalNetwork
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_598245 = newJObject()
  add(path_598245, "globalNetworkId", newJString(globalNetworkId))
  result = call_598244.call(path_598245, nil, nil, nil, nil)

var deleteGlobalNetwork* = Call_DeleteGlobalNetwork_598232(
    name: "deleteGlobalNetwork", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_DeleteGlobalNetwork_598233, base: "/",
    url: url_DeleteGlobalNetwork_598234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLink_598277 = ref object of OpenApiRestCall_597389
proc url_UpdateLink_598279(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateLink_598278(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598280 = path.getOrDefault("linkId")
  valid_598280 = validateParameter(valid_598280, JString, required = true,
                                 default = nil)
  if valid_598280 != nil:
    section.add "linkId", valid_598280
  var valid_598281 = path.getOrDefault("globalNetworkId")
  valid_598281 = validateParameter(valid_598281, JString, required = true,
                                 default = nil)
  if valid_598281 != nil:
    section.add "globalNetworkId", valid_598281
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
  var valid_598282 = header.getOrDefault("X-Amz-Signature")
  valid_598282 = validateParameter(valid_598282, JString, required = false,
                                 default = nil)
  if valid_598282 != nil:
    section.add "X-Amz-Signature", valid_598282
  var valid_598283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598283 = validateParameter(valid_598283, JString, required = false,
                                 default = nil)
  if valid_598283 != nil:
    section.add "X-Amz-Content-Sha256", valid_598283
  var valid_598284 = header.getOrDefault("X-Amz-Date")
  valid_598284 = validateParameter(valid_598284, JString, required = false,
                                 default = nil)
  if valid_598284 != nil:
    section.add "X-Amz-Date", valid_598284
  var valid_598285 = header.getOrDefault("X-Amz-Credential")
  valid_598285 = validateParameter(valid_598285, JString, required = false,
                                 default = nil)
  if valid_598285 != nil:
    section.add "X-Amz-Credential", valid_598285
  var valid_598286 = header.getOrDefault("X-Amz-Security-Token")
  valid_598286 = validateParameter(valid_598286, JString, required = false,
                                 default = nil)
  if valid_598286 != nil:
    section.add "X-Amz-Security-Token", valid_598286
  var valid_598287 = header.getOrDefault("X-Amz-Algorithm")
  valid_598287 = validateParameter(valid_598287, JString, required = false,
                                 default = nil)
  if valid_598287 != nil:
    section.add "X-Amz-Algorithm", valid_598287
  var valid_598288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598288 = validateParameter(valid_598288, JString, required = false,
                                 default = nil)
  if valid_598288 != nil:
    section.add "X-Amz-SignedHeaders", valid_598288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598290: Call_UpdateLink_598277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_598290.validator(path, query, header, formData, body)
  let scheme = call_598290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598290.url(scheme.get, call_598290.host, call_598290.base,
                         call_598290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598290, url, valid)

proc call*(call_598291: Call_UpdateLink_598277; linkId: string;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateLink
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ##   linkId: string (required)
  ##         : The ID of the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_598292 = newJObject()
  var body_598293 = newJObject()
  add(path_598292, "linkId", newJString(linkId))
  add(path_598292, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_598293 = body
  result = call_598291.call(path_598292, nil, nil, nil, body_598293)

var updateLink* = Call_UpdateLink_598277(name: "updateLink",
                                      meth: HttpMethod.HttpPatch,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links/{linkId}",
                                      validator: validate_UpdateLink_598278,
                                      base: "/", url: url_UpdateLink_598279,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLink_598262 = ref object of OpenApiRestCall_597389
proc url_DeleteLink_598264(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteLink_598263(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598265 = path.getOrDefault("linkId")
  valid_598265 = validateParameter(valid_598265, JString, required = true,
                                 default = nil)
  if valid_598265 != nil:
    section.add "linkId", valid_598265
  var valid_598266 = path.getOrDefault("globalNetworkId")
  valid_598266 = validateParameter(valid_598266, JString, required = true,
                                 default = nil)
  if valid_598266 != nil:
    section.add "globalNetworkId", valid_598266
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
  var valid_598267 = header.getOrDefault("X-Amz-Signature")
  valid_598267 = validateParameter(valid_598267, JString, required = false,
                                 default = nil)
  if valid_598267 != nil:
    section.add "X-Amz-Signature", valid_598267
  var valid_598268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598268 = validateParameter(valid_598268, JString, required = false,
                                 default = nil)
  if valid_598268 != nil:
    section.add "X-Amz-Content-Sha256", valid_598268
  var valid_598269 = header.getOrDefault("X-Amz-Date")
  valid_598269 = validateParameter(valid_598269, JString, required = false,
                                 default = nil)
  if valid_598269 != nil:
    section.add "X-Amz-Date", valid_598269
  var valid_598270 = header.getOrDefault("X-Amz-Credential")
  valid_598270 = validateParameter(valid_598270, JString, required = false,
                                 default = nil)
  if valid_598270 != nil:
    section.add "X-Amz-Credential", valid_598270
  var valid_598271 = header.getOrDefault("X-Amz-Security-Token")
  valid_598271 = validateParameter(valid_598271, JString, required = false,
                                 default = nil)
  if valid_598271 != nil:
    section.add "X-Amz-Security-Token", valid_598271
  var valid_598272 = header.getOrDefault("X-Amz-Algorithm")
  valid_598272 = validateParameter(valid_598272, JString, required = false,
                                 default = nil)
  if valid_598272 != nil:
    section.add "X-Amz-Algorithm", valid_598272
  var valid_598273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598273 = validateParameter(valid_598273, JString, required = false,
                                 default = nil)
  if valid_598273 != nil:
    section.add "X-Amz-SignedHeaders", valid_598273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598274: Call_DeleteLink_598262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ## 
  let valid = call_598274.validator(path, query, header, formData, body)
  let scheme = call_598274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598274.url(scheme.get, call_598274.host, call_598274.base,
                         call_598274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598274, url, valid)

proc call*(call_598275: Call_DeleteLink_598262; linkId: string;
          globalNetworkId: string): Recallable =
  ## deleteLink
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ##   linkId: string (required)
  ##         : The ID of the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_598276 = newJObject()
  add(path_598276, "linkId", newJString(linkId))
  add(path_598276, "globalNetworkId", newJString(globalNetworkId))
  result = call_598275.call(path_598276, nil, nil, nil, nil)

var deleteLink* = Call_DeleteLink_598262(name: "deleteLink",
                                      meth: HttpMethod.HttpDelete,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links/{linkId}",
                                      validator: validate_DeleteLink_598263,
                                      base: "/", url: url_DeleteLink_598264,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSite_598309 = ref object of OpenApiRestCall_597389
proc url_UpdateSite_598311(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateSite_598310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598312 = path.getOrDefault("siteId")
  valid_598312 = validateParameter(valid_598312, JString, required = true,
                                 default = nil)
  if valid_598312 != nil:
    section.add "siteId", valid_598312
  var valid_598313 = path.getOrDefault("globalNetworkId")
  valid_598313 = validateParameter(valid_598313, JString, required = true,
                                 default = nil)
  if valid_598313 != nil:
    section.add "globalNetworkId", valid_598313
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
  var valid_598314 = header.getOrDefault("X-Amz-Signature")
  valid_598314 = validateParameter(valid_598314, JString, required = false,
                                 default = nil)
  if valid_598314 != nil:
    section.add "X-Amz-Signature", valid_598314
  var valid_598315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598315 = validateParameter(valid_598315, JString, required = false,
                                 default = nil)
  if valid_598315 != nil:
    section.add "X-Amz-Content-Sha256", valid_598315
  var valid_598316 = header.getOrDefault("X-Amz-Date")
  valid_598316 = validateParameter(valid_598316, JString, required = false,
                                 default = nil)
  if valid_598316 != nil:
    section.add "X-Amz-Date", valid_598316
  var valid_598317 = header.getOrDefault("X-Amz-Credential")
  valid_598317 = validateParameter(valid_598317, JString, required = false,
                                 default = nil)
  if valid_598317 != nil:
    section.add "X-Amz-Credential", valid_598317
  var valid_598318 = header.getOrDefault("X-Amz-Security-Token")
  valid_598318 = validateParameter(valid_598318, JString, required = false,
                                 default = nil)
  if valid_598318 != nil:
    section.add "X-Amz-Security-Token", valid_598318
  var valid_598319 = header.getOrDefault("X-Amz-Algorithm")
  valid_598319 = validateParameter(valid_598319, JString, required = false,
                                 default = nil)
  if valid_598319 != nil:
    section.add "X-Amz-Algorithm", valid_598319
  var valid_598320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598320 = validateParameter(valid_598320, JString, required = false,
                                 default = nil)
  if valid_598320 != nil:
    section.add "X-Amz-SignedHeaders", valid_598320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598322: Call_UpdateSite_598309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_598322.validator(path, query, header, formData, body)
  let scheme = call_598322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598322.url(scheme.get, call_598322.host, call_598322.base,
                         call_598322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598322, url, valid)

proc call*(call_598323: Call_UpdateSite_598309; siteId: string;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateSite
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ##   siteId: string (required)
  ##         : The ID of your site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_598324 = newJObject()
  var body_598325 = newJObject()
  add(path_598324, "siteId", newJString(siteId))
  add(path_598324, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_598325 = body
  result = call_598323.call(path_598324, nil, nil, nil, body_598325)

var updateSite* = Call_UpdateSite_598309(name: "updateSite",
                                      meth: HttpMethod.HttpPatch,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites/{siteId}",
                                      validator: validate_UpdateSite_598310,
                                      base: "/", url: url_UpdateSite_598311,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSite_598294 = ref object of OpenApiRestCall_597389
proc url_DeleteSite_598296(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteSite_598295(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598297 = path.getOrDefault("siteId")
  valid_598297 = validateParameter(valid_598297, JString, required = true,
                                 default = nil)
  if valid_598297 != nil:
    section.add "siteId", valid_598297
  var valid_598298 = path.getOrDefault("globalNetworkId")
  valid_598298 = validateParameter(valid_598298, JString, required = true,
                                 default = nil)
  if valid_598298 != nil:
    section.add "globalNetworkId", valid_598298
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
  var valid_598299 = header.getOrDefault("X-Amz-Signature")
  valid_598299 = validateParameter(valid_598299, JString, required = false,
                                 default = nil)
  if valid_598299 != nil:
    section.add "X-Amz-Signature", valid_598299
  var valid_598300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598300 = validateParameter(valid_598300, JString, required = false,
                                 default = nil)
  if valid_598300 != nil:
    section.add "X-Amz-Content-Sha256", valid_598300
  var valid_598301 = header.getOrDefault("X-Amz-Date")
  valid_598301 = validateParameter(valid_598301, JString, required = false,
                                 default = nil)
  if valid_598301 != nil:
    section.add "X-Amz-Date", valid_598301
  var valid_598302 = header.getOrDefault("X-Amz-Credential")
  valid_598302 = validateParameter(valid_598302, JString, required = false,
                                 default = nil)
  if valid_598302 != nil:
    section.add "X-Amz-Credential", valid_598302
  var valid_598303 = header.getOrDefault("X-Amz-Security-Token")
  valid_598303 = validateParameter(valid_598303, JString, required = false,
                                 default = nil)
  if valid_598303 != nil:
    section.add "X-Amz-Security-Token", valid_598303
  var valid_598304 = header.getOrDefault("X-Amz-Algorithm")
  valid_598304 = validateParameter(valid_598304, JString, required = false,
                                 default = nil)
  if valid_598304 != nil:
    section.add "X-Amz-Algorithm", valid_598304
  var valid_598305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598305 = validateParameter(valid_598305, JString, required = false,
                                 default = nil)
  if valid_598305 != nil:
    section.add "X-Amz-SignedHeaders", valid_598305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598306: Call_DeleteSite_598294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ## 
  let valid = call_598306.validator(path, query, header, formData, body)
  let scheme = call_598306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598306.url(scheme.get, call_598306.host, call_598306.base,
                         call_598306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598306, url, valid)

proc call*(call_598307: Call_DeleteSite_598294; siteId: string;
          globalNetworkId: string): Recallable =
  ## deleteSite
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ##   siteId: string (required)
  ##         : The ID of the site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_598308 = newJObject()
  add(path_598308, "siteId", newJString(siteId))
  add(path_598308, "globalNetworkId", newJString(globalNetworkId))
  result = call_598307.call(path_598308, nil, nil, nil, nil)

var deleteSite* = Call_DeleteSite_598294(name: "deleteSite",
                                      meth: HttpMethod.HttpDelete,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites/{siteId}",
                                      validator: validate_DeleteSite_598295,
                                      base: "/", url: url_DeleteSite_598296,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTransitGateway_598326 = ref object of OpenApiRestCall_597389
proc url_DeregisterTransitGateway_598328(protocol: Scheme; host: string;
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

proc validate_DeregisterTransitGateway_598327(path: JsonNode; query: JsonNode;
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
  var valid_598329 = path.getOrDefault("globalNetworkId")
  valid_598329 = validateParameter(valid_598329, JString, required = true,
                                 default = nil)
  if valid_598329 != nil:
    section.add "globalNetworkId", valid_598329
  var valid_598330 = path.getOrDefault("transitGatewayArn")
  valid_598330 = validateParameter(valid_598330, JString, required = true,
                                 default = nil)
  if valid_598330 != nil:
    section.add "transitGatewayArn", valid_598330
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
  var valid_598331 = header.getOrDefault("X-Amz-Signature")
  valid_598331 = validateParameter(valid_598331, JString, required = false,
                                 default = nil)
  if valid_598331 != nil:
    section.add "X-Amz-Signature", valid_598331
  var valid_598332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598332 = validateParameter(valid_598332, JString, required = false,
                                 default = nil)
  if valid_598332 != nil:
    section.add "X-Amz-Content-Sha256", valid_598332
  var valid_598333 = header.getOrDefault("X-Amz-Date")
  valid_598333 = validateParameter(valid_598333, JString, required = false,
                                 default = nil)
  if valid_598333 != nil:
    section.add "X-Amz-Date", valid_598333
  var valid_598334 = header.getOrDefault("X-Amz-Credential")
  valid_598334 = validateParameter(valid_598334, JString, required = false,
                                 default = nil)
  if valid_598334 != nil:
    section.add "X-Amz-Credential", valid_598334
  var valid_598335 = header.getOrDefault("X-Amz-Security-Token")
  valid_598335 = validateParameter(valid_598335, JString, required = false,
                                 default = nil)
  if valid_598335 != nil:
    section.add "X-Amz-Security-Token", valid_598335
  var valid_598336 = header.getOrDefault("X-Amz-Algorithm")
  valid_598336 = validateParameter(valid_598336, JString, required = false,
                                 default = nil)
  if valid_598336 != nil:
    section.add "X-Amz-Algorithm", valid_598336
  var valid_598337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598337 = validateParameter(valid_598337, JString, required = false,
                                 default = nil)
  if valid_598337 != nil:
    section.add "X-Amz-SignedHeaders", valid_598337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598338: Call_DeregisterTransitGateway_598326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ## 
  let valid = call_598338.validator(path, query, header, formData, body)
  let scheme = call_598338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598338.url(scheme.get, call_598338.host, call_598338.base,
                         call_598338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598338, url, valid)

proc call*(call_598339: Call_DeregisterTransitGateway_598326;
          globalNetworkId: string; transitGatewayArn: string): Recallable =
  ## deregisterTransitGateway
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   transitGatewayArn: string (required)
  ##                    : The Amazon Resource Name (ARN) of the transit gateway.
  var path_598340 = newJObject()
  add(path_598340, "globalNetworkId", newJString(globalNetworkId))
  add(path_598340, "transitGatewayArn", newJString(transitGatewayArn))
  result = call_598339.call(path_598340, nil, nil, nil, nil)

var deregisterTransitGateway* = Call_DeregisterTransitGateway_598326(
    name: "deregisterTransitGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/transit-gateway-registrations/{transitGatewayArn}",
    validator: validate_DeregisterTransitGateway_598327, base: "/",
    url: url_DeregisterTransitGateway_598328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCustomerGateway_598341 = ref object of OpenApiRestCall_597389
proc url_DisassociateCustomerGateway_598343(protocol: Scheme; host: string;
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

proc validate_DisassociateCustomerGateway_598342(path: JsonNode; query: JsonNode;
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
  var valid_598344 = path.getOrDefault("globalNetworkId")
  valid_598344 = validateParameter(valid_598344, JString, required = true,
                                 default = nil)
  if valid_598344 != nil:
    section.add "globalNetworkId", valid_598344
  var valid_598345 = path.getOrDefault("customerGatewayArn")
  valid_598345 = validateParameter(valid_598345, JString, required = true,
                                 default = nil)
  if valid_598345 != nil:
    section.add "customerGatewayArn", valid_598345
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
  var valid_598346 = header.getOrDefault("X-Amz-Signature")
  valid_598346 = validateParameter(valid_598346, JString, required = false,
                                 default = nil)
  if valid_598346 != nil:
    section.add "X-Amz-Signature", valid_598346
  var valid_598347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598347 = validateParameter(valid_598347, JString, required = false,
                                 default = nil)
  if valid_598347 != nil:
    section.add "X-Amz-Content-Sha256", valid_598347
  var valid_598348 = header.getOrDefault("X-Amz-Date")
  valid_598348 = validateParameter(valid_598348, JString, required = false,
                                 default = nil)
  if valid_598348 != nil:
    section.add "X-Amz-Date", valid_598348
  var valid_598349 = header.getOrDefault("X-Amz-Credential")
  valid_598349 = validateParameter(valid_598349, JString, required = false,
                                 default = nil)
  if valid_598349 != nil:
    section.add "X-Amz-Credential", valid_598349
  var valid_598350 = header.getOrDefault("X-Amz-Security-Token")
  valid_598350 = validateParameter(valid_598350, JString, required = false,
                                 default = nil)
  if valid_598350 != nil:
    section.add "X-Amz-Security-Token", valid_598350
  var valid_598351 = header.getOrDefault("X-Amz-Algorithm")
  valid_598351 = validateParameter(valid_598351, JString, required = false,
                                 default = nil)
  if valid_598351 != nil:
    section.add "X-Amz-Algorithm", valid_598351
  var valid_598352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598352 = validateParameter(valid_598352, JString, required = false,
                                 default = nil)
  if valid_598352 != nil:
    section.add "X-Amz-SignedHeaders", valid_598352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598353: Call_DisassociateCustomerGateway_598341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a customer gateway from a device and a link.
  ## 
  let valid = call_598353.validator(path, query, header, formData, body)
  let scheme = call_598353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598353.url(scheme.get, call_598353.host, call_598353.base,
                         call_598353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598353, url, valid)

proc call*(call_598354: Call_DisassociateCustomerGateway_598341;
          globalNetworkId: string; customerGatewayArn: string): Recallable =
  ## disassociateCustomerGateway
  ## Disassociates a customer gateway from a device and a link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   customerGatewayArn: string (required)
  ##                     : The Amazon Resource Name (ARN) of the customer gateway. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources Defined by Amazon EC2</a>.
  var path_598355 = newJObject()
  add(path_598355, "globalNetworkId", newJString(globalNetworkId))
  add(path_598355, "customerGatewayArn", newJString(customerGatewayArn))
  result = call_598354.call(path_598355, nil, nil, nil, nil)

var disassociateCustomerGateway* = Call_DisassociateCustomerGateway_598341(
    name: "disassociateCustomerGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/customer-gateway-associations/{customerGatewayArn}",
    validator: validate_DisassociateCustomerGateway_598342, base: "/",
    url: url_DisassociateCustomerGateway_598343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateLink_598356 = ref object of OpenApiRestCall_597389
proc url_DisassociateLink_598358(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateLink_598357(path: JsonNode; query: JsonNode;
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
  var valid_598359 = path.getOrDefault("globalNetworkId")
  valid_598359 = validateParameter(valid_598359, JString, required = true,
                                 default = nil)
  if valid_598359 != nil:
    section.add "globalNetworkId", valid_598359
  result.add "path", section
  ## parameters in `query` object:
  ##   deviceId: JString (required)
  ##           : The ID of the device.
  ##   linkId: JString (required)
  ##         : The ID of the link.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `deviceId` field"
  var valid_598360 = query.getOrDefault("deviceId")
  valid_598360 = validateParameter(valid_598360, JString, required = true,
                                 default = nil)
  if valid_598360 != nil:
    section.add "deviceId", valid_598360
  var valid_598361 = query.getOrDefault("linkId")
  valid_598361 = validateParameter(valid_598361, JString, required = true,
                                 default = nil)
  if valid_598361 != nil:
    section.add "linkId", valid_598361
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
  var valid_598362 = header.getOrDefault("X-Amz-Signature")
  valid_598362 = validateParameter(valid_598362, JString, required = false,
                                 default = nil)
  if valid_598362 != nil:
    section.add "X-Amz-Signature", valid_598362
  var valid_598363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598363 = validateParameter(valid_598363, JString, required = false,
                                 default = nil)
  if valid_598363 != nil:
    section.add "X-Amz-Content-Sha256", valid_598363
  var valid_598364 = header.getOrDefault("X-Amz-Date")
  valid_598364 = validateParameter(valid_598364, JString, required = false,
                                 default = nil)
  if valid_598364 != nil:
    section.add "X-Amz-Date", valid_598364
  var valid_598365 = header.getOrDefault("X-Amz-Credential")
  valid_598365 = validateParameter(valid_598365, JString, required = false,
                                 default = nil)
  if valid_598365 != nil:
    section.add "X-Amz-Credential", valid_598365
  var valid_598366 = header.getOrDefault("X-Amz-Security-Token")
  valid_598366 = validateParameter(valid_598366, JString, required = false,
                                 default = nil)
  if valid_598366 != nil:
    section.add "X-Amz-Security-Token", valid_598366
  var valid_598367 = header.getOrDefault("X-Amz-Algorithm")
  valid_598367 = validateParameter(valid_598367, JString, required = false,
                                 default = nil)
  if valid_598367 != nil:
    section.add "X-Amz-Algorithm", valid_598367
  var valid_598368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598368 = validateParameter(valid_598368, JString, required = false,
                                 default = nil)
  if valid_598368 != nil:
    section.add "X-Amz-SignedHeaders", valid_598368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598369: Call_DisassociateLink_598356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ## 
  let valid = call_598369.validator(path, query, header, formData, body)
  let scheme = call_598369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598369.url(scheme.get, call_598369.host, call_598369.base,
                         call_598369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598369, url, valid)

proc call*(call_598370: Call_DisassociateLink_598356; globalNetworkId: string;
          deviceId: string; linkId: string): Recallable =
  ## disassociateLink
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  ##   linkId: string (required)
  ##         : The ID of the link.
  var path_598371 = newJObject()
  var query_598372 = newJObject()
  add(path_598371, "globalNetworkId", newJString(globalNetworkId))
  add(query_598372, "deviceId", newJString(deviceId))
  add(query_598372, "linkId", newJString(linkId))
  result = call_598370.call(path_598371, query_598372, nil, nil, nil)

var disassociateLink* = Call_DisassociateLink_598356(name: "disassociateLink",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/link-associations#deviceId&linkId",
    validator: validate_DisassociateLink_598357, base: "/",
    url: url_DisassociateLink_598358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTransitGateway_598393 = ref object of OpenApiRestCall_597389
proc url_RegisterTransitGateway_598395(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterTransitGateway_598394(path: JsonNode; query: JsonNode;
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
  var valid_598396 = path.getOrDefault("globalNetworkId")
  valid_598396 = validateParameter(valid_598396, JString, required = true,
                                 default = nil)
  if valid_598396 != nil:
    section.add "globalNetworkId", valid_598396
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
  var valid_598397 = header.getOrDefault("X-Amz-Signature")
  valid_598397 = validateParameter(valid_598397, JString, required = false,
                                 default = nil)
  if valid_598397 != nil:
    section.add "X-Amz-Signature", valid_598397
  var valid_598398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598398 = validateParameter(valid_598398, JString, required = false,
                                 default = nil)
  if valid_598398 != nil:
    section.add "X-Amz-Content-Sha256", valid_598398
  var valid_598399 = header.getOrDefault("X-Amz-Date")
  valid_598399 = validateParameter(valid_598399, JString, required = false,
                                 default = nil)
  if valid_598399 != nil:
    section.add "X-Amz-Date", valid_598399
  var valid_598400 = header.getOrDefault("X-Amz-Credential")
  valid_598400 = validateParameter(valid_598400, JString, required = false,
                                 default = nil)
  if valid_598400 != nil:
    section.add "X-Amz-Credential", valid_598400
  var valid_598401 = header.getOrDefault("X-Amz-Security-Token")
  valid_598401 = validateParameter(valid_598401, JString, required = false,
                                 default = nil)
  if valid_598401 != nil:
    section.add "X-Amz-Security-Token", valid_598401
  var valid_598402 = header.getOrDefault("X-Amz-Algorithm")
  valid_598402 = validateParameter(valid_598402, JString, required = false,
                                 default = nil)
  if valid_598402 != nil:
    section.add "X-Amz-Algorithm", valid_598402
  var valid_598403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598403 = validateParameter(valid_598403, JString, required = false,
                                 default = nil)
  if valid_598403 != nil:
    section.add "X-Amz-SignedHeaders", valid_598403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598405: Call_RegisterTransitGateway_598393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ## 
  let valid = call_598405.validator(path, query, header, formData, body)
  let scheme = call_598405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598405.url(scheme.get, call_598405.host, call_598405.base,
                         call_598405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598405, url, valid)

proc call*(call_598406: Call_RegisterTransitGateway_598393;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## registerTransitGateway
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_598407 = newJObject()
  var body_598408 = newJObject()
  add(path_598407, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_598408 = body
  result = call_598406.call(path_598407, nil, nil, nil, body_598408)

var registerTransitGateway* = Call_RegisterTransitGateway_598393(
    name: "registerTransitGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_RegisterTransitGateway_598394, base: "/",
    url: url_RegisterTransitGateway_598395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTransitGatewayRegistrations_598373 = ref object of OpenApiRestCall_597389
proc url_GetTransitGatewayRegistrations_598375(protocol: Scheme; host: string;
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

proc validate_GetTransitGatewayRegistrations_598374(path: JsonNode;
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
  var valid_598376 = path.getOrDefault("globalNetworkId")
  valid_598376 = validateParameter(valid_598376, JString, required = true,
                                 default = nil)
  if valid_598376 != nil:
    section.add "globalNetworkId", valid_598376
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
  var valid_598377 = query.getOrDefault("nextToken")
  valid_598377 = validateParameter(valid_598377, JString, required = false,
                                 default = nil)
  if valid_598377 != nil:
    section.add "nextToken", valid_598377
  var valid_598378 = query.getOrDefault("MaxResults")
  valid_598378 = validateParameter(valid_598378, JString, required = false,
                                 default = nil)
  if valid_598378 != nil:
    section.add "MaxResults", valid_598378
  var valid_598379 = query.getOrDefault("transitGatewayArns")
  valid_598379 = validateParameter(valid_598379, JArray, required = false,
                                 default = nil)
  if valid_598379 != nil:
    section.add "transitGatewayArns", valid_598379
  var valid_598380 = query.getOrDefault("NextToken")
  valid_598380 = validateParameter(valid_598380, JString, required = false,
                                 default = nil)
  if valid_598380 != nil:
    section.add "NextToken", valid_598380
  var valid_598381 = query.getOrDefault("maxResults")
  valid_598381 = validateParameter(valid_598381, JInt, required = false, default = nil)
  if valid_598381 != nil:
    section.add "maxResults", valid_598381
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
  var valid_598382 = header.getOrDefault("X-Amz-Signature")
  valid_598382 = validateParameter(valid_598382, JString, required = false,
                                 default = nil)
  if valid_598382 != nil:
    section.add "X-Amz-Signature", valid_598382
  var valid_598383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598383 = validateParameter(valid_598383, JString, required = false,
                                 default = nil)
  if valid_598383 != nil:
    section.add "X-Amz-Content-Sha256", valid_598383
  var valid_598384 = header.getOrDefault("X-Amz-Date")
  valid_598384 = validateParameter(valid_598384, JString, required = false,
                                 default = nil)
  if valid_598384 != nil:
    section.add "X-Amz-Date", valid_598384
  var valid_598385 = header.getOrDefault("X-Amz-Credential")
  valid_598385 = validateParameter(valid_598385, JString, required = false,
                                 default = nil)
  if valid_598385 != nil:
    section.add "X-Amz-Credential", valid_598385
  var valid_598386 = header.getOrDefault("X-Amz-Security-Token")
  valid_598386 = validateParameter(valid_598386, JString, required = false,
                                 default = nil)
  if valid_598386 != nil:
    section.add "X-Amz-Security-Token", valid_598386
  var valid_598387 = header.getOrDefault("X-Amz-Algorithm")
  valid_598387 = validateParameter(valid_598387, JString, required = false,
                                 default = nil)
  if valid_598387 != nil:
    section.add "X-Amz-Algorithm", valid_598387
  var valid_598388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598388 = validateParameter(valid_598388, JString, required = false,
                                 default = nil)
  if valid_598388 != nil:
    section.add "X-Amz-SignedHeaders", valid_598388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598389: Call_GetTransitGatewayRegistrations_598373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the transit gateway registrations in a specified global network.
  ## 
  let valid = call_598389.validator(path, query, header, formData, body)
  let scheme = call_598389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598389.url(scheme.get, call_598389.host, call_598389.base,
                         call_598389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598389, url, valid)

proc call*(call_598390: Call_GetTransitGatewayRegistrations_598373;
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
  var path_598391 = newJObject()
  var query_598392 = newJObject()
  add(query_598392, "nextToken", newJString(nextToken))
  add(query_598392, "MaxResults", newJString(MaxResults))
  if transitGatewayArns != nil:
    query_598392.add "transitGatewayArns", transitGatewayArns
  add(query_598392, "NextToken", newJString(NextToken))
  add(path_598391, "globalNetworkId", newJString(globalNetworkId))
  add(query_598392, "maxResults", newJInt(maxResults))
  result = call_598390.call(path_598391, query_598392, nil, nil, nil)

var getTransitGatewayRegistrations* = Call_GetTransitGatewayRegistrations_598373(
    name: "getTransitGatewayRegistrations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_GetTransitGatewayRegistrations_598374, base: "/",
    url: url_GetTransitGatewayRegistrations_598375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_598423 = ref object of OpenApiRestCall_597389
proc url_TagResource_598425(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_598424(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598426 = path.getOrDefault("resourceArn")
  valid_598426 = validateParameter(valid_598426, JString, required = true,
                                 default = nil)
  if valid_598426 != nil:
    section.add "resourceArn", valid_598426
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
  var valid_598427 = header.getOrDefault("X-Amz-Signature")
  valid_598427 = validateParameter(valid_598427, JString, required = false,
                                 default = nil)
  if valid_598427 != nil:
    section.add "X-Amz-Signature", valid_598427
  var valid_598428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598428 = validateParameter(valid_598428, JString, required = false,
                                 default = nil)
  if valid_598428 != nil:
    section.add "X-Amz-Content-Sha256", valid_598428
  var valid_598429 = header.getOrDefault("X-Amz-Date")
  valid_598429 = validateParameter(valid_598429, JString, required = false,
                                 default = nil)
  if valid_598429 != nil:
    section.add "X-Amz-Date", valid_598429
  var valid_598430 = header.getOrDefault("X-Amz-Credential")
  valid_598430 = validateParameter(valid_598430, JString, required = false,
                                 default = nil)
  if valid_598430 != nil:
    section.add "X-Amz-Credential", valid_598430
  var valid_598431 = header.getOrDefault("X-Amz-Security-Token")
  valid_598431 = validateParameter(valid_598431, JString, required = false,
                                 default = nil)
  if valid_598431 != nil:
    section.add "X-Amz-Security-Token", valid_598431
  var valid_598432 = header.getOrDefault("X-Amz-Algorithm")
  valid_598432 = validateParameter(valid_598432, JString, required = false,
                                 default = nil)
  if valid_598432 != nil:
    section.add "X-Amz-Algorithm", valid_598432
  var valid_598433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598433 = validateParameter(valid_598433, JString, required = false,
                                 default = nil)
  if valid_598433 != nil:
    section.add "X-Amz-SignedHeaders", valid_598433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598435: Call_TagResource_598423; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags a specified resource.
  ## 
  let valid = call_598435.validator(path, query, header, formData, body)
  let scheme = call_598435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598435.url(scheme.get, call_598435.host, call_598435.base,
                         call_598435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598435, url, valid)

proc call*(call_598436: Call_TagResource_598423; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tags a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_598437 = newJObject()
  var body_598438 = newJObject()
  add(path_598437, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_598438 = body
  result = call_598436.call(path_598437, nil, nil, nil, body_598438)

var tagResource* = Call_TagResource_598423(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "networkmanager.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_598424,
                                        base: "/", url: url_TagResource_598425,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_598409 = ref object of OpenApiRestCall_597389
proc url_ListTagsForResource_598411(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_598410(path: JsonNode; query: JsonNode;
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
  var valid_598412 = path.getOrDefault("resourceArn")
  valid_598412 = validateParameter(valid_598412, JString, required = true,
                                 default = nil)
  if valid_598412 != nil:
    section.add "resourceArn", valid_598412
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
  var valid_598413 = header.getOrDefault("X-Amz-Signature")
  valid_598413 = validateParameter(valid_598413, JString, required = false,
                                 default = nil)
  if valid_598413 != nil:
    section.add "X-Amz-Signature", valid_598413
  var valid_598414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598414 = validateParameter(valid_598414, JString, required = false,
                                 default = nil)
  if valid_598414 != nil:
    section.add "X-Amz-Content-Sha256", valid_598414
  var valid_598415 = header.getOrDefault("X-Amz-Date")
  valid_598415 = validateParameter(valid_598415, JString, required = false,
                                 default = nil)
  if valid_598415 != nil:
    section.add "X-Amz-Date", valid_598415
  var valid_598416 = header.getOrDefault("X-Amz-Credential")
  valid_598416 = validateParameter(valid_598416, JString, required = false,
                                 default = nil)
  if valid_598416 != nil:
    section.add "X-Amz-Credential", valid_598416
  var valid_598417 = header.getOrDefault("X-Amz-Security-Token")
  valid_598417 = validateParameter(valid_598417, JString, required = false,
                                 default = nil)
  if valid_598417 != nil:
    section.add "X-Amz-Security-Token", valid_598417
  var valid_598418 = header.getOrDefault("X-Amz-Algorithm")
  valid_598418 = validateParameter(valid_598418, JString, required = false,
                                 default = nil)
  if valid_598418 != nil:
    section.add "X-Amz-Algorithm", valid_598418
  var valid_598419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598419 = validateParameter(valid_598419, JString, required = false,
                                 default = nil)
  if valid_598419 != nil:
    section.add "X-Amz-SignedHeaders", valid_598419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598420: Call_ListTagsForResource_598409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for a specified resource.
  ## 
  let valid = call_598420.validator(path, query, header, formData, body)
  let scheme = call_598420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598420.url(scheme.get, call_598420.host, call_598420.base,
                         call_598420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598420, url, valid)

proc call*(call_598421: Call_ListTagsForResource_598409; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_598422 = newJObject()
  add(path_598422, "resourceArn", newJString(resourceArn))
  result = call_598421.call(path_598422, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_598409(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_598410, base: "/",
    url: url_ListTagsForResource_598411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_598439 = ref object of OpenApiRestCall_597389
proc url_UntagResource_598441(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_598440(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598442 = path.getOrDefault("resourceArn")
  valid_598442 = validateParameter(valid_598442, JString, required = true,
                                 default = nil)
  if valid_598442 != nil:
    section.add "resourceArn", valid_598442
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the specified resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_598443 = query.getOrDefault("tagKeys")
  valid_598443 = validateParameter(valid_598443, JArray, required = true, default = nil)
  if valid_598443 != nil:
    section.add "tagKeys", valid_598443
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
  var valid_598444 = header.getOrDefault("X-Amz-Signature")
  valid_598444 = validateParameter(valid_598444, JString, required = false,
                                 default = nil)
  if valid_598444 != nil:
    section.add "X-Amz-Signature", valid_598444
  var valid_598445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598445 = validateParameter(valid_598445, JString, required = false,
                                 default = nil)
  if valid_598445 != nil:
    section.add "X-Amz-Content-Sha256", valid_598445
  var valid_598446 = header.getOrDefault("X-Amz-Date")
  valid_598446 = validateParameter(valid_598446, JString, required = false,
                                 default = nil)
  if valid_598446 != nil:
    section.add "X-Amz-Date", valid_598446
  var valid_598447 = header.getOrDefault("X-Amz-Credential")
  valid_598447 = validateParameter(valid_598447, JString, required = false,
                                 default = nil)
  if valid_598447 != nil:
    section.add "X-Amz-Credential", valid_598447
  var valid_598448 = header.getOrDefault("X-Amz-Security-Token")
  valid_598448 = validateParameter(valid_598448, JString, required = false,
                                 default = nil)
  if valid_598448 != nil:
    section.add "X-Amz-Security-Token", valid_598448
  var valid_598449 = header.getOrDefault("X-Amz-Algorithm")
  valid_598449 = validateParameter(valid_598449, JString, required = false,
                                 default = nil)
  if valid_598449 != nil:
    section.add "X-Amz-Algorithm", valid_598449
  var valid_598450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598450 = validateParameter(valid_598450, JString, required = false,
                                 default = nil)
  if valid_598450 != nil:
    section.add "X-Amz-SignedHeaders", valid_598450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598451: Call_UntagResource_598439; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a specified resource.
  ## 
  let valid = call_598451.validator(path, query, header, formData, body)
  let scheme = call_598451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598451.url(scheme.get, call_598451.host, call_598451.base,
                         call_598451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598451, url, valid)

proc call*(call_598452: Call_UntagResource_598439; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the specified resource.
  var path_598453 = newJObject()
  var query_598454 = newJObject()
  add(path_598453, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_598454.add "tagKeys", tagKeys
  result = call_598452.call(path_598453, query_598454, nil, nil, nil)

var untagResource* = Call_UntagResource_598439(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_598440,
    base: "/", url: url_UntagResource_598441, schemes: {Scheme.Https, Scheme.Http})
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
