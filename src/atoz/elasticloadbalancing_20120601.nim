
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Elastic Load Balancing
## version: 2012-06-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Elastic Load Balancing</fullname> <p>A load balancer can distribute incoming traffic across your EC2 instances. This enables you to increase the availability of your application. The load balancer also monitors the health of its registered instances and ensures that it routes traffic only to healthy instances. You configure your load balancer to accept incoming traffic by specifying one or more listeners, which are configured with a protocol and port number for connections from clients to the load balancer and a protocol and port number for connections from the load balancer to the instances.</p> <p>Elastic Load Balancing supports three types of load balancers: Application Load Balancers, Network Load Balancers, and Classic Load Balancers. You can select a load balancer based on your application needs. For more information, see the <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/">Elastic Load Balancing User Guide</a>.</p> <p>This reference covers the 2012-06-01 API, which supports Classic Load Balancers. The 2015-12-01 API supports Application Load Balancers and Network Load Balancers.</p> <p>To get started, create a load balancer with one or more listeners using <a>CreateLoadBalancer</a>. Register your instances with the load balancer using <a>RegisterInstancesWithLoadBalancer</a>.</p> <p>All Elastic Load Balancing operations are <i>idempotent</i>, which means that they complete at most one time. If you repeat an operation, it succeeds with a 200 OK response code.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/elasticloadbalancing/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "elasticloadbalancing.ap-northeast-1.amazonaws.com", "ap-southeast-1": "elasticloadbalancing.ap-southeast-1.amazonaws.com", "us-west-2": "elasticloadbalancing.us-west-2.amazonaws.com", "eu-west-2": "elasticloadbalancing.eu-west-2.amazonaws.com", "ap-northeast-3": "elasticloadbalancing.ap-northeast-3.amazonaws.com", "eu-central-1": "elasticloadbalancing.eu-central-1.amazonaws.com", "us-east-2": "elasticloadbalancing.us-east-2.amazonaws.com", "us-east-1": "elasticloadbalancing.us-east-1.amazonaws.com", "cn-northwest-1": "elasticloadbalancing.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "elasticloadbalancing.ap-south-1.amazonaws.com", "eu-north-1": "elasticloadbalancing.eu-north-1.amazonaws.com", "ap-northeast-2": "elasticloadbalancing.ap-northeast-2.amazonaws.com", "us-west-1": "elasticloadbalancing.us-west-1.amazonaws.com", "us-gov-east-1": "elasticloadbalancing.us-gov-east-1.amazonaws.com", "eu-west-3": "elasticloadbalancing.eu-west-3.amazonaws.com", "cn-north-1": "elasticloadbalancing.cn-north-1.amazonaws.com.cn", "sa-east-1": "elasticloadbalancing.sa-east-1.amazonaws.com", "eu-west-1": "elasticloadbalancing.eu-west-1.amazonaws.com", "us-gov-west-1": "elasticloadbalancing.us-gov-west-1.amazonaws.com", "ap-southeast-2": "elasticloadbalancing.ap-southeast-2.amazonaws.com", "ca-central-1": "elasticloadbalancing.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "elasticloadbalancing.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "elasticloadbalancing.ap-southeast-1.amazonaws.com",
      "us-west-2": "elasticloadbalancing.us-west-2.amazonaws.com",
      "eu-west-2": "elasticloadbalancing.eu-west-2.amazonaws.com",
      "ap-northeast-3": "elasticloadbalancing.ap-northeast-3.amazonaws.com",
      "eu-central-1": "elasticloadbalancing.eu-central-1.amazonaws.com",
      "us-east-2": "elasticloadbalancing.us-east-2.amazonaws.com",
      "us-east-1": "elasticloadbalancing.us-east-1.amazonaws.com",
      "cn-northwest-1": "elasticloadbalancing.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "elasticloadbalancing.ap-south-1.amazonaws.com",
      "eu-north-1": "elasticloadbalancing.eu-north-1.amazonaws.com",
      "ap-northeast-2": "elasticloadbalancing.ap-northeast-2.amazonaws.com",
      "us-west-1": "elasticloadbalancing.us-west-1.amazonaws.com",
      "us-gov-east-1": "elasticloadbalancing.us-gov-east-1.amazonaws.com",
      "eu-west-3": "elasticloadbalancing.eu-west-3.amazonaws.com",
      "cn-north-1": "elasticloadbalancing.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "elasticloadbalancing.sa-east-1.amazonaws.com",
      "eu-west-1": "elasticloadbalancing.eu-west-1.amazonaws.com",
      "us-gov-west-1": "elasticloadbalancing.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "elasticloadbalancing.ap-southeast-2.amazonaws.com",
      "ca-central-1": "elasticloadbalancing.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "elasticloadbalancing"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddTags_606199 = ref object of OpenApiRestCall_605589
