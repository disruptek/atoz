
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_AssociateCustomerGateway_602003 = ref object of OpenApiRestCall_601389
proc url_AssociateCustomerGateway_602005(protocol: Scheme; host: string;
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

proc validate_AssociateCustomerGateway_602004(path: JsonNode; query: JsonNode;
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
  var valid_602006 = path.getOrDefault("globalNetworkId")
  valid_602006 = validateParameter(valid_602006, JString, required = true,
                                 default = nil)
  if valid_602006 != nil:
    section.add "globalNetworkId", valid_602006
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
  var valid_602007 = header.getOrDefault("X-Amz-Signature")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Signature", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Content-Sha256", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Date")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Date", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Credential")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Credential", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Security-Token")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Security-Token", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Algorithm")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Algorithm", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-SignedHeaders", valid_602013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602015: Call_AssociateCustomerGateway_602003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ## 
  let valid = call_602015.validator(path, query, header, formData, body)
  let scheme = call_602015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602015.url(scheme.get, call_602015.host, call_602015.base,
                         call_602015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602015, url, valid)

proc call*(call_602016: Call_AssociateCustomerGateway_602003;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## associateCustomerGateway
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_602017 = newJObject()
  var body_602018 = newJObject()
  add(path_602017, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_602018 = body
  result = call_602016.call(path_602017, nil, nil, nil, body_602018)

var associateCustomerGateway* = Call_AssociateCustomerGateway_602003(
    name: "associateCustomerGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_AssociateCustomerGateway_602004, base: "/",
    url: url_AssociateCustomerGateway_602005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCustomerGatewayAssociations_601727 = ref object of OpenApiRestCall_601389
proc url_GetCustomerGatewayAssociations_601729(protocol: Scheme; host: string;
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

proc validate_GetCustomerGatewayAssociations_601728(path: JsonNode;
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
  var valid_601855 = path.getOrDefault("globalNetworkId")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = nil)
  if valid_601855 != nil:
    section.add "globalNetworkId", valid_601855
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
  var valid_601856 = query.getOrDefault("nextToken")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "nextToken", valid_601856
  var valid_601857 = query.getOrDefault("MaxResults")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "MaxResults", valid_601857
  var valid_601858 = query.getOrDefault("NextToken")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "NextToken", valid_601858
  var valid_601859 = query.getOrDefault("customerGatewayArns")
  valid_601859 = validateParameter(valid_601859, JArray, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "customerGatewayArns", valid_601859
  var valid_601860 = query.getOrDefault("maxResults")
  valid_601860 = validateParameter(valid_601860, JInt, required = false, default = nil)
  if valid_601860 != nil:
    section.add "maxResults", valid_601860
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
  var valid_601861 = header.getOrDefault("X-Amz-Signature")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Signature", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Content-Sha256", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Date")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Date", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-Credential")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-Credential", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-Security-Token")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-Security-Token", valid_601865
  var valid_601866 = header.getOrDefault("X-Amz-Algorithm")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-Algorithm", valid_601866
  var valid_601867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601867 = validateParameter(valid_601867, JString, required = false,
                                 default = nil)
  if valid_601867 != nil:
    section.add "X-Amz-SignedHeaders", valid_601867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601890: Call_GetCustomerGatewayAssociations_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the association information for customer gateways that are associated with devices and links in your global network.
  ## 
  let valid = call_601890.validator(path, query, header, formData, body)
  let scheme = call_601890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601890.url(scheme.get, call_601890.host, call_601890.base,
                         call_601890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601890, url, valid)

proc call*(call_601961: Call_GetCustomerGatewayAssociations_601727;
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
  var path_601962 = newJObject()
  var query_601964 = newJObject()
  add(query_601964, "nextToken", newJString(nextToken))
  add(query_601964, "MaxResults", newJString(MaxResults))
  add(query_601964, "NextToken", newJString(NextToken))
  add(path_601962, "globalNetworkId", newJString(globalNetworkId))
  if customerGatewayArns != nil:
    query_601964.add "customerGatewayArns", customerGatewayArns
  add(query_601964, "maxResults", newJInt(maxResults))
  result = call_601961.call(path_601962, query_601964, nil, nil, nil)

var getCustomerGatewayAssociations* = Call_GetCustomerGatewayAssociations_601727(
    name: "getCustomerGatewayAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_GetCustomerGatewayAssociations_601728, base: "/",
    url: url_GetCustomerGatewayAssociations_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateLink_602040 = ref object of OpenApiRestCall_601389
proc url_AssociateLink_602042(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateLink_602041(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602043 = path.getOrDefault("globalNetworkId")
  valid_602043 = validateParameter(valid_602043, JString, required = true,
                                 default = nil)
  if valid_602043 != nil:
    section.add "globalNetworkId", valid_602043
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
  var valid_602044 = header.getOrDefault("X-Amz-Signature")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Signature", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Content-Sha256", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Date")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Date", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Credential")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Credential", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Security-Token")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Security-Token", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Algorithm")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Algorithm", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-SignedHeaders", valid_602050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602052: Call_AssociateLink_602040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ## 
  let valid = call_602052.validator(path, query, header, formData, body)
  let scheme = call_602052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602052.url(scheme.get, call_602052.host, call_602052.base,
                         call_602052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602052, url, valid)

proc call*(call_602053: Call_AssociateLink_602040; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## associateLink
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_602054 = newJObject()
  var body_602055 = newJObject()
  add(path_602054, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_602055 = body
  result = call_602053.call(path_602054, nil, nil, nil, body_602055)

var associateLink* = Call_AssociateLink_602040(name: "associateLink",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_AssociateLink_602041, base: "/", url: url_AssociateLink_602042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAssociations_602019 = ref object of OpenApiRestCall_601389
proc url_GetLinkAssociations_602021(protocol: Scheme; host: string; base: string;
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

proc validate_GetLinkAssociations_602020(path: JsonNode; query: JsonNode;
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
  var valid_602022 = path.getOrDefault("globalNetworkId")
  valid_602022 = validateParameter(valid_602022, JString, required = true,
                                 default = nil)
  if valid_602022 != nil:
    section.add "globalNetworkId", valid_602022
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
  var valid_602023 = query.getOrDefault("nextToken")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "nextToken", valid_602023
  var valid_602024 = query.getOrDefault("MaxResults")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "MaxResults", valid_602024
  var valid_602025 = query.getOrDefault("NextToken")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "NextToken", valid_602025
  var valid_602026 = query.getOrDefault("deviceId")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "deviceId", valid_602026
  var valid_602027 = query.getOrDefault("linkId")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "linkId", valid_602027
  var valid_602028 = query.getOrDefault("maxResults")
  valid_602028 = validateParameter(valid_602028, JInt, required = false, default = nil)
  if valid_602028 != nil:
    section.add "maxResults", valid_602028
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
  var valid_602029 = header.getOrDefault("X-Amz-Signature")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Signature", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Content-Sha256", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Date")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Date", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Credential")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Credential", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Security-Token")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Security-Token", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Algorithm")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Algorithm", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-SignedHeaders", valid_602035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602036: Call_GetLinkAssociations_602019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the link associations for a device or a link. Either the device ID or the link ID must be specified.
  ## 
  let valid = call_602036.validator(path, query, header, formData, body)
  let scheme = call_602036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602036.url(scheme.get, call_602036.host, call_602036.base,
                         call_602036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602036, url, valid)

proc call*(call_602037: Call_GetLinkAssociations_602019; globalNetworkId: string;
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
  var path_602038 = newJObject()
  var query_602039 = newJObject()
  add(query_602039, "nextToken", newJString(nextToken))
  add(query_602039, "MaxResults", newJString(MaxResults))
  add(query_602039, "NextToken", newJString(NextToken))
  add(path_602038, "globalNetworkId", newJString(globalNetworkId))
  add(query_602039, "deviceId", newJString(deviceId))
  add(query_602039, "linkId", newJString(linkId))
  add(query_602039, "maxResults", newJInt(maxResults))
  result = call_602037.call(path_602038, query_602039, nil, nil, nil)

var getLinkAssociations* = Call_GetLinkAssociations_602019(
    name: "getLinkAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_GetLinkAssociations_602020, base: "/",
    url: url_GetLinkAssociations_602021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevice_602077 = ref object of OpenApiRestCall_601389
proc url_CreateDevice_602079(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDevice_602078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602080 = path.getOrDefault("globalNetworkId")
  valid_602080 = validateParameter(valid_602080, JString, required = true,
                                 default = nil)
  if valid_602080 != nil:
    section.add "globalNetworkId", valid_602080
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
  var valid_602081 = header.getOrDefault("X-Amz-Signature")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Signature", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Content-Sha256", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Date")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Date", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Credential")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Credential", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Security-Token")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Security-Token", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Algorithm")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Algorithm", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-SignedHeaders", valid_602087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602089: Call_CreateDevice_602077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ## 
  let valid = call_602089.validator(path, query, header, formData, body)
  let scheme = call_602089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602089.url(scheme.get, call_602089.host, call_602089.base,
                         call_602089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602089, url, valid)

proc call*(call_602090: Call_CreateDevice_602077; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createDevice
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_602091 = newJObject()
  var body_602092 = newJObject()
  add(path_602091, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_602092 = body
  result = call_602090.call(path_602091, nil, nil, nil, body_602092)

var createDevice* = Call_CreateDevice_602077(name: "createDevice",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices",
    validator: validate_CreateDevice_602078, base: "/", url: url_CreateDevice_602079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevices_602056 = ref object of OpenApiRestCall_601389
proc url_GetDevices_602058(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDevices_602057(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602059 = path.getOrDefault("globalNetworkId")
  valid_602059 = validateParameter(valid_602059, JString, required = true,
                                 default = nil)
  if valid_602059 != nil:
    section.add "globalNetworkId", valid_602059
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
  var valid_602060 = query.getOrDefault("nextToken")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "nextToken", valid_602060
  var valid_602061 = query.getOrDefault("MaxResults")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "MaxResults", valid_602061
  var valid_602062 = query.getOrDefault("deviceIds")
  valid_602062 = validateParameter(valid_602062, JArray, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "deviceIds", valid_602062
  var valid_602063 = query.getOrDefault("NextToken")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "NextToken", valid_602063
  var valid_602064 = query.getOrDefault("siteId")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "siteId", valid_602064
  var valid_602065 = query.getOrDefault("maxResults")
  valid_602065 = validateParameter(valid_602065, JInt, required = false, default = nil)
  if valid_602065 != nil:
    section.add "maxResults", valid_602065
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
  var valid_602066 = header.getOrDefault("X-Amz-Signature")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Signature", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Content-Sha256", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Date")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Date", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Credential")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Credential", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Security-Token")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Security-Token", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Algorithm")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Algorithm", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-SignedHeaders", valid_602072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602073: Call_GetDevices_602056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more of your devices in a global network.
  ## 
  let valid = call_602073.validator(path, query, header, formData, body)
  let scheme = call_602073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602073.url(scheme.get, call_602073.host, call_602073.base,
                         call_602073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602073, url, valid)

proc call*(call_602074: Call_GetDevices_602056; globalNetworkId: string;
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
  var path_602075 = newJObject()
  var query_602076 = newJObject()
  add(query_602076, "nextToken", newJString(nextToken))
  add(query_602076, "MaxResults", newJString(MaxResults))
  if deviceIds != nil:
    query_602076.add "deviceIds", deviceIds
  add(query_602076, "NextToken", newJString(NextToken))
  add(path_602075, "globalNetworkId", newJString(globalNetworkId))
  add(query_602076, "siteId", newJString(siteId))
  add(query_602076, "maxResults", newJInt(maxResults))
  result = call_602074.call(path_602075, query_602076, nil, nil, nil)

var getDevices* = Call_GetDevices_602056(name: "getDevices",
                                      meth: HttpMethod.HttpGet,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/devices",
                                      validator: validate_GetDevices_602057,
                                      base: "/", url: url_GetDevices_602058,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGlobalNetwork_602111 = ref object of OpenApiRestCall_601389
proc url_CreateGlobalNetwork_602113(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGlobalNetwork_602112(path: JsonNode; query: JsonNode;
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
  var valid_602114 = header.getOrDefault("X-Amz-Signature")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Signature", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Content-Sha256", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Date")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Date", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Credential")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Credential", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Security-Token")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Security-Token", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Algorithm")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Algorithm", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-SignedHeaders", valid_602120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602122: Call_CreateGlobalNetwork_602111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty global network.
  ## 
  let valid = call_602122.validator(path, query, header, formData, body)
  let scheme = call_602122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602122.url(scheme.get, call_602122.host, call_602122.base,
                         call_602122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602122, url, valid)

proc call*(call_602123: Call_CreateGlobalNetwork_602111; body: JsonNode): Recallable =
  ## createGlobalNetwork
  ## Creates a new, empty global network.
  ##   body: JObject (required)
  var body_602124 = newJObject()
  if body != nil:
    body_602124 = body
  result = call_602123.call(nil, nil, nil, nil, body_602124)

var createGlobalNetwork* = Call_CreateGlobalNetwork_602111(
    name: "createGlobalNetwork", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_CreateGlobalNetwork_602112, base: "/",
    url: url_CreateGlobalNetwork_602113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalNetworks_602093 = ref object of OpenApiRestCall_601389
proc url_DescribeGlobalNetworks_602095(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeGlobalNetworks_602094(path: JsonNode; query: JsonNode;
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
  var valid_602096 = query.getOrDefault("nextToken")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "nextToken", valid_602096
  var valid_602097 = query.getOrDefault("MaxResults")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "MaxResults", valid_602097
  var valid_602098 = query.getOrDefault("NextToken")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "NextToken", valid_602098
  var valid_602099 = query.getOrDefault("globalNetworkIds")
  valid_602099 = validateParameter(valid_602099, JArray, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "globalNetworkIds", valid_602099
  var valid_602100 = query.getOrDefault("maxResults")
  valid_602100 = validateParameter(valid_602100, JInt, required = false, default = nil)
  if valid_602100 != nil:
    section.add "maxResults", valid_602100
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
  var valid_602101 = header.getOrDefault("X-Amz-Signature")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Signature", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Content-Sha256", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Date")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Date", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Credential")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Credential", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Security-Token")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Security-Token", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Algorithm")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Algorithm", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-SignedHeaders", valid_602107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602108: Call_DescribeGlobalNetworks_602093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
  ## 
  let valid = call_602108.validator(path, query, header, formData, body)
  let scheme = call_602108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602108.url(scheme.get, call_602108.host, call_602108.base,
                         call_602108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602108, url, valid)

proc call*(call_602109: Call_DescribeGlobalNetworks_602093; nextToken: string = "";
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
  var query_602110 = newJObject()
  add(query_602110, "nextToken", newJString(nextToken))
  add(query_602110, "MaxResults", newJString(MaxResults))
  add(query_602110, "NextToken", newJString(NextToken))
  if globalNetworkIds != nil:
    query_602110.add "globalNetworkIds", globalNetworkIds
  add(query_602110, "maxResults", newJInt(maxResults))
  result = call_602109.call(nil, query_602110, nil, nil, nil)

var describeGlobalNetworks* = Call_DescribeGlobalNetworks_602093(
    name: "describeGlobalNetworks", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_DescribeGlobalNetworks_602094, base: "/",
    url: url_DescribeGlobalNetworks_602095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLink_602148 = ref object of OpenApiRestCall_601389
proc url_CreateLink_602150(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateLink_602149(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602151 = path.getOrDefault("globalNetworkId")
  valid_602151 = validateParameter(valid_602151, JString, required = true,
                                 default = nil)
  if valid_602151 != nil:
    section.add "globalNetworkId", valid_602151
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
  var valid_602152 = header.getOrDefault("X-Amz-Signature")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Signature", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Content-Sha256", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Date")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Date", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Credential")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Credential", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Security-Token")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Security-Token", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Algorithm")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Algorithm", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-SignedHeaders", valid_602158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602160: Call_CreateLink_602148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new link for a specified site.
  ## 
  let valid = call_602160.validator(path, query, header, formData, body)
  let scheme = call_602160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602160.url(scheme.get, call_602160.host, call_602160.base,
                         call_602160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602160, url, valid)

proc call*(call_602161: Call_CreateLink_602148; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createLink
  ## Creates a new link for a specified site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_602162 = newJObject()
  var body_602163 = newJObject()
  add(path_602162, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_602163 = body
  result = call_602161.call(path_602162, nil, nil, nil, body_602163)

var createLink* = Call_CreateLink_602148(name: "createLink",
                                      meth: HttpMethod.HttpPost,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                      validator: validate_CreateLink_602149,
                                      base: "/", url: url_CreateLink_602150,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinks_602125 = ref object of OpenApiRestCall_601389
proc url_GetLinks_602127(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetLinks_602126(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602128 = path.getOrDefault("globalNetworkId")
  valid_602128 = validateParameter(valid_602128, JString, required = true,
                                 default = nil)
  if valid_602128 != nil:
    section.add "globalNetworkId", valid_602128
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
  var valid_602129 = query.getOrDefault("nextToken")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "nextToken", valid_602129
  var valid_602130 = query.getOrDefault("linkIds")
  valid_602130 = validateParameter(valid_602130, JArray, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "linkIds", valid_602130
  var valid_602131 = query.getOrDefault("MaxResults")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "MaxResults", valid_602131
  var valid_602132 = query.getOrDefault("NextToken")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "NextToken", valid_602132
  var valid_602133 = query.getOrDefault("type")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "type", valid_602133
  var valid_602134 = query.getOrDefault("provider")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "provider", valid_602134
  var valid_602135 = query.getOrDefault("siteId")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "siteId", valid_602135
  var valid_602136 = query.getOrDefault("maxResults")
  valid_602136 = validateParameter(valid_602136, JInt, required = false, default = nil)
  if valid_602136 != nil:
    section.add "maxResults", valid_602136
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
  var valid_602137 = header.getOrDefault("X-Amz-Signature")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Signature", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Content-Sha256", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Date")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Date", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Credential")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Credential", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Security-Token")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Security-Token", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Algorithm")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Algorithm", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-SignedHeaders", valid_602143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602144: Call_GetLinks_602125; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about one or more links in a specified global network.</p> <p>If you specify the site ID, you cannot specify the type or provider in the same request. You can specify the type and provider in the same request.</p>
  ## 
  let valid = call_602144.validator(path, query, header, formData, body)
  let scheme = call_602144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602144.url(scheme.get, call_602144.host, call_602144.base,
                         call_602144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602144, url, valid)

proc call*(call_602145: Call_GetLinks_602125; globalNetworkId: string;
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
  var path_602146 = newJObject()
  var query_602147 = newJObject()
  add(query_602147, "nextToken", newJString(nextToken))
  if linkIds != nil:
    query_602147.add "linkIds", linkIds
  add(query_602147, "MaxResults", newJString(MaxResults))
  add(query_602147, "NextToken", newJString(NextToken))
  add(query_602147, "type", newJString(`type`))
  add(path_602146, "globalNetworkId", newJString(globalNetworkId))
  add(query_602147, "provider", newJString(provider))
  add(query_602147, "siteId", newJString(siteId))
  add(query_602147, "maxResults", newJInt(maxResults))
  result = call_602145.call(path_602146, query_602147, nil, nil, nil)

var getLinks* = Call_GetLinks_602125(name: "getLinks", meth: HttpMethod.HttpGet,
                                  host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                  validator: validate_GetLinks_602126, base: "/",
                                  url: url_GetLinks_602127,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSite_602184 = ref object of OpenApiRestCall_601389
proc url_CreateSite_602186(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateSite_602185(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602187 = path.getOrDefault("globalNetworkId")
  valid_602187 = validateParameter(valid_602187, JString, required = true,
                                 default = nil)
  if valid_602187 != nil:
    section.add "globalNetworkId", valid_602187
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
  var valid_602188 = header.getOrDefault("X-Amz-Signature")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Signature", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Content-Sha256", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Date")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Date", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Credential")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Credential", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Security-Token")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Security-Token", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Algorithm")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Algorithm", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-SignedHeaders", valid_602194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602196: Call_CreateSite_602184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new site in a global network.
  ## 
  let valid = call_602196.validator(path, query, header, formData, body)
  let scheme = call_602196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602196.url(scheme.get, call_602196.host, call_602196.base,
                         call_602196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602196, url, valid)

proc call*(call_602197: Call_CreateSite_602184; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createSite
  ## Creates a new site in a global network.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_602198 = newJObject()
  var body_602199 = newJObject()
  add(path_602198, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_602199 = body
  result = call_602197.call(path_602198, nil, nil, nil, body_602199)

var createSite* = Call_CreateSite_602184(name: "createSite",
                                      meth: HttpMethod.HttpPost,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                      validator: validate_CreateSite_602185,
                                      base: "/", url: url_CreateSite_602186,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSites_602164 = ref object of OpenApiRestCall_601389
proc url_GetSites_602166(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSites_602165(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602167 = path.getOrDefault("globalNetworkId")
  valid_602167 = validateParameter(valid_602167, JString, required = true,
                                 default = nil)
  if valid_602167 != nil:
    section.add "globalNetworkId", valid_602167
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
  var valid_602168 = query.getOrDefault("nextToken")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "nextToken", valid_602168
  var valid_602169 = query.getOrDefault("MaxResults")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "MaxResults", valid_602169
  var valid_602170 = query.getOrDefault("NextToken")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "NextToken", valid_602170
  var valid_602171 = query.getOrDefault("siteIds")
  valid_602171 = validateParameter(valid_602171, JArray, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "siteIds", valid_602171
  var valid_602172 = query.getOrDefault("maxResults")
  valid_602172 = validateParameter(valid_602172, JInt, required = false, default = nil)
  if valid_602172 != nil:
    section.add "maxResults", valid_602172
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
  var valid_602173 = header.getOrDefault("X-Amz-Signature")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Signature", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Content-Sha256", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Date")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Date", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Credential")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Credential", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Security-Token")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Security-Token", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Algorithm")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Algorithm", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-SignedHeaders", valid_602179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602180: Call_GetSites_602164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more of your sites in a global network.
  ## 
  let valid = call_602180.validator(path, query, header, formData, body)
  let scheme = call_602180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602180.url(scheme.get, call_602180.host, call_602180.base,
                         call_602180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602180, url, valid)

proc call*(call_602181: Call_GetSites_602164; globalNetworkId: string;
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
  var path_602182 = newJObject()
  var query_602183 = newJObject()
  add(query_602183, "nextToken", newJString(nextToken))
  add(query_602183, "MaxResults", newJString(MaxResults))
  add(query_602183, "NextToken", newJString(NextToken))
  add(path_602182, "globalNetworkId", newJString(globalNetworkId))
  if siteIds != nil:
    query_602183.add "siteIds", siteIds
  add(query_602183, "maxResults", newJInt(maxResults))
  result = call_602181.call(path_602182, query_602183, nil, nil, nil)

var getSites* = Call_GetSites_602164(name: "getSites", meth: HttpMethod.HttpGet,
                                  host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                  validator: validate_GetSites_602165, base: "/",
                                  url: url_GetSites_602166,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_602215 = ref object of OpenApiRestCall_601389
proc url_UpdateDevice_602217(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDevice_602216(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602218 = path.getOrDefault("globalNetworkId")
  valid_602218 = validateParameter(valid_602218, JString, required = true,
                                 default = nil)
  if valid_602218 != nil:
    section.add "globalNetworkId", valid_602218
  var valid_602219 = path.getOrDefault("deviceId")
  valid_602219 = validateParameter(valid_602219, JString, required = true,
                                 default = nil)
  if valid_602219 != nil:
    section.add "deviceId", valid_602219
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
  var valid_602220 = header.getOrDefault("X-Amz-Signature")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Signature", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Content-Sha256", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Date")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Date", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Credential")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Credential", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Security-Token")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Security-Token", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Algorithm")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Algorithm", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-SignedHeaders", valid_602226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602228: Call_UpdateDevice_602215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_602228.validator(path, query, header, formData, body)
  let scheme = call_602228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602228.url(scheme.get, call_602228.host, call_602228.base,
                         call_602228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602228, url, valid)

proc call*(call_602229: Call_UpdateDevice_602215; globalNetworkId: string;
          body: JsonNode; deviceId: string): Recallable =
  ## updateDevice
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  ##   deviceId: string (required)
  ##           : The ID of the device.
  var path_602230 = newJObject()
  var body_602231 = newJObject()
  add(path_602230, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_602231 = body
  add(path_602230, "deviceId", newJString(deviceId))
  result = call_602229.call(path_602230, nil, nil, nil, body_602231)

var updateDevice* = Call_UpdateDevice_602215(name: "updateDevice",
    meth: HttpMethod.HttpPatch, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_UpdateDevice_602216, base: "/", url: url_UpdateDevice_602217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_602200 = ref object of OpenApiRestCall_601389
proc url_DeleteDevice_602202(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDevice_602201(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602203 = path.getOrDefault("globalNetworkId")
  valid_602203 = validateParameter(valid_602203, JString, required = true,
                                 default = nil)
  if valid_602203 != nil:
    section.add "globalNetworkId", valid_602203
  var valid_602204 = path.getOrDefault("deviceId")
  valid_602204 = validateParameter(valid_602204, JString, required = true,
                                 default = nil)
  if valid_602204 != nil:
    section.add "deviceId", valid_602204
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
  var valid_602205 = header.getOrDefault("X-Amz-Signature")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Signature", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Content-Sha256", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Date")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Date", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Credential")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Credential", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Security-Token")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Security-Token", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Algorithm")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Algorithm", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-SignedHeaders", valid_602211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602212: Call_DeleteDevice_602200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ## 
  let valid = call_602212.validator(path, query, header, formData, body)
  let scheme = call_602212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602212.url(scheme.get, call_602212.host, call_602212.base,
                         call_602212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602212, url, valid)

proc call*(call_602213: Call_DeleteDevice_602200; globalNetworkId: string;
          deviceId: string): Recallable =
  ## deleteDevice
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  var path_602214 = newJObject()
  add(path_602214, "globalNetworkId", newJString(globalNetworkId))
  add(path_602214, "deviceId", newJString(deviceId))
  result = call_602213.call(path_602214, nil, nil, nil, nil)

var deleteDevice* = Call_DeleteDevice_602200(name: "deleteDevice",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_DeleteDevice_602201, base: "/", url: url_DeleteDevice_602202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalNetwork_602246 = ref object of OpenApiRestCall_601389
proc url_UpdateGlobalNetwork_602248(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGlobalNetwork_602247(path: JsonNode; query: JsonNode;
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
  var valid_602249 = path.getOrDefault("globalNetworkId")
  valid_602249 = validateParameter(valid_602249, JString, required = true,
                                 default = nil)
  if valid_602249 != nil:
    section.add "globalNetworkId", valid_602249
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
  var valid_602250 = header.getOrDefault("X-Amz-Signature")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Signature", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Content-Sha256", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Date")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Date", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Credential")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Credential", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Security-Token")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Security-Token", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Algorithm")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Algorithm", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-SignedHeaders", valid_602256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602258: Call_UpdateGlobalNetwork_602246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_602258.validator(path, query, header, formData, body)
  let scheme = call_602258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602258.url(scheme.get, call_602258.host, call_602258.base,
                         call_602258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602258, url, valid)

proc call*(call_602259: Call_UpdateGlobalNetwork_602246; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## updateGlobalNetwork
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ##   globalNetworkId: string (required)
  ##                  : The ID of your global network.
  ##   body: JObject (required)
  var path_602260 = newJObject()
  var body_602261 = newJObject()
  add(path_602260, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_602261 = body
  result = call_602259.call(path_602260, nil, nil, nil, body_602261)

var updateGlobalNetwork* = Call_UpdateGlobalNetwork_602246(
    name: "updateGlobalNetwork", meth: HttpMethod.HttpPatch,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_UpdateGlobalNetwork_602247, base: "/",
    url: url_UpdateGlobalNetwork_602248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGlobalNetwork_602232 = ref object of OpenApiRestCall_601389
proc url_DeleteGlobalNetwork_602234(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGlobalNetwork_602233(path: JsonNode; query: JsonNode;
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
  var valid_602235 = path.getOrDefault("globalNetworkId")
  valid_602235 = validateParameter(valid_602235, JString, required = true,
                                 default = nil)
  if valid_602235 != nil:
    section.add "globalNetworkId", valid_602235
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
  var valid_602236 = header.getOrDefault("X-Amz-Signature")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Signature", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Content-Sha256", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Date")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Date", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Credential")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Credential", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Security-Token")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Security-Token", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Algorithm")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Algorithm", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-SignedHeaders", valid_602242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602243: Call_DeleteGlobalNetwork_602232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ## 
  let valid = call_602243.validator(path, query, header, formData, body)
  let scheme = call_602243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602243.url(scheme.get, call_602243.host, call_602243.base,
                         call_602243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602243, url, valid)

proc call*(call_602244: Call_DeleteGlobalNetwork_602232; globalNetworkId: string): Recallable =
  ## deleteGlobalNetwork
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_602245 = newJObject()
  add(path_602245, "globalNetworkId", newJString(globalNetworkId))
  result = call_602244.call(path_602245, nil, nil, nil, nil)

var deleteGlobalNetwork* = Call_DeleteGlobalNetwork_602232(
    name: "deleteGlobalNetwork", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_DeleteGlobalNetwork_602233, base: "/",
    url: url_DeleteGlobalNetwork_602234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLink_602277 = ref object of OpenApiRestCall_601389
proc url_UpdateLink_602279(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateLink_602278(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602280 = path.getOrDefault("linkId")
  valid_602280 = validateParameter(valid_602280, JString, required = true,
                                 default = nil)
  if valid_602280 != nil:
    section.add "linkId", valid_602280
  var valid_602281 = path.getOrDefault("globalNetworkId")
  valid_602281 = validateParameter(valid_602281, JString, required = true,
                                 default = nil)
  if valid_602281 != nil:
    section.add "globalNetworkId", valid_602281
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
  var valid_602282 = header.getOrDefault("X-Amz-Signature")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Signature", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Content-Sha256", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Date")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Date", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Credential")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Credential", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Security-Token")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Security-Token", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Algorithm")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Algorithm", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-SignedHeaders", valid_602288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602290: Call_UpdateLink_602277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_602290.validator(path, query, header, formData, body)
  let scheme = call_602290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602290.url(scheme.get, call_602290.host, call_602290.base,
                         call_602290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602290, url, valid)

proc call*(call_602291: Call_UpdateLink_602277; linkId: string;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateLink
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ##   linkId: string (required)
  ##         : The ID of the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_602292 = newJObject()
  var body_602293 = newJObject()
  add(path_602292, "linkId", newJString(linkId))
  add(path_602292, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_602293 = body
  result = call_602291.call(path_602292, nil, nil, nil, body_602293)

var updateLink* = Call_UpdateLink_602277(name: "updateLink",
                                      meth: HttpMethod.HttpPatch,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links/{linkId}",
                                      validator: validate_UpdateLink_602278,
                                      base: "/", url: url_UpdateLink_602279,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLink_602262 = ref object of OpenApiRestCall_601389
proc url_DeleteLink_602264(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteLink_602263(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602265 = path.getOrDefault("linkId")
  valid_602265 = validateParameter(valid_602265, JString, required = true,
                                 default = nil)
  if valid_602265 != nil:
    section.add "linkId", valid_602265
  var valid_602266 = path.getOrDefault("globalNetworkId")
  valid_602266 = validateParameter(valid_602266, JString, required = true,
                                 default = nil)
  if valid_602266 != nil:
    section.add "globalNetworkId", valid_602266
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
  var valid_602267 = header.getOrDefault("X-Amz-Signature")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Signature", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Content-Sha256", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Date")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Date", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Credential")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Credential", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Security-Token")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Security-Token", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Algorithm")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Algorithm", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-SignedHeaders", valid_602273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602274: Call_DeleteLink_602262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ## 
  let valid = call_602274.validator(path, query, header, formData, body)
  let scheme = call_602274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602274.url(scheme.get, call_602274.host, call_602274.base,
                         call_602274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602274, url, valid)

proc call*(call_602275: Call_DeleteLink_602262; linkId: string;
          globalNetworkId: string): Recallable =
  ## deleteLink
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ##   linkId: string (required)
  ##         : The ID of the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_602276 = newJObject()
  add(path_602276, "linkId", newJString(linkId))
  add(path_602276, "globalNetworkId", newJString(globalNetworkId))
  result = call_602275.call(path_602276, nil, nil, nil, nil)

var deleteLink* = Call_DeleteLink_602262(name: "deleteLink",
                                      meth: HttpMethod.HttpDelete,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links/{linkId}",
                                      validator: validate_DeleteLink_602263,
                                      base: "/", url: url_DeleteLink_602264,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSite_602309 = ref object of OpenApiRestCall_601389
proc url_UpdateSite_602311(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateSite_602310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602312 = path.getOrDefault("siteId")
  valid_602312 = validateParameter(valid_602312, JString, required = true,
                                 default = nil)
  if valid_602312 != nil:
    section.add "siteId", valid_602312
  var valid_602313 = path.getOrDefault("globalNetworkId")
  valid_602313 = validateParameter(valid_602313, JString, required = true,
                                 default = nil)
  if valid_602313 != nil:
    section.add "globalNetworkId", valid_602313
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
  var valid_602314 = header.getOrDefault("X-Amz-Signature")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Signature", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Content-Sha256", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Date")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Date", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Credential")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Credential", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Security-Token")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Security-Token", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Algorithm")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Algorithm", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-SignedHeaders", valid_602320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602322: Call_UpdateSite_602309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_602322.validator(path, query, header, formData, body)
  let scheme = call_602322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602322.url(scheme.get, call_602322.host, call_602322.base,
                         call_602322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602322, url, valid)

proc call*(call_602323: Call_UpdateSite_602309; siteId: string;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateSite
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ##   siteId: string (required)
  ##         : The ID of your site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_602324 = newJObject()
  var body_602325 = newJObject()
  add(path_602324, "siteId", newJString(siteId))
  add(path_602324, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_602325 = body
  result = call_602323.call(path_602324, nil, nil, nil, body_602325)

var updateSite* = Call_UpdateSite_602309(name: "updateSite",
                                      meth: HttpMethod.HttpPatch,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites/{siteId}",
                                      validator: validate_UpdateSite_602310,
                                      base: "/", url: url_UpdateSite_602311,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSite_602294 = ref object of OpenApiRestCall_601389
proc url_DeleteSite_602296(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteSite_602295(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602297 = path.getOrDefault("siteId")
  valid_602297 = validateParameter(valid_602297, JString, required = true,
                                 default = nil)
  if valid_602297 != nil:
    section.add "siteId", valid_602297
  var valid_602298 = path.getOrDefault("globalNetworkId")
  valid_602298 = validateParameter(valid_602298, JString, required = true,
                                 default = nil)
  if valid_602298 != nil:
    section.add "globalNetworkId", valid_602298
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
  var valid_602299 = header.getOrDefault("X-Amz-Signature")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Signature", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Content-Sha256", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Date")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Date", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Credential")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Credential", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Security-Token")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Security-Token", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Algorithm")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Algorithm", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-SignedHeaders", valid_602305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602306: Call_DeleteSite_602294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ## 
  let valid = call_602306.validator(path, query, header, formData, body)
  let scheme = call_602306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602306.url(scheme.get, call_602306.host, call_602306.base,
                         call_602306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602306, url, valid)

proc call*(call_602307: Call_DeleteSite_602294; siteId: string;
          globalNetworkId: string): Recallable =
  ## deleteSite
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ##   siteId: string (required)
  ##         : The ID of the site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_602308 = newJObject()
  add(path_602308, "siteId", newJString(siteId))
  add(path_602308, "globalNetworkId", newJString(globalNetworkId))
  result = call_602307.call(path_602308, nil, nil, nil, nil)

var deleteSite* = Call_DeleteSite_602294(name: "deleteSite",
                                      meth: HttpMethod.HttpDelete,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites/{siteId}",
                                      validator: validate_DeleteSite_602295,
                                      base: "/", url: url_DeleteSite_602296,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTransitGateway_602326 = ref object of OpenApiRestCall_601389
proc url_DeregisterTransitGateway_602328(protocol: Scheme; host: string;
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

proc validate_DeregisterTransitGateway_602327(path: JsonNode; query: JsonNode;
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
  var valid_602329 = path.getOrDefault("globalNetworkId")
  valid_602329 = validateParameter(valid_602329, JString, required = true,
                                 default = nil)
  if valid_602329 != nil:
    section.add "globalNetworkId", valid_602329
  var valid_602330 = path.getOrDefault("transitGatewayArn")
  valid_602330 = validateParameter(valid_602330, JString, required = true,
                                 default = nil)
  if valid_602330 != nil:
    section.add "transitGatewayArn", valid_602330
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
  var valid_602331 = header.getOrDefault("X-Amz-Signature")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Signature", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Content-Sha256", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Date")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Date", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Credential")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Credential", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Security-Token")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Security-Token", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Algorithm")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Algorithm", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-SignedHeaders", valid_602337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602338: Call_DeregisterTransitGateway_602326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ## 
  let valid = call_602338.validator(path, query, header, formData, body)
  let scheme = call_602338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602338.url(scheme.get, call_602338.host, call_602338.base,
                         call_602338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602338, url, valid)

proc call*(call_602339: Call_DeregisterTransitGateway_602326;
          globalNetworkId: string; transitGatewayArn: string): Recallable =
  ## deregisterTransitGateway
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   transitGatewayArn: string (required)
  ##                    : The Amazon Resource Name (ARN) of the transit gateway.
  var path_602340 = newJObject()
  add(path_602340, "globalNetworkId", newJString(globalNetworkId))
  add(path_602340, "transitGatewayArn", newJString(transitGatewayArn))
  result = call_602339.call(path_602340, nil, nil, nil, nil)

var deregisterTransitGateway* = Call_DeregisterTransitGateway_602326(
    name: "deregisterTransitGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/transit-gateway-registrations/{transitGatewayArn}",
    validator: validate_DeregisterTransitGateway_602327, base: "/",
    url: url_DeregisterTransitGateway_602328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCustomerGateway_602341 = ref object of OpenApiRestCall_601389
proc url_DisassociateCustomerGateway_602343(protocol: Scheme; host: string;
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

proc validate_DisassociateCustomerGateway_602342(path: JsonNode; query: JsonNode;
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
  var valid_602344 = path.getOrDefault("globalNetworkId")
  valid_602344 = validateParameter(valid_602344, JString, required = true,
                                 default = nil)
  if valid_602344 != nil:
    section.add "globalNetworkId", valid_602344
  var valid_602345 = path.getOrDefault("customerGatewayArn")
  valid_602345 = validateParameter(valid_602345, JString, required = true,
                                 default = nil)
  if valid_602345 != nil:
    section.add "customerGatewayArn", valid_602345
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
  var valid_602346 = header.getOrDefault("X-Amz-Signature")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Signature", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Content-Sha256", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Date")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Date", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Credential")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Credential", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Security-Token")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Security-Token", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Algorithm")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Algorithm", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-SignedHeaders", valid_602352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602353: Call_DisassociateCustomerGateway_602341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a customer gateway from a device and a link.
  ## 
  let valid = call_602353.validator(path, query, header, formData, body)
  let scheme = call_602353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602353.url(scheme.get, call_602353.host, call_602353.base,
                         call_602353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602353, url, valid)

proc call*(call_602354: Call_DisassociateCustomerGateway_602341;
          globalNetworkId: string; customerGatewayArn: string): Recallable =
  ## disassociateCustomerGateway
  ## Disassociates a customer gateway from a device and a link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   customerGatewayArn: string (required)
  ##                     : The Amazon Resource Name (ARN) of the customer gateway. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources Defined by Amazon EC2</a>.
  var path_602355 = newJObject()
  add(path_602355, "globalNetworkId", newJString(globalNetworkId))
  add(path_602355, "customerGatewayArn", newJString(customerGatewayArn))
  result = call_602354.call(path_602355, nil, nil, nil, nil)

var disassociateCustomerGateway* = Call_DisassociateCustomerGateway_602341(
    name: "disassociateCustomerGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/customer-gateway-associations/{customerGatewayArn}",
    validator: validate_DisassociateCustomerGateway_602342, base: "/",
    url: url_DisassociateCustomerGateway_602343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateLink_602356 = ref object of OpenApiRestCall_601389
proc url_DisassociateLink_602358(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateLink_602357(path: JsonNode; query: JsonNode;
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
  var valid_602359 = path.getOrDefault("globalNetworkId")
  valid_602359 = validateParameter(valid_602359, JString, required = true,
                                 default = nil)
  if valid_602359 != nil:
    section.add "globalNetworkId", valid_602359
  result.add "path", section
  ## parameters in `query` object:
  ##   deviceId: JString (required)
  ##           : The ID of the device.
  ##   linkId: JString (required)
  ##         : The ID of the link.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `deviceId` field"
  var valid_602360 = query.getOrDefault("deviceId")
  valid_602360 = validateParameter(valid_602360, JString, required = true,
                                 default = nil)
  if valid_602360 != nil:
    section.add "deviceId", valid_602360
  var valid_602361 = query.getOrDefault("linkId")
  valid_602361 = validateParameter(valid_602361, JString, required = true,
                                 default = nil)
  if valid_602361 != nil:
    section.add "linkId", valid_602361
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
  var valid_602362 = header.getOrDefault("X-Amz-Signature")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Signature", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Content-Sha256", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Date")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Date", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Credential")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Credential", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Security-Token")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Security-Token", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Algorithm")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Algorithm", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-SignedHeaders", valid_602368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602369: Call_DisassociateLink_602356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ## 
  let valid = call_602369.validator(path, query, header, formData, body)
  let scheme = call_602369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602369.url(scheme.get, call_602369.host, call_602369.base,
                         call_602369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602369, url, valid)

proc call*(call_602370: Call_DisassociateLink_602356; globalNetworkId: string;
          deviceId: string; linkId: string): Recallable =
  ## disassociateLink
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  ##   linkId: string (required)
  ##         : The ID of the link.
  var path_602371 = newJObject()
  var query_602372 = newJObject()
  add(path_602371, "globalNetworkId", newJString(globalNetworkId))
  add(query_602372, "deviceId", newJString(deviceId))
  add(query_602372, "linkId", newJString(linkId))
  result = call_602370.call(path_602371, query_602372, nil, nil, nil)

var disassociateLink* = Call_DisassociateLink_602356(name: "disassociateLink",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/link-associations#deviceId&linkId",
    validator: validate_DisassociateLink_602357, base: "/",
    url: url_DisassociateLink_602358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTransitGateway_602393 = ref object of OpenApiRestCall_601389
proc url_RegisterTransitGateway_602395(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterTransitGateway_602394(path: JsonNode; query: JsonNode;
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
  var valid_602396 = path.getOrDefault("globalNetworkId")
  valid_602396 = validateParameter(valid_602396, JString, required = true,
                                 default = nil)
  if valid_602396 != nil:
    section.add "globalNetworkId", valid_602396
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
  var valid_602397 = header.getOrDefault("X-Amz-Signature")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Signature", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Content-Sha256", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Date")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Date", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Credential")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Credential", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Security-Token")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Security-Token", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Algorithm")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Algorithm", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-SignedHeaders", valid_602403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602405: Call_RegisterTransitGateway_602393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ## 
  let valid = call_602405.validator(path, query, header, formData, body)
  let scheme = call_602405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602405.url(scheme.get, call_602405.host, call_602405.base,
                         call_602405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602405, url, valid)

proc call*(call_602406: Call_RegisterTransitGateway_602393;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## registerTransitGateway
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_602407 = newJObject()
  var body_602408 = newJObject()
  add(path_602407, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_602408 = body
  result = call_602406.call(path_602407, nil, nil, nil, body_602408)

var registerTransitGateway* = Call_RegisterTransitGateway_602393(
    name: "registerTransitGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_RegisterTransitGateway_602394, base: "/",
    url: url_RegisterTransitGateway_602395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTransitGatewayRegistrations_602373 = ref object of OpenApiRestCall_601389
proc url_GetTransitGatewayRegistrations_602375(protocol: Scheme; host: string;
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

proc validate_GetTransitGatewayRegistrations_602374(path: JsonNode;
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
  var valid_602376 = path.getOrDefault("globalNetworkId")
  valid_602376 = validateParameter(valid_602376, JString, required = true,
                                 default = nil)
  if valid_602376 != nil:
    section.add "globalNetworkId", valid_602376
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
  var valid_602377 = query.getOrDefault("nextToken")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "nextToken", valid_602377
  var valid_602378 = query.getOrDefault("MaxResults")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "MaxResults", valid_602378
  var valid_602379 = query.getOrDefault("transitGatewayArns")
  valid_602379 = validateParameter(valid_602379, JArray, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "transitGatewayArns", valid_602379
  var valid_602380 = query.getOrDefault("NextToken")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "NextToken", valid_602380
  var valid_602381 = query.getOrDefault("maxResults")
  valid_602381 = validateParameter(valid_602381, JInt, required = false, default = nil)
  if valid_602381 != nil:
    section.add "maxResults", valid_602381
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
  var valid_602382 = header.getOrDefault("X-Amz-Signature")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Signature", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Content-Sha256", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Date")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Date", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Credential")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Credential", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Security-Token")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Security-Token", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Algorithm")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Algorithm", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-SignedHeaders", valid_602388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602389: Call_GetTransitGatewayRegistrations_602373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the transit gateway registrations in a specified global network.
  ## 
  let valid = call_602389.validator(path, query, header, formData, body)
  let scheme = call_602389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602389.url(scheme.get, call_602389.host, call_602389.base,
                         call_602389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602389, url, valid)

proc call*(call_602390: Call_GetTransitGatewayRegistrations_602373;
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
  var path_602391 = newJObject()
  var query_602392 = newJObject()
  add(query_602392, "nextToken", newJString(nextToken))
  add(query_602392, "MaxResults", newJString(MaxResults))
  if transitGatewayArns != nil:
    query_602392.add "transitGatewayArns", transitGatewayArns
  add(query_602392, "NextToken", newJString(NextToken))
  add(path_602391, "globalNetworkId", newJString(globalNetworkId))
  add(query_602392, "maxResults", newJInt(maxResults))
  result = call_602390.call(path_602391, query_602392, nil, nil, nil)

var getTransitGatewayRegistrations* = Call_GetTransitGatewayRegistrations_602373(
    name: "getTransitGatewayRegistrations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_GetTransitGatewayRegistrations_602374, base: "/",
    url: url_GetTransitGatewayRegistrations_602375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602423 = ref object of OpenApiRestCall_601389
proc url_TagResource_602425(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602424(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602426 = path.getOrDefault("resourceArn")
  valid_602426 = validateParameter(valid_602426, JString, required = true,
                                 default = nil)
  if valid_602426 != nil:
    section.add "resourceArn", valid_602426
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
  var valid_602427 = header.getOrDefault("X-Amz-Signature")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Signature", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Content-Sha256", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Date")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Date", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Credential")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Credential", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Security-Token")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Security-Token", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Algorithm")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Algorithm", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-SignedHeaders", valid_602433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602435: Call_TagResource_602423; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags a specified resource.
  ## 
  let valid = call_602435.validator(path, query, header, formData, body)
  let scheme = call_602435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602435.url(scheme.get, call_602435.host, call_602435.base,
                         call_602435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602435, url, valid)

proc call*(call_602436: Call_TagResource_602423; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tags a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_602437 = newJObject()
  var body_602438 = newJObject()
  add(path_602437, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_602438 = body
  result = call_602436.call(path_602437, nil, nil, nil, body_602438)

var tagResource* = Call_TagResource_602423(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "networkmanager.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_602424,
                                        base: "/", url: url_TagResource_602425,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602409 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602411(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602410(path: JsonNode; query: JsonNode;
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
  var valid_602412 = path.getOrDefault("resourceArn")
  valid_602412 = validateParameter(valid_602412, JString, required = true,
                                 default = nil)
  if valid_602412 != nil:
    section.add "resourceArn", valid_602412
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
  var valid_602413 = header.getOrDefault("X-Amz-Signature")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Signature", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Content-Sha256", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Date")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Date", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Credential")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Credential", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Security-Token")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Security-Token", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Algorithm")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Algorithm", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-SignedHeaders", valid_602419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602420: Call_ListTagsForResource_602409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for a specified resource.
  ## 
  let valid = call_602420.validator(path, query, header, formData, body)
  let scheme = call_602420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602420.url(scheme.get, call_602420.host, call_602420.base,
                         call_602420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602420, url, valid)

proc call*(call_602421: Call_ListTagsForResource_602409; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_602422 = newJObject()
  add(path_602422, "resourceArn", newJString(resourceArn))
  result = call_602421.call(path_602422, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602409(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_602410, base: "/",
    url: url_ListTagsForResource_602411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602439 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602441(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602440(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602442 = path.getOrDefault("resourceArn")
  valid_602442 = validateParameter(valid_602442, JString, required = true,
                                 default = nil)
  if valid_602442 != nil:
    section.add "resourceArn", valid_602442
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the specified resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602443 = query.getOrDefault("tagKeys")
  valid_602443 = validateParameter(valid_602443, JArray, required = true, default = nil)
  if valid_602443 != nil:
    section.add "tagKeys", valid_602443
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
  var valid_602444 = header.getOrDefault("X-Amz-Signature")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Signature", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Content-Sha256", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Date")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Date", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Credential")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Credential", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-Security-Token")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Security-Token", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Algorithm")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Algorithm", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-SignedHeaders", valid_602450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602451: Call_UntagResource_602439; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a specified resource.
  ## 
  let valid = call_602451.validator(path, query, header, formData, body)
  let scheme = call_602451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602451.url(scheme.get, call_602451.host, call_602451.base,
                         call_602451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602451, url, valid)

proc call*(call_602452: Call_UntagResource_602439; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the specified resource.
  var path_602453 = newJObject()
  var query_602454 = newJObject()
  add(path_602453, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_602454.add "tagKeys", tagKeys
  result = call_602452.call(path_602453, query_602454, nil, nil, nil)

var untagResource* = Call_UntagResource_602439(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_602440,
    base: "/", url: url_UntagResource_602441, schemes: {Scheme.Https, Scheme.Http})
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
