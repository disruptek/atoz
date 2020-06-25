
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PostAddTags_21626035 = ref object of OpenApiRestCall_21625435
proc url_PostAddTags_21626037(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTags_21626036(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626038 = query.getOrDefault("Action")
  valid_21626038 = validateParameter(valid_21626038, JString, required = true,
                                   default = newJString("AddTags"))
  if valid_21626038 != nil:
    section.add "Action", valid_21626038
  var valid_21626039 = query.getOrDefault("Version")
  valid_21626039 = validateParameter(valid_21626039, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626039 != nil:
    section.add "Version", valid_21626039
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
  var valid_21626040 = header.getOrDefault("X-Amz-Date")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Date", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Security-Token", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Algorithm", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Signature")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Signature", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Credential")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Credential", valid_21626046
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_21626047 = formData.getOrDefault("Tags")
  valid_21626047 = validateParameter(valid_21626047, JArray, required = true,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "Tags", valid_21626047
  var valid_21626048 = formData.getOrDefault("LoadBalancerNames")
  valid_21626048 = validateParameter(valid_21626048, JArray, required = true,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "LoadBalancerNames", valid_21626048
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626049: Call_PostAddTags_21626035; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626049.validator(path, query, header, formData, body, _)
  let scheme = call_21626049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626049.makeUrl(scheme.get, call_21626049.host, call_21626049.base,
                               call_21626049.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626049, uri, valid, _)

proc call*(call_21626050: Call_PostAddTags_21626035; Tags: JsonNode;
          LoadBalancerNames: JsonNode; Action: string = "AddTags";
          Version: string = "2012-06-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Version: string (required)
  var query_21626051 = newJObject()
  var formData_21626052 = newJObject()
  if Tags != nil:
    formData_21626052.add "Tags", Tags
  add(query_21626051, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_21626052.add "LoadBalancerNames", LoadBalancerNames
  add(query_21626051, "Version", newJString(Version))
  result = call_21626050.call(nil, query_21626051, nil, formData_21626052, nil)

var postAddTags* = Call_PostAddTags_21626035(name: "postAddTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AddTags", validator: validate_PostAddTags_21626036, base: "/",
    makeUrl: url_PostAddTags_21626037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetAddTags_21625781(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTags_21625780(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_21625882 = query.getOrDefault("Tags")
  valid_21625882 = validateParameter(valid_21625882, JArray, required = true,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "Tags", valid_21625882
  var valid_21625897 = query.getOrDefault("Action")
  valid_21625897 = validateParameter(valid_21625897, JString, required = true,
                                   default = newJString("AddTags"))
  if valid_21625897 != nil:
    section.add "Action", valid_21625897
  var valid_21625898 = query.getOrDefault("LoadBalancerNames")
  valid_21625898 = validateParameter(valid_21625898, JArray, required = true,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "LoadBalancerNames", valid_21625898
  var valid_21625899 = query.getOrDefault("Version")
  valid_21625899 = validateParameter(valid_21625899, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21625899 != nil:
    section.add "Version", valid_21625899
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
  var valid_21625900 = header.getOrDefault("X-Amz-Date")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Date", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Security-Token", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Algorithm", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-Signature")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-Signature", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625905
  var valid_21625906 = header.getOrDefault("X-Amz-Credential")
  valid_21625906 = validateParameter(valid_21625906, JString, required = false,
                                   default = nil)
  if valid_21625906 != nil:
    section.add "X-Amz-Credential", valid_21625906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625931: Call_GetAddTags_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21625931.validator(path, query, header, formData, body, _)
  let scheme = call_21625931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625931.makeUrl(scheme.get, call_21625931.host, call_21625931.base,
                               call_21625931.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625931, uri, valid, _)

proc call*(call_21625994: Call_GetAddTags_21625779; Tags: JsonNode;
          LoadBalancerNames: JsonNode; Action: string = "AddTags";
          Version: string = "2012-06-01"): Recallable =
  ## getAddTags
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Version: string (required)
  var query_21625996 = newJObject()
  if Tags != nil:
    query_21625996.add "Tags", Tags
  add(query_21625996, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_21625996.add "LoadBalancerNames", LoadBalancerNames
  add(query_21625996, "Version", newJString(Version))
  result = call_21625994.call(nil, query_21625996, nil, nil, nil)

var getAddTags* = Call_GetAddTags_21625779(name: "getAddTags",
                                        meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_GetAddTags_21625780,
                                        base: "/", makeUrl: url_GetAddTags_21625781,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplySecurityGroupsToLoadBalancer_21626070 = ref object of OpenApiRestCall_21625435
proc url_PostApplySecurityGroupsToLoadBalancer_21626072(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostApplySecurityGroupsToLoadBalancer_21626071(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626073 = query.getOrDefault("Action")
  valid_21626073 = validateParameter(valid_21626073, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_21626073 != nil:
    section.add "Action", valid_21626073
  var valid_21626074 = query.getOrDefault("Version")
  valid_21626074 = validateParameter(valid_21626074, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626074 != nil:
    section.add "Version", valid_21626074
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
  var valid_21626075 = header.getOrDefault("X-Amz-Date")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Date", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Security-Token", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Algorithm", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Signature")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Signature", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Credential")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Credential", valid_21626081
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_21626082 = formData.getOrDefault("SecurityGroups")
  valid_21626082 = validateParameter(valid_21626082, JArray, required = true,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "SecurityGroups", valid_21626082
  var valid_21626083 = formData.getOrDefault("LoadBalancerName")
  valid_21626083 = validateParameter(valid_21626083, JString, required = true,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "LoadBalancerName", valid_21626083
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626084: Call_PostApplySecurityGroupsToLoadBalancer_21626070;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626084.validator(path, query, header, formData, body, _)
  let scheme = call_21626084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626084.makeUrl(scheme.get, call_21626084.host, call_21626084.base,
                               call_21626084.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626084, uri, valid, _)

proc call*(call_21626085: Call_PostApplySecurityGroupsToLoadBalancer_21626070;
          SecurityGroups: JsonNode; LoadBalancerName: string;
          Action: string = "ApplySecurityGroupsToLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postApplySecurityGroupsToLoadBalancer
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626086 = newJObject()
  var formData_21626087 = newJObject()
  add(query_21626086, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_21626087.add "SecurityGroups", SecurityGroups
  add(formData_21626087, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626086, "Version", newJString(Version))
  result = call_21626085.call(nil, query_21626086, nil, formData_21626087, nil)

var postApplySecurityGroupsToLoadBalancer* = Call_PostApplySecurityGroupsToLoadBalancer_21626070(
    name: "postApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_PostApplySecurityGroupsToLoadBalancer_21626071, base: "/",
    makeUrl: url_PostApplySecurityGroupsToLoadBalancer_21626072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplySecurityGroupsToLoadBalancer_21626053 = ref object of OpenApiRestCall_21625435
proc url_GetApplySecurityGroupsToLoadBalancer_21626055(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplySecurityGroupsToLoadBalancer_21626054(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
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
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626056 = query.getOrDefault("LoadBalancerName")
  valid_21626056 = validateParameter(valid_21626056, JString, required = true,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "LoadBalancerName", valid_21626056
  var valid_21626057 = query.getOrDefault("Action")
  valid_21626057 = validateParameter(valid_21626057, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_21626057 != nil:
    section.add "Action", valid_21626057
  var valid_21626058 = query.getOrDefault("Version")
  valid_21626058 = validateParameter(valid_21626058, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626058 != nil:
    section.add "Version", valid_21626058
  var valid_21626059 = query.getOrDefault("SecurityGroups")
  valid_21626059 = validateParameter(valid_21626059, JArray, required = true,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "SecurityGroups", valid_21626059
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
  var valid_21626060 = header.getOrDefault("X-Amz-Date")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Date", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Security-Token", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Algorithm", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Signature")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Signature", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Credential")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Credential", valid_21626066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626067: Call_GetApplySecurityGroupsToLoadBalancer_21626053;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626067.validator(path, query, header, formData, body, _)
  let scheme = call_21626067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626067.makeUrl(scheme.get, call_21626067.host, call_21626067.base,
                               call_21626067.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626067, uri, valid, _)

proc call*(call_21626068: Call_GetApplySecurityGroupsToLoadBalancer_21626053;
          LoadBalancerName: string; SecurityGroups: JsonNode;
          Action: string = "ApplySecurityGroupsToLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getApplySecurityGroupsToLoadBalancer
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  var query_21626069 = newJObject()
  add(query_21626069, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626069, "Action", newJString(Action))
  add(query_21626069, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_21626069.add "SecurityGroups", SecurityGroups
  result = call_21626068.call(nil, query_21626069, nil, nil, nil)

var getApplySecurityGroupsToLoadBalancer* = Call_GetApplySecurityGroupsToLoadBalancer_21626053(
    name: "getApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_GetApplySecurityGroupsToLoadBalancer_21626054, base: "/",
    makeUrl: url_GetApplySecurityGroupsToLoadBalancer_21626055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAttachLoadBalancerToSubnets_21626105 = ref object of OpenApiRestCall_21625435
proc url_PostAttachLoadBalancerToSubnets_21626107(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAttachLoadBalancerToSubnets_21626106(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626108 = query.getOrDefault("Action")
  valid_21626108 = validateParameter(valid_21626108, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_21626108 != nil:
    section.add "Action", valid_21626108
  var valid_21626109 = query.getOrDefault("Version")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626109 != nil:
    section.add "Version", valid_21626109
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
  var valid_21626110 = header.getOrDefault("X-Amz-Date")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Date", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Security-Token", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Algorithm", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Signature")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Signature", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Credential")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Credential", valid_21626116
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_21626117 = formData.getOrDefault("Subnets")
  valid_21626117 = validateParameter(valid_21626117, JArray, required = true,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "Subnets", valid_21626117
  var valid_21626118 = formData.getOrDefault("LoadBalancerName")
  valid_21626118 = validateParameter(valid_21626118, JString, required = true,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "LoadBalancerName", valid_21626118
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626119: Call_PostAttachLoadBalancerToSubnets_21626105;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626119.validator(path, query, header, formData, body, _)
  let scheme = call_21626119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626119.makeUrl(scheme.get, call_21626119.host, call_21626119.base,
                               call_21626119.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626119, uri, valid, _)

proc call*(call_21626120: Call_PostAttachLoadBalancerToSubnets_21626105;
          Subnets: JsonNode; LoadBalancerName: string;
          Action: string = "AttachLoadBalancerToSubnets";
          Version: string = "2012-06-01"): Recallable =
  ## postAttachLoadBalancerToSubnets
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626121 = newJObject()
  var formData_21626122 = newJObject()
  add(query_21626121, "Action", newJString(Action))
  if Subnets != nil:
    formData_21626122.add "Subnets", Subnets
  add(formData_21626122, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626121, "Version", newJString(Version))
  result = call_21626120.call(nil, query_21626121, nil, formData_21626122, nil)

var postAttachLoadBalancerToSubnets* = Call_PostAttachLoadBalancerToSubnets_21626105(
    name: "postAttachLoadBalancerToSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_PostAttachLoadBalancerToSubnets_21626106, base: "/",
    makeUrl: url_PostAttachLoadBalancerToSubnets_21626107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttachLoadBalancerToSubnets_21626088 = ref object of OpenApiRestCall_21625435
proc url_GetAttachLoadBalancerToSubnets_21626090(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAttachLoadBalancerToSubnets_21626089(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626091 = query.getOrDefault("LoadBalancerName")
  valid_21626091 = validateParameter(valid_21626091, JString, required = true,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "LoadBalancerName", valid_21626091
  var valid_21626092 = query.getOrDefault("Action")
  valid_21626092 = validateParameter(valid_21626092, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_21626092 != nil:
    section.add "Action", valid_21626092
  var valid_21626093 = query.getOrDefault("Subnets")
  valid_21626093 = validateParameter(valid_21626093, JArray, required = true,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "Subnets", valid_21626093
  var valid_21626094 = query.getOrDefault("Version")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626094 != nil:
    section.add "Version", valid_21626094
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
  var valid_21626095 = header.getOrDefault("X-Amz-Date")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Date", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Security-Token", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Algorithm", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Signature")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Signature", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Credential")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Credential", valid_21626101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626102: Call_GetAttachLoadBalancerToSubnets_21626088;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626102.validator(path, query, header, formData, body, _)
  let scheme = call_21626102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626102.makeUrl(scheme.get, call_21626102.host, call_21626102.base,
                               call_21626102.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626102, uri, valid, _)

proc call*(call_21626103: Call_GetAttachLoadBalancerToSubnets_21626088;
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
  var query_21626104 = newJObject()
  add(query_21626104, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626104, "Action", newJString(Action))
  if Subnets != nil:
    query_21626104.add "Subnets", Subnets
  add(query_21626104, "Version", newJString(Version))
  result = call_21626103.call(nil, query_21626104, nil, nil, nil)

var getAttachLoadBalancerToSubnets* = Call_GetAttachLoadBalancerToSubnets_21626088(
    name: "getAttachLoadBalancerToSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_GetAttachLoadBalancerToSubnets_21626089, base: "/",
    makeUrl: url_GetAttachLoadBalancerToSubnets_21626090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfigureHealthCheck_21626145 = ref object of OpenApiRestCall_21625435
proc url_PostConfigureHealthCheck_21626147(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostConfigureHealthCheck_21626146(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626148 = query.getOrDefault("Action")
  valid_21626148 = validateParameter(valid_21626148, JString, required = true,
                                   default = newJString("ConfigureHealthCheck"))
  if valid_21626148 != nil:
    section.add "Action", valid_21626148
  var valid_21626149 = query.getOrDefault("Version")
  valid_21626149 = validateParameter(valid_21626149, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626149 != nil:
    section.add "Version", valid_21626149
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
  var valid_21626150 = header.getOrDefault("X-Amz-Date")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Date", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Security-Token", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Algorithm", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Signature")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Signature", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Credential")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Credential", valid_21626156
  result.add "header", section
  ## parameters in `formData` object:
  ##   HealthCheck.HealthyThreshold: JString
  ##                               : Information about a health check.
  ## The number of consecutive health checks successes required before moving the instance to the <code>Healthy</code> state.
  ##   HealthCheck.Interval: JString
  ##                       : Information about a health check.
  ## The approximate interval, in seconds, between health checks of an individual instance.
  ##   HealthCheck.Timeout: JString
  ##                      : Information about a health check.
  ## <p>The amount of time, in seconds, during which no response means a failed health check.</p> <p>This value must be less than the <code>Interval</code> value.</p>
  ##   HealthCheck.UnhealthyThreshold: JString
  ##                                 : Information about a health check.
  ## The number of consecutive health check failures required before moving the instance to the <code>Unhealthy</code> state.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   HealthCheck.Target: JString
  ##                     : Information about a health check.
  ## <p>The instance being checked. The protocol is either TCP, HTTP, HTTPS, or SSL. The range of valid ports is one (1) through 65535.</p> <p>TCP is the default, specified as a TCP: port pair, for example "TCP:5000". In this case, a health check simply attempts to open a TCP connection to the instance on the specified port. Failure to connect within the configured timeout is considered unhealthy.</p> <p>SSL is also specified as SSL: port pair, for example, SSL:5000.</p> <p>For HTTP/HTTPS, you must include a ping path in the string. HTTP is specified as a HTTP:port;/;PathToPing; grouping, for example "HTTP:80/weather/us/wa/seattle". In this case, a HTTP GET request is issued to the instance on the given port and path. Any answer other than "200 OK" within the timeout period is considered unhealthy.</p> <p>The total length of the HTTP ping target must be 1024 16-bit Unicode characters or less.</p>
  section = newJObject()
  var valid_21626157 = formData.getOrDefault("HealthCheck.HealthyThreshold")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_21626157
  var valid_21626158 = formData.getOrDefault("HealthCheck.Interval")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "HealthCheck.Interval", valid_21626158
  var valid_21626159 = formData.getOrDefault("HealthCheck.Timeout")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "HealthCheck.Timeout", valid_21626159
  var valid_21626160 = formData.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_21626160
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_21626161 = formData.getOrDefault("LoadBalancerName")
  valid_21626161 = validateParameter(valid_21626161, JString, required = true,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "LoadBalancerName", valid_21626161
  var valid_21626162 = formData.getOrDefault("HealthCheck.Target")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "HealthCheck.Target", valid_21626162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626163: Call_PostConfigureHealthCheck_21626145;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626163.validator(path, query, header, formData, body, _)
  let scheme = call_21626163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626163.makeUrl(scheme.get, call_21626163.host, call_21626163.base,
                               call_21626163.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626163, uri, valid, _)

proc call*(call_21626164: Call_PostConfigureHealthCheck_21626145;
          LoadBalancerName: string; HealthCheckHealthyThreshold: string = "";
          HealthCheckInterval: string = ""; HealthCheckTimeout: string = "";
          Action: string = "ConfigureHealthCheck";
          HealthCheckUnhealthyThreshold: string = "";
          HealthCheckTarget: string = ""; Version: string = "2012-06-01"): Recallable =
  ## postConfigureHealthCheck
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   HealthCheckHealthyThreshold: string
  ##                              : Information about a health check.
  ## The number of consecutive health checks successes required before moving the instance to the <code>Healthy</code> state.
  ##   HealthCheckInterval: string
  ##                      : Information about a health check.
  ## The approximate interval, in seconds, between health checks of an individual instance.
  ##   HealthCheckTimeout: string
  ##                     : Information about a health check.
  ## <p>The amount of time, in seconds, during which no response means a failed health check.</p> <p>This value must be less than the <code>Interval</code> value.</p>
  ##   Action: string (required)
  ##   HealthCheckUnhealthyThreshold: string
  ##                                : Information about a health check.
  ## The number of consecutive health check failures required before moving the instance to the <code>Unhealthy</code> state.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   HealthCheckTarget: string
  ##                    : Information about a health check.
  ## <p>The instance being checked. The protocol is either TCP, HTTP, HTTPS, or SSL. The range of valid ports is one (1) through 65535.</p> <p>TCP is the default, specified as a TCP: port pair, for example "TCP:5000". In this case, a health check simply attempts to open a TCP connection to the instance on the specified port. Failure to connect within the configured timeout is considered unhealthy.</p> <p>SSL is also specified as SSL: port pair, for example, SSL:5000.</p> <p>For HTTP/HTTPS, you must include a ping path in the string. HTTP is specified as a HTTP:port;/;PathToPing; grouping, for example "HTTP:80/weather/us/wa/seattle". In this case, a HTTP GET request is issued to the instance on the given port and path. Any answer other than "200 OK" within the timeout period is considered unhealthy.</p> <p>The total length of the HTTP ping target must be 1024 16-bit Unicode characters or less.</p>
  ##   Version: string (required)
  var query_21626165 = newJObject()
  var formData_21626166 = newJObject()
  add(formData_21626166, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(formData_21626166, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(formData_21626166, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_21626165, "Action", newJString(Action))
  add(formData_21626166, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(formData_21626166, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_21626166, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_21626165, "Version", newJString(Version))
  result = call_21626164.call(nil, query_21626165, nil, formData_21626166, nil)

var postConfigureHealthCheck* = Call_PostConfigureHealthCheck_21626145(
    name: "postConfigureHealthCheck", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_PostConfigureHealthCheck_21626146, base: "/",
    makeUrl: url_PostConfigureHealthCheck_21626147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigureHealthCheck_21626123 = ref object of OpenApiRestCall_21625435
proc url_GetConfigureHealthCheck_21626125(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConfigureHealthCheck_21626124(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   HealthCheck.HealthyThreshold: JString
  ##                               : Information about a health check.
  ## The number of consecutive health checks successes required before moving the instance to the <code>Healthy</code> state.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   HealthCheck.UnhealthyThreshold: JString
  ##                                 : Information about a health check.
  ## The number of consecutive health check failures required before moving the instance to the <code>Unhealthy</code> state.
  ##   HealthCheck.Timeout: JString
  ##                      : Information about a health check.
  ## <p>The amount of time, in seconds, during which no response means a failed health check.</p> <p>This value must be less than the <code>Interval</code> value.</p>
  ##   HealthCheck.Target: JString
  ##                     : Information about a health check.
  ## <p>The instance being checked. The protocol is either TCP, HTTP, HTTPS, or SSL. The range of valid ports is one (1) through 65535.</p> <p>TCP is the default, specified as a TCP: port pair, for example "TCP:5000". In this case, a health check simply attempts to open a TCP connection to the instance on the specified port. Failure to connect within the configured timeout is considered unhealthy.</p> <p>SSL is also specified as SSL: port pair, for example, SSL:5000.</p> <p>For HTTP/HTTPS, you must include a ping path in the string. HTTP is specified as a HTTP:port;/;PathToPing; grouping, for example "HTTP:80/weather/us/wa/seattle". In this case, a HTTP GET request is issued to the instance on the given port and path. Any answer other than "200 OK" within the timeout period is considered unhealthy.</p> <p>The total length of the HTTP ping target must be 1024 16-bit Unicode characters or less.</p>
  ##   Action: JString (required)
  ##   HealthCheck.Interval: JString
  ##                       : Information about a health check.
  ## The approximate interval, in seconds, between health checks of an individual instance.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626126 = query.getOrDefault("HealthCheck.HealthyThreshold")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_21626126
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626127 = query.getOrDefault("LoadBalancerName")
  valid_21626127 = validateParameter(valid_21626127, JString, required = true,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "LoadBalancerName", valid_21626127
  var valid_21626128 = query.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_21626128
  var valid_21626129 = query.getOrDefault("HealthCheck.Timeout")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "HealthCheck.Timeout", valid_21626129
  var valid_21626130 = query.getOrDefault("HealthCheck.Target")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "HealthCheck.Target", valid_21626130
  var valid_21626131 = query.getOrDefault("Action")
  valid_21626131 = validateParameter(valid_21626131, JString, required = true,
                                   default = newJString("ConfigureHealthCheck"))
  if valid_21626131 != nil:
    section.add "Action", valid_21626131
  var valid_21626132 = query.getOrDefault("HealthCheck.Interval")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "HealthCheck.Interval", valid_21626132
  var valid_21626133 = query.getOrDefault("Version")
  valid_21626133 = validateParameter(valid_21626133, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626133 != nil:
    section.add "Version", valid_21626133
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
  var valid_21626134 = header.getOrDefault("X-Amz-Date")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Date", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Security-Token", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Algorithm", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Signature")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Signature", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Credential")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Credential", valid_21626140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626141: Call_GetConfigureHealthCheck_21626123;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626141.validator(path, query, header, formData, body, _)
  let scheme = call_21626141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626141.makeUrl(scheme.get, call_21626141.host, call_21626141.base,
                               call_21626141.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626141, uri, valid, _)

proc call*(call_21626142: Call_GetConfigureHealthCheck_21626123;
          LoadBalancerName: string; HealthCheckHealthyThreshold: string = "";
          HealthCheckUnhealthyThreshold: string = "";
          HealthCheckTimeout: string = ""; HealthCheckTarget: string = "";
          Action: string = "ConfigureHealthCheck"; HealthCheckInterval: string = "";
          Version: string = "2012-06-01"): Recallable =
  ## getConfigureHealthCheck
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   HealthCheckHealthyThreshold: string
  ##                              : Information about a health check.
  ## The number of consecutive health checks successes required before moving the instance to the <code>Healthy</code> state.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   HealthCheckUnhealthyThreshold: string
  ##                                : Information about a health check.
  ## The number of consecutive health check failures required before moving the instance to the <code>Unhealthy</code> state.
  ##   HealthCheckTimeout: string
  ##                     : Information about a health check.
  ## <p>The amount of time, in seconds, during which no response means a failed health check.</p> <p>This value must be less than the <code>Interval</code> value.</p>
  ##   HealthCheckTarget: string
  ##                    : Information about a health check.
  ## <p>The instance being checked. The protocol is either TCP, HTTP, HTTPS, or SSL. The range of valid ports is one (1) through 65535.</p> <p>TCP is the default, specified as a TCP: port pair, for example "TCP:5000". In this case, a health check simply attempts to open a TCP connection to the instance on the specified port. Failure to connect within the configured timeout is considered unhealthy.</p> <p>SSL is also specified as SSL: port pair, for example, SSL:5000.</p> <p>For HTTP/HTTPS, you must include a ping path in the string. HTTP is specified as a HTTP:port;/;PathToPing; grouping, for example "HTTP:80/weather/us/wa/seattle". In this case, a HTTP GET request is issued to the instance on the given port and path. Any answer other than "200 OK" within the timeout period is considered unhealthy.</p> <p>The total length of the HTTP ping target must be 1024 16-bit Unicode characters or less.</p>
  ##   Action: string (required)
  ##   HealthCheckInterval: string
  ##                      : Information about a health check.
  ## The approximate interval, in seconds, between health checks of an individual instance.
  ##   Version: string (required)
  var query_21626143 = newJObject()
  add(query_21626143, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(query_21626143, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626143, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(query_21626143, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_21626143, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_21626143, "Action", newJString(Action))
  add(query_21626143, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(query_21626143, "Version", newJString(Version))
  result = call_21626142.call(nil, query_21626143, nil, nil, nil)

var getConfigureHealthCheck* = Call_GetConfigureHealthCheck_21626123(
    name: "getConfigureHealthCheck", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_GetConfigureHealthCheck_21626124, base: "/",
    makeUrl: url_GetConfigureHealthCheck_21626125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateAppCookieStickinessPolicy_21626185 = ref object of OpenApiRestCall_21625435
proc url_PostCreateAppCookieStickinessPolicy_21626187(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateAppCookieStickinessPolicy_21626186(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626188 = query.getOrDefault("Action")
  valid_21626188 = validateParameter(valid_21626188, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_21626188 != nil:
    section.add "Action", valid_21626188
  var valid_21626189 = query.getOrDefault("Version")
  valid_21626189 = validateParameter(valid_21626189, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626189 != nil:
    section.add "Version", valid_21626189
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
  var valid_21626190 = header.getOrDefault("X-Amz-Date")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Date", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Security-Token", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Algorithm", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Signature")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Signature", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Credential")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Credential", valid_21626196
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  ##   CookieName: JString (required)
  ##             : The name of the application cookie used for stickiness.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PolicyName` field"
  var valid_21626197 = formData.getOrDefault("PolicyName")
  valid_21626197 = validateParameter(valid_21626197, JString, required = true,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "PolicyName", valid_21626197
  var valid_21626198 = formData.getOrDefault("CookieName")
  valid_21626198 = validateParameter(valid_21626198, JString, required = true,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "CookieName", valid_21626198
  var valid_21626199 = formData.getOrDefault("LoadBalancerName")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "LoadBalancerName", valid_21626199
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626200: Call_PostCreateAppCookieStickinessPolicy_21626185;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626200.validator(path, query, header, formData, body, _)
  let scheme = call_21626200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626200.makeUrl(scheme.get, call_21626200.host, call_21626200.base,
                               call_21626200.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626200, uri, valid, _)

proc call*(call_21626201: Call_PostCreateAppCookieStickinessPolicy_21626185;
          PolicyName: string; CookieName: string; LoadBalancerName: string;
          Action: string = "CreateAppCookieStickinessPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## postCreateAppCookieStickinessPolicy
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   PolicyName: string (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  ##   CookieName: string (required)
  ##             : The name of the application cookie used for stickiness.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626202 = newJObject()
  var formData_21626203 = newJObject()
  add(formData_21626203, "PolicyName", newJString(PolicyName))
  add(formData_21626203, "CookieName", newJString(CookieName))
  add(query_21626202, "Action", newJString(Action))
  add(formData_21626203, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626202, "Version", newJString(Version))
  result = call_21626201.call(nil, query_21626202, nil, formData_21626203, nil)

var postCreateAppCookieStickinessPolicy* = Call_PostCreateAppCookieStickinessPolicy_21626185(
    name: "postCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_PostCreateAppCookieStickinessPolicy_21626186, base: "/",
    makeUrl: url_PostCreateAppCookieStickinessPolicy_21626187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateAppCookieStickinessPolicy_21626167 = ref object of OpenApiRestCall_21625435
proc url_GetCreateAppCookieStickinessPolicy_21626169(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateAppCookieStickinessPolicy_21626168(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   CookieName: JString (required)
  ##             : The name of the application cookie used for stickiness.
  ##   Version: JString (required)
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626170 = query.getOrDefault("LoadBalancerName")
  valid_21626170 = validateParameter(valid_21626170, JString, required = true,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "LoadBalancerName", valid_21626170
  var valid_21626171 = query.getOrDefault("Action")
  valid_21626171 = validateParameter(valid_21626171, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_21626171 != nil:
    section.add "Action", valid_21626171
  var valid_21626172 = query.getOrDefault("CookieName")
  valid_21626172 = validateParameter(valid_21626172, JString, required = true,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "CookieName", valid_21626172
  var valid_21626173 = query.getOrDefault("Version")
  valid_21626173 = validateParameter(valid_21626173, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626173 != nil:
    section.add "Version", valid_21626173
  var valid_21626174 = query.getOrDefault("PolicyName")
  valid_21626174 = validateParameter(valid_21626174, JString, required = true,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "PolicyName", valid_21626174
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
  var valid_21626175 = header.getOrDefault("X-Amz-Date")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Date", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Security-Token", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Algorithm", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Signature")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Signature", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Credential")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Credential", valid_21626181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626182: Call_GetCreateAppCookieStickinessPolicy_21626167;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626182.validator(path, query, header, formData, body, _)
  let scheme = call_21626182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626182.makeUrl(scheme.get, call_21626182.host, call_21626182.base,
                               call_21626182.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626182, uri, valid, _)

proc call*(call_21626183: Call_GetCreateAppCookieStickinessPolicy_21626167;
          LoadBalancerName: string; CookieName: string; PolicyName: string;
          Action: string = "CreateAppCookieStickinessPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## getCreateAppCookieStickinessPolicy
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   CookieName: string (required)
  ##             : The name of the application cookie used for stickiness.
  ##   Version: string (required)
  ##   PolicyName: string (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  var query_21626184 = newJObject()
  add(query_21626184, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626184, "Action", newJString(Action))
  add(query_21626184, "CookieName", newJString(CookieName))
  add(query_21626184, "Version", newJString(Version))
  add(query_21626184, "PolicyName", newJString(PolicyName))
  result = call_21626183.call(nil, query_21626184, nil, nil, nil)

var getCreateAppCookieStickinessPolicy* = Call_GetCreateAppCookieStickinessPolicy_21626167(
    name: "getCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_GetCreateAppCookieStickinessPolicy_21626168, base: "/",
    makeUrl: url_GetCreateAppCookieStickinessPolicy_21626169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLBCookieStickinessPolicy_21626222 = ref object of OpenApiRestCall_21625435
proc url_PostCreateLBCookieStickinessPolicy_21626224(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLBCookieStickinessPolicy_21626223(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626225 = query.getOrDefault("Action")
  valid_21626225 = validateParameter(valid_21626225, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_21626225 != nil:
    section.add "Action", valid_21626225
  var valid_21626226 = query.getOrDefault("Version")
  valid_21626226 = validateParameter(valid_21626226, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626226 != nil:
    section.add "Version", valid_21626226
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
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Algorithm", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Signature")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Signature", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Credential")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Credential", valid_21626233
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   CookieExpirationPeriod: JInt
  ##                         : The time period, in seconds, after which the cookie should be considered stale. If you do not specify this parameter, the default value is 0, which indicates that the sticky session should last for the duration of the browser session.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PolicyName` field"
  var valid_21626234 = formData.getOrDefault("PolicyName")
  valid_21626234 = validateParameter(valid_21626234, JString, required = true,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "PolicyName", valid_21626234
  var valid_21626235 = formData.getOrDefault("LoadBalancerName")
  valid_21626235 = validateParameter(valid_21626235, JString, required = true,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "LoadBalancerName", valid_21626235
  var valid_21626236 = formData.getOrDefault("CookieExpirationPeriod")
  valid_21626236 = validateParameter(valid_21626236, JInt, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "CookieExpirationPeriod", valid_21626236
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626237: Call_PostCreateLBCookieStickinessPolicy_21626222;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626237.validator(path, query, header, formData, body, _)
  let scheme = call_21626237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626237.makeUrl(scheme.get, call_21626237.host, call_21626237.base,
                               call_21626237.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626237, uri, valid, _)

proc call*(call_21626238: Call_PostCreateLBCookieStickinessPolicy_21626222;
          PolicyName: string; LoadBalancerName: string;
          Action: string = "CreateLBCookieStickinessPolicy";
          Version: string = "2012-06-01"; CookieExpirationPeriod: int = 0): Recallable =
  ## postCreateLBCookieStickinessPolicy
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   PolicyName: string (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  ##   CookieExpirationPeriod: int
  ##                         : The time period, in seconds, after which the cookie should be considered stale. If you do not specify this parameter, the default value is 0, which indicates that the sticky session should last for the duration of the browser session.
  var query_21626239 = newJObject()
  var formData_21626240 = newJObject()
  add(formData_21626240, "PolicyName", newJString(PolicyName))
  add(query_21626239, "Action", newJString(Action))
  add(formData_21626240, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626239, "Version", newJString(Version))
  add(formData_21626240, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  result = call_21626238.call(nil, query_21626239, nil, formData_21626240, nil)

var postCreateLBCookieStickinessPolicy* = Call_PostCreateLBCookieStickinessPolicy_21626222(
    name: "postCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_PostCreateLBCookieStickinessPolicy_21626223, base: "/",
    makeUrl: url_PostCreateLBCookieStickinessPolicy_21626224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLBCookieStickinessPolicy_21626204 = ref object of OpenApiRestCall_21625435
proc url_GetCreateLBCookieStickinessPolicy_21626206(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLBCookieStickinessPolicy_21626205(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CookieExpirationPeriod: JInt
  ##                         : The time period, in seconds, after which the cookie should be considered stale. If you do not specify this parameter, the default value is 0, which indicates that the sticky session should last for the duration of the browser session.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  section = newJObject()
  var valid_21626207 = query.getOrDefault("CookieExpirationPeriod")
  valid_21626207 = validateParameter(valid_21626207, JInt, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "CookieExpirationPeriod", valid_21626207
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626208 = query.getOrDefault("LoadBalancerName")
  valid_21626208 = validateParameter(valid_21626208, JString, required = true,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "LoadBalancerName", valid_21626208
  var valid_21626209 = query.getOrDefault("Action")
  valid_21626209 = validateParameter(valid_21626209, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_21626209 != nil:
    section.add "Action", valid_21626209
  var valid_21626210 = query.getOrDefault("Version")
  valid_21626210 = validateParameter(valid_21626210, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626210 != nil:
    section.add "Version", valid_21626210
  var valid_21626211 = query.getOrDefault("PolicyName")
  valid_21626211 = validateParameter(valid_21626211, JString, required = true,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "PolicyName", valid_21626211
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
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Algorithm", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Signature")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Signature", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Credential")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Credential", valid_21626218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626219: Call_GetCreateLBCookieStickinessPolicy_21626204;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626219.validator(path, query, header, formData, body, _)
  let scheme = call_21626219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626219.makeUrl(scheme.get, call_21626219.host, call_21626219.base,
                               call_21626219.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626219, uri, valid, _)

proc call*(call_21626220: Call_GetCreateLBCookieStickinessPolicy_21626204;
          LoadBalancerName: string; PolicyName: string;
          CookieExpirationPeriod: int = 0;
          Action: string = "CreateLBCookieStickinessPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## getCreateLBCookieStickinessPolicy
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   CookieExpirationPeriod: int
  ##                         : The time period, in seconds, after which the cookie should be considered stale. If you do not specify this parameter, the default value is 0, which indicates that the sticky session should last for the duration of the browser session.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PolicyName: string (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  var query_21626221 = newJObject()
  add(query_21626221, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(query_21626221, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626221, "Action", newJString(Action))
  add(query_21626221, "Version", newJString(Version))
  add(query_21626221, "PolicyName", newJString(PolicyName))
  result = call_21626220.call(nil, query_21626221, nil, nil, nil)

var getCreateLBCookieStickinessPolicy* = Call_GetCreateLBCookieStickinessPolicy_21626204(
    name: "getCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_GetCreateLBCookieStickinessPolicy_21626205, base: "/",
    makeUrl: url_GetCreateLBCookieStickinessPolicy_21626206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_21626263 = ref object of OpenApiRestCall_21625435
proc url_PostCreateLoadBalancer_21626265(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLoadBalancer_21626264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626266 = query.getOrDefault("Action")
  valid_21626266 = validateParameter(valid_21626266, JString, required = true,
                                   default = newJString("CreateLoadBalancer"))
  if valid_21626266 != nil:
    section.add "Action", valid_21626266
  var valid_21626267 = query.getOrDefault("Version")
  valid_21626267 = validateParameter(valid_21626267, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626267 != nil:
    section.add "Version", valid_21626267
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
  var valid_21626268 = header.getOrDefault("X-Amz-Date")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Date", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Security-Token", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Algorithm", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Signature")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Signature", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Credential")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Credential", valid_21626274
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##       : <p>A list of tags to assign to the load balancer.</p> <p>For more information about tagging your load balancer, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   AvailabilityZones: JArray
  ##                    : <p>One or more Availability Zones from the same region as the load balancer.</p> <p>You must specify at least one Availability Zone.</p> <p>You can add more Availability Zones after you create the load balancer using <a>EnableAvailabilityZonesForLoadBalancer</a>.</p>
  ##   Subnets: JArray
  ##          : The IDs of the subnets in your VPC to attach to the load balancer. Specify one subnet per Availability Zone specified in <code>AvailabilityZones</code>.
  ##   SecurityGroups: JArray
  ##                 : The IDs of the security groups to assign to the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : <p>The name of the load balancer.</p> <p>This name must be unique within your set of load balancers for the region, must have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and cannot begin or end with a hyphen.</p>
  ##   Scheme: JString
  ##         : <p>The type of a load balancer. Valid only for load balancers in a VPC.</p> <p>By default, Elastic Load Balancing creates an Internet-facing load balancer with a DNS name that resolves to public IP addresses. For more information about Internet-facing and Internal load balancers, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html#load-balancer-scheme">Load Balancer Scheme</a> in the <i>Elastic Load Balancing User Guide</i>.</p> <p>Specify <code>internal</code> to create a load balancer with a DNS name that resolves to private IP addresses.</p>
  ##   Listeners: JArray (required)
  ##            : <p>The listeners.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  section = newJObject()
  var valid_21626275 = formData.getOrDefault("Tags")
  valid_21626275 = validateParameter(valid_21626275, JArray, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "Tags", valid_21626275
  var valid_21626276 = formData.getOrDefault("AvailabilityZones")
  valid_21626276 = validateParameter(valid_21626276, JArray, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "AvailabilityZones", valid_21626276
  var valid_21626277 = formData.getOrDefault("Subnets")
  valid_21626277 = validateParameter(valid_21626277, JArray, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "Subnets", valid_21626277
  var valid_21626278 = formData.getOrDefault("SecurityGroups")
  valid_21626278 = validateParameter(valid_21626278, JArray, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "SecurityGroups", valid_21626278
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_21626279 = formData.getOrDefault("LoadBalancerName")
  valid_21626279 = validateParameter(valid_21626279, JString, required = true,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "LoadBalancerName", valid_21626279
  var valid_21626280 = formData.getOrDefault("Scheme")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "Scheme", valid_21626280
  var valid_21626281 = formData.getOrDefault("Listeners")
  valid_21626281 = validateParameter(valid_21626281, JArray, required = true,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "Listeners", valid_21626281
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626282: Call_PostCreateLoadBalancer_21626263;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626282.validator(path, query, header, formData, body, _)
  let scheme = call_21626282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626282.makeUrl(scheme.get, call_21626282.host, call_21626282.base,
                               call_21626282.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626282, uri, valid, _)

proc call*(call_21626283: Call_PostCreateLoadBalancer_21626263;
          LoadBalancerName: string; Listeners: JsonNode; Tags: JsonNode = nil;
          Action: string = "CreateLoadBalancer"; AvailabilityZones: JsonNode = nil;
          Subnets: JsonNode = nil; SecurityGroups: JsonNode = nil; Scheme: string = "";
          Version: string = "2012-06-01"): Recallable =
  ## postCreateLoadBalancer
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Tags: JArray
  ##       : <p>A list of tags to assign to the load balancer.</p> <p>For more information about tagging your load balancer, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   AvailabilityZones: JArray
  ##                    : <p>One or more Availability Zones from the same region as the load balancer.</p> <p>You must specify at least one Availability Zone.</p> <p>You can add more Availability Zones after you create the load balancer using <a>EnableAvailabilityZonesForLoadBalancer</a>.</p>
  ##   Subnets: JArray
  ##          : The IDs of the subnets in your VPC to attach to the load balancer. Specify one subnet per Availability Zone specified in <code>AvailabilityZones</code>.
  ##   SecurityGroups: JArray
  ##                 : The IDs of the security groups to assign to the load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : <p>The name of the load balancer.</p> <p>This name must be unique within your set of load balancers for the region, must have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and cannot begin or end with a hyphen.</p>
  ##   Scheme: string
  ##         : <p>The type of a load balancer. Valid only for load balancers in a VPC.</p> <p>By default, Elastic Load Balancing creates an Internet-facing load balancer with a DNS name that resolves to public IP addresses. For more information about Internet-facing and Internal load balancers, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html#load-balancer-scheme">Load Balancer Scheme</a> in the <i>Elastic Load Balancing User Guide</i>.</p> <p>Specify <code>internal</code> to create a load balancer with a DNS name that resolves to private IP addresses.</p>
  ##   Listeners: JArray (required)
  ##            : <p>The listeners.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Version: string (required)
  var query_21626284 = newJObject()
  var formData_21626285 = newJObject()
  if Tags != nil:
    formData_21626285.add "Tags", Tags
  add(query_21626284, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_21626285.add "AvailabilityZones", AvailabilityZones
  if Subnets != nil:
    formData_21626285.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_21626285.add "SecurityGroups", SecurityGroups
  add(formData_21626285, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_21626285, "Scheme", newJString(Scheme))
  if Listeners != nil:
    formData_21626285.add "Listeners", Listeners
  add(query_21626284, "Version", newJString(Version))
  result = call_21626283.call(nil, query_21626284, nil, formData_21626285, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_21626263(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_21626264, base: "/",
    makeUrl: url_PostCreateLoadBalancer_21626265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_21626241 = ref object of OpenApiRestCall_21625435
proc url_GetCreateLoadBalancer_21626243(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLoadBalancer_21626242(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : <p>The name of the load balancer.</p> <p>This name must be unique within your set of load balancers for the region, must have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and cannot begin or end with a hyphen.</p>
  ##   AvailabilityZones: JArray
  ##                    : <p>One or more Availability Zones from the same region as the load balancer.</p> <p>You must specify at least one Availability Zone.</p> <p>You can add more Availability Zones after you create the load balancer using <a>EnableAvailabilityZonesForLoadBalancer</a>.</p>
  ##   Scheme: JString
  ##         : <p>The type of a load balancer. Valid only for load balancers in a VPC.</p> <p>By default, Elastic Load Balancing creates an Internet-facing load balancer with a DNS name that resolves to public IP addresses. For more information about Internet-facing and Internal load balancers, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html#load-balancer-scheme">Load Balancer Scheme</a> in the <i>Elastic Load Balancing User Guide</i>.</p> <p>Specify <code>internal</code> to create a load balancer with a DNS name that resolves to private IP addresses.</p>
  ##   Tags: JArray
  ##       : <p>A list of tags to assign to the load balancer.</p> <p>For more information about tagging your load balancer, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: JString (required)
  ##   Subnets: JArray
  ##          : The IDs of the subnets in your VPC to attach to the load balancer. Specify one subnet per Availability Zone specified in <code>AvailabilityZones</code>.
  ##   Version: JString (required)
  ##   Listeners: JArray (required)
  ##            : <p>The listeners.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   SecurityGroups: JArray
  ##                 : The IDs of the security groups to assign to the load balancer.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626244 = query.getOrDefault("LoadBalancerName")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "LoadBalancerName", valid_21626244
  var valid_21626245 = query.getOrDefault("AvailabilityZones")
  valid_21626245 = validateParameter(valid_21626245, JArray, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "AvailabilityZones", valid_21626245
  var valid_21626246 = query.getOrDefault("Scheme")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "Scheme", valid_21626246
  var valid_21626247 = query.getOrDefault("Tags")
  valid_21626247 = validateParameter(valid_21626247, JArray, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "Tags", valid_21626247
  var valid_21626248 = query.getOrDefault("Action")
  valid_21626248 = validateParameter(valid_21626248, JString, required = true,
                                   default = newJString("CreateLoadBalancer"))
  if valid_21626248 != nil:
    section.add "Action", valid_21626248
  var valid_21626249 = query.getOrDefault("Subnets")
  valid_21626249 = validateParameter(valid_21626249, JArray, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "Subnets", valid_21626249
  var valid_21626250 = query.getOrDefault("Version")
  valid_21626250 = validateParameter(valid_21626250, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626250 != nil:
    section.add "Version", valid_21626250
  var valid_21626251 = query.getOrDefault("Listeners")
  valid_21626251 = validateParameter(valid_21626251, JArray, required = true,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "Listeners", valid_21626251
  var valid_21626252 = query.getOrDefault("SecurityGroups")
  valid_21626252 = validateParameter(valid_21626252, JArray, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "SecurityGroups", valid_21626252
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
  var valid_21626253 = header.getOrDefault("X-Amz-Date")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Date", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Security-Token", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Algorithm", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-Signature")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Signature", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Credential")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Credential", valid_21626259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626260: Call_GetCreateLoadBalancer_21626241;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626260.validator(path, query, header, formData, body, _)
  let scheme = call_21626260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626260.makeUrl(scheme.get, call_21626260.host, call_21626260.base,
                               call_21626260.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626260, uri, valid, _)

proc call*(call_21626261: Call_GetCreateLoadBalancer_21626241;
          LoadBalancerName: string; Listeners: JsonNode;
          AvailabilityZones: JsonNode = nil; Scheme: string = ""; Tags: JsonNode = nil;
          Action: string = "CreateLoadBalancer"; Subnets: JsonNode = nil;
          Version: string = "2012-06-01"; SecurityGroups: JsonNode = nil): Recallable =
  ## getCreateLoadBalancer
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : <p>The name of the load balancer.</p> <p>This name must be unique within your set of load balancers for the region, must have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and cannot begin or end with a hyphen.</p>
  ##   AvailabilityZones: JArray
  ##                    : <p>One or more Availability Zones from the same region as the load balancer.</p> <p>You must specify at least one Availability Zone.</p> <p>You can add more Availability Zones after you create the load balancer using <a>EnableAvailabilityZonesForLoadBalancer</a>.</p>
  ##   Scheme: string
  ##         : <p>The type of a load balancer. Valid only for load balancers in a VPC.</p> <p>By default, Elastic Load Balancing creates an Internet-facing load balancer with a DNS name that resolves to public IP addresses. For more information about Internet-facing and Internal load balancers, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html#load-balancer-scheme">Load Balancer Scheme</a> in the <i>Elastic Load Balancing User Guide</i>.</p> <p>Specify <code>internal</code> to create a load balancer with a DNS name that resolves to private IP addresses.</p>
  ##   Tags: JArray
  ##       : <p>A list of tags to assign to the load balancer.</p> <p>For more information about tagging your load balancer, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   Subnets: JArray
  ##          : The IDs of the subnets in your VPC to attach to the load balancer. Specify one subnet per Availability Zone specified in <code>AvailabilityZones</code>.
  ##   Version: string (required)
  ##   Listeners: JArray (required)
  ##            : <p>The listeners.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   SecurityGroups: JArray
  ##                 : The IDs of the security groups to assign to the load balancer.
  var query_21626262 = newJObject()
  add(query_21626262, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_21626262.add "AvailabilityZones", AvailabilityZones
  add(query_21626262, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_21626262.add "Tags", Tags
  add(query_21626262, "Action", newJString(Action))
  if Subnets != nil:
    query_21626262.add "Subnets", Subnets
  add(query_21626262, "Version", newJString(Version))
  if Listeners != nil:
    query_21626262.add "Listeners", Listeners
  if SecurityGroups != nil:
    query_21626262.add "SecurityGroups", SecurityGroups
  result = call_21626261.call(nil, query_21626262, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_21626241(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_21626242, base: "/",
    makeUrl: url_GetCreateLoadBalancer_21626243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerListeners_21626303 = ref object of OpenApiRestCall_21625435
proc url_PostCreateLoadBalancerListeners_21626305(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLoadBalancerListeners_21626304(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626306 = query.getOrDefault("Action")
  valid_21626306 = validateParameter(valid_21626306, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_21626306 != nil:
    section.add "Action", valid_21626306
  var valid_21626307 = query.getOrDefault("Version")
  valid_21626307 = validateParameter(valid_21626307, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626307 != nil:
    section.add "Version", valid_21626307
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
  var valid_21626308 = header.getOrDefault("X-Amz-Date")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Date", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Security-Token", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Algorithm", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-Signature")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-Signature", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Credential")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Credential", valid_21626314
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_21626315 = formData.getOrDefault("LoadBalancerName")
  valid_21626315 = validateParameter(valid_21626315, JString, required = true,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "LoadBalancerName", valid_21626315
  var valid_21626316 = formData.getOrDefault("Listeners")
  valid_21626316 = validateParameter(valid_21626316, JArray, required = true,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "Listeners", valid_21626316
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626317: Call_PostCreateLoadBalancerListeners_21626303;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626317.validator(path, query, header, formData, body, _)
  let scheme = call_21626317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626317.makeUrl(scheme.get, call_21626317.host, call_21626317.base,
                               call_21626317.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626317, uri, valid, _)

proc call*(call_21626318: Call_PostCreateLoadBalancerListeners_21626303;
          LoadBalancerName: string; Listeners: JsonNode;
          Action: string = "CreateLoadBalancerListeners";
          Version: string = "2012-06-01"): Recallable =
  ## postCreateLoadBalancerListeners
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  ##   Version: string (required)
  var query_21626319 = newJObject()
  var formData_21626320 = newJObject()
  add(query_21626319, "Action", newJString(Action))
  add(formData_21626320, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_21626320.add "Listeners", Listeners
  add(query_21626319, "Version", newJString(Version))
  result = call_21626318.call(nil, query_21626319, nil, formData_21626320, nil)

var postCreateLoadBalancerListeners* = Call_PostCreateLoadBalancerListeners_21626303(
    name: "postCreateLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_PostCreateLoadBalancerListeners_21626304, base: "/",
    makeUrl: url_PostCreateLoadBalancerListeners_21626305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerListeners_21626286 = ref object of OpenApiRestCall_21625435
proc url_GetCreateLoadBalancerListeners_21626288(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLoadBalancerListeners_21626287(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
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
  ##   Listeners: JArray (required)
  ##            : The listeners.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626289 = query.getOrDefault("LoadBalancerName")
  valid_21626289 = validateParameter(valid_21626289, JString, required = true,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "LoadBalancerName", valid_21626289
  var valid_21626290 = query.getOrDefault("Action")
  valid_21626290 = validateParameter(valid_21626290, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_21626290 != nil:
    section.add "Action", valid_21626290
  var valid_21626291 = query.getOrDefault("Version")
  valid_21626291 = validateParameter(valid_21626291, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626291 != nil:
    section.add "Version", valid_21626291
  var valid_21626292 = query.getOrDefault("Listeners")
  valid_21626292 = validateParameter(valid_21626292, JArray, required = true,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "Listeners", valid_21626292
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
  var valid_21626293 = header.getOrDefault("X-Amz-Date")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Date", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Security-Token", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Algorithm", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Signature")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Signature", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Credential")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Credential", valid_21626299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626300: Call_GetCreateLoadBalancerListeners_21626286;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626300.validator(path, query, header, formData, body, _)
  let scheme = call_21626300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626300.makeUrl(scheme.get, call_21626300.host, call_21626300.base,
                               call_21626300.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626300, uri, valid, _)

proc call*(call_21626301: Call_GetCreateLoadBalancerListeners_21626286;
          LoadBalancerName: string; Listeners: JsonNode;
          Action: string = "CreateLoadBalancerListeners";
          Version: string = "2012-06-01"): Recallable =
  ## getCreateLoadBalancerListeners
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Listeners: JArray (required)
  ##            : The listeners.
  var query_21626302 = newJObject()
  add(query_21626302, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626302, "Action", newJString(Action))
  add(query_21626302, "Version", newJString(Version))
  if Listeners != nil:
    query_21626302.add "Listeners", Listeners
  result = call_21626301.call(nil, query_21626302, nil, nil, nil)

var getCreateLoadBalancerListeners* = Call_GetCreateLoadBalancerListeners_21626286(
    name: "getCreateLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_GetCreateLoadBalancerListeners_21626287, base: "/",
    makeUrl: url_GetCreateLoadBalancerListeners_21626288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerPolicy_21626340 = ref object of OpenApiRestCall_21625435
proc url_PostCreateLoadBalancerPolicy_21626342(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLoadBalancerPolicy_21626341(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626343 = query.getOrDefault("Action")
  valid_21626343 = validateParameter(valid_21626343, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_21626343 != nil:
    section.add "Action", valid_21626343
  var valid_21626344 = query.getOrDefault("Version")
  valid_21626344 = validateParameter(valid_21626344, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626344 != nil:
    section.add "Version", valid_21626344
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
  var valid_21626345 = header.getOrDefault("X-Amz-Date")
  valid_21626345 = validateParameter(valid_21626345, JString, required = false,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "X-Amz-Date", valid_21626345
  var valid_21626346 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-Security-Token", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Algorithm", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Signature")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Signature", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Credential")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Credential", valid_21626351
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyName: JString (required)
  ##             : The name of the load balancer policy to be created. This name must be unique within the set of policies for this load balancer.
  ##   PolicyTypeName: JString (required)
  ##                 : The name of the base policy type. To get the list of policy types, use <a>DescribeLoadBalancerPolicyTypes</a>.
  ##   PolicyAttributes: JArray
  ##                   : The policy attributes.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PolicyName` field"
  var valid_21626352 = formData.getOrDefault("PolicyName")
  valid_21626352 = validateParameter(valid_21626352, JString, required = true,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "PolicyName", valid_21626352
  var valid_21626353 = formData.getOrDefault("PolicyTypeName")
  valid_21626353 = validateParameter(valid_21626353, JString, required = true,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "PolicyTypeName", valid_21626353
  var valid_21626354 = formData.getOrDefault("PolicyAttributes")
  valid_21626354 = validateParameter(valid_21626354, JArray, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "PolicyAttributes", valid_21626354
  var valid_21626355 = formData.getOrDefault("LoadBalancerName")
  valid_21626355 = validateParameter(valid_21626355, JString, required = true,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "LoadBalancerName", valid_21626355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626356: Call_PostCreateLoadBalancerPolicy_21626340;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_PostCreateLoadBalancerPolicy_21626340;
          PolicyName: string; PolicyTypeName: string; LoadBalancerName: string;
          PolicyAttributes: JsonNode = nil;
          Action: string = "CreateLoadBalancerPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## postCreateLoadBalancerPolicy
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ##   PolicyName: string (required)
  ##             : The name of the load balancer policy to be created. This name must be unique within the set of policies for this load balancer.
  ##   PolicyTypeName: string (required)
  ##                 : The name of the base policy type. To get the list of policy types, use <a>DescribeLoadBalancerPolicyTypes</a>.
  ##   PolicyAttributes: JArray
  ##                   : The policy attributes.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626358 = newJObject()
  var formData_21626359 = newJObject()
  add(formData_21626359, "PolicyName", newJString(PolicyName))
  add(formData_21626359, "PolicyTypeName", newJString(PolicyTypeName))
  if PolicyAttributes != nil:
    formData_21626359.add "PolicyAttributes", PolicyAttributes
  add(query_21626358, "Action", newJString(Action))
  add(formData_21626359, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626358, "Version", newJString(Version))
  result = call_21626357.call(nil, query_21626358, nil, formData_21626359, nil)

var postCreateLoadBalancerPolicy* = Call_PostCreateLoadBalancerPolicy_21626340(
    name: "postCreateLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_PostCreateLoadBalancerPolicy_21626341, base: "/",
    makeUrl: url_PostCreateLoadBalancerPolicy_21626342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerPolicy_21626321 = ref object of OpenApiRestCall_21625435
proc url_GetCreateLoadBalancerPolicy_21626323(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLoadBalancerPolicy_21626322(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyAttributes: JArray
  ##                   : The policy attributes.
  ##   Action: JString (required)
  ##   PolicyTypeName: JString (required)
  ##                 : The name of the base policy type. To get the list of policy types, use <a>DescribeLoadBalancerPolicyTypes</a>.
  ##   Version: JString (required)
  ##   PolicyName: JString (required)
  ##             : The name of the load balancer policy to be created. This name must be unique within the set of policies for this load balancer.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626324 = query.getOrDefault("LoadBalancerName")
  valid_21626324 = validateParameter(valid_21626324, JString, required = true,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "LoadBalancerName", valid_21626324
  var valid_21626325 = query.getOrDefault("PolicyAttributes")
  valid_21626325 = validateParameter(valid_21626325, JArray, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "PolicyAttributes", valid_21626325
  var valid_21626326 = query.getOrDefault("Action")
  valid_21626326 = validateParameter(valid_21626326, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_21626326 != nil:
    section.add "Action", valid_21626326
  var valid_21626327 = query.getOrDefault("PolicyTypeName")
  valid_21626327 = validateParameter(valid_21626327, JString, required = true,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "PolicyTypeName", valid_21626327
  var valid_21626328 = query.getOrDefault("Version")
  valid_21626328 = validateParameter(valid_21626328, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626328 != nil:
    section.add "Version", valid_21626328
  var valid_21626329 = query.getOrDefault("PolicyName")
  valid_21626329 = validateParameter(valid_21626329, JString, required = true,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "PolicyName", valid_21626329
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
  var valid_21626330 = header.getOrDefault("X-Amz-Date")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-Date", valid_21626330
  var valid_21626331 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-Security-Token", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Algorithm", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Signature")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Signature", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Credential")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Credential", valid_21626336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626337: Call_GetCreateLoadBalancerPolicy_21626321;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_21626337.validator(path, query, header, formData, body, _)
  let scheme = call_21626337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626337.makeUrl(scheme.get, call_21626337.host, call_21626337.base,
                               call_21626337.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626337, uri, valid, _)

proc call*(call_21626338: Call_GetCreateLoadBalancerPolicy_21626321;
          LoadBalancerName: string; PolicyTypeName: string; PolicyName: string;
          PolicyAttributes: JsonNode = nil;
          Action: string = "CreateLoadBalancerPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## getCreateLoadBalancerPolicy
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   PolicyAttributes: JArray
  ##                   : The policy attributes.
  ##   Action: string (required)
  ##   PolicyTypeName: string (required)
  ##                 : The name of the base policy type. To get the list of policy types, use <a>DescribeLoadBalancerPolicyTypes</a>.
  ##   Version: string (required)
  ##   PolicyName: string (required)
  ##             : The name of the load balancer policy to be created. This name must be unique within the set of policies for this load balancer.
  var query_21626339 = newJObject()
  add(query_21626339, "LoadBalancerName", newJString(LoadBalancerName))
  if PolicyAttributes != nil:
    query_21626339.add "PolicyAttributes", PolicyAttributes
  add(query_21626339, "Action", newJString(Action))
  add(query_21626339, "PolicyTypeName", newJString(PolicyTypeName))
  add(query_21626339, "Version", newJString(Version))
  add(query_21626339, "PolicyName", newJString(PolicyName))
  result = call_21626338.call(nil, query_21626339, nil, nil, nil)

var getCreateLoadBalancerPolicy* = Call_GetCreateLoadBalancerPolicy_21626321(
    name: "getCreateLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_GetCreateLoadBalancerPolicy_21626322, base: "/",
    makeUrl: url_GetCreateLoadBalancerPolicy_21626323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_21626376 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteLoadBalancer_21626378(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteLoadBalancer_21626377(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626379 = query.getOrDefault("Action")
  valid_21626379 = validateParameter(valid_21626379, JString, required = true,
                                   default = newJString("DeleteLoadBalancer"))
  if valid_21626379 != nil:
    section.add "Action", valid_21626379
  var valid_21626380 = query.getOrDefault("Version")
  valid_21626380 = validateParameter(valid_21626380, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626380 != nil:
    section.add "Version", valid_21626380
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
  var valid_21626381 = header.getOrDefault("X-Amz-Date")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Date", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Security-Token", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Algorithm", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Signature")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Signature", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Credential")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Credential", valid_21626387
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_21626388 = formData.getOrDefault("LoadBalancerName")
  valid_21626388 = validateParameter(valid_21626388, JString, required = true,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "LoadBalancerName", valid_21626388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626389: Call_PostDeleteLoadBalancer_21626376;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_21626389.validator(path, query, header, formData, body, _)
  let scheme = call_21626389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626389.makeUrl(scheme.get, call_21626389.host, call_21626389.base,
                               call_21626389.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626389, uri, valid, _)

proc call*(call_21626390: Call_PostDeleteLoadBalancer_21626376;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626391 = newJObject()
  var formData_21626392 = newJObject()
  add(query_21626391, "Action", newJString(Action))
  add(formData_21626392, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626391, "Version", newJString(Version))
  result = call_21626390.call(nil, query_21626391, nil, formData_21626392, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_21626376(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_21626377, base: "/",
    makeUrl: url_PostDeleteLoadBalancer_21626378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_21626360 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteLoadBalancer_21626362(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteLoadBalancer_21626361(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626363 = query.getOrDefault("LoadBalancerName")
  valid_21626363 = validateParameter(valid_21626363, JString, required = true,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "LoadBalancerName", valid_21626363
  var valid_21626364 = query.getOrDefault("Action")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true,
                                   default = newJString("DeleteLoadBalancer"))
  if valid_21626364 != nil:
    section.add "Action", valid_21626364
  var valid_21626365 = query.getOrDefault("Version")
  valid_21626365 = validateParameter(valid_21626365, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626365 != nil:
    section.add "Version", valid_21626365
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
  var valid_21626366 = header.getOrDefault("X-Amz-Date")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Date", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Security-Token", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Algorithm", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-Signature")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Signature", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Credential")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Credential", valid_21626372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626373: Call_GetDeleteLoadBalancer_21626360;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_21626373.validator(path, query, header, formData, body, _)
  let scheme = call_21626373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626373.makeUrl(scheme.get, call_21626373.host, call_21626373.base,
                               call_21626373.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626373, uri, valid, _)

proc call*(call_21626374: Call_GetDeleteLoadBalancer_21626360;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626375 = newJObject()
  add(query_21626375, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626375, "Action", newJString(Action))
  add(query_21626375, "Version", newJString(Version))
  result = call_21626374.call(nil, query_21626375, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_21626360(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_21626361, base: "/",
    makeUrl: url_GetDeleteLoadBalancer_21626362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerListeners_21626410 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteLoadBalancerListeners_21626412(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteLoadBalancerListeners_21626411(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626413 = query.getOrDefault("Action")
  valid_21626413 = validateParameter(valid_21626413, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_21626413 != nil:
    section.add "Action", valid_21626413
  var valid_21626414 = query.getOrDefault("Version")
  valid_21626414 = validateParameter(valid_21626414, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626414 != nil:
    section.add "Version", valid_21626414
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
  var valid_21626415 = header.getOrDefault("X-Amz-Date")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-Date", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Security-Token", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Algorithm", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Signature")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Signature", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Credential")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Credential", valid_21626421
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_21626422 = formData.getOrDefault("LoadBalancerName")
  valid_21626422 = validateParameter(valid_21626422, JString, required = true,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "LoadBalancerName", valid_21626422
  var valid_21626423 = formData.getOrDefault("LoadBalancerPorts")
  valid_21626423 = validateParameter(valid_21626423, JArray, required = true,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "LoadBalancerPorts", valid_21626423
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626424: Call_PostDeleteLoadBalancerListeners_21626410;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_21626424.validator(path, query, header, formData, body, _)
  let scheme = call_21626424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626424.makeUrl(scheme.get, call_21626424.host, call_21626424.base,
                               call_21626424.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626424, uri, valid, _)

proc call*(call_21626425: Call_PostDeleteLoadBalancerListeners_21626410;
          LoadBalancerName: string; LoadBalancerPorts: JsonNode;
          Action: string = "DeleteLoadBalancerListeners";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancerListeners
  ## Deletes the specified listeners from the specified load balancer.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  ##   Version: string (required)
  var query_21626426 = newJObject()
  var formData_21626427 = newJObject()
  add(query_21626426, "Action", newJString(Action))
  add(formData_21626427, "LoadBalancerName", newJString(LoadBalancerName))
  if LoadBalancerPorts != nil:
    formData_21626427.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_21626426, "Version", newJString(Version))
  result = call_21626425.call(nil, query_21626426, nil, formData_21626427, nil)

var postDeleteLoadBalancerListeners* = Call_PostDeleteLoadBalancerListeners_21626410(
    name: "postDeleteLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_PostDeleteLoadBalancerListeners_21626411, base: "/",
    makeUrl: url_PostDeleteLoadBalancerListeners_21626412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerListeners_21626393 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteLoadBalancerListeners_21626395(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteLoadBalancerListeners_21626394(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626396 = query.getOrDefault("LoadBalancerName")
  valid_21626396 = validateParameter(valid_21626396, JString, required = true,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "LoadBalancerName", valid_21626396
  var valid_21626397 = query.getOrDefault("Action")
  valid_21626397 = validateParameter(valid_21626397, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_21626397 != nil:
    section.add "Action", valid_21626397
  var valid_21626398 = query.getOrDefault("LoadBalancerPorts")
  valid_21626398 = validateParameter(valid_21626398, JArray, required = true,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "LoadBalancerPorts", valid_21626398
  var valid_21626399 = query.getOrDefault("Version")
  valid_21626399 = validateParameter(valid_21626399, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626399 != nil:
    section.add "Version", valid_21626399
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
  var valid_21626400 = header.getOrDefault("X-Amz-Date")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Date", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Security-Token", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Algorithm", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Signature")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-Signature", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Credential")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Credential", valid_21626406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626407: Call_GetDeleteLoadBalancerListeners_21626393;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_21626407.validator(path, query, header, formData, body, _)
  let scheme = call_21626407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626407.makeUrl(scheme.get, call_21626407.host, call_21626407.base,
                               call_21626407.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626407, uri, valid, _)

proc call*(call_21626408: Call_GetDeleteLoadBalancerListeners_21626393;
          LoadBalancerName: string; LoadBalancerPorts: JsonNode;
          Action: string = "DeleteLoadBalancerListeners";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancerListeners
  ## Deletes the specified listeners from the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  ##   Version: string (required)
  var query_21626409 = newJObject()
  add(query_21626409, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626409, "Action", newJString(Action))
  if LoadBalancerPorts != nil:
    query_21626409.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_21626409, "Version", newJString(Version))
  result = call_21626408.call(nil, query_21626409, nil, nil, nil)

var getDeleteLoadBalancerListeners* = Call_GetDeleteLoadBalancerListeners_21626393(
    name: "getDeleteLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_GetDeleteLoadBalancerListeners_21626394, base: "/",
    makeUrl: url_GetDeleteLoadBalancerListeners_21626395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerPolicy_21626445 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteLoadBalancerPolicy_21626447(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteLoadBalancerPolicy_21626446(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626448 = query.getOrDefault("Action")
  valid_21626448 = validateParameter(valid_21626448, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_21626448 != nil:
    section.add "Action", valid_21626448
  var valid_21626449 = query.getOrDefault("Version")
  valid_21626449 = validateParameter(valid_21626449, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626449 != nil:
    section.add "Version", valid_21626449
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
  var valid_21626450 = header.getOrDefault("X-Amz-Date")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Date", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Security-Token", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Algorithm", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Signature")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Signature", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Credential")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Credential", valid_21626456
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PolicyName` field"
  var valid_21626457 = formData.getOrDefault("PolicyName")
  valid_21626457 = validateParameter(valid_21626457, JString, required = true,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "PolicyName", valid_21626457
  var valid_21626458 = formData.getOrDefault("LoadBalancerName")
  valid_21626458 = validateParameter(valid_21626458, JString, required = true,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "LoadBalancerName", valid_21626458
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626459: Call_PostDeleteLoadBalancerPolicy_21626445;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_21626459.validator(path, query, header, formData, body, _)
  let scheme = call_21626459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626459.makeUrl(scheme.get, call_21626459.host, call_21626459.base,
                               call_21626459.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626459, uri, valid, _)

proc call*(call_21626460: Call_PostDeleteLoadBalancerPolicy_21626445;
          PolicyName: string; LoadBalancerName: string;
          Action: string = "DeleteLoadBalancerPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancerPolicy
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ##   PolicyName: string (required)
  ##             : The name of the policy.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626461 = newJObject()
  var formData_21626462 = newJObject()
  add(formData_21626462, "PolicyName", newJString(PolicyName))
  add(query_21626461, "Action", newJString(Action))
  add(formData_21626462, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626461, "Version", newJString(Version))
  result = call_21626460.call(nil, query_21626461, nil, formData_21626462, nil)

var postDeleteLoadBalancerPolicy* = Call_PostDeleteLoadBalancerPolicy_21626445(
    name: "postDeleteLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_PostDeleteLoadBalancerPolicy_21626446, base: "/",
    makeUrl: url_PostDeleteLoadBalancerPolicy_21626447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerPolicy_21626428 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteLoadBalancerPolicy_21626430(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteLoadBalancerPolicy_21626429(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
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
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626431 = query.getOrDefault("LoadBalancerName")
  valid_21626431 = validateParameter(valid_21626431, JString, required = true,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "LoadBalancerName", valid_21626431
  var valid_21626432 = query.getOrDefault("Action")
  valid_21626432 = validateParameter(valid_21626432, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_21626432 != nil:
    section.add "Action", valid_21626432
  var valid_21626433 = query.getOrDefault("Version")
  valid_21626433 = validateParameter(valid_21626433, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626433 != nil:
    section.add "Version", valid_21626433
  var valid_21626434 = query.getOrDefault("PolicyName")
  valid_21626434 = validateParameter(valid_21626434, JString, required = true,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "PolicyName", valid_21626434
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
  var valid_21626435 = header.getOrDefault("X-Amz-Date")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Date", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Security-Token", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Algorithm", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Signature")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Signature", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Credential")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Credential", valid_21626441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626442: Call_GetDeleteLoadBalancerPolicy_21626428;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_21626442.validator(path, query, header, formData, body, _)
  let scheme = call_21626442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626442.makeUrl(scheme.get, call_21626442.host, call_21626442.base,
                               call_21626442.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626442, uri, valid, _)

proc call*(call_21626443: Call_GetDeleteLoadBalancerPolicy_21626428;
          LoadBalancerName: string; PolicyName: string;
          Action: string = "DeleteLoadBalancerPolicy";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancerPolicy
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PolicyName: string (required)
  ##             : The name of the policy.
  var query_21626444 = newJObject()
  add(query_21626444, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626444, "Action", newJString(Action))
  add(query_21626444, "Version", newJString(Version))
  add(query_21626444, "PolicyName", newJString(PolicyName))
  result = call_21626443.call(nil, query_21626444, nil, nil, nil)

var getDeleteLoadBalancerPolicy* = Call_GetDeleteLoadBalancerPolicy_21626428(
    name: "getDeleteLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_GetDeleteLoadBalancerPolicy_21626429, base: "/",
    makeUrl: url_GetDeleteLoadBalancerPolicy_21626430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterInstancesFromLoadBalancer_21626480 = ref object of OpenApiRestCall_21625435
proc url_PostDeregisterInstancesFromLoadBalancer_21626482(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeregisterInstancesFromLoadBalancer_21626481(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626483 = query.getOrDefault("Action")
  valid_21626483 = validateParameter(valid_21626483, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_21626483 != nil:
    section.add "Action", valid_21626483
  var valid_21626484 = query.getOrDefault("Version")
  valid_21626484 = validateParameter(valid_21626484, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626484 != nil:
    section.add "Version", valid_21626484
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
  var valid_21626485 = header.getOrDefault("X-Amz-Date")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Date", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Security-Token", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Algorithm", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Signature")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Signature", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Credential")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Credential", valid_21626491
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_21626492 = formData.getOrDefault("Instances")
  valid_21626492 = validateParameter(valid_21626492, JArray, required = true,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "Instances", valid_21626492
  var valid_21626493 = formData.getOrDefault("LoadBalancerName")
  valid_21626493 = validateParameter(valid_21626493, JString, required = true,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "LoadBalancerName", valid_21626493
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626494: Call_PostDeregisterInstancesFromLoadBalancer_21626480;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626494.validator(path, query, header, formData, body, _)
  let scheme = call_21626494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626494.makeUrl(scheme.get, call_21626494.host, call_21626494.base,
                               call_21626494.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626494, uri, valid, _)

proc call*(call_21626495: Call_PostDeregisterInstancesFromLoadBalancer_21626480;
          Instances: JsonNode; LoadBalancerName: string;
          Action: string = "DeregisterInstancesFromLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeregisterInstancesFromLoadBalancer
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626496 = newJObject()
  var formData_21626497 = newJObject()
  if Instances != nil:
    formData_21626497.add "Instances", Instances
  add(query_21626496, "Action", newJString(Action))
  add(formData_21626497, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626496, "Version", newJString(Version))
  result = call_21626495.call(nil, query_21626496, nil, formData_21626497, nil)

var postDeregisterInstancesFromLoadBalancer* = Call_PostDeregisterInstancesFromLoadBalancer_21626480(
    name: "postDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_PostDeregisterInstancesFromLoadBalancer_21626481,
    base: "/", makeUrl: url_PostDeregisterInstancesFromLoadBalancer_21626482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterInstancesFromLoadBalancer_21626463 = ref object of OpenApiRestCall_21625435
proc url_GetDeregisterInstancesFromLoadBalancer_21626465(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeregisterInstancesFromLoadBalancer_21626464(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626466 = query.getOrDefault("LoadBalancerName")
  valid_21626466 = validateParameter(valid_21626466, JString, required = true,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "LoadBalancerName", valid_21626466
  var valid_21626467 = query.getOrDefault("Action")
  valid_21626467 = validateParameter(valid_21626467, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_21626467 != nil:
    section.add "Action", valid_21626467
  var valid_21626468 = query.getOrDefault("Instances")
  valid_21626468 = validateParameter(valid_21626468, JArray, required = true,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "Instances", valid_21626468
  var valid_21626469 = query.getOrDefault("Version")
  valid_21626469 = validateParameter(valid_21626469, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626469 != nil:
    section.add "Version", valid_21626469
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
  var valid_21626470 = header.getOrDefault("X-Amz-Date")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Date", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Security-Token", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Algorithm", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Signature")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Signature", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Credential")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Credential", valid_21626476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626477: Call_GetDeregisterInstancesFromLoadBalancer_21626463;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626477.validator(path, query, header, formData, body, _)
  let scheme = call_21626477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626477.makeUrl(scheme.get, call_21626477.host, call_21626477.base,
                               call_21626477.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626477, uri, valid, _)

proc call*(call_21626478: Call_GetDeregisterInstancesFromLoadBalancer_21626463;
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
  var query_21626479 = newJObject()
  add(query_21626479, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626479, "Action", newJString(Action))
  if Instances != nil:
    query_21626479.add "Instances", Instances
  add(query_21626479, "Version", newJString(Version))
  result = call_21626478.call(nil, query_21626479, nil, nil, nil)

var getDeregisterInstancesFromLoadBalancer* = Call_GetDeregisterInstancesFromLoadBalancer_21626463(
    name: "getDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_GetDeregisterInstancesFromLoadBalancer_21626464,
    base: "/", makeUrl: url_GetDeregisterInstancesFromLoadBalancer_21626465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_21626515 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeAccountLimits_21626517(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAccountLimits_21626516(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626518 = query.getOrDefault("Action")
  valid_21626518 = validateParameter(valid_21626518, JString, required = true, default = newJString(
      "DescribeAccountLimits"))
  if valid_21626518 != nil:
    section.add "Action", valid_21626518
  var valid_21626519 = query.getOrDefault("Version")
  valid_21626519 = validateParameter(valid_21626519, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626519 != nil:
    section.add "Version", valid_21626519
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
  var valid_21626520 = header.getOrDefault("X-Amz-Date")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amz-Date", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-Security-Token", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626522
  var valid_21626523 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626523 = validateParameter(valid_21626523, JString, required = false,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "X-Amz-Algorithm", valid_21626523
  var valid_21626524 = header.getOrDefault("X-Amz-Signature")
  valid_21626524 = validateParameter(valid_21626524, JString, required = false,
                                   default = nil)
  if valid_21626524 != nil:
    section.add "X-Amz-Signature", valid_21626524
  var valid_21626525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626525
  var valid_21626526 = header.getOrDefault("X-Amz-Credential")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-Credential", valid_21626526
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_21626527 = formData.getOrDefault("Marker")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "Marker", valid_21626527
  var valid_21626528 = formData.getOrDefault("PageSize")
  valid_21626528 = validateParameter(valid_21626528, JInt, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "PageSize", valid_21626528
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626529: Call_PostDescribeAccountLimits_21626515;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626529.validator(path, query, header, formData, body, _)
  let scheme = call_21626529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626529.makeUrl(scheme.get, call_21626529.host, call_21626529.base,
                               call_21626529.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626529, uri, valid, _)

proc call*(call_21626530: Call_PostDescribeAccountLimits_21626515;
          Marker: string = ""; Action: string = "DescribeAccountLimits";
          PageSize: int = 0; Version: string = "2012-06-01"): Recallable =
  ## postDescribeAccountLimits
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Version: string (required)
  var query_21626531 = newJObject()
  var formData_21626532 = newJObject()
  add(formData_21626532, "Marker", newJString(Marker))
  add(query_21626531, "Action", newJString(Action))
  add(formData_21626532, "PageSize", newJInt(PageSize))
  add(query_21626531, "Version", newJString(Version))
  result = call_21626530.call(nil, query_21626531, nil, formData_21626532, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_21626515(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_21626516, base: "/",
    makeUrl: url_PostDescribeAccountLimits_21626517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_21626498 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeAccountLimits_21626500(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAccountLimits_21626499(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626501 = query.getOrDefault("PageSize")
  valid_21626501 = validateParameter(valid_21626501, JInt, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "PageSize", valid_21626501
  var valid_21626502 = query.getOrDefault("Action")
  valid_21626502 = validateParameter(valid_21626502, JString, required = true, default = newJString(
      "DescribeAccountLimits"))
  if valid_21626502 != nil:
    section.add "Action", valid_21626502
  var valid_21626503 = query.getOrDefault("Marker")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "Marker", valid_21626503
  var valid_21626504 = query.getOrDefault("Version")
  valid_21626504 = validateParameter(valid_21626504, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626504 != nil:
    section.add "Version", valid_21626504
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
  var valid_21626505 = header.getOrDefault("X-Amz-Date")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Date", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Security-Token", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Algorithm", valid_21626508
  var valid_21626509 = header.getOrDefault("X-Amz-Signature")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "X-Amz-Signature", valid_21626509
  var valid_21626510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-Credential")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Credential", valid_21626511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626512: Call_GetDescribeAccountLimits_21626498;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626512.validator(path, query, header, formData, body, _)
  let scheme = call_21626512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626512.makeUrl(scheme.get, call_21626512.host, call_21626512.base,
                               call_21626512.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626512, uri, valid, _)

proc call*(call_21626513: Call_GetDescribeAccountLimits_21626498;
          PageSize: int = 0; Action: string = "DescribeAccountLimits";
          Marker: string = ""; Version: string = "2012-06-01"): Recallable =
  ## getDescribeAccountLimits
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: string (required)
  var query_21626514 = newJObject()
  add(query_21626514, "PageSize", newJInt(PageSize))
  add(query_21626514, "Action", newJString(Action))
  add(query_21626514, "Marker", newJString(Marker))
  add(query_21626514, "Version", newJString(Version))
  result = call_21626513.call(nil, query_21626514, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_21626498(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_21626499, base: "/",
    makeUrl: url_GetDescribeAccountLimits_21626500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstanceHealth_21626550 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeInstanceHealth_21626552(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeInstanceHealth_21626551(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626553 = query.getOrDefault("Action")
  valid_21626553 = validateParameter(valid_21626553, JString, required = true, default = newJString(
      "DescribeInstanceHealth"))
  if valid_21626553 != nil:
    section.add "Action", valid_21626553
  var valid_21626554 = query.getOrDefault("Version")
  valid_21626554 = validateParameter(valid_21626554, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626554 != nil:
    section.add "Version", valid_21626554
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
  var valid_21626555 = header.getOrDefault("X-Amz-Date")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "X-Amz-Date", valid_21626555
  var valid_21626556 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-Security-Token", valid_21626556
  var valid_21626557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Algorithm", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Signature")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-Signature", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Credential")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Credential", valid_21626561
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_21626562 = formData.getOrDefault("Instances")
  valid_21626562 = validateParameter(valid_21626562, JArray, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "Instances", valid_21626562
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_21626563 = formData.getOrDefault("LoadBalancerName")
  valid_21626563 = validateParameter(valid_21626563, JString, required = true,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "LoadBalancerName", valid_21626563
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626564: Call_PostDescribeInstanceHealth_21626550;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_21626564.validator(path, query, header, formData, body, _)
  let scheme = call_21626564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626564.makeUrl(scheme.get, call_21626564.host, call_21626564.base,
                               call_21626564.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626564, uri, valid, _)

proc call*(call_21626565: Call_PostDescribeInstanceHealth_21626550;
          LoadBalancerName: string; Instances: JsonNode = nil;
          Action: string = "DescribeInstanceHealth"; Version: string = "2012-06-01"): Recallable =
  ## postDescribeInstanceHealth
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626566 = newJObject()
  var formData_21626567 = newJObject()
  if Instances != nil:
    formData_21626567.add "Instances", Instances
  add(query_21626566, "Action", newJString(Action))
  add(formData_21626567, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626566, "Version", newJString(Version))
  result = call_21626565.call(nil, query_21626566, nil, formData_21626567, nil)

var postDescribeInstanceHealth* = Call_PostDescribeInstanceHealth_21626550(
    name: "postDescribeInstanceHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_PostDescribeInstanceHealth_21626551, base: "/",
    makeUrl: url_PostDescribeInstanceHealth_21626552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstanceHealth_21626533 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeInstanceHealth_21626535(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeInstanceHealth_21626534(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626536 = query.getOrDefault("LoadBalancerName")
  valid_21626536 = validateParameter(valid_21626536, JString, required = true,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "LoadBalancerName", valid_21626536
  var valid_21626537 = query.getOrDefault("Action")
  valid_21626537 = validateParameter(valid_21626537, JString, required = true, default = newJString(
      "DescribeInstanceHealth"))
  if valid_21626537 != nil:
    section.add "Action", valid_21626537
  var valid_21626538 = query.getOrDefault("Instances")
  valid_21626538 = validateParameter(valid_21626538, JArray, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "Instances", valid_21626538
  var valid_21626539 = query.getOrDefault("Version")
  valid_21626539 = validateParameter(valid_21626539, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626539 != nil:
    section.add "Version", valid_21626539
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
  var valid_21626540 = header.getOrDefault("X-Amz-Date")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "X-Amz-Date", valid_21626540
  var valid_21626541 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626541 = validateParameter(valid_21626541, JString, required = false,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "X-Amz-Security-Token", valid_21626541
  var valid_21626542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Algorithm", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Signature")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Signature", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Credential")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Credential", valid_21626546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626547: Call_GetDescribeInstanceHealth_21626533;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_21626547.validator(path, query, header, formData, body, _)
  let scheme = call_21626547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626547.makeUrl(scheme.get, call_21626547.host, call_21626547.base,
                               call_21626547.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626547, uri, valid, _)

proc call*(call_21626548: Call_GetDescribeInstanceHealth_21626533;
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
  var query_21626549 = newJObject()
  add(query_21626549, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626549, "Action", newJString(Action))
  if Instances != nil:
    query_21626549.add "Instances", Instances
  add(query_21626549, "Version", newJString(Version))
  result = call_21626548.call(nil, query_21626549, nil, nil, nil)

var getDescribeInstanceHealth* = Call_GetDescribeInstanceHealth_21626533(
    name: "getDescribeInstanceHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_GetDescribeInstanceHealth_21626534, base: "/",
    makeUrl: url_GetDescribeInstanceHealth_21626535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_21626584 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeLoadBalancerAttributes_21626586(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancerAttributes_21626585(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626587 = query.getOrDefault("Action")
  valid_21626587 = validateParameter(valid_21626587, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_21626587 != nil:
    section.add "Action", valid_21626587
  var valid_21626588 = query.getOrDefault("Version")
  valid_21626588 = validateParameter(valid_21626588, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626588 != nil:
    section.add "Version", valid_21626588
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
  var valid_21626589 = header.getOrDefault("X-Amz-Date")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "X-Amz-Date", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Security-Token", valid_21626590
  var valid_21626591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626591
  var valid_21626592 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Algorithm", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-Signature")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-Signature", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-Credential")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-Credential", valid_21626595
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_21626596 = formData.getOrDefault("LoadBalancerName")
  valid_21626596 = validateParameter(valid_21626596, JString, required = true,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "LoadBalancerName", valid_21626596
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626597: Call_PostDescribeLoadBalancerAttributes_21626584;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_21626597.validator(path, query, header, formData, body, _)
  let scheme = call_21626597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626597.makeUrl(scheme.get, call_21626597.host, call_21626597.base,
                               call_21626597.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626597, uri, valid, _)

proc call*(call_21626598: Call_PostDescribeLoadBalancerAttributes_21626584;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626599 = newJObject()
  var formData_21626600 = newJObject()
  add(query_21626599, "Action", newJString(Action))
  add(formData_21626600, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626599, "Version", newJString(Version))
  result = call_21626598.call(nil, query_21626599, nil, formData_21626600, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_21626584(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_21626585, base: "/",
    makeUrl: url_PostDescribeLoadBalancerAttributes_21626586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_21626568 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeLoadBalancerAttributes_21626570(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancerAttributes_21626569(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626571 = query.getOrDefault("LoadBalancerName")
  valid_21626571 = validateParameter(valid_21626571, JString, required = true,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "LoadBalancerName", valid_21626571
  var valid_21626572 = query.getOrDefault("Action")
  valid_21626572 = validateParameter(valid_21626572, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_21626572 != nil:
    section.add "Action", valid_21626572
  var valid_21626573 = query.getOrDefault("Version")
  valid_21626573 = validateParameter(valid_21626573, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626573 != nil:
    section.add "Version", valid_21626573
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
  var valid_21626574 = header.getOrDefault("X-Amz-Date")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "X-Amz-Date", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Security-Token", valid_21626575
  var valid_21626576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Algorithm", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-Signature")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Signature", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Credential")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Credential", valid_21626580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626581: Call_GetDescribeLoadBalancerAttributes_21626568;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_21626581.validator(path, query, header, formData, body, _)
  let scheme = call_21626581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626581.makeUrl(scheme.get, call_21626581.host, call_21626581.base,
                               call_21626581.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626581, uri, valid, _)

proc call*(call_21626582: Call_GetDescribeLoadBalancerAttributes_21626568;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626583 = newJObject()
  add(query_21626583, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626583, "Action", newJString(Action))
  add(query_21626583, "Version", newJString(Version))
  result = call_21626582.call(nil, query_21626583, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_21626568(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_21626569, base: "/",
    makeUrl: url_GetDescribeLoadBalancerAttributes_21626570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicies_21626618 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeLoadBalancerPolicies_21626620(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancerPolicies_21626619(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626621 = query.getOrDefault("Action")
  valid_21626621 = validateParameter(valid_21626621, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_21626621 != nil:
    section.add "Action", valid_21626621
  var valid_21626622 = query.getOrDefault("Version")
  valid_21626622 = validateParameter(valid_21626622, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626622 != nil:
    section.add "Version", valid_21626622
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
  var valid_21626623 = header.getOrDefault("X-Amz-Date")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "X-Amz-Date", valid_21626623
  var valid_21626624 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-Security-Token", valid_21626624
  var valid_21626625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626625 = validateParameter(valid_21626625, JString, required = false,
                                   default = nil)
  if valid_21626625 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626625
  var valid_21626626 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626626 = validateParameter(valid_21626626, JString, required = false,
                                   default = nil)
  if valid_21626626 != nil:
    section.add "X-Amz-Algorithm", valid_21626626
  var valid_21626627 = header.getOrDefault("X-Amz-Signature")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Signature", valid_21626627
  var valid_21626628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-Credential")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-Credential", valid_21626629
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   LoadBalancerName: JString
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_21626630 = formData.getOrDefault("PolicyNames")
  valid_21626630 = validateParameter(valid_21626630, JArray, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "PolicyNames", valid_21626630
  var valid_21626631 = formData.getOrDefault("LoadBalancerName")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "LoadBalancerName", valid_21626631
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626632: Call_PostDescribeLoadBalancerPolicies_21626618;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_21626632.validator(path, query, header, formData, body, _)
  let scheme = call_21626632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626632.makeUrl(scheme.get, call_21626632.host, call_21626632.base,
                               call_21626632.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626632, uri, valid, _)

proc call*(call_21626633: Call_PostDescribeLoadBalancerPolicies_21626618;
          PolicyNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicies";
          LoadBalancerName: string = ""; Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicies
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   Action: string (required)
  ##   LoadBalancerName: string
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626634 = newJObject()
  var formData_21626635 = newJObject()
  if PolicyNames != nil:
    formData_21626635.add "PolicyNames", PolicyNames
  add(query_21626634, "Action", newJString(Action))
  add(formData_21626635, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626634, "Version", newJString(Version))
  result = call_21626633.call(nil, query_21626634, nil, formData_21626635, nil)

var postDescribeLoadBalancerPolicies* = Call_PostDescribeLoadBalancerPolicies_21626618(
    name: "postDescribeLoadBalancerPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_PostDescribeLoadBalancerPolicies_21626619, base: "/",
    makeUrl: url_PostDescribeLoadBalancerPolicies_21626620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicies_21626601 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeLoadBalancerPolicies_21626603(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancerPolicies_21626602(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626604 = query.getOrDefault("LoadBalancerName")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "LoadBalancerName", valid_21626604
  var valid_21626605 = query.getOrDefault("Action")
  valid_21626605 = validateParameter(valid_21626605, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_21626605 != nil:
    section.add "Action", valid_21626605
  var valid_21626606 = query.getOrDefault("PolicyNames")
  valid_21626606 = validateParameter(valid_21626606, JArray, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "PolicyNames", valid_21626606
  var valid_21626607 = query.getOrDefault("Version")
  valid_21626607 = validateParameter(valid_21626607, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626607 != nil:
    section.add "Version", valid_21626607
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
  var valid_21626608 = header.getOrDefault("X-Amz-Date")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-Date", valid_21626608
  var valid_21626609 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-Security-Token", valid_21626609
  var valid_21626610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626610 = validateParameter(valid_21626610, JString, required = false,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626610
  var valid_21626611 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626611 = validateParameter(valid_21626611, JString, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "X-Amz-Algorithm", valid_21626611
  var valid_21626612 = header.getOrDefault("X-Amz-Signature")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-Signature", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Credential")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Credential", valid_21626614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626615: Call_GetDescribeLoadBalancerPolicies_21626601;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_21626615.validator(path, query, header, formData, body, _)
  let scheme = call_21626615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626615.makeUrl(scheme.get, call_21626615.host, call_21626615.base,
                               call_21626615.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626615, uri, valid, _)

proc call*(call_21626616: Call_GetDescribeLoadBalancerPolicies_21626601;
          LoadBalancerName: string = "";
          Action: string = "DescribeLoadBalancerPolicies";
          PolicyNames: JsonNode = nil; Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerPolicies
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ##   LoadBalancerName: string
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   Version: string (required)
  var query_21626617 = newJObject()
  add(query_21626617, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626617, "Action", newJString(Action))
  if PolicyNames != nil:
    query_21626617.add "PolicyNames", PolicyNames
  add(query_21626617, "Version", newJString(Version))
  result = call_21626616.call(nil, query_21626617, nil, nil, nil)

var getDescribeLoadBalancerPolicies* = Call_GetDescribeLoadBalancerPolicies_21626601(
    name: "getDescribeLoadBalancerPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_GetDescribeLoadBalancerPolicies_21626602, base: "/",
    makeUrl: url_GetDescribeLoadBalancerPolicies_21626603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicyTypes_21626652 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeLoadBalancerPolicyTypes_21626654(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancerPolicyTypes_21626653(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626655 = query.getOrDefault("Action")
  valid_21626655 = validateParameter(valid_21626655, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_21626655 != nil:
    section.add "Action", valid_21626655
  var valid_21626656 = query.getOrDefault("Version")
  valid_21626656 = validateParameter(valid_21626656, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626656 != nil:
    section.add "Version", valid_21626656
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
  var valid_21626657 = header.getOrDefault("X-Amz-Date")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "X-Amz-Date", valid_21626657
  var valid_21626658 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626658 = validateParameter(valid_21626658, JString, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "X-Amz-Security-Token", valid_21626658
  var valid_21626659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626659 = validateParameter(valid_21626659, JString, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Algorithm", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Signature")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Signature", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Credential")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Credential", valid_21626663
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  section = newJObject()
  var valid_21626664 = formData.getOrDefault("PolicyTypeNames")
  valid_21626664 = validateParameter(valid_21626664, JArray, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "PolicyTypeNames", valid_21626664
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626665: Call_PostDescribeLoadBalancerPolicyTypes_21626652;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_21626665.validator(path, query, header, formData, body, _)
  let scheme = call_21626665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626665.makeUrl(scheme.get, call_21626665.host, call_21626665.base,
                               call_21626665.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626665, uri, valid, _)

proc call*(call_21626666: Call_PostDescribeLoadBalancerPolicyTypes_21626652;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626667 = newJObject()
  var formData_21626668 = newJObject()
  if PolicyTypeNames != nil:
    formData_21626668.add "PolicyTypeNames", PolicyTypeNames
  add(query_21626667, "Action", newJString(Action))
  add(query_21626667, "Version", newJString(Version))
  result = call_21626666.call(nil, query_21626667, nil, formData_21626668, nil)

var postDescribeLoadBalancerPolicyTypes* = Call_PostDescribeLoadBalancerPolicyTypes_21626652(
    name: "postDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_PostDescribeLoadBalancerPolicyTypes_21626653, base: "/",
    makeUrl: url_PostDescribeLoadBalancerPolicyTypes_21626654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicyTypes_21626636 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeLoadBalancerPolicyTypes_21626638(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancerPolicyTypes_21626637(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626639 = query.getOrDefault("Action")
  valid_21626639 = validateParameter(valid_21626639, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_21626639 != nil:
    section.add "Action", valid_21626639
  var valid_21626640 = query.getOrDefault("PolicyTypeNames")
  valid_21626640 = validateParameter(valid_21626640, JArray, required = false,
                                   default = nil)
  if valid_21626640 != nil:
    section.add "PolicyTypeNames", valid_21626640
  var valid_21626641 = query.getOrDefault("Version")
  valid_21626641 = validateParameter(valid_21626641, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626641 != nil:
    section.add "Version", valid_21626641
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
  var valid_21626642 = header.getOrDefault("X-Amz-Date")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "X-Amz-Date", valid_21626642
  var valid_21626643 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Security-Token", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Algorithm", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Signature")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Signature", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Credential")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Credential", valid_21626648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626649: Call_GetDescribeLoadBalancerPolicyTypes_21626636;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_21626649.validator(path, query, header, formData, body, _)
  let scheme = call_21626649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626649.makeUrl(scheme.get, call_21626649.host, call_21626649.base,
                               call_21626649.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626649, uri, valid, _)

proc call*(call_21626650: Call_GetDescribeLoadBalancerPolicyTypes_21626636;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          PolicyTypeNames: JsonNode = nil; Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   Action: string (required)
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Version: string (required)
  var query_21626651 = newJObject()
  add(query_21626651, "Action", newJString(Action))
  if PolicyTypeNames != nil:
    query_21626651.add "PolicyTypeNames", PolicyTypeNames
  add(query_21626651, "Version", newJString(Version))
  result = call_21626650.call(nil, query_21626651, nil, nil, nil)

var getDescribeLoadBalancerPolicyTypes* = Call_GetDescribeLoadBalancerPolicyTypes_21626636(
    name: "getDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_GetDescribeLoadBalancerPolicyTypes_21626637, base: "/",
    makeUrl: url_GetDescribeLoadBalancerPolicyTypes_21626638,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_21626687 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeLoadBalancers_21626689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancers_21626688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626690 = query.getOrDefault("Action")
  valid_21626690 = validateParameter(valid_21626690, JString, required = true, default = newJString(
      "DescribeLoadBalancers"))
  if valid_21626690 != nil:
    section.add "Action", valid_21626690
  var valid_21626691 = query.getOrDefault("Version")
  valid_21626691 = validateParameter(valid_21626691, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626691 != nil:
    section.add "Version", valid_21626691
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
  var valid_21626692 = header.getOrDefault("X-Amz-Date")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Date", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Security-Token", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-Algorithm", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Signature")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Signature", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-Credential")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-Credential", valid_21626698
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  section = newJObject()
  var valid_21626699 = formData.getOrDefault("Marker")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "Marker", valid_21626699
  var valid_21626700 = formData.getOrDefault("LoadBalancerNames")
  valid_21626700 = validateParameter(valid_21626700, JArray, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "LoadBalancerNames", valid_21626700
  var valid_21626701 = formData.getOrDefault("PageSize")
  valid_21626701 = validateParameter(valid_21626701, JInt, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "PageSize", valid_21626701
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626702: Call_PostDescribeLoadBalancers_21626687;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_21626702.validator(path, query, header, formData, body, _)
  let scheme = call_21626702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626702.makeUrl(scheme.get, call_21626702.host, call_21626702.base,
                               call_21626702.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626702, uri, valid, _)

proc call*(call_21626703: Call_PostDescribeLoadBalancers_21626687;
          Marker: string = ""; Action: string = "DescribeLoadBalancers";
          LoadBalancerNames: JsonNode = nil; PageSize: int = 0;
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancers
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  ##   Version: string (required)
  var query_21626704 = newJObject()
  var formData_21626705 = newJObject()
  add(formData_21626705, "Marker", newJString(Marker))
  add(query_21626704, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_21626705.add "LoadBalancerNames", LoadBalancerNames
  add(formData_21626705, "PageSize", newJInt(PageSize))
  add(query_21626704, "Version", newJString(Version))
  result = call_21626703.call(nil, query_21626704, nil, formData_21626705, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_21626687(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_21626688, base: "/",
    makeUrl: url_PostDescribeLoadBalancers_21626689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_21626669 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeLoadBalancers_21626671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancers_21626670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626672 = query.getOrDefault("PageSize")
  valid_21626672 = validateParameter(valid_21626672, JInt, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "PageSize", valid_21626672
  var valid_21626673 = query.getOrDefault("Action")
  valid_21626673 = validateParameter(valid_21626673, JString, required = true, default = newJString(
      "DescribeLoadBalancers"))
  if valid_21626673 != nil:
    section.add "Action", valid_21626673
  var valid_21626674 = query.getOrDefault("Marker")
  valid_21626674 = validateParameter(valid_21626674, JString, required = false,
                                   default = nil)
  if valid_21626674 != nil:
    section.add "Marker", valid_21626674
  var valid_21626675 = query.getOrDefault("LoadBalancerNames")
  valid_21626675 = validateParameter(valid_21626675, JArray, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "LoadBalancerNames", valid_21626675
  var valid_21626676 = query.getOrDefault("Version")
  valid_21626676 = validateParameter(valid_21626676, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626676 != nil:
    section.add "Version", valid_21626676
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
  var valid_21626677 = header.getOrDefault("X-Amz-Date")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Date", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Security-Token", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Algorithm", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Signature")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Signature", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-Credential")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Credential", valid_21626683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626684: Call_GetDescribeLoadBalancers_21626669;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_21626684.validator(path, query, header, formData, body, _)
  let scheme = call_21626684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626684.makeUrl(scheme.get, call_21626684.host, call_21626684.base,
                               call_21626684.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626684, uri, valid, _)

proc call*(call_21626685: Call_GetDescribeLoadBalancers_21626669;
          PageSize: int = 0; Action: string = "DescribeLoadBalancers";
          Marker: string = ""; LoadBalancerNames: JsonNode = nil;
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancers
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ##   PageSize: int
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_21626686 = newJObject()
  add(query_21626686, "PageSize", newJInt(PageSize))
  add(query_21626686, "Action", newJString(Action))
  add(query_21626686, "Marker", newJString(Marker))
  if LoadBalancerNames != nil:
    query_21626686.add "LoadBalancerNames", LoadBalancerNames
  add(query_21626686, "Version", newJString(Version))
  result = call_21626685.call(nil, query_21626686, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_21626669(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_21626670, base: "/",
    makeUrl: url_GetDescribeLoadBalancers_21626671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_21626722 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeTags_21626724(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTags_21626723(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626725 = query.getOrDefault("Action")
  valid_21626725 = validateParameter(valid_21626725, JString, required = true,
                                   default = newJString("DescribeTags"))
  if valid_21626725 != nil:
    section.add "Action", valid_21626725
  var valid_21626726 = query.getOrDefault("Version")
  valid_21626726 = validateParameter(valid_21626726, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626726 != nil:
    section.add "Version", valid_21626726
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
  var valid_21626727 = header.getOrDefault("X-Amz-Date")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Date", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-Security-Token", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626729
  var valid_21626730 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "X-Amz-Algorithm", valid_21626730
  var valid_21626731 = header.getOrDefault("X-Amz-Signature")
  valid_21626731 = validateParameter(valid_21626731, JString, required = false,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "X-Amz-Signature", valid_21626731
  var valid_21626732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-Credential")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-Credential", valid_21626733
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_21626734 = formData.getOrDefault("LoadBalancerNames")
  valid_21626734 = validateParameter(valid_21626734, JArray, required = true,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "LoadBalancerNames", valid_21626734
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626735: Call_PostDescribeTags_21626722; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_21626735.validator(path, query, header, formData, body, _)
  let scheme = call_21626735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626735.makeUrl(scheme.get, call_21626735.host, call_21626735.base,
                               call_21626735.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626735, uri, valid, _)

proc call*(call_21626736: Call_PostDescribeTags_21626722;
          LoadBalancerNames: JsonNode; Action: string = "DescribeTags";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_21626737 = newJObject()
  var formData_21626738 = newJObject()
  add(query_21626737, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_21626738.add "LoadBalancerNames", LoadBalancerNames
  add(query_21626737, "Version", newJString(Version))
  result = call_21626736.call(nil, query_21626737, nil, formData_21626738, nil)

var postDescribeTags* = Call_PostDescribeTags_21626722(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_21626723,
    base: "/", makeUrl: url_PostDescribeTags_21626724,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_21626706 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeTags_21626708(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTags_21626707(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the tags associated with the specified load balancers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626709 = query.getOrDefault("Action")
  valid_21626709 = validateParameter(valid_21626709, JString, required = true,
                                   default = newJString("DescribeTags"))
  if valid_21626709 != nil:
    section.add "Action", valid_21626709
  var valid_21626710 = query.getOrDefault("LoadBalancerNames")
  valid_21626710 = validateParameter(valid_21626710, JArray, required = true,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "LoadBalancerNames", valid_21626710
  var valid_21626711 = query.getOrDefault("Version")
  valid_21626711 = validateParameter(valid_21626711, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626711 != nil:
    section.add "Version", valid_21626711
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
  var valid_21626712 = header.getOrDefault("X-Amz-Date")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Date", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-Security-Token", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626714
  var valid_21626715 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626715 = validateParameter(valid_21626715, JString, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "X-Amz-Algorithm", valid_21626715
  var valid_21626716 = header.getOrDefault("X-Amz-Signature")
  valid_21626716 = validateParameter(valid_21626716, JString, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "X-Amz-Signature", valid_21626716
  var valid_21626717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626717 = validateParameter(valid_21626717, JString, required = false,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626717
  var valid_21626718 = header.getOrDefault("X-Amz-Credential")
  valid_21626718 = validateParameter(valid_21626718, JString, required = false,
                                   default = nil)
  if valid_21626718 != nil:
    section.add "X-Amz-Credential", valid_21626718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626719: Call_GetDescribeTags_21626706; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_21626719.validator(path, query, header, formData, body, _)
  let scheme = call_21626719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626719.makeUrl(scheme.get, call_21626719.host, call_21626719.base,
                               call_21626719.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626719, uri, valid, _)

proc call*(call_21626720: Call_GetDescribeTags_21626706;
          LoadBalancerNames: JsonNode; Action: string = "DescribeTags";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_21626721 = newJObject()
  add(query_21626721, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_21626721.add "LoadBalancerNames", LoadBalancerNames
  add(query_21626721, "Version", newJString(Version))
  result = call_21626720.call(nil, query_21626721, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_21626706(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_21626707,
    base: "/", makeUrl: url_GetDescribeTags_21626708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDetachLoadBalancerFromSubnets_21626756 = ref object of OpenApiRestCall_21625435
proc url_PostDetachLoadBalancerFromSubnets_21626758(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDetachLoadBalancerFromSubnets_21626757(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626759 = query.getOrDefault("Action")
  valid_21626759 = validateParameter(valid_21626759, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_21626759 != nil:
    section.add "Action", valid_21626759
  var valid_21626760 = query.getOrDefault("Version")
  valid_21626760 = validateParameter(valid_21626760, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626760 != nil:
    section.add "Version", valid_21626760
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
  var valid_21626761 = header.getOrDefault("X-Amz-Date")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-Date", valid_21626761
  var valid_21626762 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-Security-Token", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626763
  var valid_21626764 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-Algorithm", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-Signature")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Signature", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-Credential")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Credential", valid_21626767
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_21626768 = formData.getOrDefault("Subnets")
  valid_21626768 = validateParameter(valid_21626768, JArray, required = true,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "Subnets", valid_21626768
  var valid_21626769 = formData.getOrDefault("LoadBalancerName")
  valid_21626769 = validateParameter(valid_21626769, JString, required = true,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "LoadBalancerName", valid_21626769
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626770: Call_PostDetachLoadBalancerFromSubnets_21626756;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_21626770.validator(path, query, header, formData, body, _)
  let scheme = call_21626770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626770.makeUrl(scheme.get, call_21626770.host, call_21626770.base,
                               call_21626770.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626770, uri, valid, _)

proc call*(call_21626771: Call_PostDetachLoadBalancerFromSubnets_21626756;
          Subnets: JsonNode; LoadBalancerName: string;
          Action: string = "DetachLoadBalancerFromSubnets";
          Version: string = "2012-06-01"): Recallable =
  ## postDetachLoadBalancerFromSubnets
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ##   Action: string (required)
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626772 = newJObject()
  var formData_21626773 = newJObject()
  add(query_21626772, "Action", newJString(Action))
  if Subnets != nil:
    formData_21626773.add "Subnets", Subnets
  add(formData_21626773, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626772, "Version", newJString(Version))
  result = call_21626771.call(nil, query_21626772, nil, formData_21626773, nil)

var postDetachLoadBalancerFromSubnets* = Call_PostDetachLoadBalancerFromSubnets_21626756(
    name: "postDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_PostDetachLoadBalancerFromSubnets_21626757, base: "/",
    makeUrl: url_PostDetachLoadBalancerFromSubnets_21626758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetachLoadBalancerFromSubnets_21626739 = ref object of OpenApiRestCall_21625435
proc url_GetDetachLoadBalancerFromSubnets_21626741(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDetachLoadBalancerFromSubnets_21626740(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626742 = query.getOrDefault("LoadBalancerName")
  valid_21626742 = validateParameter(valid_21626742, JString, required = true,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "LoadBalancerName", valid_21626742
  var valid_21626743 = query.getOrDefault("Action")
  valid_21626743 = validateParameter(valid_21626743, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_21626743 != nil:
    section.add "Action", valid_21626743
  var valid_21626744 = query.getOrDefault("Subnets")
  valid_21626744 = validateParameter(valid_21626744, JArray, required = true,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "Subnets", valid_21626744
  var valid_21626745 = query.getOrDefault("Version")
  valid_21626745 = validateParameter(valid_21626745, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626745 != nil:
    section.add "Version", valid_21626745
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
  var valid_21626746 = header.getOrDefault("X-Amz-Date")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "X-Amz-Date", valid_21626746
  var valid_21626747 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "X-Amz-Security-Token", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-Algorithm", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-Signature")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Signature", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626751
  var valid_21626752 = header.getOrDefault("X-Amz-Credential")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Credential", valid_21626752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626753: Call_GetDetachLoadBalancerFromSubnets_21626739;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_21626753.validator(path, query, header, formData, body, _)
  let scheme = call_21626753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626753.makeUrl(scheme.get, call_21626753.host, call_21626753.base,
                               call_21626753.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626753, uri, valid, _)

proc call*(call_21626754: Call_GetDetachLoadBalancerFromSubnets_21626739;
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
  var query_21626755 = newJObject()
  add(query_21626755, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626755, "Action", newJString(Action))
  if Subnets != nil:
    query_21626755.add "Subnets", Subnets
  add(query_21626755, "Version", newJString(Version))
  result = call_21626754.call(nil, query_21626755, nil, nil, nil)

var getDetachLoadBalancerFromSubnets* = Call_GetDetachLoadBalancerFromSubnets_21626739(
    name: "getDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_GetDetachLoadBalancerFromSubnets_21626740, base: "/",
    makeUrl: url_GetDetachLoadBalancerFromSubnets_21626741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAvailabilityZonesForLoadBalancer_21626791 = ref object of OpenApiRestCall_21625435
proc url_PostDisableAvailabilityZonesForLoadBalancer_21626793(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDisableAvailabilityZonesForLoadBalancer_21626792(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626794 = query.getOrDefault("Action")
  valid_21626794 = validateParameter(valid_21626794, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_21626794 != nil:
    section.add "Action", valid_21626794
  var valid_21626795 = query.getOrDefault("Version")
  valid_21626795 = validateParameter(valid_21626795, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626795 != nil:
    section.add "Version", valid_21626795
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
  var valid_21626796 = header.getOrDefault("X-Amz-Date")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Date", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Security-Token", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-Algorithm", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Signature")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-Signature", valid_21626800
  var valid_21626801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626801
  var valid_21626802 = header.getOrDefault("X-Amz-Credential")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "X-Amz-Credential", valid_21626802
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_21626803 = formData.getOrDefault("AvailabilityZones")
  valid_21626803 = validateParameter(valid_21626803, JArray, required = true,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "AvailabilityZones", valid_21626803
  var valid_21626804 = formData.getOrDefault("LoadBalancerName")
  valid_21626804 = validateParameter(valid_21626804, JString, required = true,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "LoadBalancerName", valid_21626804
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626805: Call_PostDisableAvailabilityZonesForLoadBalancer_21626791;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626805.validator(path, query, header, formData, body, _)
  let scheme = call_21626805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626805.makeUrl(scheme.get, call_21626805.host, call_21626805.base,
                               call_21626805.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626805, uri, valid, _)

proc call*(call_21626806: Call_PostDisableAvailabilityZonesForLoadBalancer_21626791;
          AvailabilityZones: JsonNode; LoadBalancerName: string;
          Action: string = "DisableAvailabilityZonesForLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDisableAvailabilityZonesForLoadBalancer
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626807 = newJObject()
  var formData_21626808 = newJObject()
  add(query_21626807, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_21626808.add "AvailabilityZones", AvailabilityZones
  add(formData_21626808, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626807, "Version", newJString(Version))
  result = call_21626806.call(nil, query_21626807, nil, formData_21626808, nil)

var postDisableAvailabilityZonesForLoadBalancer* = Call_PostDisableAvailabilityZonesForLoadBalancer_21626791(
    name: "postDisableAvailabilityZonesForLoadBalancer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_PostDisableAvailabilityZonesForLoadBalancer_21626792,
    base: "/", makeUrl: url_PostDisableAvailabilityZonesForLoadBalancer_21626793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAvailabilityZonesForLoadBalancer_21626774 = ref object of OpenApiRestCall_21625435
proc url_GetDisableAvailabilityZonesForLoadBalancer_21626776(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDisableAvailabilityZonesForLoadBalancer_21626775(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626777 = query.getOrDefault("LoadBalancerName")
  valid_21626777 = validateParameter(valid_21626777, JString, required = true,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "LoadBalancerName", valid_21626777
  var valid_21626778 = query.getOrDefault("AvailabilityZones")
  valid_21626778 = validateParameter(valid_21626778, JArray, required = true,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "AvailabilityZones", valid_21626778
  var valid_21626779 = query.getOrDefault("Action")
  valid_21626779 = validateParameter(valid_21626779, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_21626779 != nil:
    section.add "Action", valid_21626779
  var valid_21626780 = query.getOrDefault("Version")
  valid_21626780 = validateParameter(valid_21626780, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626780 != nil:
    section.add "Version", valid_21626780
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
  var valid_21626781 = header.getOrDefault("X-Amz-Date")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-Date", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Security-Token", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-Algorithm", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-Signature")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-Signature", valid_21626785
  var valid_21626786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626786
  var valid_21626787 = header.getOrDefault("X-Amz-Credential")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-Credential", valid_21626787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626788: Call_GetDisableAvailabilityZonesForLoadBalancer_21626774;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626788.validator(path, query, header, formData, body, _)
  let scheme = call_21626788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626788.makeUrl(scheme.get, call_21626788.host, call_21626788.base,
                               call_21626788.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626788, uri, valid, _)

proc call*(call_21626789: Call_GetDisableAvailabilityZonesForLoadBalancer_21626774;
          LoadBalancerName: string; AvailabilityZones: JsonNode;
          Action: string = "DisableAvailabilityZonesForLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDisableAvailabilityZonesForLoadBalancer
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626790 = newJObject()
  add(query_21626790, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_21626790.add "AvailabilityZones", AvailabilityZones
  add(query_21626790, "Action", newJString(Action))
  add(query_21626790, "Version", newJString(Version))
  result = call_21626789.call(nil, query_21626790, nil, nil, nil)

var getDisableAvailabilityZonesForLoadBalancer* = Call_GetDisableAvailabilityZonesForLoadBalancer_21626774(
    name: "getDisableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_GetDisableAvailabilityZonesForLoadBalancer_21626775,
    base: "/", makeUrl: url_GetDisableAvailabilityZonesForLoadBalancer_21626776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAvailabilityZonesForLoadBalancer_21626826 = ref object of OpenApiRestCall_21625435
proc url_PostEnableAvailabilityZonesForLoadBalancer_21626828(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostEnableAvailabilityZonesForLoadBalancer_21626827(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626829 = query.getOrDefault("Action")
  valid_21626829 = validateParameter(valid_21626829, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_21626829 != nil:
    section.add "Action", valid_21626829
  var valid_21626830 = query.getOrDefault("Version")
  valid_21626830 = validateParameter(valid_21626830, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626830 != nil:
    section.add "Version", valid_21626830
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
  var valid_21626831 = header.getOrDefault("X-Amz-Date")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-Date", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Security-Token", valid_21626832
  var valid_21626833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626833
  var valid_21626834 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Algorithm", valid_21626834
  var valid_21626835 = header.getOrDefault("X-Amz-Signature")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Signature", valid_21626835
  var valid_21626836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626836
  var valid_21626837 = header.getOrDefault("X-Amz-Credential")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-Credential", valid_21626837
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_21626838 = formData.getOrDefault("AvailabilityZones")
  valid_21626838 = validateParameter(valid_21626838, JArray, required = true,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "AvailabilityZones", valid_21626838
  var valid_21626839 = formData.getOrDefault("LoadBalancerName")
  valid_21626839 = validateParameter(valid_21626839, JString, required = true,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "LoadBalancerName", valid_21626839
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626840: Call_PostEnableAvailabilityZonesForLoadBalancer_21626826;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626840.validator(path, query, header, formData, body, _)
  let scheme = call_21626840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626840.makeUrl(scheme.get, call_21626840.host, call_21626840.base,
                               call_21626840.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626840, uri, valid, _)

proc call*(call_21626841: Call_PostEnableAvailabilityZonesForLoadBalancer_21626826;
          AvailabilityZones: JsonNode; LoadBalancerName: string;
          Action: string = "EnableAvailabilityZonesForLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postEnableAvailabilityZonesForLoadBalancer
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626842 = newJObject()
  var formData_21626843 = newJObject()
  add(query_21626842, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_21626843.add "AvailabilityZones", AvailabilityZones
  add(formData_21626843, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626842, "Version", newJString(Version))
  result = call_21626841.call(nil, query_21626842, nil, formData_21626843, nil)

var postEnableAvailabilityZonesForLoadBalancer* = Call_PostEnableAvailabilityZonesForLoadBalancer_21626826(
    name: "postEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_PostEnableAvailabilityZonesForLoadBalancer_21626827,
    base: "/", makeUrl: url_PostEnableAvailabilityZonesForLoadBalancer_21626828,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAvailabilityZonesForLoadBalancer_21626809 = ref object of OpenApiRestCall_21625435
proc url_GetEnableAvailabilityZonesForLoadBalancer_21626811(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEnableAvailabilityZonesForLoadBalancer_21626810(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626812 = query.getOrDefault("LoadBalancerName")
  valid_21626812 = validateParameter(valid_21626812, JString, required = true,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "LoadBalancerName", valid_21626812
  var valid_21626813 = query.getOrDefault("AvailabilityZones")
  valid_21626813 = validateParameter(valid_21626813, JArray, required = true,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "AvailabilityZones", valid_21626813
  var valid_21626814 = query.getOrDefault("Action")
  valid_21626814 = validateParameter(valid_21626814, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_21626814 != nil:
    section.add "Action", valid_21626814
  var valid_21626815 = query.getOrDefault("Version")
  valid_21626815 = validateParameter(valid_21626815, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626815 != nil:
    section.add "Version", valid_21626815
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
  var valid_21626816 = header.getOrDefault("X-Amz-Date")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-Date", valid_21626816
  var valid_21626817 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626817 = validateParameter(valid_21626817, JString, required = false,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "X-Amz-Security-Token", valid_21626817
  var valid_21626818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626818 = validateParameter(valid_21626818, JString, required = false,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626818
  var valid_21626819 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Algorithm", valid_21626819
  var valid_21626820 = header.getOrDefault("X-Amz-Signature")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Signature", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-Credential")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Credential", valid_21626822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626823: Call_GetEnableAvailabilityZonesForLoadBalancer_21626809;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626823.validator(path, query, header, formData, body, _)
  let scheme = call_21626823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626823.makeUrl(scheme.get, call_21626823.host, call_21626823.base,
                               call_21626823.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626823, uri, valid, _)

proc call*(call_21626824: Call_GetEnableAvailabilityZonesForLoadBalancer_21626809;
          LoadBalancerName: string; AvailabilityZones: JsonNode;
          Action: string = "EnableAvailabilityZonesForLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getEnableAvailabilityZonesForLoadBalancer
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626825 = newJObject()
  add(query_21626825, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_21626825.add "AvailabilityZones", AvailabilityZones
  add(query_21626825, "Action", newJString(Action))
  add(query_21626825, "Version", newJString(Version))
  result = call_21626824.call(nil, query_21626825, nil, nil, nil)

var getEnableAvailabilityZonesForLoadBalancer* = Call_GetEnableAvailabilityZonesForLoadBalancer_21626809(
    name: "getEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_GetEnableAvailabilityZonesForLoadBalancer_21626810,
    base: "/", makeUrl: url_GetEnableAvailabilityZonesForLoadBalancer_21626811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_21626865 = ref object of OpenApiRestCall_21625435
proc url_PostModifyLoadBalancerAttributes_21626867(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyLoadBalancerAttributes_21626866(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626868 = query.getOrDefault("Action")
  valid_21626868 = validateParameter(valid_21626868, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_21626868 != nil:
    section.add "Action", valid_21626868
  var valid_21626869 = query.getOrDefault("Version")
  valid_21626869 = validateParameter(valid_21626869, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626869 != nil:
    section.add "Version", valid_21626869
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
  var valid_21626870 = header.getOrDefault("X-Amz-Date")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-Date", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Security-Token", valid_21626871
  var valid_21626872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Algorithm", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Signature")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-Signature", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-Credential")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-Credential", valid_21626876
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerAttributes.AdditionalAttributes: JArray
  ##                                              : The attributes for a load balancer.
  ## This parameter is reserved.
  ##   LoadBalancerAttributes.CrossZoneLoadBalancing: JString
  ##                                                : The attributes for a load balancer.
  ## <p>If enabled, the load balancer routes the request traffic evenly across all instances regardless of the Availability Zones.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Configure Cross-Zone Load Balancing</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributes.AccessLog: JString
  ##                                   : The attributes for a load balancer.
  ## <p>If enabled, the load balancer captures detailed information of all requests and delivers the information to the Amazon S3 bucket that you specify.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html">Enable Access Logs</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributes.ConnectionSettings: JString
  ##                                            : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows the connections to remain idle (no data is sent over the connection) for the specified duration.</p> <p>By default, Elastic Load Balancing maintains a 60-second idle connection timeout for both front-end and back-end connections of your load balancer. For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Configure Idle Connection Timeout</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerAttributes.ConnectionDraining: JString
  ##                                            : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows existing requests to complete before the load balancer shifts traffic away from a deregistered or unhealthy instance.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Configure Connection Draining</a> in the <i>Classic Load Balancers Guide</i>.</p>
  section = newJObject()
  var valid_21626877 = formData.getOrDefault(
      "LoadBalancerAttributes.AdditionalAttributes")
  valid_21626877 = validateParameter(valid_21626877, JArray, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_21626877
  var valid_21626878 = formData.getOrDefault(
      "LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_21626878 = validateParameter(valid_21626878, JString, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_21626878
  var valid_21626879 = formData.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_21626879
  var valid_21626880 = formData.getOrDefault(
      "LoadBalancerAttributes.ConnectionSettings")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_21626880
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_21626881 = formData.getOrDefault("LoadBalancerName")
  valid_21626881 = validateParameter(valid_21626881, JString, required = true,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "LoadBalancerName", valid_21626881
  var valid_21626882 = formData.getOrDefault(
      "LoadBalancerAttributes.ConnectionDraining")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_21626882
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626883: Call_PostModifyLoadBalancerAttributes_21626865;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_21626883.validator(path, query, header, formData, body, _)
  let scheme = call_21626883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626883.makeUrl(scheme.get, call_21626883.host, call_21626883.base,
                               call_21626883.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626883, uri, valid, _)

proc call*(call_21626884: Call_PostModifyLoadBalancerAttributes_21626865;
          LoadBalancerName: string;
          LoadBalancerAttributesAdditionalAttributes: JsonNode = nil;
          LoadBalancerAttributesCrossZoneLoadBalancing: string = "";
          LoadBalancerAttributesAccessLog: string = "";
          Action: string = "ModifyLoadBalancerAttributes";
          LoadBalancerAttributesConnectionSettings: string = "";
          LoadBalancerAttributesConnectionDraining: string = "";
          Version: string = "2012-06-01"): Recallable =
  ## postModifyLoadBalancerAttributes
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ##   LoadBalancerAttributesAdditionalAttributes: JArray
  ##                                             : The attributes for a load balancer.
  ## This parameter is reserved.
  ##   LoadBalancerAttributesCrossZoneLoadBalancing: string
  ##                                               : The attributes for a load balancer.
  ## <p>If enabled, the load balancer routes the request traffic evenly across all instances regardless of the Availability Zones.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Configure Cross-Zone Load Balancing</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributesAccessLog: string
  ##                                  : The attributes for a load balancer.
  ## <p>If enabled, the load balancer captures detailed information of all requests and delivers the information to the Amazon S3 bucket that you specify.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html">Enable Access Logs</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   LoadBalancerAttributesConnectionSettings: string
  ##                                           : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows the connections to remain idle (no data is sent over the connection) for the specified duration.</p> <p>By default, Elastic Load Balancing maintains a 60-second idle connection timeout for both front-end and back-end connections of your load balancer. For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Configure Idle Connection Timeout</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerAttributesConnectionDraining: string
  ##                                           : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows existing requests to complete before the load balancer shifts traffic away from a deregistered or unhealthy instance.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Configure Connection Draining</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Version: string (required)
  var query_21626885 = newJObject()
  var formData_21626886 = newJObject()
  if LoadBalancerAttributesAdditionalAttributes != nil:
    formData_21626886.add "LoadBalancerAttributes.AdditionalAttributes",
                         LoadBalancerAttributesAdditionalAttributes
  add(formData_21626886, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  add(formData_21626886, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_21626885, "Action", newJString(Action))
  add(formData_21626886, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(formData_21626886, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_21626886, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_21626885, "Version", newJString(Version))
  result = call_21626884.call(nil, query_21626885, nil, formData_21626886, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_21626865(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_21626866, base: "/",
    makeUrl: url_PostModifyLoadBalancerAttributes_21626867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_21626844 = ref object of OpenApiRestCall_21625435
proc url_GetModifyLoadBalancerAttributes_21626846(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyLoadBalancerAttributes_21626845(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerAttributes.AccessLog: JString
  ##                                   : The attributes for a load balancer.
  ## <p>If enabled, the load balancer captures detailed information of all requests and delivers the information to the Amazon S3 bucket that you specify.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html">Enable Access Logs</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributes.CrossZoneLoadBalancing: JString
  ##                                                : The attributes for a load balancer.
  ## <p>If enabled, the load balancer routes the request traffic evenly across all instances regardless of the Availability Zones.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Configure Cross-Zone Load Balancing</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributes.AdditionalAttributes: JArray
  ##                                              : The attributes for a load balancer.
  ## This parameter is reserved.
  ##   LoadBalancerAttributes.ConnectionSettings: JString
  ##                                            : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows the connections to remain idle (no data is sent over the connection) for the specified duration.</p> <p>By default, Elastic Load Balancing maintains a 60-second idle connection timeout for both front-end and back-end connections of your load balancer. For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Configure Idle Connection Timeout</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: JString (required)
  ##   LoadBalancerAttributes.ConnectionDraining: JString
  ##                                            : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows existing requests to complete before the load balancer shifts traffic away from a deregistered or unhealthy instance.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Configure Connection Draining</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626847 = query.getOrDefault("LoadBalancerName")
  valid_21626847 = validateParameter(valid_21626847, JString, required = true,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "LoadBalancerName", valid_21626847
  var valid_21626848 = query.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_21626848 = validateParameter(valid_21626848, JString, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_21626848
  var valid_21626849 = query.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_21626849
  var valid_21626850 = query.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_21626850 = validateParameter(valid_21626850, JArray, required = false,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_21626850
  var valid_21626851 = query.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_21626851 = validateParameter(valid_21626851, JString, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_21626851
  var valid_21626852 = query.getOrDefault("Action")
  valid_21626852 = validateParameter(valid_21626852, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_21626852 != nil:
    section.add "Action", valid_21626852
  var valid_21626853 = query.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_21626853 = validateParameter(valid_21626853, JString, required = false,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_21626853
  var valid_21626854 = query.getOrDefault("Version")
  valid_21626854 = validateParameter(valid_21626854, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626854 != nil:
    section.add "Version", valid_21626854
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
  var valid_21626855 = header.getOrDefault("X-Amz-Date")
  valid_21626855 = validateParameter(valid_21626855, JString, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "X-Amz-Date", valid_21626855
  var valid_21626856 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Security-Token", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Algorithm", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Signature")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "X-Amz-Signature", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-Credential")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-Credential", valid_21626861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626862: Call_GetModifyLoadBalancerAttributes_21626844;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_21626862.validator(path, query, header, formData, body, _)
  let scheme = call_21626862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626862.makeUrl(scheme.get, call_21626862.host, call_21626862.base,
                               call_21626862.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626862, uri, valid, _)

proc call*(call_21626863: Call_GetModifyLoadBalancerAttributes_21626844;
          LoadBalancerName: string; LoadBalancerAttributesAccessLog: string = "";
          LoadBalancerAttributesCrossZoneLoadBalancing: string = "";
          LoadBalancerAttributesAdditionalAttributes: JsonNode = nil;
          LoadBalancerAttributesConnectionSettings: string = "";
          Action: string = "ModifyLoadBalancerAttributes";
          LoadBalancerAttributesConnectionDraining: string = "";
          Version: string = "2012-06-01"): Recallable =
  ## getModifyLoadBalancerAttributes
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerAttributesAccessLog: string
  ##                                  : The attributes for a load balancer.
  ## <p>If enabled, the load balancer captures detailed information of all requests and delivers the information to the Amazon S3 bucket that you specify.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html">Enable Access Logs</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributesCrossZoneLoadBalancing: string
  ##                                               : The attributes for a load balancer.
  ## <p>If enabled, the load balancer routes the request traffic evenly across all instances regardless of the Availability Zones.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Configure Cross-Zone Load Balancing</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerAttributesAdditionalAttributes: JArray
  ##                                             : The attributes for a load balancer.
  ## This parameter is reserved.
  ##   LoadBalancerAttributesConnectionSettings: string
  ##                                           : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows the connections to remain idle (no data is sent over the connection) for the specified duration.</p> <p>By default, Elastic Load Balancing maintains a 60-second idle connection timeout for both front-end and back-end connections of your load balancer. For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Configure Idle Connection Timeout</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Action: string (required)
  ##   LoadBalancerAttributesConnectionDraining: string
  ##                                           : The attributes for a load balancer.
  ## <p>If enabled, the load balancer allows existing requests to complete before the load balancer shifts traffic away from a deregistered or unhealthy instance.</p> <p>For more information, see <a 
  ## href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Configure Connection Draining</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Version: string (required)
  var query_21626864 = newJObject()
  add(query_21626864, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626864, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_21626864, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    query_21626864.add "LoadBalancerAttributes.AdditionalAttributes",
                      LoadBalancerAttributesAdditionalAttributes
  add(query_21626864, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_21626864, "Action", newJString(Action))
  add(query_21626864, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_21626864, "Version", newJString(Version))
  result = call_21626863.call(nil, query_21626864, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_21626844(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_21626845, base: "/",
    makeUrl: url_GetModifyLoadBalancerAttributes_21626846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterInstancesWithLoadBalancer_21626904 = ref object of OpenApiRestCall_21625435
proc url_PostRegisterInstancesWithLoadBalancer_21626906(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRegisterInstancesWithLoadBalancer_21626905(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626907 = query.getOrDefault("Action")
  valid_21626907 = validateParameter(valid_21626907, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_21626907 != nil:
    section.add "Action", valid_21626907
  var valid_21626908 = query.getOrDefault("Version")
  valid_21626908 = validateParameter(valid_21626908, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626908 != nil:
    section.add "Version", valid_21626908
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
  var valid_21626909 = header.getOrDefault("X-Amz-Date")
  valid_21626909 = validateParameter(valid_21626909, JString, required = false,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "X-Amz-Date", valid_21626909
  var valid_21626910 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Security-Token", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Algorithm", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-Signature")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Signature", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-Credential")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-Credential", valid_21626915
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_21626916 = formData.getOrDefault("Instances")
  valid_21626916 = validateParameter(valid_21626916, JArray, required = true,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "Instances", valid_21626916
  var valid_21626917 = formData.getOrDefault("LoadBalancerName")
  valid_21626917 = validateParameter(valid_21626917, JString, required = true,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "LoadBalancerName", valid_21626917
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626918: Call_PostRegisterInstancesWithLoadBalancer_21626904;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626918.validator(path, query, header, formData, body, _)
  let scheme = call_21626918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626918.makeUrl(scheme.get, call_21626918.host, call_21626918.base,
                               call_21626918.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626918, uri, valid, _)

proc call*(call_21626919: Call_PostRegisterInstancesWithLoadBalancer_21626904;
          Instances: JsonNode; LoadBalancerName: string;
          Action: string = "RegisterInstancesWithLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postRegisterInstancesWithLoadBalancer
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626920 = newJObject()
  var formData_21626921 = newJObject()
  if Instances != nil:
    formData_21626921.add "Instances", Instances
  add(query_21626920, "Action", newJString(Action))
  add(formData_21626921, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626920, "Version", newJString(Version))
  result = call_21626919.call(nil, query_21626920, nil, formData_21626921, nil)

var postRegisterInstancesWithLoadBalancer* = Call_PostRegisterInstancesWithLoadBalancer_21626904(
    name: "postRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_PostRegisterInstancesWithLoadBalancer_21626905, base: "/",
    makeUrl: url_PostRegisterInstancesWithLoadBalancer_21626906,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterInstancesWithLoadBalancer_21626887 = ref object of OpenApiRestCall_21625435
proc url_GetRegisterInstancesWithLoadBalancer_21626889(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRegisterInstancesWithLoadBalancer_21626888(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626890 = query.getOrDefault("LoadBalancerName")
  valid_21626890 = validateParameter(valid_21626890, JString, required = true,
                                   default = nil)
  if valid_21626890 != nil:
    section.add "LoadBalancerName", valid_21626890
  var valid_21626891 = query.getOrDefault("Action")
  valid_21626891 = validateParameter(valid_21626891, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_21626891 != nil:
    section.add "Action", valid_21626891
  var valid_21626892 = query.getOrDefault("Instances")
  valid_21626892 = validateParameter(valid_21626892, JArray, required = true,
                                   default = nil)
  if valid_21626892 != nil:
    section.add "Instances", valid_21626892
  var valid_21626893 = query.getOrDefault("Version")
  valid_21626893 = validateParameter(valid_21626893, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626893 != nil:
    section.add "Version", valid_21626893
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
  var valid_21626894 = header.getOrDefault("X-Amz-Date")
  valid_21626894 = validateParameter(valid_21626894, JString, required = false,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "X-Amz-Date", valid_21626894
  var valid_21626895 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "X-Amz-Security-Token", valid_21626895
  var valid_21626896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Algorithm", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Signature")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Signature", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Credential")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Credential", valid_21626900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626901: Call_GetRegisterInstancesWithLoadBalancer_21626887;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626901.validator(path, query, header, formData, body, _)
  let scheme = call_21626901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626901.makeUrl(scheme.get, call_21626901.host, call_21626901.base,
                               call_21626901.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626901, uri, valid, _)

proc call*(call_21626902: Call_GetRegisterInstancesWithLoadBalancer_21626887;
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
  var query_21626903 = newJObject()
  add(query_21626903, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626903, "Action", newJString(Action))
  if Instances != nil:
    query_21626903.add "Instances", Instances
  add(query_21626903, "Version", newJString(Version))
  result = call_21626902.call(nil, query_21626903, nil, nil, nil)

var getRegisterInstancesWithLoadBalancer* = Call_GetRegisterInstancesWithLoadBalancer_21626887(
    name: "getRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_GetRegisterInstancesWithLoadBalancer_21626888, base: "/",
    makeUrl: url_GetRegisterInstancesWithLoadBalancer_21626889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_21626939 = ref object of OpenApiRestCall_21625435
proc url_PostRemoveTags_21626941(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTags_21626940(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626942 = query.getOrDefault("Action")
  valid_21626942 = validateParameter(valid_21626942, JString, required = true,
                                   default = newJString("RemoveTags"))
  if valid_21626942 != nil:
    section.add "Action", valid_21626942
  var valid_21626943 = query.getOrDefault("Version")
  valid_21626943 = validateParameter(valid_21626943, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626943 != nil:
    section.add "Version", valid_21626943
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
  var valid_21626944 = header.getOrDefault("X-Amz-Date")
  valid_21626944 = validateParameter(valid_21626944, JString, required = false,
                                   default = nil)
  if valid_21626944 != nil:
    section.add "X-Amz-Date", valid_21626944
  var valid_21626945 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-Security-Token", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Algorithm", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Signature")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Signature", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626949 = validateParameter(valid_21626949, JString, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-Credential")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-Credential", valid_21626950
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_21626951 = formData.getOrDefault("Tags")
  valid_21626951 = validateParameter(valid_21626951, JArray, required = true,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "Tags", valid_21626951
  var valid_21626952 = formData.getOrDefault("LoadBalancerNames")
  valid_21626952 = validateParameter(valid_21626952, JArray, required = true,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "LoadBalancerNames", valid_21626952
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626953: Call_PostRemoveTags_21626939; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_21626953.validator(path, query, header, formData, body, _)
  let scheme = call_21626953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626953.makeUrl(scheme.get, call_21626953.host, call_21626953.base,
                               call_21626953.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626953, uri, valid, _)

proc call*(call_21626954: Call_PostRemoveTags_21626939; Tags: JsonNode;
          LoadBalancerNames: JsonNode; Action: string = "RemoveTags";
          Version: string = "2012-06-01"): Recallable =
  ## postRemoveTags
  ## Removes one or more tags from the specified load balancer.
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  ##   Version: string (required)
  var query_21626955 = newJObject()
  var formData_21626956 = newJObject()
  if Tags != nil:
    formData_21626956.add "Tags", Tags
  add(query_21626955, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_21626956.add "LoadBalancerNames", LoadBalancerNames
  add(query_21626955, "Version", newJString(Version))
  result = call_21626954.call(nil, query_21626955, nil, formData_21626956, nil)

var postRemoveTags* = Call_PostRemoveTags_21626939(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_21626940,
    base: "/", makeUrl: url_PostRemoveTags_21626941,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_21626922 = ref object of OpenApiRestCall_21625435
proc url_GetRemoveTags_21626924(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTags_21626923(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_21626925 = query.getOrDefault("Tags")
  valid_21626925 = validateParameter(valid_21626925, JArray, required = true,
                                   default = nil)
  if valid_21626925 != nil:
    section.add "Tags", valid_21626925
  var valid_21626926 = query.getOrDefault("Action")
  valid_21626926 = validateParameter(valid_21626926, JString, required = true,
                                   default = newJString("RemoveTags"))
  if valid_21626926 != nil:
    section.add "Action", valid_21626926
  var valid_21626927 = query.getOrDefault("LoadBalancerNames")
  valid_21626927 = validateParameter(valid_21626927, JArray, required = true,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "LoadBalancerNames", valid_21626927
  var valid_21626928 = query.getOrDefault("Version")
  valid_21626928 = validateParameter(valid_21626928, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626928 != nil:
    section.add "Version", valid_21626928
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
  var valid_21626929 = header.getOrDefault("X-Amz-Date")
  valid_21626929 = validateParameter(valid_21626929, JString, required = false,
                                   default = nil)
  if valid_21626929 != nil:
    section.add "X-Amz-Date", valid_21626929
  var valid_21626930 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626930 = validateParameter(valid_21626930, JString, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "X-Amz-Security-Token", valid_21626930
  var valid_21626931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Algorithm", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Signature")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Signature", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-Credential")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-Credential", valid_21626935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626936: Call_GetRemoveTags_21626922; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_21626936.validator(path, query, header, formData, body, _)
  let scheme = call_21626936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626936.makeUrl(scheme.get, call_21626936.host, call_21626936.base,
                               call_21626936.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626936, uri, valid, _)

proc call*(call_21626937: Call_GetRemoveTags_21626922; Tags: JsonNode;
          LoadBalancerNames: JsonNode; Action: string = "RemoveTags";
          Version: string = "2012-06-01"): Recallable =
  ## getRemoveTags
  ## Removes one or more tags from the specified load balancer.
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  ##   Version: string (required)
  var query_21626938 = newJObject()
  if Tags != nil:
    query_21626938.add "Tags", Tags
  add(query_21626938, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_21626938.add "LoadBalancerNames", LoadBalancerNames
  add(query_21626938, "Version", newJString(Version))
  result = call_21626937.call(nil, query_21626938, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_21626922(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_21626923,
    base: "/", makeUrl: url_GetRemoveTags_21626924,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerListenerSSLCertificate_21626975 = ref object of OpenApiRestCall_21625435
proc url_PostSetLoadBalancerListenerSSLCertificate_21626977(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetLoadBalancerListenerSSLCertificate_21626976(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626978 = query.getOrDefault("Action")
  valid_21626978 = validateParameter(valid_21626978, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_21626978 != nil:
    section.add "Action", valid_21626978
  var valid_21626979 = query.getOrDefault("Version")
  valid_21626979 = validateParameter(valid_21626979, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626979 != nil:
    section.add "Version", valid_21626979
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
  var valid_21626980 = header.getOrDefault("X-Amz-Date")
  valid_21626980 = validateParameter(valid_21626980, JString, required = false,
                                   default = nil)
  if valid_21626980 != nil:
    section.add "X-Amz-Date", valid_21626980
  var valid_21626981 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Security-Token", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626983 = validateParameter(valid_21626983, JString, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "X-Amz-Algorithm", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-Signature")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Signature", valid_21626984
  var valid_21626985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626985 = validateParameter(valid_21626985, JString, required = false,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626985
  var valid_21626986 = header.getOrDefault("X-Amz-Credential")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "X-Amz-Credential", valid_21626986
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerPort: JInt (required)
  ##                   : The port that uses the specified SSL certificate.
  ##   SSLCertificateId: JString (required)
  ##                   : The Amazon Resource Name (ARN) of the SSL certificate.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerPort` field"
  var valid_21626987 = formData.getOrDefault("LoadBalancerPort")
  valid_21626987 = validateParameter(valid_21626987, JInt, required = true,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "LoadBalancerPort", valid_21626987
  var valid_21626988 = formData.getOrDefault("SSLCertificateId")
  valid_21626988 = validateParameter(valid_21626988, JString, required = true,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "SSLCertificateId", valid_21626988
  var valid_21626989 = formData.getOrDefault("LoadBalancerName")
  valid_21626989 = validateParameter(valid_21626989, JString, required = true,
                                   default = nil)
  if valid_21626989 != nil:
    section.add "LoadBalancerName", valid_21626989
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626990: Call_PostSetLoadBalancerListenerSSLCertificate_21626975;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626990.validator(path, query, header, formData, body, _)
  let scheme = call_21626990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626990.makeUrl(scheme.get, call_21626990.host, call_21626990.base,
                               call_21626990.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626990, uri, valid, _)

proc call*(call_21626991: Call_PostSetLoadBalancerListenerSSLCertificate_21626975;
          LoadBalancerPort: int; SSLCertificateId: string; LoadBalancerName: string;
          Action: string = "SetLoadBalancerListenerSSLCertificate";
          Version: string = "2012-06-01"): Recallable =
  ## postSetLoadBalancerListenerSSLCertificate
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerPort: int (required)
  ##                   : The port that uses the specified SSL certificate.
  ##   SSLCertificateId: string (required)
  ##                   : The Amazon Resource Name (ARN) of the SSL certificate.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21626992 = newJObject()
  var formData_21626993 = newJObject()
  add(formData_21626993, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(formData_21626993, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_21626992, "Action", newJString(Action))
  add(formData_21626993, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626992, "Version", newJString(Version))
  result = call_21626991.call(nil, query_21626992, nil, formData_21626993, nil)

var postSetLoadBalancerListenerSSLCertificate* = Call_PostSetLoadBalancerListenerSSLCertificate_21626975(
    name: "postSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_PostSetLoadBalancerListenerSSLCertificate_21626976,
    base: "/", makeUrl: url_PostSetLoadBalancerListenerSSLCertificate_21626977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerListenerSSLCertificate_21626957 = ref object of OpenApiRestCall_21625435
proc url_GetSetLoadBalancerListenerSSLCertificate_21626959(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetLoadBalancerListenerSSLCertificate_21626958(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   SSLCertificateId: JString (required)
  ##                   : The Amazon Resource Name (ARN) of the SSL certificate.
  ##   LoadBalancerPort: JInt (required)
  ##                   : The port that uses the specified SSL certificate.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626960 = query.getOrDefault("LoadBalancerName")
  valid_21626960 = validateParameter(valid_21626960, JString, required = true,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "LoadBalancerName", valid_21626960
  var valid_21626961 = query.getOrDefault("SSLCertificateId")
  valid_21626961 = validateParameter(valid_21626961, JString, required = true,
                                   default = nil)
  if valid_21626961 != nil:
    section.add "SSLCertificateId", valid_21626961
  var valid_21626962 = query.getOrDefault("LoadBalancerPort")
  valid_21626962 = validateParameter(valid_21626962, JInt, required = true,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "LoadBalancerPort", valid_21626962
  var valid_21626963 = query.getOrDefault("Action")
  valid_21626963 = validateParameter(valid_21626963, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_21626963 != nil:
    section.add "Action", valid_21626963
  var valid_21626964 = query.getOrDefault("Version")
  valid_21626964 = validateParameter(valid_21626964, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21626964 != nil:
    section.add "Version", valid_21626964
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
  var valid_21626965 = header.getOrDefault("X-Amz-Date")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Date", valid_21626965
  var valid_21626966 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-Security-Token", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626967
  var valid_21626968 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626968 = validateParameter(valid_21626968, JString, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "X-Amz-Algorithm", valid_21626968
  var valid_21626969 = header.getOrDefault("X-Amz-Signature")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "X-Amz-Signature", valid_21626969
  var valid_21626970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626970
  var valid_21626971 = header.getOrDefault("X-Amz-Credential")
  valid_21626971 = validateParameter(valid_21626971, JString, required = false,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "X-Amz-Credential", valid_21626971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626972: Call_GetSetLoadBalancerListenerSSLCertificate_21626957;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21626972.validator(path, query, header, formData, body, _)
  let scheme = call_21626972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626972.makeUrl(scheme.get, call_21626972.host, call_21626972.base,
                               call_21626972.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626972, uri, valid, _)

proc call*(call_21626973: Call_GetSetLoadBalancerListenerSSLCertificate_21626957;
          LoadBalancerName: string; SSLCertificateId: string; LoadBalancerPort: int;
          Action: string = "SetLoadBalancerListenerSSLCertificate";
          Version: string = "2012-06-01"): Recallable =
  ## getSetLoadBalancerListenerSSLCertificate
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   SSLCertificateId: string (required)
  ##                   : The Amazon Resource Name (ARN) of the SSL certificate.
  ##   LoadBalancerPort: int (required)
  ##                   : The port that uses the specified SSL certificate.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626974 = newJObject()
  add(query_21626974, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21626974, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_21626974, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_21626974, "Action", newJString(Action))
  add(query_21626974, "Version", newJString(Version))
  result = call_21626973.call(nil, query_21626974, nil, nil, nil)

var getSetLoadBalancerListenerSSLCertificate* = Call_GetSetLoadBalancerListenerSSLCertificate_21626957(
    name: "getSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_GetSetLoadBalancerListenerSSLCertificate_21626958,
    base: "/", makeUrl: url_GetSetLoadBalancerListenerSSLCertificate_21626959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesForBackendServer_21627012 = ref object of OpenApiRestCall_21625435
proc url_PostSetLoadBalancerPoliciesForBackendServer_21627014(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetLoadBalancerPoliciesForBackendServer_21627013(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627015 = query.getOrDefault("Action")
  valid_21627015 = validateParameter(valid_21627015, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_21627015 != nil:
    section.add "Action", valid_21627015
  var valid_21627016 = query.getOrDefault("Version")
  valid_21627016 = validateParameter(valid_21627016, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21627016 != nil:
    section.add "Version", valid_21627016
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
  var valid_21627017 = header.getOrDefault("X-Amz-Date")
  valid_21627017 = validateParameter(valid_21627017, JString, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "X-Amz-Date", valid_21627017
  var valid_21627018 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627018 = validateParameter(valid_21627018, JString, required = false,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "X-Amz-Security-Token", valid_21627018
  var valid_21627019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627019 = validateParameter(valid_21627019, JString, required = false,
                                   default = nil)
  if valid_21627019 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627019
  var valid_21627020 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "X-Amz-Algorithm", valid_21627020
  var valid_21627021 = header.getOrDefault("X-Amz-Signature")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "X-Amz-Signature", valid_21627021
  var valid_21627022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627022 = validateParameter(valid_21627022, JString, required = false,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627022
  var valid_21627023 = header.getOrDefault("X-Amz-Credential")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-Credential", valid_21627023
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. If the list is empty, then all current polices are removed from the EC2 instance.
  ##   InstancePort: JInt (required)
  ##               : The port number associated with the EC2 instance.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PolicyNames` field"
  var valid_21627024 = formData.getOrDefault("PolicyNames")
  valid_21627024 = validateParameter(valid_21627024, JArray, required = true,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "PolicyNames", valid_21627024
  var valid_21627025 = formData.getOrDefault("InstancePort")
  valid_21627025 = validateParameter(valid_21627025, JInt, required = true,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "InstancePort", valid_21627025
  var valid_21627026 = formData.getOrDefault("LoadBalancerName")
  valid_21627026 = validateParameter(valid_21627026, JString, required = true,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "LoadBalancerName", valid_21627026
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627027: Call_PostSetLoadBalancerPoliciesForBackendServer_21627012;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21627027.validator(path, query, header, formData, body, _)
  let scheme = call_21627027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627027.makeUrl(scheme.get, call_21627027.host, call_21627027.base,
                               call_21627027.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627027, uri, valid, _)

proc call*(call_21627028: Call_PostSetLoadBalancerPoliciesForBackendServer_21627012;
          PolicyNames: JsonNode; InstancePort: int; LoadBalancerName: string;
          Action: string = "SetLoadBalancerPoliciesForBackendServer";
          Version: string = "2012-06-01"): Recallable =
  ## postSetLoadBalancerPoliciesForBackendServer
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. If the list is empty, then all current polices are removed from the EC2 instance.
  ##   InstancePort: int (required)
  ##               : The port number associated with the EC2 instance.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21627029 = newJObject()
  var formData_21627030 = newJObject()
  if PolicyNames != nil:
    formData_21627030.add "PolicyNames", PolicyNames
  add(formData_21627030, "InstancePort", newJInt(InstancePort))
  add(query_21627029, "Action", newJString(Action))
  add(formData_21627030, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21627029, "Version", newJString(Version))
  result = call_21627028.call(nil, query_21627029, nil, formData_21627030, nil)

var postSetLoadBalancerPoliciesForBackendServer* = Call_PostSetLoadBalancerPoliciesForBackendServer_21627012(
    name: "postSetLoadBalancerPoliciesForBackendServer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_PostSetLoadBalancerPoliciesForBackendServer_21627013,
    base: "/", makeUrl: url_PostSetLoadBalancerPoliciesForBackendServer_21627014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesForBackendServer_21626994 = ref object of OpenApiRestCall_21625435
proc url_GetSetLoadBalancerPoliciesForBackendServer_21626996(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetLoadBalancerPoliciesForBackendServer_21626995(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. If the list is empty, then all current polices are removed from the EC2 instance.
  ##   Version: JString (required)
  ##   InstancePort: JInt (required)
  ##               : The port number associated with the EC2 instance.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21626997 = query.getOrDefault("LoadBalancerName")
  valid_21626997 = validateParameter(valid_21626997, JString, required = true,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "LoadBalancerName", valid_21626997
  var valid_21626998 = query.getOrDefault("Action")
  valid_21626998 = validateParameter(valid_21626998, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_21626998 != nil:
    section.add "Action", valid_21626998
  var valid_21626999 = query.getOrDefault("PolicyNames")
  valid_21626999 = validateParameter(valid_21626999, JArray, required = true,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "PolicyNames", valid_21626999
  var valid_21627000 = query.getOrDefault("Version")
  valid_21627000 = validateParameter(valid_21627000, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21627000 != nil:
    section.add "Version", valid_21627000
  var valid_21627001 = query.getOrDefault("InstancePort")
  valid_21627001 = validateParameter(valid_21627001, JInt, required = true,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "InstancePort", valid_21627001
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
  var valid_21627002 = header.getOrDefault("X-Amz-Date")
  valid_21627002 = validateParameter(valid_21627002, JString, required = false,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "X-Amz-Date", valid_21627002
  var valid_21627003 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627003 = validateParameter(valid_21627003, JString, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "X-Amz-Security-Token", valid_21627003
  var valid_21627004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627004 = validateParameter(valid_21627004, JString, required = false,
                                   default = nil)
  if valid_21627004 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627004
  var valid_21627005 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627005 = validateParameter(valid_21627005, JString, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "X-Amz-Algorithm", valid_21627005
  var valid_21627006 = header.getOrDefault("X-Amz-Signature")
  valid_21627006 = validateParameter(valid_21627006, JString, required = false,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "X-Amz-Signature", valid_21627006
  var valid_21627007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627007 = validateParameter(valid_21627007, JString, required = false,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627007
  var valid_21627008 = header.getOrDefault("X-Amz-Credential")
  valid_21627008 = validateParameter(valid_21627008, JString, required = false,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "X-Amz-Credential", valid_21627008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627009: Call_GetSetLoadBalancerPoliciesForBackendServer_21626994;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21627009.validator(path, query, header, formData, body, _)
  let scheme = call_21627009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627009.makeUrl(scheme.get, call_21627009.host, call_21627009.base,
                               call_21627009.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627009, uri, valid, _)

proc call*(call_21627010: Call_GetSetLoadBalancerPoliciesForBackendServer_21626994;
          LoadBalancerName: string; PolicyNames: JsonNode; InstancePort: int;
          Action: string = "SetLoadBalancerPoliciesForBackendServer";
          Version: string = "2012-06-01"): Recallable =
  ## getSetLoadBalancerPoliciesForBackendServer
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. If the list is empty, then all current polices are removed from the EC2 instance.
  ##   Version: string (required)
  ##   InstancePort: int (required)
  ##               : The port number associated with the EC2 instance.
  var query_21627011 = newJObject()
  add(query_21627011, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21627011, "Action", newJString(Action))
  if PolicyNames != nil:
    query_21627011.add "PolicyNames", PolicyNames
  add(query_21627011, "Version", newJString(Version))
  add(query_21627011, "InstancePort", newJInt(InstancePort))
  result = call_21627010.call(nil, query_21627011, nil, nil, nil)

var getSetLoadBalancerPoliciesForBackendServer* = Call_GetSetLoadBalancerPoliciesForBackendServer_21626994(
    name: "getSetLoadBalancerPoliciesForBackendServer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_GetSetLoadBalancerPoliciesForBackendServer_21626995,
    base: "/", makeUrl: url_GetSetLoadBalancerPoliciesForBackendServer_21626996,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesOfListener_21627049 = ref object of OpenApiRestCall_21625435
proc url_PostSetLoadBalancerPoliciesOfListener_21627051(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetLoadBalancerPoliciesOfListener_21627050(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627052 = query.getOrDefault("Action")
  valid_21627052 = validateParameter(valid_21627052, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_21627052 != nil:
    section.add "Action", valid_21627052
  var valid_21627053 = query.getOrDefault("Version")
  valid_21627053 = validateParameter(valid_21627053, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21627053 != nil:
    section.add "Version", valid_21627053
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
  var valid_21627054 = header.getOrDefault("X-Amz-Date")
  valid_21627054 = validateParameter(valid_21627054, JString, required = false,
                                   default = nil)
  if valid_21627054 != nil:
    section.add "X-Amz-Date", valid_21627054
  var valid_21627055 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "X-Amz-Security-Token", valid_21627055
  var valid_21627056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627056
  var valid_21627057 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "X-Amz-Algorithm", valid_21627057
  var valid_21627058 = header.getOrDefault("X-Amz-Signature")
  valid_21627058 = validateParameter(valid_21627058, JString, required = false,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "X-Amz-Signature", valid_21627058
  var valid_21627059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627059
  var valid_21627060 = header.getOrDefault("X-Amz-Credential")
  valid_21627060 = validateParameter(valid_21627060, JString, required = false,
                                   default = nil)
  if valid_21627060 != nil:
    section.add "X-Amz-Credential", valid_21627060
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerPort: JInt (required)
  ##                   : The external port of the load balancer.
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. This list must include all policies to be enabled. If you omit a policy that is currently enabled, it is disabled. If the list is empty, all current policies are disabled.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerPort` field"
  var valid_21627061 = formData.getOrDefault("LoadBalancerPort")
  valid_21627061 = validateParameter(valid_21627061, JInt, required = true,
                                   default = nil)
  if valid_21627061 != nil:
    section.add "LoadBalancerPort", valid_21627061
  var valid_21627062 = formData.getOrDefault("PolicyNames")
  valid_21627062 = validateParameter(valid_21627062, JArray, required = true,
                                   default = nil)
  if valid_21627062 != nil:
    section.add "PolicyNames", valid_21627062
  var valid_21627063 = formData.getOrDefault("LoadBalancerName")
  valid_21627063 = validateParameter(valid_21627063, JString, required = true,
                                   default = nil)
  if valid_21627063 != nil:
    section.add "LoadBalancerName", valid_21627063
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627064: Call_PostSetLoadBalancerPoliciesOfListener_21627049;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21627064.validator(path, query, header, formData, body, _)
  let scheme = call_21627064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627064.makeUrl(scheme.get, call_21627064.host, call_21627064.base,
                               call_21627064.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627064, uri, valid, _)

proc call*(call_21627065: Call_PostSetLoadBalancerPoliciesOfListener_21627049;
          LoadBalancerPort: int; PolicyNames: JsonNode; LoadBalancerName: string;
          Action: string = "SetLoadBalancerPoliciesOfListener";
          Version: string = "2012-06-01"): Recallable =
  ## postSetLoadBalancerPoliciesOfListener
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerPort: int (required)
  ##                   : The external port of the load balancer.
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. This list must include all policies to be enabled. If you omit a policy that is currently enabled, it is disabled. If the list is empty, all current policies are disabled.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_21627066 = newJObject()
  var formData_21627067 = newJObject()
  add(formData_21627067, "LoadBalancerPort", newJInt(LoadBalancerPort))
  if PolicyNames != nil:
    formData_21627067.add "PolicyNames", PolicyNames
  add(query_21627066, "Action", newJString(Action))
  add(formData_21627067, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21627066, "Version", newJString(Version))
  result = call_21627065.call(nil, query_21627066, nil, formData_21627067, nil)

var postSetLoadBalancerPoliciesOfListener* = Call_PostSetLoadBalancerPoliciesOfListener_21627049(
    name: "postSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_PostSetLoadBalancerPoliciesOfListener_21627050, base: "/",
    makeUrl: url_PostSetLoadBalancerPoliciesOfListener_21627051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesOfListener_21627031 = ref object of OpenApiRestCall_21625435
proc url_GetSetLoadBalancerPoliciesOfListener_21627033(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetLoadBalancerPoliciesOfListener_21627032(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerPort: JInt (required)
  ##                   : The external port of the load balancer.
  ##   Action: JString (required)
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. This list must include all policies to be enabled. If you omit a policy that is currently enabled, it is disabled. If the list is empty, all current policies are disabled.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_21627034 = query.getOrDefault("LoadBalancerName")
  valid_21627034 = validateParameter(valid_21627034, JString, required = true,
                                   default = nil)
  if valid_21627034 != nil:
    section.add "LoadBalancerName", valid_21627034
  var valid_21627035 = query.getOrDefault("LoadBalancerPort")
  valid_21627035 = validateParameter(valid_21627035, JInt, required = true,
                                   default = nil)
  if valid_21627035 != nil:
    section.add "LoadBalancerPort", valid_21627035
  var valid_21627036 = query.getOrDefault("Action")
  valid_21627036 = validateParameter(valid_21627036, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_21627036 != nil:
    section.add "Action", valid_21627036
  var valid_21627037 = query.getOrDefault("PolicyNames")
  valid_21627037 = validateParameter(valid_21627037, JArray, required = true,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "PolicyNames", valid_21627037
  var valid_21627038 = query.getOrDefault("Version")
  valid_21627038 = validateParameter(valid_21627038, JString, required = true,
                                   default = newJString("2012-06-01"))
  if valid_21627038 != nil:
    section.add "Version", valid_21627038
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
  var valid_21627039 = header.getOrDefault("X-Amz-Date")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "X-Amz-Date", valid_21627039
  var valid_21627040 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "X-Amz-Security-Token", valid_21627040
  var valid_21627041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627041
  var valid_21627042 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "X-Amz-Algorithm", valid_21627042
  var valid_21627043 = header.getOrDefault("X-Amz-Signature")
  valid_21627043 = validateParameter(valid_21627043, JString, required = false,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "X-Amz-Signature", valid_21627043
  var valid_21627044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627044
  var valid_21627045 = header.getOrDefault("X-Amz-Credential")
  valid_21627045 = validateParameter(valid_21627045, JString, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "X-Amz-Credential", valid_21627045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627046: Call_GetSetLoadBalancerPoliciesOfListener_21627031;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_21627046.validator(path, query, header, formData, body, _)
  let scheme = call_21627046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627046.makeUrl(scheme.get, call_21627046.host, call_21627046.base,
                               call_21627046.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627046, uri, valid, _)

proc call*(call_21627047: Call_GetSetLoadBalancerPoliciesOfListener_21627031;
          LoadBalancerName: string; LoadBalancerPort: int; PolicyNames: JsonNode;
          Action: string = "SetLoadBalancerPoliciesOfListener";
          Version: string = "2012-06-01"): Recallable =
  ## getSetLoadBalancerPoliciesOfListener
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerPort: int (required)
  ##                   : The external port of the load balancer.
  ##   Action: string (required)
  ##   PolicyNames: JArray (required)
  ##              : The names of the policies. This list must include all policies to be enabled. If you omit a policy that is currently enabled, it is disabled. If the list is empty, all current policies are disabled.
  ##   Version: string (required)
  var query_21627048 = newJObject()
  add(query_21627048, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_21627048, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_21627048, "Action", newJString(Action))
  if PolicyNames != nil:
    query_21627048.add "PolicyNames", PolicyNames
  add(query_21627048, "Version", newJString(Version))
  result = call_21627047.call(nil, query_21627048, nil, nil, nil)

var getSetLoadBalancerPoliciesOfListener* = Call_GetSetLoadBalancerPoliciesOfListener_21627031(
    name: "getSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_GetSetLoadBalancerPoliciesOfListener_21627032, base: "/",
    makeUrl: url_GetSetLoadBalancerPoliciesOfListener_21627033,
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