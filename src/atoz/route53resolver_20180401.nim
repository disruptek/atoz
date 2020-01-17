
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Route 53 Resolver
## version: 2018-04-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Here's how you set up to query an Amazon Route 53 private hosted zone from your network:</p> <ol> <li> <p>Connect your network to a VPC using AWS Direct Connect or a VPN.</p> </li> <li> <p>Run the following AWS CLI command to create a Resolver endpoint:</p> <p> <code>create-resolver-endpoint --name [endpoint_name] --direction INBOUND --creator-request-id [unique_string] --security-group-ids [security_group_with_inbound_rules] --ip-addresses SubnetId=[subnet_id] SubnetId=[subnet_id_in_different_AZ]</code> </p> <p>Note the resolver endpoint ID that appears in the response. You'll use it in step 3.</p> </li> <li> <p>Get the IP addresses for the Resolver endpoints:</p> <p> <code>get-resolver-endpoint --resolver-endpoint-id [resolver_endpoint_id]</code> </p> </li> <li> <p>In your network configuration, define the IP addresses that you got in step 3 as DNS servers.</p> <p>You can now query instance names in your VPCs and the names of records in your private hosted zone.</p> </li> </ol> <p>You can also perform the following operations using the AWS CLI:</p> <ul> <li> <p> <code>list-resolver-endpoints</code>: List all endpoints. The syntax includes options for pagination and filtering.</p> </li> <li> <p> <code>update-resolver-endpoints</code>: Add IP addresses to an endpoint or remove IP addresses from an endpoint. </p> </li> </ul> <p>To delete an endpoint, use the following AWS CLI command:</p> <p> <code>delete-resolver-endpoint --resolver-endpoint-id [resolver_endpoint_id]</code> </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/route53resolver/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "route53resolver.ap-northeast-1.amazonaws.com", "ap-southeast-1": "route53resolver.ap-southeast-1.amazonaws.com", "us-west-2": "route53resolver.us-west-2.amazonaws.com", "eu-west-2": "route53resolver.eu-west-2.amazonaws.com", "ap-northeast-3": "route53resolver.ap-northeast-3.amazonaws.com", "eu-central-1": "route53resolver.eu-central-1.amazonaws.com", "us-east-2": "route53resolver.us-east-2.amazonaws.com", "us-east-1": "route53resolver.us-east-1.amazonaws.com", "cn-northwest-1": "route53resolver.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "route53resolver.ap-south-1.amazonaws.com", "eu-north-1": "route53resolver.eu-north-1.amazonaws.com", "ap-northeast-2": "route53resolver.ap-northeast-2.amazonaws.com", "us-west-1": "route53resolver.us-west-1.amazonaws.com", "us-gov-east-1": "route53resolver.us-gov-east-1.amazonaws.com", "eu-west-3": "route53resolver.eu-west-3.amazonaws.com", "cn-north-1": "route53resolver.cn-north-1.amazonaws.com.cn", "sa-east-1": "route53resolver.sa-east-1.amazonaws.com", "eu-west-1": "route53resolver.eu-west-1.amazonaws.com", "us-gov-west-1": "route53resolver.us-gov-west-1.amazonaws.com", "ap-southeast-2": "route53resolver.ap-southeast-2.amazonaws.com", "ca-central-1": "route53resolver.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "route53resolver.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "route53resolver.ap-southeast-1.amazonaws.com",
      "us-west-2": "route53resolver.us-west-2.amazonaws.com",
      "eu-west-2": "route53resolver.eu-west-2.amazonaws.com",
      "ap-northeast-3": "route53resolver.ap-northeast-3.amazonaws.com",
      "eu-central-1": "route53resolver.eu-central-1.amazonaws.com",
      "us-east-2": "route53resolver.us-east-2.amazonaws.com",
      "us-east-1": "route53resolver.us-east-1.amazonaws.com",
      "cn-northwest-1": "route53resolver.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "route53resolver.ap-south-1.amazonaws.com",
      "eu-north-1": "route53resolver.eu-north-1.amazonaws.com",
      "ap-northeast-2": "route53resolver.ap-northeast-2.amazonaws.com",
      "us-west-1": "route53resolver.us-west-1.amazonaws.com",
      "us-gov-east-1": "route53resolver.us-gov-east-1.amazonaws.com",
      "eu-west-3": "route53resolver.eu-west-3.amazonaws.com",
      "cn-north-1": "route53resolver.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "route53resolver.sa-east-1.amazonaws.com",
      "eu-west-1": "route53resolver.eu-west-1.amazonaws.com",
      "us-gov-west-1": "route53resolver.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "route53resolver.ap-southeast-2.amazonaws.com",
      "ca-central-1": "route53resolver.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "route53resolver"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateResolverEndpointIpAddress_605927 = ref object of OpenApiRestCall_605589
