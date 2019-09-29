
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateResolverEndpointIpAddress_593774 = ref object of OpenApiRestCall_593437
proc url_AssociateResolverEndpointIpAddress_593776(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateResolverEndpointIpAddress_593775(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593903 = header.getOrDefault("X-Amz-Target")
  valid_593903 = validateParameter(valid_593903, JString, required = true, default = newJString(
      "Route53Resolver.AssociateResolverEndpointIpAddress"))
  if valid_593903 != nil:
    section.add "X-Amz-Target", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Credential")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Credential", valid_593908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_AssociateResolverEndpointIpAddress_593774;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds IP addresses to an inbound or an outbound resolver endpoint. If you want to adding more than one IP address, submit one <code>AssociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To remove an IP address from an endpoint, see <a>DisassociateResolverEndpointIpAddress</a>.</p>
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_AssociateResolverEndpointIpAddress_593774;
          body: JsonNode): Recallable =
  ## associateResolverEndpointIpAddress
  ## <p>Adds IP addresses to an inbound or an outbound resolver endpoint. If you want to adding more than one IP address, submit one <code>AssociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To remove an IP address from an endpoint, see <a>DisassociateResolverEndpointIpAddress</a>.</p>
  ##   body: JObject (required)
  var body_594004 = newJObject()
  if body != nil:
    body_594004 = body
  result = call_594003.call(nil, nil, nil, nil, body_594004)

var associateResolverEndpointIpAddress* = Call_AssociateResolverEndpointIpAddress_593774(
    name: "associateResolverEndpointIpAddress", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.AssociateResolverEndpointIpAddress",
    validator: validate_AssociateResolverEndpointIpAddress_593775, base: "/",
    url: url_AssociateResolverEndpointIpAddress_593776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResolverRule_594043 = ref object of OpenApiRestCall_593437
proc url_AssociateResolverRule_594045(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateResolverRule_594044(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594048 = header.getOrDefault("X-Amz-Target")
  valid_594048 = validateParameter(valid_594048, JString, required = true, default = newJString(
      "Route53Resolver.AssociateResolverRule"))
  if valid_594048 != nil:
    section.add "X-Amz-Target", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_AssociateResolverRule_594043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a resolver rule with a VPC. When you associate a rule with a VPC, Resolver forwards all DNS queries for the domain name that is specified in the rule and that originate in the VPC. The queries are forwarded to the IP addresses for the DNS resolvers that are specified in the rule. For more information about rules, see <a>CreateResolverRule</a>. 
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_AssociateResolverRule_594043; body: JsonNode): Recallable =
  ## associateResolverRule
  ## Associates a resolver rule with a VPC. When you associate a rule with a VPC, Resolver forwards all DNS queries for the domain name that is specified in the rule and that originate in the VPC. The queries are forwarded to the IP addresses for the DNS resolvers that are specified in the rule. For more information about rules, see <a>CreateResolverRule</a>. 
  ##   body: JObject (required)
  var body_594057 = newJObject()
  if body != nil:
    body_594057 = body
  result = call_594056.call(nil, nil, nil, nil, body_594057)

var associateResolverRule* = Call_AssociateResolverRule_594043(
    name: "associateResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.AssociateResolverRule",
    validator: validate_AssociateResolverRule_594044, base: "/",
    url: url_AssociateResolverRule_594045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolverEndpoint_594058 = ref object of OpenApiRestCall_593437
proc url_CreateResolverEndpoint_594060(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateResolverEndpoint_594059(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594063 = header.getOrDefault("X-Amz-Target")
  valid_594063 = validateParameter(valid_594063, JString, required = true, default = newJString(
      "Route53Resolver.CreateResolverEndpoint"))
  if valid_594063 != nil:
    section.add "X-Amz-Target", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_CreateResolverEndpoint_594058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a resolver endpoint. There are two types of resolver endpoints, inbound and outbound:</p> <ul> <li> <p>An <i>inbound resolver endpoint</i> forwards DNS queries to the DNS service for a VPC from your network or another VPC.</p> </li> <li> <p>An <i>outbound resolver endpoint</i> forwards DNS queries from the DNS service for a VPC to your network or another VPC.</p> </li> </ul>
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_CreateResolverEndpoint_594058; body: JsonNode): Recallable =
  ## createResolverEndpoint
  ## <p>Creates a resolver endpoint. There are two types of resolver endpoints, inbound and outbound:</p> <ul> <li> <p>An <i>inbound resolver endpoint</i> forwards DNS queries to the DNS service for a VPC from your network or another VPC.</p> </li> <li> <p>An <i>outbound resolver endpoint</i> forwards DNS queries from the DNS service for a VPC to your network or another VPC.</p> </li> </ul>
  ##   body: JObject (required)
  var body_594072 = newJObject()
  if body != nil:
    body_594072 = body
  result = call_594071.call(nil, nil, nil, nil, body_594072)

var createResolverEndpoint* = Call_CreateResolverEndpoint_594058(
    name: "createResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.CreateResolverEndpoint",
    validator: validate_CreateResolverEndpoint_594059, base: "/",
    url: url_CreateResolverEndpoint_594060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolverRule_594073 = ref object of OpenApiRestCall_593437
proc url_CreateResolverRule_594075(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateResolverRule_594074(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Security-Token")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Security-Token", valid_594077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594078 = header.getOrDefault("X-Amz-Target")
  valid_594078 = validateParameter(valid_594078, JString, required = true, default = newJString(
      "Route53Resolver.CreateResolverRule"))
  if valid_594078 != nil:
    section.add "X-Amz-Target", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_CreateResolverRule_594073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For DNS queries that originate in your VPCs, specifies which resolver endpoint the queries pass through, one domain name that you want to forward to your network, and the IP addresses of the DNS resolvers in your network.
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_CreateResolverRule_594073; body: JsonNode): Recallable =
  ## createResolverRule
  ## For DNS queries that originate in your VPCs, specifies which resolver endpoint the queries pass through, one domain name that you want to forward to your network, and the IP addresses of the DNS resolvers in your network.
  ##   body: JObject (required)
  var body_594087 = newJObject()
  if body != nil:
    body_594087 = body
  result = call_594086.call(nil, nil, nil, nil, body_594087)

var createResolverRule* = Call_CreateResolverRule_594073(
    name: "createResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.CreateResolverRule",
    validator: validate_CreateResolverRule_594074, base: "/",
    url: url_CreateResolverRule_594075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolverEndpoint_594088 = ref object of OpenApiRestCall_593437
proc url_DeleteResolverEndpoint_594090(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteResolverEndpoint_594089(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594093 = header.getOrDefault("X-Amz-Target")
  valid_594093 = validateParameter(valid_594093, JString, required = true, default = newJString(
      "Route53Resolver.DeleteResolverEndpoint"))
  if valid_594093 != nil:
    section.add "X-Amz-Target", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_DeleteResolverEndpoint_594088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a resolver endpoint. The effect of deleting a resolver endpoint depends on whether it's an inbound or an outbound resolver endpoint:</p> <ul> <li> <p> <b>Inbound</b>: DNS queries from your network or another VPC are no longer routed to the DNS service for the specified VPC.</p> </li> <li> <p> <b>Outbound</b>: DNS queries from a VPC are no longer routed to your network or to another VPC.</p> </li> </ul>
  ## 
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_DeleteResolverEndpoint_594088; body: JsonNode): Recallable =
  ## deleteResolverEndpoint
  ## <p>Deletes a resolver endpoint. The effect of deleting a resolver endpoint depends on whether it's an inbound or an outbound resolver endpoint:</p> <ul> <li> <p> <b>Inbound</b>: DNS queries from your network or another VPC are no longer routed to the DNS service for the specified VPC.</p> </li> <li> <p> <b>Outbound</b>: DNS queries from a VPC are no longer routed to your network or to another VPC.</p> </li> </ul>
  ##   body: JObject (required)
  var body_594102 = newJObject()
  if body != nil:
    body_594102 = body
  result = call_594101.call(nil, nil, nil, nil, body_594102)

var deleteResolverEndpoint* = Call_DeleteResolverEndpoint_594088(
    name: "deleteResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.DeleteResolverEndpoint",
    validator: validate_DeleteResolverEndpoint_594089, base: "/",
    url: url_DeleteResolverEndpoint_594090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolverRule_594103 = ref object of OpenApiRestCall_593437
proc url_DeleteResolverRule_594105(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteResolverRule_594104(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594108 = header.getOrDefault("X-Amz-Target")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "Route53Resolver.DeleteResolverRule"))
  if valid_594108 != nil:
    section.add "X-Amz-Target", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-SignedHeaders", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_DeleteResolverRule_594103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resolver rule. Before you can delete a resolver rule, you must disassociate it from all the VPCs that you associated the resolver rule with. For more infomation, see <a>DisassociateResolverRule</a>.
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_DeleteResolverRule_594103; body: JsonNode): Recallable =
  ## deleteResolverRule
  ## Deletes a resolver rule. Before you can delete a resolver rule, you must disassociate it from all the VPCs that you associated the resolver rule with. For more infomation, see <a>DisassociateResolverRule</a>.
  ##   body: JObject (required)
  var body_594117 = newJObject()
  if body != nil:
    body_594117 = body
  result = call_594116.call(nil, nil, nil, nil, body_594117)

var deleteResolverRule* = Call_DeleteResolverRule_594103(
    name: "deleteResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.DeleteResolverRule",
    validator: validate_DeleteResolverRule_594104, base: "/",
    url: url_DeleteResolverRule_594105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResolverEndpointIpAddress_594118 = ref object of OpenApiRestCall_593437
proc url_DisassociateResolverEndpointIpAddress_594120(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateResolverEndpointIpAddress_594119(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594121 = header.getOrDefault("X-Amz-Date")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Date", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Security-Token")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Security-Token", valid_594122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594123 = header.getOrDefault("X-Amz-Target")
  valid_594123 = validateParameter(valid_594123, JString, required = true, default = newJString(
      "Route53Resolver.DisassociateResolverEndpointIpAddress"))
  if valid_594123 != nil:
    section.add "X-Amz-Target", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-SignedHeaders", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_DisassociateResolverEndpointIpAddress_594118;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes IP addresses from an inbound or an outbound resolver endpoint. If you want to remove more than one IP address, submit one <code>DisassociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To add an IP address to an endpoint, see <a>AssociateResolverEndpointIpAddress</a>.</p>
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_DisassociateResolverEndpointIpAddress_594118;
          body: JsonNode): Recallable =
  ## disassociateResolverEndpointIpAddress
  ## <p>Removes IP addresses from an inbound or an outbound resolver endpoint. If you want to remove more than one IP address, submit one <code>DisassociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To add an IP address to an endpoint, see <a>AssociateResolverEndpointIpAddress</a>.</p>
  ##   body: JObject (required)
  var body_594132 = newJObject()
  if body != nil:
    body_594132 = body
  result = call_594131.call(nil, nil, nil, nil, body_594132)

var disassociateResolverEndpointIpAddress* = Call_DisassociateResolverEndpointIpAddress_594118(
    name: "disassociateResolverEndpointIpAddress", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com", route: "/#X-Amz-Target=Route53Resolver.DisassociateResolverEndpointIpAddress",
    validator: validate_DisassociateResolverEndpointIpAddress_594119, base: "/",
    url: url_DisassociateResolverEndpointIpAddress_594120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResolverRule_594133 = ref object of OpenApiRestCall_593437
proc url_DisassociateResolverRule_594135(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateResolverRule_594134(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594138 = header.getOrDefault("X-Amz-Target")
  valid_594138 = validateParameter(valid_594138, JString, required = true, default = newJString(
      "Route53Resolver.DisassociateResolverRule"))
  if valid_594138 != nil:
    section.add "X-Amz-Target", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Signature")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Signature", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-SignedHeaders", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Credential")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Credential", valid_594143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_DisassociateResolverRule_594133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the association between a specified resolver rule and a specified VPC.</p> <important> <p>If you disassociate a resolver rule from a VPC, Resolver stops forwarding DNS queries for the domain name that you specified in the resolver rule. </p> </important>
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_DisassociateResolverRule_594133; body: JsonNode): Recallable =
  ## disassociateResolverRule
  ## <p>Removes the association between a specified resolver rule and a specified VPC.</p> <important> <p>If you disassociate a resolver rule from a VPC, Resolver stops forwarding DNS queries for the domain name that you specified in the resolver rule. </p> </important>
  ##   body: JObject (required)
  var body_594147 = newJObject()
  if body != nil:
    body_594147 = body
  result = call_594146.call(nil, nil, nil, nil, body_594147)

var disassociateResolverRule* = Call_DisassociateResolverRule_594133(
    name: "disassociateResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.DisassociateResolverRule",
    validator: validate_DisassociateResolverRule_594134, base: "/",
    url: url_DisassociateResolverRule_594135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverEndpoint_594148 = ref object of OpenApiRestCall_593437
proc url_GetResolverEndpoint_594150(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResolverEndpoint_594149(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594151 = header.getOrDefault("X-Amz-Date")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Date", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Security-Token")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Security-Token", valid_594152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594153 = header.getOrDefault("X-Amz-Target")
  valid_594153 = validateParameter(valid_594153, JString, required = true, default = newJString(
      "Route53Resolver.GetResolverEndpoint"))
  if valid_594153 != nil:
    section.add "X-Amz-Target", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_GetResolverEndpoint_594148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified resolver endpoint, such as whether it's an inbound or an outbound resolver endpoint, and the current status of the endpoint.
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_GetResolverEndpoint_594148; body: JsonNode): Recallable =
  ## getResolverEndpoint
  ## Gets information about a specified resolver endpoint, such as whether it's an inbound or an outbound resolver endpoint, and the current status of the endpoint.
  ##   body: JObject (required)
  var body_594162 = newJObject()
  if body != nil:
    body_594162 = body
  result = call_594161.call(nil, nil, nil, nil, body_594162)

var getResolverEndpoint* = Call_GetResolverEndpoint_594148(
    name: "getResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverEndpoint",
    validator: validate_GetResolverEndpoint_594149, base: "/",
    url: url_GetResolverEndpoint_594150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverRule_594163 = ref object of OpenApiRestCall_593437
proc url_GetResolverRule_594165(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResolverRule_594164(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594168 = header.getOrDefault("X-Amz-Target")
  valid_594168 = validateParameter(valid_594168, JString, required = true, default = newJString(
      "Route53Resolver.GetResolverRule"))
  if valid_594168 != nil:
    section.add "X-Amz-Target", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Content-Sha256", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-SignedHeaders", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Credential")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Credential", valid_594173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_GetResolverRule_594163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified resolver rule, such as the domain name that the rule forwards DNS queries for and the ID of the outbound resolver endpoint that the rule is associated with.
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_GetResolverRule_594163; body: JsonNode): Recallable =
  ## getResolverRule
  ## Gets information about a specified resolver rule, such as the domain name that the rule forwards DNS queries for and the ID of the outbound resolver endpoint that the rule is associated with.
  ##   body: JObject (required)
  var body_594177 = newJObject()
  if body != nil:
    body_594177 = body
  result = call_594176.call(nil, nil, nil, nil, body_594177)

var getResolverRule* = Call_GetResolverRule_594163(name: "getResolverRule",
    meth: HttpMethod.HttpPost, host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverRule",
    validator: validate_GetResolverRule_594164, base: "/", url: url_GetResolverRule_594165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverRuleAssociation_594178 = ref object of OpenApiRestCall_593437
proc url_GetResolverRuleAssociation_594180(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResolverRuleAssociation_594179(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594181 = header.getOrDefault("X-Amz-Date")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Date", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594183 = header.getOrDefault("X-Amz-Target")
  valid_594183 = validateParameter(valid_594183, JString, required = true, default = newJString(
      "Route53Resolver.GetResolverRuleAssociation"))
  if valid_594183 != nil:
    section.add "X-Amz-Target", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Content-Sha256", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Signature")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Signature", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Credential")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Credential", valid_594188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594190: Call_GetResolverRuleAssociation_594178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an association between a specified resolver rule and a VPC. You associate a resolver rule and a VPC using <a>AssociateResolverRule</a>. 
  ## 
  let valid = call_594190.validator(path, query, header, formData, body)
  let scheme = call_594190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594190.url(scheme.get, call_594190.host, call_594190.base,
                         call_594190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594190, url, valid)

proc call*(call_594191: Call_GetResolverRuleAssociation_594178; body: JsonNode): Recallable =
  ## getResolverRuleAssociation
  ## Gets information about an association between a specified resolver rule and a VPC. You associate a resolver rule and a VPC using <a>AssociateResolverRule</a>. 
  ##   body: JObject (required)
  var body_594192 = newJObject()
  if body != nil:
    body_594192 = body
  result = call_594191.call(nil, nil, nil, nil, body_594192)

var getResolverRuleAssociation* = Call_GetResolverRuleAssociation_594178(
    name: "getResolverRuleAssociation", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverRuleAssociation",
    validator: validate_GetResolverRuleAssociation_594179, base: "/",
    url: url_GetResolverRuleAssociation_594180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverRulePolicy_594193 = ref object of OpenApiRestCall_593437
proc url_GetResolverRulePolicy_594195(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResolverRulePolicy_594194(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594196 = header.getOrDefault("X-Amz-Date")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Date", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Security-Token")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Security-Token", valid_594197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594198 = header.getOrDefault("X-Amz-Target")
  valid_594198 = validateParameter(valid_594198, JString, required = true, default = newJString(
      "Route53Resolver.GetResolverRulePolicy"))
  if valid_594198 != nil:
    section.add "X-Amz-Target", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_GetResolverRulePolicy_594193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a resolver rule policy. A resolver rule policy specifies the Resolver operations and resources that you want to allow another AWS account to be able to use. 
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_GetResolverRulePolicy_594193; body: JsonNode): Recallable =
  ## getResolverRulePolicy
  ## Gets information about a resolver rule policy. A resolver rule policy specifies the Resolver operations and resources that you want to allow another AWS account to be able to use. 
  ##   body: JObject (required)
  var body_594207 = newJObject()
  if body != nil:
    body_594207 = body
  result = call_594206.call(nil, nil, nil, nil, body_594207)

var getResolverRulePolicy* = Call_GetResolverRulePolicy_594193(
    name: "getResolverRulePolicy", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverRulePolicy",
    validator: validate_GetResolverRulePolicy_594194, base: "/",
    url: url_GetResolverRulePolicy_594195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverEndpointIpAddresses_594208 = ref object of OpenApiRestCall_593437
proc url_ListResolverEndpointIpAddresses_594210(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResolverEndpointIpAddresses_594209(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the IP addresses for a specified resolver endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594211 = query.getOrDefault("NextToken")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "NextToken", valid_594211
  var valid_594212 = query.getOrDefault("MaxResults")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "MaxResults", valid_594212
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
  var valid_594213 = header.getOrDefault("X-Amz-Date")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Date", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Security-Token")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Security-Token", valid_594214
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594215 = header.getOrDefault("X-Amz-Target")
  valid_594215 = validateParameter(valid_594215, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverEndpointIpAddresses"))
  if valid_594215 != nil:
    section.add "X-Amz-Target", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Content-Sha256", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Algorithm")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Algorithm", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Signature")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Signature", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-SignedHeaders", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-Credential")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-Credential", valid_594220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594222: Call_ListResolverEndpointIpAddresses_594208;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the IP addresses for a specified resolver endpoint.
  ## 
  let valid = call_594222.validator(path, query, header, formData, body)
  let scheme = call_594222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594222.url(scheme.get, call_594222.host, call_594222.base,
                         call_594222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594222, url, valid)

proc call*(call_594223: Call_ListResolverEndpointIpAddresses_594208;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResolverEndpointIpAddresses
  ## Gets the IP addresses for a specified resolver endpoint.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594224 = newJObject()
  var body_594225 = newJObject()
  add(query_594224, "NextToken", newJString(NextToken))
  if body != nil:
    body_594225 = body
  add(query_594224, "MaxResults", newJString(MaxResults))
  result = call_594223.call(nil, query_594224, nil, nil, body_594225)

var listResolverEndpointIpAddresses* = Call_ListResolverEndpointIpAddresses_594208(
    name: "listResolverEndpointIpAddresses", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverEndpointIpAddresses",
    validator: validate_ListResolverEndpointIpAddresses_594209, base: "/",
    url: url_ListResolverEndpointIpAddresses_594210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverEndpoints_594227 = ref object of OpenApiRestCall_593437
proc url_ListResolverEndpoints_594229(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResolverEndpoints_594228(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the resolver endpoints that were created using the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594230 = query.getOrDefault("NextToken")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "NextToken", valid_594230
  var valid_594231 = query.getOrDefault("MaxResults")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "MaxResults", valid_594231
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
  var valid_594232 = header.getOrDefault("X-Amz-Date")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-Date", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Security-Token")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Security-Token", valid_594233
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594234 = header.getOrDefault("X-Amz-Target")
  valid_594234 = validateParameter(valid_594234, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverEndpoints"))
  if valid_594234 != nil:
    section.add "X-Amz-Target", valid_594234
  var valid_594235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "X-Amz-Content-Sha256", valid_594235
  var valid_594236 = header.getOrDefault("X-Amz-Algorithm")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Algorithm", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Signature")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Signature", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-SignedHeaders", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Credential")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Credential", valid_594239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594241: Call_ListResolverEndpoints_594227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the resolver endpoints that were created using the current AWS account.
  ## 
  let valid = call_594241.validator(path, query, header, formData, body)
  let scheme = call_594241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594241.url(scheme.get, call_594241.host, call_594241.base,
                         call_594241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594241, url, valid)

proc call*(call_594242: Call_ListResolverEndpoints_594227; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResolverEndpoints
  ## Lists all the resolver endpoints that were created using the current AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594243 = newJObject()
  var body_594244 = newJObject()
  add(query_594243, "NextToken", newJString(NextToken))
  if body != nil:
    body_594244 = body
  add(query_594243, "MaxResults", newJString(MaxResults))
  result = call_594242.call(nil, query_594243, nil, nil, body_594244)

var listResolverEndpoints* = Call_ListResolverEndpoints_594227(
    name: "listResolverEndpoints", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverEndpoints",
    validator: validate_ListResolverEndpoints_594228, base: "/",
    url: url_ListResolverEndpoints_594229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverRuleAssociations_594245 = ref object of OpenApiRestCall_593437
proc url_ListResolverRuleAssociations_594247(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResolverRuleAssociations_594246(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the associations that were created between resolver rules and VPCs using the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594248 = query.getOrDefault("NextToken")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "NextToken", valid_594248
  var valid_594249 = query.getOrDefault("MaxResults")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "MaxResults", valid_594249
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
  var valid_594250 = header.getOrDefault("X-Amz-Date")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Date", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Security-Token")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Security-Token", valid_594251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594252 = header.getOrDefault("X-Amz-Target")
  valid_594252 = validateParameter(valid_594252, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverRuleAssociations"))
  if valid_594252 != nil:
    section.add "X-Amz-Target", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Content-Sha256", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Algorithm")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Algorithm", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Signature")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Signature", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-SignedHeaders", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Credential")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Credential", valid_594257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594259: Call_ListResolverRuleAssociations_594245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the associations that were created between resolver rules and VPCs using the current AWS account.
  ## 
  let valid = call_594259.validator(path, query, header, formData, body)
  let scheme = call_594259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594259.url(scheme.get, call_594259.host, call_594259.base,
                         call_594259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594259, url, valid)

proc call*(call_594260: Call_ListResolverRuleAssociations_594245; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResolverRuleAssociations
  ## Lists the associations that were created between resolver rules and VPCs using the current AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594261 = newJObject()
  var body_594262 = newJObject()
  add(query_594261, "NextToken", newJString(NextToken))
  if body != nil:
    body_594262 = body
  add(query_594261, "MaxResults", newJString(MaxResults))
  result = call_594260.call(nil, query_594261, nil, nil, body_594262)

var listResolverRuleAssociations* = Call_ListResolverRuleAssociations_594245(
    name: "listResolverRuleAssociations", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverRuleAssociations",
    validator: validate_ListResolverRuleAssociations_594246, base: "/",
    url: url_ListResolverRuleAssociations_594247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverRules_594263 = ref object of OpenApiRestCall_593437
proc url_ListResolverRules_594265(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResolverRules_594264(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the resolver rules that were created using the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594266 = query.getOrDefault("NextToken")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "NextToken", valid_594266
  var valid_594267 = query.getOrDefault("MaxResults")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "MaxResults", valid_594267
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
  var valid_594268 = header.getOrDefault("X-Amz-Date")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Date", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Security-Token")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Security-Token", valid_594269
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594270 = header.getOrDefault("X-Amz-Target")
  valid_594270 = validateParameter(valid_594270, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverRules"))
  if valid_594270 != nil:
    section.add "X-Amz-Target", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Content-Sha256", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Algorithm")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Algorithm", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Signature")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Signature", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-SignedHeaders", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Credential")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Credential", valid_594275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594277: Call_ListResolverRules_594263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resolver rules that were created using the current AWS account.
  ## 
  let valid = call_594277.validator(path, query, header, formData, body)
  let scheme = call_594277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594277.url(scheme.get, call_594277.host, call_594277.base,
                         call_594277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594277, url, valid)

proc call*(call_594278: Call_ListResolverRules_594263; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResolverRules
  ## Lists the resolver rules that were created using the current AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594279 = newJObject()
  var body_594280 = newJObject()
  add(query_594279, "NextToken", newJString(NextToken))
  if body != nil:
    body_594280 = body
  add(query_594279, "MaxResults", newJString(MaxResults))
  result = call_594278.call(nil, query_594279, nil, nil, body_594280)

var listResolverRules* = Call_ListResolverRules_594263(name: "listResolverRules",
    meth: HttpMethod.HttpPost, host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverRules",
    validator: validate_ListResolverRules_594264, base: "/",
    url: url_ListResolverRules_594265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594281 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_594283(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_594282(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594284 = header.getOrDefault("X-Amz-Date")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-Date", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-Security-Token")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Security-Token", valid_594285
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594286 = header.getOrDefault("X-Amz-Target")
  valid_594286 = validateParameter(valid_594286, JString, required = true, default = newJString(
      "Route53Resolver.ListTagsForResource"))
  if valid_594286 != nil:
    section.add "X-Amz-Target", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Content-Sha256", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Algorithm")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Algorithm", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Signature")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Signature", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-SignedHeaders", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Credential")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Credential", valid_594291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594293: Call_ListTagsForResource_594281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags that you associated with the specified resource.
  ## 
  let valid = call_594293.validator(path, query, header, formData, body)
  let scheme = call_594293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594293.url(scheme.get, call_594293.host, call_594293.base,
                         call_594293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594293, url, valid)

proc call*(call_594294: Call_ListTagsForResource_594281; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags that you associated with the specified resource.
  ##   body: JObject (required)
  var body_594295 = newJObject()
  if body != nil:
    body_594295 = body
  result = call_594294.call(nil, nil, nil, nil, body_594295)

var listTagsForResource* = Call_ListTagsForResource_594281(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListTagsForResource",
    validator: validate_ListTagsForResource_594282, base: "/",
    url: url_ListTagsForResource_594283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResolverRulePolicy_594296 = ref object of OpenApiRestCall_593437
proc url_PutResolverRulePolicy_594298(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutResolverRulePolicy_594297(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594299 = header.getOrDefault("X-Amz-Date")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Date", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-Security-Token")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-Security-Token", valid_594300
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594301 = header.getOrDefault("X-Amz-Target")
  valid_594301 = validateParameter(valid_594301, JString, required = true, default = newJString(
      "Route53Resolver.PutResolverRulePolicy"))
  if valid_594301 != nil:
    section.add "X-Amz-Target", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Content-Sha256", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Algorithm")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Algorithm", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Signature")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Signature", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-SignedHeaders", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Credential")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Credential", valid_594306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594308: Call_PutResolverRulePolicy_594296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies the Resolver operations and resources that you want to allow another AWS account to be able to use.
  ## 
  let valid = call_594308.validator(path, query, header, formData, body)
  let scheme = call_594308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594308.url(scheme.get, call_594308.host, call_594308.base,
                         call_594308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594308, url, valid)

proc call*(call_594309: Call_PutResolverRulePolicy_594296; body: JsonNode): Recallable =
  ## putResolverRulePolicy
  ## Specifies the Resolver operations and resources that you want to allow another AWS account to be able to use.
  ##   body: JObject (required)
  var body_594310 = newJObject()
  if body != nil:
    body_594310 = body
  result = call_594309.call(nil, nil, nil, nil, body_594310)

var putResolverRulePolicy* = Call_PutResolverRulePolicy_594296(
    name: "putResolverRulePolicy", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.PutResolverRulePolicy",
    validator: validate_PutResolverRulePolicy_594297, base: "/",
    url: url_PutResolverRulePolicy_594298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594311 = ref object of OpenApiRestCall_593437
proc url_TagResource_594313(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_594312(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594314 = header.getOrDefault("X-Amz-Date")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Date", valid_594314
  var valid_594315 = header.getOrDefault("X-Amz-Security-Token")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "X-Amz-Security-Token", valid_594315
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594316 = header.getOrDefault("X-Amz-Target")
  valid_594316 = validateParameter(valid_594316, JString, required = true, default = newJString(
      "Route53Resolver.TagResource"))
  if valid_594316 != nil:
    section.add "X-Amz-Target", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Content-Sha256", valid_594317
  var valid_594318 = header.getOrDefault("X-Amz-Algorithm")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Algorithm", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Signature")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Signature", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-SignedHeaders", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Credential")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Credential", valid_594321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594323: Call_TagResource_594311; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a specified resource.
  ## 
  let valid = call_594323.validator(path, query, header, formData, body)
  let scheme = call_594323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594323.url(scheme.get, call_594323.host, call_594323.base,
                         call_594323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594323, url, valid)

proc call*(call_594324: Call_TagResource_594311; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a specified resource.
  ##   body: JObject (required)
  var body_594325 = newJObject()
  if body != nil:
    body_594325 = body
  result = call_594324.call(nil, nil, nil, nil, body_594325)

var tagResource* = Call_TagResource_594311(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "route53resolver.amazonaws.com", route: "/#X-Amz-Target=Route53Resolver.TagResource",
                                        validator: validate_TagResource_594312,
                                        base: "/", url: url_TagResource_594313,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594326 = ref object of OpenApiRestCall_593437
proc url_UntagResource_594328(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_594327(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594329 = header.getOrDefault("X-Amz-Date")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Date", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Security-Token")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Security-Token", valid_594330
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594331 = header.getOrDefault("X-Amz-Target")
  valid_594331 = validateParameter(valid_594331, JString, required = true, default = newJString(
      "Route53Resolver.UntagResource"))
  if valid_594331 != nil:
    section.add "X-Amz-Target", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Content-Sha256", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-Algorithm")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Algorithm", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Signature")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Signature", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-SignedHeaders", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Credential")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Credential", valid_594336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594338: Call_UntagResource_594326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a specified resource.
  ## 
  let valid = call_594338.validator(path, query, header, formData, body)
  let scheme = call_594338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594338.url(scheme.get, call_594338.host, call_594338.base,
                         call_594338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594338, url, valid)

proc call*(call_594339: Call_UntagResource_594326; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a specified resource.
  ##   body: JObject (required)
  var body_594340 = newJObject()
  if body != nil:
    body_594340 = body
  result = call_594339.call(nil, nil, nil, nil, body_594340)

var untagResource* = Call_UntagResource_594326(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.UntagResource",
    validator: validate_UntagResource_594327, base: "/", url: url_UntagResource_594328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolverEndpoint_594341 = ref object of OpenApiRestCall_593437
proc url_UpdateResolverEndpoint_594343(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateResolverEndpoint_594342(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594344 = header.getOrDefault("X-Amz-Date")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Date", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-Security-Token")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Security-Token", valid_594345
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594346 = header.getOrDefault("X-Amz-Target")
  valid_594346 = validateParameter(valid_594346, JString, required = true, default = newJString(
      "Route53Resolver.UpdateResolverEndpoint"))
  if valid_594346 != nil:
    section.add "X-Amz-Target", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Content-Sha256", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Algorithm")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Algorithm", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Signature")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Signature", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-SignedHeaders", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Credential")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Credential", valid_594351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594353: Call_UpdateResolverEndpoint_594341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name of an inbound or an outbound resolver endpoint. 
  ## 
  let valid = call_594353.validator(path, query, header, formData, body)
  let scheme = call_594353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594353.url(scheme.get, call_594353.host, call_594353.base,
                         call_594353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594353, url, valid)

proc call*(call_594354: Call_UpdateResolverEndpoint_594341; body: JsonNode): Recallable =
  ## updateResolverEndpoint
  ## Updates the name of an inbound or an outbound resolver endpoint. 
  ##   body: JObject (required)
  var body_594355 = newJObject()
  if body != nil:
    body_594355 = body
  result = call_594354.call(nil, nil, nil, nil, body_594355)

var updateResolverEndpoint* = Call_UpdateResolverEndpoint_594341(
    name: "updateResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.UpdateResolverEndpoint",
    validator: validate_UpdateResolverEndpoint_594342, base: "/",
    url: url_UpdateResolverEndpoint_594343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolverRule_594356 = ref object of OpenApiRestCall_593437
proc url_UpdateResolverRule_594358(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateResolverRule_594357(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594359 = header.getOrDefault("X-Amz-Date")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Date", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-Security-Token")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-Security-Token", valid_594360
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594361 = header.getOrDefault("X-Amz-Target")
  valid_594361 = validateParameter(valid_594361, JString, required = true, default = newJString(
      "Route53Resolver.UpdateResolverRule"))
  if valid_594361 != nil:
    section.add "X-Amz-Target", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Content-Sha256", valid_594362
  var valid_594363 = header.getOrDefault("X-Amz-Algorithm")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Algorithm", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Signature")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Signature", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-SignedHeaders", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Credential")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Credential", valid_594366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594368: Call_UpdateResolverRule_594356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates settings for a specified resolver rule. <code>ResolverRuleId</code> is required, and all other parameters are optional. If you don't specify a parameter, it retains its current value.
  ## 
  let valid = call_594368.validator(path, query, header, formData, body)
  let scheme = call_594368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594368.url(scheme.get, call_594368.host, call_594368.base,
                         call_594368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594368, url, valid)

proc call*(call_594369: Call_UpdateResolverRule_594356; body: JsonNode): Recallable =
  ## updateResolverRule
  ## Updates settings for a specified resolver rule. <code>ResolverRuleId</code> is required, and all other parameters are optional. If you don't specify a parameter, it retains its current value.
  ##   body: JObject (required)
  var body_594370 = newJObject()
  if body != nil:
    body_594370 = body
  result = call_594369.call(nil, nil, nil, nil, body_594370)

var updateResolverRule* = Call_UpdateResolverRule_594356(
    name: "updateResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.UpdateResolverRule",
    validator: validate_UpdateResolverRule_594357, base: "/",
    url: url_UpdateResolverRule_594358, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
