
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
  Call_AssociateResolverEndpointIpAddress_602803 = ref object of OpenApiRestCall_602466
proc url_AssociateResolverEndpointIpAddress_602805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateResolverEndpointIpAddress_602804(path: JsonNode;
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
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "Route53Resolver.AssociateResolverEndpointIpAddress"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_AssociateResolverEndpointIpAddress_602803;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds IP addresses to an inbound or an outbound resolver endpoint. If you want to adding more than one IP address, submit one <code>AssociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To remove an IP address from an endpoint, see <a>DisassociateResolverEndpointIpAddress</a>.</p>
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_AssociateResolverEndpointIpAddress_602803;
          body: JsonNode): Recallable =
  ## associateResolverEndpointIpAddress
  ## <p>Adds IP addresses to an inbound or an outbound resolver endpoint. If you want to adding more than one IP address, submit one <code>AssociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To remove an IP address from an endpoint, see <a>DisassociateResolverEndpointIpAddress</a>.</p>
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var associateResolverEndpointIpAddress* = Call_AssociateResolverEndpointIpAddress_602803(
    name: "associateResolverEndpointIpAddress", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.AssociateResolverEndpointIpAddress",
    validator: validate_AssociateResolverEndpointIpAddress_602804, base: "/",
    url: url_AssociateResolverEndpointIpAddress_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResolverRule_603072 = ref object of OpenApiRestCall_602466
proc url_AssociateResolverRule_603074(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateResolverRule_603073(path: JsonNode; query: JsonNode;
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
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "Route53Resolver.AssociateResolverRule"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_AssociateResolverRule_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a resolver rule with a VPC. When you associate a rule with a VPC, Resolver forwards all DNS queries for the domain name that is specified in the rule and that originate in the VPC. The queries are forwarded to the IP addresses for the DNS resolvers that are specified in the rule. For more information about rules, see <a>CreateResolverRule</a>. 
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_AssociateResolverRule_603072; body: JsonNode): Recallable =
  ## associateResolverRule
  ## Associates a resolver rule with a VPC. When you associate a rule with a VPC, Resolver forwards all DNS queries for the domain name that is specified in the rule and that originate in the VPC. The queries are forwarded to the IP addresses for the DNS resolvers that are specified in the rule. For more information about rules, see <a>CreateResolverRule</a>. 
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var associateResolverRule* = Call_AssociateResolverRule_603072(
    name: "associateResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.AssociateResolverRule",
    validator: validate_AssociateResolverRule_603073, base: "/",
    url: url_AssociateResolverRule_603074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolverEndpoint_603087 = ref object of OpenApiRestCall_602466
proc url_CreateResolverEndpoint_603089(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateResolverEndpoint_603088(path: JsonNode; query: JsonNode;
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "Route53Resolver.CreateResolverEndpoint"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_CreateResolverEndpoint_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a resolver endpoint. There are two types of resolver endpoints, inbound and outbound:</p> <ul> <li> <p>An <i>inbound resolver endpoint</i> forwards DNS queries to the DNS service for a VPC from your network or another VPC.</p> </li> <li> <p>An <i>outbound resolver endpoint</i> forwards DNS queries from the DNS service for a VPC to your network or another VPC.</p> </li> </ul>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_CreateResolverEndpoint_603087; body: JsonNode): Recallable =
  ## createResolverEndpoint
  ## <p>Creates a resolver endpoint. There are two types of resolver endpoints, inbound and outbound:</p> <ul> <li> <p>An <i>inbound resolver endpoint</i> forwards DNS queries to the DNS service for a VPC from your network or another VPC.</p> </li> <li> <p>An <i>outbound resolver endpoint</i> forwards DNS queries from the DNS service for a VPC to your network or another VPC.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var createResolverEndpoint* = Call_CreateResolverEndpoint_603087(
    name: "createResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.CreateResolverEndpoint",
    validator: validate_CreateResolverEndpoint_603088, base: "/",
    url: url_CreateResolverEndpoint_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolverRule_603102 = ref object of OpenApiRestCall_602466
proc url_CreateResolverRule_603104(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateResolverRule_603103(path: JsonNode; query: JsonNode;
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
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "Route53Resolver.CreateResolverRule"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_CreateResolverRule_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For DNS queries that originate in your VPCs, specifies which resolver endpoint the queries pass through, one domain name that you want to forward to your network, and the IP addresses of the DNS resolvers in your network.
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CreateResolverRule_603102; body: JsonNode): Recallable =
  ## createResolverRule
  ## For DNS queries that originate in your VPCs, specifies which resolver endpoint the queries pass through, one domain name that you want to forward to your network, and the IP addresses of the DNS resolvers in your network.
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var createResolverRule* = Call_CreateResolverRule_603102(
    name: "createResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.CreateResolverRule",
    validator: validate_CreateResolverRule_603103, base: "/",
    url: url_CreateResolverRule_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolverEndpoint_603117 = ref object of OpenApiRestCall_602466
proc url_DeleteResolverEndpoint_603119(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteResolverEndpoint_603118(path: JsonNode; query: JsonNode;
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
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "Route53Resolver.DeleteResolverEndpoint"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_DeleteResolverEndpoint_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a resolver endpoint. The effect of deleting a resolver endpoint depends on whether it's an inbound or an outbound resolver endpoint:</p> <ul> <li> <p> <b>Inbound</b>: DNS queries from your network or another VPC are no longer routed to the DNS service for the specified VPC.</p> </li> <li> <p> <b>Outbound</b>: DNS queries from a VPC are no longer routed to your network or to another VPC.</p> </li> </ul>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_DeleteResolverEndpoint_603117; body: JsonNode): Recallable =
  ## deleteResolverEndpoint
  ## <p>Deletes a resolver endpoint. The effect of deleting a resolver endpoint depends on whether it's an inbound or an outbound resolver endpoint:</p> <ul> <li> <p> <b>Inbound</b>: DNS queries from your network or another VPC are no longer routed to the DNS service for the specified VPC.</p> </li> <li> <p> <b>Outbound</b>: DNS queries from a VPC are no longer routed to your network or to another VPC.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var deleteResolverEndpoint* = Call_DeleteResolverEndpoint_603117(
    name: "deleteResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.DeleteResolverEndpoint",
    validator: validate_DeleteResolverEndpoint_603118, base: "/",
    url: url_DeleteResolverEndpoint_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolverRule_603132 = ref object of OpenApiRestCall_602466
proc url_DeleteResolverRule_603134(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteResolverRule_603133(path: JsonNode; query: JsonNode;
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
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "Route53Resolver.DeleteResolverRule"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_DeleteResolverRule_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a resolver rule. Before you can delete a resolver rule, you must disassociate it from all the VPCs that you associated the resolver rule with. For more infomation, see <a>DisassociateResolverRule</a>.
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_DeleteResolverRule_603132; body: JsonNode): Recallable =
  ## deleteResolverRule
  ## Deletes a resolver rule. Before you can delete a resolver rule, you must disassociate it from all the VPCs that you associated the resolver rule with. For more infomation, see <a>DisassociateResolverRule</a>.
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var deleteResolverRule* = Call_DeleteResolverRule_603132(
    name: "deleteResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.DeleteResolverRule",
    validator: validate_DeleteResolverRule_603133, base: "/",
    url: url_DeleteResolverRule_603134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResolverEndpointIpAddress_603147 = ref object of OpenApiRestCall_602466
proc url_DisassociateResolverEndpointIpAddress_603149(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateResolverEndpointIpAddress_603148(path: JsonNode;
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
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "Route53Resolver.DisassociateResolverEndpointIpAddress"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_DisassociateResolverEndpointIpAddress_603147;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes IP addresses from an inbound or an outbound resolver endpoint. If you want to remove more than one IP address, submit one <code>DisassociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To add an IP address to an endpoint, see <a>AssociateResolverEndpointIpAddress</a>.</p>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_DisassociateResolverEndpointIpAddress_603147;
          body: JsonNode): Recallable =
  ## disassociateResolverEndpointIpAddress
  ## <p>Removes IP addresses from an inbound or an outbound resolver endpoint. If you want to remove more than one IP address, submit one <code>DisassociateResolverEndpointIpAddress</code> request for each IP address.</p> <p>To add an IP address to an endpoint, see <a>AssociateResolverEndpointIpAddress</a>.</p>
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var disassociateResolverEndpointIpAddress* = Call_DisassociateResolverEndpointIpAddress_603147(
    name: "disassociateResolverEndpointIpAddress", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com", route: "/#X-Amz-Target=Route53Resolver.DisassociateResolverEndpointIpAddress",
    validator: validate_DisassociateResolverEndpointIpAddress_603148, base: "/",
    url: url_DisassociateResolverEndpointIpAddress_603149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResolverRule_603162 = ref object of OpenApiRestCall_602466
proc url_DisassociateResolverRule_603164(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateResolverRule_603163(path: JsonNode; query: JsonNode;
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
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "Route53Resolver.DisassociateResolverRule"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_DisassociateResolverRule_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the association between a specified resolver rule and a specified VPC.</p> <important> <p>If you disassociate a resolver rule from a VPC, Resolver stops forwarding DNS queries for the domain name that you specified in the resolver rule. </p> </important>
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_DisassociateResolverRule_603162; body: JsonNode): Recallable =
  ## disassociateResolverRule
  ## <p>Removes the association between a specified resolver rule and a specified VPC.</p> <important> <p>If you disassociate a resolver rule from a VPC, Resolver stops forwarding DNS queries for the domain name that you specified in the resolver rule. </p> </important>
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var disassociateResolverRule* = Call_DisassociateResolverRule_603162(
    name: "disassociateResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.DisassociateResolverRule",
    validator: validate_DisassociateResolverRule_603163, base: "/",
    url: url_DisassociateResolverRule_603164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverEndpoint_603177 = ref object of OpenApiRestCall_602466
proc url_GetResolverEndpoint_603179(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResolverEndpoint_603178(path: JsonNode; query: JsonNode;
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "Route53Resolver.GetResolverEndpoint"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_GetResolverEndpoint_603177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified resolver endpoint, such as whether it's an inbound or an outbound resolver endpoint, and the current status of the endpoint.
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_GetResolverEndpoint_603177; body: JsonNode): Recallable =
  ## getResolverEndpoint
  ## Gets information about a specified resolver endpoint, such as whether it's an inbound or an outbound resolver endpoint, and the current status of the endpoint.
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var getResolverEndpoint* = Call_GetResolverEndpoint_603177(
    name: "getResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverEndpoint",
    validator: validate_GetResolverEndpoint_603178, base: "/",
    url: url_GetResolverEndpoint_603179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverRule_603192 = ref object of OpenApiRestCall_602466
proc url_GetResolverRule_603194(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResolverRule_603193(path: JsonNode; query: JsonNode;
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "Route53Resolver.GetResolverRule"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_GetResolverRule_603192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified resolver rule, such as the domain name that the rule forwards DNS queries for and the ID of the outbound resolver endpoint that the rule is associated with.
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_GetResolverRule_603192; body: JsonNode): Recallable =
  ## getResolverRule
  ## Gets information about a specified resolver rule, such as the domain name that the rule forwards DNS queries for and the ID of the outbound resolver endpoint that the rule is associated with.
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var getResolverRule* = Call_GetResolverRule_603192(name: "getResolverRule",
    meth: HttpMethod.HttpPost, host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverRule",
    validator: validate_GetResolverRule_603193, base: "/", url: url_GetResolverRule_603194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverRuleAssociation_603207 = ref object of OpenApiRestCall_602466
proc url_GetResolverRuleAssociation_603209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResolverRuleAssociation_603208(path: JsonNode; query: JsonNode;
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
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "Route53Resolver.GetResolverRuleAssociation"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_GetResolverRuleAssociation_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an association between a specified resolver rule and a VPC. You associate a resolver rule and a VPC using <a>AssociateResolverRule</a>. 
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_GetResolverRuleAssociation_603207; body: JsonNode): Recallable =
  ## getResolverRuleAssociation
  ## Gets information about an association between a specified resolver rule and a VPC. You associate a resolver rule and a VPC using <a>AssociateResolverRule</a>. 
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var getResolverRuleAssociation* = Call_GetResolverRuleAssociation_603207(
    name: "getResolverRuleAssociation", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverRuleAssociation",
    validator: validate_GetResolverRuleAssociation_603208, base: "/",
    url: url_GetResolverRuleAssociation_603209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolverRulePolicy_603222 = ref object of OpenApiRestCall_602466
proc url_GetResolverRulePolicy_603224(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResolverRulePolicy_603223(path: JsonNode; query: JsonNode;
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
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "Route53Resolver.GetResolverRulePolicy"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_GetResolverRulePolicy_603222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a resolver rule policy. A resolver rule policy specifies the Resolver operations and resources that you want to allow another AWS account to be able to use. 
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_GetResolverRulePolicy_603222; body: JsonNode): Recallable =
  ## getResolverRulePolicy
  ## Gets information about a resolver rule policy. A resolver rule policy specifies the Resolver operations and resources that you want to allow another AWS account to be able to use. 
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var getResolverRulePolicy* = Call_GetResolverRulePolicy_603222(
    name: "getResolverRulePolicy", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.GetResolverRulePolicy",
    validator: validate_GetResolverRulePolicy_603223, base: "/",
    url: url_GetResolverRulePolicy_603224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverEndpointIpAddresses_603237 = ref object of OpenApiRestCall_602466
proc url_ListResolverEndpointIpAddresses_603239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResolverEndpointIpAddresses_603238(path: JsonNode;
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
  var valid_603240 = query.getOrDefault("NextToken")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "NextToken", valid_603240
  var valid_603241 = query.getOrDefault("MaxResults")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "MaxResults", valid_603241
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
  var valid_603242 = header.getOrDefault("X-Amz-Date")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Date", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Security-Token")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Security-Token", valid_603243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603244 = header.getOrDefault("X-Amz-Target")
  valid_603244 = validateParameter(valid_603244, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverEndpointIpAddresses"))
  if valid_603244 != nil:
    section.add "X-Amz-Target", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Content-Sha256", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Algorithm")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Algorithm", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Signature")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Signature", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-SignedHeaders", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Credential")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Credential", valid_603249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603251: Call_ListResolverEndpointIpAddresses_603237;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the IP addresses for a specified resolver endpoint.
  ## 
  let valid = call_603251.validator(path, query, header, formData, body)
  let scheme = call_603251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603251.url(scheme.get, call_603251.host, call_603251.base,
                         call_603251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603251, url, valid)

proc call*(call_603252: Call_ListResolverEndpointIpAddresses_603237;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResolverEndpointIpAddresses
  ## Gets the IP addresses for a specified resolver endpoint.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603253 = newJObject()
  var body_603254 = newJObject()
  add(query_603253, "NextToken", newJString(NextToken))
  if body != nil:
    body_603254 = body
  add(query_603253, "MaxResults", newJString(MaxResults))
  result = call_603252.call(nil, query_603253, nil, nil, body_603254)

var listResolverEndpointIpAddresses* = Call_ListResolverEndpointIpAddresses_603237(
    name: "listResolverEndpointIpAddresses", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverEndpointIpAddresses",
    validator: validate_ListResolverEndpointIpAddresses_603238, base: "/",
    url: url_ListResolverEndpointIpAddresses_603239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverEndpoints_603256 = ref object of OpenApiRestCall_602466
proc url_ListResolverEndpoints_603258(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResolverEndpoints_603257(path: JsonNode; query: JsonNode;
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
  var valid_603259 = query.getOrDefault("NextToken")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "NextToken", valid_603259
  var valid_603260 = query.getOrDefault("MaxResults")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "MaxResults", valid_603260
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
  var valid_603261 = header.getOrDefault("X-Amz-Date")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Date", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Security-Token")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Security-Token", valid_603262
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603263 = header.getOrDefault("X-Amz-Target")
  valid_603263 = validateParameter(valid_603263, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverEndpoints"))
  if valid_603263 != nil:
    section.add "X-Amz-Target", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Content-Sha256", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Algorithm")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Algorithm", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Signature")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Signature", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-SignedHeaders", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Credential")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Credential", valid_603268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603270: Call_ListResolverEndpoints_603256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the resolver endpoints that were created using the current AWS account.
  ## 
  let valid = call_603270.validator(path, query, header, formData, body)
  let scheme = call_603270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603270.url(scheme.get, call_603270.host, call_603270.base,
                         call_603270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603270, url, valid)

proc call*(call_603271: Call_ListResolverEndpoints_603256; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResolverEndpoints
  ## Lists all the resolver endpoints that were created using the current AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603272 = newJObject()
  var body_603273 = newJObject()
  add(query_603272, "NextToken", newJString(NextToken))
  if body != nil:
    body_603273 = body
  add(query_603272, "MaxResults", newJString(MaxResults))
  result = call_603271.call(nil, query_603272, nil, nil, body_603273)

var listResolverEndpoints* = Call_ListResolverEndpoints_603256(
    name: "listResolverEndpoints", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverEndpoints",
    validator: validate_ListResolverEndpoints_603257, base: "/",
    url: url_ListResolverEndpoints_603258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverRuleAssociations_603274 = ref object of OpenApiRestCall_602466
proc url_ListResolverRuleAssociations_603276(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResolverRuleAssociations_603275(path: JsonNode; query: JsonNode;
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
  var valid_603277 = query.getOrDefault("NextToken")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "NextToken", valid_603277
  var valid_603278 = query.getOrDefault("MaxResults")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "MaxResults", valid_603278
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
  var valid_603279 = header.getOrDefault("X-Amz-Date")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Date", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Security-Token")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Security-Token", valid_603280
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603281 = header.getOrDefault("X-Amz-Target")
  valid_603281 = validateParameter(valid_603281, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverRuleAssociations"))
  if valid_603281 != nil:
    section.add "X-Amz-Target", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Content-Sha256", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Algorithm")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Algorithm", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Signature")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Signature", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-SignedHeaders", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Credential")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Credential", valid_603286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603288: Call_ListResolverRuleAssociations_603274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the associations that were created between resolver rules and VPCs using the current AWS account.
  ## 
  let valid = call_603288.validator(path, query, header, formData, body)
  let scheme = call_603288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603288.url(scheme.get, call_603288.host, call_603288.base,
                         call_603288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603288, url, valid)

proc call*(call_603289: Call_ListResolverRuleAssociations_603274; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResolverRuleAssociations
  ## Lists the associations that were created between resolver rules and VPCs using the current AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603290 = newJObject()
  var body_603291 = newJObject()
  add(query_603290, "NextToken", newJString(NextToken))
  if body != nil:
    body_603291 = body
  add(query_603290, "MaxResults", newJString(MaxResults))
  result = call_603289.call(nil, query_603290, nil, nil, body_603291)

var listResolverRuleAssociations* = Call_ListResolverRuleAssociations_603274(
    name: "listResolverRuleAssociations", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverRuleAssociations",
    validator: validate_ListResolverRuleAssociations_603275, base: "/",
    url: url_ListResolverRuleAssociations_603276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolverRules_603292 = ref object of OpenApiRestCall_602466
proc url_ListResolverRules_603294(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResolverRules_603293(path: JsonNode; query: JsonNode;
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
  var valid_603295 = query.getOrDefault("NextToken")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "NextToken", valid_603295
  var valid_603296 = query.getOrDefault("MaxResults")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "MaxResults", valid_603296
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
  var valid_603297 = header.getOrDefault("X-Amz-Date")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Date", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Security-Token")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Security-Token", valid_603298
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603299 = header.getOrDefault("X-Amz-Target")
  valid_603299 = validateParameter(valid_603299, JString, required = true, default = newJString(
      "Route53Resolver.ListResolverRules"))
  if valid_603299 != nil:
    section.add "X-Amz-Target", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Content-Sha256", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Algorithm")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Algorithm", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Signature")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Signature", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-SignedHeaders", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Credential")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Credential", valid_603304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603306: Call_ListResolverRules_603292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resolver rules that were created using the current AWS account.
  ## 
  let valid = call_603306.validator(path, query, header, formData, body)
  let scheme = call_603306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603306.url(scheme.get, call_603306.host, call_603306.base,
                         call_603306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603306, url, valid)

proc call*(call_603307: Call_ListResolverRules_603292; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listResolverRules
  ## Lists the resolver rules that were created using the current AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603308 = newJObject()
  var body_603309 = newJObject()
  add(query_603308, "NextToken", newJString(NextToken))
  if body != nil:
    body_603309 = body
  add(query_603308, "MaxResults", newJString(MaxResults))
  result = call_603307.call(nil, query_603308, nil, nil, body_603309)

var listResolverRules* = Call_ListResolverRules_603292(name: "listResolverRules",
    meth: HttpMethod.HttpPost, host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListResolverRules",
    validator: validate_ListResolverRules_603293, base: "/",
    url: url_ListResolverRules_603294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603310 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603312(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_603311(path: JsonNode; query: JsonNode;
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
  var valid_603313 = header.getOrDefault("X-Amz-Date")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Date", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Security-Token")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Security-Token", valid_603314
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603315 = header.getOrDefault("X-Amz-Target")
  valid_603315 = validateParameter(valid_603315, JString, required = true, default = newJString(
      "Route53Resolver.ListTagsForResource"))
  if valid_603315 != nil:
    section.add "X-Amz-Target", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Content-Sha256", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Algorithm")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Algorithm", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Signature")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Signature", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-SignedHeaders", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Credential")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Credential", valid_603320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603322: Call_ListTagsForResource_603310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags that you associated with the specified resource.
  ## 
  let valid = call_603322.validator(path, query, header, formData, body)
  let scheme = call_603322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603322.url(scheme.get, call_603322.host, call_603322.base,
                         call_603322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603322, url, valid)

proc call*(call_603323: Call_ListTagsForResource_603310; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags that you associated with the specified resource.
  ##   body: JObject (required)
  var body_603324 = newJObject()
  if body != nil:
    body_603324 = body
  result = call_603323.call(nil, nil, nil, nil, body_603324)

var listTagsForResource* = Call_ListTagsForResource_603310(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.ListTagsForResource",
    validator: validate_ListTagsForResource_603311, base: "/",
    url: url_ListTagsForResource_603312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResolverRulePolicy_603325 = ref object of OpenApiRestCall_602466
proc url_PutResolverRulePolicy_603327(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutResolverRulePolicy_603326(path: JsonNode; query: JsonNode;
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
  var valid_603328 = header.getOrDefault("X-Amz-Date")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Date", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Security-Token")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Security-Token", valid_603329
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603330 = header.getOrDefault("X-Amz-Target")
  valid_603330 = validateParameter(valid_603330, JString, required = true, default = newJString(
      "Route53Resolver.PutResolverRulePolicy"))
  if valid_603330 != nil:
    section.add "X-Amz-Target", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Content-Sha256", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Algorithm")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Algorithm", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Signature")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Signature", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-SignedHeaders", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Credential")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Credential", valid_603335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603337: Call_PutResolverRulePolicy_603325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Specifies the Resolver operations and resources that you want to allow another AWS account to be able to use.
  ## 
  let valid = call_603337.validator(path, query, header, formData, body)
  let scheme = call_603337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603337.url(scheme.get, call_603337.host, call_603337.base,
                         call_603337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603337, url, valid)

proc call*(call_603338: Call_PutResolverRulePolicy_603325; body: JsonNode): Recallable =
  ## putResolverRulePolicy
  ## Specifies the Resolver operations and resources that you want to allow another AWS account to be able to use.
  ##   body: JObject (required)
  var body_603339 = newJObject()
  if body != nil:
    body_603339 = body
  result = call_603338.call(nil, nil, nil, nil, body_603339)

var putResolverRulePolicy* = Call_PutResolverRulePolicy_603325(
    name: "putResolverRulePolicy", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.PutResolverRulePolicy",
    validator: validate_PutResolverRulePolicy_603326, base: "/",
    url: url_PutResolverRulePolicy_603327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603340 = ref object of OpenApiRestCall_602466
proc url_TagResource_603342(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_603341(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603343 = header.getOrDefault("X-Amz-Date")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Date", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Security-Token")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Security-Token", valid_603344
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603345 = header.getOrDefault("X-Amz-Target")
  valid_603345 = validateParameter(valid_603345, JString, required = true, default = newJString(
      "Route53Resolver.TagResource"))
  if valid_603345 != nil:
    section.add "X-Amz-Target", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Content-Sha256", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Algorithm")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Algorithm", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Signature")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Signature", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-SignedHeaders", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Credential")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Credential", valid_603350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603352: Call_TagResource_603340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a specified resource.
  ## 
  let valid = call_603352.validator(path, query, header, formData, body)
  let scheme = call_603352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603352.url(scheme.get, call_603352.host, call_603352.base,
                         call_603352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603352, url, valid)

proc call*(call_603353: Call_TagResource_603340; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a specified resource.
  ##   body: JObject (required)
  var body_603354 = newJObject()
  if body != nil:
    body_603354 = body
  result = call_603353.call(nil, nil, nil, nil, body_603354)

var tagResource* = Call_TagResource_603340(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "route53resolver.amazonaws.com", route: "/#X-Amz-Target=Route53Resolver.TagResource",
                                        validator: validate_TagResource_603341,
                                        base: "/", url: url_TagResource_603342,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603355 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603357(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_603356(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603358 = header.getOrDefault("X-Amz-Date")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Date", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Security-Token")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Security-Token", valid_603359
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603360 = header.getOrDefault("X-Amz-Target")
  valid_603360 = validateParameter(valid_603360, JString, required = true, default = newJString(
      "Route53Resolver.UntagResource"))
  if valid_603360 != nil:
    section.add "X-Amz-Target", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Content-Sha256", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Algorithm")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Algorithm", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Signature")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Signature", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-SignedHeaders", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Credential")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Credential", valid_603365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603367: Call_UntagResource_603355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a specified resource.
  ## 
  let valid = call_603367.validator(path, query, header, formData, body)
  let scheme = call_603367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603367.url(scheme.get, call_603367.host, call_603367.base,
                         call_603367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603367, url, valid)

proc call*(call_603368: Call_UntagResource_603355; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a specified resource.
  ##   body: JObject (required)
  var body_603369 = newJObject()
  if body != nil:
    body_603369 = body
  result = call_603368.call(nil, nil, nil, nil, body_603369)

var untagResource* = Call_UntagResource_603355(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.UntagResource",
    validator: validate_UntagResource_603356, base: "/", url: url_UntagResource_603357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolverEndpoint_603370 = ref object of OpenApiRestCall_602466
proc url_UpdateResolverEndpoint_603372(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateResolverEndpoint_603371(path: JsonNode; query: JsonNode;
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
  var valid_603373 = header.getOrDefault("X-Amz-Date")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Date", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Security-Token")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Security-Token", valid_603374
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603375 = header.getOrDefault("X-Amz-Target")
  valid_603375 = validateParameter(valid_603375, JString, required = true, default = newJString(
      "Route53Resolver.UpdateResolverEndpoint"))
  if valid_603375 != nil:
    section.add "X-Amz-Target", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Content-Sha256", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Algorithm")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Algorithm", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Signature")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Signature", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-SignedHeaders", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Credential")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Credential", valid_603380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603382: Call_UpdateResolverEndpoint_603370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name of an inbound or an outbound resolver endpoint. 
  ## 
  let valid = call_603382.validator(path, query, header, formData, body)
  let scheme = call_603382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603382.url(scheme.get, call_603382.host, call_603382.base,
                         call_603382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603382, url, valid)

proc call*(call_603383: Call_UpdateResolverEndpoint_603370; body: JsonNode): Recallable =
  ## updateResolverEndpoint
  ## Updates the name of an inbound or an outbound resolver endpoint. 
  ##   body: JObject (required)
  var body_603384 = newJObject()
  if body != nil:
    body_603384 = body
  result = call_603383.call(nil, nil, nil, nil, body_603384)

var updateResolverEndpoint* = Call_UpdateResolverEndpoint_603370(
    name: "updateResolverEndpoint", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.UpdateResolverEndpoint",
    validator: validate_UpdateResolverEndpoint_603371, base: "/",
    url: url_UpdateResolverEndpoint_603372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolverRule_603385 = ref object of OpenApiRestCall_602466
proc url_UpdateResolverRule_603387(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateResolverRule_603386(path: JsonNode; query: JsonNode;
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
  var valid_603388 = header.getOrDefault("X-Amz-Date")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Date", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Security-Token")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Security-Token", valid_603389
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603390 = header.getOrDefault("X-Amz-Target")
  valid_603390 = validateParameter(valid_603390, JString, required = true, default = newJString(
      "Route53Resolver.UpdateResolverRule"))
  if valid_603390 != nil:
    section.add "X-Amz-Target", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Content-Sha256", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Algorithm")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Algorithm", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Signature")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Signature", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-SignedHeaders", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Credential")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Credential", valid_603395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603397: Call_UpdateResolverRule_603385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates settings for a specified resolver rule. <code>ResolverRuleId</code> is required, and all other parameters are optional. If you don't specify a parameter, it retains its current value.
  ## 
  let valid = call_603397.validator(path, query, header, formData, body)
  let scheme = call_603397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603397.url(scheme.get, call_603397.host, call_603397.base,
                         call_603397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603397, url, valid)

proc call*(call_603398: Call_UpdateResolverRule_603385; body: JsonNode): Recallable =
  ## updateResolverRule
  ## Updates settings for a specified resolver rule. <code>ResolverRuleId</code> is required, and all other parameters are optional. If you don't specify a parameter, it retains its current value.
  ##   body: JObject (required)
  var body_603399 = newJObject()
  if body != nil:
    body_603399 = body
  result = call_603398.call(nil, nil, nil, nil, body_603399)

var updateResolverRule* = Call_UpdateResolverRule_603385(
    name: "updateResolverRule", meth: HttpMethod.HttpPost,
    host: "route53resolver.amazonaws.com",
    route: "/#X-Amz-Target=Route53Resolver.UpdateResolverRule",
    validator: validate_UpdateResolverRule_603386, base: "/",
    url: url_UpdateResolverRule_603387, schemes: {Scheme.Https, Scheme.Http})
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