proc url_AssociateResolverEndpointIpAddress_605929(protocol: Scheme; host: string;
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

proc validate_AssociateResolverEndpointIpAddress_605928(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds IP addresses to an inbound or an outbound resolver endpoint. If you want to adding more than one IP address, submit one <code>AssociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To remove an IP address from an endpoint, see <a>DisassociateResolverEndpointIpAddress</a>.</p>
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
      "Route53Resolver.AssociateResolverEndpointIpAddress"))
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

proc call*(call_606085: Call_AssociateResolverEndpointIpAddress_605927;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds IP addresses to an inbound or an outbound resolver endpoint. If you want to adding more than one IP address, submit one <code>AssociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To remove an IP address from an endpoint, see <a>DisassociateResolverEndpointIpAddress</a>.</p>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AssociateResolverEndpointIpAddress_605927;
          body: JsonNode): Recallable =
  ## associateResolverEndpointIpAddress
  ## <p>Adds IP addresses to an inbound or an outbound resolver endpoint. If you want to adding more than one IP address, submit one <code>AssociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To remove an IP address from an endpoint, see <a>DisassociateResolverEndpointIpAddress</a>.</p>
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var associateResolverEndpointIpAddress* = Call_AssociateResolverEndpointIpAddress_605927(
    name: "associateResolverEndpointIpAddress", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.AssociateResolverEndpointIpAddress",
    validator: validate_AssociateResolverEndpointIpAddress_605928, base: "/",
    url: url_AssociateResolverEndpointIpAddress_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResolverRule_606196 = ref object of OpenApiRestCall_605589
proc url_AssociateResolverRule_606198(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateResolverRule_606197(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a resolver rule with a VPC. When you associate a rule with a VPC, Resolver forwards all DNS queries for the domain name that is specified in the rule and that originate in the VPC. The queries are forwarded to the IP addresses for the DNS resolvers that are specified in the rule. For more information about rules, see <a>CreateResolverRule</a>. 
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
      "Route53Resolver.AssociateResolverRule"))
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

proc call*(call_606208: Call_AssociateResolverRule_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a resolver rule with a VPC. When you associate a rule with a VPC, Resolver forwards all DNS queries for the domain name that is specified in the rule and that originate in the VPC. The queries are forwarded to the IP addresses for the DNS resolvers that are specified in the rule. For more information about rules, see <a>CreateResolverRule</a>. 
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_AssociateResolverRule_606196; body: JsonNode): Recallable =
  ## associateResolverRule
  ## Associates a resolver rule with a VPC. When you associate a rule with a VPC, Resolver forwards all DNS queries for the domain name that is specified in the rule and that originate in the VPC. The queries are forwarded to the IP addresses for the DNS resolvers that are specified in the rule. For more information about rules, see <a>CreateResolverRule</a>. 
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var associateResolverRule* = Call_AssociateResolverRule_606196(
    name: "associateResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.AssociateResolverRule",
    validator: validate_AssociateResolverRule_606197, base: "/",
    url: url_AssociateResolverRule_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolverEndpoint_606211 = ref object of OpenApiRestCall_605589
proc url_CreateResolverEndpoint_606213(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResolverEndpoint_606212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a resolver endpoint. There are two types of resolver endpoints, inbound and outbound:</p> <ul> <li> <p>An <i>inbound resolver endpoint</i> forwards DNS queries to the DNS service for a VPC from your network or another VPC.</p> </li> <li> <p>An <i>outbound resolver endpoint</i> forwards DNS queries from the DNS service for a VPC to your network or another VPC.</p> </li> </ul>
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
      "Route53Resolver.CreateResolverEndpoint"))
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

proc call*(call_606223: Call_CreateResolverEndpoint_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a resolver endpoint. There are two types of resolver endpoints, inbound and outbound:</p> <ul> <li> <p>An <i>inbound resolver endpoint</i> forwards DNS queries to the DNS service for a VPC from your network or another VPC.</p> </li> <li> <p>An <i>outbound resolver endpoint</i> forwards DNS queries from the DNS service for a VPC to your network or another VPC.</p> </li> </ul>
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_CreateResolverEndpoint_606211; body: JsonNode): Recallable =
  ## createResolverEndpoint
  ## <p>Creates a resolver endpoint. There are two types of resolver endpoints, inbound and outbound:</p> <ul> <li> <p>An <i>inbound resolver endpoint</i> forwards DNS queries to the DNS service for a VPC from your network or another VPC.</p> </li> <li> <p>An <i>outbound resolver endpoint</i> forwards DNS queries from the DNS service for a VPC to your network or another VPC.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var createResolverEndpoint* = Call_CreateResolverEndpoint_606211(
    name: "createResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.CreateResolverEndpoint",
    validator: validate_CreateResolverEndpoint_606212, base: "/",
    url: url_CreateResolverEndpoint_606213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolverRule_606226 = ref object of OpenApiRestCall_605589
proc url_CreateResolverRule_606228(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResolverRule_606227(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## For DNS queries that originate in your VPCs, specifies which resolver endpoint the queries pass through, one domain name that you want to forward to your network, and the IP addresses of the DNS resolvers in your network.
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
      "Route53Resolver.CreateResolverRule"))
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

proc call*(call_606238: Call_CreateResolverRule_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For DNS queries that originate in your VPCs, specifies which resolver endpoint the queries pass through, one domain name that you want to forward to your network, and the IP addresses of the DNS resolvers in your network.
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_CreateResolverRule_606226; body: JsonNode): Recallable =
  ## createResolverRule
  ## For DNS queries that originate in your VPCs, specifies which resolver endpoint the queries pass through, one domain name that you want to forward to your network, and the IP addresses of the DNS resolvers in your network.
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var createResolverRule* = Call_CreateResolverRule_606226(
    name: "createResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.CreateResolverRule",
    validator: validate_CreateResolverRule_606227, base: "/",
    url: url_CreateResolverRule_606228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolverEndpoint_606241 = ref object of OpenApiRestCall_605589
proc url_DeleteResolverEndpoint_606243(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResolverEndpoint_606242(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a resolver endpoint. The effect of deleting a resolver endpoint depends on whether it's an inbound or an outbound resolver endpoint:</p> <ul> <li> <p> <b>Inbound</b>: DNS queries from your network or another VPC are no longer routed to the DNS service for the specified VPC.</p> </li> <li> <p> <b>Outbound</b>: DNS queries from a VPC are no longer routed to your network or to another VPC.</p> </li> </ul>
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
      "Route53Resolver.DeleteResolverEndpoint"))
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

proc call*(call_606253: Call_DeleteResolverEndpoint_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a resolver endpoint. The effect of deleting a resolver endpoint depends on whether it's an inbound or an outbound resolver endpoint:</p> <ul> <li> <p> <b>Inbound</b>: DNS queries from your network or another VPC are no longer routed to the DNS service for the specified VPC.</p> </li> <li> <p> <b>Outbound</b>: DNS queries from a VPC are no longer routed to your network or to another VPC.</p> </li> </ul>
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_DeleteResolverEndpoint_606241; body: JsonNode): Recallable =
  ## deleteResolverEndpoint
  ## <p>Deletes a resolver endpoint. The effect of deleting a resolver endpoint depends on whether it's an inbound or an outbound resolver endpoint:</p> <ul> <li> <p> <b>Inbound</b>: DNS queries from your network or another VPC are no longer routed to the DNS service for the specified VPC.</p> </li> <li> <p> <b>Outbound</b>: DNS queries from a VPC are no longer routed to your network or to another VPC.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var deleteResolverEndpoint* = Call_DeleteResolverEndpoint_606241(
    name: "deleteResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.DeleteResolverEndpoint",
    validator: validate_DeleteResolverEndpoint_606242, base: "/",
    url: url_DeleteResolverEndpoint_606243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolverRule_606256 = ref object of OpenApiRestCall_605589
proc url_DeleteResolverRule_606258(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResolverRule_606257(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a resolver rule. Before you can delete a resolver rule, you must disassociate it from all the VPCs that you associated the resolver rule with. For more infomation, see <a>DisassociateResolverRule</a>.
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
      "Route53Resolver.DeleteResolverRule"))
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

proc call*(call_606268: Call_DeleteResolverRule_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resolver rule. Before you can delete a resolver rule, you must disassociate it from all the VPCs that you associated the resolver rule with. For more infomation, see <a>DisassociateResolverRule</a>.
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_DeleteResolverRule_606256; body: JsonNode): Recallable =
  ## deleteResolverRule
  ## Deletes a resolver rule. Before you can delete a resolver rule, you must disassociate it from all the VPCs that you associated the resolver rule with. For more infomation, see <a>DisassociateResolverRule</a>.
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var deleteResolverRule* = Call_DeleteResolverRule_606256(
    name: "deleteResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.DeleteResolverRule",
    validator: validate_DeleteResolverRule_606257, base: "/",
    url: url_DeleteResolverRule_606258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResolverEndpointIpAddress_606271 = ref object of OpenApiRestCall_605589
proc url_DisassociateResolverEndpointIpAddress_606273(protocol: Scheme;
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

proc validate_DisassociateResolverEndpointIpAddress_606272(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes IP addresses from an inbound or an outbound resolver endpoint. If you want to remove more than one IP address, submit one <code>DisassociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To add an IP address to an endpoint, see <a>AssociateResolverEndpointIpAddress</a>.</p>
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
      "Route53Resolver.DisassociateResolverEndpointIpAddress"))
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

proc call*(call_606283: Call_DisassociateResolverEndpointIpAddress_606271;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes IP addresses from an inbound or an outbound resolver endpoint. If you want to remove more than one IP address, submit one <code>DisassociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To add an IP address to an endpoint, see <a>AssociateResolverEndpointIpAddress</a>.</p>
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_DisassociateResolverEndpointIpAddress_606271;
          body: JsonNode): Recallable =
  ## disassociateResolverEndpointIpAddress
  ## <p>Removes IP addresses from an inbound or an outbound resolver endpoint. If you want to remove more than one IP address, submit one <code>DisassociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To add an IP address to an endpoint, see <a>AssociateResolverEndpointIpAddress</a>.</p>
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var disassociateResolverEndpointIpAddress* = Call_DisassociateResolverEndpointIpAddress_606271(
    name: "disassociateResolverEndpointIpAddress", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com", route: "/#X-Amz-Target=Route53Resolver.DisassociateResolverEndpointIpAddress",
    validator: validate_DisassociateResolverEndpointIpAddress_606272, base: "/",
    url: url_DisassociateResolverEndpointIpAddress_606273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResolverRule_606286 = ref object of OpenApiRestCall_605589
proc url_DisassociateResolverRule_606288(protocol: Scheme; host: string;
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

proc validate_DisassociateResolverRule_606287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the association between a specified resolver rule and a specified VPC.</p> <important> <p>If you disassociate a resolver rule from a VPC, Resolver stops forwarding DNS queries for the domain name that you specified in the resolver rule. </p> </important>
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
      "Route53Resolver.DisassociateResolverRule"))
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

proc call*(call_606298: Call_DisassociateResolverRule_606286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the association between a specified resolver rule and a specified VPC.</p> <important> <p>If you disassociate a resolver rule from a VPC, Resolver stops forwarding DNS queries for the domain name that you specified in the resolver rule. </p> </important>
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_DisassociateResolverRule_606286; body: JsonNode): Recallable =
  ## disassociateResolverRule
  ## <p>Removes the association between a specified resolver rule and a specified VPC.</p> <important> <p>If you disassociate a resolver rule from a VPC, Resolver stops forwarding DNS queries for the domain name that you specified in the resolver rule. </p> </important>
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var disassociateResolverRule* = Call_DisassociateResolverRule_606286(
    name: "disassociateResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.DisassociateResolverRule",
    validator: validate_DisassociateResolverRule_606287, base: "/",
    url: url_DisassociateResolverRule_606288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverEndpoint_606301 = ref object of OpenApiRestCall_605589
proc url_GetResolverEndpoint_606303(protocol: Scheme; host: string; base: string;
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

proc validate_GetResolverEndpoint_606302(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about a specified resolver endpoint, such as whether it's an inbound or an outbound resolver endpoint, and the current status of the endpoint.
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
      "Route53Resolver.GetResolverEndpoint"))
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

proc call*(call_606313: Call_GetResolverEndpoint_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified resolver endpoint, such as whether it's an inbound or an outbound resolver endpoint, and the current status of the endpoint.
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_GetResolverEndpoint_606301; body: JsonNode): Recallable =
  ## getResolverEndpoint
  ## Gets information about a specified resolver endpoint, such as whether it's an inbound or an outbound resolver endpoint, and the current status of the endpoint.
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var getResolverEndpoint* = Call_GetResolverEndpoint_606301(
    name: "getResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverEndpoint",
    validator: validate_GetResolverEndpoint_606302, base: "/",
    url: url_GetResolverEndpoint_606303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverRule_606316 = ref object of OpenApiRestCall_605589
proc url_GetResolverRule_606318(protocol: Scheme; host: string; base: string;
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

proc validate_GetResolverRule_606317(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets information about a specified resolver rule, such as the domain name that the rule forwards DNS queries for and the ID of the outbound resolver endpoint that the rule is associated with.
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
      "Route53Resolver.GetResolverRule"))
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

proc call*(call_606328: Call_GetResolverRule_606316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified resolver rule, such as the domain name that the rule forwards DNS queries for and the ID of the outbound resolver endpoint that the rule is associated with.
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_GetResolverRule_606316; body: JsonNode): Recallable =
  ## getResolverRule
  ## Gets information about a specified resolver rule, such as the domain name that the rule forwards DNS queries for and the ID of the outbound resolver endpoint that the rule is associated with.
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var getResolverRule* = Call_GetResolverRule_606316(name: "getResolverRule",
    meth: HttpMethod.HttpPost, host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverRule",
    validator: validate_GetResolverRule_606317, base: "/", url: url_GetResolverRule_606318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverRuleAssociation_606331 = ref object of OpenApiRestCall_605589
proc url_GetResolverRuleAssociation_606333(protocol: Scheme; host: string;
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

proc validate_GetResolverRuleAssociation_606332(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about an association between a specified resolver rule and a VPC. You associate a resolver rule and a VPC using <a>AssociateResolverRule</a>. 
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
      "Route53Resolver.GetResolverRuleAssociation"))
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

proc call*(call_606343: Call_GetResolverRuleAssociation_606331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an association between a specified resolver rule and a VPC. You associate a resolver rule and a VPC using <a>AssociateResolverRule</a>. 
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_GetResolverRuleAssociation_606331; body: JsonNode): Recallable =
  ## getResolverRuleAssociation
  ## Gets information about an association between a specified resolver rule and a VPC. You associate a resolver rule and a VPC using <a>AssociateResolverRule</a>. 
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var getResolverRuleAssociation* = Call_GetResolverRuleAssociation_606331(
    name: "getResolverRuleAssociation", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverRuleAssociation",
    validator: validate_GetResolverRuleAssociation_606332, base: "/",
    url: url_GetResolverRuleAssociation_606333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverRulePolicy_606346 = ref object of OpenApiRestCall_605589
proc url_GetResolverRulePolicy_606348(protocol: Scheme; host: string; base: string;
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

proc validate_GetResolverRulePolicy_606347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a resolver rule policy. A resolver rule policy specifies the Resolver operations and resources that you want to allow another AWS account to be able to use. 
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
      "Route53Resolver.GetResolverRulePolicy"))
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

proc call*(call_606358: Call_GetResolverRulePolicy_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a resolver rule policy. A resolver rule policy specifies the Resolver operations and resources that you want to allow another AWS account to be able to use. 
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_GetResolverRulePolicy_606346; body: JsonNode): Recallable =
  ## getResolverRulePolicy
  ## Gets information about a resolver rule policy. A resolver rule policy specifies the Resolver operations and resources that you want to allow another AWS account to be able to use. 
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var getResolverRulePolicy* = Call_GetResolverRulePolicy_606346(
    name: "getResolverRulePolicy", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverRulePolicy",
    validator: validate_GetResolverRulePolicy_606347, base: "/",
    url: url_GetResolverRulePolicy_606348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverEndpointIpAddresses_606361 = ref object of OpenApiRestCall_605589
proc url_ListResolverEndpointIpAddresses_606363(protocol: Scheme; host: string;
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

proc validate_ListResolverEndpointIpAddresses_606362(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the IP addresses for a specified resolver endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606364 = query.getOrDefault("MaxResults")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "MaxResults", valid_606364
  var valid_606365 = query.getOrDefault("NextToken")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "NextToken", valid_606365
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
  var valid_606366 = header.getOrDefault("X-Amz-Target")
  valid_606366 = validateParameter(valid_606366, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverEndpointIpAddresses"))
  if valid_606366 != nil:
    section.add "X-Amz-Target", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Signature")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Signature", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Content-Sha256", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Date")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Date", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Credential")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Credential", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Security-Token")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Security-Token", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Algorithm")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Algorithm", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-SignedHeaders", valid_606373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606375: Call_ListResolverEndpointIpAddresses_606361;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the IP addresses for a specified resolver endpoint.
  ## 
  let valid = call_606375.validator(path, query, header, formData, body)
  let scheme = call_606375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606375.url(scheme.get, call_606375.host, call_606375.base,
                         call_606375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606375, url, valid)

proc call*(call_606376: Call_ListResolverEndpointIpAddresses_606361;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResolverEndpointIpAddresses
  ## Gets the IP addresses for a specified resolver endpoint.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606377 = newJObject()
  var body_606378 = newJObject()
  add(query_606377, "MaxResults", newJString(MaxResults))
  add(query_606377, "NextToken", newJString(NextToken))
  if body != nil:
    body_606378 = body
  result = call_606376.call(nil, query_606377, nil, nil, body_606378)

var listResolverEndpointIpAddresses* = Call_ListResolverEndpointIpAddresses_606361(
    name: "listResolverEndpointIpAddresses", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverEndpointIpAddresses",
    validator: validate_ListResolverEndpointIpAddresses_606362, base: "/",
    url: url_ListResolverEndpointIpAddresses_606363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverEndpoints_606380 = ref object of OpenApiRestCall_605589
proc url_ListResolverEndpoints_606382(protocol: Scheme; host: string; base: string;
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

proc validate_ListResolverEndpoints_606381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the resolver endpoints that were created using the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606383 = query.getOrDefault("MaxResults")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "MaxResults", valid_606383
  var valid_606384 = query.getOrDefault("NextToken")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "NextToken", valid_606384
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
  var valid_606385 = header.getOrDefault("X-Amz-Target")
  valid_606385 = validateParameter(valid_606385, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverEndpoints"))
  if valid_606385 != nil:
    section.add "X-Amz-Target", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Signature")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Signature", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Content-Sha256", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Date")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Date", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Credential")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Credential", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Security-Token")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Security-Token", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Algorithm")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Algorithm", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-SignedHeaders", valid_606392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606394: Call_ListResolverEndpoints_606380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the resolver endpoints that were created using the current AWS account.
  ## 
  let valid = call_606394.validator(path, query, header, formData, body)
  let scheme = call_606394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606394.url(scheme.get, call_606394.host, call_606394.base,
                         call_606394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606394, url, valid)

proc call*(call_606395: Call_ListResolverEndpoints_606380; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResolverEndpoints
  ## Lists all the resolver endpoints that were created using the current AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606396 = newJObject()
  var body_606397 = newJObject()
  add(query_606396, "MaxResults", newJString(MaxResults))
  add(query_606396, "NextToken", newJString(NextToken))
  if body != nil:
    body_606397 = body
  result = call_606395.call(nil, query_606396, nil, nil, body_606397)

var listResolverEndpoints* = Call_ListResolverEndpoints_606380(
    name: "listResolverEndpoints", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverEndpoints",
    validator: validate_ListResolverEndpoints_606381, base: "/",
    url: url_ListResolverEndpoints_606382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverRuleAssociations_606398 = ref object of OpenApiRestCall_605589
proc url_ListResolverRuleAssociations_606400(protocol: Scheme; host: string;
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

proc validate_ListResolverRuleAssociations_606399(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the associations that were created between resolver rules and VPCs using the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606401 = query.getOrDefault("MaxResults")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "MaxResults", valid_606401
  var valid_606402 = query.getOrDefault("NextToken")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "NextToken", valid_606402
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
  var valid_606403 = header.getOrDefault("X-Amz-Target")
  valid_606403 = validateParameter(valid_606403, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverRuleAssociations"))
  if valid_606403 != nil:
    section.add "X-Amz-Target", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Signature")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Signature", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Content-Sha256", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Date")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Date", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Credential")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Credential", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Security-Token")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Security-Token", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Algorithm")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Algorithm", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-SignedHeaders", valid_606410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606412: Call_ListResolverRuleAssociations_606398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the associations that were created between resolver rules and VPCs using the current AWS account.
  ## 
  let valid = call_606412.validator(path, query, header, formData, body)
  let scheme = call_606412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606412.url(scheme.get, call_606412.host, call_606412.base,
                         call_606412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606412, url, valid)

proc call*(call_606413: Call_ListResolverRuleAssociations_606398; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResolverRuleAssociations
  ## Lists the associations that were created between resolver rules and VPCs using the current AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606414 = newJObject()
  var body_606415 = newJObject()
  add(query_606414, "MaxResults", newJString(MaxResults))
  add(query_606414, "NextToken", newJString(NextToken))
  if body != nil:
    body_606415 = body
  result = call_606413.call(nil, query_606414, nil, nil, body_606415)

var listResolverRuleAssociations* = Call_ListResolverRuleAssociations_606398(
    name: "listResolverRuleAssociations", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverRuleAssociations",
    validator: validate_ListResolverRuleAssociations_606399, base: "/",
    url: url_ListResolverRuleAssociations_606400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverRules_606416 = ref object of OpenApiRestCall_605589
proc url_ListResolverRules_606418(protocol: Scheme; host: string; base: string;
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

proc validate_ListResolverRules_606417(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the resolver rules that were created using the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606419 = query.getOrDefault("MaxResults")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "MaxResults", valid_606419
  var valid_606420 = query.getOrDefault("NextToken")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "NextToken", valid_606420
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
  var valid_606421 = header.getOrDefault("X-Amz-Target")
  valid_606421 = validateParameter(valid_606421, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverRules"))
  if valid_606421 != nil:
    section.add "X-Amz-Target", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Signature")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Signature", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Content-Sha256", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Date")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Date", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Credential")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Credential", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Security-Token")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Security-Token", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Algorithm")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Algorithm", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-SignedHeaders", valid_606428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606430: Call_ListResolverRules_606416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resolver rules that were created using the current AWS account.
  ## 
  let valid = call_606430.validator(path, query, header, formData, body)
  let scheme = call_606430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606430.url(scheme.get, call_606430.host, call_606430.base,
                         call_606430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606430, url, valid)

proc call*(call_606431: Call_ListResolverRules_606416; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResolverRules
  ## Lists the resolver rules that were created using the current AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606432 = newJObject()
  var body_606433 = newJObject()
  add(query_606432, "MaxResults", newJString(MaxResults))
  add(query_606432, "NextToken", newJString(NextToken))
  if body != nil:
    body_606433 = body
  result = call_606431.call(nil, query_606432, nil, nil, body_606433)

var listResolverRules* = Call_ListResolverRules_606416(name: "listResolverRules",
    meth: HttpMethod.HttpPost, host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverRules",
    validator: validate_ListResolverRules_606417, base: "/",
    url: url_ListResolverRules_606418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606434 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606436(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606435(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags that you associated with the specified resource.
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
  var valid_606437 = header.getOrDefault("X-Amz-Target")
  valid_606437 = validateParameter(valid_606437, JString, required = true, default = newJString(
      "Route53Resolver.ListTagsForResource"))
  if valid_606437 != nil:
    section.add "X-Amz-Target", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Signature")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Signature", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Content-Sha256", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Date")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Date", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Credential")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Credential", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Security-Token")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Security-Token", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Algorithm")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Algorithm", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-SignedHeaders", valid_606444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606446: Call_ListTagsForResource_606434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags that you associated with the specified resource.
  ## 
  let valid = call_606446.validator(path, query, header, formData, body)
  let scheme = call_606446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606446.url(scheme.get, call_606446.host, call_606446.base,
                         call_606446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606446, url, valid)

proc call*(call_606447: Call_ListTagsForResource_606434; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags that you associated with the specified resource.
  ##   body: JObject (required)
  var body_606448 = newJObject()
  if body != nil:
    body_606448 = body
  result = call_606447.call(nil, nil, nil, nil, body_606448)

var listTagsForResource* = Call_ListTagsForResource_606434(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListTagsForResource",
    validator: validate_ListTagsForResource_606435, base: "/",
    url: url_ListTagsForResource_606436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResolverRulePolicy_606449 = ref object of OpenApiRestCall_605589
proc url_PutResolverRulePolicy_606451(protocol: Scheme; host: string; base: string;
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

proc validate_PutResolverRulePolicy_606450(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Specifies the Resolver operations and resources that you want to allow another AWS account to be able to use.
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
  var valid_606452 = header.getOrDefault("X-Amz-Target")
  valid_606452 = validateParameter(valid_606452, JString, required = true, default = newJString(
      "Route53Resolver.PutResolverRulePolicy"))
  if valid_606452 != nil:
    section.add "X-Amz-Target", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Signature")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Signature", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Content-Sha256", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Date")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Date", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Credential")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Credential", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Security-Token")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Security-Token", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Algorithm")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Algorithm", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-SignedHeaders", valid_606459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606461: Call_PutResolverRulePolicy_606449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies the Resolver operations and resources that you want to allow another AWS account to be able to use.
  ## 
  let valid = call_606461.validator(path, query, header, formData, body)
  let scheme = call_606461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606461.url(scheme.get, call_606461.host, call_606461.base,
                         call_606461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606461, url, valid)

proc call*(call_606462: Call_PutResolverRulePolicy_606449; body: JsonNode): Recallable =
  ## putResolverRulePolicy
  ## Specifies the Resolver operations and resources that you want to allow another AWS account to be able to use.
  ##   body: JObject (required)
  var body_606463 = newJObject()
  if body != nil:
    body_606463 = body
  result = call_606462.call(nil, nil, nil, nil, body_606463)

var putResolverRulePolicy* = Call_PutResolverRulePolicy_606449(
    name: "putResolverRulePolicy", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.PutResolverRulePolicy",
    validator: validate_PutResolverRulePolicy_606450, base: "/",
    url: url_PutResolverRulePolicy_606451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606464 = ref object of OpenApiRestCall_605589
proc url_TagResource_606466(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606465(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more tags to a specified resource.
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
  var valid_606467 = header.getOrDefault("X-Amz-Target")
  valid_606467 = validateParameter(valid_606467, JString, required = true, default = newJString(
      "Route53Resolver.TagResource"))
  if valid_606467 != nil:
    section.add "X-Amz-Target", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Signature")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Signature", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Content-Sha256", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Date")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Date", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Credential")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Credential", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Security-Token")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Security-Token", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Algorithm")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Algorithm", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-SignedHeaders", valid_606474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606476: Call_TagResource_606464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a specified resource.
  ## 
  let valid = call_606476.validator(path, query, header, formData, body)
  let scheme = call_606476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606476.url(scheme.get, call_606476.host, call_606476.base,
                         call_606476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606476, url, valid)

proc call*(call_606477: Call_TagResource_606464; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a specified resource.
  ##   body: JObject (required)
  var body_606478 = newJObject()
  if body != nil:
    body_606478 = body
  result = call_606477.call(nil, nil, nil, nil, body_606478)

var tagResource* = Call_TagResource_606464(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "route53resolver.amazonaws.com", route: "/#X-Amz-Target=Route53Resolver.TagResource",
                                        validator: validate_TagResource_606465,
                                        base: "/", url: url_TagResource_606466,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606479 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606481(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606480(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags from a specified resource.
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
  var valid_606482 = header.getOrDefault("X-Amz-Target")
  valid_606482 = validateParameter(valid_606482, JString, required = true, default = newJString(
      "Route53Resolver.UntagResource"))
  if valid_606482 != nil:
    section.add "X-Amz-Target", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Signature")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Signature", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Content-Sha256", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Date")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Date", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Credential")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Credential", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Security-Token")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Security-Token", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Algorithm")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Algorithm", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-SignedHeaders", valid_606489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606491: Call_UntagResource_606479; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a specified resource.
  ## 
  let valid = call_606491.validator(path, query, header, formData, body)
  let scheme = call_606491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606491.url(scheme.get, call_606491.host, call_606491.base,
                         call_606491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606491, url, valid)

proc call*(call_606492: Call_UntagResource_606479; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a specified resource.
  ##   body: JObject (required)
  var body_606493 = newJObject()
  if body != nil:
    body_606493 = body
  result = call_606492.call(nil, nil, nil, nil, body_606493)

var untagResource* = Call_UntagResource_606479(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.UntagResource",
    validator: validate_UntagResource_606480, base: "/", url: url_UntagResource_606481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolverEndpoint_606494 = ref object of OpenApiRestCall_605589
proc url_UpdateResolverEndpoint_606496(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResolverEndpoint_606495(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the name of an inbound or an outbound resolver endpoint. 
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
  var valid_606497 = header.getOrDefault("X-Amz-Target")
  valid_606497 = validateParameter(valid_606497, JString, required = true, default = newJString(
      "Route53Resolver.UpdateResolverEndpoint"))
  if valid_606497 != nil:
    section.add "X-Amz-Target", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Signature")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Signature", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Content-Sha256", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Date")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Date", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Credential")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Credential", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Security-Token")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Security-Token", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Algorithm")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Algorithm", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-SignedHeaders", valid_606504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606506: Call_UpdateResolverEndpoint_606494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name of an inbound or an outbound resolver endpoint. 
  ## 
  let valid = call_606506.validator(path, query, header, formData, body)
  let scheme = call_606506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606506.url(scheme.get, call_606506.host, call_606506.base,
                         call_606506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606506, url, valid)

proc call*(call_606507: Call_UpdateResolverEndpoint_606494; body: JsonNode): Recallable =
  ## updateResolverEndpoint
  ## Updates the name of an inbound or an outbound resolver endpoint. 
  ##   body: JObject (required)
  var body_606508 = newJObject()
  if body != nil:
    body_606508 = body
  result = call_606507.call(nil, nil, nil, nil, body_606508)

var updateResolverEndpoint* = Call_UpdateResolverEndpoint_606494(
    name: "updateResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.UpdateResolverEndpoint",
    validator: validate_UpdateResolverEndpoint_606495, base: "/",
    url: url_UpdateResolverEndpoint_606496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolverRule_606509 = ref object of OpenApiRestCall_605589
proc url_UpdateResolverRule_606511(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResolverRule_606510(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates settings for a specified resolver rule. <code>ResolverRuleId</code> is required, and all other parameters are optional. If you don't specify a parameter, it retains its current value.
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
  var valid_606512 = header.getOrDefault("X-Amz-Target")
  valid_606512 = validateParameter(valid_606512, JString, required = true, default = newJString(
      "Route53Resolver.UpdateResolverRule"))
  if valid_606512 != nil:
    section.add "X-Amz-Target", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Signature")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Signature", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Content-Sha256", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Date")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Date", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Credential")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Credential", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Security-Token")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Security-Token", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Algorithm")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Algorithm", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-SignedHeaders", valid_606519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606521: Call_UpdateResolverRule_606509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates settings for a specified resolver rule. <code>ResolverRuleId</code> is required, and all other parameters are optional. If you don't specify a parameter, it retains its current value.
  ## 
  let valid = call_606521.validator(path, query, header, formData, body)
  let scheme = call_606521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606521.url(scheme.get, call_606521.host, call_606521.base,
                         call_606521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606521, url, valid)

proc call*(call_606522: Call_UpdateResolverRule_606509; body: JsonNode): Recallable =
  ## updateResolverRule
  ## Updates settings for a specified resolver rule. <code>ResolverRuleId</code> is required, and all other parameters are optional. If you don't specify a parameter, it retains its current value.
  ##   body: JObject (required)
  var body_606523 = newJObject()
  if body != nil:
    body_606523 = body
  result = call_606522.call(nil, nil, nil, nil, body_606523)

var updateResolverRule* = Call_UpdateResolverRule_606509(
    name: "updateResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.UpdateResolverRule",
    validator: validate_UpdateResolverRule_606510, base: "/",
    url: url_UpdateResolverRule_606511, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
