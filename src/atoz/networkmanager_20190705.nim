
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AssociateCustomerGateway_21626037 = ref object of OpenApiRestCall_21625435
proc url_AssociateCustomerGateway_21626039(protocol: Scheme; host: string;
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

proc validate_AssociateCustomerGateway_21626038(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626040 = path.getOrDefault("globalNetworkId")
  valid_21626040 = validateParameter(valid_21626040, JString, required = true,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "globalNetworkId", valid_21626040
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626041 = header.getOrDefault("X-Amz-Date")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Date", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Security-Token", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Algorithm", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Signature")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Signature", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Credential")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Credential", valid_21626047
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

proc call*(call_21626049: Call_AssociateCustomerGateway_21626037;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ## 
  let valid = call_21626049.validator(path, query, header, formData, body, _)
  let scheme = call_21626049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626049.makeUrl(scheme.get, call_21626049.host, call_21626049.base,
                               call_21626049.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626049, uri, valid, _)

proc call*(call_21626050: Call_AssociateCustomerGateway_21626037;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## associateCustomerGateway
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_21626051 = newJObject()
  var body_21626052 = newJObject()
  add(path_21626051, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_21626052 = body
  result = call_21626050.call(path_21626051, nil, nil, nil, body_21626052)

var associateCustomerGateway* = Call_AssociateCustomerGateway_21626037(
    name: "associateCustomerGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_AssociateCustomerGateway_21626038, base: "/",
    makeUrl: url_AssociateCustomerGateway_21626039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCustomerGatewayAssociations_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetCustomerGatewayAssociations_21625781(protocol: Scheme; host: string;
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

proc validate_GetCustomerGatewayAssociations_21625780(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21625895 = path.getOrDefault("globalNetworkId")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "globalNetworkId", valid_21625895
  result.add "path", section
  ## parameters in `query` object:
  ##   customerGatewayArns: JArray
  ##                      : One or more customer gateway Amazon Resource Names (ARNs). For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources Defined by Amazon EC2</a>. The maximum is 10.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21625896 = query.getOrDefault("customerGatewayArns")
  valid_21625896 = validateParameter(valid_21625896, JArray, required = false,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "customerGatewayArns", valid_21625896
  var valid_21625897 = query.getOrDefault("NextToken")
  valid_21625897 = validateParameter(valid_21625897, JString, required = false,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "NextToken", valid_21625897
  var valid_21625898 = query.getOrDefault("maxResults")
  valid_21625898 = validateParameter(valid_21625898, JInt, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "maxResults", valid_21625898
  var valid_21625899 = query.getOrDefault("nextToken")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "nextToken", valid_21625899
  var valid_21625900 = query.getOrDefault("MaxResults")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "MaxResults", valid_21625900
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625901 = header.getOrDefault("X-Amz-Date")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Date", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Security-Token", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-Algorithm", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-Signature")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-Signature", valid_21625905
  var valid_21625906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625906 = validateParameter(valid_21625906, JString, required = false,
                                   default = nil)
  if valid_21625906 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625906
  var valid_21625907 = header.getOrDefault("X-Amz-Credential")
  valid_21625907 = validateParameter(valid_21625907, JString, required = false,
                                   default = nil)
  if valid_21625907 != nil:
    section.add "X-Amz-Credential", valid_21625907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625932: Call_GetCustomerGatewayAssociations_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the association information for customer gateways that are associated with devices and links in your global network.
  ## 
  let valid = call_21625932.validator(path, query, header, formData, body, _)
  let scheme = call_21625932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625932.makeUrl(scheme.get, call_21625932.host, call_21625932.base,
                               call_21625932.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625932, uri, valid, _)

proc call*(call_21625995: Call_GetCustomerGatewayAssociations_21625779;
          globalNetworkId: string; customerGatewayArns: JsonNode = nil;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## getCustomerGatewayAssociations
  ## Gets the association information for customer gateways that are associated with devices and links in your global network.
  ##   customerGatewayArns: JArray
  ##                      : One or more customer gateway Amazon Resource Names (ARNs). For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources Defined by Amazon EC2</a>. The maximum is 10.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21625997 = newJObject()
  var query_21625999 = newJObject()
  if customerGatewayArns != nil:
    query_21625999.add "customerGatewayArns", customerGatewayArns
  add(query_21625999, "NextToken", newJString(NextToken))
  add(query_21625999, "maxResults", newJInt(maxResults))
  add(query_21625999, "nextToken", newJString(nextToken))
  add(path_21625997, "globalNetworkId", newJString(globalNetworkId))
  add(query_21625999, "MaxResults", newJString(MaxResults))
  result = call_21625995.call(path_21625997, query_21625999, nil, nil, nil)

var getCustomerGatewayAssociations* = Call_GetCustomerGatewayAssociations_21625779(
    name: "getCustomerGatewayAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_GetCustomerGatewayAssociations_21625780, base: "/",
    makeUrl: url_GetCustomerGatewayAssociations_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateLink_21626074 = ref object of OpenApiRestCall_21625435
proc url_AssociateLink_21626076(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateLink_21626075(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626077 = path.getOrDefault("globalNetworkId")
  valid_21626077 = validateParameter(valid_21626077, JString, required = true,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "globalNetworkId", valid_21626077
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626078 = header.getOrDefault("X-Amz-Date")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Date", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Security-Token", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
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

proc call*(call_21626086: Call_AssociateLink_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_AssociateLink_21626074; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## associateLink
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_21626088 = newJObject()
  var body_21626089 = newJObject()
  add(path_21626088, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_21626089 = body
  result = call_21626087.call(path_21626088, nil, nil, nil, body_21626089)

var associateLink* = Call_AssociateLink_21626074(name: "associateLink",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_AssociateLink_21626075, base: "/",
    makeUrl: url_AssociateLink_21626076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAssociations_21626053 = ref object of OpenApiRestCall_21625435
proc url_GetLinkAssociations_21626055(protocol: Scheme; host: string; base: string;
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

proc validate_GetLinkAssociations_21626054(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626056 = path.getOrDefault("globalNetworkId")
  valid_21626056 = validateParameter(valid_21626056, JString, required = true,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "globalNetworkId", valid_21626056
  result.add "path", section
  ## parameters in `query` object:
  ##   linkId: JString
  ##         : The ID of the link.
  ##   deviceId: JString
  ##           : The ID of the device.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626057 = query.getOrDefault("linkId")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "linkId", valid_21626057
  var valid_21626058 = query.getOrDefault("deviceId")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "deviceId", valid_21626058
  var valid_21626059 = query.getOrDefault("NextToken")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "NextToken", valid_21626059
  var valid_21626060 = query.getOrDefault("maxResults")
  valid_21626060 = validateParameter(valid_21626060, JInt, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "maxResults", valid_21626060
  var valid_21626061 = query.getOrDefault("nextToken")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "nextToken", valid_21626061
  var valid_21626062 = query.getOrDefault("MaxResults")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "MaxResults", valid_21626062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626063 = header.getOrDefault("X-Amz-Date")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Date", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Security-Token", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626070: Call_GetLinkAssociations_21626053; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the link associations for a device or a link. Either the device ID or the link ID must be specified.
  ## 
  let valid = call_21626070.validator(path, query, header, formData, body, _)
  let scheme = call_21626070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626070.makeUrl(scheme.get, call_21626070.host, call_21626070.base,
                               call_21626070.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626070, uri, valid, _)

proc call*(call_21626071: Call_GetLinkAssociations_21626053;
          globalNetworkId: string; linkId: string = ""; deviceId: string = "";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## getLinkAssociations
  ## Gets the link associations for a device or a link. Either the device ID or the link ID must be specified.
  ##   linkId: string
  ##         : The ID of the link.
  ##   deviceId: string
  ##           : The ID of the device.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626072 = newJObject()
  var query_21626073 = newJObject()
  add(query_21626073, "linkId", newJString(linkId))
  add(query_21626073, "deviceId", newJString(deviceId))
  add(query_21626073, "NextToken", newJString(NextToken))
  add(query_21626073, "maxResults", newJInt(maxResults))
  add(query_21626073, "nextToken", newJString(nextToken))
  add(path_21626072, "globalNetworkId", newJString(globalNetworkId))
  add(query_21626073, "MaxResults", newJString(MaxResults))
  result = call_21626071.call(path_21626072, query_21626073, nil, nil, nil)

var getLinkAssociations* = Call_GetLinkAssociations_21626053(
    name: "getLinkAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_GetLinkAssociations_21626054, base: "/",
    makeUrl: url_GetLinkAssociations_21626055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevice_21626111 = ref object of OpenApiRestCall_21625435
proc url_CreateDevice_21626113(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDevice_21626112(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626114 = path.getOrDefault("globalNetworkId")
  valid_21626114 = validateParameter(valid_21626114, JString, required = true,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "globalNetworkId", valid_21626114
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626115 = header.getOrDefault("X-Amz-Date")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Date", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Security-Token", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Algorithm", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Signature")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Signature", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Credential")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Credential", valid_21626121
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

proc call*(call_21626123: Call_CreateDevice_21626111; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ## 
  let valid = call_21626123.validator(path, query, header, formData, body, _)
  let scheme = call_21626123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626123.makeUrl(scheme.get, call_21626123.host, call_21626123.base,
                               call_21626123.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626123, uri, valid, _)

proc call*(call_21626124: Call_CreateDevice_21626111; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createDevice
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_21626125 = newJObject()
  var body_21626126 = newJObject()
  add(path_21626125, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_21626126 = body
  result = call_21626124.call(path_21626125, nil, nil, nil, body_21626126)

var createDevice* = Call_CreateDevice_21626111(name: "createDevice",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices",
    validator: validate_CreateDevice_21626112, base: "/", makeUrl: url_CreateDevice_21626113,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevices_21626090 = ref object of OpenApiRestCall_21625435
proc url_GetDevices_21626092(protocol: Scheme; host: string; base: string;
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

proc validate_GetDevices_21626091(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626093 = path.getOrDefault("globalNetworkId")
  valid_21626093 = validateParameter(valid_21626093, JString, required = true,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "globalNetworkId", valid_21626093
  result.add "path", section
  ## parameters in `query` object:
  ##   siteId: JString
  ##         : The ID of the site.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   deviceIds: JArray
  ##            : One or more device IDs. The maximum is 10.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626094 = query.getOrDefault("siteId")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "siteId", valid_21626094
  var valid_21626095 = query.getOrDefault("NextToken")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "NextToken", valid_21626095
  var valid_21626096 = query.getOrDefault("maxResults")
  valid_21626096 = validateParameter(valid_21626096, JInt, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "maxResults", valid_21626096
  var valid_21626097 = query.getOrDefault("nextToken")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "nextToken", valid_21626097
  var valid_21626098 = query.getOrDefault("deviceIds")
  valid_21626098 = validateParameter(valid_21626098, JArray, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "deviceIds", valid_21626098
  var valid_21626099 = query.getOrDefault("MaxResults")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "MaxResults", valid_21626099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626100 = header.getOrDefault("X-Amz-Date")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Date", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Security-Token", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Algorithm", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Signature")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Signature", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Credential")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Credential", valid_21626106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626107: Call_GetDevices_21626090; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about one or more of your devices in a global network.
  ## 
  let valid = call_21626107.validator(path, query, header, formData, body, _)
  let scheme = call_21626107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626107.makeUrl(scheme.get, call_21626107.host, call_21626107.base,
                               call_21626107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626107, uri, valid, _)

proc call*(call_21626108: Call_GetDevices_21626090; globalNetworkId: string;
          siteId: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; deviceIds: JsonNode = nil; MaxResults: string = ""): Recallable =
  ## getDevices
  ## Gets information about one or more of your devices in a global network.
  ##   siteId: string
  ##         : The ID of the site.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   deviceIds: JArray
  ##            : One or more device IDs. The maximum is 10.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626109 = newJObject()
  var query_21626110 = newJObject()
  add(query_21626110, "siteId", newJString(siteId))
  add(query_21626110, "NextToken", newJString(NextToken))
  add(query_21626110, "maxResults", newJInt(maxResults))
  add(query_21626110, "nextToken", newJString(nextToken))
  if deviceIds != nil:
    query_21626110.add "deviceIds", deviceIds
  add(path_21626109, "globalNetworkId", newJString(globalNetworkId))
  add(query_21626110, "MaxResults", newJString(MaxResults))
  result = call_21626108.call(path_21626109, query_21626110, nil, nil, nil)

var getDevices* = Call_GetDevices_21626090(name: "getDevices",
                                        meth: HttpMethod.HttpGet,
                                        host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/devices",
                                        validator: validate_GetDevices_21626091,
                                        base: "/", makeUrl: url_GetDevices_21626092,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGlobalNetwork_21626145 = ref object of OpenApiRestCall_21625435
proc url_CreateGlobalNetwork_21626147(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGlobalNetwork_21626146(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new, empty global network.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626148 = header.getOrDefault("X-Amz-Date")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Date", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Security-Token", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Algorithm", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Signature")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Signature", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Credential")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Credential", valid_21626154
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

proc call*(call_21626156: Call_CreateGlobalNetwork_21626145; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new, empty global network.
  ## 
  let valid = call_21626156.validator(path, query, header, formData, body, _)
  let scheme = call_21626156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626156.makeUrl(scheme.get, call_21626156.host, call_21626156.base,
                               call_21626156.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626156, uri, valid, _)

proc call*(call_21626157: Call_CreateGlobalNetwork_21626145; body: JsonNode): Recallable =
  ## createGlobalNetwork
  ## Creates a new, empty global network.
  ##   body: JObject (required)
  var body_21626158 = newJObject()
  if body != nil:
    body_21626158 = body
  result = call_21626157.call(nil, nil, nil, nil, body_21626158)

var createGlobalNetwork* = Call_CreateGlobalNetwork_21626145(
    name: "createGlobalNetwork", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_CreateGlobalNetwork_21626146, base: "/",
    makeUrl: url_CreateGlobalNetwork_21626147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalNetworks_21626127 = ref object of OpenApiRestCall_21625435
proc url_DescribeGlobalNetworks_21626129(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeGlobalNetworks_21626128(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   globalNetworkIds: JArray
  ##                   : The IDs of one or more global networks. The maximum is 10.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626130 = query.getOrDefault("NextToken")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "NextToken", valid_21626130
  var valid_21626131 = query.getOrDefault("maxResults")
  valid_21626131 = validateParameter(valid_21626131, JInt, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "maxResults", valid_21626131
  var valid_21626132 = query.getOrDefault("nextToken")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "nextToken", valid_21626132
  var valid_21626133 = query.getOrDefault("globalNetworkIds")
  valid_21626133 = validateParameter(valid_21626133, JArray, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "globalNetworkIds", valid_21626133
  var valid_21626134 = query.getOrDefault("MaxResults")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "MaxResults", valid_21626134
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626135 = header.getOrDefault("X-Amz-Date")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Date", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Security-Token", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Algorithm", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Signature")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Signature", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Credential")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Credential", valid_21626141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626142: Call_DescribeGlobalNetworks_21626127;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
  ## 
  let valid = call_21626142.validator(path, query, header, formData, body, _)
  let scheme = call_21626142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626142.makeUrl(scheme.get, call_21626142.host, call_21626142.base,
                               call_21626142.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626142, uri, valid, _)

proc call*(call_21626143: Call_DescribeGlobalNetworks_21626127;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          globalNetworkIds: JsonNode = nil; MaxResults: string = ""): Recallable =
  ## describeGlobalNetworks
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   globalNetworkIds: JArray
  ##                   : The IDs of one or more global networks. The maximum is 10.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626144 = newJObject()
  add(query_21626144, "NextToken", newJString(NextToken))
  add(query_21626144, "maxResults", newJInt(maxResults))
  add(query_21626144, "nextToken", newJString(nextToken))
  if globalNetworkIds != nil:
    query_21626144.add "globalNetworkIds", globalNetworkIds
  add(query_21626144, "MaxResults", newJString(MaxResults))
  result = call_21626143.call(nil, query_21626144, nil, nil, nil)

var describeGlobalNetworks* = Call_DescribeGlobalNetworks_21626127(
    name: "describeGlobalNetworks", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_DescribeGlobalNetworks_21626128, base: "/",
    makeUrl: url_DescribeGlobalNetworks_21626129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLink_21626182 = ref object of OpenApiRestCall_21625435
proc url_CreateLink_21626184(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateLink_21626183(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626185 = path.getOrDefault("globalNetworkId")
  valid_21626185 = validateParameter(valid_21626185, JString, required = true,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "globalNetworkId", valid_21626185
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626186 = header.getOrDefault("X-Amz-Date")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Date", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Security-Token", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Algorithm", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Signature")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Signature", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Credential")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Credential", valid_21626192
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

proc call*(call_21626194: Call_CreateLink_21626182; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new link for a specified site.
  ## 
  let valid = call_21626194.validator(path, query, header, formData, body, _)
  let scheme = call_21626194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626194.makeUrl(scheme.get, call_21626194.host, call_21626194.base,
                               call_21626194.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626194, uri, valid, _)

proc call*(call_21626195: Call_CreateLink_21626182; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createLink
  ## Creates a new link for a specified site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_21626196 = newJObject()
  var body_21626197 = newJObject()
  add(path_21626196, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_21626197 = body
  result = call_21626195.call(path_21626196, nil, nil, nil, body_21626197)

var createLink* = Call_CreateLink_21626182(name: "createLink",
                                        meth: HttpMethod.HttpPost,
                                        host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                        validator: validate_CreateLink_21626183,
                                        base: "/", makeUrl: url_CreateLink_21626184,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinks_21626159 = ref object of OpenApiRestCall_21625435
proc url_GetLinks_21626161(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetLinks_21626160(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626162 = path.getOrDefault("globalNetworkId")
  valid_21626162 = validateParameter(valid_21626162, JString, required = true,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "globalNetworkId", valid_21626162
  result.add "path", section
  ## parameters in `query` object:
  ##   type: JString
  ##       : The link type.
  ##   linkIds: JArray
  ##          : One or more link IDs. The maximum is 10.
  ##   siteId: JString
  ##         : The ID of the site.
  ##   NextToken: JString
  ##            : Pagination token
  ##   provider: JString
  ##           : The link provider.
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626163 = query.getOrDefault("type")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "type", valid_21626163
  var valid_21626164 = query.getOrDefault("linkIds")
  valid_21626164 = validateParameter(valid_21626164, JArray, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "linkIds", valid_21626164
  var valid_21626165 = query.getOrDefault("siteId")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "siteId", valid_21626165
  var valid_21626166 = query.getOrDefault("NextToken")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "NextToken", valid_21626166
  var valid_21626167 = query.getOrDefault("provider")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "provider", valid_21626167
  var valid_21626168 = query.getOrDefault("maxResults")
  valid_21626168 = validateParameter(valid_21626168, JInt, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "maxResults", valid_21626168
  var valid_21626169 = query.getOrDefault("nextToken")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "nextToken", valid_21626169
  var valid_21626170 = query.getOrDefault("MaxResults")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "MaxResults", valid_21626170
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626171 = header.getOrDefault("X-Amz-Date")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Date", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Security-Token", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Algorithm", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-Signature")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Signature", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Credential")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Credential", valid_21626177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626178: Call_GetLinks_21626159; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets information about one or more links in a specified global network.</p> <p>If you specify the site ID, you cannot specify the type or provider in the same request. You can specify the type and provider in the same request.</p>
  ## 
  let valid = call_21626178.validator(path, query, header, formData, body, _)
  let scheme = call_21626178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626178.makeUrl(scheme.get, call_21626178.host, call_21626178.base,
                               call_21626178.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626178, uri, valid, _)

proc call*(call_21626179: Call_GetLinks_21626159; globalNetworkId: string;
          `type`: string = ""; linkIds: JsonNode = nil; siteId: string = "";
          NextToken: string = ""; provider: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getLinks
  ## <p>Gets information about one or more links in a specified global network.</p> <p>If you specify the site ID, you cannot specify the type or provider in the same request. You can specify the type and provider in the same request.</p>
  ##   type: string
  ##       : The link type.
  ##   linkIds: JArray
  ##          : One or more link IDs. The maximum is 10.
  ##   siteId: string
  ##         : The ID of the site.
  ##   NextToken: string
  ##            : Pagination token
  ##   provider: string
  ##           : The link provider.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626180 = newJObject()
  var query_21626181 = newJObject()
  add(query_21626181, "type", newJString(`type`))
  if linkIds != nil:
    query_21626181.add "linkIds", linkIds
  add(query_21626181, "siteId", newJString(siteId))
  add(query_21626181, "NextToken", newJString(NextToken))
  add(query_21626181, "provider", newJString(provider))
  add(query_21626181, "maxResults", newJInt(maxResults))
  add(query_21626181, "nextToken", newJString(nextToken))
  add(path_21626180, "globalNetworkId", newJString(globalNetworkId))
  add(query_21626181, "MaxResults", newJString(MaxResults))
  result = call_21626179.call(path_21626180, query_21626181, nil, nil, nil)

var getLinks* = Call_GetLinks_21626159(name: "getLinks", meth: HttpMethod.HttpGet,
                                    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                    validator: validate_GetLinks_21626160,
                                    base: "/", makeUrl: url_GetLinks_21626161,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSite_21626218 = ref object of OpenApiRestCall_21625435
proc url_CreateSite_21626220(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateSite_21626219(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626221 = path.getOrDefault("globalNetworkId")
  valid_21626221 = validateParameter(valid_21626221, JString, required = true,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "globalNetworkId", valid_21626221
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626222 = header.getOrDefault("X-Amz-Date")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-Date", valid_21626222
  var valid_21626223 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-Security-Token", valid_21626223
  var valid_21626224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626224 = validateParameter(valid_21626224, JString, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626224
  var valid_21626225 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Algorithm", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Signature")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Signature", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Credential")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Credential", valid_21626228
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

proc call*(call_21626230: Call_CreateSite_21626218; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new site in a global network.
  ## 
  let valid = call_21626230.validator(path, query, header, formData, body, _)
  let scheme = call_21626230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626230.makeUrl(scheme.get, call_21626230.host, call_21626230.base,
                               call_21626230.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626230, uri, valid, _)

proc call*(call_21626231: Call_CreateSite_21626218; globalNetworkId: string;
          body: JsonNode): Recallable =
  ## createSite
  ## Creates a new site in a global network.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_21626232 = newJObject()
  var body_21626233 = newJObject()
  add(path_21626232, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_21626233 = body
  result = call_21626231.call(path_21626232, nil, nil, nil, body_21626233)

var createSite* = Call_CreateSite_21626218(name: "createSite",
                                        meth: HttpMethod.HttpPost,
                                        host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                        validator: validate_CreateSite_21626219,
                                        base: "/", makeUrl: url_CreateSite_21626220,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSites_21626198 = ref object of OpenApiRestCall_21625435
proc url_GetSites_21626200(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetSites_21626199(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626201 = path.getOrDefault("globalNetworkId")
  valid_21626201 = validateParameter(valid_21626201, JString, required = true,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "globalNetworkId", valid_21626201
  result.add "path", section
  ## parameters in `query` object:
  ##   siteIds: JArray
  ##          : One or more site IDs. The maximum is 10.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626202 = query.getOrDefault("siteIds")
  valid_21626202 = validateParameter(valid_21626202, JArray, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "siteIds", valid_21626202
  var valid_21626203 = query.getOrDefault("NextToken")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "NextToken", valid_21626203
  var valid_21626204 = query.getOrDefault("maxResults")
  valid_21626204 = validateParameter(valid_21626204, JInt, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "maxResults", valid_21626204
  var valid_21626205 = query.getOrDefault("nextToken")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "nextToken", valid_21626205
  var valid_21626206 = query.getOrDefault("MaxResults")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "MaxResults", valid_21626206
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626207 = header.getOrDefault("X-Amz-Date")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-Date", valid_21626207
  var valid_21626208 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Security-Token", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Algorithm", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Signature")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Signature", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Credential")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Credential", valid_21626213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626214: Call_GetSites_21626198; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about one or more of your sites in a global network.
  ## 
  let valid = call_21626214.validator(path, query, header, formData, body, _)
  let scheme = call_21626214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626214.makeUrl(scheme.get, call_21626214.host, call_21626214.base,
                               call_21626214.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626214, uri, valid, _)

proc call*(call_21626215: Call_GetSites_21626198; globalNetworkId: string;
          siteIds: JsonNode = nil; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getSites
  ## Gets information about one or more of your sites in a global network.
  ##   siteIds: JArray
  ##          : One or more site IDs. The maximum is 10.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626216 = newJObject()
  var query_21626217 = newJObject()
  if siteIds != nil:
    query_21626217.add "siteIds", siteIds
  add(query_21626217, "NextToken", newJString(NextToken))
  add(query_21626217, "maxResults", newJInt(maxResults))
  add(query_21626217, "nextToken", newJString(nextToken))
  add(path_21626216, "globalNetworkId", newJString(globalNetworkId))
  add(query_21626217, "MaxResults", newJString(MaxResults))
  result = call_21626215.call(path_21626216, query_21626217, nil, nil, nil)

var getSites* = Call_GetSites_21626198(name: "getSites", meth: HttpMethod.HttpGet,
                                    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                    validator: validate_GetSites_21626199,
                                    base: "/", makeUrl: url_GetSites_21626200,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_21626249 = ref object of OpenApiRestCall_21625435
proc url_UpdateDevice_21626251(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDevice_21626250(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
  ##           : The ID of the device.
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `deviceId` field"
  var valid_21626252 = path.getOrDefault("deviceId")
  valid_21626252 = validateParameter(valid_21626252, JString, required = true,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "deviceId", valid_21626252
  var valid_21626253 = path.getOrDefault("globalNetworkId")
  valid_21626253 = validateParameter(valid_21626253, JString, required = true,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "globalNetworkId", valid_21626253
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626254 = header.getOrDefault("X-Amz-Date")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Date", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Security-Token", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Algorithm", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Signature")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Signature", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Credential")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Credential", valid_21626260
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

proc call*(call_21626262: Call_UpdateDevice_21626249; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_21626262.validator(path, query, header, formData, body, _)
  let scheme = call_21626262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626262.makeUrl(scheme.get, call_21626262.host, call_21626262.base,
                               call_21626262.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626262, uri, valid, _)

proc call*(call_21626263: Call_UpdateDevice_21626249; deviceId: string;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateDevice
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_21626264 = newJObject()
  var body_21626265 = newJObject()
  add(path_21626264, "deviceId", newJString(deviceId))
  add(path_21626264, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_21626265 = body
  result = call_21626263.call(path_21626264, nil, nil, nil, body_21626265)

var updateDevice* = Call_UpdateDevice_21626249(name: "updateDevice",
    meth: HttpMethod.HttpPatch, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_UpdateDevice_21626250, base: "/", makeUrl: url_UpdateDevice_21626251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_21626234 = ref object of OpenApiRestCall_21625435
proc url_DeleteDevice_21626236(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDevice_21626235(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
  ##           : The ID of the device.
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `deviceId` field"
  var valid_21626237 = path.getOrDefault("deviceId")
  valid_21626237 = validateParameter(valid_21626237, JString, required = true,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "deviceId", valid_21626237
  var valid_21626238 = path.getOrDefault("globalNetworkId")
  valid_21626238 = validateParameter(valid_21626238, JString, required = true,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "globalNetworkId", valid_21626238
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626239 = header.getOrDefault("X-Amz-Date")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-Date", valid_21626239
  var valid_21626240 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Security-Token", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Algorithm", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Signature")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Signature", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Credential")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Credential", valid_21626245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626246: Call_DeleteDevice_21626234; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ## 
  let valid = call_21626246.validator(path, query, header, formData, body, _)
  let scheme = call_21626246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626246.makeUrl(scheme.get, call_21626246.host, call_21626246.base,
                               call_21626246.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626246, uri, valid, _)

proc call*(call_21626247: Call_DeleteDevice_21626234; deviceId: string;
          globalNetworkId: string): Recallable =
  ## deleteDevice
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_21626248 = newJObject()
  add(path_21626248, "deviceId", newJString(deviceId))
  add(path_21626248, "globalNetworkId", newJString(globalNetworkId))
  result = call_21626247.call(path_21626248, nil, nil, nil, nil)

var deleteDevice* = Call_DeleteDevice_21626234(name: "deleteDevice",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_DeleteDevice_21626235, base: "/", makeUrl: url_DeleteDevice_21626236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalNetwork_21626280 = ref object of OpenApiRestCall_21625435
proc url_UpdateGlobalNetwork_21626282(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGlobalNetwork_21626281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626283 = path.getOrDefault("globalNetworkId")
  valid_21626283 = validateParameter(valid_21626283, JString, required = true,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "globalNetworkId", valid_21626283
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626284 = header.getOrDefault("X-Amz-Date")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Date", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Security-Token", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Algorithm", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Signature")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Signature", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Credential")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Credential", valid_21626290
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

proc call*(call_21626292: Call_UpdateGlobalNetwork_21626280; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_21626292.validator(path, query, header, formData, body, _)
  let scheme = call_21626292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626292.makeUrl(scheme.get, call_21626292.host, call_21626292.base,
                               call_21626292.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626292, uri, valid, _)

proc call*(call_21626293: Call_UpdateGlobalNetwork_21626280;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateGlobalNetwork
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ##   globalNetworkId: string (required)
  ##                  : The ID of your global network.
  ##   body: JObject (required)
  var path_21626294 = newJObject()
  var body_21626295 = newJObject()
  add(path_21626294, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_21626295 = body
  result = call_21626293.call(path_21626294, nil, nil, nil, body_21626295)

var updateGlobalNetwork* = Call_UpdateGlobalNetwork_21626280(
    name: "updateGlobalNetwork", meth: HttpMethod.HttpPatch,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_UpdateGlobalNetwork_21626281, base: "/",
    makeUrl: url_UpdateGlobalNetwork_21626282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGlobalNetwork_21626266 = ref object of OpenApiRestCall_21625435
proc url_DeleteGlobalNetwork_21626268(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGlobalNetwork_21626267(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626269 = path.getOrDefault("globalNetworkId")
  valid_21626269 = validateParameter(valid_21626269, JString, required = true,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "globalNetworkId", valid_21626269
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626270 = header.getOrDefault("X-Amz-Date")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Date", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Security-Token", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Algorithm", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Signature")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Signature", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Credential")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Credential", valid_21626276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626277: Call_DeleteGlobalNetwork_21626266; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ## 
  let valid = call_21626277.validator(path, query, header, formData, body, _)
  let scheme = call_21626277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626277.makeUrl(scheme.get, call_21626277.host, call_21626277.base,
                               call_21626277.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626277, uri, valid, _)

proc call*(call_21626278: Call_DeleteGlobalNetwork_21626266;
          globalNetworkId: string): Recallable =
  ## deleteGlobalNetwork
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_21626279 = newJObject()
  add(path_21626279, "globalNetworkId", newJString(globalNetworkId))
  result = call_21626278.call(path_21626279, nil, nil, nil, nil)

var deleteGlobalNetwork* = Call_DeleteGlobalNetwork_21626266(
    name: "deleteGlobalNetwork", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_DeleteGlobalNetwork_21626267, base: "/",
    makeUrl: url_DeleteGlobalNetwork_21626268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLink_21626311 = ref object of OpenApiRestCall_21625435
proc url_UpdateLink_21626313(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateLink_21626312(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  ##   linkId: JString (required)
  ##         : The ID of the link.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_21626314 = path.getOrDefault("globalNetworkId")
  valid_21626314 = validateParameter(valid_21626314, JString, required = true,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "globalNetworkId", valid_21626314
  var valid_21626315 = path.getOrDefault("linkId")
  valid_21626315 = validateParameter(valid_21626315, JString, required = true,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "linkId", valid_21626315
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626316 = header.getOrDefault("X-Amz-Date")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Date", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Security-Token", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Algorithm", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Signature")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Signature", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Credential")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Credential", valid_21626322
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

proc call*(call_21626324: Call_UpdateLink_21626311; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_21626324.validator(path, query, header, formData, body, _)
  let scheme = call_21626324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626324.makeUrl(scheme.get, call_21626324.host, call_21626324.base,
                               call_21626324.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626324, uri, valid, _)

proc call*(call_21626325: Call_UpdateLink_21626311; globalNetworkId: string;
          linkId: string; body: JsonNode): Recallable =
  ## updateLink
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   linkId: string (required)
  ##         : The ID of the link.
  ##   body: JObject (required)
  var path_21626326 = newJObject()
  var body_21626327 = newJObject()
  add(path_21626326, "globalNetworkId", newJString(globalNetworkId))
  add(path_21626326, "linkId", newJString(linkId))
  if body != nil:
    body_21626327 = body
  result = call_21626325.call(path_21626326, nil, nil, nil, body_21626327)

var updateLink* = Call_UpdateLink_21626311(name: "updateLink",
                                        meth: HttpMethod.HttpPatch,
                                        host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links/{linkId}",
                                        validator: validate_UpdateLink_21626312,
                                        base: "/", makeUrl: url_UpdateLink_21626313,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLink_21626296 = ref object of OpenApiRestCall_21625435
proc url_DeleteLink_21626298(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteLink_21626297(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  ##   linkId: JString (required)
  ##         : The ID of the link.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `globalNetworkId` field"
  var valid_21626299 = path.getOrDefault("globalNetworkId")
  valid_21626299 = validateParameter(valid_21626299, JString, required = true,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "globalNetworkId", valid_21626299
  var valid_21626300 = path.getOrDefault("linkId")
  valid_21626300 = validateParameter(valid_21626300, JString, required = true,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "linkId", valid_21626300
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626301 = header.getOrDefault("X-Amz-Date")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Date", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Security-Token", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Algorithm", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Signature")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Signature", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Credential")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Credential", valid_21626307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626308: Call_DeleteLink_21626296; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ## 
  let valid = call_21626308.validator(path, query, header, formData, body, _)
  let scheme = call_21626308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626308.makeUrl(scheme.get, call_21626308.host, call_21626308.base,
                               call_21626308.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626308, uri, valid, _)

proc call*(call_21626309: Call_DeleteLink_21626296; globalNetworkId: string;
          linkId: string): Recallable =
  ## deleteLink
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   linkId: string (required)
  ##         : The ID of the link.
  var path_21626310 = newJObject()
  add(path_21626310, "globalNetworkId", newJString(globalNetworkId))
  add(path_21626310, "linkId", newJString(linkId))
  result = call_21626309.call(path_21626310, nil, nil, nil, nil)

var deleteLink* = Call_DeleteLink_21626296(name: "deleteLink",
                                        meth: HttpMethod.HttpDelete,
                                        host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links/{linkId}",
                                        validator: validate_DeleteLink_21626297,
                                        base: "/", makeUrl: url_DeleteLink_21626298,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSite_21626343 = ref object of OpenApiRestCall_21625435
proc url_UpdateSite_21626345(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateSite_21626344(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626346 = path.getOrDefault("siteId")
  valid_21626346 = validateParameter(valid_21626346, JString, required = true,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "siteId", valid_21626346
  var valid_21626347 = path.getOrDefault("globalNetworkId")
  valid_21626347 = validateParameter(valid_21626347, JString, required = true,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "globalNetworkId", valid_21626347
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626348 = header.getOrDefault("X-Amz-Date")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Date", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Security-Token", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
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

proc call*(call_21626356: Call_UpdateSite_21626343; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_UpdateSite_21626343; siteId: string;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## updateSite
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ##   siteId: string (required)
  ##         : The ID of your site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_21626358 = newJObject()
  var body_21626359 = newJObject()
  add(path_21626358, "siteId", newJString(siteId))
  add(path_21626358, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_21626359 = body
  result = call_21626357.call(path_21626358, nil, nil, nil, body_21626359)

var updateSite* = Call_UpdateSite_21626343(name: "updateSite",
                                        meth: HttpMethod.HttpPatch,
                                        host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites/{siteId}",
                                        validator: validate_UpdateSite_21626344,
                                        base: "/", makeUrl: url_UpdateSite_21626345,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSite_21626328 = ref object of OpenApiRestCall_21625435
proc url_DeleteSite_21626330(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteSite_21626329(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626331 = path.getOrDefault("siteId")
  valid_21626331 = validateParameter(valid_21626331, JString, required = true,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "siteId", valid_21626331
  var valid_21626332 = path.getOrDefault("globalNetworkId")
  valid_21626332 = validateParameter(valid_21626332, JString, required = true,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "globalNetworkId", valid_21626332
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626333 = header.getOrDefault("X-Amz-Date")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Date", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Security-Token", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Algorithm", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Signature")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Signature", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Credential")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Credential", valid_21626339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626340: Call_DeleteSite_21626328; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ## 
  let valid = call_21626340.validator(path, query, header, formData, body, _)
  let scheme = call_21626340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626340.makeUrl(scheme.get, call_21626340.host, call_21626340.base,
                               call_21626340.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626340, uri, valid, _)

proc call*(call_21626341: Call_DeleteSite_21626328; siteId: string;
          globalNetworkId: string): Recallable =
  ## deleteSite
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ##   siteId: string (required)
  ##         : The ID of the site.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_21626342 = newJObject()
  add(path_21626342, "siteId", newJString(siteId))
  add(path_21626342, "globalNetworkId", newJString(globalNetworkId))
  result = call_21626341.call(path_21626342, nil, nil, nil, nil)

var deleteSite* = Call_DeleteSite_21626328(name: "deleteSite",
                                        meth: HttpMethod.HttpDelete,
                                        host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites/{siteId}",
                                        validator: validate_DeleteSite_21626329,
                                        base: "/", makeUrl: url_DeleteSite_21626330,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTransitGateway_21626360 = ref object of OpenApiRestCall_21625435
proc url_DeregisterTransitGateway_21626362(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeregisterTransitGateway_21626361(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   transitGatewayArn: JString (required)
  ##                    : The Amazon Resource Name (ARN) of the transit gateway.
  ##   globalNetworkId: JString (required)
  ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `transitGatewayArn` field"
  var valid_21626363 = path.getOrDefault("transitGatewayArn")
  valid_21626363 = validateParameter(valid_21626363, JString, required = true,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "transitGatewayArn", valid_21626363
  var valid_21626364 = path.getOrDefault("globalNetworkId")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "globalNetworkId", valid_21626364
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626365 = header.getOrDefault("X-Amz-Date")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Date", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Security-Token", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Algorithm", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Signature")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Signature", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Credential")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Credential", valid_21626371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626372: Call_DeregisterTransitGateway_21626360;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ## 
  let valid = call_21626372.validator(path, query, header, formData, body, _)
  let scheme = call_21626372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626372.makeUrl(scheme.get, call_21626372.host, call_21626372.base,
                               call_21626372.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626372, uri, valid, _)

proc call*(call_21626373: Call_DeregisterTransitGateway_21626360;
          transitGatewayArn: string; globalNetworkId: string): Recallable =
  ## deregisterTransitGateway
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ##   transitGatewayArn: string (required)
  ##                    : The Amazon Resource Name (ARN) of the transit gateway.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_21626374 = newJObject()
  add(path_21626374, "transitGatewayArn", newJString(transitGatewayArn))
  add(path_21626374, "globalNetworkId", newJString(globalNetworkId))
  result = call_21626373.call(path_21626374, nil, nil, nil, nil)

var deregisterTransitGateway* = Call_DeregisterTransitGateway_21626360(
    name: "deregisterTransitGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/transit-gateway-registrations/{transitGatewayArn}",
    validator: validate_DeregisterTransitGateway_21626361, base: "/",
    makeUrl: url_DeregisterTransitGateway_21626362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCustomerGateway_21626375 = ref object of OpenApiRestCall_21625435
proc url_DisassociateCustomerGateway_21626377(protocol: Scheme; host: string;
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

proc validate_DisassociateCustomerGateway_21626376(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626378 = path.getOrDefault("globalNetworkId")
  valid_21626378 = validateParameter(valid_21626378, JString, required = true,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "globalNetworkId", valid_21626378
  var valid_21626379 = path.getOrDefault("customerGatewayArn")
  valid_21626379 = validateParameter(valid_21626379, JString, required = true,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "customerGatewayArn", valid_21626379
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626380 = header.getOrDefault("X-Amz-Date")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Date", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Security-Token", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Algorithm", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Signature")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Signature", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Credential")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Credential", valid_21626386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626387: Call_DisassociateCustomerGateway_21626375;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates a customer gateway from a device and a link.
  ## 
  let valid = call_21626387.validator(path, query, header, formData, body, _)
  let scheme = call_21626387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626387.makeUrl(scheme.get, call_21626387.host, call_21626387.base,
                               call_21626387.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626387, uri, valid, _)

proc call*(call_21626388: Call_DisassociateCustomerGateway_21626375;
          globalNetworkId: string; customerGatewayArn: string): Recallable =
  ## disassociateCustomerGateway
  ## Disassociates a customer gateway from a device and a link.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   customerGatewayArn: string (required)
  ##                     : The Amazon Resource Name (ARN) of the customer gateway. For more information, see <a 
  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources Defined by Amazon EC2</a>.
  var path_21626389 = newJObject()
  add(path_21626389, "globalNetworkId", newJString(globalNetworkId))
  add(path_21626389, "customerGatewayArn", newJString(customerGatewayArn))
  result = call_21626388.call(path_21626389, nil, nil, nil, nil)

var disassociateCustomerGateway* = Call_DisassociateCustomerGateway_21626375(
    name: "disassociateCustomerGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/customer-gateway-associations/{customerGatewayArn}",
    validator: validate_DisassociateCustomerGateway_21626376, base: "/",
    makeUrl: url_DisassociateCustomerGateway_21626377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateLink_21626390 = ref object of OpenApiRestCall_21625435
proc url_DisassociateLink_21626392(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateLink_21626391(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626393 = path.getOrDefault("globalNetworkId")
  valid_21626393 = validateParameter(valid_21626393, JString, required = true,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "globalNetworkId", valid_21626393
  result.add "path", section
  ## parameters in `query` object:
  ##   linkId: JString (required)
  ##         : The ID of the link.
  ##   deviceId: JString (required)
  ##           : The ID of the device.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `linkId` field"
  var valid_21626394 = query.getOrDefault("linkId")
  valid_21626394 = validateParameter(valid_21626394, JString, required = true,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "linkId", valid_21626394
  var valid_21626395 = query.getOrDefault("deviceId")
  valid_21626395 = validateParameter(valid_21626395, JString, required = true,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "deviceId", valid_21626395
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626396 = header.getOrDefault("X-Amz-Date")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Date", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Security-Token", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Algorithm", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Signature")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Signature", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Credential")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Credential", valid_21626402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626403: Call_DisassociateLink_21626390; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ## 
  let valid = call_21626403.validator(path, query, header, formData, body, _)
  let scheme = call_21626403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626403.makeUrl(scheme.get, call_21626403.host, call_21626403.base,
                               call_21626403.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626403, uri, valid, _)

proc call*(call_21626404: Call_DisassociateLink_21626390; linkId: string;
          deviceId: string; globalNetworkId: string): Recallable =
  ## disassociateLink
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ##   linkId: string (required)
  ##         : The ID of the link.
  ##   deviceId: string (required)
  ##           : The ID of the device.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  var path_21626405 = newJObject()
  var query_21626406 = newJObject()
  add(query_21626406, "linkId", newJString(linkId))
  add(query_21626406, "deviceId", newJString(deviceId))
  add(path_21626405, "globalNetworkId", newJString(globalNetworkId))
  result = call_21626404.call(path_21626405, query_21626406, nil, nil, nil)

var disassociateLink* = Call_DisassociateLink_21626390(name: "disassociateLink",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/link-associations#deviceId&linkId",
    validator: validate_DisassociateLink_21626391, base: "/",
    makeUrl: url_DisassociateLink_21626392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTransitGateway_21626427 = ref object of OpenApiRestCall_21625435
proc url_RegisterTransitGateway_21626429(protocol: Scheme; host: string;
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
               (kind: ConstantSegment, value: "/transit-gateway-registrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegisterTransitGateway_21626428(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626430 = path.getOrDefault("globalNetworkId")
  valid_21626430 = validateParameter(valid_21626430, JString, required = true,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "globalNetworkId", valid_21626430
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626431 = header.getOrDefault("X-Amz-Date")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Date", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Security-Token", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Algorithm", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Signature")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Signature", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Credential")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Credential", valid_21626437
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

proc call*(call_21626439: Call_RegisterTransitGateway_21626427;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ## 
  let valid = call_21626439.validator(path, query, header, formData, body, _)
  let scheme = call_21626439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626439.makeUrl(scheme.get, call_21626439.host, call_21626439.base,
                               call_21626439.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626439, uri, valid, _)

proc call*(call_21626440: Call_RegisterTransitGateway_21626427;
          globalNetworkId: string; body: JsonNode): Recallable =
  ## registerTransitGateway
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   body: JObject (required)
  var path_21626441 = newJObject()
  var body_21626442 = newJObject()
  add(path_21626441, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_21626442 = body
  result = call_21626440.call(path_21626441, nil, nil, nil, body_21626442)

var registerTransitGateway* = Call_RegisterTransitGateway_21626427(
    name: "registerTransitGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_RegisterTransitGateway_21626428, base: "/",
    makeUrl: url_RegisterTransitGateway_21626429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTransitGatewayRegistrations_21626407 = ref object of OpenApiRestCall_21625435
proc url_GetTransitGatewayRegistrations_21626409(protocol: Scheme; host: string;
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

proc validate_GetTransitGatewayRegistrations_21626408(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626410 = path.getOrDefault("globalNetworkId")
  valid_21626410 = validateParameter(valid_21626410, JString, required = true,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "globalNetworkId", valid_21626410
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return.
  ##   nextToken: JString
  ##            : The token for the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   transitGatewayArns: JArray
  ##                     : The Amazon Resource Names (ARNs) of one or more transit gateways. The maximum is 10.
  section = newJObject()
  var valid_21626411 = query.getOrDefault("NextToken")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "NextToken", valid_21626411
  var valid_21626412 = query.getOrDefault("maxResults")
  valid_21626412 = validateParameter(valid_21626412, JInt, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "maxResults", valid_21626412
  var valid_21626413 = query.getOrDefault("nextToken")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "nextToken", valid_21626413
  var valid_21626414 = query.getOrDefault("MaxResults")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "MaxResults", valid_21626414
  var valid_21626415 = query.getOrDefault("transitGatewayArns")
  valid_21626415 = validateParameter(valid_21626415, JArray, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "transitGatewayArns", valid_21626415
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626416 = header.getOrDefault("X-Amz-Date")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Date", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Security-Token", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Algorithm", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Signature")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Signature", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Credential")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Credential", valid_21626422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626423: Call_GetTransitGatewayRegistrations_21626407;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the transit gateway registrations in a specified global network.
  ## 
  let valid = call_21626423.validator(path, query, header, formData, body, _)
  let scheme = call_21626423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626423.makeUrl(scheme.get, call_21626423.host, call_21626423.base,
                               call_21626423.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626423, uri, valid, _)

proc call*(call_21626424: Call_GetTransitGatewayRegistrations_21626407;
          globalNetworkId: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = "";
          transitGatewayArns: JsonNode = nil): Recallable =
  ## getTransitGatewayRegistrations
  ## Gets information about the transit gateway registrations in a specified global network.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return.
  ##   nextToken: string
  ##            : The token for the next page of results.
  ##   globalNetworkId: string (required)
  ##                  : The ID of the global network.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   transitGatewayArns: JArray
  ##                     : The Amazon Resource Names (ARNs) of one or more transit gateways. The maximum is 10.
  var path_21626425 = newJObject()
  var query_21626426 = newJObject()
  add(query_21626426, "NextToken", newJString(NextToken))
  add(query_21626426, "maxResults", newJInt(maxResults))
  add(query_21626426, "nextToken", newJString(nextToken))
  add(path_21626425, "globalNetworkId", newJString(globalNetworkId))
  add(query_21626426, "MaxResults", newJString(MaxResults))
  if transitGatewayArns != nil:
    query_21626426.add "transitGatewayArns", transitGatewayArns
  result = call_21626424.call(path_21626425, query_21626426, nil, nil, nil)

var getTransitGatewayRegistrations* = Call_GetTransitGatewayRegistrations_21626407(
    name: "getTransitGatewayRegistrations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_GetTransitGatewayRegistrations_21626408, base: "/",
    makeUrl: url_GetTransitGatewayRegistrations_21626409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626457 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626459(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21626458(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626460 = path.getOrDefault("resourceArn")
  valid_21626460 = validateParameter(valid_21626460, JString, required = true,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "resourceArn", valid_21626460
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626461 = header.getOrDefault("X-Amz-Date")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Date", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-Security-Token", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Algorithm", valid_21626464
  var valid_21626465 = header.getOrDefault("X-Amz-Signature")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-Signature", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Credential")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Credential", valid_21626467
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

proc call*(call_21626469: Call_TagResource_21626457; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Tags a specified resource.
  ## 
  let valid = call_21626469.validator(path, query, header, formData, body, _)
  let scheme = call_21626469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626469.makeUrl(scheme.get, call_21626469.host, call_21626469.base,
                               call_21626469.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626469, uri, valid, _)

proc call*(call_21626470: Call_TagResource_21626457; body: JsonNode;
          resourceArn: string): Recallable =
  ## tagResource
  ## Tags a specified resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_21626471 = newJObject()
  var body_21626472 = newJObject()
  if body != nil:
    body_21626472 = body
  add(path_21626471, "resourceArn", newJString(resourceArn))
  result = call_21626470.call(path_21626471, nil, nil, nil, body_21626472)

var tagResource* = Call_TagResource_21626457(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_21626458,
    base: "/", makeUrl: url_TagResource_21626459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626443 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626445(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_21626444(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626446 = path.getOrDefault("resourceArn")
  valid_21626446 = validateParameter(valid_21626446, JString, required = true,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "resourceArn", valid_21626446
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626447 = header.getOrDefault("X-Amz-Date")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Date", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Security-Token", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Algorithm", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Signature")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Signature", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Credential")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Credential", valid_21626453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626454: Call_ListTagsForResource_21626443; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags for a specified resource.
  ## 
  let valid = call_21626454.validator(path, query, header, formData, body, _)
  let scheme = call_21626454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626454.makeUrl(scheme.get, call_21626454.host, call_21626454.base,
                               call_21626454.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626454, uri, valid, _)

proc call*(call_21626455: Call_ListTagsForResource_21626443; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_21626456 = newJObject()
  add(path_21626456, "resourceArn", newJString(resourceArn))
  result = call_21626455.call(path_21626456, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626443(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_21626444, base: "/",
    makeUrl: url_ListTagsForResource_21626445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626473 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626475(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21626474(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626476 = path.getOrDefault("resourceArn")
  valid_21626476 = validateParameter(valid_21626476, JString, required = true,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "resourceArn", valid_21626476
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the specified resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626477 = query.getOrDefault("tagKeys")
  valid_21626477 = validateParameter(valid_21626477, JArray, required = true,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "tagKeys", valid_21626477
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626478 = header.getOrDefault("X-Amz-Date")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Date", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Security-Token", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-Algorithm", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-Signature")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Signature", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Credential")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Credential", valid_21626484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626485: Call_UntagResource_21626473; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags from a specified resource.
  ## 
  let valid = call_21626485.validator(path, query, header, formData, body, _)
  let scheme = call_21626485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626485.makeUrl(scheme.get, call_21626485.host, call_21626485.base,
                               call_21626485.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626485, uri, valid, _)

proc call*(call_21626486: Call_UntagResource_21626473; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes tags from a specified resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_21626487 = newJObject()
  var query_21626488 = newJObject()
  if tagKeys != nil:
    query_21626488.add "tagKeys", tagKeys
  add(path_21626487, "resourceArn", newJString(resourceArn))
  result = call_21626486.call(path_21626487, query_21626488, nil, nil, nil)

var untagResource* = Call_UntagResource_21626473(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_21626474,
    base: "/", makeUrl: url_UntagResource_21626475,
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