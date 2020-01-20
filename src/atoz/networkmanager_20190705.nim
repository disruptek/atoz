
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
  Call_AssociateCustomerGateway_606203 = ref object of OpenApiRestCall_605589
proc url_AssociateCustomerGateway_606205(protocol: Scheme; host: string;
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

proc validate_AssociateCustomerGateway_606204(path: JsonNode; query: JsonNode;
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
  var valid_606206 = path.getOrDefault("globalNetworkId")
  valid_606206 = validateParameter(valid_606206, JString, required = true,
                                 default = nil)
  if valid_606206 != nil:
    section.add "globalNetworkId", valid_606206
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
  var valid_606207 = header.getOrDefault("X-Amz-Signature")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Signature", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Content-Sha256", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Date")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Date", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Credential")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Credential", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Security-Token")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Security-Token", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Algorithm")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Algorithm", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-SignedHeaders", valid_606213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606215: Call_AssociateCustomerGateway_606203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ## 
  let valid = call_606215.validator(path, query, header, formData, body)
  let scheme = call_606215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606215.url(scheme.get, call_606215.host, call_606215.base,
                         call_606215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606215, url, valid)

proc call*(call_606216: Call_AssociateCustomerGateway_606203;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## associateCustomerGateway
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_606217 = newJObject()
  var body_606218 = newJObject()
  add(path_606217, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_606218 = body
  result = call_606216.call(path_606217, nil, nil, nil, body_606218)

var associateCustomerGateway* = Call_AssociateCustomerGateway_606203(
    name: "associateCustomerGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_AssociateCustomerGateway_606204, base: "/",
    url: url_AssociateCustomerGateway_606205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCustomerGatewayAssociations_605927 = ref object of OpenApiRestCall_605589
proc url_GetCustomerGatewayAssociations_605929(protocol: Scheme; host: string;
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

proc validate_GetCustomerGatewayAssociations_605928(path: JsonNode;
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
  var valid_606055 = path.getOrDefault("globalNetworkId")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "globalNetworkId", valid_606055
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
  var valid_606056 = query.getOrDefault("nextToken")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "nextToken", valid_606056
  var valid_606057 = query.getOrDefault("MaxResults")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "MaxResults", valid_606057
  var valid_606058 = query.getOrDefault("NextToken")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "NextToken", valid_606058
  var valid_606059 = query.getOrDefault("customerGatewayArns")
  valid_606059 = validateParameter(valid_606059, JArray, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "customerGatewayArns", valid_606059
  var valid_606060 = query.getOrDefault("maxResults")
  valid_606060 = validateParameter(valid_606060, JInt, required = false, default = nil)
  if valid_606060 != nil:
    section.add "maxResults", valid_606060
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
  var valid_606061 = header.getOrDefault("X-Amz-Signature")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Signature", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Content-Sha256", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-Date")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-Date", valid_606063
  var valid_606064 = header.getOrDefault("X-Amz-Credential")
  valid_606064 = validateParameter(valid_606064, JString, required = false,
                                 default = nil)
  if valid_606064 != nil:
    section.add "X-Amz-Credential", valid_606064
  var valid_606065 = header.getOrDefault("X-Amz-Security-Token")
  valid_606065 = validateParameter(valid_606065, JString, required = false,
                                 default = nil)
  if valid_606065 != nil:
    section.add "X-Amz-Security-Token", valid_606065
  var valid_606066 = header.getOrDefault("X-Amz-Algorithm")
  valid_606066 = validateParameter(valid_606066, JString, required = false,
                                 default = nil)
  if valid_606066 != nil:
    section.add "X-Amz-Algorithm", valid_606066
  var valid_606067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606067 = validateParameter(valid_606067, JString, required = false,
                                 default = nil)
  if valid_606067 != nil:
    section.add "X-Amz-SignedHeaders", valid_606067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606090: Call_GetCustomerGatewayAssociations_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the association information for customer gateways that are associated with devices and links in your global network.
  ## 
  let valid = call_606090.validator(path, query, header, formData, body)
  let scheme = call_606090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606090.url(scheme.get, call_606090.host, call_606090.base,
                         call_606090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606090, url, valid)

proc call*(call_606161: Call_GetCustomerGatewayAssociations_605927;
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
  var path_606162 = newJObject()
  var query_606164 = newJObject()
  add(query_606164, "nextToken", newJString(nextToken))
  add(query_606164, "MaxResults", newJString(MaxResults))
  add(query_606164, "NextToken", newJString(NextToken))
  add(path_606162, "globalNetworkId", newJString(globalNetworkId))
  if customerGatewayArns != nil:
    query_606164.add "customerGatewayArns", customerGatewayArns
  add(query_606164, "maxResults", newJInt(maxResults))
  result = call_606161.call(path_606162, query_606164, nil, nil, nil)

var getCustomerGatewayAssociations* = Call_GetCustomerGatewayAssociations_605927(
    name: "getCustomerGatewayAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_GetCustomerGatewayAssociations_605928, base: "/",
    url: url_GetCustomerGatewayAssociations_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateLink_606240 = ref object of OpenApiRestCall_605589
proc url_AssociateLink_606242(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateLink_606241(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606243 = path.getOrDefault("globalNetworkId")
  valid_606243 = validateParameter(valid_606243, JString, required = true,
                                 default = nil)
  if valid_606243 != nil:
    section.add "globalNetworkId", valid_606243
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
  var valid_606244 = header.getOrDefault("X-Amz-Signature")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Signature", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Content-Sha256", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Date")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Date", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Credential")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Credential", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Security-Token")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Security-Token", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Algorithm")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Algorithm", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-SignedHeaders", valid_606250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606252: Call_AssociateLink_606240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ## 
  let valid = call_606252.validator(path, query, header, formData, body)
  let scheme = call_606252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606252.url(scheme.get, call_606252.host, call_606252.base,
                         call_606252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606252, url, valid)

proc call*(call_606253: Call_AssociateLink_606240; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## associateLink
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_606254 = newJObject()
  var body_606255 = newJObject()
  add(path_606254, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_606255 = body
  result = call_606253.call(path_606254, nil, nil, nil, body_606255)

var associateLink* = Call_AssociateLink_606240(name: "associateLink",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_AssociateLink_606241, base: "/", url: url_AssociateLink_606242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAssociations_606219 = ref object of OpenApiRestCall_605589
proc url_GetLinkAssociations_606221(protocol: Scheme; host: string; base: string;
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

proc validate_GetLinkAssociations_606220(path: JsonNode; query: JsonNode;
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
  var valid_606222 = path.getOrDefault("globalNetworkId")
  valid_606222 = validateParameter(valid_606222, JString, required = true,
                                 default = nil)
  if valid_606222 != nil:
    section.add "globalNetworkId", valid_606222
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
  var valid_606223 = query.getOrDefault("nextToken")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "nextToken", valid_606223
  var valid_606224 = query.getOrDefault("MaxResults")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "MaxResults", valid_606224
  var valid_606225 = query.getOrDefault("NextToken")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "NextToken", valid_606225
  var valid_606226 = query.getOrDefault("deviceId")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "deviceId", valid_606226
  var valid_606227 = query.getOrDefault("linkId")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "linkId", valid_606227
  var valid_606228 = query.getOrDefault("maxResults")
  valid_606228 = validateParameter(valid_606228, JInt, required = false, default = nil)
  if valid_606228 != nil:
    section.add "maxResults", valid_606228
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
  var valid_606229 = header.getOrDefault("X-Amz-Signature")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Signature", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Content-Sha256", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Date")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Date", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Credential")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Credential", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Security-Token")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Security-Token", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Algorithm")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Algorithm", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-SignedHeaders", valid_606235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606236: Call_GetLinkAssociations_606219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the link associations for a device or a link. Either the device ID or the link ID must be specified.
  ## 
  let valid = call_606236.validator(path, query, header, formData, body)
  let scheme = call_606236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606236.url(scheme.get, call_606236.host, call_606236.base,
                         call_606236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606236, url, valid)

proc call*(call_606237: Call_GetLinkAssociations_606219; globalNetworkId: string;
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
  var path_606238 = newJObject()
  var query_606239 = newJObject()
  add(query_606239, "nextToken", newJString(nextToken))
  add(query_606239, "MaxResults", newJString(MaxResults))
  add(query_606239, "NextToken", newJString(NextToken))
  add(path_606238, "globalNetworkId", newJString(globalNetworkId))
  add(query_606239, "deviceId", newJString(deviceId))
  add(query_606239, "linkId", newJString(linkId))
  add(query_606239, "maxResults", newJInt(maxResults))
  result = call_606237.call(path_606238, query_606239, nil, nil, nil)

var getLinkAssociations* = Call_GetLinkAssociations_606219(
    name: "getLinkAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_GetLinkAssociations_606220, base: "/",
    url: url_GetLinkAssociations_606221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevice_606277 = ref object of OpenApiRestCall_605589
proc url_CreateDevice_606279(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDevice_606278(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606280 = path.getOrDefault("globalNetworkId")
  valid_606280 = validateParameter(valid_606280, JString, required = true,
                                 default = nil)
  if valid_606280 != nil:
    section.add "globalNetworkId", valid_606280
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
  var valid_606281 = header.getOrDefault("X-Amz-Signature")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Signature", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Content-Sha256", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Date")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Date", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Credential")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Credential", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Security-Token")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Security-Token", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Algorithm")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Algorithm", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-SignedHeaders", valid_606287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606289: Call_CreateDevice_606277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ## 
  let valid = call_606289.validator(path, query, header, formData, body)
  let scheme = call_606289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606289.url(scheme.get, call_606289.host, call_606289.base,
                         call_606289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606289, url, valid)

proc call*(call_606290: Call_CreateDevice_606277; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createDevice
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_606291 = newJObject()
  var body_606292 = newJObject()
  add(path_606291, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_606292 = body
  result = call_606290.call(path_606291, nil, nil, nil, body_606292)

var createDevice* = Call_CreateDevice_606277(name: "createDevice",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices",
    validator: validate_CreateDevice_606278, base: "/", url: url_CreateDevice_606279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevices_606256 = ref object of OpenApiRestCall_605589
proc url_GetDevices_606258(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDevices_606257(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606259 = path.getOrDefault("globalNetworkId")
  valid_606259 = validateParameter(valid_606259, JString, required = true,
                                 default = nil)
  if valid_606259 != nil:
    section.add "globalNetworkId", valid_606259
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
  var valid_606260 = query.getOrDefault("nextToken")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "nextToken", valid_606260
  var valid_606261 = query.getOrDefault("MaxResults")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "MaxResults", valid_606261
  var valid_606262 = query.getOrDefault("deviceIds")
  valid_606262 = validateParameter(valid_606262, JArray, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "deviceIds", valid_606262
  var valid_606263 = query.getOrDefault("NextToken")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "NextToken", valid_606263
  var valid_606264 = query.getOrDefault("siteId")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "siteId", valid_606264
  var valid_606265 = query.getOrDefault("maxResults")
  valid_606265 = validateParameter(valid_606265, JInt, required = false, default = nil)
  if valid_606265 != nil:
    section.add "maxResults", valid_606265
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
  var valid_606266 = header.getOrDefault("X-Amz-Signature")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Signature", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Content-Sha256", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Date")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Date", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Credential")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Credential", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Security-Token")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Security-Token", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Algorithm")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Algorithm", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-SignedHeaders", valid_606272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606273: Call_GetDevices_606256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more of your devices in a global network.
  ## 
  let valid = call_606273.validator(path, query, header, formData, body)
  let scheme = call_606273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606273.url(scheme.get, call_606273.host, call_606273.base,
                         call_606273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606273, url, valid)

proc call*(call_606274: Call_GetDevices_606256; globalNetworkId: string;
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
  var path_606275 = newJObject()
  var query_606276 = newJObject()
  add(query_606276, "nextToken", newJString(nextToken))
  add(query_606276, "MaxResults", newJString(MaxResults))
  if deviceIds != nil:
    query_606276.add "deviceIds", deviceIds
  add(query_606276, "NextToken", newJString(NextToken))
  add(path_606275, "globalNetworkId", newJString(globalNetworkId))
  add(query_606276, "siteId", newJString(siteId))
  add(query_606276, "maxResults", newJInt(maxResults))
  result = call_606274.call(path_606275, query_606276, nil, nil, nil)

var getDevices* = Call_GetDevices_606256(name: "getDevices",
                                      meth: HttpMethod.HttpGet,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/devices",
                                      validator: validate_GetDevices_606257,
                                      base: "/", url: url_GetDevices_606258,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGlobalNetwork_606311 = ref object of OpenApiRestCall_605589
proc url_CreateGlobalNetwork_606313(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGlobalNetwork_606312(path: JsonNode; query: JsonNode;
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
  var valid_606314 = header.getOrDefault("X-Amz-Signature")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Signature", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Content-Sha256", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Date")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Date", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Credential")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Credential", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Security-Token")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Security-Token", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Algorithm")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Algorithm", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-SignedHeaders", valid_606320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606322: Call_CreateGlobalNetwork_606311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty global network.
  ## 
  let valid = call_606322.validator(path, query, header, formData, body)
  let scheme = call_606322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606322.url(scheme.get, call_606322.host, call_606322.base,
                         call_606322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606322, url, valid)

proc call*(call_606323: Call_CreateGlobalNetwork_606311; body: JsonNode): Recallable =
  ## createGlobalNetwork
  ## Creates a new, empty global network.
  ##   body: JObject (required)
  var body_606324 = newJObject()
  if body != nil:
    body_606324 = body
  result = call_606323.call(nil, nil, nil, nil, body_606324)

var createGlobalNetwork* = Call_CreateGlobalNetwork_606311(
    name: "createGlobalNetwork", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_CreateGlobalNetwork_606312, base: "/",
    url: url_CreateGlobalNetwork_606313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalNetworks_606293 = ref object of OpenApiRestCall_605589
proc url_DescribeGlobalNetworks_606295(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeGlobalNetworks_606294(path: JsonNode; query: JsonNode;
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
  var valid_606296 = query.getOrDefault("nextToken")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "nextToken", valid_606296
  var valid_606297 = query.getOrDefault("MaxResults")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "MaxResults", valid_606297
  var valid_606298 = query.getOrDefault("NextToken")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "NextToken", valid_606298
  var valid_606299 = query.getOrDefault("globalNetworkIds")
  valid_606299 = validateParameter(valid_606299, JArray, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "globalNetworkIds", valid_606299
  var valid_606300 = query.getOrDefault("maxResults")
  valid_606300 = validateParameter(valid_606300, JInt, required = false, default = nil)
  if valid_606300 != nil:
    section.add "maxResults", valid_606300
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
  var valid_606301 = header.getOrDefault("X-Amz-Signature")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Signature", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Content-Sha256", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Date")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Date", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Credential")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Credential", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Security-Token")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Security-Token", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Algorithm")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Algorithm", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-SignedHeaders", valid_606307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606308: Call_DescribeGlobalNetworks_606293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
  ## 
  let valid = call_606308.validator(path, query, header, formData, body)
  let scheme = call_606308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606308.url(scheme.get, call_606308.host, call_606308.base,
                         call_606308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606308, url, valid)

proc call*(call_606309: Call_DescribeGlobalNetworks_606293; nextToken: string = "";
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
  var query_606310 = newJObject()
  add(query_606310, "nextToken", newJString(nextToken))
  add(query_606310, "MaxResults", newJString(MaxResults))
  add(query_606310, "NextToken", newJString(NextToken))
  if globalNetworkIds != nil:
    query_606310.add "globalNetworkIds", globalNetworkIds
  add(query_606310, "maxResults", newJInt(maxResults))
  result = call_606309.call(nil, query_606310, nil, nil, nil)

var describeGlobalNetworks* = Call_DescribeGlobalNetworks_606293(
    name: "describeGlobalNetworks", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_DescribeGlobalNetworks_606294, base: "/",
    url: url_DescribeGlobalNetworks_606295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLink_606348 = ref object of OpenApiRestCall_605589
proc url_CreateLink_606350(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateLink_606349(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606351 = path.getOrDefault("globalNetworkId")
  valid_606351 = validateParameter(valid_606351, JString, required = true,
                                 default = nil)
  if valid_606351 != nil:
    section.add "globalNetworkId", valid_606351
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
  var valid_606352 = header.getOrDefault("X-Amz-Signature")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Signature", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Content-Sha256", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Date")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Date", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Credential")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Credential", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Security-Token")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Security-Token", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Algorithm")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Algorithm", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-SignedHeaders", valid_606358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606360: Call_CreateLink_606348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new link for a specified site.
  ## 
  let valid = call_606360.validator(path, query, header, formData, body)
  let scheme = call_606360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606360.url(scheme.get, call_606360.host, call_606360.base,
                         call_606360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606360, url, valid)

proc call*(call_606361: Call_CreateLink_606348; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createLink
  ## Creates a new link for a specified site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_606362 = newJObject()
  var body_606363 = newJObject()
  add(path_606362, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_606363 = body
  result = call_606361.call(path_606362, nil, nil, nil, body_606363)

var createLink* = Call_CreateLink_606348(name: "createLink",
                                      meth: HttpMethod.HttpPost,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                      validator: validate_CreateLink_606349,
                                      base: "/", url: url_CreateLink_606350,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinks_606325 = ref object of OpenApiRestCall_605589
proc url_GetLinks_606327(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetLinks_606326(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606328 = path.getOrDefault("globalNetworkId")
  valid_606328 = validateParameter(valid_606328, JString, required = true,
                                 default = nil)
  if valid_606328 != nil:
    section.add "globalNetworkId", valid_606328
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
  var valid_606329 = query.getOrDefault("nextToken")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "nextToken", valid_606329
  var valid_606330 = query.getOrDefault("linkIds")
  valid_606330 = validateParameter(valid_606330, JArray, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "linkIds", valid_606330
  var valid_606331 = query.getOrDefault("MaxResults")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "MaxResults", valid_606331
  var valid_606332 = query.getOrDefault("NextToken")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "NextToken", valid_606332
  var valid_606333 = query.getOrDefault("type")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "type", valid_606333
  var valid_606334 = query.getOrDefault("provider")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "provider", valid_606334
  var valid_606335 = query.getOrDefault("siteId")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "siteId", valid_606335
  var valid_606336 = query.getOrDefault("maxResults")
  valid_606336 = validateParameter(valid_606336, JInt, required = false, default = nil)
  if valid_606336 != nil:
    section.add "maxResults", valid_606336
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
  var valid_606337 = header.getOrDefault("X-Amz-Signature")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Signature", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Content-Sha256", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Date")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Date", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Credential")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Credential", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Security-Token")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Security-Token", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Algorithm")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Algorithm", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-SignedHeaders", valid_606343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606344: Call_GetLinks_606325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about one or more links in a specified global network.</p> <p>If you specify the site ID, you cannot specify the type or provider in the same request. You can specify the type and provider in the same request.</p>
  ## 
  let valid = call_606344.validator(path, query, header, formData, body)
  let scheme = call_606344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606344.url(scheme.get, call_606344.host, call_606344.base,
                         call_606344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606344, url, valid)

proc call*(call_606345: Call_GetLinks_606325; globalNetworkId: string;
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
  var path_606346 = newJObject()
  var query_606347 = newJObject()
  add(query_606347, "nextToken", newJString(nextToken))
  if linkIds != nil:
    query_606347.add "linkIds", linkIds
  add(query_606347, "MaxResults", newJString(MaxResults))
  add(query_606347, "NextToken", newJString(NextToken))
  add(query_606347, "type", newJString(`type`))
  add(path_606346, "globalNetworkId", newJString(globalNetworkId))
  add(query_606347, "provider", newJString(provider))
  add(query_606347, "siteId", newJString(siteId))
  add(query_606347, "maxResults", newJInt(maxResults))
  result = call_606345.call(path_606346, query_606347, nil, nil, nil)

var getLinks* = Call_GetLinks_606325(name: "getLinks", meth: HttpMethod.HttpGet,
                                  host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                  validator: validate_GetLinks_606326, base: "/",
                                  url: url_GetLinks_606327,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSite_606384 = ref object of OpenApiRestCall_605589
proc url_CreateSite_606386(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateSite_606385(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606387 = path.getOrDefault("globalNetworkId")
  valid_606387 = validateParameter(valid_606387, JString, required = true,
                                 default = nil)
  if valid_606387 != nil:
    section.add "globalNetworkId", valid_606387
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
  var valid_606388 = header.getOrDefault("X-Amz-Signature")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Signature", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Content-Sha256", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Date")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Date", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Credential")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Credential", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Security-Token")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Security-Token", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Algorithm")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Algorithm", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-SignedHeaders", valid_606394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606396: Call_CreateSite_606384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new site in a global network.
  ## 
  let valid = call_606396.validator(path, query, header, formData, body)
  let scheme = call_606396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606396.url(scheme.get, call_606396.host, call_606396.base,
                         call_606396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606396, url, valid)

proc call*(call_606397: Call_CreateSite_606384; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createSite
  ## Creates a new site in a global network.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_606398 = newJObject()
  var body_606399 = newJObject()
  add(path_606398, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_606399 = body
  result = call_606397.call(path_606398, nil, nil, nil, body_606399)

var createSite* = Call_CreateSite_606384(name: "createSite",
                                      meth: HttpMethod.HttpPost,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                      validator: validate_CreateSite_606385,
                                      base: "/", url: url_CreateSite_606386,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSites_606364 = ref object of OpenApiRestCall_605589
proc url_GetSites_606366(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSites_606365(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606367 = path.getOrDefault("globalNetworkId")
  valid_606367 = validateParameter(valid_606367, JString, required = true,
                                 default = nil)
  if valid_606367 != nil:
    section.add "globalNetworkId", valid_606367
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
  var valid_606368 = query.getOrDefault("nextToken")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "nextToken", valid_606368
  var valid_606369 = query.getOrDefault("MaxResults")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "MaxResults", valid_606369
  var valid_606370 = query.getOrDefault("NextToken")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "NextToken", valid_606370
  var valid_606371 = query.getOrDefault("siteIds")
  valid_606371 = validateParameter(valid_606371, JArray, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "siteIds", valid_606371
  var valid_606372 = query.getOrDefault("maxResults")
  valid_606372 = validateParameter(valid_606372, JInt, required = false, default = nil)
  if valid_606372 != nil:
    section.add "maxResults", valid_606372
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
  var valid_606373 = header.getOrDefault("X-Amz-Signature")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Signature", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Content-Sha256", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Date")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Date", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Credential")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Credential", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Security-Token")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Security-Token", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Algorithm")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Algorithm", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-SignedHeaders", valid_606379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606380: Call_GetSites_606364; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more of your sites in a global network.
  ## 
  let valid = call_606380.validator(path, query, header, formData, body)
  let scheme = call_606380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606380.url(scheme.get, call_606380.host, call_606380.base,
                         call_606380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606380, url, valid)

proc call*(call_606381: Call_GetSites_606364; globalNetworkId: string;
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
  var path_606382 = newJObject()
  var query_606383 = newJObject()
  add(query_606383, "nextToken", newJString(nextToken))
  add(query_606383, "MaxResults", newJString(MaxResults))
  add(query_606383, "NextToken", newJString(NextToken))
  add(path_606382, "globalNetworkId", newJString(globalNetworkId))
  if siteIds != nil:
    query_606383.add "siteIds", siteIds
  add(query_606383, "maxResults", newJInt(maxResults))
  result = call_606381.call(path_606382, query_606383, nil, nil, nil)

var getSites* = Call_GetSites_606364(name: "getSites", meth: HttpMethod.HttpGet,
                                  host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                  validator: validate_GetSites_606365, base: "/",
                                  url: url_GetSites_606366,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_606415 = ref object of OpenApiRestCall_605589
proc url_UpdateDevice_606417(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDevice_606416(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606418 = path.getOrDefault("globalNetworkId")
  valid_606418 = validateParameter(valid_606418, JString, required = true,
                                 default = nil)
  if valid_606418 != nil:
    section.add "globalNetworkId", valid_606418
  var valid_606419 = path.getOrDefault("deviceId")
  valid_606419 = validateParameter(valid_606419, JString, required = true,
                                 default = nil)
  if valid_606419 != nil:
    section.add "deviceId", valid_606419
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
  var valid_606420 = header.getOrDefault("X-Amz-Signature")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Signature", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Content-Sha256", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Date")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Date", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Credential")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Credential", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Security-Token")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Security-Token", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Algorithm")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Algorithm", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-SignedHeaders", valid_606426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606428: Call_UpdateDevice_606415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_606428.validator(path, query, header, formData, body)
  let scheme = call_606428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606428.url(scheme.get, call_606428.host, call_606428.base,
                         call_606428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606428, url, valid)

proc call*(call_606429: Call_UpdateDevice_606415; globalNetworkId: string;
          body: JsonNode; deviceId: string): Recallable =
  ## updateDevice
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  ##   deviceId: string (required)
  ##           : The ID of the device.
  var path_606430 = newJObject()
  var body_606431 = newJObject()
  add(path_606430, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_606431 = body
  add(path_606430, "deviceId", newJString(deviceId))
  result = call_606429.call(path_606430, nil, nil, nil, body_606431)

var updateDevice* = Call_UpdateDevice_606415(name: "updateDevice",
    meth: HttpMethod.HttpPatch, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_UpdateDevice_606416, base: "/", url: url_UpdateDevice_606417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_606400 = ref object of OpenApiRestCall_605589
proc url_DeleteDevice_606402(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDevice_606401(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606403 = path.getOrDefault("globalNetworkId")
  valid_606403 = validateParameter(valid_606403, JString, required = true,
                                 default = nil)
  if valid_606403 != nil:
    section.add "globalNetworkId", valid_606403
  var valid_606404 = path.getOrDefault("deviceId")
  valid_606404 = validateParameter(valid_606404, JString, required = true,
                                 default = nil)
  if valid_606404 != nil:
    section.add "deviceId", valid_606404
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
  var valid_606405 = header.getOrDefault("X-Amz-Signature")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Signature", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Content-Sha256", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Date")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Date", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Credential")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Credential", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Security-Token")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Security-Token", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Algorithm")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Algorithm", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-SignedHeaders", valid_606411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606412: Call_DeleteDevice_606400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ## 
  let valid = call_606412.validator(path, query, header, formData, body)
  let scheme = call_606412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606412.url(scheme.get, call_606412.host, call_606412.base,
                         call_606412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606412, url, valid)

proc call*(call_606413: Call_DeleteDevice_606400; globalNetworkId: string;
          deviceId: string): Recallable =
  ## deleteDevice
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  var path_606414 = newJObject()
  add(path_606414, "globalNetworkId", newJString(globalNetworkId))
  add(path_606414, "deviceId", newJString(deviceId))
  result = call_606413.call(path_606414, nil, nil, nil, nil)

var deleteDevice* = Call_DeleteDevice_606400(name: "deleteDevice",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_DeleteDevice_606401, base: "/", url: url_DeleteDevice_606402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalNetwork_606446 = ref object of OpenApiRestCall_605589
proc url_UpdateGlobalNetwork_606448(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGlobalNetwork_606447(path: JsonNode; query: JsonNode;
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
  var valid_606449 = path.getOrDefault("globalNetworkId")
  valid_606449 = validateParameter(valid_606449, JString, required = true,
                                 default = nil)
  if valid_606449 != nil:
    section.add "globalNetworkId", valid_606449
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
  var valid_606450 = header.getOrDefault("X-Amz-Signature")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Signature", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Content-Sha256", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Date")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Date", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Credential")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Credential", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-Security-Token")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Security-Token", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Algorithm")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Algorithm", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-SignedHeaders", valid_606456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606458: Call_UpdateGlobalNetwork_606446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_606458.validator(path, query, header, formData, body)
  let scheme = call_606458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606458.url(scheme.get, call_606458.host, call_606458.base,
                         call_606458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606458, url, valid)

proc call*(call_606459: Call_UpdateGlobalNetwork_606446; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## updateGlobalNetwork
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ##   globalNetworkId: string (required)
  ##                  : The ID of your global network.
  ##   body: JObject (required)
  var path_606460 = newJObject()
  var body_606461 = newJObject()
  add(path_606460, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_606461 = body
  result = call_606459.call(path_606460, nil, nil, nil, body_606461)

var updateGlobalNetwork* = Call_UpdateGlobalNetwork_606446(
    name: "updateGlobalNetwork", meth: HttpMethod.HttpPatch,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_UpdateGlobalNetwork_606447, base: "/",
    url: url_UpdateGlobalNetwork_606448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGlobalNetwork_606432 = ref object of OpenApiRestCall_605589
proc url_DeleteGlobalNetwork_606434(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGlobalNetwork_606433(path: JsonNode; query: JsonNode;
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
  var valid_606435 = path.getOrDefault("globalNetworkId")
  valid_606435 = validateParameter(valid_606435, JString, required = true,
                                 default = nil)
  if valid_606435 != nil:
    section.add "globalNetworkId", valid_606435
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
  var valid_606436 = header.getOrDefault("X-Amz-Signature")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Signature", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Content-Sha256", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Date")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Date", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Credential")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Credential", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Security-Token")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Security-Token", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Algorithm")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Algorithm", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-SignedHeaders", valid_606442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606443: Call_DeleteGlobalNetwork_606432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ## 
  let valid = call_606443.validator(path, query, header, formData, body)
  let scheme = call_606443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606443.url(scheme.get, call_606443.host, call_606443.base,
                         call_606443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606443, url, valid)

proc call*(call_606444: Call_DeleteGlobalNetwork_606432; globalNetworkId: string): Recallable =
  ## deleteGlobalNetwork
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_606445 = newJObject()
  add(path_606445, "globalNetworkId", newJString(globalNetworkId))
  result = call_606444.call(path_606445, nil, nil, nil, nil)

var deleteGlobalNetwork* = Call_DeleteGlobalNetwork_606432(
    name: "deleteGlobalNetwork", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_DeleteGlobalNetwork_606433, base: "/",
    url: url_DeleteGlobalNetwork_606434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLink_606477 = ref object of OpenApiRestCall_605589
proc url_UpdateLink_606479(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateLink_606478(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606480 = path.getOrDefault("linkId")
  valid_606480 = validateParameter(valid_606480, JString, required = true,
                                 default = nil)
  if valid_606480 != nil:
    section.add "linkId", valid_606480
  var valid_606481 = path.getOrDefault("globalNetworkId")
  valid_606481 = validateParameter(valid_606481, JString, required = true,
                                 default = nil)
  if valid_606481 != nil:
    section.add "globalNetworkId", valid_606481
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
  var valid_606482 = header.getOrDefault("X-Amz-Signature")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Signature", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Content-Sha256", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Date")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Date", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Credential")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Credential", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Security-Token")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Security-Token", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Algorithm")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Algorithm", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-SignedHeaders", valid_606488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606490: Call_UpdateLink_606477; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_606490.validator(path, query, header, formData, body)
  let scheme = call_606490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606490.url(scheme.get, call_606490.host, call_606490.base,
                         call_606490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606490, url, valid)

proc call*(call_606491: Call_UpdateLink_606477; linkId: string;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateLink
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ##   linkId: string (required)
  ##         : The ID of the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_606492 = newJObject()
  var body_606493 = newJObject()
  add(path_606492, "linkId", newJString(linkId))
  add(path_606492, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_606493 = body
  result = call_606491.call(path_606492, nil, nil, nil, body_606493)

var updateLink* = Call_UpdateLink_606477(name: "updateLink",
                                      meth: HttpMethod.HttpPatch,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links/{linkId}",
                                      validator: validate_UpdateLink_606478,
                                      base: "/", url: url_UpdateLink_606479,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLink_606462 = ref object of OpenApiRestCall_605589
proc url_DeleteLink_606464(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteLink_606463(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606465 = path.getOrDefault("linkId")
  valid_606465 = validateParameter(valid_606465, JString, required = true,
                                 default = nil)
  if valid_606465 != nil:
    section.add "linkId", valid_606465
  var valid_606466 = path.getOrDefault("globalNetworkId")
  valid_606466 = validateParameter(valid_606466, JString, required = true,
                                 default = nil)
  if valid_606466 != nil:
    section.add "globalNetworkId", valid_606466
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
  var valid_606467 = header.getOrDefault("X-Amz-Signature")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Signature", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Content-Sha256", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Date")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Date", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Credential")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Credential", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Security-Token")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Security-Token", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Algorithm")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Algorithm", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-SignedHeaders", valid_606473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606474: Call_DeleteLink_606462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ## 
  let valid = call_606474.validator(path, query, header, formData, body)
  let scheme = call_606474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606474.url(scheme.get, call_606474.host, call_606474.base,
                         call_606474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606474, url, valid)

proc call*(call_606475: Call_DeleteLink_606462; linkId: string;
          globalNetworkId: string): Recallable =
  ## deleteLink
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ##   linkId: string (required)
  ##         : The ID of the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_606476 = newJObject()
  add(path_606476, "linkId", newJString(linkId))
  add(path_606476, "globalNetworkId", newJString(globalNetworkId))
  result = call_606475.call(path_606476, nil, nil, nil, nil)

var deleteLink* = Call_DeleteLink_606462(name: "deleteLink",
                                      meth: HttpMethod.HttpDelete,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links/{linkId}",
                                      validator: validate_DeleteLink_606463,
                                      base: "/", url: url_DeleteLink_606464,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSite_606509 = ref object of OpenApiRestCall_605589
proc url_UpdateSite_606511(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateSite_606510(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606512 = path.getOrDefault("siteId")
  valid_606512 = validateParameter(valid_606512, JString, required = true,
                                 default = nil)
  if valid_606512 != nil:
    section.add "siteId", valid_606512
  var valid_606513 = path.getOrDefault("globalNetworkId")
  valid_606513 = validateParameter(valid_606513, JString, required = true,
                                 default = nil)
  if valid_606513 != nil:
    section.add "globalNetworkId", valid_606513
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
  var valid_606514 = header.getOrDefault("X-Amz-Signature")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Signature", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Content-Sha256", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Date")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Date", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Credential")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Credential", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Security-Token")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Security-Token", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Algorithm")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Algorithm", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-SignedHeaders", valid_606520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606522: Call_UpdateSite_606509; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_606522.validator(path, query, header, formData, body)
  let scheme = call_606522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606522.url(scheme.get, call_606522.host, call_606522.base,
                         call_606522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606522, url, valid)

proc call*(call_606523: Call_UpdateSite_606509; siteId: string;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateSite
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ##   siteId: string (required)
  ##         : The ID of your site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_606524 = newJObject()
  var body_606525 = newJObject()
  add(path_606524, "siteId", newJString(siteId))
  add(path_606524, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_606525 = body
  result = call_606523.call(path_606524, nil, nil, nil, body_606525)

var updateSite* = Call_UpdateSite_606509(name: "updateSite",
                                      meth: HttpMethod.HttpPatch,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites/{siteId}",
                                      validator: validate_UpdateSite_606510,
                                      base: "/", url: url_UpdateSite_606511,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSite_606494 = ref object of OpenApiRestCall_605589
proc url_DeleteSite_606496(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteSite_606495(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606497 = path.getOrDefault("siteId")
  valid_606497 = validateParameter(valid_606497, JString, required = true,
                                 default = nil)
  if valid_606497 != nil:
    section.add "siteId", valid_606497
  var valid_606498 = path.getOrDefault("globalNetworkId")
  valid_606498 = validateParameter(valid_606498, JString, required = true,
                                 default = nil)
  if valid_606498 != nil:
    section.add "globalNetworkId", valid_606498
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
  var valid_606499 = header.getOrDefault("X-Amz-Signature")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Signature", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Content-Sha256", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Date")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Date", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Credential")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Credential", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Security-Token")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Security-Token", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Algorithm")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Algorithm", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-SignedHeaders", valid_606505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606506: Call_DeleteSite_606494; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ## 
  let valid = call_606506.validator(path, query, header, formData, body)
  let scheme = call_606506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606506.url(scheme.get, call_606506.host, call_606506.base,
                         call_606506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606506, url, valid)

proc call*(call_606507: Call_DeleteSite_606494; siteId: string;
          globalNetworkId: string): Recallable =
  ## deleteSite
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ##   siteId: string (required)
  ##         : The ID of the site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_606508 = newJObject()
  add(path_606508, "siteId", newJString(siteId))
  add(path_606508, "globalNetworkId", newJString(globalNetworkId))
  result = call_606507.call(path_606508, nil, nil, nil, nil)

var deleteSite* = Call_DeleteSite_606494(name: "deleteSite",
                                      meth: HttpMethod.HttpDelete,
                                      host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites/{siteId}",
                                      validator: validate_DeleteSite_606495,
                                      base: "/", url: url_DeleteSite_606496,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTransitGateway_606526 = ref object of OpenApiRestCall_605589
proc url_DeregisterTransitGateway_606528(protocol: Scheme; host: string;
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

proc validate_DeregisterTransitGateway_606527(path: JsonNode; query: JsonNode;
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
  var valid_606529 = path.getOrDefault("globalNetworkId")
  valid_606529 = validateParameter(valid_606529, JString, required = true,
                                 default = nil)
  if valid_606529 != nil:
    section.add "globalNetworkId", valid_606529
  var valid_606530 = path.getOrDefault("transitGatewayArn")
  valid_606530 = validateParameter(valid_606530, JString, required = true,
                                 default = nil)
  if valid_606530 != nil:
    section.add "transitGatewayArn", valid_606530
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
  var valid_606531 = header.getOrDefault("X-Amz-Signature")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Signature", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Content-Sha256", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Date")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Date", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Credential")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Credential", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Security-Token")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Security-Token", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Algorithm")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Algorithm", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-SignedHeaders", valid_606537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606538: Call_DeregisterTransitGateway_606526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ## 
  let valid = call_606538.validator(path, query, header, formData, body)
  let scheme = call_606538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606538.url(scheme.get, call_606538.host, call_606538.base,
                         call_606538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606538, url, valid)

proc call*(call_606539: Call_DeregisterTransitGateway_606526;
          globalNetworkId: string; transitGatewayArn: string): Recallable =
  ## deregisterTransitGateway
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   transitGatewayArn: string (required)
  ##                    : The Amazon Resource Name (ARN) of the transit gateway.
  var path_606540 = newJObject()
  add(path_606540, "globalNetworkId", newJString(globalNetworkId))
  add(path_606540, "transitGatewayArn", newJString(transitGatewayArn))
  result = call_606539.call(path_606540, nil, nil, nil, nil)

var deregisterTransitGateway* = Call_DeregisterTransitGateway_606526(
    name: "deregisterTransitGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/transit-gateway-registrations/{transitGatewayArn}",
    validator: validate_DeregisterTransitGateway_606527, base: "/",
    url: url_DeregisterTransitGateway_606528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCustomerGateway_606541 = ref object of OpenApiRestCall_605589
proc url_DisassociateCustomerGateway_606543(protocol: Scheme; host: string;
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

proc validate_DisassociateCustomerGateway_606542(path: JsonNode; query: JsonNode;
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
  var valid_606544 = path.getOrDefault("globalNetworkId")
  valid_606544 = validateParameter(valid_606544, JString, required = true,
                                 default = nil)
  if valid_606544 != nil:
    section.add "globalNetworkId", valid_606544
  var valid_606545 = path.getOrDefault("customerGatewayArn")
  valid_606545 = validateParameter(valid_606545, JString, required = true,
                                 default = nil)
  if valid_606545 != nil:
    section.add "customerGatewayArn", valid_606545
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
  var valid_606546 = header.getOrDefault("X-Amz-Signature")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Signature", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Content-Sha256", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Date")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Date", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Credential")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Credential", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Security-Token")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Security-Token", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Algorithm")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Algorithm", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-SignedHeaders", valid_606552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606553: Call_DisassociateCustomerGateway_606541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a customer gateway from a device and a link.
  ## 
  let valid = call_606553.validator(path, query, header, formData, body)
  let scheme = call_606553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606553.url(scheme.get, call_606553.host, call_606553.base,
                         call_606553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606553, url, valid)

proc call*(call_606554: Call_DisassociateCustomerGateway_606541;
          globalNetworkId: string; customerGatewayArn: string): Recallable =
  ## disassociateCustomerGateway
  ## Disassociates a customer gateway from a device and a link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   customerGatewayArn: string (required)
  ##                     : The Amazon Resource Name (ARN) of the customer gateway. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources Defined by Amazon EC2</a>.
  var path_606555 = newJObject()
  add(path_606555, "globalNetworkId", newJString(globalNetworkId))
  add(path_606555, "customerGatewayArn", newJString(customerGatewayArn))
  result = call_606554.call(path_606555, nil, nil, nil, nil)

var disassociateCustomerGateway* = Call_DisassociateCustomerGateway_606541(
    name: "disassociateCustomerGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/customer-gateway-associations/{customerGatewayArn}",
    validator: validate_DisassociateCustomerGateway_606542, base: "/",
    url: url_DisassociateCustomerGateway_606543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateLink_606556 = ref object of OpenApiRestCall_605589
proc url_DisassociateLink_606558(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateLink_606557(path: JsonNode; query: JsonNode;
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
  var valid_606559 = path.getOrDefault("globalNetworkId")
  valid_606559 = validateParameter(valid_606559, JString, required = true,
                                 default = nil)
  if valid_606559 != nil:
    section.add "globalNetworkId", valid_606559
  result.add "path", section
  ## parameters in `query` object:
  ##   deviceId: JString (required)
  ##           : The ID of the device.
  ##   linkId: JString (required)
  ##         : The ID of the link.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `deviceId` field"
  var valid_606560 = query.getOrDefault("deviceId")
  valid_606560 = validateParameter(valid_606560, JString, required = true,
                                 default = nil)
  if valid_606560 != nil:
    section.add "deviceId", valid_606560
  var valid_606561 = query.getOrDefault("linkId")
  valid_606561 = validateParameter(valid_606561, JString, required = true,
                                 default = nil)
  if valid_606561 != nil:
    section.add "linkId", valid_606561
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
  var valid_606562 = header.getOrDefault("X-Amz-Signature")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Signature", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Content-Sha256", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Date")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Date", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Credential")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Credential", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Security-Token")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Security-Token", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Algorithm")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Algorithm", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-SignedHeaders", valid_606568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606569: Call_DisassociateLink_606556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ## 
  let valid = call_606569.validator(path, query, header, formData, body)
  let scheme = call_606569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606569.url(scheme.get, call_606569.host, call_606569.base,
                         call_606569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606569, url, valid)

proc call*(call_606570: Call_DisassociateLink_606556; globalNetworkId: string;
          deviceId: string; linkId: string): Recallable =
  ## disassociateLink
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  ##   linkId: string (required)
  ##         : The ID of the link.
  var path_606571 = newJObject()
  var query_606572 = newJObject()
  add(path_606571, "globalNetworkId", newJString(globalNetworkId))
  add(query_606572, "deviceId", newJString(deviceId))
  add(query_606572, "linkId", newJString(linkId))
  result = call_606570.call(path_606571, query_606572, nil, nil, nil)

var disassociateLink* = Call_DisassociateLink_606556(name: "disassociateLink",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/link-associations#deviceId&linkId",
    validator: validate_DisassociateLink_606557, base: "/",
    url: url_DisassociateLink_606558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTransitGateway_606593 = ref object of OpenApiRestCall_605589
proc url_RegisterTransitGateway_606595(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterTransitGateway_606594(path: JsonNode; query: JsonNode;
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
  var valid_606596 = path.getOrDefault("globalNetworkId")
  valid_606596 = validateParameter(valid_606596, JString, required = true,
                                 default = nil)
  if valid_606596 != nil:
    section.add "globalNetworkId", valid_606596
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
  var valid_606597 = header.getOrDefault("X-Amz-Signature")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Signature", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Content-Sha256", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Date")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Date", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Credential")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Credential", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Security-Token")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Security-Token", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Algorithm")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Algorithm", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-SignedHeaders", valid_606603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606605: Call_RegisterTransitGateway_606593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ## 
  let valid = call_606605.validator(path, query, header, formData, body)
  let scheme = call_606605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606605.url(scheme.get, call_606605.host, call_606605.base,
                         call_606605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606605, url, valid)

proc call*(call_606606: Call_RegisterTransitGateway_606593;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## registerTransitGateway
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_606607 = newJObject()
  var body_606608 = newJObject()
  add(path_606607, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_606608 = body
  result = call_606606.call(path_606607, nil, nil, nil, body_606608)

var registerTransitGateway* = Call_RegisterTransitGateway_606593(
    name: "registerTransitGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_RegisterTransitGateway_606594, base: "/",
    url: url_RegisterTransitGateway_606595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTransitGatewayRegistrations_606573 = ref object of OpenApiRestCall_605589
proc url_GetTransitGatewayRegistrations_606575(protocol: Scheme; host: string;
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

proc validate_GetTransitGatewayRegistrations_606574(path: JsonNode;
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
  var valid_606576 = path.getOrDefault("globalNetworkId")
  valid_606576 = validateParameter(valid_606576, JString, required = true,
                                 default = nil)
  if valid_606576 != nil:
    section.add "globalNetworkId", valid_606576
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
  var valid_606577 = query.getOrDefault("nextToken")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "nextToken", valid_606577
  var valid_606578 = query.getOrDefault("MaxResults")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "MaxResults", valid_606578
  var valid_606579 = query.getOrDefault("transitGatewayArns")
  valid_606579 = validateParameter(valid_606579, JArray, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "transitGatewayArns", valid_606579
  var valid_606580 = query.getOrDefault("NextToken")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "NextToken", valid_606580
  var valid_606581 = query.getOrDefault("maxResults")
  valid_606581 = validateParameter(valid_606581, JInt, required = false, default = nil)
  if valid_606581 != nil:
    section.add "maxResults", valid_606581
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
  var valid_606582 = header.getOrDefault("X-Amz-Signature")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Signature", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Content-Sha256", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Date")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Date", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Credential")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Credential", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Security-Token")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Security-Token", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-Algorithm")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Algorithm", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-SignedHeaders", valid_606588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606589: Call_GetTransitGatewayRegistrations_606573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the transit gateway registrations in a specified global network.
  ## 
  let valid = call_606589.validator(path, query, header, formData, body)
  let scheme = call_606589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606589.url(scheme.get, call_606589.host, call_606589.base,
                         call_606589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606589, url, valid)

proc call*(call_606590: Call_GetTransitGatewayRegistrations_606573;
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
  var path_606591 = newJObject()
  var query_606592 = newJObject()
  add(query_606592, "nextToken", newJString(nextToken))
  add(query_606592, "MaxResults", newJString(MaxResults))
  if transitGatewayArns != nil:
    query_606592.add "transitGatewayArns", transitGatewayArns
  add(query_606592, "NextToken", newJString(NextToken))
  add(path_606591, "globalNetworkId", newJString(globalNetworkId))
  add(query_606592, "maxResults", newJInt(maxResults))
  result = call_606590.call(path_606591, query_606592, nil, nil, nil)

var getTransitGatewayRegistrations* = Call_GetTransitGatewayRegistrations_606573(
    name: "getTransitGatewayRegistrations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_GetTransitGatewayRegistrations_606574, base: "/",
    url: url_GetTransitGatewayRegistrations_606575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606623 = ref object of OpenApiRestCall_605589
proc url_TagResource_606625(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606624(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606626 = path.getOrDefault("resourceArn")
  valid_606626 = validateParameter(valid_606626, JString, required = true,
                                 default = nil)
  if valid_606626 != nil:
    section.add "resourceArn", valid_606626
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
  var valid_606627 = header.getOrDefault("X-Amz-Signature")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Signature", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Content-Sha256", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Date")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Date", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Credential")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Credential", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-Security-Token")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Security-Token", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-Algorithm")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Algorithm", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-SignedHeaders", valid_606633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606635: Call_TagResource_606623; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags a specified resource.
  ## 
  let valid = call_606635.validator(path, query, header, formData, body)
  let scheme = call_606635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606635.url(scheme.get, call_606635.host, call_606635.base,
                         call_606635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606635, url, valid)

proc call*(call_606636: Call_TagResource_606623; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tags a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_606637 = newJObject()
  var body_606638 = newJObject()
  add(path_606637, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606638 = body
  result = call_606636.call(path_606637, nil, nil, nil, body_606638)

var tagResource* = Call_TagResource_606623(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "networkmanager.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_606624,
                                        base: "/", url: url_TagResource_606625,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606609 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606611(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606610(path: JsonNode; query: JsonNode;
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
  var valid_606612 = path.getOrDefault("resourceArn")
  valid_606612 = validateParameter(valid_606612, JString, required = true,
                                 default = nil)
  if valid_606612 != nil:
    section.add "resourceArn", valid_606612
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
  var valid_606613 = header.getOrDefault("X-Amz-Signature")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Signature", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Content-Sha256", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Date")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Date", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Credential")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Credential", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Security-Token")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Security-Token", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Algorithm")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Algorithm", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-SignedHeaders", valid_606619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606620: Call_ListTagsForResource_606609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for a specified resource.
  ## 
  let valid = call_606620.validator(path, query, header, formData, body)
  let scheme = call_606620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606620.url(scheme.get, call_606620.host, call_606620.base,
                         call_606620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606620, url, valid)

proc call*(call_606621: Call_ListTagsForResource_606609; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_606622 = newJObject()
  add(path_606622, "resourceArn", newJString(resourceArn))
  result = call_606621.call(path_606622, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606609(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_606610, base: "/",
    url: url_ListTagsForResource_606611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606639 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606641(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606640(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606642 = path.getOrDefault("resourceArn")
  valid_606642 = validateParameter(valid_606642, JString, required = true,
                                 default = nil)
  if valid_606642 != nil:
    section.add "resourceArn", valid_606642
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the specified resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606643 = query.getOrDefault("tagKeys")
  valid_606643 = validateParameter(valid_606643, JArray, required = true, default = nil)
  if valid_606643 != nil:
    section.add "tagKeys", valid_606643
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
  var valid_606644 = header.getOrDefault("X-Amz-Signature")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Signature", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Content-Sha256", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Date")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Date", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-Credential")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Credential", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-Security-Token")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-Security-Token", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-Algorithm")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-Algorithm", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-SignedHeaders", valid_606650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606651: Call_UntagResource_606639; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a specified resource.
  ## 
  let valid = call_606651.validator(path, query, header, formData, body)
  let scheme = call_606651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606651.url(scheme.get, call_606651.host, call_606651.base,
                         call_606651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606651, url, valid)

proc call*(call_606652: Call_UntagResource_606639; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the specified resource.
  var path_606653 = newJObject()
  var query_606654 = newJObject()
  add(path_606653, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_606654.add "tagKeys", tagKeys
  result = call_606652.call(path_606653, query_606654, nil, nil, nil)

var untagResource* = Call_UntagResource_606639(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_606640,
    base: "/", url: url_UntagResource_606641, schemes: {Scheme.Https, Scheme.Http})
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
