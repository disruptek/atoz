
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
  Call_AssociateResolverEndpointIpAddress_612996 = ref object of OpenApiRestCall_612658
proc url_AssociateResolverEndpointIpAddress_612998(protocol: Scheme; host: string;
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

proc validate_AssociateResolverEndpointIpAddress_612997(path: JsonNode;
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
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "Route53Resolver.AssociateResolverEndpointIpAddress"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_AssociateResolverEndpointIpAddress_612996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds IP addresses to an inbound or an outbound resolver endpoint. If you want to adding more than one IP address, submit one <code>AssociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To remove an IP address from an endpoint, see <a>DisassociateResolverEndpointIpAddress</a>.</p>
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_AssociateResolverEndpointIpAddress_612996;
          body: JsonNode): Recallable =
  ## associateResolverEndpointIpAddress
  ## <p>Adds IP addresses to an inbound or an outbound resolver endpoint. If you want to adding more than one IP address, submit one <code>AssociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To remove an IP address from an endpoint, see <a>DisassociateResolverEndpointIpAddress</a>.</p>
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var associateResolverEndpointIpAddress* = Call_AssociateResolverEndpointIpAddress_612996(
    name: "associateResolverEndpointIpAddress", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.AssociateResolverEndpointIpAddress",
    validator: validate_AssociateResolverEndpointIpAddress_612997, base: "/",
    url: url_AssociateResolverEndpointIpAddress_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResolverRule_613265 = ref object of OpenApiRestCall_612658
proc url_AssociateResolverRule_613267(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateResolverRule_613266(path: JsonNode; query: JsonNode;
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
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "Route53Resolver.AssociateResolverRule"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_AssociateResolverRule_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a resolver rule with a VPC. When you associate a rule with a VPC, Resolver forwards all DNS queries for the domain name that is specified in the rule and that originate in the VPC. The queries are forwarded to the IP addresses for the DNS resolvers that are specified in the rule. For more information about rules, see <a>CreateResolverRule</a>. 
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_AssociateResolverRule_613265; body: JsonNode): Recallable =
  ## associateResolverRule
  ## Associates a resolver rule with a VPC. When you associate a rule with a VPC, Resolver forwards all DNS queries for the domain name that is specified in the rule and that originate in the VPC. The queries are forwarded to the IP addresses for the DNS resolvers that are specified in the rule. For more information about rules, see <a>CreateResolverRule</a>. 
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var associateResolverRule* = Call_AssociateResolverRule_613265(
    name: "associateResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.AssociateResolverRule",
    validator: validate_AssociateResolverRule_613266, base: "/",
    url: url_AssociateResolverRule_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolverEndpoint_613280 = ref object of OpenApiRestCall_612658
proc url_CreateResolverEndpoint_613282(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResolverEndpoint_613281(path: JsonNode; query: JsonNode;
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
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "Route53Resolver.CreateResolverEndpoint"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_CreateResolverEndpoint_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a resolver endpoint. There are two types of resolver endpoints, inbound and outbound:</p> <ul> <li> <p>An <i>inbound resolver endpoint</i> forwards DNS queries to the DNS service for a VPC from your network or another VPC.</p> </li> <li> <p>An <i>outbound resolver endpoint</i> forwards DNS queries from the DNS service for a VPC to your network or another VPC.</p> </li> </ul>
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_CreateResolverEndpoint_613280; body: JsonNode): Recallable =
  ## createResolverEndpoint
  ## <p>Creates a resolver endpoint. There are two types of resolver endpoints, inbound and outbound:</p> <ul> <li> <p>An <i>inbound resolver endpoint</i> forwards DNS queries to the DNS service for a VPC from your network or another VPC.</p> </li> <li> <p>An <i>outbound resolver endpoint</i> forwards DNS queries from the DNS service for a VPC to your network or another VPC.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var createResolverEndpoint* = Call_CreateResolverEndpoint_613280(
    name: "createResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.CreateResolverEndpoint",
    validator: validate_CreateResolverEndpoint_613281, base: "/",
    url: url_CreateResolverEndpoint_613282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolverRule_613295 = ref object of OpenApiRestCall_612658
proc url_CreateResolverRule_613297(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResolverRule_613296(path: JsonNode; query: JsonNode;
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
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "Route53Resolver.CreateResolverRule"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_CreateResolverRule_613295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For DNS queries that originate in your VPCs, specifies which resolver endpoint the queries pass through, one domain name that you want to forward to your network, and the IP addresses of the DNS resolvers in your network.
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CreateResolverRule_613295; body: JsonNode): Recallable =
  ## createResolverRule
  ## For DNS queries that originate in your VPCs, specifies which resolver endpoint the queries pass through, one domain name that you want to forward to your network, and the IP addresses of the DNS resolvers in your network.
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var createResolverRule* = Call_CreateResolverRule_613295(
    name: "createResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.CreateResolverRule",
    validator: validate_CreateResolverRule_613296, base: "/",
    url: url_CreateResolverRule_613297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolverEndpoint_613310 = ref object of OpenApiRestCall_612658
proc url_DeleteResolverEndpoint_613312(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResolverEndpoint_613311(path: JsonNode; query: JsonNode;
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
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "Route53Resolver.DeleteResolverEndpoint"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_DeleteResolverEndpoint_613310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a resolver endpoint. The effect of deleting a resolver endpoint depends on whether it's an inbound or an outbound resolver endpoint:</p> <ul> <li> <p> <b>Inbound</b>: DNS queries from your network or another VPC are no longer routed to the DNS service for the specified VPC.</p> </li> <li> <p> <b>Outbound</b>: DNS queries from a VPC are no longer routed to your network or to another VPC.</p> </li> </ul>
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_DeleteResolverEndpoint_613310; body: JsonNode): Recallable =
  ## deleteResolverEndpoint
  ## <p>Deletes a resolver endpoint. The effect of deleting a resolver endpoint depends on whether it's an inbound or an outbound resolver endpoint:</p> <ul> <li> <p> <b>Inbound</b>: DNS queries from your network or another VPC are no longer routed to the DNS service for the specified VPC.</p> </li> <li> <p> <b>Outbound</b>: DNS queries from a VPC are no longer routed to your network or to another VPC.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var deleteResolverEndpoint* = Call_DeleteResolverEndpoint_613310(
    name: "deleteResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.DeleteResolverEndpoint",
    validator: validate_DeleteResolverEndpoint_613311, base: "/",
    url: url_DeleteResolverEndpoint_613312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolverRule_613325 = ref object of OpenApiRestCall_612658
proc url_DeleteResolverRule_613327(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResolverRule_613326(path: JsonNode; query: JsonNode;
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
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "Route53Resolver.DeleteResolverRule"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_DeleteResolverRule_613325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resolver rule. Before you can delete a resolver rule, you must disassociate it from all the VPCs that you associated the resolver rule with. For more infomation, see <a>DisassociateResolverRule</a>.
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_DeleteResolverRule_613325; body: JsonNode): Recallable =
  ## deleteResolverRule
  ## Deletes a resolver rule. Before you can delete a resolver rule, you must disassociate it from all the VPCs that you associated the resolver rule with. For more infomation, see <a>DisassociateResolverRule</a>.
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var deleteResolverRule* = Call_DeleteResolverRule_613325(
    name: "deleteResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.DeleteResolverRule",
    validator: validate_DeleteResolverRule_613326, base: "/",
    url: url_DeleteResolverRule_613327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResolverEndpointIpAddress_613340 = ref object of OpenApiRestCall_612658
proc url_DisassociateResolverEndpointIpAddress_613342(protocol: Scheme;
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

proc validate_DisassociateResolverEndpointIpAddress_613341(path: JsonNode;
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
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "Route53Resolver.DisassociateResolverEndpointIpAddress"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_DisassociateResolverEndpointIpAddress_613340;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes IP addresses from an inbound or an outbound resolver endpoint. If you want to remove more than one IP address, submit one <code>DisassociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To add an IP address to an endpoint, see <a>AssociateResolverEndpointIpAddress</a>.</p>
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_DisassociateResolverEndpointIpAddress_613340;
          body: JsonNode): Recallable =
  ## disassociateResolverEndpointIpAddress
  ## <p>Removes IP addresses from an inbound or an outbound resolver endpoint. If you want to remove more than one IP address, submit one <code>DisassociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To add an IP address to an endpoint, see <a>AssociateResolverEndpointIpAddress</a>.</p>
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var disassociateResolverEndpointIpAddress* = Call_DisassociateResolverEndpointIpAddress_613340(
    name: "disassociateResolverEndpointIpAddress", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com", route: "/#X-Amz-Target=Route53Resolver.DisassociateResolverEndpointIpAddress",
    validator: validate_DisassociateResolverEndpointIpAddress_613341, base: "/",
    url: url_DisassociateResolverEndpointIpAddress_613342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResolverRule_613355 = ref object of OpenApiRestCall_612658
proc url_DisassociateResolverRule_613357(protocol: Scheme; host: string;
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

proc validate_DisassociateResolverRule_613356(path: JsonNode; query: JsonNode;
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
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true, default = newJString(
      "Route53Resolver.DisassociateResolverRule"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_DisassociateResolverRule_613355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the association between a specified resolver rule and a specified VPC.</p> <important> <p>If you disassociate a resolver rule from a VPC, Resolver stops forwarding DNS queries for the domain name that you specified in the resolver rule. </p> </important>
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_DisassociateResolverRule_613355; body: JsonNode): Recallable =
  ## disassociateResolverRule
  ## <p>Removes the association between a specified resolver rule and a specified VPC.</p> <important> <p>If you disassociate a resolver rule from a VPC, Resolver stops forwarding DNS queries for the domain name that you specified in the resolver rule. </p> </important>
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var disassociateResolverRule* = Call_DisassociateResolverRule_613355(
    name: "disassociateResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.DisassociateResolverRule",
    validator: validate_DisassociateResolverRule_613356, base: "/",
    url: url_DisassociateResolverRule_613357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverEndpoint_613370 = ref object of OpenApiRestCall_612658
proc url_GetResolverEndpoint_613372(protocol: Scheme; host: string; base: string;
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

proc validate_GetResolverEndpoint_613371(path: JsonNode; query: JsonNode;
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
  var valid_613373 = header.getOrDefault("X-Amz-Target")
  valid_613373 = validateParameter(valid_613373, JString, required = true, default = newJString(
      "Route53Resolver.GetResolverEndpoint"))
  if valid_613373 != nil:
    section.add "X-Amz-Target", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_GetResolverEndpoint_613370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified resolver endpoint, such as whether it's an inbound or an outbound resolver endpoint, and the current status of the endpoint.
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_GetResolverEndpoint_613370; body: JsonNode): Recallable =
  ## getResolverEndpoint
  ## Gets information about a specified resolver endpoint, such as whether it's an inbound or an outbound resolver endpoint, and the current status of the endpoint.
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var getResolverEndpoint* = Call_GetResolverEndpoint_613370(
    name: "getResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverEndpoint",
    validator: validate_GetResolverEndpoint_613371, base: "/",
    url: url_GetResolverEndpoint_613372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverRule_613385 = ref object of OpenApiRestCall_612658
proc url_GetResolverRule_613387(protocol: Scheme; host: string; base: string;
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

proc validate_GetResolverRule_613386(path: JsonNode; query: JsonNode;
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
  var valid_613388 = header.getOrDefault("X-Amz-Target")
  valid_613388 = validateParameter(valid_613388, JString, required = true, default = newJString(
      "Route53Resolver.GetResolverRule"))
  if valid_613388 != nil:
    section.add "X-Amz-Target", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Signature")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Signature", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Content-Sha256", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Date")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Date", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Credential")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Credential", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Security-Token")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Security-Token", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Algorithm")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Algorithm", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-SignedHeaders", valid_613395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_GetResolverRule_613385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified resolver rule, such as the domain name that the rule forwards DNS queries for and the ID of the outbound resolver endpoint that the rule is associated with.
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_GetResolverRule_613385; body: JsonNode): Recallable =
  ## getResolverRule
  ## Gets information about a specified resolver rule, such as the domain name that the rule forwards DNS queries for and the ID of the outbound resolver endpoint that the rule is associated with.
  ##   body: JObject (required)
  var body_613399 = newJObject()
  if body != nil:
    body_613399 = body
  result = call_613398.call(nil, nil, nil, nil, body_613399)

var getResolverRule* = Call_GetResolverRule_613385(name: "getResolverRule",
    meth: HttpMethod.HttpPost, host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverRule",
    validator: validate_GetResolverRule_613386, base: "/", url: url_GetResolverRule_613387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverRuleAssociation_613400 = ref object of OpenApiRestCall_612658
proc url_GetResolverRuleAssociation_613402(protocol: Scheme; host: string;
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

proc validate_GetResolverRuleAssociation_613401(path: JsonNode; query: JsonNode;
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
  var valid_613403 = header.getOrDefault("X-Amz-Target")
  valid_613403 = validateParameter(valid_613403, JString, required = true, default = newJString(
      "Route53Resolver.GetResolverRuleAssociation"))
  if valid_613403 != nil:
    section.add "X-Amz-Target", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_GetResolverRuleAssociation_613400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an association between a specified resolver rule and a VPC. You associate a resolver rule and a VPC using <a>AssociateResolverRule</a>. 
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_GetResolverRuleAssociation_613400; body: JsonNode): Recallable =
  ## getResolverRuleAssociation
  ## Gets information about an association between a specified resolver rule and a VPC. You associate a resolver rule and a VPC using <a>AssociateResolverRule</a>. 
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var getResolverRuleAssociation* = Call_GetResolverRuleAssociation_613400(
    name: "getResolverRuleAssociation", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverRuleAssociation",
    validator: validate_GetResolverRuleAssociation_613401, base: "/",
    url: url_GetResolverRuleAssociation_613402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverRulePolicy_613415 = ref object of OpenApiRestCall_612658
proc url_GetResolverRulePolicy_613417(protocol: Scheme; host: string; base: string;
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

proc validate_GetResolverRulePolicy_613416(path: JsonNode; query: JsonNode;
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
  var valid_613418 = header.getOrDefault("X-Amz-Target")
  valid_613418 = validateParameter(valid_613418, JString, required = true, default = newJString(
      "Route53Resolver.GetResolverRulePolicy"))
  if valid_613418 != nil:
    section.add "X-Amz-Target", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_GetResolverRulePolicy_613415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a resolver rule policy. A resolver rule policy specifies the Resolver operations and resources that you want to allow another AWS account to be able to use. 
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_GetResolverRulePolicy_613415; body: JsonNode): Recallable =
  ## getResolverRulePolicy
  ## Gets information about a resolver rule policy. A resolver rule policy specifies the Resolver operations and resources that you want to allow another AWS account to be able to use. 
  ##   body: JObject (required)
  var body_613429 = newJObject()
  if body != nil:
    body_613429 = body
  result = call_613428.call(nil, nil, nil, nil, body_613429)

var getResolverRulePolicy* = Call_GetResolverRulePolicy_613415(
    name: "getResolverRulePolicy", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverRulePolicy",
    validator: validate_GetResolverRulePolicy_613416, base: "/",
    url: url_GetResolverRulePolicy_613417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverEndpointIpAddresses_613430 = ref object of OpenApiRestCall_612658
proc url_ListResolverEndpointIpAddresses_613432(protocol: Scheme; host: string;
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

proc validate_ListResolverEndpointIpAddresses_613431(path: JsonNode;
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
  var valid_613433 = query.getOrDefault("MaxResults")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "MaxResults", valid_613433
  var valid_613434 = query.getOrDefault("NextToken")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "NextToken", valid_613434
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
  var valid_613435 = header.getOrDefault("X-Amz-Target")
  valid_613435 = validateParameter(valid_613435, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverEndpointIpAddresses"))
  if valid_613435 != nil:
    section.add "X-Amz-Target", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Signature")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Signature", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Content-Sha256", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Date")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Date", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Credential")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Credential", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-Security-Token")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Security-Token", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-Algorithm")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-Algorithm", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-SignedHeaders", valid_613442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613444: Call_ListResolverEndpointIpAddresses_613430;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the IP addresses for a specified resolver endpoint.
  ## 
  let valid = call_613444.validator(path, query, header, formData, body)
  let scheme = call_613444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613444.url(scheme.get, call_613444.host, call_613444.base,
                         call_613444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613444, url, valid)

proc call*(call_613445: Call_ListResolverEndpointIpAddresses_613430;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResolverEndpointIpAddresses
  ## Gets the IP addresses for a specified resolver endpoint.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613446 = newJObject()
  var body_613447 = newJObject()
  add(query_613446, "MaxResults", newJString(MaxResults))
  add(query_613446, "NextToken", newJString(NextToken))
  if body != nil:
    body_613447 = body
  result = call_613445.call(nil, query_613446, nil, nil, body_613447)

var listResolverEndpointIpAddresses* = Call_ListResolverEndpointIpAddresses_613430(
    name: "listResolverEndpointIpAddresses", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverEndpointIpAddresses",
    validator: validate_ListResolverEndpointIpAddresses_613431, base: "/",
    url: url_ListResolverEndpointIpAddresses_613432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverEndpoints_613449 = ref object of OpenApiRestCall_612658
proc url_ListResolverEndpoints_613451(protocol: Scheme; host: string; base: string;
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

proc validate_ListResolverEndpoints_613450(path: JsonNode; query: JsonNode;
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
  var valid_613452 = query.getOrDefault("MaxResults")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "MaxResults", valid_613452
  var valid_613453 = query.getOrDefault("NextToken")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "NextToken", valid_613453
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
  var valid_613454 = header.getOrDefault("X-Amz-Target")
  valid_613454 = validateParameter(valid_613454, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverEndpoints"))
  if valid_613454 != nil:
    section.add "X-Amz-Target", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Signature")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Signature", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-Content-Sha256", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-Date")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Date", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Credential")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Credential", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Security-Token")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Security-Token", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Algorithm")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Algorithm", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-SignedHeaders", valid_613461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613463: Call_ListResolverEndpoints_613449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the resolver endpoints that were created using the current AWS account.
  ## 
  let valid = call_613463.validator(path, query, header, formData, body)
  let scheme = call_613463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613463.url(scheme.get, call_613463.host, call_613463.base,
                         call_613463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613463, url, valid)

proc call*(call_613464: Call_ListResolverEndpoints_613449; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResolverEndpoints
  ## Lists all the resolver endpoints that were created using the current AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613465 = newJObject()
  var body_613466 = newJObject()
  add(query_613465, "MaxResults", newJString(MaxResults))
  add(query_613465, "NextToken", newJString(NextToken))
  if body != nil:
    body_613466 = body
  result = call_613464.call(nil, query_613465, nil, nil, body_613466)

var listResolverEndpoints* = Call_ListResolverEndpoints_613449(
    name: "listResolverEndpoints", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverEndpoints",
    validator: validate_ListResolverEndpoints_613450, base: "/",
    url: url_ListResolverEndpoints_613451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverRuleAssociations_613467 = ref object of OpenApiRestCall_612658
proc url_ListResolverRuleAssociations_613469(protocol: Scheme; host: string;
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

proc validate_ListResolverRuleAssociations_613468(path: JsonNode; query: JsonNode;
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
  var valid_613470 = query.getOrDefault("MaxResults")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "MaxResults", valid_613470
  var valid_613471 = query.getOrDefault("NextToken")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "NextToken", valid_613471
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
  var valid_613472 = header.getOrDefault("X-Amz-Target")
  valid_613472 = validateParameter(valid_613472, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverRuleAssociations"))
  if valid_613472 != nil:
    section.add "X-Amz-Target", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Signature")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Signature", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Content-Sha256", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Date")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Date", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Credential")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Credential", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Security-Token")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Security-Token", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Algorithm")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Algorithm", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-SignedHeaders", valid_613479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613481: Call_ListResolverRuleAssociations_613467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the associations that were created between resolver rules and VPCs using the current AWS account.
  ## 
  let valid = call_613481.validator(path, query, header, formData, body)
  let scheme = call_613481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613481.url(scheme.get, call_613481.host, call_613481.base,
                         call_613481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613481, url, valid)

proc call*(call_613482: Call_ListResolverRuleAssociations_613467; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResolverRuleAssociations
  ## Lists the associations that were created between resolver rules and VPCs using the current AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613483 = newJObject()
  var body_613484 = newJObject()
  add(query_613483, "MaxResults", newJString(MaxResults))
  add(query_613483, "NextToken", newJString(NextToken))
  if body != nil:
    body_613484 = body
  result = call_613482.call(nil, query_613483, nil, nil, body_613484)

var listResolverRuleAssociations* = Call_ListResolverRuleAssociations_613467(
    name: "listResolverRuleAssociations", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverRuleAssociations",
    validator: validate_ListResolverRuleAssociations_613468, base: "/",
    url: url_ListResolverRuleAssociations_613469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverRules_613485 = ref object of OpenApiRestCall_612658
proc url_ListResolverRules_613487(protocol: Scheme; host: string; base: string;
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

proc validate_ListResolverRules_613486(path: JsonNode; query: JsonNode;
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
  var valid_613488 = query.getOrDefault("MaxResults")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "MaxResults", valid_613488
  var valid_613489 = query.getOrDefault("NextToken")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "NextToken", valid_613489
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
  var valid_613490 = header.getOrDefault("X-Amz-Target")
  valid_613490 = validateParameter(valid_613490, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverRules"))
  if valid_613490 != nil:
    section.add "X-Amz-Target", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Signature")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Signature", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Content-Sha256", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Date")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Date", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Credential")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Credential", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Security-Token")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Security-Token", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Algorithm")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Algorithm", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-SignedHeaders", valid_613497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613499: Call_ListResolverRules_613485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resolver rules that were created using the current AWS account.
  ## 
  let valid = call_613499.validator(path, query, header, formData, body)
  let scheme = call_613499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613499.url(scheme.get, call_613499.host, call_613499.base,
                         call_613499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613499, url, valid)

proc call*(call_613500: Call_ListResolverRules_613485; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResolverRules
  ## Lists the resolver rules that were created using the current AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613501 = newJObject()
  var body_613502 = newJObject()
  add(query_613501, "MaxResults", newJString(MaxResults))
  add(query_613501, "NextToken", newJString(NextToken))
  if body != nil:
    body_613502 = body
  result = call_613500.call(nil, query_613501, nil, nil, body_613502)

var listResolverRules* = Call_ListResolverRules_613485(name: "listResolverRules",
    meth: HttpMethod.HttpPost, host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverRules",
    validator: validate_ListResolverRules_613486, base: "/",
    url: url_ListResolverRules_613487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613503 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613505(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613504(path: JsonNode; query: JsonNode;
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
  var valid_613506 = header.getOrDefault("X-Amz-Target")
  valid_613506 = validateParameter(valid_613506, JString, required = true, default = newJString(
      "Route53Resolver.ListTagsForResource"))
  if valid_613506 != nil:
    section.add "X-Amz-Target", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Signature")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Signature", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Content-Sha256", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Date")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Date", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Credential")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Credential", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Security-Token")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Security-Token", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Algorithm")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Algorithm", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-SignedHeaders", valid_613513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613515: Call_ListTagsForResource_613503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags that you associated with the specified resource.
  ## 
  let valid = call_613515.validator(path, query, header, formData, body)
  let scheme = call_613515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613515.url(scheme.get, call_613515.host, call_613515.base,
                         call_613515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613515, url, valid)

proc call*(call_613516: Call_ListTagsForResource_613503; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags that you associated with the specified resource.
  ##   body: JObject (required)
  var body_613517 = newJObject()
  if body != nil:
    body_613517 = body
  result = call_613516.call(nil, nil, nil, nil, body_613517)

var listTagsForResource* = Call_ListTagsForResource_613503(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListTagsForResource",
    validator: validate_ListTagsForResource_613504, base: "/",
    url: url_ListTagsForResource_613505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResolverRulePolicy_613518 = ref object of OpenApiRestCall_612658
proc url_PutResolverRulePolicy_613520(protocol: Scheme; host: string; base: string;
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

proc validate_PutResolverRulePolicy_613519(path: JsonNode; query: JsonNode;
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
  var valid_613521 = header.getOrDefault("X-Amz-Target")
  valid_613521 = validateParameter(valid_613521, JString, required = true, default = newJString(
      "Route53Resolver.PutResolverRulePolicy"))
  if valid_613521 != nil:
    section.add "X-Amz-Target", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Signature")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Signature", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Content-Sha256", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Date")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Date", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Credential")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Credential", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Security-Token")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Security-Token", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Algorithm")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Algorithm", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-SignedHeaders", valid_613528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613530: Call_PutResolverRulePolicy_613518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies the Resolver operations and resources that you want to allow another AWS account to be able to use.
  ## 
  let valid = call_613530.validator(path, query, header, formData, body)
  let scheme = call_613530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613530.url(scheme.get, call_613530.host, call_613530.base,
                         call_613530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613530, url, valid)

proc call*(call_613531: Call_PutResolverRulePolicy_613518; body: JsonNode): Recallable =
  ## putResolverRulePolicy
  ## Specifies the Resolver operations and resources that you want to allow another AWS account to be able to use.
  ##   body: JObject (required)
  var body_613532 = newJObject()
  if body != nil:
    body_613532 = body
  result = call_613531.call(nil, nil, nil, nil, body_613532)

var putResolverRulePolicy* = Call_PutResolverRulePolicy_613518(
    name: "putResolverRulePolicy", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.PutResolverRulePolicy",
    validator: validate_PutResolverRulePolicy_613519, base: "/",
    url: url_PutResolverRulePolicy_613520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613533 = ref object of OpenApiRestCall_612658
proc url_TagResource_613535(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613534(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613536 = header.getOrDefault("X-Amz-Target")
  valid_613536 = validateParameter(valid_613536, JString, required = true, default = newJString(
      "Route53Resolver.TagResource"))
  if valid_613536 != nil:
    section.add "X-Amz-Target", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Signature")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Signature", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Content-Sha256", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Date")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Date", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Credential")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Credential", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Security-Token")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Security-Token", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Algorithm")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Algorithm", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-SignedHeaders", valid_613543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613545: Call_TagResource_613533; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a specified resource.
  ## 
  let valid = call_613545.validator(path, query, header, formData, body)
  let scheme = call_613545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613545.url(scheme.get, call_613545.host, call_613545.base,
                         call_613545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613545, url, valid)

proc call*(call_613546: Call_TagResource_613533; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a specified resource.
  ##   body: JObject (required)
  var body_613547 = newJObject()
  if body != nil:
    body_613547 = body
  result = call_613546.call(nil, nil, nil, nil, body_613547)

var tagResource* = Call_TagResource_613533(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "route53resolver.amazonaws.com", route: "/#X-Amz-Target=Route53Resolver.TagResource",
                                        validator: validate_TagResource_613534,
                                        base: "/", url: url_TagResource_613535,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613548 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613550(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_613549(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613551 = header.getOrDefault("X-Amz-Target")
  valid_613551 = validateParameter(valid_613551, JString, required = true, default = newJString(
      "Route53Resolver.UntagResource"))
  if valid_613551 != nil:
    section.add "X-Amz-Target", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Signature")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Signature", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Content-Sha256", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Date")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Date", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Credential")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Credential", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Security-Token")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Security-Token", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Algorithm")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Algorithm", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-SignedHeaders", valid_613558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613560: Call_UntagResource_613548; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a specified resource.
  ## 
  let valid = call_613560.validator(path, query, header, formData, body)
  let scheme = call_613560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613560.url(scheme.get, call_613560.host, call_613560.base,
                         call_613560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613560, url, valid)

proc call*(call_613561: Call_UntagResource_613548; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a specified resource.
  ##   body: JObject (required)
  var body_613562 = newJObject()
  if body != nil:
    body_613562 = body
  result = call_613561.call(nil, nil, nil, nil, body_613562)

var untagResource* = Call_UntagResource_613548(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.UntagResource",
    validator: validate_UntagResource_613549, base: "/", url: url_UntagResource_613550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolverEndpoint_613563 = ref object of OpenApiRestCall_612658
proc url_UpdateResolverEndpoint_613565(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResolverEndpoint_613564(path: JsonNode; query: JsonNode;
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
  var valid_613566 = header.getOrDefault("X-Amz-Target")
  valid_613566 = validateParameter(valid_613566, JString, required = true, default = newJString(
      "Route53Resolver.UpdateResolverEndpoint"))
  if valid_613566 != nil:
    section.add "X-Amz-Target", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Signature")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Signature", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Content-Sha256", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Date")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Date", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Credential")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Credential", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Security-Token")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Security-Token", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Algorithm")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Algorithm", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-SignedHeaders", valid_613573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613575: Call_UpdateResolverEndpoint_613563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name of an inbound or an outbound resolver endpoint. 
  ## 
  let valid = call_613575.validator(path, query, header, formData, body)
  let scheme = call_613575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613575.url(scheme.get, call_613575.host, call_613575.base,
                         call_613575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613575, url, valid)

proc call*(call_613576: Call_UpdateResolverEndpoint_613563; body: JsonNode): Recallable =
  ## updateResolverEndpoint
  ## Updates the name of an inbound or an outbound resolver endpoint. 
  ##   body: JObject (required)
  var body_613577 = newJObject()
  if body != nil:
    body_613577 = body
  result = call_613576.call(nil, nil, nil, nil, body_613577)

var updateResolverEndpoint* = Call_UpdateResolverEndpoint_613563(
    name: "updateResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.UpdateResolverEndpoint",
    validator: validate_UpdateResolverEndpoint_613564, base: "/",
    url: url_UpdateResolverEndpoint_613565, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolverRule_613578 = ref object of OpenApiRestCall_612658
proc url_UpdateResolverRule_613580(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResolverRule_613579(path: JsonNode; query: JsonNode;
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
  var valid_613581 = header.getOrDefault("X-Amz-Target")
  valid_613581 = validateParameter(valid_613581, JString, required = true, default = newJString(
      "Route53Resolver.UpdateResolverRule"))
  if valid_613581 != nil:
    section.add "X-Amz-Target", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-Signature")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Signature", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Content-Sha256", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Date")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Date", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Credential")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Credential", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Security-Token")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Security-Token", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Algorithm")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Algorithm", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-SignedHeaders", valid_613588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613590: Call_UpdateResolverRule_613578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates settings for a specified resolver rule. <code>ResolverRuleId</code> is required, and all other parameters are optional. If you don't specify a parameter, it retains its current value.
  ## 
  let valid = call_613590.validator(path, query, header, formData, body)
  let scheme = call_613590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613590.url(scheme.get, call_613590.host, call_613590.base,
                         call_613590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613590, url, valid)

proc call*(call_613591: Call_UpdateResolverRule_613578; body: JsonNode): Recallable =
  ## updateResolverRule
  ## Updates settings for a specified resolver rule. <code>ResolverRuleId</code> is required, and all other parameters are optional. If you don't specify a parameter, it retains its current value.
  ##   body: JObject (required)
  var body_613592 = newJObject()
  if body != nil:
    body_613592 = body
  result = call_613591.call(nil, nil, nil, nil, body_613592)

var updateResolverRule* = Call_UpdateResolverRule_613578(
    name: "updateResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.UpdateResolverRule",
    validator: validate_UpdateResolverRule_613579, base: "/",
    url: url_UpdateResolverRule_613580, schemes: {Scheme.Https, Scheme.Http})
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
