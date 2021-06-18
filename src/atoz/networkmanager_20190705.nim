
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  awsServers = {Scheme.Https: {"ap-northeast-1": "networkmanager.ap-northeast-1.amazonaws.com", "ap-southeast-1": "networkmanager.ap-southeast-1.amazonaws.com", "us-west-2": "networkmanager.us-west-2.amazonaws.com", "eu-west-2": "networkmanager.eu-west-2.amazonaws.com", "ap-northeast-3": "networkmanager.ap-northeast-3.amazonaws.com", "eu-central-1": "networkmanager.eu-central-1.amazonaws.com", "us-east-2": "networkmanager.us-east-2.amazonaws.com", "us-east-1": "networkmanager.us-east-1.amazonaws.com", "cn-northwest-1": "networkmanager.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "networkmanager.ap-south-1.amazonaws.com", "eu-north-1": "networkmanager.eu-north-1.amazonaws.com", "ap-northeast-2": "networkmanager.ap-northeast-2.amazonaws.com", "us-west-1": "networkmanager.us-west-1.amazonaws.com", "us-gov-east-1": "networkmanager.us-gov-east-1.amazonaws.com", "eu-west-3": "networkmanager.eu-west-3.amazonaws.com", "cn-north-1": "networkmanager.cn-north-1.amazonaws.com.cn", "sa-east-1": "networkmanager.sa-east-1.amazonaws.com", "eu-west-1": "networkmanager.eu-west-1.amazonaws.com", "us-gov-west-1": "networkmanager.us-gov-west-1.amazonaws.com", "ap-southeast-2": "networkmanager.ap-southeast-2.amazonaws.com", "ca-central-1": "networkmanager.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AssociateCustomerGateway_402656493 = ref object of OpenApiRestCall_402656044
proc url_AssociateCustomerGateway_402656495(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
                 (kind: VariableSegment, value: "globalNetworkId"), (
        kind: ConstantSegment, value: "/customer-gateway-associations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateCustomerGateway_402656494(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656496 = path.getOrDefault("globalNetworkId")
  valid_402656496 = validateParameter(valid_402656496, JString, required = true,
                                      default = nil)
  if valid_402656496 != nil:
    section.add "globalNetworkId", valid_402656496
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656497 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Security-Token", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Signature")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Signature", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Algorithm", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Date")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Date", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Credential")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Credential", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656503
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

proc call*(call_402656505: Call_AssociateCustomerGateway_402656493;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
                                                                                         ## 
  let valid = call_402656505.validator(path, query, header, formData, body, _)
  let scheme = call_402656505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656505.makeUrl(scheme.get, call_402656505.host, call_402656505.base,
                                   call_402656505.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656505, uri, valid, _)

proc call*(call_402656506: Call_AssociateCustomerGateway_402656493;
           globalNetworkId: string; body: JsonNode): Recallable =
  ## associateCustomerGateway
  ## <p>Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. </p> <p>You can only associate customer gateways that are connected to a VPN attachment on a transit gateway. The transit gateway must be registered in your global network. When you register a transit gateway, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the <a href="https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html">DescribeVpnConnections</a> EC2 API and filter by <code>transit-gateway-id</code>.</p> <p>You cannot associate a customer gateway with more than one device and link. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## globalNetworkId: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ##                  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## ID 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## global 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## network.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var path_402656507 = newJObject()
  var body_402656508 = newJObject()
  add(path_402656507, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_402656508 = body
  result = call_402656506.call(path_402656507, nil, nil, nil, body_402656508)

var associateCustomerGateway* = Call_AssociateCustomerGateway_402656493(
    name: "associateCustomerGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_AssociateCustomerGateway_402656494, base: "/",
    makeUrl: url_AssociateCustomerGateway_402656495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCustomerGatewayAssociations_402656294 = ref object of OpenApiRestCall_402656044
proc url_GetCustomerGatewayAssociations_402656296(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
                 (kind: VariableSegment, value: "globalNetworkId"), (
        kind: ConstantSegment, value: "/customer-gateway-associations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCustomerGatewayAssociations_402656295(path: JsonNode;
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
  var valid_402656389 = path.getOrDefault("globalNetworkId")
  valid_402656389 = validateParameter(valid_402656389, JString, required = true,
                                      default = nil)
  if valid_402656389 != nil:
    section.add "globalNetworkId", valid_402656389
  result.add "path", section
  ## parameters in `query` object:
  ##   customerGatewayArns: JArray
                                  ##                      : One or more customer gateway Amazon Resource Names (ARNs). For more information, see <a 
                                  ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources 
                                  ## Defined 
                                  ## by Amazon EC2</a>. The maximum is 10.
  ##   
                                                                          ## maxResults: JInt
                                                                          ##             
                                                                          ## : 
                                                                          ## The 
                                                                          ## maximum 
                                                                          ## number 
                                                                          ## of 
                                                                          ## results 
                                                                          ## to 
                                                                          ## return.
  ##   
                                                                                    ## nextToken: JString
                                                                                    ##            
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## token 
                                                                                    ## for 
                                                                                    ## the 
                                                                                    ## next 
                                                                                    ## page 
                                                                                    ## of 
                                                                                    ## results.
  ##   
                                                                                               ## MaxResults: JString
                                                                                               ##             
                                                                                               ## : 
                                                                                               ## Pagination 
                                                                                               ## limit
  ##   
                                                                                                       ## NextToken: JString
                                                                                                       ##            
                                                                                                       ## : 
                                                                                                       ## Pagination 
                                                                                                       ## token
  section = newJObject()
  var valid_402656390 = query.getOrDefault("customerGatewayArns")
  valid_402656390 = validateParameter(valid_402656390, JArray, required = false,
                                      default = nil)
  if valid_402656390 != nil:
    section.add "customerGatewayArns", valid_402656390
  var valid_402656391 = query.getOrDefault("maxResults")
  valid_402656391 = validateParameter(valid_402656391, JInt, required = false,
                                      default = nil)
  if valid_402656391 != nil:
    section.add "maxResults", valid_402656391
  var valid_402656392 = query.getOrDefault("nextToken")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "nextToken", valid_402656392
  var valid_402656393 = query.getOrDefault("MaxResults")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "MaxResults", valid_402656393
  var valid_402656394 = query.getOrDefault("NextToken")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "NextToken", valid_402656394
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656395 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Security-Token", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Signature")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Signature", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656397
  var valid_402656398 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656398 = validateParameter(valid_402656398, JString,
                                      required = false, default = nil)
  if valid_402656398 != nil:
    section.add "X-Amz-Algorithm", valid_402656398
  var valid_402656399 = header.getOrDefault("X-Amz-Date")
  valid_402656399 = validateParameter(valid_402656399, JString,
                                      required = false, default = nil)
  if valid_402656399 != nil:
    section.add "X-Amz-Date", valid_402656399
  var valid_402656400 = header.getOrDefault("X-Amz-Credential")
  valid_402656400 = validateParameter(valid_402656400, JString,
                                      required = false, default = nil)
  if valid_402656400 != nil:
    section.add "X-Amz-Credential", valid_402656400
  var valid_402656401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656401 = validateParameter(valid_402656401, JString,
                                      required = false, default = nil)
  if valid_402656401 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656415: Call_GetCustomerGatewayAssociations_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the association information for customer gateways that are associated with devices and links in your global network.
                                                                                         ## 
  let valid = call_402656415.validator(path, query, header, formData, body, _)
  let scheme = call_402656415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656415.makeUrl(scheme.get, call_402656415.host, call_402656415.base,
                                   call_402656415.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656415, uri, valid, _)

proc call*(call_402656464: Call_GetCustomerGatewayAssociations_402656294;
           globalNetworkId: string; customerGatewayArns: JsonNode = nil;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## getCustomerGatewayAssociations
  ## Gets the association information for customer gateways that are associated with devices and links in your global network.
  ##   
                                                                                                                              ## customerGatewayArns: JArray
                                                                                                                              ##                      
                                                                                                                              ## : 
                                                                                                                              ## One 
                                                                                                                              ## or 
                                                                                                                              ## more 
                                                                                                                              ## customer 
                                                                                                                              ## gateway 
                                                                                                                              ## Amazon 
                                                                                                                              ## Resource 
                                                                                                                              ## Names 
                                                                                                                              ## (ARNs). 
                                                                                                                              ## For 
                                                                                                                              ## more 
                                                                                                                              ## information, 
                                                                                                                              ## see 
                                                                                                                              ## <a 
                                                                                                                              ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources 
                                                                                                                              ## Defined 
                                                                                                                              ## by 
                                                                                                                              ## Amazon 
                                                                                                                              ## EC2</a>. 
                                                                                                                              ## The 
                                                                                                                              ## maximum 
                                                                                                                              ## is 
                                                                                                                              ## 10.
  ##   
                                                                                                                                    ## globalNetworkId: string (required)
                                                                                                                                    ##                  
                                                                                                                                    ## : 
                                                                                                                                    ## The 
                                                                                                                                    ## ID 
                                                                                                                                    ## of 
                                                                                                                                    ## the 
                                                                                                                                    ## global 
                                                                                                                                    ## network.
  ##   
                                                                                                                                               ## maxResults: int
                                                                                                                                               ##             
                                                                                                                                               ## : 
                                                                                                                                               ## The 
                                                                                                                                               ## maximum 
                                                                                                                                               ## number 
                                                                                                                                               ## of 
                                                                                                                                               ## results 
                                                                                                                                               ## to 
                                                                                                                                               ## return.
  ##   
                                                                                                                                                         ## nextToken: string
                                                                                                                                                         ##            
                                                                                                                                                         ## : 
                                                                                                                                                         ## The 
                                                                                                                                                         ## token 
                                                                                                                                                         ## for 
                                                                                                                                                         ## the 
                                                                                                                                                         ## next 
                                                                                                                                                         ## page 
                                                                                                                                                         ## of 
                                                                                                                                                         ## results.
  ##   
                                                                                                                                                                    ## MaxResults: string
                                                                                                                                                                    ##             
                                                                                                                                                                    ## : 
                                                                                                                                                                    ## Pagination 
                                                                                                                                                                    ## limit
  ##   
                                                                                                                                                                            ## NextToken: string
                                                                                                                                                                            ##            
                                                                                                                                                                            ## : 
                                                                                                                                                                            ## Pagination 
                                                                                                                                                                            ## token
  var path_402656465 = newJObject()
  var query_402656467 = newJObject()
  if customerGatewayArns != nil:
    query_402656467.add "customerGatewayArns", customerGatewayArns
  add(path_402656465, "globalNetworkId", newJString(globalNetworkId))
  add(query_402656467, "maxResults", newJInt(maxResults))
  add(query_402656467, "nextToken", newJString(nextToken))
  add(query_402656467, "MaxResults", newJString(MaxResults))
  add(query_402656467, "NextToken", newJString(NextToken))
  result = call_402656464.call(path_402656465, query_402656467, nil, nil, nil)

var getCustomerGatewayAssociations* = Call_GetCustomerGatewayAssociations_402656294(
    name: "getCustomerGatewayAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/customer-gateway-associations",
    validator: validate_GetCustomerGatewayAssociations_402656295, base: "/",
    makeUrl: url_GetCustomerGatewayAssociations_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateLink_402656530 = ref object of OpenApiRestCall_402656044
proc url_AssociateLink_402656532(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_AssociateLink_402656531(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656533 = path.getOrDefault("globalNetworkId")
  valid_402656533 = validateParameter(valid_402656533, JString, required = true,
                                      default = nil)
  if valid_402656533 != nil:
    section.add "globalNetworkId", valid_402656533
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656534 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Security-Token", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Signature")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Signature", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Algorithm", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Date")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Date", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Credential")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Credential", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656540
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

proc call*(call_402656542: Call_AssociateLink_402656530; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
                                                                                         ## 
  let valid = call_402656542.validator(path, query, header, formData, body, _)
  let scheme = call_402656542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656542.makeUrl(scheme.get, call_402656542.host, call_402656542.base,
                                   call_402656542.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656542, uri, valid, _)

proc call*(call_402656543: Call_AssociateLink_402656530;
           globalNetworkId: string; body: JsonNode): Recallable =
  ## associateLink
  ## Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
  ##   
                                                                                                                                                                                                            ## globalNetworkId: string (required)
                                                                                                                                                                                                            ##                  
                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                            ## ID 
                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                            ## global 
                                                                                                                                                                                                            ## network.
  ##   
                                                                                                                                                                                                                       ## body: JObject (required)
  var path_402656544 = newJObject()
  var body_402656545 = newJObject()
  add(path_402656544, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_402656545 = body
  result = call_402656543.call(path_402656544, nil, nil, nil, body_402656545)

var associateLink* = Call_AssociateLink_402656530(name: "associateLink",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_AssociateLink_402656531, base: "/",
    makeUrl: url_AssociateLink_402656532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAssociations_402656509 = ref object of OpenApiRestCall_402656044
proc url_GetLinkAssociations_402656511(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_GetLinkAssociations_402656510(path: JsonNode; query: JsonNode;
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
  var valid_402656512 = path.getOrDefault("globalNetworkId")
  valid_402656512 = validateParameter(valid_402656512, JString, required = true,
                                      default = nil)
  if valid_402656512 != nil:
    section.add "globalNetworkId", valid_402656512
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return.
  ##   
                                                                                           ## nextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## token 
                                                                                           ## for 
                                                                                           ## the 
                                                                                           ## next 
                                                                                           ## page 
                                                                                           ## of 
                                                                                           ## results.
  ##   
                                                                                                      ## MaxResults: JString
                                                                                                      ##             
                                                                                                      ## : 
                                                                                                      ## Pagination 
                                                                                                      ## limit
  ##   
                                                                                                              ## deviceId: JString
                                                                                                              ##           
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## ID 
                                                                                                              ## of 
                                                                                                              ## the 
                                                                                                              ## device.
  ##   
                                                                                                                        ## NextToken: JString
                                                                                                                        ##            
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## token
  ##   
                                                                                                                                ## linkId: JString
                                                                                                                                ##         
                                                                                                                                ## : 
                                                                                                                                ## The 
                                                                                                                                ## ID 
                                                                                                                                ## of 
                                                                                                                                ## the 
                                                                                                                                ## link.
  section = newJObject()
  var valid_402656513 = query.getOrDefault("maxResults")
  valid_402656513 = validateParameter(valid_402656513, JInt, required = false,
                                      default = nil)
  if valid_402656513 != nil:
    section.add "maxResults", valid_402656513
  var valid_402656514 = query.getOrDefault("nextToken")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "nextToken", valid_402656514
  var valid_402656515 = query.getOrDefault("MaxResults")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "MaxResults", valid_402656515
  var valid_402656516 = query.getOrDefault("deviceId")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "deviceId", valid_402656516
  var valid_402656517 = query.getOrDefault("NextToken")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "NextToken", valid_402656517
  var valid_402656518 = query.getOrDefault("linkId")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "linkId", valid_402656518
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_402656526: Call_GetLinkAssociations_402656509;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the link associations for a device or a link. Either the device ID or the link ID must be specified.
                                                                                         ## 
  let valid = call_402656526.validator(path, query, header, formData, body, _)
  let scheme = call_402656526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656526.makeUrl(scheme.get, call_402656526.host, call_402656526.base,
                                   call_402656526.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656526, uri, valid, _)

proc call*(call_402656527: Call_GetLinkAssociations_402656509;
           globalNetworkId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; deviceId: string = "";
           NextToken: string = ""; linkId: string = ""): Recallable =
  ## getLinkAssociations
  ## Gets the link associations for a device or a link. Either the device ID or the link ID must be specified.
  ##   
                                                                                                              ## globalNetworkId: string (required)
                                                                                                              ##                  
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## ID 
                                                                                                              ## of 
                                                                                                              ## the 
                                                                                                              ## global 
                                                                                                              ## network.
  ##   
                                                                                                                         ## maxResults: int
                                                                                                                         ##             
                                                                                                                         ## : 
                                                                                                                         ## The 
                                                                                                                         ## maximum 
                                                                                                                         ## number 
                                                                                                                         ## of 
                                                                                                                         ## results 
                                                                                                                         ## to 
                                                                                                                         ## return.
  ##   
                                                                                                                                   ## nextToken: string
                                                                                                                                   ##            
                                                                                                                                   ## : 
                                                                                                                                   ## The 
                                                                                                                                   ## token 
                                                                                                                                   ## for 
                                                                                                                                   ## the 
                                                                                                                                   ## next 
                                                                                                                                   ## page 
                                                                                                                                   ## of 
                                                                                                                                   ## results.
  ##   
                                                                                                                                              ## MaxResults: string
                                                                                                                                              ##             
                                                                                                                                              ## : 
                                                                                                                                              ## Pagination 
                                                                                                                                              ## limit
  ##   
                                                                                                                                                      ## deviceId: string
                                                                                                                                                      ##           
                                                                                                                                                      ## : 
                                                                                                                                                      ## The 
                                                                                                                                                      ## ID 
                                                                                                                                                      ## of 
                                                                                                                                                      ## the 
                                                                                                                                                      ## device.
  ##   
                                                                                                                                                                ## NextToken: string
                                                                                                                                                                ##            
                                                                                                                                                                ## : 
                                                                                                                                                                ## Pagination 
                                                                                                                                                                ## token
  ##   
                                                                                                                                                                        ## linkId: string
                                                                                                                                                                        ##         
                                                                                                                                                                        ## : 
                                                                                                                                                                        ## The 
                                                                                                                                                                        ## ID 
                                                                                                                                                                        ## of 
                                                                                                                                                                        ## the 
                                                                                                                                                                        ## link.
  var path_402656528 = newJObject()
  var query_402656529 = newJObject()
  add(path_402656528, "globalNetworkId", newJString(globalNetworkId))
  add(query_402656529, "maxResults", newJInt(maxResults))
  add(query_402656529, "nextToken", newJString(nextToken))
  add(query_402656529, "MaxResults", newJString(MaxResults))
  add(query_402656529, "deviceId", newJString(deviceId))
  add(query_402656529, "NextToken", newJString(NextToken))
  add(query_402656529, "linkId", newJString(linkId))
  result = call_402656527.call(path_402656528, query_402656529, nil, nil, nil)

var getLinkAssociations* = Call_GetLinkAssociations_402656509(
    name: "getLinkAssociations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/link-associations",
    validator: validate_GetLinkAssociations_402656510, base: "/",
    makeUrl: url_GetLinkAssociations_402656511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevice_402656567 = ref object of OpenApiRestCall_402656044
proc url_CreateDevice_402656569(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_CreateDevice_402656568(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656570 = path.getOrDefault("globalNetworkId")
  valid_402656570 = validateParameter(valid_402656570, JString, required = true,
                                      default = nil)
  if valid_402656570 != nil:
    section.add "globalNetworkId", valid_402656570
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656571 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Security-Token", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Signature")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Signature", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Algorithm", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Date")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Date", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Credential")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Credential", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656577
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

proc call*(call_402656579: Call_CreateDevice_402656567; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
                                                                                         ## 
  let valid = call_402656579.validator(path, query, header, formData, body, _)
  let scheme = call_402656579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656579.makeUrl(scheme.get, call_402656579.host, call_402656579.base,
                                   call_402656579.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656579, uri, valid, _)

proc call*(call_402656580: Call_CreateDevice_402656567; globalNetworkId: string;
           body: JsonNode): Recallable =
  ## createDevice
  ## Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
  ##   
                                                                                                                                                                               ## globalNetworkId: string (required)
                                                                                                                                                                               ##                  
                                                                                                                                                                               ## : 
                                                                                                                                                                               ## The 
                                                                                                                                                                               ## ID 
                                                                                                                                                                               ## of 
                                                                                                                                                                               ## the 
                                                                                                                                                                               ## global 
                                                                                                                                                                               ## network.
  ##   
                                                                                                                                                                                          ## body: JObject (required)
  var path_402656581 = newJObject()
  var body_402656582 = newJObject()
  add(path_402656581, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_402656582 = body
  result = call_402656580.call(path_402656581, nil, nil, nil, body_402656582)

var createDevice* = Call_CreateDevice_402656567(name: "createDevice",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices",
    validator: validate_CreateDevice_402656568, base: "/",
    makeUrl: url_CreateDevice_402656569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevices_402656546 = ref object of OpenApiRestCall_402656044
proc url_GetDevices_402656548(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_GetDevices_402656547(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656549 = path.getOrDefault("globalNetworkId")
  valid_402656549 = validateParameter(valid_402656549, JString, required = true,
                                      default = nil)
  if valid_402656549 != nil:
    section.add "globalNetworkId", valid_402656549
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return.
  ##   
                                                                                           ## siteId: JString
                                                                                           ##         
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## ID 
                                                                                           ## of 
                                                                                           ## the 
                                                                                           ## site.
  ##   
                                                                                                   ## nextToken: JString
                                                                                                   ##            
                                                                                                   ## : 
                                                                                                   ## The 
                                                                                                   ## token 
                                                                                                   ## for 
                                                                                                   ## the 
                                                                                                   ## next 
                                                                                                   ## page 
                                                                                                   ## of 
                                                                                                   ## results.
  ##   
                                                                                                              ## deviceIds: JArray
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## One 
                                                                                                              ## or 
                                                                                                              ## more 
                                                                                                              ## device 
                                                                                                              ## IDs. 
                                                                                                              ## The 
                                                                                                              ## maximum 
                                                                                                              ## is 
                                                                                                              ## 10.
  ##   
                                                                                                                    ## MaxResults: JString
                                                                                                                    ##             
                                                                                                                    ## : 
                                                                                                                    ## Pagination 
                                                                                                                    ## limit
  ##   
                                                                                                                            ## NextToken: JString
                                                                                                                            ##            
                                                                                                                            ## : 
                                                                                                                            ## Pagination 
                                                                                                                            ## token
  section = newJObject()
  var valid_402656550 = query.getOrDefault("maxResults")
  valid_402656550 = validateParameter(valid_402656550, JInt, required = false,
                                      default = nil)
  if valid_402656550 != nil:
    section.add "maxResults", valid_402656550
  var valid_402656551 = query.getOrDefault("siteId")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "siteId", valid_402656551
  var valid_402656552 = query.getOrDefault("nextToken")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "nextToken", valid_402656552
  var valid_402656553 = query.getOrDefault("deviceIds")
  valid_402656553 = validateParameter(valid_402656553, JArray, required = false,
                                      default = nil)
  if valid_402656553 != nil:
    section.add "deviceIds", valid_402656553
  var valid_402656554 = query.getOrDefault("MaxResults")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "MaxResults", valid_402656554
  var valid_402656555 = query.getOrDefault("NextToken")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "NextToken", valid_402656555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656556 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Security-Token", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Signature")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Signature", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Algorithm", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Date")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Date", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Credential")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Credential", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656563: Call_GetDevices_402656546; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about one or more of your devices in a global network.
                                                                                         ## 
  let valid = call_402656563.validator(path, query, header, formData, body, _)
  let scheme = call_402656563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656563.makeUrl(scheme.get, call_402656563.host, call_402656563.base,
                                   call_402656563.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656563, uri, valid, _)

proc call*(call_402656564: Call_GetDevices_402656546; globalNetworkId: string;
           maxResults: int = 0; siteId: string = ""; nextToken: string = "";
           deviceIds: JsonNode = nil; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## getDevices
  ## Gets information about one or more of your devices in a global network.
  ##   
                                                                            ## globalNetworkId: string (required)
                                                                            ##                  
                                                                            ## : 
                                                                            ## The 
                                                                            ## ID 
                                                                            ## of 
                                                                            ## the 
                                                                            ## global 
                                                                            ## network.
  ##   
                                                                                       ## maxResults: int
                                                                                       ##             
                                                                                       ## : 
                                                                                       ## The 
                                                                                       ## maximum 
                                                                                       ## number 
                                                                                       ## of 
                                                                                       ## results 
                                                                                       ## to 
                                                                                       ## return.
  ##   
                                                                                                 ## siteId: string
                                                                                                 ##         
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## ID 
                                                                                                 ## of 
                                                                                                 ## the 
                                                                                                 ## site.
  ##   
                                                                                                         ## nextToken: string
                                                                                                         ##            
                                                                                                         ## : 
                                                                                                         ## The 
                                                                                                         ## token 
                                                                                                         ## for 
                                                                                                         ## the 
                                                                                                         ## next 
                                                                                                         ## page 
                                                                                                         ## of 
                                                                                                         ## results.
  ##   
                                                                                                                    ## deviceIds: JArray
                                                                                                                    ##            
                                                                                                                    ## : 
                                                                                                                    ## One 
                                                                                                                    ## or 
                                                                                                                    ## more 
                                                                                                                    ## device 
                                                                                                                    ## IDs. 
                                                                                                                    ## The 
                                                                                                                    ## maximum 
                                                                                                                    ## is 
                                                                                                                    ## 10.
  ##   
                                                                                                                          ## MaxResults: string
                                                                                                                          ##             
                                                                                                                          ## : 
                                                                                                                          ## Pagination 
                                                                                                                          ## limit
  ##   
                                                                                                                                  ## NextToken: string
                                                                                                                                  ##            
                                                                                                                                  ## : 
                                                                                                                                  ## Pagination 
                                                                                                                                  ## token
  var path_402656565 = newJObject()
  var query_402656566 = newJObject()
  add(path_402656565, "globalNetworkId", newJString(globalNetworkId))
  add(query_402656566, "maxResults", newJInt(maxResults))
  add(query_402656566, "siteId", newJString(siteId))
  add(query_402656566, "nextToken", newJString(nextToken))
  if deviceIds != nil:
    query_402656566.add "deviceIds", deviceIds
  add(query_402656566, "MaxResults", newJString(MaxResults))
  add(query_402656566, "NextToken", newJString(NextToken))
  result = call_402656564.call(path_402656565, query_402656566, nil, nil, nil)

var getDevices* = Call_GetDevices_402656546(name: "getDevices",
    meth: HttpMethod.HttpGet, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices",
    validator: validate_GetDevices_402656547, base: "/",
    makeUrl: url_GetDevices_402656548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGlobalNetwork_402656601 = ref object of OpenApiRestCall_402656044
proc url_CreateGlobalNetwork_402656603(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGlobalNetwork_402656602(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656604 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Security-Token", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Signature")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Signature", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Algorithm", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Date")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Date", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Credential")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Credential", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656610
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

proc call*(call_402656612: Call_CreateGlobalNetwork_402656601;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new, empty global network.
                                                                                         ## 
  let valid = call_402656612.validator(path, query, header, formData, body, _)
  let scheme = call_402656612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656612.makeUrl(scheme.get, call_402656612.host, call_402656612.base,
                                   call_402656612.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656612, uri, valid, _)

proc call*(call_402656613: Call_CreateGlobalNetwork_402656601; body: JsonNode): Recallable =
  ## createGlobalNetwork
  ## Creates a new, empty global network.
  ##   body: JObject (required)
  var body_402656614 = newJObject()
  if body != nil:
    body_402656614 = body
  result = call_402656613.call(nil, nil, nil, nil, body_402656614)

var createGlobalNetwork* = Call_CreateGlobalNetwork_402656601(
    name: "createGlobalNetwork", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_CreateGlobalNetwork_402656602, base: "/",
    makeUrl: url_CreateGlobalNetwork_402656603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGlobalNetworks_402656583 = ref object of OpenApiRestCall_402656044
proc url_DescribeGlobalNetworks_402656585(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeGlobalNetworks_402656584(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return.
  ##   
                                                                                           ## nextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## token 
                                                                                           ## for 
                                                                                           ## the 
                                                                                           ## next 
                                                                                           ## page 
                                                                                           ## of 
                                                                                           ## results.
  ##   
                                                                                                      ## MaxResults: JString
                                                                                                      ##             
                                                                                                      ## : 
                                                                                                      ## Pagination 
                                                                                                      ## limit
  ##   
                                                                                                              ## NextToken: JString
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## Pagination 
                                                                                                              ## token
  ##   
                                                                                                                      ## globalNetworkIds: JArray
                                                                                                                      ##                   
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## IDs 
                                                                                                                      ## of 
                                                                                                                      ## one 
                                                                                                                      ## or 
                                                                                                                      ## more 
                                                                                                                      ## global 
                                                                                                                      ## networks. 
                                                                                                                      ## The 
                                                                                                                      ## maximum 
                                                                                                                      ## is 
                                                                                                                      ## 10.
  section = newJObject()
  var valid_402656586 = query.getOrDefault("maxResults")
  valid_402656586 = validateParameter(valid_402656586, JInt, required = false,
                                      default = nil)
  if valid_402656586 != nil:
    section.add "maxResults", valid_402656586
  var valid_402656587 = query.getOrDefault("nextToken")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "nextToken", valid_402656587
  var valid_402656588 = query.getOrDefault("MaxResults")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "MaxResults", valid_402656588
  var valid_402656589 = query.getOrDefault("NextToken")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "NextToken", valid_402656589
  var valid_402656590 = query.getOrDefault("globalNetworkIds")
  valid_402656590 = validateParameter(valid_402656590, JArray, required = false,
                                      default = nil)
  if valid_402656590 != nil:
    section.add "globalNetworkIds", valid_402656590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656591 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Security-Token", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Signature")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Signature", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Algorithm", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Date")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Date", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Credential")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Credential", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656598: Call_DescribeGlobalNetworks_402656583;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
                                                                                         ## 
  let valid = call_402656598.validator(path, query, header, formData, body, _)
  let scheme = call_402656598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656598.makeUrl(scheme.get, call_402656598.host, call_402656598.base,
                                   call_402656598.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656598, uri, valid, _)

proc call*(call_402656599: Call_DescribeGlobalNetworks_402656583;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""; globalNetworkIds: JsonNode = nil): Recallable =
  ## describeGlobalNetworks
  ## Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate <code>Get*</code> action. For example, to list the transit gateways in your global network, use <a>GetTransitGatewayRegistrations</a>.
  ##   
                                                                                                                                                                                                                                                                                                              ## maxResults: int
                                                                                                                                                                                                                                                                                                              ##             
                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                              ## maximum 
                                                                                                                                                                                                                                                                                                              ## number 
                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                              ## results 
                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                              ## return.
  ##   
                                                                                                                                                                                                                                                                                                                        ## nextToken: string
                                                                                                                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                        ## token 
                                                                                                                                                                                                                                                                                                                        ## for 
                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                        ## next 
                                                                                                                                                                                                                                                                                                                        ## page 
                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                        ## results.
  ##   
                                                                                                                                                                                                                                                                                                                                   ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                   ##             
                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                                                                                                                                                                   ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                           ## NextToken: string
                                                                                                                                                                                                                                                                                                                                           ##            
                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                           ## Pagination 
                                                                                                                                                                                                                                                                                                                                           ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                   ## globalNetworkIds: JArray
                                                                                                                                                                                                                                                                                                                                                   ##                   
                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                   ## IDs 
                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                   ## one 
                                                                                                                                                                                                                                                                                                                                                   ## or 
                                                                                                                                                                                                                                                                                                                                                   ## more 
                                                                                                                                                                                                                                                                                                                                                   ## global 
                                                                                                                                                                                                                                                                                                                                                   ## networks. 
                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                   ## maximum 
                                                                                                                                                                                                                                                                                                                                                   ## is 
                                                                                                                                                                                                                                                                                                                                                   ## 10.
  var query_402656600 = newJObject()
  add(query_402656600, "maxResults", newJInt(maxResults))
  add(query_402656600, "nextToken", newJString(nextToken))
  add(query_402656600, "MaxResults", newJString(MaxResults))
  add(query_402656600, "NextToken", newJString(NextToken))
  if globalNetworkIds != nil:
    query_402656600.add "globalNetworkIds", globalNetworkIds
  result = call_402656599.call(nil, query_402656600, nil, nil, nil)

var describeGlobalNetworks* = Call_DescribeGlobalNetworks_402656583(
    name: "describeGlobalNetworks", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/global-networks",
    validator: validate_DescribeGlobalNetworks_402656584, base: "/",
    makeUrl: url_DescribeGlobalNetworks_402656585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLink_402656638 = ref object of OpenApiRestCall_402656044
proc url_CreateLink_402656640(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_CreateLink_402656639(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656641 = path.getOrDefault("globalNetworkId")
  valid_402656641 = validateParameter(valid_402656641, JString, required = true,
                                      default = nil)
  if valid_402656641 != nil:
    section.add "globalNetworkId", valid_402656641
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Security-Token", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Signature")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Signature", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Algorithm", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Date")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Date", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Credential")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Credential", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656648
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

proc call*(call_402656650: Call_CreateLink_402656638; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new link for a specified site.
                                                                                         ## 
  let valid = call_402656650.validator(path, query, header, formData, body, _)
  let scheme = call_402656650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656650.makeUrl(scheme.get, call_402656650.host, call_402656650.base,
                                   call_402656650.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656650, uri, valid, _)

proc call*(call_402656651: Call_CreateLink_402656638; globalNetworkId: string;
           body: JsonNode): Recallable =
  ## createLink
  ## Creates a new link for a specified site.
  ##   globalNetworkId: string (required)
                                             ##                  : The ID of the global network.
  ##   
                                                                                                ## body: JObject (required)
  var path_402656652 = newJObject()
  var body_402656653 = newJObject()
  add(path_402656652, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_402656653 = body
  result = call_402656651.call(path_402656652, nil, nil, nil, body_402656653)

var createLink* = Call_CreateLink_402656638(name: "createLink",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/links",
    validator: validate_CreateLink_402656639, base: "/",
    makeUrl: url_CreateLink_402656640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinks_402656615 = ref object of OpenApiRestCall_402656044
proc url_GetLinks_402656617(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_GetLinks_402656616(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656618 = path.getOrDefault("globalNetworkId")
  valid_402656618 = validateParameter(valid_402656618, JString, required = true,
                                      default = nil)
  if valid_402656618 != nil:
    section.add "globalNetworkId", valid_402656618
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return.
  ##   
                                                                                           ## siteId: JString
                                                                                           ##         
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## ID 
                                                                                           ## of 
                                                                                           ## the 
                                                                                           ## site.
  ##   
                                                                                                   ## nextToken: JString
                                                                                                   ##            
                                                                                                   ## : 
                                                                                                   ## The 
                                                                                                   ## token 
                                                                                                   ## for 
                                                                                                   ## the 
                                                                                                   ## next 
                                                                                                   ## page 
                                                                                                   ## of 
                                                                                                   ## results.
  ##   
                                                                                                              ## MaxResults: JString
                                                                                                              ##             
                                                                                                              ## : 
                                                                                                              ## Pagination 
                                                                                                              ## limit
  ##   
                                                                                                                      ## NextToken: JString
                                                                                                                      ##            
                                                                                                                      ## : 
                                                                                                                      ## Pagination 
                                                                                                                      ## token
  ##   
                                                                                                                              ## type: JString
                                                                                                                              ##       
                                                                                                                              ## : 
                                                                                                                              ## The 
                                                                                                                              ## link 
                                                                                                                              ## type.
  ##   
                                                                                                                                      ## linkIds: JArray
                                                                                                                                      ##          
                                                                                                                                      ## : 
                                                                                                                                      ## One 
                                                                                                                                      ## or 
                                                                                                                                      ## more 
                                                                                                                                      ## link 
                                                                                                                                      ## IDs. 
                                                                                                                                      ## The 
                                                                                                                                      ## maximum 
                                                                                                                                      ## is 
                                                                                                                                      ## 10.
  ##   
                                                                                                                                            ## provider: JString
                                                                                                                                            ##           
                                                                                                                                            ## : 
                                                                                                                                            ## The 
                                                                                                                                            ## link 
                                                                                                                                            ## provider.
  section = newJObject()
  var valid_402656619 = query.getOrDefault("maxResults")
  valid_402656619 = validateParameter(valid_402656619, JInt, required = false,
                                      default = nil)
  if valid_402656619 != nil:
    section.add "maxResults", valid_402656619
  var valid_402656620 = query.getOrDefault("siteId")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "siteId", valid_402656620
  var valid_402656621 = query.getOrDefault("nextToken")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "nextToken", valid_402656621
  var valid_402656622 = query.getOrDefault("MaxResults")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "MaxResults", valid_402656622
  var valid_402656623 = query.getOrDefault("NextToken")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "NextToken", valid_402656623
  var valid_402656624 = query.getOrDefault("type")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "type", valid_402656624
  var valid_402656625 = query.getOrDefault("linkIds")
  valid_402656625 = validateParameter(valid_402656625, JArray, required = false,
                                      default = nil)
  if valid_402656625 != nil:
    section.add "linkIds", valid_402656625
  var valid_402656626 = query.getOrDefault("provider")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "provider", valid_402656626
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Security-Token", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Signature")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Signature", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Algorithm", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Date")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Date", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Credential")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Credential", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656634: Call_GetLinks_402656615; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets information about one or more links in a specified global network.</p> <p>If you specify the site ID, you cannot specify the type or provider in the same request. You can specify the type and provider in the same request.</p>
                                                                                         ## 
  let valid = call_402656634.validator(path, query, header, formData, body, _)
  let scheme = call_402656634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656634.makeUrl(scheme.get, call_402656634.host, call_402656634.base,
                                   call_402656634.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656634, uri, valid, _)

proc call*(call_402656635: Call_GetLinks_402656615; globalNetworkId: string;
           maxResults: int = 0; siteId: string = ""; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""; `type`: string = "";
           linkIds: JsonNode = nil; provider: string = ""): Recallable =
  ## getLinks
  ## <p>Gets information about one or more links in a specified global network.</p> <p>If you specify the site ID, you cannot specify the type or provider in the same request. You can specify the type and provider in the same request.</p>
  ##   
                                                                                                                                                                                                                                              ## globalNetworkId: string (required)
                                                                                                                                                                                                                                              ##                  
                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                              ## ID 
                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                              ## global 
                                                                                                                                                                                                                                              ## network.
  ##   
                                                                                                                                                                                                                                                         ## maxResults: int
                                                                                                                                                                                                                                                         ##             
                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                         ## maximum 
                                                                                                                                                                                                                                                         ## number 
                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                         ## results 
                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                         ## return.
  ##   
                                                                                                                                                                                                                                                                   ## siteId: string
                                                                                                                                                                                                                                                                   ##         
                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                   ## ID 
                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                   ## site.
  ##   
                                                                                                                                                                                                                                                                           ## nextToken: string
                                                                                                                                                                                                                                                                           ##            
                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                                                                           ## token 
                                                                                                                                                                                                                                                                           ## for 
                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                           ## next 
                                                                                                                                                                                                                                                                           ## page 
                                                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                                                           ## results.
  ##   
                                                                                                                                                                                                                                                                                      ## MaxResults: string
                                                                                                                                                                                                                                                                                      ##             
                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                      ## Pagination 
                                                                                                                                                                                                                                                                                      ## limit
  ##   
                                                                                                                                                                                                                                                                                              ## NextToken: string
                                                                                                                                                                                                                                                                                              ##            
                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                              ## Pagination 
                                                                                                                                                                                                                                                                                              ## token
  ##   
                                                                                                                                                                                                                                                                                                      ## type: string
                                                                                                                                                                                                                                                                                                      ##       
                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                      ## link 
                                                                                                                                                                                                                                                                                                      ## type.
  ##   
                                                                                                                                                                                                                                                                                                              ## linkIds: JArray
                                                                                                                                                                                                                                                                                                              ##          
                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                              ## One 
                                                                                                                                                                                                                                                                                                              ## or 
                                                                                                                                                                                                                                                                                                              ## more 
                                                                                                                                                                                                                                                                                                              ## link 
                                                                                                                                                                                                                                                                                                              ## IDs. 
                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                              ## maximum 
                                                                                                                                                                                                                                                                                                              ## is 
                                                                                                                                                                                                                                                                                                              ## 10.
  ##   
                                                                                                                                                                                                                                                                                                                    ## provider: string
                                                                                                                                                                                                                                                                                                                    ##           
                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                                                                                    ## link 
                                                                                                                                                                                                                                                                                                                    ## provider.
  var path_402656636 = newJObject()
  var query_402656637 = newJObject()
  add(path_402656636, "globalNetworkId", newJString(globalNetworkId))
  add(query_402656637, "maxResults", newJInt(maxResults))
  add(query_402656637, "siteId", newJString(siteId))
  add(query_402656637, "nextToken", newJString(nextToken))
  add(query_402656637, "MaxResults", newJString(MaxResults))
  add(query_402656637, "NextToken", newJString(NextToken))
  add(query_402656637, "type", newJString(`type`))
  if linkIds != nil:
    query_402656637.add "linkIds", linkIds
  add(query_402656637, "provider", newJString(provider))
  result = call_402656635.call(path_402656636, query_402656637, nil, nil, nil)

var getLinks* = Call_GetLinks_402656615(name: "getLinks",
                                        meth: HttpMethod.HttpGet,
                                        host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/links",
                                        validator: validate_GetLinks_402656616,
                                        base: "/", makeUrl: url_GetLinks_402656617,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSite_402656674 = ref object of OpenApiRestCall_402656044
proc url_CreateSite_402656676(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_CreateSite_402656675(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656677 = path.getOrDefault("globalNetworkId")
  valid_402656677 = validateParameter(valid_402656677, JString, required = true,
                                      default = nil)
  if valid_402656677 != nil:
    section.add "globalNetworkId", valid_402656677
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656678 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Security-Token", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Signature")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Signature", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Algorithm", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Date")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Date", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Credential")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Credential", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656684
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

proc call*(call_402656686: Call_CreateSite_402656674; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new site in a global network.
                                                                                         ## 
  let valid = call_402656686.validator(path, query, header, formData, body, _)
  let scheme = call_402656686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656686.makeUrl(scheme.get, call_402656686.host, call_402656686.base,
                                   call_402656686.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656686, uri, valid, _)

proc call*(call_402656687: Call_CreateSite_402656674; globalNetworkId: string;
           body: JsonNode): Recallable =
  ## createSite
  ## Creates a new site in a global network.
  ##   globalNetworkId: string (required)
                                            ##                  : The ID of the global network.
  ##   
                                                                                               ## body: JObject (required)
  var path_402656688 = newJObject()
  var body_402656689 = newJObject()
  add(path_402656688, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_402656689 = body
  result = call_402656687.call(path_402656688, nil, nil, nil, body_402656689)

var createSite* = Call_CreateSite_402656674(name: "createSite",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/sites",
    validator: validate_CreateSite_402656675, base: "/",
    makeUrl: url_CreateSite_402656676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSites_402656654 = ref object of OpenApiRestCall_402656044
proc url_GetSites_402656656(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_GetSites_402656655(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656657 = path.getOrDefault("globalNetworkId")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true,
                                      default = nil)
  if valid_402656657 != nil:
    section.add "globalNetworkId", valid_402656657
  result.add "path", section
  ## parameters in `query` object:
  ##   siteIds: JArray
                                  ##          : One or more site IDs. The maximum is 10.
  ##   
                                                                                        ## maxResults: JInt
                                                                                        ##             
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## maximum 
                                                                                        ## number 
                                                                                        ## of 
                                                                                        ## results 
                                                                                        ## to 
                                                                                        ## return.
  ##   
                                                                                                  ## nextToken: JString
                                                                                                  ##            
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## token 
                                                                                                  ## for 
                                                                                                  ## the 
                                                                                                  ## next 
                                                                                                  ## page 
                                                                                                  ## of 
                                                                                                  ## results.
  ##   
                                                                                                             ## MaxResults: JString
                                                                                                             ##             
                                                                                                             ## : 
                                                                                                             ## Pagination 
                                                                                                             ## limit
  ##   
                                                                                                                     ## NextToken: JString
                                                                                                                     ##            
                                                                                                                     ## : 
                                                                                                                     ## Pagination 
                                                                                                                     ## token
  section = newJObject()
  var valid_402656658 = query.getOrDefault("siteIds")
  valid_402656658 = validateParameter(valid_402656658, JArray, required = false,
                                      default = nil)
  if valid_402656658 != nil:
    section.add "siteIds", valid_402656658
  var valid_402656659 = query.getOrDefault("maxResults")
  valid_402656659 = validateParameter(valid_402656659, JInt, required = false,
                                      default = nil)
  if valid_402656659 != nil:
    section.add "maxResults", valid_402656659
  var valid_402656660 = query.getOrDefault("nextToken")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "nextToken", valid_402656660
  var valid_402656661 = query.getOrDefault("MaxResults")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "MaxResults", valid_402656661
  var valid_402656662 = query.getOrDefault("NextToken")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "NextToken", valid_402656662
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656663 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Security-Token", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Signature")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Signature", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Algorithm", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Date")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Date", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Credential")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Credential", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656670: Call_GetSites_402656654; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about one or more of your sites in a global network.
                                                                                         ## 
  let valid = call_402656670.validator(path, query, header, formData, body, _)
  let scheme = call_402656670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656670.makeUrl(scheme.get, call_402656670.host, call_402656670.base,
                                   call_402656670.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656670, uri, valid, _)

proc call*(call_402656671: Call_GetSites_402656654; globalNetworkId: string;
           siteIds: JsonNode = nil; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getSites
  ## Gets information about one or more of your sites in a global network.
  ##   
                                                                          ## globalNetworkId: string (required)
                                                                          ##                  
                                                                          ## : 
                                                                          ## The 
                                                                          ## ID 
                                                                          ## of 
                                                                          ## the 
                                                                          ## global 
                                                                          ## network.
  ##   
                                                                                     ## siteIds: JArray
                                                                                     ##          
                                                                                     ## : 
                                                                                     ## One 
                                                                                     ## or 
                                                                                     ## more 
                                                                                     ## site 
                                                                                     ## IDs. 
                                                                                     ## The 
                                                                                     ## maximum 
                                                                                     ## is 
                                                                                     ## 10.
  ##   
                                                                                           ## maxResults: int
                                                                                           ##             
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## maximum 
                                                                                           ## number 
                                                                                           ## of 
                                                                                           ## results 
                                                                                           ## to 
                                                                                           ## return.
  ##   
                                                                                                     ## nextToken: string
                                                                                                     ##            
                                                                                                     ## : 
                                                                                                     ## The 
                                                                                                     ## token 
                                                                                                     ## for 
                                                                                                     ## the 
                                                                                                     ## next 
                                                                                                     ## page 
                                                                                                     ## of 
                                                                                                     ## results.
  ##   
                                                                                                                ## MaxResults: string
                                                                                                                ##             
                                                                                                                ## : 
                                                                                                                ## Pagination 
                                                                                                                ## limit
  ##   
                                                                                                                        ## NextToken: string
                                                                                                                        ##            
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## token
  var path_402656672 = newJObject()
  var query_402656673 = newJObject()
  add(path_402656672, "globalNetworkId", newJString(globalNetworkId))
  if siteIds != nil:
    query_402656673.add "siteIds", siteIds
  add(query_402656673, "maxResults", newJInt(maxResults))
  add(query_402656673, "nextToken", newJString(nextToken))
  add(query_402656673, "MaxResults", newJString(MaxResults))
  add(query_402656673, "NextToken", newJString(NextToken))
  result = call_402656671.call(path_402656672, query_402656673, nil, nil, nil)

var getSites* = Call_GetSites_402656654(name: "getSites",
                                        meth: HttpMethod.HttpGet,
                                        host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/sites",
                                        validator: validate_GetSites_402656655,
                                        base: "/", makeUrl: url_GetSites_402656656,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevice_402656705 = ref object of OpenApiRestCall_402656044
proc url_UpdateDevice_402656707(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_UpdateDevice_402656706(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
                                 ##           : The ID of the device.
  ##   
                                                                     ## globalNetworkId: JString (required)
                                                                     ##                  
                                                                     ## : 
                                                                     ## The ID of the global 
                                                                     ## network.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `deviceId` field"
  var valid_402656708 = path.getOrDefault("deviceId")
  valid_402656708 = validateParameter(valid_402656708, JString, required = true,
                                      default = nil)
  if valid_402656708 != nil:
    section.add "deviceId", valid_402656708
  var valid_402656709 = path.getOrDefault("globalNetworkId")
  valid_402656709 = validateParameter(valid_402656709, JString, required = true,
                                      default = nil)
  if valid_402656709 != nil:
    section.add "globalNetworkId", valid_402656709
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656710 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Security-Token", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-Signature")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Signature", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656712
  var valid_402656713 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Algorithm", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Date")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Date", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Credential")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Credential", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656716
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

proc call*(call_402656718: Call_UpdateDevice_402656705; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
                                                                                         ## 
  let valid = call_402656718.validator(path, query, header, formData, body, _)
  let scheme = call_402656718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656718.makeUrl(scheme.get, call_402656718.host, call_402656718.base,
                                   call_402656718.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656718, uri, valid, _)

proc call*(call_402656719: Call_UpdateDevice_402656705; deviceId: string;
           globalNetworkId: string; body: JsonNode): Recallable =
  ## updateDevice
  ## Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
  ##   
                                                                                                                          ## deviceId: string (required)
                                                                                                                          ##           
                                                                                                                          ## : 
                                                                                                                          ## The 
                                                                                                                          ## ID 
                                                                                                                          ## of 
                                                                                                                          ## the 
                                                                                                                          ## device.
  ##   
                                                                                                                                    ## globalNetworkId: string (required)
                                                                                                                                    ##                  
                                                                                                                                    ## : 
                                                                                                                                    ## The 
                                                                                                                                    ## ID 
                                                                                                                                    ## of 
                                                                                                                                    ## the 
                                                                                                                                    ## global 
                                                                                                                                    ## network.
  ##   
                                                                                                                                               ## body: JObject (required)
  var path_402656720 = newJObject()
  var body_402656721 = newJObject()
  add(path_402656720, "deviceId", newJString(deviceId))
  add(path_402656720, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_402656721 = body
  result = call_402656719.call(path_402656720, nil, nil, nil, body_402656721)

var updateDevice* = Call_UpdateDevice_402656705(name: "updateDevice",
    meth: HttpMethod.HttpPatch, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_UpdateDevice_402656706, base: "/",
    makeUrl: url_UpdateDevice_402656707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevice_402656690 = ref object of OpenApiRestCall_402656044
proc url_DeleteDevice_402656692(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_DeleteDevice_402656691(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   deviceId: JString (required)
                                 ##           : The ID of the device.
  ##   
                                                                     ## globalNetworkId: JString (required)
                                                                     ##                  
                                                                     ## : 
                                                                     ## The ID of the global 
                                                                     ## network.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `deviceId` field"
  var valid_402656693 = path.getOrDefault("deviceId")
  valid_402656693 = validateParameter(valid_402656693, JString, required = true,
                                      default = nil)
  if valid_402656693 != nil:
    section.add "deviceId", valid_402656693
  var valid_402656694 = path.getOrDefault("globalNetworkId")
  valid_402656694 = validateParameter(valid_402656694, JString, required = true,
                                      default = nil)
  if valid_402656694 != nil:
    section.add "globalNetworkId", valid_402656694
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656695 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Security-Token", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-Signature")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Signature", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Algorithm", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Date")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Date", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Credential")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Credential", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656702: Call_DeleteDevice_402656690; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
                                                                                         ## 
  let valid = call_402656702.validator(path, query, header, formData, body, _)
  let scheme = call_402656702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656702.makeUrl(scheme.get, call_402656702.host, call_402656702.base,
                                   call_402656702.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656702, uri, valid, _)

proc call*(call_402656703: Call_DeleteDevice_402656690; deviceId: string;
           globalNetworkId: string): Recallable =
  ## deleteDevice
  ## Deletes an existing device. You must first disassociate the device from any links and customer gateways.
  ##   
                                                                                                             ## deviceId: string (required)
                                                                                                             ##           
                                                                                                             ## : 
                                                                                                             ## The 
                                                                                                             ## ID 
                                                                                                             ## of 
                                                                                                             ## the 
                                                                                                             ## device.
  ##   
                                                                                                                       ## globalNetworkId: string (required)
                                                                                                                       ##                  
                                                                                                                       ## : 
                                                                                                                       ## The 
                                                                                                                       ## ID 
                                                                                                                       ## of 
                                                                                                                       ## the 
                                                                                                                       ## global 
                                                                                                                       ## network.
  var path_402656704 = newJObject()
  add(path_402656704, "deviceId", newJString(deviceId))
  add(path_402656704, "globalNetworkId", newJString(globalNetworkId))
  result = call_402656703.call(path_402656704, nil, nil, nil, nil)

var deleteDevice* = Call_DeleteDevice_402656690(name: "deleteDevice",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/devices/{deviceId}",
    validator: validate_DeleteDevice_402656691, base: "/",
    makeUrl: url_DeleteDevice_402656692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGlobalNetwork_402656736 = ref object of OpenApiRestCall_402656044
proc url_UpdateGlobalNetwork_402656738(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_UpdateGlobalNetwork_402656737(path: JsonNode; query: JsonNode;
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
  var valid_402656739 = path.getOrDefault("globalNetworkId")
  valid_402656739 = validateParameter(valid_402656739, JString, required = true,
                                      default = nil)
  if valid_402656739 != nil:
    section.add "globalNetworkId", valid_402656739
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656740 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Security-Token", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Signature")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Signature", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-Algorithm", valid_402656743
  var valid_402656744 = header.getOrDefault("X-Amz-Date")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Date", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-Credential")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Credential", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656746
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

proc call*(call_402656748: Call_UpdateGlobalNetwork_402656736;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
                                                                                         ## 
  let valid = call_402656748.validator(path, query, header, formData, body, _)
  let scheme = call_402656748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656748.makeUrl(scheme.get, call_402656748.host, call_402656748.base,
                                   call_402656748.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656748, uri, valid, _)

proc call*(call_402656749: Call_UpdateGlobalNetwork_402656736;
           globalNetworkId: string; body: JsonNode): Recallable =
  ## updateGlobalNetwork
  ## Updates an existing global network. To remove information for any of the parameters, specify an empty string.
  ##   
                                                                                                                  ## globalNetworkId: string (required)
                                                                                                                  ##                  
                                                                                                                  ## : 
                                                                                                                  ## The 
                                                                                                                  ## ID 
                                                                                                                  ## of 
                                                                                                                  ## your 
                                                                                                                  ## global 
                                                                                                                  ## network.
  ##   
                                                                                                                             ## body: JObject (required)
  var path_402656750 = newJObject()
  var body_402656751 = newJObject()
  add(path_402656750, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_402656751 = body
  result = call_402656749.call(path_402656750, nil, nil, nil, body_402656751)

var updateGlobalNetwork* = Call_UpdateGlobalNetwork_402656736(
    name: "updateGlobalNetwork", meth: HttpMethod.HttpPatch,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_UpdateGlobalNetwork_402656737, base: "/",
    makeUrl: url_UpdateGlobalNetwork_402656738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGlobalNetwork_402656722 = ref object of OpenApiRestCall_402656044
proc url_DeleteGlobalNetwork_402656724(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_DeleteGlobalNetwork_402656723(path: JsonNode; query: JsonNode;
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
  var valid_402656725 = path.getOrDefault("globalNetworkId")
  valid_402656725 = validateParameter(valid_402656725, JString, required = true,
                                      default = nil)
  if valid_402656725 != nil:
    section.add "globalNetworkId", valid_402656725
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656726 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Security-Token", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Signature")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Signature", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Algorithm", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-Date")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Date", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Credential")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Credential", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656733: Call_DeleteGlobalNetwork_402656722;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
                                                                                         ## 
  let valid = call_402656733.validator(path, query, header, formData, body, _)
  let scheme = call_402656733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656733.makeUrl(scheme.get, call_402656733.host, call_402656733.base,
                                   call_402656733.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656733, uri, valid, _)

proc call*(call_402656734: Call_DeleteGlobalNetwork_402656722;
           globalNetworkId: string): Recallable =
  ## deleteGlobalNetwork
  ## Deletes an existing global network. You must first delete all global network objects (devices, links, and sites) and deregister all transit gateways.
  ##   
                                                                                                                                                          ## globalNetworkId: string (required)
                                                                                                                                                          ##                  
                                                                                                                                                          ## : 
                                                                                                                                                          ## The 
                                                                                                                                                          ## ID 
                                                                                                                                                          ## of 
                                                                                                                                                          ## the 
                                                                                                                                                          ## global 
                                                                                                                                                          ## network.
  var path_402656735 = newJObject()
  add(path_402656735, "globalNetworkId", newJString(globalNetworkId))
  result = call_402656734.call(path_402656735, nil, nil, nil, nil)

var deleteGlobalNetwork* = Call_DeleteGlobalNetwork_402656722(
    name: "deleteGlobalNetwork", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}",
    validator: validate_DeleteGlobalNetwork_402656723, base: "/",
    makeUrl: url_DeleteGlobalNetwork_402656724,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLink_402656767 = ref object of OpenApiRestCall_402656044
proc url_UpdateLink_402656769(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_UpdateLink_402656768(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
                                 ##                  : The ID of the global network.
  ##   
                                                                                    ## linkId: JString (required)
                                                                                    ##         
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## ID 
                                                                                    ## of 
                                                                                    ## the 
                                                                                    ## link.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `globalNetworkId` field"
  var valid_402656770 = path.getOrDefault("globalNetworkId")
  valid_402656770 = validateParameter(valid_402656770, JString, required = true,
                                      default = nil)
  if valid_402656770 != nil:
    section.add "globalNetworkId", valid_402656770
  var valid_402656771 = path.getOrDefault("linkId")
  valid_402656771 = validateParameter(valid_402656771, JString, required = true,
                                      default = nil)
  if valid_402656771 != nil:
    section.add "linkId", valid_402656771
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656772 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Security-Token", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Signature")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Signature", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Algorithm", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-Date")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-Date", valid_402656776
  var valid_402656777 = header.getOrDefault("X-Amz-Credential")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-Credential", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656778
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

proc call*(call_402656780: Call_UpdateLink_402656767; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
                                                                                         ## 
  let valid = call_402656780.validator(path, query, header, formData, body, _)
  let scheme = call_402656780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656780.makeUrl(scheme.get, call_402656780.host, call_402656780.base,
                                   call_402656780.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656780, uri, valid, _)

proc call*(call_402656781: Call_UpdateLink_402656767; globalNetworkId: string;
           body: JsonNode; linkId: string): Recallable =
  ## updateLink
  ## Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
  ##   
                                                                                                                        ## globalNetworkId: string (required)
                                                                                                                        ##                  
                                                                                                                        ## : 
                                                                                                                        ## The 
                                                                                                                        ## ID 
                                                                                                                        ## of 
                                                                                                                        ## the 
                                                                                                                        ## global 
                                                                                                                        ## network.
  ##   
                                                                                                                                   ## body: JObject (required)
  ##   
                                                                                                                                                              ## linkId: string (required)
                                                                                                                                                              ##         
                                                                                                                                                              ## : 
                                                                                                                                                              ## The 
                                                                                                                                                              ## ID 
                                                                                                                                                              ## of 
                                                                                                                                                              ## the 
                                                                                                                                                              ## link.
  var path_402656782 = newJObject()
  var body_402656783 = newJObject()
  add(path_402656782, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_402656783 = body
  add(path_402656782, "linkId", newJString(linkId))
  result = call_402656781.call(path_402656782, nil, nil, nil, body_402656783)

var updateLink* = Call_UpdateLink_402656767(name: "updateLink",
    meth: HttpMethod.HttpPatch, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/links/{linkId}",
    validator: validate_UpdateLink_402656768, base: "/",
    makeUrl: url_UpdateLink_402656769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLink_402656752 = ref object of OpenApiRestCall_402656044
proc url_DeleteLink_402656754(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_DeleteLink_402656753(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
                                 ##                  : The ID of the global network.
  ##   
                                                                                    ## linkId: JString (required)
                                                                                    ##         
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## ID 
                                                                                    ## of 
                                                                                    ## the 
                                                                                    ## link.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `globalNetworkId` field"
  var valid_402656755 = path.getOrDefault("globalNetworkId")
  valid_402656755 = validateParameter(valid_402656755, JString, required = true,
                                      default = nil)
  if valid_402656755 != nil:
    section.add "globalNetworkId", valid_402656755
  var valid_402656756 = path.getOrDefault("linkId")
  valid_402656756 = validateParameter(valid_402656756, JString, required = true,
                                      default = nil)
  if valid_402656756 != nil:
    section.add "linkId", valid_402656756
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656757 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-Security-Token", valid_402656757
  var valid_402656758 = header.getOrDefault("X-Amz-Signature")
  valid_402656758 = validateParameter(valid_402656758, JString,
                                      required = false, default = nil)
  if valid_402656758 != nil:
    section.add "X-Amz-Signature", valid_402656758
  var valid_402656759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-Algorithm", valid_402656760
  var valid_402656761 = header.getOrDefault("X-Amz-Date")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "X-Amz-Date", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Credential")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Credential", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656764: Call_DeleteLink_402656752; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
                                                                                         ## 
  let valid = call_402656764.validator(path, query, header, formData, body, _)
  let scheme = call_402656764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656764.makeUrl(scheme.get, call_402656764.host, call_402656764.base,
                                   call_402656764.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656764, uri, valid, _)

proc call*(call_402656765: Call_DeleteLink_402656752; globalNetworkId: string;
           linkId: string): Recallable =
  ## deleteLink
  ## Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
  ##   
                                                                                                           ## globalNetworkId: string (required)
                                                                                                           ##                  
                                                                                                           ## : 
                                                                                                           ## The 
                                                                                                           ## ID 
                                                                                                           ## of 
                                                                                                           ## the 
                                                                                                           ## global 
                                                                                                           ## network.
  ##   
                                                                                                                      ## linkId: string (required)
                                                                                                                      ##         
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## ID 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## link.
  var path_402656766 = newJObject()
  add(path_402656766, "globalNetworkId", newJString(globalNetworkId))
  add(path_402656766, "linkId", newJString(linkId))
  result = call_402656765.call(path_402656766, nil, nil, nil, nil)

var deleteLink* = Call_DeleteLink_402656752(name: "deleteLink",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/links/{linkId}",
    validator: validate_DeleteLink_402656753, base: "/",
    makeUrl: url_DeleteLink_402656754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSite_402656799 = ref object of OpenApiRestCall_402656044
proc url_UpdateSite_402656801(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_UpdateSite_402656800(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
                                 ##                  : The ID of the global network.
  ##   
                                                                                    ## siteId: JString (required)
                                                                                    ##         
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## ID 
                                                                                    ## of 
                                                                                    ## your 
                                                                                    ## site.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `globalNetworkId` field"
  var valid_402656802 = path.getOrDefault("globalNetworkId")
  valid_402656802 = validateParameter(valid_402656802, JString, required = true,
                                      default = nil)
  if valid_402656802 != nil:
    section.add "globalNetworkId", valid_402656802
  var valid_402656803 = path.getOrDefault("siteId")
  valid_402656803 = validateParameter(valid_402656803, JString, required = true,
                                      default = nil)
  if valid_402656803 != nil:
    section.add "siteId", valid_402656803
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656804 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Security-Token", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-Signature")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Signature", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Algorithm", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Date")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Date", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Credential")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Credential", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656810
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

proc call*(call_402656812: Call_UpdateSite_402656799; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
                                                                                         ## 
  let valid = call_402656812.validator(path, query, header, formData, body, _)
  let scheme = call_402656812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656812.makeUrl(scheme.get, call_402656812.host, call_402656812.base,
                                   call_402656812.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656812, uri, valid, _)

proc call*(call_402656813: Call_UpdateSite_402656799; globalNetworkId: string;
           body: JsonNode; siteId: string): Recallable =
  ## updateSite
  ## Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
  ##   
                                                                                                                            ## globalNetworkId: string (required)
                                                                                                                            ##                  
                                                                                                                            ## : 
                                                                                                                            ## The 
                                                                                                                            ## ID 
                                                                                                                            ## of 
                                                                                                                            ## the 
                                                                                                                            ## global 
                                                                                                                            ## network.
  ##   
                                                                                                                                       ## body: JObject (required)
  ##   
                                                                                                                                                                  ## siteId: string (required)
                                                                                                                                                                  ##         
                                                                                                                                                                  ## : 
                                                                                                                                                                  ## The 
                                                                                                                                                                  ## ID 
                                                                                                                                                                  ## of 
                                                                                                                                                                  ## your 
                                                                                                                                                                  ## site.
  var path_402656814 = newJObject()
  var body_402656815 = newJObject()
  add(path_402656814, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_402656815 = body
  add(path_402656814, "siteId", newJString(siteId))
  result = call_402656813.call(path_402656814, nil, nil, nil, body_402656815)

var updateSite* = Call_UpdateSite_402656799(name: "updateSite",
    meth: HttpMethod.HttpPatch, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/sites/{siteId}",
    validator: validate_UpdateSite_402656800, base: "/",
    makeUrl: url_UpdateSite_402656801, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSite_402656784 = ref object of OpenApiRestCall_402656044
proc url_DeleteSite_402656786(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_DeleteSite_402656785(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing site. The site cannot be associated with any device or link.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
                                 ##                  : The ID of the global network.
  ##   
                                                                                    ## siteId: JString (required)
                                                                                    ##         
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## ID 
                                                                                    ## of 
                                                                                    ## the 
                                                                                    ## site.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `globalNetworkId` field"
  var valid_402656787 = path.getOrDefault("globalNetworkId")
  valid_402656787 = validateParameter(valid_402656787, JString, required = true,
                                      default = nil)
  if valid_402656787 != nil:
    section.add "globalNetworkId", valid_402656787
  var valid_402656788 = path.getOrDefault("siteId")
  valid_402656788 = validateParameter(valid_402656788, JString, required = true,
                                      default = nil)
  if valid_402656788 != nil:
    section.add "siteId", valid_402656788
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656789 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Security-Token", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-Signature")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Signature", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Algorithm", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Date")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Date", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Credential")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Credential", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656796: Call_DeleteSite_402656784; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing site. The site cannot be associated with any device or link.
                                                                                         ## 
  let valid = call_402656796.validator(path, query, header, formData, body, _)
  let scheme = call_402656796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656796.makeUrl(scheme.get, call_402656796.host, call_402656796.base,
                                   call_402656796.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656796, uri, valid, _)

proc call*(call_402656797: Call_DeleteSite_402656784; globalNetworkId: string;
           siteId: string): Recallable =
  ## deleteSite
  ## Deletes an existing site. The site cannot be associated with any device or link.
  ##   
                                                                                     ## globalNetworkId: string (required)
                                                                                     ##                  
                                                                                     ## : 
                                                                                     ## The 
                                                                                     ## ID 
                                                                                     ## of 
                                                                                     ## the 
                                                                                     ## global 
                                                                                     ## network.
  ##   
                                                                                                ## siteId: string (required)
                                                                                                ##         
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## ID 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## site.
  var path_402656798 = newJObject()
  add(path_402656798, "globalNetworkId", newJString(globalNetworkId))
  add(path_402656798, "siteId", newJString(siteId))
  result = call_402656797.call(path_402656798, nil, nil, nil, nil)

var deleteSite* = Call_DeleteSite_402656784(name: "deleteSite",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/sites/{siteId}",
    validator: validate_DeleteSite_402656785, base: "/",
    makeUrl: url_DeleteSite_402656786, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTransitGateway_402656816 = ref object of OpenApiRestCall_402656044
proc url_DeregisterTransitGateway_402656818(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_DeregisterTransitGateway_402656817(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   globalNetworkId: JString (required)
                                 ##                  : The ID of the global network.
  ##   
                                                                                    ## transitGatewayArn: JString (required)
                                                                                    ##                    
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## Amazon 
                                                                                    ## Resource 
                                                                                    ## Name 
                                                                                    ## (ARN) 
                                                                                    ## of 
                                                                                    ## the 
                                                                                    ## transit 
                                                                                    ## gateway.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `globalNetworkId` field"
  var valid_402656819 = path.getOrDefault("globalNetworkId")
  valid_402656819 = validateParameter(valid_402656819, JString, required = true,
                                      default = nil)
  if valid_402656819 != nil:
    section.add "globalNetworkId", valid_402656819
  var valid_402656820 = path.getOrDefault("transitGatewayArn")
  valid_402656820 = validateParameter(valid_402656820, JString, required = true,
                                      default = nil)
  if valid_402656820 != nil:
    section.add "transitGatewayArn", valid_402656820
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656821 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Security-Token", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Signature")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Signature", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Algorithm", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Date")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Date", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Credential")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Credential", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656828: Call_DeregisterTransitGateway_402656816;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
                                                                                         ## 
  let valid = call_402656828.validator(path, query, header, formData, body, _)
  let scheme = call_402656828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656828.makeUrl(scheme.get, call_402656828.host, call_402656828.base,
                                   call_402656828.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656828, uri, valid, _)

proc call*(call_402656829: Call_DeregisterTransitGateway_402656816;
           globalNetworkId: string; transitGatewayArn: string): Recallable =
  ## deregisterTransitGateway
  ## Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
  ##   
                                                                                                                                                                                                       ## globalNetworkId: string (required)
                                                                                                                                                                                                       ##                  
                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                       ## ID 
                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                       ## global 
                                                                                                                                                                                                       ## network.
  ##   
                                                                                                                                                                                                                  ## transitGatewayArn: string (required)
                                                                                                                                                                                                                  ##                    
                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                  ## Amazon 
                                                                                                                                                                                                                  ## Resource 
                                                                                                                                                                                                                  ## Name 
                                                                                                                                                                                                                  ## (ARN) 
                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                  ## transit 
                                                                                                                                                                                                                  ## gateway.
  var path_402656830 = newJObject()
  add(path_402656830, "globalNetworkId", newJString(globalNetworkId))
  add(path_402656830, "transitGatewayArn", newJString(transitGatewayArn))
  result = call_402656829.call(path_402656830, nil, nil, nil, nil)

var deregisterTransitGateway* = Call_DeregisterTransitGateway_402656816(
    name: "deregisterTransitGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/transit-gateway-registrations/{transitGatewayArn}",
    validator: validate_DeregisterTransitGateway_402656817, base: "/",
    makeUrl: url_DeregisterTransitGateway_402656818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateCustomerGateway_402656831 = ref object of OpenApiRestCall_402656044
proc url_DisassociateCustomerGateway_402656833(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_DisassociateCustomerGateway_402656832(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Disassociates a customer gateway from a device and a link.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   customerGatewayArn: JString (required)
                                 ##                     : The Amazon Resource Name (ARN) of the customer gateway. For more information, see <a 
                                 ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources 
                                 ## Defined 
                                 ## by Amazon EC2</a>.
  ##   globalNetworkId: JString (required)
                                                      ##                  : The ID of the global network.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `customerGatewayArn` field"
  var valid_402656834 = path.getOrDefault("customerGatewayArn")
  valid_402656834 = validateParameter(valid_402656834, JString, required = true,
                                      default = nil)
  if valid_402656834 != nil:
    section.add "customerGatewayArn", valid_402656834
  var valid_402656835 = path.getOrDefault("globalNetworkId")
  valid_402656835 = validateParameter(valid_402656835, JString, required = true,
                                      default = nil)
  if valid_402656835 != nil:
    section.add "globalNetworkId", valid_402656835
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656836 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "X-Amz-Security-Token", valid_402656836
  var valid_402656837 = header.getOrDefault("X-Amz-Signature")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Signature", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Algorithm", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Date")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Date", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Credential")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Credential", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656843: Call_DisassociateCustomerGateway_402656831;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates a customer gateway from a device and a link.
                                                                                         ## 
  let valid = call_402656843.validator(path, query, header, formData, body, _)
  let scheme = call_402656843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656843.makeUrl(scheme.get, call_402656843.host, call_402656843.base,
                                   call_402656843.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656843, uri, valid, _)

proc call*(call_402656844: Call_DisassociateCustomerGateway_402656831;
           customerGatewayArn: string; globalNetworkId: string): Recallable =
  ## disassociateCustomerGateway
  ## Disassociates a customer gateway from a device and a link.
  ##   
                                                               ## customerGatewayArn: string (required)
                                                               ##                     
                                                               ## : 
                                                               ## The Amazon Resource Name (ARN) of the customer gateway. For more information, see <a 
                                                               ## href="https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2.html#amazonec2-resources-for-iam-policies">Resources 
                                                               ## Defined 
                                                               ## by Amazon 
                                                               ## EC2</a>.
  ##   
                                                                          ## globalNetworkId: string (required)
                                                                          ##                  
                                                                          ## : 
                                                                          ## The 
                                                                          ## ID 
                                                                          ## of 
                                                                          ## the 
                                                                          ## global 
                                                                          ## network.
  var path_402656845 = newJObject()
  add(path_402656845, "customerGatewayArn", newJString(customerGatewayArn))
  add(path_402656845, "globalNetworkId", newJString(globalNetworkId))
  result = call_402656844.call(path_402656845, nil, nil, nil, nil)

var disassociateCustomerGateway* = Call_DisassociateCustomerGateway_402656831(
    name: "disassociateCustomerGateway", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/customer-gateway-associations/{customerGatewayArn}",
    validator: validate_DisassociateCustomerGateway_402656832, base: "/",
    makeUrl: url_DisassociateCustomerGateway_402656833,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateLink_402656846 = ref object of OpenApiRestCall_402656044
proc url_DisassociateLink_402656848(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
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

proc validate_DisassociateLink_402656847(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656849 = path.getOrDefault("globalNetworkId")
  valid_402656849 = validateParameter(valid_402656849, JString, required = true,
                                      default = nil)
  if valid_402656849 != nil:
    section.add "globalNetworkId", valid_402656849
  result.add "path", section
  ## parameters in `query` object:
  ##   deviceId: JString (required)
                                  ##           : The ID of the device.
  ##   linkId: JString (required)
                                                                      ##         : The ID of the link.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `deviceId` field"
  var valid_402656850 = query.getOrDefault("deviceId")
  valid_402656850 = validateParameter(valid_402656850, JString, required = true,
                                      default = nil)
  if valid_402656850 != nil:
    section.add "deviceId", valid_402656850
  var valid_402656851 = query.getOrDefault("linkId")
  valid_402656851 = validateParameter(valid_402656851, JString, required = true,
                                      default = nil)
  if valid_402656851 != nil:
    section.add "linkId", valid_402656851
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656852 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "X-Amz-Security-Token", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-Signature")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Signature", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Algorithm", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Date")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Date", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Credential")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Credential", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656859: Call_DisassociateLink_402656846;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
                                                                                         ## 
  let valid = call_402656859.validator(path, query, header, formData, body, _)
  let scheme = call_402656859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656859.makeUrl(scheme.get, call_402656859.host, call_402656859.base,
                                   call_402656859.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656859, uri, valid, _)

proc call*(call_402656860: Call_DisassociateLink_402656846;
           globalNetworkId: string; deviceId: string; linkId: string): Recallable =
  ## disassociateLink
  ## Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
  ##   
                                                                                                                                       ## globalNetworkId: string (required)
                                                                                                                                       ##                  
                                                                                                                                       ## : 
                                                                                                                                       ## The 
                                                                                                                                       ## ID 
                                                                                                                                       ## of 
                                                                                                                                       ## the 
                                                                                                                                       ## global 
                                                                                                                                       ## network.
  ##   
                                                                                                                                                  ## deviceId: string (required)
                                                                                                                                                  ##           
                                                                                                                                                  ## : 
                                                                                                                                                  ## The 
                                                                                                                                                  ## ID 
                                                                                                                                                  ## of 
                                                                                                                                                  ## the 
                                                                                                                                                  ## device.
  ##   
                                                                                                                                                            ## linkId: string (required)
                                                                                                                                                            ##         
                                                                                                                                                            ## : 
                                                                                                                                                            ## The 
                                                                                                                                                            ## ID 
                                                                                                                                                            ## of 
                                                                                                                                                            ## the 
                                                                                                                                                            ## link.
  var path_402656861 = newJObject()
  var query_402656862 = newJObject()
  add(path_402656861, "globalNetworkId", newJString(globalNetworkId))
  add(query_402656862, "deviceId", newJString(deviceId))
  add(query_402656862, "linkId", newJString(linkId))
  result = call_402656860.call(path_402656861, query_402656862, nil, nil, nil)

var disassociateLink* = Call_DisassociateLink_402656846(
    name: "disassociateLink", meth: HttpMethod.HttpDelete,
    host: "networkmanager.amazonaws.com", route: "/global-networks/{globalNetworkId}/link-associations#deviceId&linkId",
    validator: validate_DisassociateLink_402656847, base: "/",
    makeUrl: url_DisassociateLink_402656848,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTransitGateway_402656883 = ref object of OpenApiRestCall_402656044
proc url_RegisterTransitGateway_402656885(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
                 (kind: VariableSegment, value: "globalNetworkId"), (
        kind: ConstantSegment, value: "/transit-gateway-registrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegisterTransitGateway_402656884(path: JsonNode; query: JsonNode;
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
  var valid_402656886 = path.getOrDefault("globalNetworkId")
  valid_402656886 = validateParameter(valid_402656886, JString, required = true,
                                      default = nil)
  if valid_402656886 != nil:
    section.add "globalNetworkId", valid_402656886
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656887 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Security-Token", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Signature")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Signature", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Algorithm", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Date")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Date", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-Credential")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Credential", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656893
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

proc call*(call_402656895: Call_RegisterTransitGateway_402656883;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
                                                                                         ## 
  let valid = call_402656895.validator(path, query, header, formData, body, _)
  let scheme = call_402656895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656895.makeUrl(scheme.get, call_402656895.host, call_402656895.base,
                                   call_402656895.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656895, uri, valid, _)

proc call*(call_402656896: Call_RegisterTransitGateway_402656883;
           globalNetworkId: string; body: JsonNode): Recallable =
  ## registerTransitGateway
  ## Registers a transit gateway in your global network. The transit gateway can be in any AWS Region, but it must be owned by the same AWS account that owns the global network. You cannot register a transit gateway in more than one global network.
  ##   
                                                                                                                                                                                                                                                        ## globalNetworkId: string (required)
                                                                                                                                                                                                                                                        ##                  
                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                        ## ID 
                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                        ## global 
                                                                                                                                                                                                                                                        ## network.
  ##   
                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var path_402656897 = newJObject()
  var body_402656898 = newJObject()
  add(path_402656897, "globalNetworkId", newJString(globalNetworkId))
  if body != nil:
    body_402656898 = body
  result = call_402656896.call(path_402656897, nil, nil, nil, body_402656898)

var registerTransitGateway* = Call_RegisterTransitGateway_402656883(
    name: "registerTransitGateway", meth: HttpMethod.HttpPost,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_RegisterTransitGateway_402656884, base: "/",
    makeUrl: url_RegisterTransitGateway_402656885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTransitGatewayRegistrations_402656863 = ref object of OpenApiRestCall_402656044
proc url_GetTransitGatewayRegistrations_402656865(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "globalNetworkId" in path,
         "`globalNetworkId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/global-networks/"),
                 (kind: VariableSegment, value: "globalNetworkId"), (
        kind: ConstantSegment, value: "/transit-gateway-registrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTransitGatewayRegistrations_402656864(path: JsonNode;
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
  var valid_402656866 = path.getOrDefault("globalNetworkId")
  valid_402656866 = validateParameter(valid_402656866, JString, required = true,
                                      default = nil)
  if valid_402656866 != nil:
    section.add "globalNetworkId", valid_402656866
  result.add "path", section
  ## parameters in `query` object:
  ##   transitGatewayArns: JArray
                                  ##                     : The Amazon Resource Names (ARNs) of one or more transit gateways. The maximum is 10.
  ##   
                                                                                                                                               ## maxResults: JInt
                                                                                                                                               ##             
                                                                                                                                               ## : 
                                                                                                                                               ## The 
                                                                                                                                               ## maximum 
                                                                                                                                               ## number 
                                                                                                                                               ## of 
                                                                                                                                               ## results 
                                                                                                                                               ## to 
                                                                                                                                               ## return.
  ##   
                                                                                                                                                         ## nextToken: JString
                                                                                                                                                         ##            
                                                                                                                                                         ## : 
                                                                                                                                                         ## The 
                                                                                                                                                         ## token 
                                                                                                                                                         ## for 
                                                                                                                                                         ## the 
                                                                                                                                                         ## next 
                                                                                                                                                         ## page 
                                                                                                                                                         ## of 
                                                                                                                                                         ## results.
  ##   
                                                                                                                                                                    ## MaxResults: JString
                                                                                                                                                                    ##             
                                                                                                                                                                    ## : 
                                                                                                                                                                    ## Pagination 
                                                                                                                                                                    ## limit
  ##   
                                                                                                                                                                            ## NextToken: JString
                                                                                                                                                                            ##            
                                                                                                                                                                            ## : 
                                                                                                                                                                            ## Pagination 
                                                                                                                                                                            ## token
  section = newJObject()
  var valid_402656867 = query.getOrDefault("transitGatewayArns")
  valid_402656867 = validateParameter(valid_402656867, JArray, required = false,
                                      default = nil)
  if valid_402656867 != nil:
    section.add "transitGatewayArns", valid_402656867
  var valid_402656868 = query.getOrDefault("maxResults")
  valid_402656868 = validateParameter(valid_402656868, JInt, required = false,
                                      default = nil)
  if valid_402656868 != nil:
    section.add "maxResults", valid_402656868
  var valid_402656869 = query.getOrDefault("nextToken")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "nextToken", valid_402656869
  var valid_402656870 = query.getOrDefault("MaxResults")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "MaxResults", valid_402656870
  var valid_402656871 = query.getOrDefault("NextToken")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "NextToken", valid_402656871
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656872 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Security-Token", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Signature")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Signature", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Algorithm", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Date")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Date", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-Credential")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-Credential", valid_402656877
  var valid_402656878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656879: Call_GetTransitGatewayRegistrations_402656863;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the transit gateway registrations in a specified global network.
                                                                                         ## 
  let valid = call_402656879.validator(path, query, header, formData, body, _)
  let scheme = call_402656879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656879.makeUrl(scheme.get, call_402656879.host, call_402656879.base,
                                   call_402656879.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656879, uri, valid, _)

proc call*(call_402656880: Call_GetTransitGatewayRegistrations_402656863;
           globalNetworkId: string; transitGatewayArns: JsonNode = nil;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## getTransitGatewayRegistrations
  ## Gets information about the transit gateway registrations in a specified global network.
  ##   
                                                                                            ## transitGatewayArns: JArray
                                                                                            ##                     
                                                                                            ## : 
                                                                                            ## The 
                                                                                            ## Amazon 
                                                                                            ## Resource 
                                                                                            ## Names 
                                                                                            ## (ARNs) 
                                                                                            ## of 
                                                                                            ## one 
                                                                                            ## or 
                                                                                            ## more 
                                                                                            ## transit 
                                                                                            ## gateways. 
                                                                                            ## The 
                                                                                            ## maximum 
                                                                                            ## is 
                                                                                            ## 10.
  ##   
                                                                                                  ## globalNetworkId: string (required)
                                                                                                  ##                  
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## ID 
                                                                                                  ## of 
                                                                                                  ## the 
                                                                                                  ## global 
                                                                                                  ## network.
  ##   
                                                                                                             ## maxResults: int
                                                                                                             ##             
                                                                                                             ## : 
                                                                                                             ## The 
                                                                                                             ## maximum 
                                                                                                             ## number 
                                                                                                             ## of 
                                                                                                             ## results 
                                                                                                             ## to 
                                                                                                             ## return.
  ##   
                                                                                                                       ## nextToken: string
                                                                                                                       ##            
                                                                                                                       ## : 
                                                                                                                       ## The 
                                                                                                                       ## token 
                                                                                                                       ## for 
                                                                                                                       ## the 
                                                                                                                       ## next 
                                                                                                                       ## page 
                                                                                                                       ## of 
                                                                                                                       ## results.
  ##   
                                                                                                                                  ## MaxResults: string
                                                                                                                                  ##             
                                                                                                                                  ## : 
                                                                                                                                  ## Pagination 
                                                                                                                                  ## limit
  ##   
                                                                                                                                          ## NextToken: string
                                                                                                                                          ##            
                                                                                                                                          ## : 
                                                                                                                                          ## Pagination 
                                                                                                                                          ## token
  var path_402656881 = newJObject()
  var query_402656882 = newJObject()
  if transitGatewayArns != nil:
    query_402656882.add "transitGatewayArns", transitGatewayArns
  add(path_402656881, "globalNetworkId", newJString(globalNetworkId))
  add(query_402656882, "maxResults", newJInt(maxResults))
  add(query_402656882, "nextToken", newJString(nextToken))
  add(query_402656882, "MaxResults", newJString(MaxResults))
  add(query_402656882, "NextToken", newJString(NextToken))
  result = call_402656880.call(path_402656881, query_402656882, nil, nil, nil)

var getTransitGatewayRegistrations* = Call_GetTransitGatewayRegistrations_402656863(
    name: "getTransitGatewayRegistrations", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com",
    route: "/global-networks/{globalNetworkId}/transit-gateway-registrations",
    validator: validate_GetTransitGatewayRegistrations_402656864, base: "/",
    makeUrl: url_GetTransitGatewayRegistrations_402656865,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656913 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656915(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_402656914(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656916 = path.getOrDefault("resourceArn")
  valid_402656916 = validateParameter(valid_402656916, JString, required = true,
                                      default = nil)
  if valid_402656916 != nil:
    section.add "resourceArn", valid_402656916
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656917 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Security-Token", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Signature")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Signature", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-Algorithm", valid_402656920
  var valid_402656921 = header.getOrDefault("X-Amz-Date")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Date", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Credential")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Credential", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656923
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

proc call*(call_402656925: Call_TagResource_402656913; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Tags a specified resource.
                                                                                         ## 
  let valid = call_402656925.validator(path, query, header, formData, body, _)
  let scheme = call_402656925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656925.makeUrl(scheme.get, call_402656925.host, call_402656925.base,
                                   call_402656925.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656925, uri, valid, _)

proc call*(call_402656926: Call_TagResource_402656913; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Tags a specified resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              : The Amazon Resource Name (ARN) of the resource.
  var path_402656927 = newJObject()
  var body_402656928 = newJObject()
  if body != nil:
    body_402656928 = body
  add(path_402656927, "resourceArn", newJString(resourceArn))
  result = call_402656926.call(path_402656927, nil, nil, nil, body_402656928)

var tagResource* = Call_TagResource_402656913(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "networkmanager.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656914,
    base: "/", makeUrl: url_TagResource_402656915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656899 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656901(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListTagsForResource_402656900(path: JsonNode; query: JsonNode;
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
  var valid_402656902 = path.getOrDefault("resourceArn")
  valid_402656902 = validateParameter(valid_402656902, JString, required = true,
                                      default = nil)
  if valid_402656902 != nil:
    section.add "resourceArn", valid_402656902
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656903 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Security-Token", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Signature")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Signature", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Algorithm", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-Date")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-Date", valid_402656907
  var valid_402656908 = header.getOrDefault("X-Amz-Credential")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "X-Amz-Credential", valid_402656908
  var valid_402656909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656910: Call_ListTagsForResource_402656899;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags for a specified resource.
                                                                                         ## 
  let valid = call_402656910.validator(path, query, header, formData, body, _)
  let scheme = call_402656910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656910.makeUrl(scheme.get, call_402656910.host, call_402656910.base,
                                   call_402656910.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656910, uri, valid, _)

proc call*(call_402656911: Call_ListTagsForResource_402656899;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a specified resource.
  ##   resourceArn: string (required)
                                             ##              : The Amazon Resource Name (ARN) of the resource.
  var path_402656912 = newJObject()
  add(path_402656912, "resourceArn", newJString(resourceArn))
  result = call_402656911.call(path_402656912, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656899(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "networkmanager.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656900, base: "/",
    makeUrl: url_ListTagsForResource_402656901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656929 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656931(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_402656930(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656932 = path.getOrDefault("resourceArn")
  valid_402656932 = validateParameter(valid_402656932, JString, required = true,
                                      default = nil)
  if valid_402656932 != nil:
    section.add "resourceArn", valid_402656932
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The tag keys to remove from the specified resource.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656933 = query.getOrDefault("tagKeys")
  valid_402656933 = validateParameter(valid_402656933, JArray, required = true,
                                      default = nil)
  if valid_402656933 != nil:
    section.add "tagKeys", valid_402656933
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656934 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Security-Token", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Signature")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Signature", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Algorithm", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-Date")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Date", valid_402656938
  var valid_402656939 = header.getOrDefault("X-Amz-Credential")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "X-Amz-Credential", valid_402656939
  var valid_402656940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656941: Call_UntagResource_402656929; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags from a specified resource.
                                                                                         ## 
  let valid = call_402656941.validator(path, query, header, formData, body, _)
  let scheme = call_402656941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656941.makeUrl(scheme.get, call_402656941.host, call_402656941.base,
                                   call_402656941.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656941, uri, valid, _)

proc call*(call_402656942: Call_UntagResource_402656929; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Removes tags from a specified resource.
  ##   tagKeys: JArray (required)
                                            ##          : The tag keys to remove from the specified resource.
  ##   
                                                                                                             ## resourceArn: string (required)
                                                                                                             ##              
                                                                                                             ## : 
                                                                                                             ## The 
                                                                                                             ## Amazon 
                                                                                                             ## Resource 
                                                                                                             ## Name 
                                                                                                             ## (ARN) 
                                                                                                             ## of 
                                                                                                             ## the 
                                                                                                             ## resource.
  var path_402656943 = newJObject()
  var query_402656944 = newJObject()
  if tagKeys != nil:
    query_402656944.add "tagKeys", tagKeys
  add(path_402656943, "resourceArn", newJString(resourceArn))
  result = call_402656942.call(path_402656943, query_402656944, nil, nil, nil)

var untagResource* = Call_UntagResource_402656929(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "networkmanager.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402656930,
    base: "/", makeUrl: url_UntagResource_402656931,
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