proc url_PostAddTags_606201(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTags_606200(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606202 = query.getOrDefault("Action")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_606202 != nil:
    section.add "Action", valid_606202
  var valid_606203 = query.getOrDefault("Version")
  valid_606203 = validateParameter(valid_606203, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606203 != nil:
    section.add "Version", valid_606203
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
  var valid_606204 = header.getOrDefault("X-Amz-Signature")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Signature", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Content-Sha256", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Date")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Date", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Credential")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Credential", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Security-Token")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Security-Token", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Algorithm")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Algorithm", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-SignedHeaders", valid_606210
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Tags: JArray (required)
  ##       : The tags.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_606211 = formData.getOrDefault("LoadBalancerNames")
  valid_606211 = validateParameter(valid_606211, JArray, required = true, default = nil)
  if valid_606211 != nil:
    section.add "LoadBalancerNames", valid_606211
  var valid_606212 = formData.getOrDefault("Tags")
  valid_606212 = validateParameter(valid_606212, JArray, required = true, default = nil)
  if valid_606212 != nil:
    section.add "Tags", valid_606212
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606213: Call_PostAddTags_606199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606213.validator(path, query, header, formData, body)
  let scheme = call_606213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606213.url(scheme.get, call_606213.host, call_606213.base,
                         call_606213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606213, url, valid)

proc call*(call_606214: Call_PostAddTags_606199; LoadBalancerNames: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2012-06-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   Version: string (required)
  var query_606215 = newJObject()
  var formData_606216 = newJObject()
  if LoadBalancerNames != nil:
    formData_606216.add "LoadBalancerNames", LoadBalancerNames
  add(query_606215, "Action", newJString(Action))
  if Tags != nil:
    formData_606216.add "Tags", Tags
  add(query_606215, "Version", newJString(Version))
  result = call_606214.call(nil, query_606215, nil, formData_606216, nil)

var postAddTags* = Call_PostAddTags_606199(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_606200,
                                        base: "/", url: url_PostAddTags_606201,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_605927 = ref object of OpenApiRestCall_605589
proc url_GetAddTags_605929(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTags_605928(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_606041 = query.getOrDefault("Tags")
  valid_606041 = validateParameter(valid_606041, JArray, required = true, default = nil)
  if valid_606041 != nil:
    section.add "Tags", valid_606041
  var valid_606055 = query.getOrDefault("Action")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_606055 != nil:
    section.add "Action", valid_606055
  var valid_606056 = query.getOrDefault("Version")
  valid_606056 = validateParameter(valid_606056, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606056 != nil:
    section.add "Version", valid_606056
  var valid_606057 = query.getOrDefault("LoadBalancerNames")
  valid_606057 = validateParameter(valid_606057, JArray, required = true, default = nil)
  if valid_606057 != nil:
    section.add "LoadBalancerNames", valid_606057
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
  var valid_606058 = header.getOrDefault("X-Amz-Signature")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Signature", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Content-Sha256", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Date")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Date", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Credential")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Credential", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Security-Token")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Security-Token", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-Algorithm")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-Algorithm", valid_606063
  var valid_606064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606064 = validateParameter(valid_606064, JString, required = false,
                                 default = nil)
  if valid_606064 != nil:
    section.add "X-Amz-SignedHeaders", valid_606064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606087: Call_GetAddTags_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606087.validator(path, query, header, formData, body)
  let scheme = call_606087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606087.url(scheme.get, call_606087.host, call_606087.base,
                         call_606087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606087, url, valid)

proc call*(call_606158: Call_GetAddTags_605927; Tags: JsonNode;
          LoadBalancerNames: JsonNode; Action: string = "AddTags";
          Version: string = "2012-06-01"): Recallable =
  ## getAddTags
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  var query_606159 = newJObject()
  if Tags != nil:
    query_606159.add "Tags", Tags
  add(query_606159, "Action", newJString(Action))
  add(query_606159, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_606159.add "LoadBalancerNames", LoadBalancerNames
  result = call_606158.call(nil, query_606159, nil, nil, nil)

var getAddTags* = Call_GetAddTags_605927(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_605928,
                                      base: "/", url: url_GetAddTags_605929,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplySecurityGroupsToLoadBalancer_606234 = ref object of OpenApiRestCall_605589
proc url_PostApplySecurityGroupsToLoadBalancer_606236(protocol: Scheme;
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

proc validate_PostApplySecurityGroupsToLoadBalancer_606235(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606237 = query.getOrDefault("Action")
  valid_606237 = validateParameter(valid_606237, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_606237 != nil:
    section.add "Action", valid_606237
  var valid_606238 = query.getOrDefault("Version")
  valid_606238 = validateParameter(valid_606238, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606238 != nil:
    section.add "Version", valid_606238
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
  var valid_606239 = header.getOrDefault("X-Amz-Signature")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Signature", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Content-Sha256", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Date")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Date", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Credential")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Credential", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Security-Token")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Security-Token", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Algorithm")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Algorithm", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-SignedHeaders", valid_606245
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_606246 = formData.getOrDefault("SecurityGroups")
  valid_606246 = validateParameter(valid_606246, JArray, required = true, default = nil)
  if valid_606246 != nil:
    section.add "SecurityGroups", valid_606246
  var valid_606247 = formData.getOrDefault("LoadBalancerName")
  valid_606247 = validateParameter(valid_606247, JString, required = true,
                                 default = nil)
  if valid_606247 != nil:
    section.add "LoadBalancerName", valid_606247
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606248: Call_PostApplySecurityGroupsToLoadBalancer_606234;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606248.validator(path, query, header, formData, body)
  let scheme = call_606248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606248.url(scheme.get, call_606248.host, call_606248.base,
                         call_606248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606248, url, valid)

proc call*(call_606249: Call_PostApplySecurityGroupsToLoadBalancer_606234;
          SecurityGroups: JsonNode; LoadBalancerName: string;
          Action: string = "ApplySecurityGroupsToLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postApplySecurityGroupsToLoadBalancer
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606250 = newJObject()
  var formData_606251 = newJObject()
  if SecurityGroups != nil:
    formData_606251.add "SecurityGroups", SecurityGroups
  add(formData_606251, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606250, "Action", newJString(Action))
  add(query_606250, "Version", newJString(Version))
  result = call_606249.call(nil, query_606250, nil, formData_606251, nil)

var postApplySecurityGroupsToLoadBalancer* = Call_PostApplySecurityGroupsToLoadBalancer_606234(
    name: "postApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_PostApplySecurityGroupsToLoadBalancer_606235, base: "/",
    url: url_PostApplySecurityGroupsToLoadBalancer_606236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplySecurityGroupsToLoadBalancer_606217 = ref object of OpenApiRestCall_605589
proc url_GetApplySecurityGroupsToLoadBalancer_606219(protocol: Scheme;
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

proc validate_GetApplySecurityGroupsToLoadBalancer_606218(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SecurityGroups` field"
  var valid_606220 = query.getOrDefault("SecurityGroups")
  valid_606220 = validateParameter(valid_606220, JArray, required = true, default = nil)
  if valid_606220 != nil:
    section.add "SecurityGroups", valid_606220
  var valid_606221 = query.getOrDefault("LoadBalancerName")
  valid_606221 = validateParameter(valid_606221, JString, required = true,
                                 default = nil)
  if valid_606221 != nil:
    section.add "LoadBalancerName", valid_606221
  var valid_606222 = query.getOrDefault("Action")
  valid_606222 = validateParameter(valid_606222, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_606222 != nil:
    section.add "Action", valid_606222
  var valid_606223 = query.getOrDefault("Version")
  valid_606223 = validateParameter(valid_606223, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606223 != nil:
    section.add "Version", valid_606223
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
  var valid_606224 = header.getOrDefault("X-Amz-Signature")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Signature", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Content-Sha256", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Date")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Date", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Credential")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Credential", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Security-Token")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Security-Token", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Algorithm")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Algorithm", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-SignedHeaders", valid_606230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606231: Call_GetApplySecurityGroupsToLoadBalancer_606217;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606231.validator(path, query, header, formData, body)
  let scheme = call_606231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606231.url(scheme.get, call_606231.host, call_606231.base,
                         call_606231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606231, url, valid)

proc call*(call_606232: Call_GetApplySecurityGroupsToLoadBalancer_606217;
          SecurityGroups: JsonNode; LoadBalancerName: string;
          Action: string = "ApplySecurityGroupsToLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getApplySecurityGroupsToLoadBalancer
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606233 = newJObject()
  if SecurityGroups != nil:
    query_606233.add "SecurityGroups", SecurityGroups
  add(query_606233, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606233, "Action", newJString(Action))
  add(query_606233, "Version", newJString(Version))
  result = call_606232.call(nil, query_606233, nil, nil, nil)

var getApplySecurityGroupsToLoadBalancer* = Call_GetApplySecurityGroupsToLoadBalancer_606217(
    name: "getApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_GetApplySecurityGroupsToLoadBalancer_606218, base: "/",
    url: url_GetApplySecurityGroupsToLoadBalancer_606219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAttachLoadBalancerToSubnets_606269 = ref object of OpenApiRestCall_605589
proc url_PostAttachLoadBalancerToSubnets_606271(protocol: Scheme; host: string;
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

proc validate_PostAttachLoadBalancerToSubnets_606270(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606272 = query.getOrDefault("Action")
  valid_606272 = validateParameter(valid_606272, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_606272 != nil:
    section.add "Action", valid_606272
  var valid_606273 = query.getOrDefault("Version")
  valid_606273 = validateParameter(valid_606273, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606273 != nil:
    section.add "Version", valid_606273
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
  var valid_606274 = header.getOrDefault("X-Amz-Signature")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Signature", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Content-Sha256", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Date")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Date", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Credential")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Credential", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Security-Token")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Security-Token", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Algorithm")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Algorithm", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-SignedHeaders", valid_606280
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_606281 = formData.getOrDefault("Subnets")
  valid_606281 = validateParameter(valid_606281, JArray, required = true, default = nil)
  if valid_606281 != nil:
    section.add "Subnets", valid_606281
  var valid_606282 = formData.getOrDefault("LoadBalancerName")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = nil)
  if valid_606282 != nil:
    section.add "LoadBalancerName", valid_606282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_PostAttachLoadBalancerToSubnets_606269;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_PostAttachLoadBalancerToSubnets_606269;
          Subnets: JsonNode; LoadBalancerName: string;
          Action: string = "AttachLoadBalancerToSubnets";
          Version: string = "2012-06-01"): Recallable =
  ## postAttachLoadBalancerToSubnets
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606285 = newJObject()
  var formData_606286 = newJObject()
  if Subnets != nil:
    formData_606286.add "Subnets", Subnets
  add(formData_606286, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606285, "Action", newJString(Action))
  add(query_606285, "Version", newJString(Version))
  result = call_606284.call(nil, query_606285, nil, formData_606286, nil)

var postAttachLoadBalancerToSubnets* = Call_PostAttachLoadBalancerToSubnets_606269(
    name: "postAttachLoadBalancerToSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_PostAttachLoadBalancerToSubnets_606270, base: "/",
    url: url_PostAttachLoadBalancerToSubnets_606271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttachLoadBalancerToSubnets_606252 = ref object of OpenApiRestCall_605589
proc url_GetAttachLoadBalancerToSubnets_606254(protocol: Scheme; host: string;
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

proc validate_GetAttachLoadBalancerToSubnets_606253(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_606255 = query.getOrDefault("LoadBalancerName")
  valid_606255 = validateParameter(valid_606255, JString, required = true,
                                 default = nil)
  if valid_606255 != nil:
    section.add "LoadBalancerName", valid_606255
  var valid_606256 = query.getOrDefault("Action")
  valid_606256 = validateParameter(valid_606256, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_606256 != nil:
    section.add "Action", valid_606256
  var valid_606257 = query.getOrDefault("Subnets")
  valid_606257 = validateParameter(valid_606257, JArray, required = true, default = nil)
  if valid_606257 != nil:
    section.add "Subnets", valid_606257
  var valid_606258 = query.getOrDefault("Version")
  valid_606258 = validateParameter(valid_606258, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606258 != nil:
    section.add "Version", valid_606258
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
  var valid_606259 = header.getOrDefault("X-Amz-Signature")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Signature", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Content-Sha256", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Date")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Date", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Credential")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Credential", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Security-Token")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Security-Token", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Algorithm")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Algorithm", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-SignedHeaders", valid_606265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606266: Call_GetAttachLoadBalancerToSubnets_606252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606266.validator(path, query, header, formData, body)
  let scheme = call_606266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606266.url(scheme.get, call_606266.host, call_606266.base,
                         call_606266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606266, url, valid)

proc call*(call_606267: Call_GetAttachLoadBalancerToSubnets_606252;
          LoadBalancerName: string; Subnets: JsonNode;
          Action: string = "AttachLoadBalancerToSubnets";
          Version: string = "2012-06-01"): Recallable =
  ## getAttachLoadBalancerToSubnets
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   Version: string (required)
  var query_606268 = newJObject()
  add(query_606268, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606268, "Action", newJString(Action))
  if Subnets != nil:
    query_606268.add "Subnets", Subnets
  add(query_606268, "Version", newJString(Version))
  result = call_606267.call(nil, query_606268, nil, nil, nil)

var getAttachLoadBalancerToSubnets* = Call_GetAttachLoadBalancerToSubnets_606252(
    name: "getAttachLoadBalancerToSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_GetAttachLoadBalancerToSubnets_606253, base: "/",
    url: url_GetAttachLoadBalancerToSubnets_606254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfigureHealthCheck_606308 = ref object of OpenApiRestCall_605589
proc url_PostConfigureHealthCheck_606310(protocol: Scheme; host: string;
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

proc validate_PostConfigureHealthCheck_606309(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606311 = query.getOrDefault("Action")
  valid_606311 = validateParameter(valid_606311, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_606311 != nil:
    section.add "Action", valid_606311
  var valid_606312 = query.getOrDefault("Version")
  valid_606312 = validateParameter(valid_606312, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606312 != nil:
    section.add "Version", valid_606312
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
  var valid_606313 = header.getOrDefault("X-Amz-Signature")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Signature", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Content-Sha256", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Date")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Date", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Credential")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Credential", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Security-Token")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Security-Token", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Algorithm")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Algorithm", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-SignedHeaders", valid_606319
  result.add "header", section
  ## parameters in `formData` object:
  ##   HealthCheck.Interval: JString
  ##                       : Information about a health check.
  ## The approximate interval, in seconds, between health checks of an individual instance.
  ##   HealthCheck.HealthyThreshold: JString
  ##                               : Information about a health check.
  ## The number of consecutive health checks successes required before moving the instance to the <code>Healthy</code> state.
  ##   HealthCheck.Timeout: JString
  ##                      : Information about a health check.
  ## <p>The amount of time, in seconds, during which no response means a failed health check.</p> <p>This value must be less than the <code>Interval</code> value.</p>
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   HealthCheck.Target: JString
  ##                     : Information about a health check.
  ## <p>The instance being checked. The protocol is either TCP, HTTP, HTTPS, or SSL. The range of valid ports is one (1) through 65535.</p> <p>TCP is the default, specified as a TCP: port pair, for example "TCP:5000". In this case, a health check simply attempts to open a TCP connection to the instance on the specified port. Failure to connect within the configured timeout is considered unhealthy.</p> <p>SSL is also specified as SSL: port pair, for example, SSL:5000.</p> <p>For HTTP/HTTPS, you must include a ping path in the string. HTTP is specified as a HTTP:port;/;PathToPing; grouping, for example "HTTP:80/weather/us/wa/seattle". In this case, a HTTP GET request is issued to the instance on the given port and path. Any answer other than "200 OK" within the timeout period is considered unhealthy.</p> <p>The total length of the HTTP ping target must be 1024 16-bit Unicode characters or less.</p>
  ##   HealthCheck.UnhealthyThreshold: JString
  ##                                 : Information about a health check.
  ## The number of consecutive health check failures required before moving the instance to the <code>Unhealthy</code> state.
  section = newJObject()
  var valid_606320 = formData.getOrDefault("HealthCheck.Interval")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "HealthCheck.Interval", valid_606320
  var valid_606321 = formData.getOrDefault("HealthCheck.HealthyThreshold")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_606321
  var valid_606322 = formData.getOrDefault("HealthCheck.Timeout")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "HealthCheck.Timeout", valid_606322
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_606323 = formData.getOrDefault("LoadBalancerName")
  valid_606323 = validateParameter(valid_606323, JString, required = true,
                                 default = nil)
  if valid_606323 != nil:
    section.add "LoadBalancerName", valid_606323
  var valid_606324 = formData.getOrDefault("HealthCheck.Target")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "HealthCheck.Target", valid_606324
  var valid_606325 = formData.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_606325
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606326: Call_PostConfigureHealthCheck_606308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606326.validator(path, query, header, formData, body)
  let scheme = call_606326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606326.url(scheme.get, call_606326.host, call_606326.base,
                         call_606326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606326, url, valid)

proc call*(call_606327: Call_PostConfigureHealthCheck_606308;
          LoadBalancerName: string; HealthCheckInterval: string = "";
          HealthCheckHealthyThreshold: string = ""; HealthCheckTimeout: string = "";
          Action: string = "ConfigureHealthCheck"; HealthCheckTarget: string = "";
          Version: string = "2012-06-01"; HealthCheckUnhealthyThreshold: string = ""): Recallable =
  ## postConfigureHealthCheck
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   HealthCheckInterval: string
  ##                      : Information about a health check.
  ## The approximate interval, in seconds, between health checks of an individual instance.
  ##   HealthCheckHealthyThreshold: string
  ##                              : Information about a health check.
  ## The number of consecutive health checks successes required before moving the instance to the <code>Healthy</code> state.
  ##   HealthCheckTimeout: string
  ##                     : Information about a health check.
  ## <p>The amount of time, in seconds, during which no response means a failed health check.</p> <p>This value must be less than the <code>Interval</code> value.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   HealthCheckTarget: string
  ##                    : Information about a health check.
  ## <p>The instance being checked. The protocol is either TCP, HTTP, HTTPS, or SSL. The range of valid ports is one (1) through 65535.</p> <p>TCP is the default, specified as a TCP: port pair, for example "TCP:5000". In this case, a health check simply attempts to open a TCP connection to the instance on the specified port. Failure to connect within the configured timeout is considered unhealthy.</p> <p>SSL is also specified as SSL: port pair, for example, SSL:5000.</p> <p>For HTTP/HTTPS, you must include a ping path in the string. HTTP is specified as a HTTP:port;/;PathToPing; grouping, for example "HTTP:80/weather/us/wa/seattle". In this case, a HTTP GET request is issued to the instance on the given port and path. Any answer other than "200 OK" within the timeout period is considered unhealthy.</p> <p>The total length of the HTTP ping target must be 1024 16-bit Unicode characters or less.</p>
  ##   Version: string (required)
  ##   HealthCheckUnhealthyThreshold: string
  ##                                : Information about a health check.
  ## The number of consecutive health check failures required before moving the instance to the <code>Unhealthy</code> state.
  var query_606328 = newJObject()
  var formData_606329 = newJObject()
  add(formData_606329, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(formData_606329, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(formData_606329, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(formData_606329, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606328, "Action", newJString(Action))
  add(formData_606329, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_606328, "Version", newJString(Version))
  add(formData_606329, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  result = call_606327.call(nil, query_606328, nil, formData_606329, nil)

var postConfigureHealthCheck* = Call_PostConfigureHealthCheck_606308(
    name: "postConfigureHealthCheck", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_PostConfigureHealthCheck_606309, base: "/",
    url: url_PostConfigureHealthCheck_606310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigureHealthCheck_606287 = ref object of OpenApiRestCall_605589
proc url_GetConfigureHealthCheck_606289(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetConfigureHealthCheck_606288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   HealthCheck.Interval: JString
  ##                       : Information about a health check.
  ## The approximate interval, in seconds, between health checks of an individual instance.
  ##   HealthCheck.UnhealthyThreshold: JString
  ##                                 : Information about a health check.
  ## The number of consecutive health check failures required before moving the instance to the <code>Unhealthy</code> state.
  ##   HealthCheck.Timeout: JString
  ##                      : Information about a health check.
  ## <p>The amount of time, in seconds, during which no response means a failed health check.</p> <p>This value must be less than the <code>Interval</code> value.</p>
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   HealthCheck.Target: JString
  ##                     : Information about a health check.
  ## <p>The instance being checked. The protocol is either TCP, HTTP, HTTPS, or SSL. The range of valid ports is one (1) through 65535.</p> <p>TCP is the default, specified as a TCP: port pair, for example "TCP:5000". In this case, a health check simply attempts to open a TCP connection to the instance on the specified port. Failure to connect within the configured timeout is considered unhealthy.</p> <p>SSL is also specified as SSL: port pair, for example, SSL:5000.</p> <p>For HTTP/HTTPS, you must include a ping path in the string. HTTP is specified as a HTTP:port;/;PathToPing; grouping, for example "HTTP:80/weather/us/wa/seattle". In this case, a HTTP GET request is issued to the instance on the given port and path. Any answer other than "200 OK" within the timeout period is considered unhealthy.</p> <p>The total length of the HTTP ping target must be 1024 16-bit Unicode characters or less.</p>
  ##   HealthCheck.HealthyThreshold: JString
  ##                               : Information about a health check.
  ## The number of consecutive health checks successes required before moving the instance to the <code>Healthy</code> state.
  ##   Version: JString (required)
  section = newJObject()
  var valid_606290 = query.getOrDefault("HealthCheck.Interval")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "HealthCheck.Interval", valid_606290
  var valid_606291 = query.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_606291
  var valid_606292 = query.getOrDefault("HealthCheck.Timeout")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "HealthCheck.Timeout", valid_606292
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_606293 = query.getOrDefault("LoadBalancerName")
  valid_606293 = validateParameter(valid_606293, JString, required = true,
                                 default = nil)
  if valid_606293 != nil:
    section.add "LoadBalancerName", valid_606293
  var valid_606294 = query.getOrDefault("Action")
  valid_606294 = validateParameter(valid_606294, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_606294 != nil:
    section.add "Action", valid_606294
  var valid_606295 = query.getOrDefault("HealthCheck.Target")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "HealthCheck.Target", valid_606295
  var valid_606296 = query.getOrDefault("HealthCheck.HealthyThreshold")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_606296
  var valid_606297 = query.getOrDefault("Version")
  valid_606297 = validateParameter(valid_606297, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606297 != nil:
    section.add "Version", valid_606297
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
  var valid_606298 = header.getOrDefault("X-Amz-Signature")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Signature", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Content-Sha256", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Date")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Date", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Credential")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Credential", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Security-Token")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Security-Token", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Algorithm")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Algorithm", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-SignedHeaders", valid_606304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606305: Call_GetConfigureHealthCheck_606287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606305.validator(path, query, header, formData, body)
  let scheme = call_606305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606305.url(scheme.get, call_606305.host, call_606305.base,
                         call_606305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606305, url, valid)

proc call*(call_606306: Call_GetConfigureHealthCheck_606287;
          LoadBalancerName: string; HealthCheckInterval: string = "";
          HealthCheckUnhealthyThreshold: string = "";
          HealthCheckTimeout: string = ""; Action: string = "ConfigureHealthCheck";
          HealthCheckTarget: string = ""; HealthCheckHealthyThreshold: string = "";
          Version: string = "2012-06-01"): Recallable =
  ## getConfigureHealthCheck
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   HealthCheckInterval: string
  ##                      : Information about a health check.
  ## The approximate interval, in seconds, between health checks of an individual instance.
  ##   HealthCheckUnhealthyThreshold: string
  ##                                : Information about a health check.
  ## The number of consecutive health check failures required before moving the instance to the <code>Unhealthy</code> state.
  ##   HealthCheckTimeout: string
  ##                     : Information about a health check.
  ## <p>The amount of time, in seconds, during which no response means a failed health check.</p> <p>This value must be less than the <code>Interval</code> value.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   HealthCheckTarget: string
  ##                    : Information about a health check.
  ## <p>The instance being checked. The protocol is either TCP, HTTP, HTTPS, or SSL. The range of valid ports is one (1) through 65535.</p> <p>TCP is the default, specified as a TCP: port pair, for example "TCP:5000". In this case, a health check simply attempts to open a TCP connection to the instance on the specified port. Failure to connect within the configured timeout is considered unhealthy.</p> <p>SSL is also specified as SSL: port pair, for example, SSL:5000.</p> <p>For HTTP/HTTPS, you must include a ping path in the string. HTTP is specified as a HTTP:port;/;PathToPing; grouping, for example "HTTP:80/weather/us/wa/seattle". In this case, a HTTP GET request is issued to the instance on the given port and path. Any answer other than "200 OK" within the timeout period is considered unhealthy.</p> <p>The total length of the HTTP ping target must be 1024 16-bit Unicode characters or less.</p>
  ##   HealthCheckHealthyThreshold: string
  ##                              : Information about a health check.
  ## The number of consecutive health checks successes required before moving the instance to the <code>Healthy</code> state.
  ##   Version: string (required)
  var query_606307 = newJObject()
  add(query_606307, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(query_606307, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(query_606307, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_606307, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606307, "Action", newJString(Action))
  add(query_606307, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_606307, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(query_606307, "Version", newJString(Version))
  result = call_606306.call(nil, query_606307, nil, nil, nil)

var getConfigureHealthCheck* = Call_GetConfigureHealthCheck_606287(
    name: "getConfigureHealthCheck", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_GetConfigureHealthCheck_606288, base: "/",
    url: url_GetConfigureHealthCheck_606289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateAppCookieStickinessPolicy_606348 = ref object of OpenApiRestCall_605589
proc url_PostCreateAppCookieStickinessPolicy_606350(protocol: Scheme; host: string;
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

proc validate_PostCreateAppCookieStickinessPolicy_606349(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606351 = query.getOrDefault("Action")
  valid_606351 = validateParameter(valid_606351, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_606351 != nil:
    section.add "Action", valid_606351
  var valid_606352 = query.getOrDefault("Version")
  valid_606352 = validateParameter(valid_606352, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606352 != nil:
    section.add "Version", valid_606352
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
  var valid_606353 = header.getOrDefault("X-Amz-Signature")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Signature", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Content-Sha256", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Date")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Date", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Credential")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Credential", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Security-Token")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Security-Token", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Algorithm")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Algorithm", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-SignedHeaders", valid_606359
  result.add "header", section
  ## parameters in `formData` object:
  ##   CookieName: JString (required)
  ##             : The name of the application cookie used for stickiness.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CookieName` field"
  var valid_606360 = formData.getOrDefault("CookieName")
  valid_606360 = validateParameter(valid_606360, JString, required = true,
                                 default = nil)
  if valid_606360 != nil:
    section.add "CookieName", valid_606360
  var valid_606361 = formData.getOrDefault("LoadBalancerName")
  valid_606361 = validateParameter(valid_606361, JString, required = true,
                                 default = nil)
  if valid_606361 != nil:
    section.add "LoadBalancerName", valid_606361
  var valid_606362 = formData.getOrDefault("PolicyName")
  valid_606362 = validateParameter(valid_606362, JString, required = true,
                                 default = nil)
  if valid_606362 != nil:
    section.add "PolicyName", valid_606362
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606363: Call_PostCreateAppCookieStickinessPolicy_606348;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606363.validator(path, query, header, formData, body)
  let scheme = call_606363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606363.url(scheme.get, call_606363.host, call_606363.base,
                         call_606363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606363, url, valid)

proc call*(call_606364: Call_PostCreateAppCookieStickinessPolicy_606348;
          CookieName: string; LoadBalancerName: string; PolicyName: string;
          Action: string = "CreateAppCookieStickinessPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## postCreateAppCookieStickinessPolicy
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   CookieName: string (required)
  ##             : The name of the application cookie used for stickiness.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PolicyName: string (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  var query_606365 = newJObject()
  var formData_606366 = newJObject()
  add(formData_606366, "CookieName", newJString(CookieName))
  add(formData_606366, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606365, "Action", newJString(Action))
  add(query_606365, "Version", newJString(Version))
  add(formData_606366, "PolicyName", newJString(PolicyName))
  result = call_606364.call(nil, query_606365, nil, formData_606366, nil)

var postCreateAppCookieStickinessPolicy* = Call_PostCreateAppCookieStickinessPolicy_606348(
    name: "postCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_PostCreateAppCookieStickinessPolicy_606349, base: "/",
    url: url_PostCreateAppCookieStickinessPolicy_606350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateAppCookieStickinessPolicy_606330 = ref object of OpenApiRestCall_605589
proc url_GetCreateAppCookieStickinessPolicy_606332(protocol: Scheme; host: string;
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

proc validate_GetCreateAppCookieStickinessPolicy_606331(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  ##   CookieName: JString (required)
  ##             : The name of the application cookie used for stickiness.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `PolicyName` field"
  var valid_606333 = query.getOrDefault("PolicyName")
  valid_606333 = validateParameter(valid_606333, JString, required = true,
                                 default = nil)
  if valid_606333 != nil:
    section.add "PolicyName", valid_606333
  var valid_606334 = query.getOrDefault("CookieName")
  valid_606334 = validateParameter(valid_606334, JString, required = true,
                                 default = nil)
  if valid_606334 != nil:
    section.add "CookieName", valid_606334
  var valid_606335 = query.getOrDefault("LoadBalancerName")
  valid_606335 = validateParameter(valid_606335, JString, required = true,
                                 default = nil)
  if valid_606335 != nil:
    section.add "LoadBalancerName", valid_606335
  var valid_606336 = query.getOrDefault("Action")
  valid_606336 = validateParameter(valid_606336, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_606336 != nil:
    section.add "Action", valid_606336
  var valid_606337 = query.getOrDefault("Version")
  valid_606337 = validateParameter(valid_606337, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606337 != nil:
    section.add "Version", valid_606337
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
  var valid_606338 = header.getOrDefault("X-Amz-Signature")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Signature", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Content-Sha256", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Date")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Date", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Credential")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Credential", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Security-Token")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Security-Token", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Algorithm")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Algorithm", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-SignedHeaders", valid_606344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606345: Call_GetCreateAppCookieStickinessPolicy_606330;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606345.validator(path, query, header, formData, body)
  let scheme = call_606345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606345.url(scheme.get, call_606345.host, call_606345.base,
                         call_606345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606345, url, valid)

proc call*(call_606346: Call_GetCreateAppCookieStickinessPolicy_606330;
          PolicyName: string; CookieName: string; LoadBalancerName: string;
          Action: string = "CreateAppCookieStickinessPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## getCreateAppCookieStickinessPolicy
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   PolicyName: string (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  ##   CookieName: string (required)
  ##             : The name of the application cookie used for stickiness.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606347 = newJObject()
  add(query_606347, "PolicyName", newJString(PolicyName))
  add(query_606347, "CookieName", newJString(CookieName))
  add(query_606347, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606347, "Action", newJString(Action))
  add(query_606347, "Version", newJString(Version))
  result = call_606346.call(nil, query_606347, nil, nil, nil)

var getCreateAppCookieStickinessPolicy* = Call_GetCreateAppCookieStickinessPolicy_606330(
    name: "getCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_GetCreateAppCookieStickinessPolicy_606331, base: "/",
    url: url_GetCreateAppCookieStickinessPolicy_606332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLBCookieStickinessPolicy_606385 = ref object of OpenApiRestCall_605589
proc url_PostCreateLBCookieStickinessPolicy_606387(protocol: Scheme; host: string;
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

proc validate_PostCreateLBCookieStickinessPolicy_606386(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606388 = query.getOrDefault("Action")
  valid_606388 = validateParameter(valid_606388, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_606388 != nil:
    section.add "Action", valid_606388
  var valid_606389 = query.getOrDefault("Version")
  valid_606389 = validateParameter(valid_606389, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606389 != nil:
    section.add "Version", valid_606389
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
  var valid_606390 = header.getOrDefault("X-Amz-Signature")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Signature", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Content-Sha256", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Date")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Date", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Credential")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Credential", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Security-Token")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Security-Token", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Algorithm")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Algorithm", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-SignedHeaders", valid_606396
  result.add "header", section
  ## parameters in `formData` object:
  ##   CookieExpirationPeriod: JInt
  ##                         : The time period, in seconds, after which the cookie should be considered stale. If you do not specify this parameter, the default value is 0, which indicates that the sticky session should last for the duration of the browser session.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  section = newJObject()
  var valid_606397 = formData.getOrDefault("CookieExpirationPeriod")
  valid_606397 = validateParameter(valid_606397, JInt, required = false, default = nil)
  if valid_606397 != nil:
    section.add "CookieExpirationPeriod", valid_606397
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_606398 = formData.getOrDefault("LoadBalancerName")
  valid_606398 = validateParameter(valid_606398, JString, required = true,
                                 default = nil)
  if valid_606398 != nil:
    section.add "LoadBalancerName", valid_606398
  var valid_606399 = formData.getOrDefault("PolicyName")
  valid_606399 = validateParameter(valid_606399, JString, required = true,
                                 default = nil)
  if valid_606399 != nil:
    section.add "PolicyName", valid_606399
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606400: Call_PostCreateLBCookieStickinessPolicy_606385;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606400.validator(path, query, header, formData, body)
  let scheme = call_606400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606400.url(scheme.get, call_606400.host, call_606400.base,
                         call_606400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606400, url, valid)

proc call*(call_606401: Call_PostCreateLBCookieStickinessPolicy_606385;
          LoadBalancerName: string; PolicyName: string;
          CookieExpirationPeriod: int = 0;
          Action: string = "CreateLBCookieStickinessPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## postCreateLBCookieStickinessPolicy
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   CookieExpirationPeriod: int
  ##                         : The time period, in seconds, after which the cookie should be considered stale. If you do not specify this parameter, the default value is 0, which indicates that the sticky session should last for the duration of the browser session.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PolicyName: string (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  var query_606402 = newJObject()
  var formData_606403 = newJObject()
  add(formData_606403, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(formData_606403, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606402, "Action", newJString(Action))
  add(query_606402, "Version", newJString(Version))
  add(formData_606403, "PolicyName", newJString(PolicyName))
  result = call_606401.call(nil, query_606402, nil, formData_606403, nil)

var postCreateLBCookieStickinessPolicy* = Call_PostCreateLBCookieStickinessPolicy_606385(
    name: "postCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_PostCreateLBCookieStickinessPolicy_606386, base: "/",
    url: url_PostCreateLBCookieStickinessPolicy_606387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLBCookieStickinessPolicy_606367 = ref object of OpenApiRestCall_605589
proc url_GetCreateLBCookieStickinessPolicy_606369(protocol: Scheme; host: string;
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

proc validate_GetCreateLBCookieStickinessPolicy_606368(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CookieExpirationPeriod: JInt
  ##                         : The time period, in seconds, after which the cookie should be considered stale. If you do not specify this parameter, the default value is 0, which indicates that the sticky session should last for the duration of the browser session.
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606370 = query.getOrDefault("CookieExpirationPeriod")
  valid_606370 = validateParameter(valid_606370, JInt, required = false, default = nil)
  if valid_606370 != nil:
    section.add "CookieExpirationPeriod", valid_606370
  assert query != nil,
        "query argument is necessary due to required `PolicyName` field"
  var valid_606371 = query.getOrDefault("PolicyName")
  valid_606371 = validateParameter(valid_606371, JString, required = true,
                                 default = nil)
  if valid_606371 != nil:
    section.add "PolicyName", valid_606371
  var valid_606372 = query.getOrDefault("LoadBalancerName")
  valid_606372 = validateParameter(valid_606372, JString, required = true,
                                 default = nil)
  if valid_606372 != nil:
    section.add "LoadBalancerName", valid_606372
  var valid_606373 = query.getOrDefault("Action")
  valid_606373 = validateParameter(valid_606373, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_606373 != nil:
    section.add "Action", valid_606373
  var valid_606374 = query.getOrDefault("Version")
  valid_606374 = validateParameter(valid_606374, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606374 != nil:
    section.add "Version", valid_606374
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
  var valid_606375 = header.getOrDefault("X-Amz-Signature")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Signature", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Content-Sha256", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Date")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Date", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Credential")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Credential", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Security-Token")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Security-Token", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Algorithm")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Algorithm", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-SignedHeaders", valid_606381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606382: Call_GetCreateLBCookieStickinessPolicy_606367;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606382.validator(path, query, header, formData, body)
  let scheme = call_606382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606382.url(scheme.get, call_606382.host, call_606382.base,
                         call_606382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606382, url, valid)

proc call*(call_606383: Call_GetCreateLBCookieStickinessPolicy_606367;
          PolicyName: string; LoadBalancerName: string;
          CookieExpirationPeriod: int = 0;
          Action: string = "CreateLBCookieStickinessPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## getCreateLBCookieStickinessPolicy
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   CookieExpirationPeriod: int
  ##                         : The time period, in seconds, after which the cookie should be considered stale. If you do not specify this parameter, the default value is 0, which indicates that the sticky session should last for the duration of the browser session.
  ##   PolicyName: string (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606384 = newJObject()
  add(query_606384, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(query_606384, "PolicyName", newJString(PolicyName))
  add(query_606384, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606384, "Action", newJString(Action))
  add(query_606384, "Version", newJString(Version))
  result = call_606383.call(nil, query_606384, nil, nil, nil)

var getCreateLBCookieStickinessPolicy* = Call_GetCreateLBCookieStickinessPolicy_606367(
    name: "getCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_GetCreateLBCookieStickinessPolicy_606368, base: "/",
    url: url_GetCreateLBCookieStickinessPolicy_606369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_606426 = ref object of OpenApiRestCall_605589
proc url_PostCreateLoadBalancer_606428(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateLoadBalancer_606427(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606429 = query.getOrDefault("Action")
  valid_606429 = validateParameter(valid_606429, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_606429 != nil:
    section.add "Action", valid_606429
  var valid_606430 = query.getOrDefault("Version")
  valid_606430 = validateParameter(valid_606430, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606430 != nil:
    section.add "Version", valid_606430
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
  var valid_606431 = header.getOrDefault("X-Amz-Signature")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Signature", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Content-Sha256", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Date")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Date", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Credential")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Credential", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Security-Token")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Security-Token", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Algorithm")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Algorithm", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-SignedHeaders", valid_606437
  result.add "header", section
  ## parameters in `formData` object:
  ##   Scheme: JString
  ##         : <p>The type of a load balancer. Valid only for load balancers in a VPC.</p> <p>By default, Elastic Load Balancing creates an Internet-facing load balancer with a DNS name that resolves to public IP addresses. For more information about Internet-facing and Internal load balancers, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html#load-balancer-scheme">Load Balancer Scheme</a> in the <i>Elastic Load Balancing User Guide</i>.</p> <p>Specify <code>internal</code> to create a load balancer with a DNS name that resolves to private IP addresses.</p>
  ##   SecurityGroups: JArray
  ##                 : The IDs of the security groups to assign to the load balancer.
  ##   AvailabilityZones: JArray
  ##                    : <p>One or more Availability Zones from the same region as the load balancer.</p> <p>You must specify at least one Availability Zone.</p> <p>You can add more Availability Zones after you create the load balancer using <a>EnableAvailabilityZonesForLoadBalancer</a>.</p>
  ##   Subnets: JArray
  ##          : The IDs of the subnets in your VPC to attach to the load balancer. Specify one subnet per Availability Zone specified in <code>AvailabilityZones</code>.
  ##   LoadBalancerName: JString (required)
  ##                   : <p>The name of the load balancer.</p> <p>This name must be unique within your set of load balancers for the region, must have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and cannot begin or end with a hyphen.</p>
  ##   Listeners: JArray (required)
  ##            : <p>The listeners.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Tags: JArray
  ##       : <p>A list of tags to assign to the load balancer.</p> <p>For more information about tagging your load balancer, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  section = newJObject()
  var valid_606438 = formData.getOrDefault("Scheme")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "Scheme", valid_606438
  var valid_606439 = formData.getOrDefault("SecurityGroups")
  valid_606439 = validateParameter(valid_606439, JArray, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "SecurityGroups", valid_606439
  var valid_606440 = formData.getOrDefault("AvailabilityZones")
  valid_606440 = validateParameter(valid_606440, JArray, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "AvailabilityZones", valid_606440
  var valid_606441 = formData.getOrDefault("Subnets")
  valid_606441 = validateParameter(valid_606441, JArray, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "Subnets", valid_606441
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_606442 = formData.getOrDefault("LoadBalancerName")
  valid_606442 = validateParameter(valid_606442, JString, required = true,
                                 default = nil)
  if valid_606442 != nil:
    section.add "LoadBalancerName", valid_606442
  var valid_606443 = formData.getOrDefault("Listeners")
  valid_606443 = validateParameter(valid_606443, JArray, required = true, default = nil)
  if valid_606443 != nil:
    section.add "Listeners", valid_606443
  var valid_606444 = formData.getOrDefault("Tags")
  valid_606444 = validateParameter(valid_606444, JArray, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "Tags", valid_606444
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606445: Call_PostCreateLoadBalancer_606426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606445.validator(path, query, header, formData, body)
  let scheme = call_606445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606445.url(scheme.get, call_606445.host, call_606445.base,
                         call_606445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606445, url, valid)

proc call*(call_606446: Call_PostCreateLoadBalancer_606426;
          LoadBalancerName: string; Listeners: JsonNode; Scheme: string = "";
          SecurityGroups: JsonNode = nil; AvailabilityZones: JsonNode = nil;
          Subnets: JsonNode = nil; Action: string = "CreateLoadBalancer";
          Tags: JsonNode = nil; Version: string = "2012-06-01"): Recallable =
  ## postCreateLoadBalancer
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Scheme: string
  ##         : <p>The type of a load balancer. Valid only for load balancers in a VPC.</p> <p>By default, Elastic Load Balancing creates an Internet-facing load balancer with a DNS name that resolves to public IP addresses. For more information about Internet-facing and Internal load balancers, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html#load-balancer-scheme">Load Balancer Scheme</a> in the <i>Elastic Load Balancing User Guide</i>.</p> <p>Specify <code>internal</code> to create a load balancer with a DNS name that resolves to private IP addresses.</p>
  ##   SecurityGroups: JArray
  ##                 : The IDs of the security groups to assign to the load balancer.
  ##   AvailabilityZones: JArray
  ##                    : <p>One or more Availability Zones from the same region as the load balancer.</p> <p>You must specify at least one Availability Zone.</p> <p>You can add more Availability Zones after you create the load balancer using <a>EnableAvailabilityZonesForLoadBalancer</a>.</p>
  ##   Subnets: JArray
  ##          : The IDs of the subnets in your VPC to attach to the load balancer. Specify one subnet per Availability Zone specified in <code>AvailabilityZones</code>.
  ##   LoadBalancerName: string (required)
  ##                   : <p>The name of the load balancer.</p> <p>This name must be unique within your set of load balancers for the region, must have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and cannot begin or end with a hyphen.</p>
  ##   Listeners: JArray (required)
  ##            : <p>The listeners.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : <p>A list of tags to assign to the load balancer.</p> <p>For more information about tagging your load balancer, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Version: string (required)
  var query_606447 = newJObject()
  var formData_606448 = newJObject()
  add(formData_606448, "Scheme", newJString(Scheme))
  if SecurityGroups != nil:
    formData_606448.add "SecurityGroups", SecurityGroups
  if AvailabilityZones != nil:
    formData_606448.add "AvailabilityZones", AvailabilityZones
  if Subnets != nil:
    formData_606448.add "Subnets", Subnets
  add(formData_606448, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_606448.add "Listeners", Listeners
  add(query_606447, "Action", newJString(Action))
  if Tags != nil:
    formData_606448.add "Tags", Tags
  add(query_606447, "Version", newJString(Version))
  result = call_606446.call(nil, query_606447, nil, formData_606448, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_606426(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_606427, base: "/",
    url: url_PostCreateLoadBalancer_606428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_606404 = ref object of OpenApiRestCall_605589
proc url_GetCreateLoadBalancer_606406(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateLoadBalancer_606405(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##       : <p>A list of tags to assign to the load balancer.</p> <p>For more information about tagging your load balancer, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Scheme: JString
  ##         : <p>The type of a load balancer. Valid only for load balancers in a VPC.</p> <p>By default, Elastic Load Balancing creates an Internet-facing load balancer with a DNS name that resolves to public IP addresses. For more information about Internet-facing and Internal load balancers, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html#load-balancer-scheme">Load Balancer Scheme</a> in the <i>Elastic Load Balancing User Guide</i>.</p> <p>Specify <code>internal</code> to create a load balancer with a DNS name that resolves to private IP addresses.</p>
  ##   AvailabilityZones: JArray
  ##                    : <p>One or more Availability Zones from the same region as the load balancer.</p> <p>You must specify at least one Availability Zone.</p> <p>You can add more Availability Zones after you create the load balancer using <a>EnableAvailabilityZonesForLoadBalancer</a>.</p>
  ##   Listeners: JArray (required)
  ##            : <p>The listeners.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   SecurityGroups: JArray
  ##                 : The IDs of the security groups to assign to the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : <p>The name of the load balancer.</p> <p>This name must be unique within your set of load balancers for the region, must have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and cannot begin or end with a hyphen.</p>
  ##   Action: JString (required)
  ##   Subnets: JArray
  ##          : The IDs of the subnets in your VPC to attach to the load balancer. Specify one subnet per Availability Zone specified in <code>AvailabilityZones</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_606407 = query.getOrDefault("Tags")
  valid_606407 = validateParameter(valid_606407, JArray, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "Tags", valid_606407
  var valid_606408 = query.getOrDefault("Scheme")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "Scheme", valid_606408
  var valid_606409 = query.getOrDefault("AvailabilityZones")
  valid_606409 = validateParameter(valid_606409, JArray, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "AvailabilityZones", valid_606409
  assert query != nil,
        "query argument is necessary due to required `Listeners` field"
  var valid_606410 = query.getOrDefault("Listeners")
  valid_606410 = validateParameter(valid_606410, JArray, required = true, default = nil)
  if valid_606410 != nil:
    section.add "Listeners", valid_606410
  var valid_606411 = query.getOrDefault("SecurityGroups")
  valid_606411 = validateParameter(valid_606411, JArray, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "SecurityGroups", valid_606411
  var valid_606412 = query.getOrDefault("LoadBalancerName")
  valid_606412 = validateParameter(valid_606412, JString, required = true,
                                 default = nil)
  if valid_606412 != nil:
    section.add "LoadBalancerName", valid_606412
  var valid_606413 = query.getOrDefault("Action")
  valid_606413 = validateParameter(valid_606413, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_606413 != nil:
    section.add "Action", valid_606413
  var valid_606414 = query.getOrDefault("Subnets")
  valid_606414 = validateParameter(valid_606414, JArray, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "Subnets", valid_606414
  var valid_606415 = query.getOrDefault("Version")
  valid_606415 = validateParameter(valid_606415, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606415 != nil:
    section.add "Version", valid_606415
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
  var valid_606416 = header.getOrDefault("X-Amz-Signature")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Signature", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Content-Sha256", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Date")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Date", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Credential")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Credential", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Security-Token")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Security-Token", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Algorithm")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Algorithm", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-SignedHeaders", valid_606422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606423: Call_GetCreateLoadBalancer_606404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606423.validator(path, query, header, formData, body)
  let scheme = call_606423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606423.url(scheme.get, call_606423.host, call_606423.base,
                         call_606423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606423, url, valid)

proc call*(call_606424: Call_GetCreateLoadBalancer_606404; Listeners: JsonNode;
          LoadBalancerName: string; Tags: JsonNode = nil; Scheme: string = "";
          AvailabilityZones: JsonNode = nil; SecurityGroups: JsonNode = nil;
          Action: string = "CreateLoadBalancer"; Subnets: JsonNode = nil;
          Version: string = "2012-06-01"): Recallable =
  ## getCreateLoadBalancer
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Tags: JArray
  ##       : <p>A list of tags to assign to the load balancer.</p> <p>For more information about tagging your load balancer, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Scheme: string
  ##         : <p>The type of a load balancer. Valid only for load balancers in a VPC.</p> <p>By default, Elastic Load Balancing creates an Internet-facing load balancer with a DNS name that resolves to public IP addresses. For more information about Internet-facing and Internal load balancers, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html#load-balancer-scheme">Load Balancer Scheme</a> in the <i>Elastic Load Balancing User Guide</i>.</p> <p>Specify <code>internal</code> to create a load balancer with a DNS name that resolves to private IP addresses.</p>
  ##   AvailabilityZones: JArray
  ##                    : <p>One or more Availability Zones from the same region as the load balancer.</p> <p>You must specify at least one Availability Zone.</p> <p>You can add more Availability Zones after you create the load balancer using <a>EnableAvailabilityZonesForLoadBalancer</a>.</p>
  ##   Listeners: JArray (required)
  ##            : <p>The listeners.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   SecurityGroups: JArray
  ##                 : The IDs of the security groups to assign to the load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : <p>The name of the load balancer.</p> <p>This name must be unique within your set of load balancers for the region, must have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and cannot begin or end with a hyphen.</p>
  ##   Action: string (required)
  ##   Subnets: JArray
  ##          : The IDs of the subnets in your VPC to attach to the load balancer. Specify one subnet per Availability Zone specified in <code>AvailabilityZones</code>.
  ##   Version: string (required)
  var query_606425 = newJObject()
  if Tags != nil:
    query_606425.add "Tags", Tags
  add(query_606425, "Scheme", newJString(Scheme))
  if AvailabilityZones != nil:
    query_606425.add "AvailabilityZones", AvailabilityZones
  if Listeners != nil:
    query_606425.add "Listeners", Listeners
  if SecurityGroups != nil:
    query_606425.add "SecurityGroups", SecurityGroups
  add(query_606425, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606425, "Action", newJString(Action))
  if Subnets != nil:
    query_606425.add "Subnets", Subnets
  add(query_606425, "Version", newJString(Version))
  result = call_606424.call(nil, query_606425, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_606404(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_606405, base: "/",
    url: url_GetCreateLoadBalancer_606406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerListeners_606466 = ref object of OpenApiRestCall_605589
proc url_PostCreateLoadBalancerListeners_606468(protocol: Scheme; host: string;
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

proc validate_PostCreateLoadBalancerListeners_606467(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606469 = query.getOrDefault("Action")
  valid_606469 = validateParameter(valid_606469, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_606469 != nil:
    section.add "Action", valid_606469
  var valid_606470 = query.getOrDefault("Version")
  valid_606470 = validateParameter(valid_606470, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606470 != nil:
    section.add "Version", valid_606470
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
  var valid_606471 = header.getOrDefault("X-Amz-Signature")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Signature", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Content-Sha256", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Date")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Date", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Credential")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Credential", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Security-Token")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Security-Token", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Algorithm")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Algorithm", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-SignedHeaders", valid_606477
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_606478 = formData.getOrDefault("LoadBalancerName")
  valid_606478 = validateParameter(valid_606478, JString, required = true,
                                 default = nil)
  if valid_606478 != nil:
    section.add "LoadBalancerName", valid_606478
  var valid_606479 = formData.getOrDefault("Listeners")
  valid_606479 = validateParameter(valid_606479, JArray, required = true, default = nil)
  if valid_606479 != nil:
    section.add "Listeners", valid_606479
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606480: Call_PostCreateLoadBalancerListeners_606466;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606480.validator(path, query, header, formData, body)
  let scheme = call_606480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606480.url(scheme.get, call_606480.host, call_606480.base,
                         call_606480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606480, url, valid)

proc call*(call_606481: Call_PostCreateLoadBalancerListeners_606466;
          LoadBalancerName: string; Listeners: JsonNode;
          Action: string = "CreateLoadBalancerListeners";
          Version: string = "2012-06-01"): Recallable =
  ## postCreateLoadBalancerListeners
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606482 = newJObject()
  var formData_606483 = newJObject()
  add(formData_606483, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_606483.add "Listeners", Listeners
  add(query_606482, "Action", newJString(Action))
  add(query_606482, "Version", newJString(Version))
  result = call_606481.call(nil, query_606482, nil, formData_606483, nil)

var postCreateLoadBalancerListeners* = Call_PostCreateLoadBalancerListeners_606466(
    name: "postCreateLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_PostCreateLoadBalancerListeners_606467, base: "/",
    url: url_PostCreateLoadBalancerListeners_606468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerListeners_606449 = ref object of OpenApiRestCall_605589
proc url_GetCreateLoadBalancerListeners_606451(protocol: Scheme; host: string;
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

proc validate_GetCreateLoadBalancerListeners_606450(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Listeners: JArray (required)
  ##            : The listeners.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Listeners` field"
  var valid_606452 = query.getOrDefault("Listeners")
  valid_606452 = validateParameter(valid_606452, JArray, required = true, default = nil)
  if valid_606452 != nil:
    section.add "Listeners", valid_606452
  var valid_606453 = query.getOrDefault("LoadBalancerName")
  valid_606453 = validateParameter(valid_606453, JString, required = true,
                                 default = nil)
  if valid_606453 != nil:
    section.add "LoadBalancerName", valid_606453
  var valid_606454 = query.getOrDefault("Action")
  valid_606454 = validateParameter(valid_606454, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_606454 != nil:
    section.add "Action", valid_606454
  var valid_606455 = query.getOrDefault("Version")
  valid_606455 = validateParameter(valid_606455, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606455 != nil:
    section.add "Version", valid_606455
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
  var valid_606456 = header.getOrDefault("X-Amz-Signature")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Signature", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Content-Sha256", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Date")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Date", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Credential")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Credential", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Security-Token")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Security-Token", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Algorithm")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Algorithm", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-SignedHeaders", valid_606462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_GetCreateLoadBalancerListeners_606449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_GetCreateLoadBalancerListeners_606449;
          Listeners: JsonNode; LoadBalancerName: string;
          Action: string = "CreateLoadBalancerListeners";
          Version: string = "2012-06-01"): Recallable =
  ## getCreateLoadBalancerListeners
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Listeners: JArray (required)
  ##            : The listeners.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606465 = newJObject()
  if Listeners != nil:
    query_606465.add "Listeners", Listeners
  add(query_606465, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606465, "Action", newJString(Action))
  add(query_606465, "Version", newJString(Version))
  result = call_606464.call(nil, query_606465, nil, nil, nil)

var getCreateLoadBalancerListeners* = Call_GetCreateLoadBalancerListeners_606449(
    name: "getCreateLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_GetCreateLoadBalancerListeners_606450, base: "/",
    url: url_GetCreateLoadBalancerListeners_606451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerPolicy_606503 = ref object of OpenApiRestCall_605589
proc url_PostCreateLoadBalancerPolicy_606505(protocol: Scheme; host: string;
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

proc validate_PostCreateLoadBalancerPolicy_606504(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606506 = query.getOrDefault("Action")
  valid_606506 = validateParameter(valid_606506, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_606506 != nil:
    section.add "Action", valid_606506
  var valid_606507 = query.getOrDefault("Version")
  valid_606507 = validateParameter(valid_606507, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606507 != nil:
    section.add "Version", valid_606507
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
  var valid_606508 = header.getOrDefault("X-Amz-Signature")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-Signature", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Content-Sha256", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Date")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Date", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Credential")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Credential", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Security-Token")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Security-Token", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Algorithm")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Algorithm", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-SignedHeaders", valid_606514
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyAttributes: JArray
  ##                   : The policy attributes.
  ##   PolicyTypeName: JString (required)
  ##                 : The name of the base policy type. To get the list of policy types, use <a>DescribeLoadBalancerPolicyTypes</a>.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyName: JString (required)
  ##             : The name of the load balancer policy to be created. This name must be unique within the set of policies for this load balancer.
  section = newJObject()
  var valid_606515 = formData.getOrDefault("PolicyAttributes")
  valid_606515 = validateParameter(valid_606515, JArray, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "PolicyAttributes", valid_606515
  assert formData != nil,
        "formData argument is necessary due to required `PolicyTypeName` field"
  var valid_606516 = formData.getOrDefault("PolicyTypeName")
  valid_606516 = validateParameter(valid_606516, JString, required = true,
                                 default = nil)
  if valid_606516 != nil:
    section.add "PolicyTypeName", valid_606516
  var valid_606517 = formData.getOrDefault("LoadBalancerName")
  valid_606517 = validateParameter(valid_606517, JString, required = true,
                                 default = nil)
  if valid_606517 != nil:
    section.add "LoadBalancerName", valid_606517
  var valid_606518 = formData.getOrDefault("PolicyName")
  valid_606518 = validateParameter(valid_606518, JString, required = true,
                                 default = nil)
  if valid_606518 != nil:
    section.add "PolicyName", valid_606518
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606519: Call_PostCreateLoadBalancerPolicy_606503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_606519.validator(path, query, header, formData, body)
  let scheme = call_606519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606519.url(scheme.get, call_606519.host, call_606519.base,
                         call_606519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606519, url, valid)

proc call*(call_606520: Call_PostCreateLoadBalancerPolicy_606503;
          PolicyTypeName: string; LoadBalancerName: string; PolicyName: string;
          PolicyAttributes: JsonNode = nil;
          Action: string = "CreateLoadBalancerPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## postCreateLoadBalancerPolicy
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ##   PolicyAttributes: JArray
  ##                   : The policy attributes.
  ##   PolicyTypeName: string (required)
  ##                 : The name of the base policy type. To get the list of policy types, use <a>DescribeLoadBalancerPolicyTypes</a>.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PolicyName: string (required)
  ##             : The name of the load balancer policy to be created. This name must be unique within the set of policies for this load balancer.
  var query_606521 = newJObject()
  var formData_606522 = newJObject()
  if PolicyAttributes != nil:
    formData_606522.add "PolicyAttributes", PolicyAttributes
  add(formData_606522, "PolicyTypeName", newJString(PolicyTypeName))
  add(formData_606522, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606521, "Action", newJString(Action))
  add(query_606521, "Version", newJString(Version))
  add(formData_606522, "PolicyName", newJString(PolicyName))
  result = call_606520.call(nil, query_606521, nil, formData_606522, nil)

var postCreateLoadBalancerPolicy* = Call_PostCreateLoadBalancerPolicy_606503(
    name: "postCreateLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_PostCreateLoadBalancerPolicy_606504, base: "/",
    url: url_PostCreateLoadBalancerPolicy_606505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerPolicy_606484 = ref object of OpenApiRestCall_605589
proc url_GetCreateLoadBalancerPolicy_606486(protocol: Scheme; host: string;
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

proc validate_GetCreateLoadBalancerPolicy_606485(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PolicyAttributes: JArray
  ##                   : The policy attributes.
  ##   PolicyName: JString (required)
  ##             : The name of the load balancer policy to be created. This name must be unique within the set of policies for this load balancer.
  ##   PolicyTypeName: JString (required)
  ##                 : The name of the base policy type. To get the list of policy types, use <a>DescribeLoadBalancerPolicyTypes</a>.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606487 = query.getOrDefault("PolicyAttributes")
  valid_606487 = validateParameter(valid_606487, JArray, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "PolicyAttributes", valid_606487
  assert query != nil,
        "query argument is necessary due to required `PolicyName` field"
  var valid_606488 = query.getOrDefault("PolicyName")
  valid_606488 = validateParameter(valid_606488, JString, required = true,
                                 default = nil)
  if valid_606488 != nil:
    section.add "PolicyName", valid_606488
  var valid_606489 = query.getOrDefault("PolicyTypeName")
  valid_606489 = validateParameter(valid_606489, JString, required = true,
                                 default = nil)
  if valid_606489 != nil:
    section.add "PolicyTypeName", valid_606489
  var valid_606490 = query.getOrDefault("LoadBalancerName")
  valid_606490 = validateParameter(valid_606490, JString, required = true,
                                 default = nil)
  if valid_606490 != nil:
    section.add "LoadBalancerName", valid_606490
  var valid_606491 = query.getOrDefault("Action")
  valid_606491 = validateParameter(valid_606491, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_606491 != nil:
    section.add "Action", valid_606491
  var valid_606492 = query.getOrDefault("Version")
  valid_606492 = validateParameter(valid_606492, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606492 != nil:
    section.add "Version", valid_606492
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
  var valid_606493 = header.getOrDefault("X-Amz-Signature")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Signature", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Content-Sha256", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Date")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Date", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Credential")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Credential", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Security-Token")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Security-Token", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Algorithm")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Algorithm", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-SignedHeaders", valid_606499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606500: Call_GetCreateLoadBalancerPolicy_606484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_606500.validator(path, query, header, formData, body)
  let scheme = call_606500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606500.url(scheme.get, call_606500.host, call_606500.base,
                         call_606500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606500, url, valid)

proc call*(call_606501: Call_GetCreateLoadBalancerPolicy_606484;
          PolicyName: string; PolicyTypeName: string; LoadBalancerName: string;
          PolicyAttributes: JsonNode = nil;
          Action: string = "CreateLoadBalancerPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## getCreateLoadBalancerPolicy
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ##   PolicyAttributes: JArray
  ##                   : The policy attributes.
  ##   PolicyName: string (required)
  ##             : The name of the load balancer policy to be created. This name must be unique within the set of policies for this load balancer.
  ##   PolicyTypeName: string (required)
  ##                 : The name of the base policy type. To get the list of policy types, use <a>DescribeLoadBalancerPolicyTypes</a>.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606502 = newJObject()
  if PolicyAttributes != nil:
    query_606502.add "PolicyAttributes", PolicyAttributes
  add(query_606502, "PolicyName", newJString(PolicyName))
  add(query_606502, "PolicyTypeName", newJString(PolicyTypeName))
  add(query_606502, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606502, "Action", newJString(Action))
  add(query_606502, "Version", newJString(Version))
  result = call_606501.call(nil, query_606502, nil, nil, nil)

var getCreateLoadBalancerPolicy* = Call_GetCreateLoadBalancerPolicy_606484(
    name: "getCreateLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_GetCreateLoadBalancerPolicy_606485, base: "/",
    url: url_GetCreateLoadBalancerPolicy_606486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_606539 = ref object of OpenApiRestCall_605589
proc url_PostDeleteLoadBalancer_606541(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteLoadBalancer_606540(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606542 = query.getOrDefault("Action")
  valid_606542 = validateParameter(valid_606542, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_606542 != nil:
    section.add "Action", valid_606542
  var valid_606543 = query.getOrDefault("Version")
  valid_606543 = validateParameter(valid_606543, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606543 != nil:
    section.add "Version", valid_606543
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
  var valid_606544 = header.getOrDefault("X-Amz-Signature")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Signature", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Content-Sha256", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Date")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Date", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Credential")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Credential", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Security-Token")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Security-Token", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Algorithm")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Algorithm", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-SignedHeaders", valid_606550
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_606551 = formData.getOrDefault("LoadBalancerName")
  valid_606551 = validateParameter(valid_606551, JString, required = true,
                                 default = nil)
  if valid_606551 != nil:
    section.add "LoadBalancerName", valid_606551
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606552: Call_PostDeleteLoadBalancer_606539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_606552.validator(path, query, header, formData, body)
  let scheme = call_606552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606552.url(scheme.get, call_606552.host, call_606552.base,
                         call_606552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606552, url, valid)

proc call*(call_606553: Call_PostDeleteLoadBalancer_606539;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606554 = newJObject()
  var formData_606555 = newJObject()
  add(formData_606555, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606554, "Action", newJString(Action))
  add(query_606554, "Version", newJString(Version))
  result = call_606553.call(nil, query_606554, nil, formData_606555, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_606539(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_606540, base: "/",
    url: url_PostDeleteLoadBalancer_606541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_606523 = ref object of OpenApiRestCall_605589
proc url_GetDeleteLoadBalancer_606525(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteLoadBalancer_606524(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_606526 = query.getOrDefault("LoadBalancerName")
  valid_606526 = validateParameter(valid_606526, JString, required = true,
                                 default = nil)
  if valid_606526 != nil:
    section.add "LoadBalancerName", valid_606526
  var valid_606527 = query.getOrDefault("Action")
  valid_606527 = validateParameter(valid_606527, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_606527 != nil:
    section.add "Action", valid_606527
  var valid_606528 = query.getOrDefault("Version")
  valid_606528 = validateParameter(valid_606528, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606528 != nil:
    section.add "Version", valid_606528
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
  var valid_606529 = header.getOrDefault("X-Amz-Signature")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Signature", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Content-Sha256", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Date")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Date", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Credential")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Credential", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Security-Token")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Security-Token", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Algorithm")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Algorithm", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-SignedHeaders", valid_606535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606536: Call_GetDeleteLoadBalancer_606523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_606536.validator(path, query, header, formData, body)
  let scheme = call_606536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606536.url(scheme.get, call_606536.host, call_606536.base,
                         call_606536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606536, url, valid)

proc call*(call_606537: Call_GetDeleteLoadBalancer_606523;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606538 = newJObject()
  add(query_606538, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606538, "Action", newJString(Action))
  add(query_606538, "Version", newJString(Version))
  result = call_606537.call(nil, query_606538, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_606523(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_606524, base: "/",
    url: url_GetDeleteLoadBalancer_606525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerListeners_606573 = ref object of OpenApiRestCall_605589
proc url_PostDeleteLoadBalancerListeners_606575(protocol: Scheme; host: string;
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

proc validate_PostDeleteLoadBalancerListeners_606574(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606576 = query.getOrDefault("Action")
  valid_606576 = validateParameter(valid_606576, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_606576 != nil:
    section.add "Action", valid_606576
  var valid_606577 = query.getOrDefault("Version")
  valid_606577 = validateParameter(valid_606577, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606577 != nil:
    section.add "Version", valid_606577
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
  var valid_606578 = header.getOrDefault("X-Amz-Signature")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Signature", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Content-Sha256", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Date")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Date", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Credential")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Credential", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Security-Token")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Security-Token", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Algorithm")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Algorithm", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-SignedHeaders", valid_606584
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerPorts` field"
  var valid_606585 = formData.getOrDefault("LoadBalancerPorts")
  valid_606585 = validateParameter(valid_606585, JArray, required = true, default = nil)
  if valid_606585 != nil:
    section.add "LoadBalancerPorts", valid_606585
  var valid_606586 = formData.getOrDefault("LoadBalancerName")
  valid_606586 = validateParameter(valid_606586, JString, required = true,
                                 default = nil)
  if valid_606586 != nil:
    section.add "LoadBalancerName", valid_606586
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606587: Call_PostDeleteLoadBalancerListeners_606573;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_606587.validator(path, query, header, formData, body)
  let scheme = call_606587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606587.url(scheme.get, call_606587.host, call_606587.base,
                         call_606587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606587, url, valid)

proc call*(call_606588: Call_PostDeleteLoadBalancerListeners_606573;
          LoadBalancerPorts: JsonNode; LoadBalancerName: string;
          Action: string = "DeleteLoadBalancerListeners";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancerListeners
  ## Deletes the specified listeners from the specified load balancer.
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606589 = newJObject()
  var formData_606590 = newJObject()
  if LoadBalancerPorts != nil:
    formData_606590.add "LoadBalancerPorts", LoadBalancerPorts
  add(formData_606590, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606589, "Action", newJString(Action))
  add(query_606589, "Version", newJString(Version))
  result = call_606588.call(nil, query_606589, nil, formData_606590, nil)

var postDeleteLoadBalancerListeners* = Call_PostDeleteLoadBalancerListeners_606573(
    name: "postDeleteLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_PostDeleteLoadBalancerListeners_606574, base: "/",
    url: url_PostDeleteLoadBalancerListeners_606575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerListeners_606556 = ref object of OpenApiRestCall_605589
proc url_GetDeleteLoadBalancerListeners_606558(protocol: Scheme; host: string;
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

proc validate_GetDeleteLoadBalancerListeners_606557(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerPorts` field"
  var valid_606559 = query.getOrDefault("LoadBalancerPorts")
  valid_606559 = validateParameter(valid_606559, JArray, required = true, default = nil)
  if valid_606559 != nil:
    section.add "LoadBalancerPorts", valid_606559
  var valid_606560 = query.getOrDefault("LoadBalancerName")
  valid_606560 = validateParameter(valid_606560, JString, required = true,
                                 default = nil)
  if valid_606560 != nil:
    section.add "LoadBalancerName", valid_606560
  var valid_606561 = query.getOrDefault("Action")
  valid_606561 = validateParameter(valid_606561, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_606561 != nil:
    section.add "Action", valid_606561
  var valid_606562 = query.getOrDefault("Version")
  valid_606562 = validateParameter(valid_606562, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606562 != nil:
    section.add "Version", valid_606562
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
  var valid_606563 = header.getOrDefault("X-Amz-Signature")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Signature", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Content-Sha256", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Date")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Date", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Credential")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Credential", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Security-Token")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Security-Token", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Algorithm")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Algorithm", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-SignedHeaders", valid_606569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606570: Call_GetDeleteLoadBalancerListeners_606556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_606570.validator(path, query, header, formData, body)
  let scheme = call_606570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606570.url(scheme.get, call_606570.host, call_606570.base,
                         call_606570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606570, url, valid)

proc call*(call_606571: Call_GetDeleteLoadBalancerListeners_606556;
          LoadBalancerPorts: JsonNode; LoadBalancerName: string;
          Action: string = "DeleteLoadBalancerListeners";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancerListeners
  ## Deletes the specified listeners from the specified load balancer.
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606572 = newJObject()
  if LoadBalancerPorts != nil:
    query_606572.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_606572, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606572, "Action", newJString(Action))
  add(query_606572, "Version", newJString(Version))
  result = call_606571.call(nil, query_606572, nil, nil, nil)

var getDeleteLoadBalancerListeners* = Call_GetDeleteLoadBalancerListeners_606556(
    name: "getDeleteLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_GetDeleteLoadBalancerListeners_606557, base: "/",
    url: url_GetDeleteLoadBalancerListeners_606558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerPolicy_606608 = ref object of OpenApiRestCall_605589
proc url_PostDeleteLoadBalancerPolicy_606610(protocol: Scheme; host: string;
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

proc validate_PostDeleteLoadBalancerPolicy_606609(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606611 = query.getOrDefault("Action")
  valid_606611 = validateParameter(valid_606611, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_606611 != nil:
    section.add "Action", valid_606611
  var valid_606612 = query.getOrDefault("Version")
  valid_606612 = validateParameter(valid_606612, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606612 != nil:
    section.add "Version", valid_606612
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
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_606620 = formData.getOrDefault("LoadBalancerName")
  valid_606620 = validateParameter(valid_606620, JString, required = true,
                                 default = nil)
  if valid_606620 != nil:
    section.add "LoadBalancerName", valid_606620
  var valid_606621 = formData.getOrDefault("PolicyName")
  valid_606621 = validateParameter(valid_606621, JString, required = true,
                                 default = nil)
  if valid_606621 != nil:
    section.add "PolicyName", valid_606621
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606622: Call_PostDeleteLoadBalancerPolicy_606608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_606622.validator(path, query, header, formData, body)
  let scheme = call_606622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606622.url(scheme.get, call_606622.host, call_606622.base,
                         call_606622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606622, url, valid)

proc call*(call_606623: Call_PostDeleteLoadBalancerPolicy_606608;
          LoadBalancerName: string; PolicyName: string;
          Action: string = "DeleteLoadBalancerPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancerPolicy
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PolicyName: string (required)
  ##             : The name of the policy.
  var query_606624 = newJObject()
  var formData_606625 = newJObject()
  add(formData_606625, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606624, "Action", newJString(Action))
  add(query_606624, "Version", newJString(Version))
  add(formData_606625, "PolicyName", newJString(PolicyName))
  result = call_606623.call(nil, query_606624, nil, formData_606625, nil)

var postDeleteLoadBalancerPolicy* = Call_PostDeleteLoadBalancerPolicy_606608(
    name: "postDeleteLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_PostDeleteLoadBalancerPolicy_606609, base: "/",
    url: url_PostDeleteLoadBalancerPolicy_606610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerPolicy_606591 = ref object of OpenApiRestCall_605589
proc url_GetDeleteLoadBalancerPolicy_606593(protocol: Scheme; host: string;
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

proc validate_GetDeleteLoadBalancerPolicy_606592(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `PolicyName` field"
  var valid_606594 = query.getOrDefault("PolicyName")
  valid_606594 = validateParameter(valid_606594, JString, required = true,
                                 default = nil)
  if valid_606594 != nil:
    section.add "PolicyName", valid_606594
  var valid_606595 = query.getOrDefault("LoadBalancerName")
  valid_606595 = validateParameter(valid_606595, JString, required = true,
                                 default = nil)
  if valid_606595 != nil:
    section.add "LoadBalancerName", valid_606595
  var valid_606596 = query.getOrDefault("Action")
  valid_606596 = validateParameter(valid_606596, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_606596 != nil:
    section.add "Action", valid_606596
  var valid_606597 = query.getOrDefault("Version")
  valid_606597 = validateParameter(valid_606597, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606597 != nil:
    section.add "Version", valid_606597
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
  var valid_606598 = header.getOrDefault("X-Amz-Signature")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Signature", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Content-Sha256", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Date")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Date", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Credential")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Credential", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Security-Token")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Security-Token", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Algorithm")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Algorithm", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-SignedHeaders", valid_606604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606605: Call_GetDeleteLoadBalancerPolicy_606591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_606605.validator(path, query, header, formData, body)
  let scheme = call_606605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606605.url(scheme.get, call_606605.host, call_606605.base,
                         call_606605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606605, url, valid)

proc call*(call_606606: Call_GetDeleteLoadBalancerPolicy_606591;
          PolicyName: string; LoadBalancerName: string;
          Action: string = "DeleteLoadBalancerPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancerPolicy
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ##   PolicyName: string (required)
  ##             : The name of the policy.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606607 = newJObject()
  add(query_606607, "PolicyName", newJString(PolicyName))
  add(query_606607, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606607, "Action", newJString(Action))
  add(query_606607, "Version", newJString(Version))
  result = call_606606.call(nil, query_606607, nil, nil, nil)

var getDeleteLoadBalancerPolicy* = Call_GetDeleteLoadBalancerPolicy_606591(
    name: "getDeleteLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_GetDeleteLoadBalancerPolicy_606592, base: "/",
    url: url_GetDeleteLoadBalancerPolicy_606593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterInstancesFromLoadBalancer_606643 = ref object of OpenApiRestCall_605589
proc url_PostDeregisterInstancesFromLoadBalancer_606645(protocol: Scheme;
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

proc validate_PostDeregisterInstancesFromLoadBalancer_606644(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606646 = query.getOrDefault("Action")
  valid_606646 = validateParameter(valid_606646, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_606646 != nil:
    section.add "Action", valid_606646
  var valid_606647 = query.getOrDefault("Version")
  valid_606647 = validateParameter(valid_606647, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606647 != nil:
    section.add "Version", valid_606647
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
  var valid_606648 = header.getOrDefault("X-Amz-Signature")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-Signature", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-Content-Sha256", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Date")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Date", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Credential")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Credential", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Security-Token")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Security-Token", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Algorithm")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Algorithm", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-SignedHeaders", valid_606654
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_606655 = formData.getOrDefault("Instances")
  valid_606655 = validateParameter(valid_606655, JArray, required = true, default = nil)
  if valid_606655 != nil:
    section.add "Instances", valid_606655
  var valid_606656 = formData.getOrDefault("LoadBalancerName")
  valid_606656 = validateParameter(valid_606656, JString, required = true,
                                 default = nil)
  if valid_606656 != nil:
    section.add "LoadBalancerName", valid_606656
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606657: Call_PostDeregisterInstancesFromLoadBalancer_606643;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606657.validator(path, query, header, formData, body)
  let scheme = call_606657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606657.url(scheme.get, call_606657.host, call_606657.base,
                         call_606657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606657, url, valid)

proc call*(call_606658: Call_PostDeregisterInstancesFromLoadBalancer_606643;
          Instances: JsonNode; LoadBalancerName: string;
          Action: string = "DeregisterInstancesFromLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeregisterInstancesFromLoadBalancer
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606659 = newJObject()
  var formData_606660 = newJObject()
  if Instances != nil:
    formData_606660.add "Instances", Instances
  add(formData_606660, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606659, "Action", newJString(Action))
  add(query_606659, "Version", newJString(Version))
  result = call_606658.call(nil, query_606659, nil, formData_606660, nil)

var postDeregisterInstancesFromLoadBalancer* = Call_PostDeregisterInstancesFromLoadBalancer_606643(
    name: "postDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_PostDeregisterInstancesFromLoadBalancer_606644, base: "/",
    url: url_PostDeregisterInstancesFromLoadBalancer_606645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterInstancesFromLoadBalancer_606626 = ref object of OpenApiRestCall_605589
proc url_GetDeregisterInstancesFromLoadBalancer_606628(protocol: Scheme;
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

proc validate_GetDeregisterInstancesFromLoadBalancer_606627(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_606629 = query.getOrDefault("LoadBalancerName")
  valid_606629 = validateParameter(valid_606629, JString, required = true,
                                 default = nil)
  if valid_606629 != nil:
    section.add "LoadBalancerName", valid_606629
  var valid_606630 = query.getOrDefault("Action")
  valid_606630 = validateParameter(valid_606630, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_606630 != nil:
    section.add "Action", valid_606630
  var valid_606631 = query.getOrDefault("Instances")
  valid_606631 = validateParameter(valid_606631, JArray, required = true, default = nil)
  if valid_606631 != nil:
    section.add "Instances", valid_606631
  var valid_606632 = query.getOrDefault("Version")
  valid_606632 = validateParameter(valid_606632, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606632 != nil:
    section.add "Version", valid_606632
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
  var valid_606633 = header.getOrDefault("X-Amz-Signature")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-Signature", valid_606633
  var valid_606634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-Content-Sha256", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Date")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Date", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Credential")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Credential", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Security-Token")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Security-Token", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Algorithm")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Algorithm", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-SignedHeaders", valid_606639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606640: Call_GetDeregisterInstancesFromLoadBalancer_606626;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606640.validator(path, query, header, formData, body)
  let scheme = call_606640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606640.url(scheme.get, call_606640.host, call_606640.base,
                         call_606640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606640, url, valid)

proc call*(call_606641: Call_GetDeregisterInstancesFromLoadBalancer_606626;
          LoadBalancerName: string; Instances: JsonNode;
          Action: string = "DeregisterInstancesFromLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDeregisterInstancesFromLoadBalancer
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   Version: string (required)
  var query_606642 = newJObject()
  add(query_606642, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606642, "Action", newJString(Action))
  if Instances != nil:
    query_606642.add "Instances", Instances
  add(query_606642, "Version", newJString(Version))
  result = call_606641.call(nil, query_606642, nil, nil, nil)

var getDeregisterInstancesFromLoadBalancer* = Call_GetDeregisterInstancesFromLoadBalancer_606626(
    name: "getDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_GetDeregisterInstancesFromLoadBalancer_606627, base: "/",
    url: url_GetDeregisterInstancesFromLoadBalancer_606628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_606678 = ref object of OpenApiRestCall_605589
proc url_PostDescribeAccountLimits_606680(protocol: Scheme; host: string;
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

proc validate_PostDescribeAccountLimits_606679(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606681 = query.getOrDefault("Action")
  valid_606681 = validateParameter(valid_606681, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_606681 != nil:
    section.add "Action", valid_606681
  var valid_606682 = query.getOrDefault("Version")
  valid_606682 = validateParameter(valid_606682, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606682 != nil:
    section.add "Version", valid_606682
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
  var valid_606683 = header.getOrDefault("X-Amz-Signature")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Signature", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Content-Sha256", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Date")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Date", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-Credential")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Credential", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-Security-Token")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Security-Token", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Algorithm")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Algorithm", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-SignedHeaders", valid_606689
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_606690 = formData.getOrDefault("Marker")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "Marker", valid_606690
  var valid_606691 = formData.getOrDefault("PageSize")
  valid_606691 = validateParameter(valid_606691, JInt, required = false, default = nil)
  if valid_606691 != nil:
    section.add "PageSize", valid_606691
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606692: Call_PostDescribeAccountLimits_606678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606692.validator(path, query, header, formData, body)
  let scheme = call_606692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606692.url(scheme.get, call_606692.host, call_606692.base,
                         call_606692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606692, url, valid)

proc call*(call_606693: Call_PostDescribeAccountLimits_606678; Marker: string = "";
          Action: string = "DescribeAccountLimits"; PageSize: int = 0;
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeAccountLimits
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_606694 = newJObject()
  var formData_606695 = newJObject()
  add(formData_606695, "Marker", newJString(Marker))
  add(query_606694, "Action", newJString(Action))
  add(formData_606695, "PageSize", newJInt(PageSize))
  add(query_606694, "Version", newJString(Version))
  result = call_606693.call(nil, query_606694, nil, formData_606695, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_606678(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_606679, base: "/",
    url: url_PostDescribeAccountLimits_606680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_606661 = ref object of OpenApiRestCall_605589
proc url_GetDescribeAccountLimits_606663(protocol: Scheme; host: string;
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

proc validate_GetDescribeAccountLimits_606662(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606664 = query.getOrDefault("Marker")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "Marker", valid_606664
  var valid_606665 = query.getOrDefault("PageSize")
  valid_606665 = validateParameter(valid_606665, JInt, required = false, default = nil)
  if valid_606665 != nil:
    section.add "PageSize", valid_606665
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606666 = query.getOrDefault("Action")
  valid_606666 = validateParameter(valid_606666, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_606666 != nil:
    section.add "Action", valid_606666
  var valid_606667 = query.getOrDefault("Version")
  valid_606667 = validateParameter(valid_606667, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606667 != nil:
    section.add "Version", valid_606667
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
  var valid_606668 = header.getOrDefault("X-Amz-Signature")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Signature", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Content-Sha256", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Date")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Date", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-Credential")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Credential", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Security-Token")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Security-Token", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Algorithm")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Algorithm", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-SignedHeaders", valid_606674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606675: Call_GetDescribeAccountLimits_606661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606675.validator(path, query, header, formData, body)
  let scheme = call_606675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606675.url(scheme.get, call_606675.host, call_606675.base,
                         call_606675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606675, url, valid)

proc call*(call_606676: Call_GetDescribeAccountLimits_606661; Marker: string = "";
          PageSize: int = 0; Action: string = "DescribeAccountLimits";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeAccountLimits
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606677 = newJObject()
  add(query_606677, "Marker", newJString(Marker))
  add(query_606677, "PageSize", newJInt(PageSize))
  add(query_606677, "Action", newJString(Action))
  add(query_606677, "Version", newJString(Version))
  result = call_606676.call(nil, query_606677, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_606661(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_606662, base: "/",
    url: url_GetDescribeAccountLimits_606663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstanceHealth_606713 = ref object of OpenApiRestCall_605589
proc url_PostDescribeInstanceHealth_606715(protocol: Scheme; host: string;
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

proc validate_PostDescribeInstanceHealth_606714(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606716 = query.getOrDefault("Action")
  valid_606716 = validateParameter(valid_606716, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_606716 != nil:
    section.add "Action", valid_606716
  var valid_606717 = query.getOrDefault("Version")
  valid_606717 = validateParameter(valid_606717, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606717 != nil:
    section.add "Version", valid_606717
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
  var valid_606718 = header.getOrDefault("X-Amz-Signature")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amz-Signature", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Content-Sha256", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Date")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Date", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Credential")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Credential", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Security-Token")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Security-Token", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Algorithm")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Algorithm", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-SignedHeaders", valid_606724
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_606725 = formData.getOrDefault("Instances")
  valid_606725 = validateParameter(valid_606725, JArray, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "Instances", valid_606725
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_606726 = formData.getOrDefault("LoadBalancerName")
  valid_606726 = validateParameter(valid_606726, JString, required = true,
                                 default = nil)
  if valid_606726 != nil:
    section.add "LoadBalancerName", valid_606726
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606727: Call_PostDescribeInstanceHealth_606713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_606727.validator(path, query, header, formData, body)
  let scheme = call_606727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606727.url(scheme.get, call_606727.host, call_606727.base,
                         call_606727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606727, url, valid)

proc call*(call_606728: Call_PostDescribeInstanceHealth_606713;
          LoadBalancerName: string; Instances: JsonNode = nil;
          Action: string = "DescribeInstanceHealth"; Version: string = "2012-06-01"): Recallable =
  ## postDescribeInstanceHealth
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606729 = newJObject()
  var formData_606730 = newJObject()
  if Instances != nil:
    formData_606730.add "Instances", Instances
  add(formData_606730, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606729, "Action", newJString(Action))
  add(query_606729, "Version", newJString(Version))
  result = call_606728.call(nil, query_606729, nil, formData_606730, nil)

var postDescribeInstanceHealth* = Call_PostDescribeInstanceHealth_606713(
    name: "postDescribeInstanceHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_PostDescribeInstanceHealth_606714, base: "/",
    url: url_PostDescribeInstanceHealth_606715,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstanceHealth_606696 = ref object of OpenApiRestCall_605589
proc url_GetDescribeInstanceHealth_606698(protocol: Scheme; host: string;
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

proc validate_GetDescribeInstanceHealth_606697(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_606699 = query.getOrDefault("LoadBalancerName")
  valid_606699 = validateParameter(valid_606699, JString, required = true,
                                 default = nil)
  if valid_606699 != nil:
    section.add "LoadBalancerName", valid_606699
  var valid_606700 = query.getOrDefault("Action")
  valid_606700 = validateParameter(valid_606700, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_606700 != nil:
    section.add "Action", valid_606700
  var valid_606701 = query.getOrDefault("Instances")
  valid_606701 = validateParameter(valid_606701, JArray, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "Instances", valid_606701
  var valid_606702 = query.getOrDefault("Version")
  valid_606702 = validateParameter(valid_606702, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606702 != nil:
    section.add "Version", valid_606702
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
  var valid_606703 = header.getOrDefault("X-Amz-Signature")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Signature", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Content-Sha256", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Date")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Date", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Credential")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Credential", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Security-Token")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Security-Token", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Algorithm")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Algorithm", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-SignedHeaders", valid_606709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606710: Call_GetDescribeInstanceHealth_606696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_606710.validator(path, query, header, formData, body)
  let scheme = call_606710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606710.url(scheme.get, call_606710.host, call_606710.base,
                         call_606710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606710, url, valid)

proc call*(call_606711: Call_GetDescribeInstanceHealth_606696;
          LoadBalancerName: string; Action: string = "DescribeInstanceHealth";
          Instances: JsonNode = nil; Version: string = "2012-06-01"): Recallable =
  ## getDescribeInstanceHealth
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   Version: string (required)
  var query_606712 = newJObject()
  add(query_606712, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606712, "Action", newJString(Action))
  if Instances != nil:
    query_606712.add "Instances", Instances
  add(query_606712, "Version", newJString(Version))
  result = call_606711.call(nil, query_606712, nil, nil, nil)

var getDescribeInstanceHealth* = Call_GetDescribeInstanceHealth_606696(
    name: "getDescribeInstanceHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_GetDescribeInstanceHealth_606697, base: "/",
    url: url_GetDescribeInstanceHealth_606698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_606747 = ref object of OpenApiRestCall_605589
proc url_PostDescribeLoadBalancerAttributes_606749(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerAttributes_606748(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the attributes for the specified load balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606750 = query.getOrDefault("Action")
  valid_606750 = validateParameter(valid_606750, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_606750 != nil:
    section.add "Action", valid_606750
  var valid_606751 = query.getOrDefault("Version")
  valid_606751 = validateParameter(valid_606751, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606751 != nil:
    section.add "Version", valid_606751
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
  var valid_606752 = header.getOrDefault("X-Amz-Signature")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Signature", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-Content-Sha256", valid_606753
  var valid_606754 = header.getOrDefault("X-Amz-Date")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-Date", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Credential")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Credential", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Security-Token")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Security-Token", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Algorithm")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Algorithm", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-SignedHeaders", valid_606758
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_606759 = formData.getOrDefault("LoadBalancerName")
  valid_606759 = validateParameter(valid_606759, JString, required = true,
                                 default = nil)
  if valid_606759 != nil:
    section.add "LoadBalancerName", valid_606759
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606760: Call_PostDescribeLoadBalancerAttributes_606747;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_606760.validator(path, query, header, formData, body)
  let scheme = call_606760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606760.url(scheme.get, call_606760.host, call_606760.base,
                         call_606760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606760, url, valid)

proc call*(call_606761: Call_PostDescribeLoadBalancerAttributes_606747;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606762 = newJObject()
  var formData_606763 = newJObject()
  add(formData_606763, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606762, "Action", newJString(Action))
  add(query_606762, "Version", newJString(Version))
  result = call_606761.call(nil, query_606762, nil, formData_606763, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_606747(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_606748, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_606749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_606731 = ref object of OpenApiRestCall_605589
proc url_GetDescribeLoadBalancerAttributes_606733(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerAttributes_606732(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the attributes for the specified load balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_606734 = query.getOrDefault("LoadBalancerName")
  valid_606734 = validateParameter(valid_606734, JString, required = true,
                                 default = nil)
  if valid_606734 != nil:
    section.add "LoadBalancerName", valid_606734
  var valid_606735 = query.getOrDefault("Action")
  valid_606735 = validateParameter(valid_606735, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_606735 != nil:
    section.add "Action", valid_606735
  var valid_606736 = query.getOrDefault("Version")
  valid_606736 = validateParameter(valid_606736, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606736 != nil:
    section.add "Version", valid_606736
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
  var valid_606737 = header.getOrDefault("X-Amz-Signature")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Signature", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-Content-Sha256", valid_606738
  var valid_606739 = header.getOrDefault("X-Amz-Date")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-Date", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Credential")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Credential", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-Security-Token")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Security-Token", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Algorithm")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Algorithm", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-SignedHeaders", valid_606743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606744: Call_GetDescribeLoadBalancerAttributes_606731;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_606744.validator(path, query, header, formData, body)
  let scheme = call_606744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606744.url(scheme.get, call_606744.host, call_606744.base,
                         call_606744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606744, url, valid)

proc call*(call_606745: Call_GetDescribeLoadBalancerAttributes_606731;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606746 = newJObject()
  add(query_606746, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606746, "Action", newJString(Action))
  add(query_606746, "Version", newJString(Version))
  result = call_606745.call(nil, query_606746, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_606731(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_606732, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_606733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicies_606781 = ref object of OpenApiRestCall_605589
proc url_PostDescribeLoadBalancerPolicies_606783(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerPolicies_606782(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606784 = query.getOrDefault("Action")
  valid_606784 = validateParameter(valid_606784, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_606784 != nil:
    section.add "Action", valid_606784
  var valid_606785 = query.getOrDefault("Version")
  valid_606785 = validateParameter(valid_606785, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606785 != nil:
    section.add "Version", valid_606785
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
  var valid_606786 = header.getOrDefault("X-Amz-Signature")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Signature", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Content-Sha256", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-Date")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-Date", valid_606788
  var valid_606789 = header.getOrDefault("X-Amz-Credential")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-Credential", valid_606789
  var valid_606790 = header.getOrDefault("X-Amz-Security-Token")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Security-Token", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-Algorithm")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-Algorithm", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-SignedHeaders", valid_606792
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   LoadBalancerName: JString
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_606793 = formData.getOrDefault("PolicyNames")
  valid_606793 = validateParameter(valid_606793, JArray, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "PolicyNames", valid_606793
  var valid_606794 = formData.getOrDefault("LoadBalancerName")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "LoadBalancerName", valid_606794
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606795: Call_PostDescribeLoadBalancerPolicies_606781;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_606795.validator(path, query, header, formData, body)
  let scheme = call_606795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606795.url(scheme.get, call_606795.host, call_606795.base,
                         call_606795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606795, url, valid)

proc call*(call_606796: Call_PostDescribeLoadBalancerPolicies_606781;
          PolicyNames: JsonNode = nil; LoadBalancerName: string = "";
          Action: string = "DescribeLoadBalancerPolicies";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicies
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   LoadBalancerName: string
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606797 = newJObject()
  var formData_606798 = newJObject()
  if PolicyNames != nil:
    formData_606798.add "PolicyNames", PolicyNames
  add(formData_606798, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606797, "Action", newJString(Action))
  add(query_606797, "Version", newJString(Version))
  result = call_606796.call(nil, query_606797, nil, formData_606798, nil)

var postDescribeLoadBalancerPolicies* = Call_PostDescribeLoadBalancerPolicies_606781(
    name: "postDescribeLoadBalancerPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_PostDescribeLoadBalancerPolicies_606782, base: "/",
    url: url_PostDescribeLoadBalancerPolicies_606783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicies_606764 = ref object of OpenApiRestCall_605589
proc url_GetDescribeLoadBalancerPolicies_606766(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerPolicies_606765(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  section = newJObject()
  var valid_606767 = query.getOrDefault("LoadBalancerName")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "LoadBalancerName", valid_606767
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606768 = query.getOrDefault("Action")
  valid_606768 = validateParameter(valid_606768, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_606768 != nil:
    section.add "Action", valid_606768
  var valid_606769 = query.getOrDefault("Version")
  valid_606769 = validateParameter(valid_606769, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606769 != nil:
    section.add "Version", valid_606769
  var valid_606770 = query.getOrDefault("PolicyNames")
  valid_606770 = validateParameter(valid_606770, JArray, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "PolicyNames", valid_606770
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
  var valid_606771 = header.getOrDefault("X-Amz-Signature")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-Signature", valid_606771
  var valid_606772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-Content-Sha256", valid_606772
  var valid_606773 = header.getOrDefault("X-Amz-Date")
  valid_606773 = validateParameter(valid_606773, JString, required = false,
                                 default = nil)
  if valid_606773 != nil:
    section.add "X-Amz-Date", valid_606773
  var valid_606774 = header.getOrDefault("X-Amz-Credential")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-Credential", valid_606774
  var valid_606775 = header.getOrDefault("X-Amz-Security-Token")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Security-Token", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-Algorithm")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-Algorithm", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-SignedHeaders", valid_606777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606778: Call_GetDescribeLoadBalancerPolicies_606764;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_606778.validator(path, query, header, formData, body)
  let scheme = call_606778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606778.url(scheme.get, call_606778.host, call_606778.base,
                         call_606778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606778, url, valid)

proc call*(call_606779: Call_GetDescribeLoadBalancerPolicies_606764;
          LoadBalancerName: string = "";
          Action: string = "DescribeLoadBalancerPolicies";
          Version: string = "2012-06-01"; PolicyNames: JsonNode = nil): Recallable =
  ## getDescribeLoadBalancerPolicies
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ##   LoadBalancerName: string
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  var query_606780 = newJObject()
  add(query_606780, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606780, "Action", newJString(Action))
  add(query_606780, "Version", newJString(Version))
  if PolicyNames != nil:
    query_606780.add "PolicyNames", PolicyNames
  result = call_606779.call(nil, query_606780, nil, nil, nil)

var getDescribeLoadBalancerPolicies* = Call_GetDescribeLoadBalancerPolicies_606764(
    name: "getDescribeLoadBalancerPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_GetDescribeLoadBalancerPolicies_606765, base: "/",
    url: url_GetDescribeLoadBalancerPolicies_606766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicyTypes_606815 = ref object of OpenApiRestCall_605589
proc url_PostDescribeLoadBalancerPolicyTypes_606817(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerPolicyTypes_606816(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606818 = query.getOrDefault("Action")
  valid_606818 = validateParameter(valid_606818, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_606818 != nil:
    section.add "Action", valid_606818
  var valid_606819 = query.getOrDefault("Version")
  valid_606819 = validateParameter(valid_606819, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606819 != nil:
    section.add "Version", valid_606819
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
  var valid_606820 = header.getOrDefault("X-Amz-Signature")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "X-Amz-Signature", valid_606820
  var valid_606821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "X-Amz-Content-Sha256", valid_606821
  var valid_606822 = header.getOrDefault("X-Amz-Date")
  valid_606822 = validateParameter(valid_606822, JString, required = false,
                                 default = nil)
  if valid_606822 != nil:
    section.add "X-Amz-Date", valid_606822
  var valid_606823 = header.getOrDefault("X-Amz-Credential")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Credential", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-Security-Token")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-Security-Token", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Algorithm")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Algorithm", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-SignedHeaders", valid_606826
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  section = newJObject()
  var valid_606827 = formData.getOrDefault("PolicyTypeNames")
  valid_606827 = validateParameter(valid_606827, JArray, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "PolicyTypeNames", valid_606827
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606828: Call_PostDescribeLoadBalancerPolicyTypes_606815;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_606828.validator(path, query, header, formData, body)
  let scheme = call_606828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606828.url(scheme.get, call_606828.host, call_606828.base,
                         call_606828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606828, url, valid)

proc call*(call_606829: Call_PostDescribeLoadBalancerPolicyTypes_606815;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606830 = newJObject()
  var formData_606831 = newJObject()
  if PolicyTypeNames != nil:
    formData_606831.add "PolicyTypeNames", PolicyTypeNames
  add(query_606830, "Action", newJString(Action))
  add(query_606830, "Version", newJString(Version))
  result = call_606829.call(nil, query_606830, nil, formData_606831, nil)

var postDescribeLoadBalancerPolicyTypes* = Call_PostDescribeLoadBalancerPolicyTypes_606815(
    name: "postDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_PostDescribeLoadBalancerPolicyTypes_606816, base: "/",
    url: url_PostDescribeLoadBalancerPolicyTypes_606817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicyTypes_606799 = ref object of OpenApiRestCall_605589
proc url_GetDescribeLoadBalancerPolicyTypes_606801(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerPolicyTypes_606800(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606802 = query.getOrDefault("PolicyTypeNames")
  valid_606802 = validateParameter(valid_606802, JArray, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "PolicyTypeNames", valid_606802
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606803 = query.getOrDefault("Action")
  valid_606803 = validateParameter(valid_606803, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_606803 != nil:
    section.add "Action", valid_606803
  var valid_606804 = query.getOrDefault("Version")
  valid_606804 = validateParameter(valid_606804, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606804 != nil:
    section.add "Version", valid_606804
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
  var valid_606805 = header.getOrDefault("X-Amz-Signature")
  valid_606805 = validateParameter(valid_606805, JString, required = false,
                                 default = nil)
  if valid_606805 != nil:
    section.add "X-Amz-Signature", valid_606805
  var valid_606806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606806 = validateParameter(valid_606806, JString, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "X-Amz-Content-Sha256", valid_606806
  var valid_606807 = header.getOrDefault("X-Amz-Date")
  valid_606807 = validateParameter(valid_606807, JString, required = false,
                                 default = nil)
  if valid_606807 != nil:
    section.add "X-Amz-Date", valid_606807
  var valid_606808 = header.getOrDefault("X-Amz-Credential")
  valid_606808 = validateParameter(valid_606808, JString, required = false,
                                 default = nil)
  if valid_606808 != nil:
    section.add "X-Amz-Credential", valid_606808
  var valid_606809 = header.getOrDefault("X-Amz-Security-Token")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Security-Token", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Algorithm")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Algorithm", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-SignedHeaders", valid_606811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606812: Call_GetDescribeLoadBalancerPolicyTypes_606799;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_606812.validator(path, query, header, formData, body)
  let scheme = call_606812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606812.url(scheme.get, call_606812.host, call_606812.base,
                         call_606812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606812, url, valid)

proc call*(call_606813: Call_GetDescribeLoadBalancerPolicyTypes_606799;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606814 = newJObject()
  if PolicyTypeNames != nil:
    query_606814.add "PolicyTypeNames", PolicyTypeNames
  add(query_606814, "Action", newJString(Action))
  add(query_606814, "Version", newJString(Version))
  result = call_606813.call(nil, query_606814, nil, nil, nil)

var getDescribeLoadBalancerPolicyTypes* = Call_GetDescribeLoadBalancerPolicyTypes_606799(
    name: "getDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_GetDescribeLoadBalancerPolicyTypes_606800, base: "/",
    url: url_GetDescribeLoadBalancerPolicyTypes_606801,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_606850 = ref object of OpenApiRestCall_605589
proc url_PostDescribeLoadBalancers_606852(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancers_606851(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606853 = query.getOrDefault("Action")
  valid_606853 = validateParameter(valid_606853, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_606853 != nil:
    section.add "Action", valid_606853
  var valid_606854 = query.getOrDefault("Version")
  valid_606854 = validateParameter(valid_606854, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606854 != nil:
    section.add "Version", valid_606854
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
  var valid_606855 = header.getOrDefault("X-Amz-Signature")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Signature", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Content-Sha256", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Date")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Date", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Credential")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Credential", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Security-Token")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Security-Token", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Algorithm")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Algorithm", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-SignedHeaders", valid_606861
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  section = newJObject()
  var valid_606862 = formData.getOrDefault("LoadBalancerNames")
  valid_606862 = validateParameter(valid_606862, JArray, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "LoadBalancerNames", valid_606862
  var valid_606863 = formData.getOrDefault("Marker")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "Marker", valid_606863
  var valid_606864 = formData.getOrDefault("PageSize")
  valid_606864 = validateParameter(valid_606864, JInt, required = false, default = nil)
  if valid_606864 != nil:
    section.add "PageSize", valid_606864
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606865: Call_PostDescribeLoadBalancers_606850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_606865.validator(path, query, header, formData, body)
  let scheme = call_606865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606865.url(scheme.get, call_606865.host, call_606865.base,
                         call_606865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606865, url, valid)

proc call*(call_606866: Call_PostDescribeLoadBalancers_606850;
          LoadBalancerNames: JsonNode = nil; Marker: string = "";
          Action: string = "DescribeLoadBalancers"; PageSize: int = 0;
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancers
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  ##   Version: string (required)
  var query_606867 = newJObject()
  var formData_606868 = newJObject()
  if LoadBalancerNames != nil:
    formData_606868.add "LoadBalancerNames", LoadBalancerNames
  add(formData_606868, "Marker", newJString(Marker))
  add(query_606867, "Action", newJString(Action))
  add(formData_606868, "PageSize", newJInt(PageSize))
  add(query_606867, "Version", newJString(Version))
  result = call_606866.call(nil, query_606867, nil, formData_606868, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_606850(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_606851, base: "/",
    url: url_PostDescribeLoadBalancers_606852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_606832 = ref object of OpenApiRestCall_605589
proc url_GetDescribeLoadBalancers_606834(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancers_606833(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  section = newJObject()
  var valid_606835 = query.getOrDefault("Marker")
  valid_606835 = validateParameter(valid_606835, JString, required = false,
                                 default = nil)
  if valid_606835 != nil:
    section.add "Marker", valid_606835
  var valid_606836 = query.getOrDefault("PageSize")
  valid_606836 = validateParameter(valid_606836, JInt, required = false, default = nil)
  if valid_606836 != nil:
    section.add "PageSize", valid_606836
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606837 = query.getOrDefault("Action")
  valid_606837 = validateParameter(valid_606837, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_606837 != nil:
    section.add "Action", valid_606837
  var valid_606838 = query.getOrDefault("Version")
  valid_606838 = validateParameter(valid_606838, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606838 != nil:
    section.add "Version", valid_606838
  var valid_606839 = query.getOrDefault("LoadBalancerNames")
  valid_606839 = validateParameter(valid_606839, JArray, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "LoadBalancerNames", valid_606839
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
  var valid_606840 = header.getOrDefault("X-Amz-Signature")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "X-Amz-Signature", valid_606840
  var valid_606841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Content-Sha256", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Date")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Date", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Credential")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Credential", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Security-Token")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Security-Token", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Algorithm")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Algorithm", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-SignedHeaders", valid_606846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606847: Call_GetDescribeLoadBalancers_606832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_606847.validator(path, query, header, formData, body)
  let scheme = call_606847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606847.url(scheme.get, call_606847.host, call_606847.base,
                         call_606847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606847, url, valid)

proc call*(call_606848: Call_GetDescribeLoadBalancers_606832; Marker: string = "";
          PageSize: int = 0; Action: string = "DescribeLoadBalancers";
          Version: string = "2012-06-01"; LoadBalancerNames: JsonNode = nil): Recallable =
  ## getDescribeLoadBalancers
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  var query_606849 = newJObject()
  add(query_606849, "Marker", newJString(Marker))
  add(query_606849, "PageSize", newJInt(PageSize))
  add(query_606849, "Action", newJString(Action))
  add(query_606849, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_606849.add "LoadBalancerNames", LoadBalancerNames
  result = call_606848.call(nil, query_606849, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_606832(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_606833, base: "/",
    url: url_GetDescribeLoadBalancers_606834, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_606885 = ref object of OpenApiRestCall_605589
proc url_PostDescribeTags_606887(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeTags_606886(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes the tags associated with the specified load balancers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606888 = query.getOrDefault("Action")
  valid_606888 = validateParameter(valid_606888, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_606888 != nil:
    section.add "Action", valid_606888
  var valid_606889 = query.getOrDefault("Version")
  valid_606889 = validateParameter(valid_606889, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606889 != nil:
    section.add "Version", valid_606889
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
  var valid_606890 = header.getOrDefault("X-Amz-Signature")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Signature", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Content-Sha256", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-Date")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Date", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-Credential")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-Credential", valid_606893
  var valid_606894 = header.getOrDefault("X-Amz-Security-Token")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "X-Amz-Security-Token", valid_606894
  var valid_606895 = header.getOrDefault("X-Amz-Algorithm")
  valid_606895 = validateParameter(valid_606895, JString, required = false,
                                 default = nil)
  if valid_606895 != nil:
    section.add "X-Amz-Algorithm", valid_606895
  var valid_606896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "X-Amz-SignedHeaders", valid_606896
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_606897 = formData.getOrDefault("LoadBalancerNames")
  valid_606897 = validateParameter(valid_606897, JArray, required = true, default = nil)
  if valid_606897 != nil:
    section.add "LoadBalancerNames", valid_606897
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606898: Call_PostDescribeTags_606885; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_606898.validator(path, query, header, formData, body)
  let scheme = call_606898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606898.url(scheme.get, call_606898.host, call_606898.base,
                         call_606898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606898, url, valid)

proc call*(call_606899: Call_PostDescribeTags_606885; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606900 = newJObject()
  var formData_606901 = newJObject()
  if LoadBalancerNames != nil:
    formData_606901.add "LoadBalancerNames", LoadBalancerNames
  add(query_606900, "Action", newJString(Action))
  add(query_606900, "Version", newJString(Version))
  result = call_606899.call(nil, query_606900, nil, formData_606901, nil)

var postDescribeTags* = Call_PostDescribeTags_606885(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_606886,
    base: "/", url: url_PostDescribeTags_606887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_606869 = ref object of OpenApiRestCall_605589
proc url_GetDescribeTags_606871(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTags_606870(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Describes the tags associated with the specified load balancers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606872 = query.getOrDefault("Action")
  valid_606872 = validateParameter(valid_606872, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_606872 != nil:
    section.add "Action", valid_606872
  var valid_606873 = query.getOrDefault("Version")
  valid_606873 = validateParameter(valid_606873, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606873 != nil:
    section.add "Version", valid_606873
  var valid_606874 = query.getOrDefault("LoadBalancerNames")
  valid_606874 = validateParameter(valid_606874, JArray, required = true, default = nil)
  if valid_606874 != nil:
    section.add "LoadBalancerNames", valid_606874
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
  var valid_606875 = header.getOrDefault("X-Amz-Signature")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Signature", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Content-Sha256", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Date")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Date", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Credential")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Credential", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-Security-Token")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-Security-Token", valid_606879
  var valid_606880 = header.getOrDefault("X-Amz-Algorithm")
  valid_606880 = validateParameter(valid_606880, JString, required = false,
                                 default = nil)
  if valid_606880 != nil:
    section.add "X-Amz-Algorithm", valid_606880
  var valid_606881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606881 = validateParameter(valid_606881, JString, required = false,
                                 default = nil)
  if valid_606881 != nil:
    section.add "X-Amz-SignedHeaders", valid_606881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606882: Call_GetDescribeTags_606869; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_606882.validator(path, query, header, formData, body)
  let scheme = call_606882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606882.url(scheme.get, call_606882.host, call_606882.base,
                         call_606882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606882, url, valid)

proc call*(call_606883: Call_GetDescribeTags_606869; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  var query_606884 = newJObject()
  add(query_606884, "Action", newJString(Action))
  add(query_606884, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_606884.add "LoadBalancerNames", LoadBalancerNames
  result = call_606883.call(nil, query_606884, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_606869(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_606870,
    base: "/", url: url_GetDescribeTags_606871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDetachLoadBalancerFromSubnets_606919 = ref object of OpenApiRestCall_605589
proc url_PostDetachLoadBalancerFromSubnets_606921(protocol: Scheme; host: string;
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

proc validate_PostDetachLoadBalancerFromSubnets_606920(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606922 = query.getOrDefault("Action")
  valid_606922 = validateParameter(valid_606922, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_606922 != nil:
    section.add "Action", valid_606922
  var valid_606923 = query.getOrDefault("Version")
  valid_606923 = validateParameter(valid_606923, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606923 != nil:
    section.add "Version", valid_606923
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
  var valid_606924 = header.getOrDefault("X-Amz-Signature")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Signature", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-Content-Sha256", valid_606925
  var valid_606926 = header.getOrDefault("X-Amz-Date")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-Date", valid_606926
  var valid_606927 = header.getOrDefault("X-Amz-Credential")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "X-Amz-Credential", valid_606927
  var valid_606928 = header.getOrDefault("X-Amz-Security-Token")
  valid_606928 = validateParameter(valid_606928, JString, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "X-Amz-Security-Token", valid_606928
  var valid_606929 = header.getOrDefault("X-Amz-Algorithm")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "X-Amz-Algorithm", valid_606929
  var valid_606930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606930 = validateParameter(valid_606930, JString, required = false,
                                 default = nil)
  if valid_606930 != nil:
    section.add "X-Amz-SignedHeaders", valid_606930
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_606931 = formData.getOrDefault("Subnets")
  valid_606931 = validateParameter(valid_606931, JArray, required = true, default = nil)
  if valid_606931 != nil:
    section.add "Subnets", valid_606931
  var valid_606932 = formData.getOrDefault("LoadBalancerName")
  valid_606932 = validateParameter(valid_606932, JString, required = true,
                                 default = nil)
  if valid_606932 != nil:
    section.add "LoadBalancerName", valid_606932
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606933: Call_PostDetachLoadBalancerFromSubnets_606919;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_606933.validator(path, query, header, formData, body)
  let scheme = call_606933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606933.url(scheme.get, call_606933.host, call_606933.base,
                         call_606933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606933, url, valid)

proc call*(call_606934: Call_PostDetachLoadBalancerFromSubnets_606919;
          Subnets: JsonNode; LoadBalancerName: string;
          Action: string = "DetachLoadBalancerFromSubnets";
          Version: string = "2012-06-01"): Recallable =
  ## postDetachLoadBalancerFromSubnets
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606935 = newJObject()
  var formData_606936 = newJObject()
  if Subnets != nil:
    formData_606936.add "Subnets", Subnets
  add(formData_606936, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606935, "Action", newJString(Action))
  add(query_606935, "Version", newJString(Version))
  result = call_606934.call(nil, query_606935, nil, formData_606936, nil)

var postDetachLoadBalancerFromSubnets* = Call_PostDetachLoadBalancerFromSubnets_606919(
    name: "postDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_PostDetachLoadBalancerFromSubnets_606920, base: "/",
    url: url_PostDetachLoadBalancerFromSubnets_606921,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetachLoadBalancerFromSubnets_606902 = ref object of OpenApiRestCall_605589
proc url_GetDetachLoadBalancerFromSubnets_606904(protocol: Scheme; host: string;
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

proc validate_GetDetachLoadBalancerFromSubnets_606903(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_606905 = query.getOrDefault("LoadBalancerName")
  valid_606905 = validateParameter(valid_606905, JString, required = true,
                                 default = nil)
  if valid_606905 != nil:
    section.add "LoadBalancerName", valid_606905
  var valid_606906 = query.getOrDefault("Action")
  valid_606906 = validateParameter(valid_606906, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_606906 != nil:
    section.add "Action", valid_606906
  var valid_606907 = query.getOrDefault("Subnets")
  valid_606907 = validateParameter(valid_606907, JArray, required = true, default = nil)
  if valid_606907 != nil:
    section.add "Subnets", valid_606907
  var valid_606908 = query.getOrDefault("Version")
  valid_606908 = validateParameter(valid_606908, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606908 != nil:
    section.add "Version", valid_606908
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
  var valid_606909 = header.getOrDefault("X-Amz-Signature")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Signature", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-Content-Sha256", valid_606910
  var valid_606911 = header.getOrDefault("X-Amz-Date")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "X-Amz-Date", valid_606911
  var valid_606912 = header.getOrDefault("X-Amz-Credential")
  valid_606912 = validateParameter(valid_606912, JString, required = false,
                                 default = nil)
  if valid_606912 != nil:
    section.add "X-Amz-Credential", valid_606912
  var valid_606913 = header.getOrDefault("X-Amz-Security-Token")
  valid_606913 = validateParameter(valid_606913, JString, required = false,
                                 default = nil)
  if valid_606913 != nil:
    section.add "X-Amz-Security-Token", valid_606913
  var valid_606914 = header.getOrDefault("X-Amz-Algorithm")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "X-Amz-Algorithm", valid_606914
  var valid_606915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = nil)
  if valid_606915 != nil:
    section.add "X-Amz-SignedHeaders", valid_606915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606916: Call_GetDetachLoadBalancerFromSubnets_606902;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_606916.validator(path, query, header, formData, body)
  let scheme = call_606916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606916.url(scheme.get, call_606916.host, call_606916.base,
                         call_606916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606916, url, valid)

proc call*(call_606917: Call_GetDetachLoadBalancerFromSubnets_606902;
          LoadBalancerName: string; Subnets: JsonNode;
          Action: string = "DetachLoadBalancerFromSubnets";
          Version: string = "2012-06-01"): Recallable =
  ## getDetachLoadBalancerFromSubnets
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   Version: string (required)
  var query_606918 = newJObject()
  add(query_606918, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606918, "Action", newJString(Action))
  if Subnets != nil:
    query_606918.add "Subnets", Subnets
  add(query_606918, "Version", newJString(Version))
  result = call_606917.call(nil, query_606918, nil, nil, nil)

var getDetachLoadBalancerFromSubnets* = Call_GetDetachLoadBalancerFromSubnets_606902(
    name: "getDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_GetDetachLoadBalancerFromSubnets_606903, base: "/",
    url: url_GetDetachLoadBalancerFromSubnets_606904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAvailabilityZonesForLoadBalancer_606954 = ref object of OpenApiRestCall_605589
proc url_PostDisableAvailabilityZonesForLoadBalancer_606956(protocol: Scheme;
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

proc validate_PostDisableAvailabilityZonesForLoadBalancer_606955(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606957 = query.getOrDefault("Action")
  valid_606957 = validateParameter(valid_606957, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_606957 != nil:
    section.add "Action", valid_606957
  var valid_606958 = query.getOrDefault("Version")
  valid_606958 = validateParameter(valid_606958, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606958 != nil:
    section.add "Version", valid_606958
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
  var valid_606959 = header.getOrDefault("X-Amz-Signature")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-Signature", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-Content-Sha256", valid_606960
  var valid_606961 = header.getOrDefault("X-Amz-Date")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Date", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-Credential")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-Credential", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-Security-Token")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-Security-Token", valid_606963
  var valid_606964 = header.getOrDefault("X-Amz-Algorithm")
  valid_606964 = validateParameter(valid_606964, JString, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "X-Amz-Algorithm", valid_606964
  var valid_606965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-SignedHeaders", valid_606965
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_606966 = formData.getOrDefault("AvailabilityZones")
  valid_606966 = validateParameter(valid_606966, JArray, required = true, default = nil)
  if valid_606966 != nil:
    section.add "AvailabilityZones", valid_606966
  var valid_606967 = formData.getOrDefault("LoadBalancerName")
  valid_606967 = validateParameter(valid_606967, JString, required = true,
                                 default = nil)
  if valid_606967 != nil:
    section.add "LoadBalancerName", valid_606967
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606968: Call_PostDisableAvailabilityZonesForLoadBalancer_606954;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606968.validator(path, query, header, formData, body)
  let scheme = call_606968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606968.url(scheme.get, call_606968.host, call_606968.base,
                         call_606968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606968, url, valid)

proc call*(call_606969: Call_PostDisableAvailabilityZonesForLoadBalancer_606954;
          AvailabilityZones: JsonNode; LoadBalancerName: string;
          Action: string = "DisableAvailabilityZonesForLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDisableAvailabilityZonesForLoadBalancer
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606970 = newJObject()
  var formData_606971 = newJObject()
  if AvailabilityZones != nil:
    formData_606971.add "AvailabilityZones", AvailabilityZones
  add(formData_606971, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606970, "Action", newJString(Action))
  add(query_606970, "Version", newJString(Version))
  result = call_606969.call(nil, query_606970, nil, formData_606971, nil)

var postDisableAvailabilityZonesForLoadBalancer* = Call_PostDisableAvailabilityZonesForLoadBalancer_606954(
    name: "postDisableAvailabilityZonesForLoadBalancer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_PostDisableAvailabilityZonesForLoadBalancer_606955,
    base: "/", url: url_PostDisableAvailabilityZonesForLoadBalancer_606956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAvailabilityZonesForLoadBalancer_606937 = ref object of OpenApiRestCall_605589
proc url_GetDisableAvailabilityZonesForLoadBalancer_606939(protocol: Scheme;
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

proc validate_GetDisableAvailabilityZonesForLoadBalancer_606938(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AvailabilityZones` field"
  var valid_606940 = query.getOrDefault("AvailabilityZones")
  valid_606940 = validateParameter(valid_606940, JArray, required = true, default = nil)
  if valid_606940 != nil:
    section.add "AvailabilityZones", valid_606940
  var valid_606941 = query.getOrDefault("LoadBalancerName")
  valid_606941 = validateParameter(valid_606941, JString, required = true,
                                 default = nil)
  if valid_606941 != nil:
    section.add "LoadBalancerName", valid_606941
  var valid_606942 = query.getOrDefault("Action")
  valid_606942 = validateParameter(valid_606942, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_606942 != nil:
    section.add "Action", valid_606942
  var valid_606943 = query.getOrDefault("Version")
  valid_606943 = validateParameter(valid_606943, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606943 != nil:
    section.add "Version", valid_606943
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
  var valid_606944 = header.getOrDefault("X-Amz-Signature")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "X-Amz-Signature", valid_606944
  var valid_606945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-Content-Sha256", valid_606945
  var valid_606946 = header.getOrDefault("X-Amz-Date")
  valid_606946 = validateParameter(valid_606946, JString, required = false,
                                 default = nil)
  if valid_606946 != nil:
    section.add "X-Amz-Date", valid_606946
  var valid_606947 = header.getOrDefault("X-Amz-Credential")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Credential", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-Security-Token")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-Security-Token", valid_606948
  var valid_606949 = header.getOrDefault("X-Amz-Algorithm")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "X-Amz-Algorithm", valid_606949
  var valid_606950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-SignedHeaders", valid_606950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606951: Call_GetDisableAvailabilityZonesForLoadBalancer_606937;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606951.validator(path, query, header, formData, body)
  let scheme = call_606951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606951.url(scheme.get, call_606951.host, call_606951.base,
                         call_606951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606951, url, valid)

proc call*(call_606952: Call_GetDisableAvailabilityZonesForLoadBalancer_606937;
          AvailabilityZones: JsonNode; LoadBalancerName: string;
          Action: string = "DisableAvailabilityZonesForLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDisableAvailabilityZonesForLoadBalancer
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606953 = newJObject()
  if AvailabilityZones != nil:
    query_606953.add "AvailabilityZones", AvailabilityZones
  add(query_606953, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606953, "Action", newJString(Action))
  add(query_606953, "Version", newJString(Version))
  result = call_606952.call(nil, query_606953, nil, nil, nil)

var getDisableAvailabilityZonesForLoadBalancer* = Call_GetDisableAvailabilityZonesForLoadBalancer_606937(
    name: "getDisableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_GetDisableAvailabilityZonesForLoadBalancer_606938,
    base: "/", url: url_GetDisableAvailabilityZonesForLoadBalancer_606939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAvailabilityZonesForLoadBalancer_606989 = ref object of OpenApiRestCall_605589
proc url_PostEnableAvailabilityZonesForLoadBalancer_606991(protocol: Scheme;
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

proc validate_PostEnableAvailabilityZonesForLoadBalancer_606990(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606992 = query.getOrDefault("Action")
  valid_606992 = validateParameter(valid_606992, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_606992 != nil:
    section.add "Action", valid_606992
  var valid_606993 = query.getOrDefault("Version")
  valid_606993 = validateParameter(valid_606993, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606993 != nil:
    section.add "Version", valid_606993
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
  var valid_606994 = header.getOrDefault("X-Amz-Signature")
  valid_606994 = validateParameter(valid_606994, JString, required = false,
                                 default = nil)
  if valid_606994 != nil:
    section.add "X-Amz-Signature", valid_606994
  var valid_606995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606995 = validateParameter(valid_606995, JString, required = false,
                                 default = nil)
  if valid_606995 != nil:
    section.add "X-Amz-Content-Sha256", valid_606995
  var valid_606996 = header.getOrDefault("X-Amz-Date")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "X-Amz-Date", valid_606996
  var valid_606997 = header.getOrDefault("X-Amz-Credential")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-Credential", valid_606997
  var valid_606998 = header.getOrDefault("X-Amz-Security-Token")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-Security-Token", valid_606998
  var valid_606999 = header.getOrDefault("X-Amz-Algorithm")
  valid_606999 = validateParameter(valid_606999, JString, required = false,
                                 default = nil)
  if valid_606999 != nil:
    section.add "X-Amz-Algorithm", valid_606999
  var valid_607000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "X-Amz-SignedHeaders", valid_607000
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_607001 = formData.getOrDefault("AvailabilityZones")
  valid_607001 = validateParameter(valid_607001, JArray, required = true, default = nil)
  if valid_607001 != nil:
    section.add "AvailabilityZones", valid_607001
  var valid_607002 = formData.getOrDefault("LoadBalancerName")
  valid_607002 = validateParameter(valid_607002, JString, required = true,
                                 default = nil)
  if valid_607002 != nil:
    section.add "LoadBalancerName", valid_607002
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607003: Call_PostEnableAvailabilityZonesForLoadBalancer_606989;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_607003.validator(path, query, header, formData, body)
  let scheme = call_607003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607003.url(scheme.get, call_607003.host, call_607003.base,
                         call_607003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607003, url, valid)

proc call*(call_607004: Call_PostEnableAvailabilityZonesForLoadBalancer_606989;
          AvailabilityZones: JsonNode; LoadBalancerName: string;
          Action: string = "EnableAvailabilityZonesForLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postEnableAvailabilityZonesForLoadBalancer
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607005 = newJObject()
  var formData_607006 = newJObject()
  if AvailabilityZones != nil:
    formData_607006.add "AvailabilityZones", AvailabilityZones
  add(formData_607006, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_607005, "Action", newJString(Action))
  add(query_607005, "Version", newJString(Version))
  result = call_607004.call(nil, query_607005, nil, formData_607006, nil)

var postEnableAvailabilityZonesForLoadBalancer* = Call_PostEnableAvailabilityZonesForLoadBalancer_606989(
    name: "postEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_PostEnableAvailabilityZonesForLoadBalancer_606990,
    base: "/", url: url_PostEnableAvailabilityZonesForLoadBalancer_606991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAvailabilityZonesForLoadBalancer_606972 = ref object of OpenApiRestCall_605589
proc url_GetEnableAvailabilityZonesForLoadBalancer_606974(protocol: Scheme;
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

proc validate_GetEnableAvailabilityZonesForLoadBalancer_606973(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AvailabilityZones` field"
  var valid_606975 = query.getOrDefault("AvailabilityZones")
  valid_606975 = validateParameter(valid_606975, JArray, required = true, default = nil)
  if valid_606975 != nil:
    section.add "AvailabilityZones", valid_606975
  var valid_606976 = query.getOrDefault("LoadBalancerName")
  valid_606976 = validateParameter(valid_606976, JString, required = true,
                                 default = nil)
  if valid_606976 != nil:
    section.add "LoadBalancerName", valid_606976
  var valid_606977 = query.getOrDefault("Action")
  valid_606977 = validateParameter(valid_606977, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_606977 != nil:
    section.add "Action", valid_606977
  var valid_606978 = query.getOrDefault("Version")
  valid_606978 = validateParameter(valid_606978, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_606978 != nil:
    section.add "Version", valid_606978
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
  var valid_606979 = header.getOrDefault("X-Amz-Signature")
  valid_606979 = validateParameter(valid_606979, JString, required = false,
                                 default = nil)
  if valid_606979 != nil:
    section.add "X-Amz-Signature", valid_606979
  var valid_606980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606980 = validateParameter(valid_606980, JString, required = false,
                                 default = nil)
  if valid_606980 != nil:
    section.add "X-Amz-Content-Sha256", valid_606980
  var valid_606981 = header.getOrDefault("X-Amz-Date")
  valid_606981 = validateParameter(valid_606981, JString, required = false,
                                 default = nil)
  if valid_606981 != nil:
    section.add "X-Amz-Date", valid_606981
  var valid_606982 = header.getOrDefault("X-Amz-Credential")
  valid_606982 = validateParameter(valid_606982, JString, required = false,
                                 default = nil)
  if valid_606982 != nil:
    section.add "X-Amz-Credential", valid_606982
  var valid_606983 = header.getOrDefault("X-Amz-Security-Token")
  valid_606983 = validateParameter(valid_606983, JString, required = false,
                                 default = nil)
  if valid_606983 != nil:
    section.add "X-Amz-Security-Token", valid_606983
  var valid_606984 = header.getOrDefault("X-Amz-Algorithm")
  valid_606984 = validateParameter(valid_606984, JString, required = false,
                                 default = nil)
  if valid_606984 != nil:
    section.add "X-Amz-Algorithm", valid_606984
  var valid_606985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606985 = validateParameter(valid_606985, JString, required = false,
                                 default = nil)
  if valid_606985 != nil:
    section.add "X-Amz-SignedHeaders", valid_606985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606986: Call_GetEnableAvailabilityZonesForLoadBalancer_606972;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_606986.validator(path, query, header, formData, body)
  let scheme = call_606986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606986.url(scheme.get, call_606986.host, call_606986.base,
                         call_606986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606986, url, valid)

proc call*(call_606987: Call_GetEnableAvailabilityZonesForLoadBalancer_606972;
          AvailabilityZones: JsonNode; LoadBalancerName: string;
          Action: string = "EnableAvailabilityZonesForLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getEnableAvailabilityZonesForLoadBalancer
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606988 = newJObject()
  if AvailabilityZones != nil:
    query_606988.add "AvailabilityZones", AvailabilityZones
  add(query_606988, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_606988, "Action", newJString(Action))
  add(query_606988, "Version", newJString(Version))
  result = call_606987.call(nil, query_606988, nil, nil, nil)

var getEnableAvailabilityZonesForLoadBalancer* = Call_GetEnableAvailabilityZonesForLoadBalancer_606972(
    name: "getEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_GetEnableAvailabilityZonesForLoadBalancer_606973,
    base: "/", url: url_GetEnableAvailabilityZonesForLoadBalancer_606974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_607028 = ref object of OpenApiRestCall_605589
proc url_PostModifyLoadBalancerAttributes_607030(protocol: Scheme; host: string;
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

proc validate_PostModifyLoadBalancerAttributes_607029(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607031 = query.getOrDefault("Action")
  valid_607031 = validateParameter(valid_607031, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_607031 != nil:
    section.add "Action", valid_607031
  var valid_607032 = query.getOrDefault("Version")
  valid_607032 = validateParameter(valid_607032, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_607032 != nil:
    section.add "Version", valid_607032
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
  var valid_607033 = header.getOrDefault("X-Amz-Signature")
  valid_607033 = validateParameter(valid_607033, JString, required = false,
                                 default = nil)
  if valid_607033 != nil:
    section.add "X-Amz-Signature", valid_607033
  var valid_607034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-Content-Sha256", valid_607034
  var valid_607035 = header.getOrDefault("X-Amz-Date")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-Date", valid_607035
  var valid_607036 = header.getOrDefault("X-Amz-Credential")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Credential", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-Security-Token")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Security-Token", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-Algorithm")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-Algorithm", valid_607038
  var valid_607039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "X-Amz-SignedHeaders", valid_607039
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerAttributes.CrossZoneLoadBalancing: JString
  ##                                                : The attributes for a load balancer.
  ## <p>If enabled, the load balancer routes the request traffic evenly across all instances regardless of the Availability Zones.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Configure Cross-Zone Load Balancing</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributes.AdditionalAttributes: JArray
  ##                                              : The attributes for a load balancer.
  ## This parameter is reserved.
  ##   LoadBalancerAttributes.ConnectionDraining: JString
  ##                                            : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows existing requests to complete before the load balancer shifts traffic away from a deregistered or unhealthy instance.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Configure Connection Draining</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerAttributes.ConnectionSettings: JString
  ##                                            : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows the connections to remain idle (no data is sent over the connection) for the specified duration.</p> <p>By default, Elastic Load Balancing maintains a 60-second idle connection timeout for both front-end and back-end connections of your load balancer. For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Configure Idle Connection Timeout</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributes.AccessLog: JString
  ##                                   : The attributes for a load balancer.
  ## <p>If enabled, the load balancer captures detailed information of all requests and delivers the information to the Amazon S3 bucket that you specify.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html">Enable Access Logs</a> in the <i>Classic Load Balancers Guide</i>.</p>
  section = newJObject()
  var valid_607040 = formData.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_607040
  var valid_607041 = formData.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_607041 = validateParameter(valid_607041, JArray, required = false,
                                 default = nil)
  if valid_607041 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_607041
  var valid_607042 = formData.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_607042 = validateParameter(valid_607042, JString, required = false,
                                 default = nil)
  if valid_607042 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_607042
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_607043 = formData.getOrDefault("LoadBalancerName")
  valid_607043 = validateParameter(valid_607043, JString, required = true,
                                 default = nil)
  if valid_607043 != nil:
    section.add "LoadBalancerName", valid_607043
  var valid_607044 = formData.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_607044
  var valid_607045 = formData.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_607045
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607046: Call_PostModifyLoadBalancerAttributes_607028;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_607046.validator(path, query, header, formData, body)
  let scheme = call_607046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607046.url(scheme.get, call_607046.host, call_607046.base,
                         call_607046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607046, url, valid)

proc call*(call_607047: Call_PostModifyLoadBalancerAttributes_607028;
          LoadBalancerName: string;
          LoadBalancerAttributesCrossZoneLoadBalancing: string = "";
          LoadBalancerAttributesAdditionalAttributes: JsonNode = nil;
          LoadBalancerAttributesConnectionDraining: string = "";
          Action: string = "ModifyLoadBalancerAttributes";
          LoadBalancerAttributesConnectionSettings: string = "";
          Version: string = "2012-06-01";
          LoadBalancerAttributesAccessLog: string = ""): Recallable =
  ## postModifyLoadBalancerAttributes
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ##   LoadBalancerAttributesCrossZoneLoadBalancing: string
  ##                                               : The attributes for a load balancer.
  ## <p>If enabled, the load balancer routes the request traffic evenly across all instances regardless of the Availability Zones.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Configure Cross-Zone Load Balancing</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributesAdditionalAttributes: JArray
  ##                                             : The attributes for a load balancer.
  ## This parameter is reserved.
  ##   LoadBalancerAttributesConnectionDraining: string
  ##                                           : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows existing requests to complete before the load balancer shifts traffic away from a deregistered or unhealthy instance.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Configure Connection Draining</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   LoadBalancerAttributesConnectionSettings: string
  ##                                           : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows the connections to remain idle (no data is sent over the connection) for the specified duration.</p> <p>By default, Elastic Load Balancing maintains a 60-second idle connection timeout for both front-end and back-end connections of your load balancer. For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Configure Idle Connection Timeout</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Version: string (required)
  ##   LoadBalancerAttributesAccessLog: string
  ##                                  : The attributes for a load balancer.
  ## <p>If enabled, the load balancer captures detailed information of all requests and delivers the information to the Amazon S3 bucket that you specify.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html">Enable Access Logs</a> in the <i>Classic Load Balancers Guide</i>.</p>
  var query_607048 = newJObject()
  var formData_607049 = newJObject()
  add(formData_607049, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    formData_607049.add "LoadBalancerAttributes.AdditionalAttributes",
                       LoadBalancerAttributesAdditionalAttributes
  add(formData_607049, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(formData_607049, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_607048, "Action", newJString(Action))
  add(formData_607049, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_607048, "Version", newJString(Version))
  add(formData_607049, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  result = call_607047.call(nil, query_607048, nil, formData_607049, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_607028(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_607029, base: "/",
    url: url_PostModifyLoadBalancerAttributes_607030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_607007 = ref object of OpenApiRestCall_605589
proc url_GetModifyLoadBalancerAttributes_607009(protocol: Scheme; host: string;
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

proc validate_GetModifyLoadBalancerAttributes_607008(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerAttributes.ConnectionSettings: JString
  ##                                            : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows the connections to remain idle (no data is sent over the connection) for the specified duration.</p> <p>By default, Elastic Load Balancing maintains a 60-second idle connection timeout for both front-end and back-end connections of your load balancer. For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Configure Idle Connection Timeout</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributes.AccessLog: JString
  ##                                   : The attributes for a load balancer.
  ## <p>If enabled, the load balancer captures detailed information of all requests and delivers the information to the Amazon S3 bucket that you specify.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html">Enable Access Logs</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributes.ConnectionDraining: JString
  ##                                            : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows existing requests to complete before the load balancer shifts traffic away from a deregistered or unhealthy instance.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Configure Connection Draining</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerAttributes.CrossZoneLoadBalancing: JString
  ##                                                : The attributes for a load balancer.
  ## <p>If enabled, the load balancer routes the request traffic evenly across all instances regardless of the Availability Zones.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Configure Cross-Zone Load Balancing</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   LoadBalancerAttributes.AdditionalAttributes: JArray
  ##                                              : The attributes for a load balancer.
  ## This parameter is reserved.
  section = newJObject()
  var valid_607010 = query.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_607010
  var valid_607011 = query.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_607011
  var valid_607012 = query.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_607012 = validateParameter(valid_607012, JString, required = false,
                                 default = nil)
  if valid_607012 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_607012
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_607013 = query.getOrDefault("LoadBalancerName")
  valid_607013 = validateParameter(valid_607013, JString, required = true,
                                 default = nil)
  if valid_607013 != nil:
    section.add "LoadBalancerName", valid_607013
  var valid_607014 = query.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_607014 = validateParameter(valid_607014, JString, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_607014
  var valid_607015 = query.getOrDefault("Action")
  valid_607015 = validateParameter(valid_607015, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_607015 != nil:
    section.add "Action", valid_607015
  var valid_607016 = query.getOrDefault("Version")
  valid_607016 = validateParameter(valid_607016, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_607016 != nil:
    section.add "Version", valid_607016
  var valid_607017 = query.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_607017 = validateParameter(valid_607017, JArray, required = false,
                                 default = nil)
  if valid_607017 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_607017
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
  var valid_607018 = header.getOrDefault("X-Amz-Signature")
  valid_607018 = validateParameter(valid_607018, JString, required = false,
                                 default = nil)
  if valid_607018 != nil:
    section.add "X-Amz-Signature", valid_607018
  var valid_607019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607019 = validateParameter(valid_607019, JString, required = false,
                                 default = nil)
  if valid_607019 != nil:
    section.add "X-Amz-Content-Sha256", valid_607019
  var valid_607020 = header.getOrDefault("X-Amz-Date")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "X-Amz-Date", valid_607020
  var valid_607021 = header.getOrDefault("X-Amz-Credential")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Credential", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Security-Token")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Security-Token", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-Algorithm")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-Algorithm", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-SignedHeaders", valid_607024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607025: Call_GetModifyLoadBalancerAttributes_607007;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_607025.validator(path, query, header, formData, body)
  let scheme = call_607025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607025.url(scheme.get, call_607025.host, call_607025.base,
                         call_607025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607025, url, valid)

proc call*(call_607026: Call_GetModifyLoadBalancerAttributes_607007;
          LoadBalancerName: string;
          LoadBalancerAttributesConnectionSettings: string = "";
          LoadBalancerAttributesAccessLog: string = "";
          LoadBalancerAttributesConnectionDraining: string = "";
          LoadBalancerAttributesCrossZoneLoadBalancing: string = "";
          Action: string = "ModifyLoadBalancerAttributes";
          Version: string = "2012-06-01";
          LoadBalancerAttributesAdditionalAttributes: JsonNode = nil): Recallable =
  ## getModifyLoadBalancerAttributes
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ##   LoadBalancerAttributesConnectionSettings: string
  ##                                           : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows the connections to remain idle (no data is sent over the connection) for the specified duration.</p> <p>By default, Elastic Load Balancing maintains a 60-second idle connection timeout for both front-end and back-end connections of your load balancer. For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Configure Idle Connection Timeout</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributesAccessLog: string
  ##                                  : The attributes for a load balancer.
  ## <p>If enabled, the load balancer captures detailed information of all requests and delivers the information to the Amazon S3 bucket that you specify.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html">Enable Access Logs</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributesConnectionDraining: string
  ##                                           : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows existing requests to complete before the load balancer shifts traffic away from a deregistered or unhealthy instance.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Configure Connection Draining</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerAttributesCrossZoneLoadBalancing: string
  ##                                               : The attributes for a load balancer.
  ## <p>If enabled, the load balancer routes the request traffic evenly across all instances regardless of the Availability Zones.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Configure Cross-Zone Load Balancing</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerAttributesAdditionalAttributes: JArray
  ##                                             : The attributes for a load balancer.
  ## This parameter is reserved.
  var query_607027 = newJObject()
  add(query_607027, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_607027, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_607027, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_607027, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_607027, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  add(query_607027, "Action", newJString(Action))
  add(query_607027, "Version", newJString(Version))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    query_607027.add "LoadBalancerAttributes.AdditionalAttributes",
                    LoadBalancerAttributesAdditionalAttributes
  result = call_607026.call(nil, query_607027, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_607007(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_607008, base: "/",
    url: url_GetModifyLoadBalancerAttributes_607009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterInstancesWithLoadBalancer_607067 = ref object of OpenApiRestCall_605589
proc url_PostRegisterInstancesWithLoadBalancer_607069(protocol: Scheme;
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

proc validate_PostRegisterInstancesWithLoadBalancer_607068(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607070 = query.getOrDefault("Action")
  valid_607070 = validateParameter(valid_607070, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_607070 != nil:
    section.add "Action", valid_607070
  var valid_607071 = query.getOrDefault("Version")
  valid_607071 = validateParameter(valid_607071, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_607071 != nil:
    section.add "Version", valid_607071
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
  var valid_607072 = header.getOrDefault("X-Amz-Signature")
  valid_607072 = validateParameter(valid_607072, JString, required = false,
                                 default = nil)
  if valid_607072 != nil:
    section.add "X-Amz-Signature", valid_607072
  var valid_607073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607073 = validateParameter(valid_607073, JString, required = false,
                                 default = nil)
  if valid_607073 != nil:
    section.add "X-Amz-Content-Sha256", valid_607073
  var valid_607074 = header.getOrDefault("X-Amz-Date")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-Date", valid_607074
  var valid_607075 = header.getOrDefault("X-Amz-Credential")
  valid_607075 = validateParameter(valid_607075, JString, required = false,
                                 default = nil)
  if valid_607075 != nil:
    section.add "X-Amz-Credential", valid_607075
  var valid_607076 = header.getOrDefault("X-Amz-Security-Token")
  valid_607076 = validateParameter(valid_607076, JString, required = false,
                                 default = nil)
  if valid_607076 != nil:
    section.add "X-Amz-Security-Token", valid_607076
  var valid_607077 = header.getOrDefault("X-Amz-Algorithm")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-Algorithm", valid_607077
  var valid_607078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-SignedHeaders", valid_607078
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_607079 = formData.getOrDefault("Instances")
  valid_607079 = validateParameter(valid_607079, JArray, required = true, default = nil)
  if valid_607079 != nil:
    section.add "Instances", valid_607079
  var valid_607080 = formData.getOrDefault("LoadBalancerName")
  valid_607080 = validateParameter(valid_607080, JString, required = true,
                                 default = nil)
  if valid_607080 != nil:
    section.add "LoadBalancerName", valid_607080
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607081: Call_PostRegisterInstancesWithLoadBalancer_607067;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_607081.validator(path, query, header, formData, body)
  let scheme = call_607081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607081.url(scheme.get, call_607081.host, call_607081.base,
                         call_607081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607081, url, valid)

proc call*(call_607082: Call_PostRegisterInstancesWithLoadBalancer_607067;
          Instances: JsonNode; LoadBalancerName: string;
          Action: string = "RegisterInstancesWithLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postRegisterInstancesWithLoadBalancer
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607083 = newJObject()
  var formData_607084 = newJObject()
  if Instances != nil:
    formData_607084.add "Instances", Instances
  add(formData_607084, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_607083, "Action", newJString(Action))
  add(query_607083, "Version", newJString(Version))
  result = call_607082.call(nil, query_607083, nil, formData_607084, nil)

var postRegisterInstancesWithLoadBalancer* = Call_PostRegisterInstancesWithLoadBalancer_607067(
    name: "postRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_PostRegisterInstancesWithLoadBalancer_607068, base: "/",
    url: url_PostRegisterInstancesWithLoadBalancer_607069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterInstancesWithLoadBalancer_607050 = ref object of OpenApiRestCall_605589
proc url_GetRegisterInstancesWithLoadBalancer_607052(protocol: Scheme;
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

proc validate_GetRegisterInstancesWithLoadBalancer_607051(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_607053 = query.getOrDefault("LoadBalancerName")
  valid_607053 = validateParameter(valid_607053, JString, required = true,
                                 default = nil)
  if valid_607053 != nil:
    section.add "LoadBalancerName", valid_607053
  var valid_607054 = query.getOrDefault("Action")
  valid_607054 = validateParameter(valid_607054, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_607054 != nil:
    section.add "Action", valid_607054
  var valid_607055 = query.getOrDefault("Instances")
  valid_607055 = validateParameter(valid_607055, JArray, required = true, default = nil)
  if valid_607055 != nil:
    section.add "Instances", valid_607055
  var valid_607056 = query.getOrDefault("Version")
  valid_607056 = validateParameter(valid_607056, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_607056 != nil:
    section.add "Version", valid_607056
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
  var valid_607057 = header.getOrDefault("X-Amz-Signature")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "X-Amz-Signature", valid_607057
  var valid_607058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "X-Amz-Content-Sha256", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Date")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Date", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Credential")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Credential", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-Security-Token")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-Security-Token", valid_607061
  var valid_607062 = header.getOrDefault("X-Amz-Algorithm")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "X-Amz-Algorithm", valid_607062
  var valid_607063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-SignedHeaders", valid_607063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607064: Call_GetRegisterInstancesWithLoadBalancer_607050;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_607064.validator(path, query, header, formData, body)
  let scheme = call_607064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607064.url(scheme.get, call_607064.host, call_607064.base,
                         call_607064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607064, url, valid)

proc call*(call_607065: Call_GetRegisterInstancesWithLoadBalancer_607050;
          LoadBalancerName: string; Instances: JsonNode;
          Action: string = "RegisterInstancesWithLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getRegisterInstancesWithLoadBalancer
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   Version: string (required)
  var query_607066 = newJObject()
  add(query_607066, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_607066, "Action", newJString(Action))
  if Instances != nil:
    query_607066.add "Instances", Instances
  add(query_607066, "Version", newJString(Version))
  result = call_607065.call(nil, query_607066, nil, nil, nil)

var getRegisterInstancesWithLoadBalancer* = Call_GetRegisterInstancesWithLoadBalancer_607050(
    name: "getRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_GetRegisterInstancesWithLoadBalancer_607051, base: "/",
    url: url_GetRegisterInstancesWithLoadBalancer_607052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_607102 = ref object of OpenApiRestCall_605589
proc url_PostRemoveTags_607104(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemoveTags_607103(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Removes one or more tags from the specified load balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607105 = query.getOrDefault("Action")
  valid_607105 = validateParameter(valid_607105, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_607105 != nil:
    section.add "Action", valid_607105
  var valid_607106 = query.getOrDefault("Version")
  valid_607106 = validateParameter(valid_607106, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_607106 != nil:
    section.add "Version", valid_607106
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
  var valid_607107 = header.getOrDefault("X-Amz-Signature")
  valid_607107 = validateParameter(valid_607107, JString, required = false,
                                 default = nil)
  if valid_607107 != nil:
    section.add "X-Amz-Signature", valid_607107
  var valid_607108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607108 = validateParameter(valid_607108, JString, required = false,
                                 default = nil)
  if valid_607108 != nil:
    section.add "X-Amz-Content-Sha256", valid_607108
  var valid_607109 = header.getOrDefault("X-Amz-Date")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Date", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Credential")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Credential", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Security-Token")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Security-Token", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-Algorithm")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-Algorithm", valid_607112
  var valid_607113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-SignedHeaders", valid_607113
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_607114 = formData.getOrDefault("LoadBalancerNames")
  valid_607114 = validateParameter(valid_607114, JArray, required = true, default = nil)
  if valid_607114 != nil:
    section.add "LoadBalancerNames", valid_607114
  var valid_607115 = formData.getOrDefault("Tags")
  valid_607115 = validateParameter(valid_607115, JArray, required = true, default = nil)
  if valid_607115 != nil:
    section.add "Tags", valid_607115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607116: Call_PostRemoveTags_607102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_607116.validator(path, query, header, formData, body)
  let scheme = call_607116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607116.url(scheme.get, call_607116.host, call_607116.base,
                         call_607116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607116, url, valid)

proc call*(call_607117: Call_PostRemoveTags_607102; LoadBalancerNames: JsonNode;
          Tags: JsonNode; Action: string = "RemoveTags";
          Version: string = "2012-06-01"): Recallable =
  ## postRemoveTags
  ## Removes one or more tags from the specified load balancer.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  ##   Version: string (required)
  var query_607118 = newJObject()
  var formData_607119 = newJObject()
  if LoadBalancerNames != nil:
    formData_607119.add "LoadBalancerNames", LoadBalancerNames
  add(query_607118, "Action", newJString(Action))
  if Tags != nil:
    formData_607119.add "Tags", Tags
  add(query_607118, "Version", newJString(Version))
  result = call_607117.call(nil, query_607118, nil, formData_607119, nil)

var postRemoveTags* = Call_PostRemoveTags_607102(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_607103,
    base: "/", url: url_PostRemoveTags_607104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_607085 = ref object of OpenApiRestCall_605589
proc url_GetRemoveTags_607087(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemoveTags_607086(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags from the specified load balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_607088 = query.getOrDefault("Tags")
  valid_607088 = validateParameter(valid_607088, JArray, required = true, default = nil)
  if valid_607088 != nil:
    section.add "Tags", valid_607088
  var valid_607089 = query.getOrDefault("Action")
  valid_607089 = validateParameter(valid_607089, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_607089 != nil:
    section.add "Action", valid_607089
  var valid_607090 = query.getOrDefault("Version")
  valid_607090 = validateParameter(valid_607090, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_607090 != nil:
    section.add "Version", valid_607090
  var valid_607091 = query.getOrDefault("LoadBalancerNames")
  valid_607091 = validateParameter(valid_607091, JArray, required = true, default = nil)
  if valid_607091 != nil:
    section.add "LoadBalancerNames", valid_607091
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
  var valid_607092 = header.getOrDefault("X-Amz-Signature")
  valid_607092 = validateParameter(valid_607092, JString, required = false,
                                 default = nil)
  if valid_607092 != nil:
    section.add "X-Amz-Signature", valid_607092
  var valid_607093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607093 = validateParameter(valid_607093, JString, required = false,
                                 default = nil)
  if valid_607093 != nil:
    section.add "X-Amz-Content-Sha256", valid_607093
  var valid_607094 = header.getOrDefault("X-Amz-Date")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "X-Amz-Date", valid_607094
  var valid_607095 = header.getOrDefault("X-Amz-Credential")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "X-Amz-Credential", valid_607095
  var valid_607096 = header.getOrDefault("X-Amz-Security-Token")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "X-Amz-Security-Token", valid_607096
  var valid_607097 = header.getOrDefault("X-Amz-Algorithm")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "X-Amz-Algorithm", valid_607097
  var valid_607098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "X-Amz-SignedHeaders", valid_607098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607099: Call_GetRemoveTags_607085; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_607099.validator(path, query, header, formData, body)
  let scheme = call_607099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607099.url(scheme.get, call_607099.host, call_607099.base,
                         call_607099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607099, url, valid)

proc call*(call_607100: Call_GetRemoveTags_607085; Tags: JsonNode;
          LoadBalancerNames: JsonNode; Action: string = "RemoveTags";
          Version: string = "2012-06-01"): Recallable =
  ## getRemoveTags
  ## Removes one or more tags from the specified load balancer.
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  var query_607101 = newJObject()
  if Tags != nil:
    query_607101.add "Tags", Tags
  add(query_607101, "Action", newJString(Action))
  add(query_607101, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_607101.add "LoadBalancerNames", LoadBalancerNames
  result = call_607100.call(nil, query_607101, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_607085(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_607086,
    base: "/", url: url_GetRemoveTags_607087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerListenerSSLCertificate_607138 = ref object of OpenApiRestCall_605589
proc url_PostSetLoadBalancerListenerSSLCertificate_607140(protocol: Scheme;
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

proc validate_PostSetLoadBalancerListenerSSLCertificate_607139(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607141 = query.getOrDefault("Action")
  valid_607141 = validateParameter(valid_607141, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_607141 != nil:
    section.add "Action", valid_607141
  var valid_607142 = query.getOrDefault("Version")
  valid_607142 = validateParameter(valid_607142, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_607142 != nil:
    section.add "Version", valid_607142
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
  var valid_607143 = header.getOrDefault("X-Amz-Signature")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "X-Amz-Signature", valid_607143
  var valid_607144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607144 = validateParameter(valid_607144, JString, required = false,
                                 default = nil)
  if valid_607144 != nil:
    section.add "X-Amz-Content-Sha256", valid_607144
  var valid_607145 = header.getOrDefault("X-Amz-Date")
  valid_607145 = validateParameter(valid_607145, JString, required = false,
                                 default = nil)
  if valid_607145 != nil:
    section.add "X-Amz-Date", valid_607145
  var valid_607146 = header.getOrDefault("X-Amz-Credential")
  valid_607146 = validateParameter(valid_607146, JString, required = false,
                                 default = nil)
  if valid_607146 != nil:
    section.add "X-Amz-Credential", valid_607146
  var valid_607147 = header.getOrDefault("X-Amz-Security-Token")
  valid_607147 = validateParameter(valid_607147, JString, required = false,
                                 default = nil)
  if valid_607147 != nil:
    section.add "X-Amz-Security-Token", valid_607147
  var valid_607148 = header.getOrDefault("X-Amz-Algorithm")
  valid_607148 = validateParameter(valid_607148, JString, required = false,
                                 default = nil)
  if valid_607148 != nil:
    section.add "X-Amz-Algorithm", valid_607148
  var valid_607149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607149 = validateParameter(valid_607149, JString, required = false,
                                 default = nil)
  if valid_607149 != nil:
    section.add "X-Amz-SignedHeaders", valid_607149
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   SSLCertificateId: JString (required)
  ##                   : The Amazon Resource Name (ARN) of the SSL certificate.
  ##   LoadBalancerPort: JInt (required)
  ##                   : The port that uses the specified SSL certificate.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_607150 = formData.getOrDefault("LoadBalancerName")
  valid_607150 = validateParameter(valid_607150, JString, required = true,
                                 default = nil)
  if valid_607150 != nil:
    section.add "LoadBalancerName", valid_607150
  var valid_607151 = formData.getOrDefault("SSLCertificateId")
  valid_607151 = validateParameter(valid_607151, JString, required = true,
                                 default = nil)
  if valid_607151 != nil:
    section.add "SSLCertificateId", valid_607151
  var valid_607152 = formData.getOrDefault("LoadBalancerPort")
  valid_607152 = validateParameter(valid_607152, JInt, required = true, default = nil)
  if valid_607152 != nil:
    section.add "LoadBalancerPort", valid_607152
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607153: Call_PostSetLoadBalancerListenerSSLCertificate_607138;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_607153.validator(path, query, header, formData, body)
  let scheme = call_607153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607153.url(scheme.get, call_607153.host, call_607153.base,
                         call_607153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607153, url, valid)

proc call*(call_607154: Call_PostSetLoadBalancerListenerSSLCertificate_607138;
          LoadBalancerName: string; SSLCertificateId: string; LoadBalancerPort: int;
          Action: string = "SetLoadBalancerListenerSSLCertificate";
          Version: string = "2012-06-01"): Recallable =
  ## postSetLoadBalancerListenerSSLCertificate
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   SSLCertificateId: string (required)
  ##                   : The Amazon Resource Name (ARN) of the SSL certificate.
  ##   Version: string (required)
  ##   LoadBalancerPort: int (required)
  ##                   : The port that uses the specified SSL certificate.
  var query_607155 = newJObject()
  var formData_607156 = newJObject()
  add(formData_607156, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_607155, "Action", newJString(Action))
  add(formData_607156, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_607155, "Version", newJString(Version))
  add(formData_607156, "LoadBalancerPort", newJInt(LoadBalancerPort))
  result = call_607154.call(nil, query_607155, nil, formData_607156, nil)

var postSetLoadBalancerListenerSSLCertificate* = Call_PostSetLoadBalancerListenerSSLCertificate_607138(
    name: "postSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_PostSetLoadBalancerListenerSSLCertificate_607139,
    base: "/", url: url_PostSetLoadBalancerListenerSSLCertificate_607140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerListenerSSLCertificate_607120 = ref object of OpenApiRestCall_605589
proc url_GetSetLoadBalancerListenerSSLCertificate_607122(protocol: Scheme;
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

proc validate_GetSetLoadBalancerListenerSSLCertificate_607121(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerPort: JInt (required)
  ##                   : The port that uses the specified SSL certificate.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   SSLCertificateId: JString (required)
  ##                   : The Amazon Resource Name (ARN) of the SSL certificate.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerPort` field"
  var valid_607123 = query.getOrDefault("LoadBalancerPort")
  valid_607123 = validateParameter(valid_607123, JInt, required = true, default = nil)
  if valid_607123 != nil:
    section.add "LoadBalancerPort", valid_607123
  var valid_607124 = query.getOrDefault("LoadBalancerName")
  valid_607124 = validateParameter(valid_607124, JString, required = true,
                                 default = nil)
  if valid_607124 != nil:
    section.add "LoadBalancerName", valid_607124
  var valid_607125 = query.getOrDefault("Action")
  valid_607125 = validateParameter(valid_607125, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_607125 != nil:
    section.add "Action", valid_607125
  var valid_607126 = query.getOrDefault("Version")
  valid_607126 = validateParameter(valid_607126, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_607126 != nil:
    section.add "Version", valid_607126
  var valid_607127 = query.getOrDefault("SSLCertificateId")
  valid_607127 = validateParameter(valid_607127, JString, required = true,
                                 default = nil)
  if valid_607127 != nil:
    section.add "SSLCertificateId", valid_607127
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
  var valid_607128 = header.getOrDefault("X-Amz-Signature")
  valid_607128 = validateParameter(valid_607128, JString, required = false,
                                 default = nil)
  if valid_607128 != nil:
    section.add "X-Amz-Signature", valid_607128
  var valid_607129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607129 = validateParameter(valid_607129, JString, required = false,
                                 default = nil)
  if valid_607129 != nil:
    section.add "X-Amz-Content-Sha256", valid_607129
  var valid_607130 = header.getOrDefault("X-Amz-Date")
  valid_607130 = validateParameter(valid_607130, JString, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "X-Amz-Date", valid_607130
  var valid_607131 = header.getOrDefault("X-Amz-Credential")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "X-Amz-Credential", valid_607131
  var valid_607132 = header.getOrDefault("X-Amz-Security-Token")
  valid_607132 = validateParameter(valid_607132, JString, required = false,
                                 default = nil)
  if valid_607132 != nil:
    section.add "X-Amz-Security-Token", valid_607132
  var valid_607133 = header.getOrDefault("X-Amz-Algorithm")
  valid_607133 = validateParameter(valid_607133, JString, required = false,
                                 default = nil)
  if valid_607133 != nil:
    section.add "X-Amz-Algorithm", valid_607133
  var valid_607134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607134 = validateParameter(valid_607134, JString, required = false,
                                 default = nil)
  if valid_607134 != nil:
    section.add "X-Amz-SignedHeaders", valid_607134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607135: Call_GetSetLoadBalancerListenerSSLCertificate_607120;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_607135.validator(path, query, header, formData, body)
  let scheme = call_607135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607135.url(scheme.get, call_607135.host, call_607135.base,
                         call_607135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607135, url, valid)

proc call*(call_607136: Call_GetSetLoadBalancerListenerSSLCertificate_607120;
          LoadBalancerPort: int; LoadBalancerName: string; SSLCertificateId: string;
          Action: string = "SetLoadBalancerListenerSSLCertificate";
          Version: string = "2012-06-01"): Recallable =
  ## getSetLoadBalancerListenerSSLCertificate
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerPort: int (required)
  ##                   : The port that uses the specified SSL certificate.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SSLCertificateId: string (required)
  ##                   : The Amazon Resource Name (ARN) of the SSL certificate.
  var query_607137 = newJObject()
  add(query_607137, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_607137, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_607137, "Action", newJString(Action))
  add(query_607137, "Version", newJString(Version))
  add(query_607137, "SSLCertificateId", newJString(SSLCertificateId))
  result = call_607136.call(nil, query_607137, nil, nil, nil)

var getSetLoadBalancerListenerSSLCertificate* = Call_GetSetLoadBalancerListenerSSLCertificate_607120(
    name: "getSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_GetSetLoadBalancerListenerSSLCertificate_607121,
    base: "/", url: url_GetSetLoadBalancerListenerSSLCertificate_607122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesForBackendServer_607175 = ref object of OpenApiRestCall_605589
proc url_PostSetLoadBalancerPoliciesForBackendServer_607177(protocol: Scheme;
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

proc validate_PostSetLoadBalancerPoliciesForBackendServer_607176(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607178 = query.getOrDefault("Action")
  valid_607178 = validateParameter(valid_607178, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_607178 != nil:
    section.add "Action", valid_607178
  var valid_607179 = query.getOrDefault("Version")
  valid_607179 = validateParameter(valid_607179, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_607179 != nil:
    section.add "Version", valid_607179
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
  var valid_607180 = header.getOrDefault("X-Amz-Signature")
  valid_607180 = validateParameter(valid_607180, JString, required = false,
                                 default = nil)
  if valid_607180 != nil:
    section.add "X-Amz-Signature", valid_607180
  var valid_607181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607181 = validateParameter(valid_607181, JString, required = false,
                                 default = nil)
  if valid_607181 != nil:
    section.add "X-Amz-Content-Sha256", valid_607181
  var valid_607182 = header.getOrDefault("X-Amz-Date")
  valid_607182 = validateParameter(valid_607182, JString, required = false,
                                 default = nil)
  if valid_607182 != nil:
    section.add "X-Amz-Date", valid_607182
  var valid_607183 = header.getOrDefault("X-Amz-Credential")
  valid_607183 = validateParameter(valid_607183, JString, required = false,
                                 default = nil)
  if valid_607183 != nil:
    section.add "X-Amz-Credential", valid_607183
  var valid_607184 = header.getOrDefault("X-Amz-Security-Token")
  valid_607184 = validateParameter(valid_607184, JString, required = false,
                                 default = nil)
  if valid_607184 != nil:
    section.add "X-Amz-Security-Token", valid_607184
  var valid_607185 = header.getOrDefault("X-Amz-Algorithm")
  valid_607185 = validateParameter(valid_607185, JString, required = false,
                                 default = nil)
  if valid_607185 != nil:
    section.add "X-Amz-Algorithm", valid_607185
  var valid_607186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607186 = validateParameter(valid_607186, JString, required = false,
                                 default = nil)
  if valid_607186 != nil:
    section.add "X-Amz-SignedHeaders", valid_607186
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. If the list is empty, then all current polices are removed from the EC2 instance.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   InstancePort: JInt (required)
  ##               : The port number associated with the EC2 instance.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PolicyNames` field"
  var valid_607187 = formData.getOrDefault("PolicyNames")
  valid_607187 = validateParameter(valid_607187, JArray, required = true, default = nil)
  if valid_607187 != nil:
    section.add "PolicyNames", valid_607187
  var valid_607188 = formData.getOrDefault("LoadBalancerName")
  valid_607188 = validateParameter(valid_607188, JString, required = true,
                                 default = nil)
  if valid_607188 != nil:
    section.add "LoadBalancerName", valid_607188
  var valid_607189 = formData.getOrDefault("InstancePort")
  valid_607189 = validateParameter(valid_607189, JInt, required = true, default = nil)
  if valid_607189 != nil:
    section.add "InstancePort", valid_607189
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607190: Call_PostSetLoadBalancerPoliciesForBackendServer_607175;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_607190.validator(path, query, header, formData, body)
  let scheme = call_607190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607190.url(scheme.get, call_607190.host, call_607190.base,
                         call_607190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607190, url, valid)

proc call*(call_607191: Call_PostSetLoadBalancerPoliciesForBackendServer_607175;
          PolicyNames: JsonNode; LoadBalancerName: string; InstancePort: int;
          Action: string = "SetLoadBalancerPoliciesForBackendServer";
          Version: string = "2012-06-01"): Recallable =
  ## postSetLoadBalancerPoliciesForBackendServer
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. If the list is empty, then all current polices are removed from the EC2 instance.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   InstancePort: int (required)
  ##               : The port number associated with the EC2 instance.
  ##   Version: string (required)
  var query_607192 = newJObject()
  var formData_607193 = newJObject()
  if PolicyNames != nil:
    formData_607193.add "PolicyNames", PolicyNames
  add(formData_607193, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_607192, "Action", newJString(Action))
  add(formData_607193, "InstancePort", newJInt(InstancePort))
  add(query_607192, "Version", newJString(Version))
  result = call_607191.call(nil, query_607192, nil, formData_607193, nil)

var postSetLoadBalancerPoliciesForBackendServer* = Call_PostSetLoadBalancerPoliciesForBackendServer_607175(
    name: "postSetLoadBalancerPoliciesForBackendServer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_PostSetLoadBalancerPoliciesForBackendServer_607176,
    base: "/", url: url_PostSetLoadBalancerPoliciesForBackendServer_607177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesForBackendServer_607157 = ref object of OpenApiRestCall_605589
proc url_GetSetLoadBalancerPoliciesForBackendServer_607159(protocol: Scheme;
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

proc validate_GetSetLoadBalancerPoliciesForBackendServer_607158(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   InstancePort: JInt (required)
  ##               : The port number associated with the EC2 instance.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. If the list is empty, then all current polices are removed from the EC2 instance.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `InstancePort` field"
  var valid_607160 = query.getOrDefault("InstancePort")
  valid_607160 = validateParameter(valid_607160, JInt, required = true, default = nil)
  if valid_607160 != nil:
    section.add "InstancePort", valid_607160
  var valid_607161 = query.getOrDefault("LoadBalancerName")
  valid_607161 = validateParameter(valid_607161, JString, required = true,
                                 default = nil)
  if valid_607161 != nil:
    section.add "LoadBalancerName", valid_607161
  var valid_607162 = query.getOrDefault("Action")
  valid_607162 = validateParameter(valid_607162, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_607162 != nil:
    section.add "Action", valid_607162
  var valid_607163 = query.getOrDefault("Version")
  valid_607163 = validateParameter(valid_607163, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_607163 != nil:
    section.add "Version", valid_607163
  var valid_607164 = query.getOrDefault("PolicyNames")
  valid_607164 = validateParameter(valid_607164, JArray, required = true, default = nil)
  if valid_607164 != nil:
    section.add "PolicyNames", valid_607164
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
  var valid_607165 = header.getOrDefault("X-Amz-Signature")
  valid_607165 = validateParameter(valid_607165, JString, required = false,
                                 default = nil)
  if valid_607165 != nil:
    section.add "X-Amz-Signature", valid_607165
  var valid_607166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607166 = validateParameter(valid_607166, JString, required = false,
                                 default = nil)
  if valid_607166 != nil:
    section.add "X-Amz-Content-Sha256", valid_607166
  var valid_607167 = header.getOrDefault("X-Amz-Date")
  valid_607167 = validateParameter(valid_607167, JString, required = false,
                                 default = nil)
  if valid_607167 != nil:
    section.add "X-Amz-Date", valid_607167
  var valid_607168 = header.getOrDefault("X-Amz-Credential")
  valid_607168 = validateParameter(valid_607168, JString, required = false,
                                 default = nil)
  if valid_607168 != nil:
    section.add "X-Amz-Credential", valid_607168
  var valid_607169 = header.getOrDefault("X-Amz-Security-Token")
  valid_607169 = validateParameter(valid_607169, JString, required = false,
                                 default = nil)
  if valid_607169 != nil:
    section.add "X-Amz-Security-Token", valid_607169
  var valid_607170 = header.getOrDefault("X-Amz-Algorithm")
  valid_607170 = validateParameter(valid_607170, JString, required = false,
                                 default = nil)
  if valid_607170 != nil:
    section.add "X-Amz-Algorithm", valid_607170
  var valid_607171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607171 = validateParameter(valid_607171, JString, required = false,
                                 default = nil)
  if valid_607171 != nil:
    section.add "X-Amz-SignedHeaders", valid_607171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607172: Call_GetSetLoadBalancerPoliciesForBackendServer_607157;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_607172.validator(path, query, header, formData, body)
  let scheme = call_607172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607172.url(scheme.get, call_607172.host, call_607172.base,
                         call_607172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607172, url, valid)

proc call*(call_607173: Call_GetSetLoadBalancerPoliciesForBackendServer_607157;
          InstancePort: int; LoadBalancerName: string; PolicyNames: JsonNode;
          Action: string = "SetLoadBalancerPoliciesForBackendServer";
          Version: string = "2012-06-01"): Recallable =
  ## getSetLoadBalancerPoliciesForBackendServer
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   InstancePort: int (required)
  ##               : The port number associated with the EC2 instance.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. If the list is empty, then all current polices are removed from the EC2 instance.
  var query_607174 = newJObject()
  add(query_607174, "InstancePort", newJInt(InstancePort))
  add(query_607174, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_607174, "Action", newJString(Action))
  add(query_607174, "Version", newJString(Version))
  if PolicyNames != nil:
    query_607174.add "PolicyNames", PolicyNames
  result = call_607173.call(nil, query_607174, nil, nil, nil)

var getSetLoadBalancerPoliciesForBackendServer* = Call_GetSetLoadBalancerPoliciesForBackendServer_607157(
    name: "getSetLoadBalancerPoliciesForBackendServer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_GetSetLoadBalancerPoliciesForBackendServer_607158,
    base: "/", url: url_GetSetLoadBalancerPoliciesForBackendServer_607159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesOfListener_607212 = ref object of OpenApiRestCall_605589
proc url_PostSetLoadBalancerPoliciesOfListener_607214(protocol: Scheme;
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

proc validate_PostSetLoadBalancerPoliciesOfListener_607213(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607215 = query.getOrDefault("Action")
  valid_607215 = validateParameter(valid_607215, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_607215 != nil:
    section.add "Action", valid_607215
  var valid_607216 = query.getOrDefault("Version")
  valid_607216 = validateParameter(valid_607216, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_607216 != nil:
    section.add "Version", valid_607216
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
  var valid_607217 = header.getOrDefault("X-Amz-Signature")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Signature", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-Content-Sha256", valid_607218
  var valid_607219 = header.getOrDefault("X-Amz-Date")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "X-Amz-Date", valid_607219
  var valid_607220 = header.getOrDefault("X-Amz-Credential")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-Credential", valid_607220
  var valid_607221 = header.getOrDefault("X-Amz-Security-Token")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-Security-Token", valid_607221
  var valid_607222 = header.getOrDefault("X-Amz-Algorithm")
  valid_607222 = validateParameter(valid_607222, JString, required = false,
                                 default = nil)
  if valid_607222 != nil:
    section.add "X-Amz-Algorithm", valid_607222
  var valid_607223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607223 = validateParameter(valid_607223, JString, required = false,
                                 default = nil)
  if valid_607223 != nil:
    section.add "X-Amz-SignedHeaders", valid_607223
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. This list must include all policies to be enabled. If you omit a policy that is currently enabled, it is disabled. If the list is empty, all current policies are disabled.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerPort: JInt (required)
  ##                   : The external port of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PolicyNames` field"
  var valid_607224 = formData.getOrDefault("PolicyNames")
  valid_607224 = validateParameter(valid_607224, JArray, required = true, default = nil)
  if valid_607224 != nil:
    section.add "PolicyNames", valid_607224
  var valid_607225 = formData.getOrDefault("LoadBalancerName")
  valid_607225 = validateParameter(valid_607225, JString, required = true,
                                 default = nil)
  if valid_607225 != nil:
    section.add "LoadBalancerName", valid_607225
  var valid_607226 = formData.getOrDefault("LoadBalancerPort")
  valid_607226 = validateParameter(valid_607226, JInt, required = true, default = nil)
  if valid_607226 != nil:
    section.add "LoadBalancerPort", valid_607226
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607227: Call_PostSetLoadBalancerPoliciesOfListener_607212;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_607227.validator(path, query, header, formData, body)
  let scheme = call_607227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607227.url(scheme.get, call_607227.host, call_607227.base,
                         call_607227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607227, url, valid)

proc call*(call_607228: Call_PostSetLoadBalancerPoliciesOfListener_607212;
          PolicyNames: JsonNode; LoadBalancerName: string; LoadBalancerPort: int;
          Action: string = "SetLoadBalancerPoliciesOfListener";
          Version: string = "2012-06-01"): Recallable =
  ## postSetLoadBalancerPoliciesOfListener
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. This list must include all policies to be enabled. If you omit a policy that is currently enabled, it is disabled. If the list is empty, all current policies are disabled.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerPort: int (required)
  ##                   : The external port of the load balancer.
  var query_607229 = newJObject()
  var formData_607230 = newJObject()
  if PolicyNames != nil:
    formData_607230.add "PolicyNames", PolicyNames
  add(formData_607230, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_607229, "Action", newJString(Action))
  add(query_607229, "Version", newJString(Version))
  add(formData_607230, "LoadBalancerPort", newJInt(LoadBalancerPort))
  result = call_607228.call(nil, query_607229, nil, formData_607230, nil)

var postSetLoadBalancerPoliciesOfListener* = Call_PostSetLoadBalancerPoliciesOfListener_607212(
    name: "postSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_PostSetLoadBalancerPoliciesOfListener_607213, base: "/",
    url: url_PostSetLoadBalancerPoliciesOfListener_607214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesOfListener_607194 = ref object of OpenApiRestCall_605589
proc url_GetSetLoadBalancerPoliciesOfListener_607196(protocol: Scheme;
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

proc validate_GetSetLoadBalancerPoliciesOfListener_607195(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerPort: JInt (required)
  ##                   : The external port of the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. This list must include all policies to be enabled. If you omit a policy that is currently enabled, it is disabled. If the list is empty, all current policies are disabled.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerPort` field"
  var valid_607197 = query.getOrDefault("LoadBalancerPort")
  valid_607197 = validateParameter(valid_607197, JInt, required = true, default = nil)
  if valid_607197 != nil:
    section.add "LoadBalancerPort", valid_607197
  var valid_607198 = query.getOrDefault("LoadBalancerName")
  valid_607198 = validateParameter(valid_607198, JString, required = true,
                                 default = nil)
  if valid_607198 != nil:
    section.add "LoadBalancerName", valid_607198
  var valid_607199 = query.getOrDefault("Action")
  valid_607199 = validateParameter(valid_607199, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_607199 != nil:
    section.add "Action", valid_607199
  var valid_607200 = query.getOrDefault("Version")
  valid_607200 = validateParameter(valid_607200, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_607200 != nil:
    section.add "Version", valid_607200
  var valid_607201 = query.getOrDefault("PolicyNames")
  valid_607201 = validateParameter(valid_607201, JArray, required = true, default = nil)
  if valid_607201 != nil:
    section.add "PolicyNames", valid_607201
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
  var valid_607202 = header.getOrDefault("X-Amz-Signature")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Signature", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-Content-Sha256", valid_607203
  var valid_607204 = header.getOrDefault("X-Amz-Date")
  valid_607204 = validateParameter(valid_607204, JString, required = false,
                                 default = nil)
  if valid_607204 != nil:
    section.add "X-Amz-Date", valid_607204
  var valid_607205 = header.getOrDefault("X-Amz-Credential")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-Credential", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-Security-Token")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-Security-Token", valid_607206
  var valid_607207 = header.getOrDefault("X-Amz-Algorithm")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "X-Amz-Algorithm", valid_607207
  var valid_607208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607208 = validateParameter(valid_607208, JString, required = false,
                                 default = nil)
  if valid_607208 != nil:
    section.add "X-Amz-SignedHeaders", valid_607208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607209: Call_GetSetLoadBalancerPoliciesOfListener_607194;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_607209.validator(path, query, header, formData, body)
  let scheme = call_607209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607209.url(scheme.get, call_607209.host, call_607209.base,
                         call_607209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607209, url, valid)

proc call*(call_607210: Call_GetSetLoadBalancerPoliciesOfListener_607194;
          LoadBalancerPort: int; LoadBalancerName: string; PolicyNames: JsonNode;
          Action: string = "SetLoadBalancerPoliciesOfListener";
          Version: string = "2012-06-01"): Recallable =
  ## getSetLoadBalancerPoliciesOfListener
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerPort: int (required)
  ##                   : The external port of the load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. This list must include all policies to be enabled. If you omit a policy that is currently enabled, it is disabled. If the list is empty, all current policies are disabled.
  var query_607211 = newJObject()
  add(query_607211, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_607211, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_607211, "Action", newJString(Action))
  add(query_607211, "Version", newJString(Version))
  if PolicyNames != nil:
    query_607211.add "PolicyNames", PolicyNames
  result = call_607210.call(nil, query_607211, nil, nil, nil)

var getSetLoadBalancerPoliciesOfListener* = Call_GetSetLoadBalancerPoliciesOfListener_607194(
    name: "getSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_GetSetLoadBalancerPoliciesOfListener_607195, base: "/",
    url: url_GetSetLoadBalancerPoliciesOfListener_607196,
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
