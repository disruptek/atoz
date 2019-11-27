
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_PostAddTags_599977 = ref object of OpenApiRestCall_599368
proc url_PostAddTags_599979(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTags_599978(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599980 = query.getOrDefault("Action")
  valid_599980 = validateParameter(valid_599980, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_599980 != nil:
    section.add "Action", valid_599980
  var valid_599981 = query.getOrDefault("Version")
  valid_599981 = validateParameter(valid_599981, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_599981 != nil:
    section.add "Version", valid_599981
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
  var valid_599982 = header.getOrDefault("X-Amz-Date")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Date", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Security-Token")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Security-Token", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Content-Sha256", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Algorithm")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Algorithm", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Signature")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Signature", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-SignedHeaders", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Credential")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Credential", valid_599988
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_599989 = formData.getOrDefault("Tags")
  valid_599989 = validateParameter(valid_599989, JArray, required = true, default = nil)
  if valid_599989 != nil:
    section.add "Tags", valid_599989
  var valid_599990 = formData.getOrDefault("LoadBalancerNames")
  valid_599990 = validateParameter(valid_599990, JArray, required = true, default = nil)
  if valid_599990 != nil:
    section.add "LoadBalancerNames", valid_599990
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599991: Call_PostAddTags_599977; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_599991.validator(path, query, header, formData, body)
  let scheme = call_599991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599991.url(scheme.get, call_599991.host, call_599991.base,
                         call_599991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599991, url, valid)

proc call*(call_599992: Call_PostAddTags_599977; Tags: JsonNode;
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
  var query_599993 = newJObject()
  var formData_599994 = newJObject()
  if Tags != nil:
    formData_599994.add "Tags", Tags
  add(query_599993, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_599994.add "LoadBalancerNames", LoadBalancerNames
  add(query_599993, "Version", newJString(Version))
  result = call_599992.call(nil, query_599993, nil, formData_599994, nil)

var postAddTags* = Call_PostAddTags_599977(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_599978,
                                        base: "/", url: url_PostAddTags_599979,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_599705 = ref object of OpenApiRestCall_599368
proc url_GetAddTags_599707(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTags_599706(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_599819 = query.getOrDefault("Tags")
  valid_599819 = validateParameter(valid_599819, JArray, required = true, default = nil)
  if valid_599819 != nil:
    section.add "Tags", valid_599819
  var valid_599833 = query.getOrDefault("Action")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_599833 != nil:
    section.add "Action", valid_599833
  var valid_599834 = query.getOrDefault("LoadBalancerNames")
  valid_599834 = validateParameter(valid_599834, JArray, required = true, default = nil)
  if valid_599834 != nil:
    section.add "LoadBalancerNames", valid_599834
  var valid_599835 = query.getOrDefault("Version")
  valid_599835 = validateParameter(valid_599835, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_599835 != nil:
    section.add "Version", valid_599835
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
  var valid_599836 = header.getOrDefault("X-Amz-Date")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Date", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Security-Token")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Security-Token", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Content-Sha256", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Algorithm")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Algorithm", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Signature")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Signature", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-SignedHeaders", valid_599841
  var valid_599842 = header.getOrDefault("X-Amz-Credential")
  valid_599842 = validateParameter(valid_599842, JString, required = false,
                                 default = nil)
  if valid_599842 != nil:
    section.add "X-Amz-Credential", valid_599842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599865: Call_GetAddTags_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_599865.validator(path, query, header, formData, body)
  let scheme = call_599865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599865.url(scheme.get, call_599865.host, call_599865.base,
                         call_599865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599865, url, valid)

proc call*(call_599936: Call_GetAddTags_599705; Tags: JsonNode;
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
  var query_599937 = newJObject()
  if Tags != nil:
    query_599937.add "Tags", Tags
  add(query_599937, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_599937.add "LoadBalancerNames", LoadBalancerNames
  add(query_599937, "Version", newJString(Version))
  result = call_599936.call(nil, query_599937, nil, nil, nil)

var getAddTags* = Call_GetAddTags_599705(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_599706,
                                      base: "/", url: url_GetAddTags_599707,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplySecurityGroupsToLoadBalancer_600012 = ref object of OpenApiRestCall_599368
proc url_PostApplySecurityGroupsToLoadBalancer_600014(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostApplySecurityGroupsToLoadBalancer_600013(path: JsonNode;
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
  var valid_600015 = query.getOrDefault("Action")
  valid_600015 = validateParameter(valid_600015, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_600015 != nil:
    section.add "Action", valid_600015
  var valid_600016 = query.getOrDefault("Version")
  valid_600016 = validateParameter(valid_600016, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600016 != nil:
    section.add "Version", valid_600016
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
  var valid_600017 = header.getOrDefault("X-Amz-Date")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Date", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Security-Token")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Security-Token", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Content-Sha256", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Algorithm")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Algorithm", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Signature")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Signature", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-SignedHeaders", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Credential")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Credential", valid_600023
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_600024 = formData.getOrDefault("SecurityGroups")
  valid_600024 = validateParameter(valid_600024, JArray, required = true, default = nil)
  if valid_600024 != nil:
    section.add "SecurityGroups", valid_600024
  var valid_600025 = formData.getOrDefault("LoadBalancerName")
  valid_600025 = validateParameter(valid_600025, JString, required = true,
                                 default = nil)
  if valid_600025 != nil:
    section.add "LoadBalancerName", valid_600025
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600026: Call_PostApplySecurityGroupsToLoadBalancer_600012;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600026.validator(path, query, header, formData, body)
  let scheme = call_600026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600026.url(scheme.get, call_600026.host, call_600026.base,
                         call_600026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600026, url, valid)

proc call*(call_600027: Call_PostApplySecurityGroupsToLoadBalancer_600012;
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
  var query_600028 = newJObject()
  var formData_600029 = newJObject()
  add(query_600028, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_600029.add "SecurityGroups", SecurityGroups
  add(formData_600029, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600028, "Version", newJString(Version))
  result = call_600027.call(nil, query_600028, nil, formData_600029, nil)

var postApplySecurityGroupsToLoadBalancer* = Call_PostApplySecurityGroupsToLoadBalancer_600012(
    name: "postApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_PostApplySecurityGroupsToLoadBalancer_600013, base: "/",
    url: url_PostApplySecurityGroupsToLoadBalancer_600014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplySecurityGroupsToLoadBalancer_599995 = ref object of OpenApiRestCall_599368
proc url_GetApplySecurityGroupsToLoadBalancer_599997(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplySecurityGroupsToLoadBalancer_599996(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599998 = query.getOrDefault("LoadBalancerName")
  valid_599998 = validateParameter(valid_599998, JString, required = true,
                                 default = nil)
  if valid_599998 != nil:
    section.add "LoadBalancerName", valid_599998
  var valid_599999 = query.getOrDefault("Action")
  valid_599999 = validateParameter(valid_599999, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_599999 != nil:
    section.add "Action", valid_599999
  var valid_600000 = query.getOrDefault("Version")
  valid_600000 = validateParameter(valid_600000, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600000 != nil:
    section.add "Version", valid_600000
  var valid_600001 = query.getOrDefault("SecurityGroups")
  valid_600001 = validateParameter(valid_600001, JArray, required = true, default = nil)
  if valid_600001 != nil:
    section.add "SecurityGroups", valid_600001
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
  var valid_600002 = header.getOrDefault("X-Amz-Date")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Date", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Security-Token")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Security-Token", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Content-Sha256", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Algorithm")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Algorithm", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Signature")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Signature", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-SignedHeaders", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Credential")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Credential", valid_600008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600009: Call_GetApplySecurityGroupsToLoadBalancer_599995;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600009.validator(path, query, header, formData, body)
  let scheme = call_600009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600009.url(scheme.get, call_600009.host, call_600009.base,
                         call_600009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600009, url, valid)

proc call*(call_600010: Call_GetApplySecurityGroupsToLoadBalancer_599995;
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
  var query_600011 = newJObject()
  add(query_600011, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600011, "Action", newJString(Action))
  add(query_600011, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_600011.add "SecurityGroups", SecurityGroups
  result = call_600010.call(nil, query_600011, nil, nil, nil)

var getApplySecurityGroupsToLoadBalancer* = Call_GetApplySecurityGroupsToLoadBalancer_599995(
    name: "getApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_GetApplySecurityGroupsToLoadBalancer_599996, base: "/",
    url: url_GetApplySecurityGroupsToLoadBalancer_599997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAttachLoadBalancerToSubnets_600047 = ref object of OpenApiRestCall_599368
proc url_PostAttachLoadBalancerToSubnets_600049(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAttachLoadBalancerToSubnets_600048(path: JsonNode;
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
  var valid_600050 = query.getOrDefault("Action")
  valid_600050 = validateParameter(valid_600050, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_600050 != nil:
    section.add "Action", valid_600050
  var valid_600051 = query.getOrDefault("Version")
  valid_600051 = validateParameter(valid_600051, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600051 != nil:
    section.add "Version", valid_600051
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
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Content-Sha256", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Algorithm")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Algorithm", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Signature")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Signature", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-SignedHeaders", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Credential")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Credential", valid_600058
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_600059 = formData.getOrDefault("Subnets")
  valid_600059 = validateParameter(valid_600059, JArray, required = true, default = nil)
  if valid_600059 != nil:
    section.add "Subnets", valid_600059
  var valid_600060 = formData.getOrDefault("LoadBalancerName")
  valid_600060 = validateParameter(valid_600060, JString, required = true,
                                 default = nil)
  if valid_600060 != nil:
    section.add "LoadBalancerName", valid_600060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_PostAttachLoadBalancerToSubnets_600047;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_PostAttachLoadBalancerToSubnets_600047;
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
  var query_600063 = newJObject()
  var formData_600064 = newJObject()
  add(query_600063, "Action", newJString(Action))
  if Subnets != nil:
    formData_600064.add "Subnets", Subnets
  add(formData_600064, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600063, "Version", newJString(Version))
  result = call_600062.call(nil, query_600063, nil, formData_600064, nil)

var postAttachLoadBalancerToSubnets* = Call_PostAttachLoadBalancerToSubnets_600047(
    name: "postAttachLoadBalancerToSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_PostAttachLoadBalancerToSubnets_600048, base: "/",
    url: url_PostAttachLoadBalancerToSubnets_600049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttachLoadBalancerToSubnets_600030 = ref object of OpenApiRestCall_599368
proc url_GetAttachLoadBalancerToSubnets_600032(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAttachLoadBalancerToSubnets_600031(path: JsonNode;
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
  var valid_600033 = query.getOrDefault("LoadBalancerName")
  valid_600033 = validateParameter(valid_600033, JString, required = true,
                                 default = nil)
  if valid_600033 != nil:
    section.add "LoadBalancerName", valid_600033
  var valid_600034 = query.getOrDefault("Action")
  valid_600034 = validateParameter(valid_600034, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_600034 != nil:
    section.add "Action", valid_600034
  var valid_600035 = query.getOrDefault("Subnets")
  valid_600035 = validateParameter(valid_600035, JArray, required = true, default = nil)
  if valid_600035 != nil:
    section.add "Subnets", valid_600035
  var valid_600036 = query.getOrDefault("Version")
  valid_600036 = validateParameter(valid_600036, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600036 != nil:
    section.add "Version", valid_600036
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
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Content-Sha256", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Algorithm")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Algorithm", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Signature")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Signature", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-SignedHeaders", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Credential")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Credential", valid_600043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600044: Call_GetAttachLoadBalancerToSubnets_600030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600044.validator(path, query, header, formData, body)
  let scheme = call_600044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600044.url(scheme.get, call_600044.host, call_600044.base,
                         call_600044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600044, url, valid)

proc call*(call_600045: Call_GetAttachLoadBalancerToSubnets_600030;
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
  var query_600046 = newJObject()
  add(query_600046, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600046, "Action", newJString(Action))
  if Subnets != nil:
    query_600046.add "Subnets", Subnets
  add(query_600046, "Version", newJString(Version))
  result = call_600045.call(nil, query_600046, nil, nil, nil)

var getAttachLoadBalancerToSubnets* = Call_GetAttachLoadBalancerToSubnets_600030(
    name: "getAttachLoadBalancerToSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_GetAttachLoadBalancerToSubnets_600031, base: "/",
    url: url_GetAttachLoadBalancerToSubnets_600032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfigureHealthCheck_600086 = ref object of OpenApiRestCall_599368
proc url_PostConfigureHealthCheck_600088(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostConfigureHealthCheck_600087(path: JsonNode; query: JsonNode;
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
  var valid_600089 = query.getOrDefault("Action")
  valid_600089 = validateParameter(valid_600089, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_600089 != nil:
    section.add "Action", valid_600089
  var valid_600090 = query.getOrDefault("Version")
  valid_600090 = validateParameter(valid_600090, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600090 != nil:
    section.add "Version", valid_600090
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
  var valid_600091 = header.getOrDefault("X-Amz-Date")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Date", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Security-Token")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Security-Token", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-Content-Sha256", valid_600093
  var valid_600094 = header.getOrDefault("X-Amz-Algorithm")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Algorithm", valid_600094
  var valid_600095 = header.getOrDefault("X-Amz-Signature")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "X-Amz-Signature", valid_600095
  var valid_600096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-SignedHeaders", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-Credential")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Credential", valid_600097
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
  var valid_600098 = formData.getOrDefault("HealthCheck.HealthyThreshold")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_600098
  var valid_600099 = formData.getOrDefault("HealthCheck.Interval")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "HealthCheck.Interval", valid_600099
  var valid_600100 = formData.getOrDefault("HealthCheck.Timeout")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "HealthCheck.Timeout", valid_600100
  var valid_600101 = formData.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_600101
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_600102 = formData.getOrDefault("LoadBalancerName")
  valid_600102 = validateParameter(valid_600102, JString, required = true,
                                 default = nil)
  if valid_600102 != nil:
    section.add "LoadBalancerName", valid_600102
  var valid_600103 = formData.getOrDefault("HealthCheck.Target")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "HealthCheck.Target", valid_600103
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600104: Call_PostConfigureHealthCheck_600086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600104.validator(path, query, header, formData, body)
  let scheme = call_600104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600104.url(scheme.get, call_600104.host, call_600104.base,
                         call_600104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600104, url, valid)

proc call*(call_600105: Call_PostConfigureHealthCheck_600086;
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
  var query_600106 = newJObject()
  var formData_600107 = newJObject()
  add(formData_600107, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(formData_600107, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(formData_600107, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_600106, "Action", newJString(Action))
  add(formData_600107, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(formData_600107, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_600107, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_600106, "Version", newJString(Version))
  result = call_600105.call(nil, query_600106, nil, formData_600107, nil)

var postConfigureHealthCheck* = Call_PostConfigureHealthCheck_600086(
    name: "postConfigureHealthCheck", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_PostConfigureHealthCheck_600087, base: "/",
    url: url_PostConfigureHealthCheck_600088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigureHealthCheck_600065 = ref object of OpenApiRestCall_599368
proc url_GetConfigureHealthCheck_600067(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConfigureHealthCheck_600066(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600068 = query.getOrDefault("HealthCheck.HealthyThreshold")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_600068
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_600069 = query.getOrDefault("LoadBalancerName")
  valid_600069 = validateParameter(valid_600069, JString, required = true,
                                 default = nil)
  if valid_600069 != nil:
    section.add "LoadBalancerName", valid_600069
  var valid_600070 = query.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_600070
  var valid_600071 = query.getOrDefault("HealthCheck.Timeout")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "HealthCheck.Timeout", valid_600071
  var valid_600072 = query.getOrDefault("HealthCheck.Target")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "HealthCheck.Target", valid_600072
  var valid_600073 = query.getOrDefault("Action")
  valid_600073 = validateParameter(valid_600073, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_600073 != nil:
    section.add "Action", valid_600073
  var valid_600074 = query.getOrDefault("HealthCheck.Interval")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "HealthCheck.Interval", valid_600074
  var valid_600075 = query.getOrDefault("Version")
  valid_600075 = validateParameter(valid_600075, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600075 != nil:
    section.add "Version", valid_600075
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
  var valid_600076 = header.getOrDefault("X-Amz-Date")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Date", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Security-Token")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Security-Token", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Content-Sha256", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Algorithm")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Algorithm", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Signature")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Signature", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-SignedHeaders", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Credential")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Credential", valid_600082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600083: Call_GetConfigureHealthCheck_600065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600083.validator(path, query, header, formData, body)
  let scheme = call_600083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600083.url(scheme.get, call_600083.host, call_600083.base,
                         call_600083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600083, url, valid)

proc call*(call_600084: Call_GetConfigureHealthCheck_600065;
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
  var query_600085 = newJObject()
  add(query_600085, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(query_600085, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600085, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(query_600085, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_600085, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_600085, "Action", newJString(Action))
  add(query_600085, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(query_600085, "Version", newJString(Version))
  result = call_600084.call(nil, query_600085, nil, nil, nil)

var getConfigureHealthCheck* = Call_GetConfigureHealthCheck_600065(
    name: "getConfigureHealthCheck", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_GetConfigureHealthCheck_600066, base: "/",
    url: url_GetConfigureHealthCheck_600067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateAppCookieStickinessPolicy_600126 = ref object of OpenApiRestCall_599368
proc url_PostCreateAppCookieStickinessPolicy_600128(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateAppCookieStickinessPolicy_600127(path: JsonNode;
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
  var valid_600129 = query.getOrDefault("Action")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_600129 != nil:
    section.add "Action", valid_600129
  var valid_600130 = query.getOrDefault("Version")
  valid_600130 = validateParameter(valid_600130, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600130 != nil:
    section.add "Version", valid_600130
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
  var valid_600131 = header.getOrDefault("X-Amz-Date")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Date", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Security-Token")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Security-Token", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Content-Sha256", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Algorithm")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Algorithm", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Signature")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Signature", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-SignedHeaders", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Credential")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Credential", valid_600137
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
  var valid_600138 = formData.getOrDefault("PolicyName")
  valid_600138 = validateParameter(valid_600138, JString, required = true,
                                 default = nil)
  if valid_600138 != nil:
    section.add "PolicyName", valid_600138
  var valid_600139 = formData.getOrDefault("CookieName")
  valid_600139 = validateParameter(valid_600139, JString, required = true,
                                 default = nil)
  if valid_600139 != nil:
    section.add "CookieName", valid_600139
  var valid_600140 = formData.getOrDefault("LoadBalancerName")
  valid_600140 = validateParameter(valid_600140, JString, required = true,
                                 default = nil)
  if valid_600140 != nil:
    section.add "LoadBalancerName", valid_600140
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600141: Call_PostCreateAppCookieStickinessPolicy_600126;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600141.validator(path, query, header, formData, body)
  let scheme = call_600141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600141.url(scheme.get, call_600141.host, call_600141.base,
                         call_600141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600141, url, valid)

proc call*(call_600142: Call_PostCreateAppCookieStickinessPolicy_600126;
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
  var query_600143 = newJObject()
  var formData_600144 = newJObject()
  add(formData_600144, "PolicyName", newJString(PolicyName))
  add(formData_600144, "CookieName", newJString(CookieName))
  add(query_600143, "Action", newJString(Action))
  add(formData_600144, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600143, "Version", newJString(Version))
  result = call_600142.call(nil, query_600143, nil, formData_600144, nil)

var postCreateAppCookieStickinessPolicy* = Call_PostCreateAppCookieStickinessPolicy_600126(
    name: "postCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_PostCreateAppCookieStickinessPolicy_600127, base: "/",
    url: url_PostCreateAppCookieStickinessPolicy_600128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateAppCookieStickinessPolicy_600108 = ref object of OpenApiRestCall_599368
proc url_GetCreateAppCookieStickinessPolicy_600110(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateAppCookieStickinessPolicy_600109(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600111 = query.getOrDefault("LoadBalancerName")
  valid_600111 = validateParameter(valid_600111, JString, required = true,
                                 default = nil)
  if valid_600111 != nil:
    section.add "LoadBalancerName", valid_600111
  var valid_600112 = query.getOrDefault("Action")
  valid_600112 = validateParameter(valid_600112, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_600112 != nil:
    section.add "Action", valid_600112
  var valid_600113 = query.getOrDefault("CookieName")
  valid_600113 = validateParameter(valid_600113, JString, required = true,
                                 default = nil)
  if valid_600113 != nil:
    section.add "CookieName", valid_600113
  var valid_600114 = query.getOrDefault("Version")
  valid_600114 = validateParameter(valid_600114, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600114 != nil:
    section.add "Version", valid_600114
  var valid_600115 = query.getOrDefault("PolicyName")
  valid_600115 = validateParameter(valid_600115, JString, required = true,
                                 default = nil)
  if valid_600115 != nil:
    section.add "PolicyName", valid_600115
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
  var valid_600116 = header.getOrDefault("X-Amz-Date")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Date", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Security-Token")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Security-Token", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Content-Sha256", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Algorithm")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Algorithm", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Signature")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Signature", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-SignedHeaders", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Credential")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Credential", valid_600122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600123: Call_GetCreateAppCookieStickinessPolicy_600108;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600123.validator(path, query, header, formData, body)
  let scheme = call_600123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600123.url(scheme.get, call_600123.host, call_600123.base,
                         call_600123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600123, url, valid)

proc call*(call_600124: Call_GetCreateAppCookieStickinessPolicy_600108;
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
  var query_600125 = newJObject()
  add(query_600125, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600125, "Action", newJString(Action))
  add(query_600125, "CookieName", newJString(CookieName))
  add(query_600125, "Version", newJString(Version))
  add(query_600125, "PolicyName", newJString(PolicyName))
  result = call_600124.call(nil, query_600125, nil, nil, nil)

var getCreateAppCookieStickinessPolicy* = Call_GetCreateAppCookieStickinessPolicy_600108(
    name: "getCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_GetCreateAppCookieStickinessPolicy_600109, base: "/",
    url: url_GetCreateAppCookieStickinessPolicy_600110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLBCookieStickinessPolicy_600163 = ref object of OpenApiRestCall_599368
proc url_PostCreateLBCookieStickinessPolicy_600165(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLBCookieStickinessPolicy_600164(path: JsonNode;
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
  var valid_600166 = query.getOrDefault("Action")
  valid_600166 = validateParameter(valid_600166, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_600166 != nil:
    section.add "Action", valid_600166
  var valid_600167 = query.getOrDefault("Version")
  valid_600167 = validateParameter(valid_600167, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600167 != nil:
    section.add "Version", valid_600167
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
  var valid_600168 = header.getOrDefault("X-Amz-Date")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Date", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-Security-Token")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Security-Token", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Content-Sha256", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Algorithm")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Algorithm", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Signature")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Signature", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-SignedHeaders", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Credential")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Credential", valid_600174
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
  var valid_600175 = formData.getOrDefault("PolicyName")
  valid_600175 = validateParameter(valid_600175, JString, required = true,
                                 default = nil)
  if valid_600175 != nil:
    section.add "PolicyName", valid_600175
  var valid_600176 = formData.getOrDefault("LoadBalancerName")
  valid_600176 = validateParameter(valid_600176, JString, required = true,
                                 default = nil)
  if valid_600176 != nil:
    section.add "LoadBalancerName", valid_600176
  var valid_600177 = formData.getOrDefault("CookieExpirationPeriod")
  valid_600177 = validateParameter(valid_600177, JInt, required = false, default = nil)
  if valid_600177 != nil:
    section.add "CookieExpirationPeriod", valid_600177
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600178: Call_PostCreateLBCookieStickinessPolicy_600163;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600178.validator(path, query, header, formData, body)
  let scheme = call_600178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600178.url(scheme.get, call_600178.host, call_600178.base,
                         call_600178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600178, url, valid)

proc call*(call_600179: Call_PostCreateLBCookieStickinessPolicy_600163;
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
  var query_600180 = newJObject()
  var formData_600181 = newJObject()
  add(formData_600181, "PolicyName", newJString(PolicyName))
  add(query_600180, "Action", newJString(Action))
  add(formData_600181, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600180, "Version", newJString(Version))
  add(formData_600181, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  result = call_600179.call(nil, query_600180, nil, formData_600181, nil)

var postCreateLBCookieStickinessPolicy* = Call_PostCreateLBCookieStickinessPolicy_600163(
    name: "postCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_PostCreateLBCookieStickinessPolicy_600164, base: "/",
    url: url_PostCreateLBCookieStickinessPolicy_600165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLBCookieStickinessPolicy_600145 = ref object of OpenApiRestCall_599368
proc url_GetCreateLBCookieStickinessPolicy_600147(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLBCookieStickinessPolicy_600146(path: JsonNode;
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
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  section = newJObject()
  var valid_600148 = query.getOrDefault("CookieExpirationPeriod")
  valid_600148 = validateParameter(valid_600148, JInt, required = false, default = nil)
  if valid_600148 != nil:
    section.add "CookieExpirationPeriod", valid_600148
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_600149 = query.getOrDefault("LoadBalancerName")
  valid_600149 = validateParameter(valid_600149, JString, required = true,
                                 default = nil)
  if valid_600149 != nil:
    section.add "LoadBalancerName", valid_600149
  var valid_600150 = query.getOrDefault("Action")
  valid_600150 = validateParameter(valid_600150, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_600150 != nil:
    section.add "Action", valid_600150
  var valid_600151 = query.getOrDefault("Version")
  valid_600151 = validateParameter(valid_600151, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600151 != nil:
    section.add "Version", valid_600151
  var valid_600152 = query.getOrDefault("PolicyName")
  valid_600152 = validateParameter(valid_600152, JString, required = true,
                                 default = nil)
  if valid_600152 != nil:
    section.add "PolicyName", valid_600152
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
  var valid_600153 = header.getOrDefault("X-Amz-Date")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Date", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Security-Token")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Security-Token", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Content-Sha256", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Algorithm")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Algorithm", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Signature")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Signature", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-SignedHeaders", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Credential")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Credential", valid_600159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600160: Call_GetCreateLBCookieStickinessPolicy_600145;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600160.validator(path, query, header, formData, body)
  let scheme = call_600160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600160.url(scheme.get, call_600160.host, call_600160.base,
                         call_600160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600160, url, valid)

proc call*(call_600161: Call_GetCreateLBCookieStickinessPolicy_600145;
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
  var query_600162 = newJObject()
  add(query_600162, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(query_600162, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600162, "Action", newJString(Action))
  add(query_600162, "Version", newJString(Version))
  add(query_600162, "PolicyName", newJString(PolicyName))
  result = call_600161.call(nil, query_600162, nil, nil, nil)

var getCreateLBCookieStickinessPolicy* = Call_GetCreateLBCookieStickinessPolicy_600145(
    name: "getCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_GetCreateLBCookieStickinessPolicy_600146, base: "/",
    url: url_GetCreateLBCookieStickinessPolicy_600147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_600204 = ref object of OpenApiRestCall_599368
proc url_PostCreateLoadBalancer_600206(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLoadBalancer_600205(path: JsonNode; query: JsonNode;
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
  var valid_600207 = query.getOrDefault("Action")
  valid_600207 = validateParameter(valid_600207, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_600207 != nil:
    section.add "Action", valid_600207
  var valid_600208 = query.getOrDefault("Version")
  valid_600208 = validateParameter(valid_600208, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600208 != nil:
    section.add "Version", valid_600208
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
  var valid_600209 = header.getOrDefault("X-Amz-Date")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Date", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-Security-Token")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Security-Token", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Content-Sha256", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Algorithm")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Algorithm", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Signature")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Signature", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-SignedHeaders", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Credential")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Credential", valid_600215
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
  var valid_600216 = formData.getOrDefault("Tags")
  valid_600216 = validateParameter(valid_600216, JArray, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "Tags", valid_600216
  var valid_600217 = formData.getOrDefault("AvailabilityZones")
  valid_600217 = validateParameter(valid_600217, JArray, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "AvailabilityZones", valid_600217
  var valid_600218 = formData.getOrDefault("Subnets")
  valid_600218 = validateParameter(valid_600218, JArray, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "Subnets", valid_600218
  var valid_600219 = formData.getOrDefault("SecurityGroups")
  valid_600219 = validateParameter(valid_600219, JArray, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "SecurityGroups", valid_600219
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_600220 = formData.getOrDefault("LoadBalancerName")
  valid_600220 = validateParameter(valid_600220, JString, required = true,
                                 default = nil)
  if valid_600220 != nil:
    section.add "LoadBalancerName", valid_600220
  var valid_600221 = formData.getOrDefault("Scheme")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "Scheme", valid_600221
  var valid_600222 = formData.getOrDefault("Listeners")
  valid_600222 = validateParameter(valid_600222, JArray, required = true, default = nil)
  if valid_600222 != nil:
    section.add "Listeners", valid_600222
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600223: Call_PostCreateLoadBalancer_600204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600223.validator(path, query, header, formData, body)
  let scheme = call_600223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600223.url(scheme.get, call_600223.host, call_600223.base,
                         call_600223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600223, url, valid)

proc call*(call_600224: Call_PostCreateLoadBalancer_600204;
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
  var query_600225 = newJObject()
  var formData_600226 = newJObject()
  if Tags != nil:
    formData_600226.add "Tags", Tags
  add(query_600225, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_600226.add "AvailabilityZones", AvailabilityZones
  if Subnets != nil:
    formData_600226.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_600226.add "SecurityGroups", SecurityGroups
  add(formData_600226, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_600226, "Scheme", newJString(Scheme))
  if Listeners != nil:
    formData_600226.add "Listeners", Listeners
  add(query_600225, "Version", newJString(Version))
  result = call_600224.call(nil, query_600225, nil, formData_600226, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_600204(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_600205, base: "/",
    url: url_PostCreateLoadBalancer_600206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_600182 = ref object of OpenApiRestCall_599368
proc url_GetCreateLoadBalancer_600184(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLoadBalancer_600183(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600185 = query.getOrDefault("LoadBalancerName")
  valid_600185 = validateParameter(valid_600185, JString, required = true,
                                 default = nil)
  if valid_600185 != nil:
    section.add "LoadBalancerName", valid_600185
  var valid_600186 = query.getOrDefault("AvailabilityZones")
  valid_600186 = validateParameter(valid_600186, JArray, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "AvailabilityZones", valid_600186
  var valid_600187 = query.getOrDefault("Scheme")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "Scheme", valid_600187
  var valid_600188 = query.getOrDefault("Tags")
  valid_600188 = validateParameter(valid_600188, JArray, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "Tags", valid_600188
  var valid_600189 = query.getOrDefault("Action")
  valid_600189 = validateParameter(valid_600189, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_600189 != nil:
    section.add "Action", valid_600189
  var valid_600190 = query.getOrDefault("Subnets")
  valid_600190 = validateParameter(valid_600190, JArray, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "Subnets", valid_600190
  var valid_600191 = query.getOrDefault("Version")
  valid_600191 = validateParameter(valid_600191, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600191 != nil:
    section.add "Version", valid_600191
  var valid_600192 = query.getOrDefault("Listeners")
  valid_600192 = validateParameter(valid_600192, JArray, required = true, default = nil)
  if valid_600192 != nil:
    section.add "Listeners", valid_600192
  var valid_600193 = query.getOrDefault("SecurityGroups")
  valid_600193 = validateParameter(valid_600193, JArray, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "SecurityGroups", valid_600193
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
  var valid_600194 = header.getOrDefault("X-Amz-Date")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Date", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Security-Token")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Security-Token", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Content-Sha256", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-Algorithm")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Algorithm", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-Signature")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Signature", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-SignedHeaders", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Credential")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Credential", valid_600200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600201: Call_GetCreateLoadBalancer_600182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600201.validator(path, query, header, formData, body)
  let scheme = call_600201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600201.url(scheme.get, call_600201.host, call_600201.base,
                         call_600201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600201, url, valid)

proc call*(call_600202: Call_GetCreateLoadBalancer_600182;
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
  var query_600203 = newJObject()
  add(query_600203, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_600203.add "AvailabilityZones", AvailabilityZones
  add(query_600203, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_600203.add "Tags", Tags
  add(query_600203, "Action", newJString(Action))
  if Subnets != nil:
    query_600203.add "Subnets", Subnets
  add(query_600203, "Version", newJString(Version))
  if Listeners != nil:
    query_600203.add "Listeners", Listeners
  if SecurityGroups != nil:
    query_600203.add "SecurityGroups", SecurityGroups
  result = call_600202.call(nil, query_600203, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_600182(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_600183, base: "/",
    url: url_GetCreateLoadBalancer_600184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerListeners_600244 = ref object of OpenApiRestCall_599368
proc url_PostCreateLoadBalancerListeners_600246(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLoadBalancerListeners_600245(path: JsonNode;
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
  var valid_600247 = query.getOrDefault("Action")
  valid_600247 = validateParameter(valid_600247, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_600247 != nil:
    section.add "Action", valid_600247
  var valid_600248 = query.getOrDefault("Version")
  valid_600248 = validateParameter(valid_600248, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600248 != nil:
    section.add "Version", valid_600248
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
  var valid_600249 = header.getOrDefault("X-Amz-Date")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Date", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Security-Token")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Security-Token", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Content-Sha256", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Algorithm")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Algorithm", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-Signature")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Signature", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-SignedHeaders", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-Credential")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Credential", valid_600255
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_600256 = formData.getOrDefault("LoadBalancerName")
  valid_600256 = validateParameter(valid_600256, JString, required = true,
                                 default = nil)
  if valid_600256 != nil:
    section.add "LoadBalancerName", valid_600256
  var valid_600257 = formData.getOrDefault("Listeners")
  valid_600257 = validateParameter(valid_600257, JArray, required = true, default = nil)
  if valid_600257 != nil:
    section.add "Listeners", valid_600257
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600258: Call_PostCreateLoadBalancerListeners_600244;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600258.validator(path, query, header, formData, body)
  let scheme = call_600258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600258.url(scheme.get, call_600258.host, call_600258.base,
                         call_600258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600258, url, valid)

proc call*(call_600259: Call_PostCreateLoadBalancerListeners_600244;
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
  var query_600260 = newJObject()
  var formData_600261 = newJObject()
  add(query_600260, "Action", newJString(Action))
  add(formData_600261, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_600261.add "Listeners", Listeners
  add(query_600260, "Version", newJString(Version))
  result = call_600259.call(nil, query_600260, nil, formData_600261, nil)

var postCreateLoadBalancerListeners* = Call_PostCreateLoadBalancerListeners_600244(
    name: "postCreateLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_PostCreateLoadBalancerListeners_600245, base: "/",
    url: url_PostCreateLoadBalancerListeners_600246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerListeners_600227 = ref object of OpenApiRestCall_599368
proc url_GetCreateLoadBalancerListeners_600229(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLoadBalancerListeners_600228(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600230 = query.getOrDefault("LoadBalancerName")
  valid_600230 = validateParameter(valid_600230, JString, required = true,
                                 default = nil)
  if valid_600230 != nil:
    section.add "LoadBalancerName", valid_600230
  var valid_600231 = query.getOrDefault("Action")
  valid_600231 = validateParameter(valid_600231, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_600231 != nil:
    section.add "Action", valid_600231
  var valid_600232 = query.getOrDefault("Version")
  valid_600232 = validateParameter(valid_600232, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600232 != nil:
    section.add "Version", valid_600232
  var valid_600233 = query.getOrDefault("Listeners")
  valid_600233 = validateParameter(valid_600233, JArray, required = true, default = nil)
  if valid_600233 != nil:
    section.add "Listeners", valid_600233
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
  var valid_600234 = header.getOrDefault("X-Amz-Date")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Date", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Security-Token")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Security-Token", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Content-Sha256", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Algorithm")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Algorithm", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-Signature")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Signature", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-SignedHeaders", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Credential")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Credential", valid_600240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600241: Call_GetCreateLoadBalancerListeners_600227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600241.validator(path, query, header, formData, body)
  let scheme = call_600241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600241.url(scheme.get, call_600241.host, call_600241.base,
                         call_600241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600241, url, valid)

proc call*(call_600242: Call_GetCreateLoadBalancerListeners_600227;
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
  var query_600243 = newJObject()
  add(query_600243, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600243, "Action", newJString(Action))
  add(query_600243, "Version", newJString(Version))
  if Listeners != nil:
    query_600243.add "Listeners", Listeners
  result = call_600242.call(nil, query_600243, nil, nil, nil)

var getCreateLoadBalancerListeners* = Call_GetCreateLoadBalancerListeners_600227(
    name: "getCreateLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_GetCreateLoadBalancerListeners_600228, base: "/",
    url: url_GetCreateLoadBalancerListeners_600229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerPolicy_600281 = ref object of OpenApiRestCall_599368
proc url_PostCreateLoadBalancerPolicy_600283(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLoadBalancerPolicy_600282(path: JsonNode; query: JsonNode;
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
  var valid_600284 = query.getOrDefault("Action")
  valid_600284 = validateParameter(valid_600284, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_600284 != nil:
    section.add "Action", valid_600284
  var valid_600285 = query.getOrDefault("Version")
  valid_600285 = validateParameter(valid_600285, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600285 != nil:
    section.add "Version", valid_600285
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
  var valid_600286 = header.getOrDefault("X-Amz-Date")
  valid_600286 = validateParameter(valid_600286, JString, required = false,
                                 default = nil)
  if valid_600286 != nil:
    section.add "X-Amz-Date", valid_600286
  var valid_600287 = header.getOrDefault("X-Amz-Security-Token")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "X-Amz-Security-Token", valid_600287
  var valid_600288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Content-Sha256", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-Algorithm")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Algorithm", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Signature")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Signature", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-SignedHeaders", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Credential")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Credential", valid_600292
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
  var valid_600293 = formData.getOrDefault("PolicyName")
  valid_600293 = validateParameter(valid_600293, JString, required = true,
                                 default = nil)
  if valid_600293 != nil:
    section.add "PolicyName", valid_600293
  var valid_600294 = formData.getOrDefault("PolicyTypeName")
  valid_600294 = validateParameter(valid_600294, JString, required = true,
                                 default = nil)
  if valid_600294 != nil:
    section.add "PolicyTypeName", valid_600294
  var valid_600295 = formData.getOrDefault("PolicyAttributes")
  valid_600295 = validateParameter(valid_600295, JArray, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "PolicyAttributes", valid_600295
  var valid_600296 = formData.getOrDefault("LoadBalancerName")
  valid_600296 = validateParameter(valid_600296, JString, required = true,
                                 default = nil)
  if valid_600296 != nil:
    section.add "LoadBalancerName", valid_600296
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600297: Call_PostCreateLoadBalancerPolicy_600281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_600297.validator(path, query, header, formData, body)
  let scheme = call_600297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600297.url(scheme.get, call_600297.host, call_600297.base,
                         call_600297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600297, url, valid)

proc call*(call_600298: Call_PostCreateLoadBalancerPolicy_600281;
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
  var query_600299 = newJObject()
  var formData_600300 = newJObject()
  add(formData_600300, "PolicyName", newJString(PolicyName))
  add(formData_600300, "PolicyTypeName", newJString(PolicyTypeName))
  if PolicyAttributes != nil:
    formData_600300.add "PolicyAttributes", PolicyAttributes
  add(query_600299, "Action", newJString(Action))
  add(formData_600300, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600299, "Version", newJString(Version))
  result = call_600298.call(nil, query_600299, nil, formData_600300, nil)

var postCreateLoadBalancerPolicy* = Call_PostCreateLoadBalancerPolicy_600281(
    name: "postCreateLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_PostCreateLoadBalancerPolicy_600282, base: "/",
    url: url_PostCreateLoadBalancerPolicy_600283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerPolicy_600262 = ref object of OpenApiRestCall_599368
proc url_GetCreateLoadBalancerPolicy_600264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLoadBalancerPolicy_600263(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600265 = query.getOrDefault("LoadBalancerName")
  valid_600265 = validateParameter(valid_600265, JString, required = true,
                                 default = nil)
  if valid_600265 != nil:
    section.add "LoadBalancerName", valid_600265
  var valid_600266 = query.getOrDefault("PolicyAttributes")
  valid_600266 = validateParameter(valid_600266, JArray, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "PolicyAttributes", valid_600266
  var valid_600267 = query.getOrDefault("Action")
  valid_600267 = validateParameter(valid_600267, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_600267 != nil:
    section.add "Action", valid_600267
  var valid_600268 = query.getOrDefault("PolicyTypeName")
  valid_600268 = validateParameter(valid_600268, JString, required = true,
                                 default = nil)
  if valid_600268 != nil:
    section.add "PolicyTypeName", valid_600268
  var valid_600269 = query.getOrDefault("Version")
  valid_600269 = validateParameter(valid_600269, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600269 != nil:
    section.add "Version", valid_600269
  var valid_600270 = query.getOrDefault("PolicyName")
  valid_600270 = validateParameter(valid_600270, JString, required = true,
                                 default = nil)
  if valid_600270 != nil:
    section.add "PolicyName", valid_600270
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
  var valid_600271 = header.getOrDefault("X-Amz-Date")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "X-Amz-Date", valid_600271
  var valid_600272 = header.getOrDefault("X-Amz-Security-Token")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-Security-Token", valid_600272
  var valid_600273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Content-Sha256", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Algorithm")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Algorithm", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Signature")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Signature", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-SignedHeaders", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-Credential")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Credential", valid_600277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600278: Call_GetCreateLoadBalancerPolicy_600262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_600278.validator(path, query, header, formData, body)
  let scheme = call_600278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600278.url(scheme.get, call_600278.host, call_600278.base,
                         call_600278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600278, url, valid)

proc call*(call_600279: Call_GetCreateLoadBalancerPolicy_600262;
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
  var query_600280 = newJObject()
  add(query_600280, "LoadBalancerName", newJString(LoadBalancerName))
  if PolicyAttributes != nil:
    query_600280.add "PolicyAttributes", PolicyAttributes
  add(query_600280, "Action", newJString(Action))
  add(query_600280, "PolicyTypeName", newJString(PolicyTypeName))
  add(query_600280, "Version", newJString(Version))
  add(query_600280, "PolicyName", newJString(PolicyName))
  result = call_600279.call(nil, query_600280, nil, nil, nil)

var getCreateLoadBalancerPolicy* = Call_GetCreateLoadBalancerPolicy_600262(
    name: "getCreateLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_GetCreateLoadBalancerPolicy_600263, base: "/",
    url: url_GetCreateLoadBalancerPolicy_600264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_600317 = ref object of OpenApiRestCall_599368
proc url_PostDeleteLoadBalancer_600319(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteLoadBalancer_600318(path: JsonNode; query: JsonNode;
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
  var valid_600320 = query.getOrDefault("Action")
  valid_600320 = validateParameter(valid_600320, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_600320 != nil:
    section.add "Action", valid_600320
  var valid_600321 = query.getOrDefault("Version")
  valid_600321 = validateParameter(valid_600321, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600321 != nil:
    section.add "Version", valid_600321
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
  var valid_600322 = header.getOrDefault("X-Amz-Date")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Date", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Security-Token")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Security-Token", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Content-Sha256", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Algorithm")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Algorithm", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Signature")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Signature", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-SignedHeaders", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Credential")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Credential", valid_600328
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_600329 = formData.getOrDefault("LoadBalancerName")
  valid_600329 = validateParameter(valid_600329, JString, required = true,
                                 default = nil)
  if valid_600329 != nil:
    section.add "LoadBalancerName", valid_600329
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600330: Call_PostDeleteLoadBalancer_600317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_600330.validator(path, query, header, formData, body)
  let scheme = call_600330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600330.url(scheme.get, call_600330.host, call_600330.base,
                         call_600330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600330, url, valid)

proc call*(call_600331: Call_PostDeleteLoadBalancer_600317;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_600332 = newJObject()
  var formData_600333 = newJObject()
  add(query_600332, "Action", newJString(Action))
  add(formData_600333, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600332, "Version", newJString(Version))
  result = call_600331.call(nil, query_600332, nil, formData_600333, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_600317(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_600318, base: "/",
    url: url_PostDeleteLoadBalancer_600319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_600301 = ref object of OpenApiRestCall_599368
proc url_GetDeleteLoadBalancer_600303(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteLoadBalancer_600302(path: JsonNode; query: JsonNode;
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
  var valid_600304 = query.getOrDefault("LoadBalancerName")
  valid_600304 = validateParameter(valid_600304, JString, required = true,
                                 default = nil)
  if valid_600304 != nil:
    section.add "LoadBalancerName", valid_600304
  var valid_600305 = query.getOrDefault("Action")
  valid_600305 = validateParameter(valid_600305, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_600305 != nil:
    section.add "Action", valid_600305
  var valid_600306 = query.getOrDefault("Version")
  valid_600306 = validateParameter(valid_600306, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600306 != nil:
    section.add "Version", valid_600306
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
  var valid_600307 = header.getOrDefault("X-Amz-Date")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Date", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Security-Token")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Security-Token", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Content-Sha256", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Algorithm")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Algorithm", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Signature")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Signature", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-SignedHeaders", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Credential")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Credential", valid_600313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600314: Call_GetDeleteLoadBalancer_600301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_600314.validator(path, query, header, formData, body)
  let scheme = call_600314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600314.url(scheme.get, call_600314.host, call_600314.base,
                         call_600314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600314, url, valid)

proc call*(call_600315: Call_GetDeleteLoadBalancer_600301;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600316 = newJObject()
  add(query_600316, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600316, "Action", newJString(Action))
  add(query_600316, "Version", newJString(Version))
  result = call_600315.call(nil, query_600316, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_600301(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_600302, base: "/",
    url: url_GetDeleteLoadBalancer_600303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerListeners_600351 = ref object of OpenApiRestCall_599368
proc url_PostDeleteLoadBalancerListeners_600353(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteLoadBalancerListeners_600352(path: JsonNode;
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
  var valid_600354 = query.getOrDefault("Action")
  valid_600354 = validateParameter(valid_600354, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_600354 != nil:
    section.add "Action", valid_600354
  var valid_600355 = query.getOrDefault("Version")
  valid_600355 = validateParameter(valid_600355, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600355 != nil:
    section.add "Version", valid_600355
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
  var valid_600356 = header.getOrDefault("X-Amz-Date")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Date", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Security-Token")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Security-Token", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Content-Sha256", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Algorithm")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Algorithm", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Signature")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Signature", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-SignedHeaders", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-Credential")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-Credential", valid_600362
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_600363 = formData.getOrDefault("LoadBalancerName")
  valid_600363 = validateParameter(valid_600363, JString, required = true,
                                 default = nil)
  if valid_600363 != nil:
    section.add "LoadBalancerName", valid_600363
  var valid_600364 = formData.getOrDefault("LoadBalancerPorts")
  valid_600364 = validateParameter(valid_600364, JArray, required = true, default = nil)
  if valid_600364 != nil:
    section.add "LoadBalancerPorts", valid_600364
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600365: Call_PostDeleteLoadBalancerListeners_600351;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_600365.validator(path, query, header, formData, body)
  let scheme = call_600365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600365.url(scheme.get, call_600365.host, call_600365.base,
                         call_600365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600365, url, valid)

proc call*(call_600366: Call_PostDeleteLoadBalancerListeners_600351;
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
  var query_600367 = newJObject()
  var formData_600368 = newJObject()
  add(query_600367, "Action", newJString(Action))
  add(formData_600368, "LoadBalancerName", newJString(LoadBalancerName))
  if LoadBalancerPorts != nil:
    formData_600368.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_600367, "Version", newJString(Version))
  result = call_600366.call(nil, query_600367, nil, formData_600368, nil)

var postDeleteLoadBalancerListeners* = Call_PostDeleteLoadBalancerListeners_600351(
    name: "postDeleteLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_PostDeleteLoadBalancerListeners_600352, base: "/",
    url: url_PostDeleteLoadBalancerListeners_600353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerListeners_600334 = ref object of OpenApiRestCall_599368
proc url_GetDeleteLoadBalancerListeners_600336(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteLoadBalancerListeners_600335(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600337 = query.getOrDefault("LoadBalancerName")
  valid_600337 = validateParameter(valid_600337, JString, required = true,
                                 default = nil)
  if valid_600337 != nil:
    section.add "LoadBalancerName", valid_600337
  var valid_600338 = query.getOrDefault("Action")
  valid_600338 = validateParameter(valid_600338, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_600338 != nil:
    section.add "Action", valid_600338
  var valid_600339 = query.getOrDefault("LoadBalancerPorts")
  valid_600339 = validateParameter(valid_600339, JArray, required = true, default = nil)
  if valid_600339 != nil:
    section.add "LoadBalancerPorts", valid_600339
  var valid_600340 = query.getOrDefault("Version")
  valid_600340 = validateParameter(valid_600340, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600340 != nil:
    section.add "Version", valid_600340
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
  var valid_600341 = header.getOrDefault("X-Amz-Date")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Date", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Security-Token")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Security-Token", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Content-Sha256", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Algorithm")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Algorithm", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Signature")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Signature", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-SignedHeaders", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-Credential")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Credential", valid_600347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600348: Call_GetDeleteLoadBalancerListeners_600334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_600348.validator(path, query, header, formData, body)
  let scheme = call_600348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600348.url(scheme.get, call_600348.host, call_600348.base,
                         call_600348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600348, url, valid)

proc call*(call_600349: Call_GetDeleteLoadBalancerListeners_600334;
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
  var query_600350 = newJObject()
  add(query_600350, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600350, "Action", newJString(Action))
  if LoadBalancerPorts != nil:
    query_600350.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_600350, "Version", newJString(Version))
  result = call_600349.call(nil, query_600350, nil, nil, nil)

var getDeleteLoadBalancerListeners* = Call_GetDeleteLoadBalancerListeners_600334(
    name: "getDeleteLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_GetDeleteLoadBalancerListeners_600335, base: "/",
    url: url_GetDeleteLoadBalancerListeners_600336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerPolicy_600386 = ref object of OpenApiRestCall_599368
proc url_PostDeleteLoadBalancerPolicy_600388(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteLoadBalancerPolicy_600387(path: JsonNode; query: JsonNode;
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
  var valid_600389 = query.getOrDefault("Action")
  valid_600389 = validateParameter(valid_600389, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_600389 != nil:
    section.add "Action", valid_600389
  var valid_600390 = query.getOrDefault("Version")
  valid_600390 = validateParameter(valid_600390, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600390 != nil:
    section.add "Version", valid_600390
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
  var valid_600391 = header.getOrDefault("X-Amz-Date")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Date", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-Security-Token")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Security-Token", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-Content-Sha256", valid_600393
  var valid_600394 = header.getOrDefault("X-Amz-Algorithm")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-Algorithm", valid_600394
  var valid_600395 = header.getOrDefault("X-Amz-Signature")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-Signature", valid_600395
  var valid_600396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-SignedHeaders", valid_600396
  var valid_600397 = header.getOrDefault("X-Amz-Credential")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Credential", valid_600397
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PolicyName` field"
  var valid_600398 = formData.getOrDefault("PolicyName")
  valid_600398 = validateParameter(valid_600398, JString, required = true,
                                 default = nil)
  if valid_600398 != nil:
    section.add "PolicyName", valid_600398
  var valid_600399 = formData.getOrDefault("LoadBalancerName")
  valid_600399 = validateParameter(valid_600399, JString, required = true,
                                 default = nil)
  if valid_600399 != nil:
    section.add "LoadBalancerName", valid_600399
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600400: Call_PostDeleteLoadBalancerPolicy_600386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_600400.validator(path, query, header, formData, body)
  let scheme = call_600400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600400.url(scheme.get, call_600400.host, call_600400.base,
                         call_600400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600400, url, valid)

proc call*(call_600401: Call_PostDeleteLoadBalancerPolicy_600386;
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
  var query_600402 = newJObject()
  var formData_600403 = newJObject()
  add(formData_600403, "PolicyName", newJString(PolicyName))
  add(query_600402, "Action", newJString(Action))
  add(formData_600403, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600402, "Version", newJString(Version))
  result = call_600401.call(nil, query_600402, nil, formData_600403, nil)

var postDeleteLoadBalancerPolicy* = Call_PostDeleteLoadBalancerPolicy_600386(
    name: "postDeleteLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_PostDeleteLoadBalancerPolicy_600387, base: "/",
    url: url_PostDeleteLoadBalancerPolicy_600388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerPolicy_600369 = ref object of OpenApiRestCall_599368
proc url_GetDeleteLoadBalancerPolicy_600371(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteLoadBalancerPolicy_600370(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600372 = query.getOrDefault("LoadBalancerName")
  valid_600372 = validateParameter(valid_600372, JString, required = true,
                                 default = nil)
  if valid_600372 != nil:
    section.add "LoadBalancerName", valid_600372
  var valid_600373 = query.getOrDefault("Action")
  valid_600373 = validateParameter(valid_600373, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_600373 != nil:
    section.add "Action", valid_600373
  var valid_600374 = query.getOrDefault("Version")
  valid_600374 = validateParameter(valid_600374, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600374 != nil:
    section.add "Version", valid_600374
  var valid_600375 = query.getOrDefault("PolicyName")
  valid_600375 = validateParameter(valid_600375, JString, required = true,
                                 default = nil)
  if valid_600375 != nil:
    section.add "PolicyName", valid_600375
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
  var valid_600376 = header.getOrDefault("X-Amz-Date")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Date", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-Security-Token")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-Security-Token", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-Content-Sha256", valid_600378
  var valid_600379 = header.getOrDefault("X-Amz-Algorithm")
  valid_600379 = validateParameter(valid_600379, JString, required = false,
                                 default = nil)
  if valid_600379 != nil:
    section.add "X-Amz-Algorithm", valid_600379
  var valid_600380 = header.getOrDefault("X-Amz-Signature")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "X-Amz-Signature", valid_600380
  var valid_600381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "X-Amz-SignedHeaders", valid_600381
  var valid_600382 = header.getOrDefault("X-Amz-Credential")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Credential", valid_600382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600383: Call_GetDeleteLoadBalancerPolicy_600369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_600383.validator(path, query, header, formData, body)
  let scheme = call_600383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600383.url(scheme.get, call_600383.host, call_600383.base,
                         call_600383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600383, url, valid)

proc call*(call_600384: Call_GetDeleteLoadBalancerPolicy_600369;
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
  var query_600385 = newJObject()
  add(query_600385, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600385, "Action", newJString(Action))
  add(query_600385, "Version", newJString(Version))
  add(query_600385, "PolicyName", newJString(PolicyName))
  result = call_600384.call(nil, query_600385, nil, nil, nil)

var getDeleteLoadBalancerPolicy* = Call_GetDeleteLoadBalancerPolicy_600369(
    name: "getDeleteLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_GetDeleteLoadBalancerPolicy_600370, base: "/",
    url: url_GetDeleteLoadBalancerPolicy_600371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterInstancesFromLoadBalancer_600421 = ref object of OpenApiRestCall_599368
proc url_PostDeregisterInstancesFromLoadBalancer_600423(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeregisterInstancesFromLoadBalancer_600422(path: JsonNode;
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
  var valid_600424 = query.getOrDefault("Action")
  valid_600424 = validateParameter(valid_600424, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_600424 != nil:
    section.add "Action", valid_600424
  var valid_600425 = query.getOrDefault("Version")
  valid_600425 = validateParameter(valid_600425, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600425 != nil:
    section.add "Version", valid_600425
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
  var valid_600426 = header.getOrDefault("X-Amz-Date")
  valid_600426 = validateParameter(valid_600426, JString, required = false,
                                 default = nil)
  if valid_600426 != nil:
    section.add "X-Amz-Date", valid_600426
  var valid_600427 = header.getOrDefault("X-Amz-Security-Token")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "X-Amz-Security-Token", valid_600427
  var valid_600428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Content-Sha256", valid_600428
  var valid_600429 = header.getOrDefault("X-Amz-Algorithm")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Algorithm", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Signature")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Signature", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-SignedHeaders", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Credential")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Credential", valid_600432
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_600433 = formData.getOrDefault("Instances")
  valid_600433 = validateParameter(valid_600433, JArray, required = true, default = nil)
  if valid_600433 != nil:
    section.add "Instances", valid_600433
  var valid_600434 = formData.getOrDefault("LoadBalancerName")
  valid_600434 = validateParameter(valid_600434, JString, required = true,
                                 default = nil)
  if valid_600434 != nil:
    section.add "LoadBalancerName", valid_600434
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600435: Call_PostDeregisterInstancesFromLoadBalancer_600421;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600435.validator(path, query, header, formData, body)
  let scheme = call_600435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600435.url(scheme.get, call_600435.host, call_600435.base,
                         call_600435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600435, url, valid)

proc call*(call_600436: Call_PostDeregisterInstancesFromLoadBalancer_600421;
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
  var query_600437 = newJObject()
  var formData_600438 = newJObject()
  if Instances != nil:
    formData_600438.add "Instances", Instances
  add(query_600437, "Action", newJString(Action))
  add(formData_600438, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600437, "Version", newJString(Version))
  result = call_600436.call(nil, query_600437, nil, formData_600438, nil)

var postDeregisterInstancesFromLoadBalancer* = Call_PostDeregisterInstancesFromLoadBalancer_600421(
    name: "postDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_PostDeregisterInstancesFromLoadBalancer_600422, base: "/",
    url: url_PostDeregisterInstancesFromLoadBalancer_600423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterInstancesFromLoadBalancer_600404 = ref object of OpenApiRestCall_599368
proc url_GetDeregisterInstancesFromLoadBalancer_600406(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeregisterInstancesFromLoadBalancer_600405(path: JsonNode;
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
  var valid_600407 = query.getOrDefault("LoadBalancerName")
  valid_600407 = validateParameter(valid_600407, JString, required = true,
                                 default = nil)
  if valid_600407 != nil:
    section.add "LoadBalancerName", valid_600407
  var valid_600408 = query.getOrDefault("Action")
  valid_600408 = validateParameter(valid_600408, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_600408 != nil:
    section.add "Action", valid_600408
  var valid_600409 = query.getOrDefault("Instances")
  valid_600409 = validateParameter(valid_600409, JArray, required = true, default = nil)
  if valid_600409 != nil:
    section.add "Instances", valid_600409
  var valid_600410 = query.getOrDefault("Version")
  valid_600410 = validateParameter(valid_600410, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600410 != nil:
    section.add "Version", valid_600410
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
  var valid_600411 = header.getOrDefault("X-Amz-Date")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "X-Amz-Date", valid_600411
  var valid_600412 = header.getOrDefault("X-Amz-Security-Token")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Security-Token", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Content-Sha256", valid_600413
  var valid_600414 = header.getOrDefault("X-Amz-Algorithm")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "X-Amz-Algorithm", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-Signature")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Signature", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-SignedHeaders", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Credential")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Credential", valid_600417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600418: Call_GetDeregisterInstancesFromLoadBalancer_600404;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600418.validator(path, query, header, formData, body)
  let scheme = call_600418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600418.url(scheme.get, call_600418.host, call_600418.base,
                         call_600418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600418, url, valid)

proc call*(call_600419: Call_GetDeregisterInstancesFromLoadBalancer_600404;
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
  var query_600420 = newJObject()
  add(query_600420, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600420, "Action", newJString(Action))
  if Instances != nil:
    query_600420.add "Instances", Instances
  add(query_600420, "Version", newJString(Version))
  result = call_600419.call(nil, query_600420, nil, nil, nil)

var getDeregisterInstancesFromLoadBalancer* = Call_GetDeregisterInstancesFromLoadBalancer_600404(
    name: "getDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_GetDeregisterInstancesFromLoadBalancer_600405, base: "/",
    url: url_GetDeregisterInstancesFromLoadBalancer_600406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_600456 = ref object of OpenApiRestCall_599368
proc url_PostDescribeAccountLimits_600458(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAccountLimits_600457(path: JsonNode; query: JsonNode;
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
  var valid_600459 = query.getOrDefault("Action")
  valid_600459 = validateParameter(valid_600459, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_600459 != nil:
    section.add "Action", valid_600459
  var valid_600460 = query.getOrDefault("Version")
  valid_600460 = validateParameter(valid_600460, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600460 != nil:
    section.add "Version", valid_600460
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
  var valid_600461 = header.getOrDefault("X-Amz-Date")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Date", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Security-Token")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Security-Token", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-Content-Sha256", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-Algorithm")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Algorithm", valid_600464
  var valid_600465 = header.getOrDefault("X-Amz-Signature")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-Signature", valid_600465
  var valid_600466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-SignedHeaders", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-Credential")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-Credential", valid_600467
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_600468 = formData.getOrDefault("Marker")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "Marker", valid_600468
  var valid_600469 = formData.getOrDefault("PageSize")
  valid_600469 = validateParameter(valid_600469, JInt, required = false, default = nil)
  if valid_600469 != nil:
    section.add "PageSize", valid_600469
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600470: Call_PostDescribeAccountLimits_600456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600470.validator(path, query, header, formData, body)
  let scheme = call_600470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600470.url(scheme.get, call_600470.host, call_600470.base,
                         call_600470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600470, url, valid)

proc call*(call_600471: Call_PostDescribeAccountLimits_600456; Marker: string = "";
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
  var query_600472 = newJObject()
  var formData_600473 = newJObject()
  add(formData_600473, "Marker", newJString(Marker))
  add(query_600472, "Action", newJString(Action))
  add(formData_600473, "PageSize", newJInt(PageSize))
  add(query_600472, "Version", newJString(Version))
  result = call_600471.call(nil, query_600472, nil, formData_600473, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_600456(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_600457, base: "/",
    url: url_PostDescribeAccountLimits_600458,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_600439 = ref object of OpenApiRestCall_599368
proc url_GetDescribeAccountLimits_600441(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAccountLimits_600440(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600442 = query.getOrDefault("PageSize")
  valid_600442 = validateParameter(valid_600442, JInt, required = false, default = nil)
  if valid_600442 != nil:
    section.add "PageSize", valid_600442
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600443 = query.getOrDefault("Action")
  valid_600443 = validateParameter(valid_600443, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_600443 != nil:
    section.add "Action", valid_600443
  var valid_600444 = query.getOrDefault("Marker")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "Marker", valid_600444
  var valid_600445 = query.getOrDefault("Version")
  valid_600445 = validateParameter(valid_600445, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600445 != nil:
    section.add "Version", valid_600445
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
  var valid_600446 = header.getOrDefault("X-Amz-Date")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Date", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Security-Token")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Security-Token", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-Content-Sha256", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Algorithm")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Algorithm", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Signature")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Signature", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-SignedHeaders", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Credential")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Credential", valid_600452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600453: Call_GetDescribeAccountLimits_600439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600453.validator(path, query, header, formData, body)
  let scheme = call_600453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600453.url(scheme.get, call_600453.host, call_600453.base,
                         call_600453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600453, url, valid)

proc call*(call_600454: Call_GetDescribeAccountLimits_600439; PageSize: int = 0;
          Action: string = "DescribeAccountLimits"; Marker: string = "";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeAccountLimits
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   PageSize: int
  ##           : The maximum number of results to return with this call.
  ##   Action: string (required)
  ##   Marker: string
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   Version: string (required)
  var query_600455 = newJObject()
  add(query_600455, "PageSize", newJInt(PageSize))
  add(query_600455, "Action", newJString(Action))
  add(query_600455, "Marker", newJString(Marker))
  add(query_600455, "Version", newJString(Version))
  result = call_600454.call(nil, query_600455, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_600439(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_600440, base: "/",
    url: url_GetDescribeAccountLimits_600441, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstanceHealth_600491 = ref object of OpenApiRestCall_599368
proc url_PostDescribeInstanceHealth_600493(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeInstanceHealth_600492(path: JsonNode; query: JsonNode;
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
  var valid_600494 = query.getOrDefault("Action")
  valid_600494 = validateParameter(valid_600494, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_600494 != nil:
    section.add "Action", valid_600494
  var valid_600495 = query.getOrDefault("Version")
  valid_600495 = validateParameter(valid_600495, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600495 != nil:
    section.add "Version", valid_600495
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
  var valid_600496 = header.getOrDefault("X-Amz-Date")
  valid_600496 = validateParameter(valid_600496, JString, required = false,
                                 default = nil)
  if valid_600496 != nil:
    section.add "X-Amz-Date", valid_600496
  var valid_600497 = header.getOrDefault("X-Amz-Security-Token")
  valid_600497 = validateParameter(valid_600497, JString, required = false,
                                 default = nil)
  if valid_600497 != nil:
    section.add "X-Amz-Security-Token", valid_600497
  var valid_600498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600498 = validateParameter(valid_600498, JString, required = false,
                                 default = nil)
  if valid_600498 != nil:
    section.add "X-Amz-Content-Sha256", valid_600498
  var valid_600499 = header.getOrDefault("X-Amz-Algorithm")
  valid_600499 = validateParameter(valid_600499, JString, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "X-Amz-Algorithm", valid_600499
  var valid_600500 = header.getOrDefault("X-Amz-Signature")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "X-Amz-Signature", valid_600500
  var valid_600501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-SignedHeaders", valid_600501
  var valid_600502 = header.getOrDefault("X-Amz-Credential")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Credential", valid_600502
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_600503 = formData.getOrDefault("Instances")
  valid_600503 = validateParameter(valid_600503, JArray, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "Instances", valid_600503
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_600504 = formData.getOrDefault("LoadBalancerName")
  valid_600504 = validateParameter(valid_600504, JString, required = true,
                                 default = nil)
  if valid_600504 != nil:
    section.add "LoadBalancerName", valid_600504
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600505: Call_PostDescribeInstanceHealth_600491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_600505.validator(path, query, header, formData, body)
  let scheme = call_600505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600505.url(scheme.get, call_600505.host, call_600505.base,
                         call_600505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600505, url, valid)

proc call*(call_600506: Call_PostDescribeInstanceHealth_600491;
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
  var query_600507 = newJObject()
  var formData_600508 = newJObject()
  if Instances != nil:
    formData_600508.add "Instances", Instances
  add(query_600507, "Action", newJString(Action))
  add(formData_600508, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600507, "Version", newJString(Version))
  result = call_600506.call(nil, query_600507, nil, formData_600508, nil)

var postDescribeInstanceHealth* = Call_PostDescribeInstanceHealth_600491(
    name: "postDescribeInstanceHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_PostDescribeInstanceHealth_600492, base: "/",
    url: url_PostDescribeInstanceHealth_600493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstanceHealth_600474 = ref object of OpenApiRestCall_599368
proc url_GetDescribeInstanceHealth_600476(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeInstanceHealth_600475(path: JsonNode; query: JsonNode;
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
  var valid_600477 = query.getOrDefault("LoadBalancerName")
  valid_600477 = validateParameter(valid_600477, JString, required = true,
                                 default = nil)
  if valid_600477 != nil:
    section.add "LoadBalancerName", valid_600477
  var valid_600478 = query.getOrDefault("Action")
  valid_600478 = validateParameter(valid_600478, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_600478 != nil:
    section.add "Action", valid_600478
  var valid_600479 = query.getOrDefault("Instances")
  valid_600479 = validateParameter(valid_600479, JArray, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "Instances", valid_600479
  var valid_600480 = query.getOrDefault("Version")
  valid_600480 = validateParameter(valid_600480, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600480 != nil:
    section.add "Version", valid_600480
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
  var valid_600481 = header.getOrDefault("X-Amz-Date")
  valid_600481 = validateParameter(valid_600481, JString, required = false,
                                 default = nil)
  if valid_600481 != nil:
    section.add "X-Amz-Date", valid_600481
  var valid_600482 = header.getOrDefault("X-Amz-Security-Token")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-Security-Token", valid_600482
  var valid_600483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-Content-Sha256", valid_600483
  var valid_600484 = header.getOrDefault("X-Amz-Algorithm")
  valid_600484 = validateParameter(valid_600484, JString, required = false,
                                 default = nil)
  if valid_600484 != nil:
    section.add "X-Amz-Algorithm", valid_600484
  var valid_600485 = header.getOrDefault("X-Amz-Signature")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-Signature", valid_600485
  var valid_600486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-SignedHeaders", valid_600486
  var valid_600487 = header.getOrDefault("X-Amz-Credential")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Credential", valid_600487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600488: Call_GetDescribeInstanceHealth_600474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_600488.validator(path, query, header, formData, body)
  let scheme = call_600488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600488.url(scheme.get, call_600488.host, call_600488.base,
                         call_600488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600488, url, valid)

proc call*(call_600489: Call_GetDescribeInstanceHealth_600474;
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
  var query_600490 = newJObject()
  add(query_600490, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600490, "Action", newJString(Action))
  if Instances != nil:
    query_600490.add "Instances", Instances
  add(query_600490, "Version", newJString(Version))
  result = call_600489.call(nil, query_600490, nil, nil, nil)

var getDescribeInstanceHealth* = Call_GetDescribeInstanceHealth_600474(
    name: "getDescribeInstanceHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_GetDescribeInstanceHealth_600475, base: "/",
    url: url_GetDescribeInstanceHealth_600476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_600525 = ref object of OpenApiRestCall_599368
proc url_PostDescribeLoadBalancerAttributes_600527(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancerAttributes_600526(path: JsonNode;
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
  var valid_600528 = query.getOrDefault("Action")
  valid_600528 = validateParameter(valid_600528, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_600528 != nil:
    section.add "Action", valid_600528
  var valid_600529 = query.getOrDefault("Version")
  valid_600529 = validateParameter(valid_600529, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600529 != nil:
    section.add "Version", valid_600529
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
  var valid_600530 = header.getOrDefault("X-Amz-Date")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "X-Amz-Date", valid_600530
  var valid_600531 = header.getOrDefault("X-Amz-Security-Token")
  valid_600531 = validateParameter(valid_600531, JString, required = false,
                                 default = nil)
  if valid_600531 != nil:
    section.add "X-Amz-Security-Token", valid_600531
  var valid_600532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-Content-Sha256", valid_600532
  var valid_600533 = header.getOrDefault("X-Amz-Algorithm")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-Algorithm", valid_600533
  var valid_600534 = header.getOrDefault("X-Amz-Signature")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-Signature", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-SignedHeaders", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-Credential")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Credential", valid_600536
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_600537 = formData.getOrDefault("LoadBalancerName")
  valid_600537 = validateParameter(valid_600537, JString, required = true,
                                 default = nil)
  if valid_600537 != nil:
    section.add "LoadBalancerName", valid_600537
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600538: Call_PostDescribeLoadBalancerAttributes_600525;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_600538.validator(path, query, header, formData, body)
  let scheme = call_600538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600538.url(scheme.get, call_600538.host, call_600538.base,
                         call_600538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600538, url, valid)

proc call*(call_600539: Call_PostDescribeLoadBalancerAttributes_600525;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_600540 = newJObject()
  var formData_600541 = newJObject()
  add(query_600540, "Action", newJString(Action))
  add(formData_600541, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600540, "Version", newJString(Version))
  result = call_600539.call(nil, query_600540, nil, formData_600541, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_600525(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_600526, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_600527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_600509 = ref object of OpenApiRestCall_599368
proc url_GetDescribeLoadBalancerAttributes_600511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancerAttributes_600510(path: JsonNode;
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
  var valid_600512 = query.getOrDefault("LoadBalancerName")
  valid_600512 = validateParameter(valid_600512, JString, required = true,
                                 default = nil)
  if valid_600512 != nil:
    section.add "LoadBalancerName", valid_600512
  var valid_600513 = query.getOrDefault("Action")
  valid_600513 = validateParameter(valid_600513, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_600513 != nil:
    section.add "Action", valid_600513
  var valid_600514 = query.getOrDefault("Version")
  valid_600514 = validateParameter(valid_600514, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600514 != nil:
    section.add "Version", valid_600514
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
  var valid_600515 = header.getOrDefault("X-Amz-Date")
  valid_600515 = validateParameter(valid_600515, JString, required = false,
                                 default = nil)
  if valid_600515 != nil:
    section.add "X-Amz-Date", valid_600515
  var valid_600516 = header.getOrDefault("X-Amz-Security-Token")
  valid_600516 = validateParameter(valid_600516, JString, required = false,
                                 default = nil)
  if valid_600516 != nil:
    section.add "X-Amz-Security-Token", valid_600516
  var valid_600517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600517 = validateParameter(valid_600517, JString, required = false,
                                 default = nil)
  if valid_600517 != nil:
    section.add "X-Amz-Content-Sha256", valid_600517
  var valid_600518 = header.getOrDefault("X-Amz-Algorithm")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-Algorithm", valid_600518
  var valid_600519 = header.getOrDefault("X-Amz-Signature")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Signature", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-SignedHeaders", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Credential")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Credential", valid_600521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600522: Call_GetDescribeLoadBalancerAttributes_600509;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_600522.validator(path, query, header, formData, body)
  let scheme = call_600522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600522.url(scheme.get, call_600522.host, call_600522.base,
                         call_600522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600522, url, valid)

proc call*(call_600523: Call_GetDescribeLoadBalancerAttributes_600509;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600524 = newJObject()
  add(query_600524, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600524, "Action", newJString(Action))
  add(query_600524, "Version", newJString(Version))
  result = call_600523.call(nil, query_600524, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_600509(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_600510, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_600511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicies_600559 = ref object of OpenApiRestCall_599368
proc url_PostDescribeLoadBalancerPolicies_600561(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancerPolicies_600560(path: JsonNode;
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
  var valid_600562 = query.getOrDefault("Action")
  valid_600562 = validateParameter(valid_600562, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_600562 != nil:
    section.add "Action", valid_600562
  var valid_600563 = query.getOrDefault("Version")
  valid_600563 = validateParameter(valid_600563, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600563 != nil:
    section.add "Version", valid_600563
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
  var valid_600564 = header.getOrDefault("X-Amz-Date")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-Date", valid_600564
  var valid_600565 = header.getOrDefault("X-Amz-Security-Token")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "X-Amz-Security-Token", valid_600565
  var valid_600566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-Content-Sha256", valid_600566
  var valid_600567 = header.getOrDefault("X-Amz-Algorithm")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Algorithm", valid_600567
  var valid_600568 = header.getOrDefault("X-Amz-Signature")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "X-Amz-Signature", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-SignedHeaders", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-Credential")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-Credential", valid_600570
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   LoadBalancerName: JString
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_600571 = formData.getOrDefault("PolicyNames")
  valid_600571 = validateParameter(valid_600571, JArray, required = false,
                                 default = nil)
  if valid_600571 != nil:
    section.add "PolicyNames", valid_600571
  var valid_600572 = formData.getOrDefault("LoadBalancerName")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "LoadBalancerName", valid_600572
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600573: Call_PostDescribeLoadBalancerPolicies_600559;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_600573.validator(path, query, header, formData, body)
  let scheme = call_600573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600573.url(scheme.get, call_600573.host, call_600573.base,
                         call_600573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600573, url, valid)

proc call*(call_600574: Call_PostDescribeLoadBalancerPolicies_600559;
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
  var query_600575 = newJObject()
  var formData_600576 = newJObject()
  if PolicyNames != nil:
    formData_600576.add "PolicyNames", PolicyNames
  add(query_600575, "Action", newJString(Action))
  add(formData_600576, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600575, "Version", newJString(Version))
  result = call_600574.call(nil, query_600575, nil, formData_600576, nil)

var postDescribeLoadBalancerPolicies* = Call_PostDescribeLoadBalancerPolicies_600559(
    name: "postDescribeLoadBalancerPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_PostDescribeLoadBalancerPolicies_600560, base: "/",
    url: url_PostDescribeLoadBalancerPolicies_600561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicies_600542 = ref object of OpenApiRestCall_599368
proc url_GetDescribeLoadBalancerPolicies_600544(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancerPolicies_600543(path: JsonNode;
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
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   Version: JString (required)
  section = newJObject()
  var valid_600545 = query.getOrDefault("LoadBalancerName")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "LoadBalancerName", valid_600545
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600546 = query.getOrDefault("Action")
  valid_600546 = validateParameter(valid_600546, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_600546 != nil:
    section.add "Action", valid_600546
  var valid_600547 = query.getOrDefault("PolicyNames")
  valid_600547 = validateParameter(valid_600547, JArray, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "PolicyNames", valid_600547
  var valid_600548 = query.getOrDefault("Version")
  valid_600548 = validateParameter(valid_600548, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600548 != nil:
    section.add "Version", valid_600548
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
  var valid_600549 = header.getOrDefault("X-Amz-Date")
  valid_600549 = validateParameter(valid_600549, JString, required = false,
                                 default = nil)
  if valid_600549 != nil:
    section.add "X-Amz-Date", valid_600549
  var valid_600550 = header.getOrDefault("X-Amz-Security-Token")
  valid_600550 = validateParameter(valid_600550, JString, required = false,
                                 default = nil)
  if valid_600550 != nil:
    section.add "X-Amz-Security-Token", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-Content-Sha256", valid_600551
  var valid_600552 = header.getOrDefault("X-Amz-Algorithm")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Algorithm", valid_600552
  var valid_600553 = header.getOrDefault("X-Amz-Signature")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-Signature", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-SignedHeaders", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-Credential")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Credential", valid_600555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600556: Call_GetDescribeLoadBalancerPolicies_600542;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_600556.validator(path, query, header, formData, body)
  let scheme = call_600556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600556.url(scheme.get, call_600556.host, call_600556.base,
                         call_600556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600556, url, valid)

proc call*(call_600557: Call_GetDescribeLoadBalancerPolicies_600542;
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
  var query_600558 = newJObject()
  add(query_600558, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600558, "Action", newJString(Action))
  if PolicyNames != nil:
    query_600558.add "PolicyNames", PolicyNames
  add(query_600558, "Version", newJString(Version))
  result = call_600557.call(nil, query_600558, nil, nil, nil)

var getDescribeLoadBalancerPolicies* = Call_GetDescribeLoadBalancerPolicies_600542(
    name: "getDescribeLoadBalancerPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_GetDescribeLoadBalancerPolicies_600543, base: "/",
    url: url_GetDescribeLoadBalancerPolicies_600544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicyTypes_600593 = ref object of OpenApiRestCall_599368
proc url_PostDescribeLoadBalancerPolicyTypes_600595(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancerPolicyTypes_600594(path: JsonNode;
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
  var valid_600596 = query.getOrDefault("Action")
  valid_600596 = validateParameter(valid_600596, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_600596 != nil:
    section.add "Action", valid_600596
  var valid_600597 = query.getOrDefault("Version")
  valid_600597 = validateParameter(valid_600597, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600597 != nil:
    section.add "Version", valid_600597
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
  var valid_600598 = header.getOrDefault("X-Amz-Date")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-Date", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Security-Token")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Security-Token", valid_600599
  var valid_600600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600600 = validateParameter(valid_600600, JString, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "X-Amz-Content-Sha256", valid_600600
  var valid_600601 = header.getOrDefault("X-Amz-Algorithm")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "X-Amz-Algorithm", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-Signature")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Signature", valid_600602
  var valid_600603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-SignedHeaders", valid_600603
  var valid_600604 = header.getOrDefault("X-Amz-Credential")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Credential", valid_600604
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  section = newJObject()
  var valid_600605 = formData.getOrDefault("PolicyTypeNames")
  valid_600605 = validateParameter(valid_600605, JArray, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "PolicyTypeNames", valid_600605
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600606: Call_PostDescribeLoadBalancerPolicyTypes_600593;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_600606.validator(path, query, header, formData, body)
  let scheme = call_600606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600606.url(scheme.get, call_600606.host, call_600606.base,
                         call_600606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600606, url, valid)

proc call*(call_600607: Call_PostDescribeLoadBalancerPolicyTypes_600593;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600608 = newJObject()
  var formData_600609 = newJObject()
  if PolicyTypeNames != nil:
    formData_600609.add "PolicyTypeNames", PolicyTypeNames
  add(query_600608, "Action", newJString(Action))
  add(query_600608, "Version", newJString(Version))
  result = call_600607.call(nil, query_600608, nil, formData_600609, nil)

var postDescribeLoadBalancerPolicyTypes* = Call_PostDescribeLoadBalancerPolicyTypes_600593(
    name: "postDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_PostDescribeLoadBalancerPolicyTypes_600594, base: "/",
    url: url_PostDescribeLoadBalancerPolicyTypes_600595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicyTypes_600577 = ref object of OpenApiRestCall_599368
proc url_GetDescribeLoadBalancerPolicyTypes_600579(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancerPolicyTypes_600578(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600580 = query.getOrDefault("Action")
  valid_600580 = validateParameter(valid_600580, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_600580 != nil:
    section.add "Action", valid_600580
  var valid_600581 = query.getOrDefault("PolicyTypeNames")
  valid_600581 = validateParameter(valid_600581, JArray, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "PolicyTypeNames", valid_600581
  var valid_600582 = query.getOrDefault("Version")
  valid_600582 = validateParameter(valid_600582, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600582 != nil:
    section.add "Version", valid_600582
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
  var valid_600583 = header.getOrDefault("X-Amz-Date")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-Date", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-Security-Token")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Security-Token", valid_600584
  var valid_600585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600585 = validateParameter(valid_600585, JString, required = false,
                                 default = nil)
  if valid_600585 != nil:
    section.add "X-Amz-Content-Sha256", valid_600585
  var valid_600586 = header.getOrDefault("X-Amz-Algorithm")
  valid_600586 = validateParameter(valid_600586, JString, required = false,
                                 default = nil)
  if valid_600586 != nil:
    section.add "X-Amz-Algorithm", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-Signature")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Signature", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-SignedHeaders", valid_600588
  var valid_600589 = header.getOrDefault("X-Amz-Credential")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Credential", valid_600589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600590: Call_GetDescribeLoadBalancerPolicyTypes_600577;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_600590.validator(path, query, header, formData, body)
  let scheme = call_600590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600590.url(scheme.get, call_600590.host, call_600590.base,
                         call_600590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600590, url, valid)

proc call*(call_600591: Call_GetDescribeLoadBalancerPolicyTypes_600577;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          PolicyTypeNames: JsonNode = nil; Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   Action: string (required)
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Version: string (required)
  var query_600592 = newJObject()
  add(query_600592, "Action", newJString(Action))
  if PolicyTypeNames != nil:
    query_600592.add "PolicyTypeNames", PolicyTypeNames
  add(query_600592, "Version", newJString(Version))
  result = call_600591.call(nil, query_600592, nil, nil, nil)

var getDescribeLoadBalancerPolicyTypes* = Call_GetDescribeLoadBalancerPolicyTypes_600577(
    name: "getDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_GetDescribeLoadBalancerPolicyTypes_600578, base: "/",
    url: url_GetDescribeLoadBalancerPolicyTypes_600579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_600628 = ref object of OpenApiRestCall_599368
proc url_PostDescribeLoadBalancers_600630(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancers_600629(path: JsonNode; query: JsonNode;
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
  var valid_600631 = query.getOrDefault("Action")
  valid_600631 = validateParameter(valid_600631, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_600631 != nil:
    section.add "Action", valid_600631
  var valid_600632 = query.getOrDefault("Version")
  valid_600632 = validateParameter(valid_600632, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600632 != nil:
    section.add "Version", valid_600632
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
  var valid_600633 = header.getOrDefault("X-Amz-Date")
  valid_600633 = validateParameter(valid_600633, JString, required = false,
                                 default = nil)
  if valid_600633 != nil:
    section.add "X-Amz-Date", valid_600633
  var valid_600634 = header.getOrDefault("X-Amz-Security-Token")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "X-Amz-Security-Token", valid_600634
  var valid_600635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-Content-Sha256", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-Algorithm")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Algorithm", valid_600636
  var valid_600637 = header.getOrDefault("X-Amz-Signature")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-Signature", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-SignedHeaders", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-Credential")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Credential", valid_600639
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  section = newJObject()
  var valid_600640 = formData.getOrDefault("Marker")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "Marker", valid_600640
  var valid_600641 = formData.getOrDefault("LoadBalancerNames")
  valid_600641 = validateParameter(valid_600641, JArray, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "LoadBalancerNames", valid_600641
  var valid_600642 = formData.getOrDefault("PageSize")
  valid_600642 = validateParameter(valid_600642, JInt, required = false, default = nil)
  if valid_600642 != nil:
    section.add "PageSize", valid_600642
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600643: Call_PostDescribeLoadBalancers_600628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_600643.validator(path, query, header, formData, body)
  let scheme = call_600643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600643.url(scheme.get, call_600643.host, call_600643.base,
                         call_600643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600643, url, valid)

proc call*(call_600644: Call_PostDescribeLoadBalancers_600628; Marker: string = "";
          Action: string = "DescribeLoadBalancers";
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
  var query_600645 = newJObject()
  var formData_600646 = newJObject()
  add(formData_600646, "Marker", newJString(Marker))
  add(query_600645, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_600646.add "LoadBalancerNames", LoadBalancerNames
  add(formData_600646, "PageSize", newJInt(PageSize))
  add(query_600645, "Version", newJString(Version))
  result = call_600644.call(nil, query_600645, nil, formData_600646, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_600628(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_600629, base: "/",
    url: url_PostDescribeLoadBalancers_600630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_600610 = ref object of OpenApiRestCall_599368
proc url_GetDescribeLoadBalancers_600612(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancers_600611(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600613 = query.getOrDefault("PageSize")
  valid_600613 = validateParameter(valid_600613, JInt, required = false, default = nil)
  if valid_600613 != nil:
    section.add "PageSize", valid_600613
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600614 = query.getOrDefault("Action")
  valid_600614 = validateParameter(valid_600614, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_600614 != nil:
    section.add "Action", valid_600614
  var valid_600615 = query.getOrDefault("Marker")
  valid_600615 = validateParameter(valid_600615, JString, required = false,
                                 default = nil)
  if valid_600615 != nil:
    section.add "Marker", valid_600615
  var valid_600616 = query.getOrDefault("LoadBalancerNames")
  valid_600616 = validateParameter(valid_600616, JArray, required = false,
                                 default = nil)
  if valid_600616 != nil:
    section.add "LoadBalancerNames", valid_600616
  var valid_600617 = query.getOrDefault("Version")
  valid_600617 = validateParameter(valid_600617, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600617 != nil:
    section.add "Version", valid_600617
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
  var valid_600618 = header.getOrDefault("X-Amz-Date")
  valid_600618 = validateParameter(valid_600618, JString, required = false,
                                 default = nil)
  if valid_600618 != nil:
    section.add "X-Amz-Date", valid_600618
  var valid_600619 = header.getOrDefault("X-Amz-Security-Token")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-Security-Token", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-Content-Sha256", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Algorithm")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Algorithm", valid_600621
  var valid_600622 = header.getOrDefault("X-Amz-Signature")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-Signature", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-SignedHeaders", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-Credential")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Credential", valid_600624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600625: Call_GetDescribeLoadBalancers_600610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_600625.validator(path, query, header, formData, body)
  let scheme = call_600625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600625.url(scheme.get, call_600625.host, call_600625.base,
                         call_600625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600625, url, valid)

proc call*(call_600626: Call_GetDescribeLoadBalancers_600610; PageSize: int = 0;
          Action: string = "DescribeLoadBalancers"; Marker: string = "";
          LoadBalancerNames: JsonNode = nil; Version: string = "2012-06-01"): Recallable =
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
  var query_600627 = newJObject()
  add(query_600627, "PageSize", newJInt(PageSize))
  add(query_600627, "Action", newJString(Action))
  add(query_600627, "Marker", newJString(Marker))
  if LoadBalancerNames != nil:
    query_600627.add "LoadBalancerNames", LoadBalancerNames
  add(query_600627, "Version", newJString(Version))
  result = call_600626.call(nil, query_600627, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_600610(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_600611, base: "/",
    url: url_GetDescribeLoadBalancers_600612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_600663 = ref object of OpenApiRestCall_599368
proc url_PostDescribeTags_600665(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTags_600664(path: JsonNode; query: JsonNode;
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
  var valid_600666 = query.getOrDefault("Action")
  valid_600666 = validateParameter(valid_600666, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_600666 != nil:
    section.add "Action", valid_600666
  var valid_600667 = query.getOrDefault("Version")
  valid_600667 = validateParameter(valid_600667, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600667 != nil:
    section.add "Version", valid_600667
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
  var valid_600668 = header.getOrDefault("X-Amz-Date")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Date", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-Security-Token")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-Security-Token", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-Content-Sha256", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-Algorithm")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-Algorithm", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-Signature")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-Signature", valid_600672
  var valid_600673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600673 = validateParameter(valid_600673, JString, required = false,
                                 default = nil)
  if valid_600673 != nil:
    section.add "X-Amz-SignedHeaders", valid_600673
  var valid_600674 = header.getOrDefault("X-Amz-Credential")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-Credential", valid_600674
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_600675 = formData.getOrDefault("LoadBalancerNames")
  valid_600675 = validateParameter(valid_600675, JArray, required = true, default = nil)
  if valid_600675 != nil:
    section.add "LoadBalancerNames", valid_600675
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600676: Call_PostDescribeTags_600663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_600676.validator(path, query, header, formData, body)
  let scheme = call_600676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600676.url(scheme.get, call_600676.host, call_600676.base,
                         call_600676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600676, url, valid)

proc call*(call_600677: Call_PostDescribeTags_600663; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_600678 = newJObject()
  var formData_600679 = newJObject()
  add(query_600678, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_600679.add "LoadBalancerNames", LoadBalancerNames
  add(query_600678, "Version", newJString(Version))
  result = call_600677.call(nil, query_600678, nil, formData_600679, nil)

var postDescribeTags* = Call_PostDescribeTags_600663(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_600664,
    base: "/", url: url_PostDescribeTags_600665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_600647 = ref object of OpenApiRestCall_599368
proc url_GetDescribeTags_600649(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTags_600648(path: JsonNode; query: JsonNode;
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
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600650 = query.getOrDefault("Action")
  valid_600650 = validateParameter(valid_600650, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_600650 != nil:
    section.add "Action", valid_600650
  var valid_600651 = query.getOrDefault("LoadBalancerNames")
  valid_600651 = validateParameter(valid_600651, JArray, required = true, default = nil)
  if valid_600651 != nil:
    section.add "LoadBalancerNames", valid_600651
  var valid_600652 = query.getOrDefault("Version")
  valid_600652 = validateParameter(valid_600652, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600652 != nil:
    section.add "Version", valid_600652
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
  var valid_600653 = header.getOrDefault("X-Amz-Date")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Date", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Security-Token")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Security-Token", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Content-Sha256", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-Algorithm")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Algorithm", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Signature")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Signature", valid_600657
  var valid_600658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600658 = validateParameter(valid_600658, JString, required = false,
                                 default = nil)
  if valid_600658 != nil:
    section.add "X-Amz-SignedHeaders", valid_600658
  var valid_600659 = header.getOrDefault("X-Amz-Credential")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-Credential", valid_600659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600660: Call_GetDescribeTags_600647; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_600660.validator(path, query, header, formData, body)
  let scheme = call_600660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600660.url(scheme.get, call_600660.host, call_600660.base,
                         call_600660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600660, url, valid)

proc call*(call_600661: Call_GetDescribeTags_600647; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_600662 = newJObject()
  add(query_600662, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_600662.add "LoadBalancerNames", LoadBalancerNames
  add(query_600662, "Version", newJString(Version))
  result = call_600661.call(nil, query_600662, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_600647(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_600648,
    base: "/", url: url_GetDescribeTags_600649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDetachLoadBalancerFromSubnets_600697 = ref object of OpenApiRestCall_599368
proc url_PostDetachLoadBalancerFromSubnets_600699(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDetachLoadBalancerFromSubnets_600698(path: JsonNode;
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
  var valid_600700 = query.getOrDefault("Action")
  valid_600700 = validateParameter(valid_600700, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_600700 != nil:
    section.add "Action", valid_600700
  var valid_600701 = query.getOrDefault("Version")
  valid_600701 = validateParameter(valid_600701, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600701 != nil:
    section.add "Version", valid_600701
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
  var valid_600702 = header.getOrDefault("X-Amz-Date")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Date", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-Security-Token")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-Security-Token", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-Content-Sha256", valid_600704
  var valid_600705 = header.getOrDefault("X-Amz-Algorithm")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "X-Amz-Algorithm", valid_600705
  var valid_600706 = header.getOrDefault("X-Amz-Signature")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "X-Amz-Signature", valid_600706
  var valid_600707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600707 = validateParameter(valid_600707, JString, required = false,
                                 default = nil)
  if valid_600707 != nil:
    section.add "X-Amz-SignedHeaders", valid_600707
  var valid_600708 = header.getOrDefault("X-Amz-Credential")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "X-Amz-Credential", valid_600708
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_600709 = formData.getOrDefault("Subnets")
  valid_600709 = validateParameter(valid_600709, JArray, required = true, default = nil)
  if valid_600709 != nil:
    section.add "Subnets", valid_600709
  var valid_600710 = formData.getOrDefault("LoadBalancerName")
  valid_600710 = validateParameter(valid_600710, JString, required = true,
                                 default = nil)
  if valid_600710 != nil:
    section.add "LoadBalancerName", valid_600710
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600711: Call_PostDetachLoadBalancerFromSubnets_600697;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_600711.validator(path, query, header, formData, body)
  let scheme = call_600711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600711.url(scheme.get, call_600711.host, call_600711.base,
                         call_600711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600711, url, valid)

proc call*(call_600712: Call_PostDetachLoadBalancerFromSubnets_600697;
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
  var query_600713 = newJObject()
  var formData_600714 = newJObject()
  add(query_600713, "Action", newJString(Action))
  if Subnets != nil:
    formData_600714.add "Subnets", Subnets
  add(formData_600714, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600713, "Version", newJString(Version))
  result = call_600712.call(nil, query_600713, nil, formData_600714, nil)

var postDetachLoadBalancerFromSubnets* = Call_PostDetachLoadBalancerFromSubnets_600697(
    name: "postDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_PostDetachLoadBalancerFromSubnets_600698, base: "/",
    url: url_PostDetachLoadBalancerFromSubnets_600699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetachLoadBalancerFromSubnets_600680 = ref object of OpenApiRestCall_599368
proc url_GetDetachLoadBalancerFromSubnets_600682(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDetachLoadBalancerFromSubnets_600681(path: JsonNode;
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
  var valid_600683 = query.getOrDefault("LoadBalancerName")
  valid_600683 = validateParameter(valid_600683, JString, required = true,
                                 default = nil)
  if valid_600683 != nil:
    section.add "LoadBalancerName", valid_600683
  var valid_600684 = query.getOrDefault("Action")
  valid_600684 = validateParameter(valid_600684, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_600684 != nil:
    section.add "Action", valid_600684
  var valid_600685 = query.getOrDefault("Subnets")
  valid_600685 = validateParameter(valid_600685, JArray, required = true, default = nil)
  if valid_600685 != nil:
    section.add "Subnets", valid_600685
  var valid_600686 = query.getOrDefault("Version")
  valid_600686 = validateParameter(valid_600686, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600686 != nil:
    section.add "Version", valid_600686
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
  var valid_600687 = header.getOrDefault("X-Amz-Date")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Date", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-Security-Token")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-Security-Token", valid_600688
  var valid_600689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-Content-Sha256", valid_600689
  var valid_600690 = header.getOrDefault("X-Amz-Algorithm")
  valid_600690 = validateParameter(valid_600690, JString, required = false,
                                 default = nil)
  if valid_600690 != nil:
    section.add "X-Amz-Algorithm", valid_600690
  var valid_600691 = header.getOrDefault("X-Amz-Signature")
  valid_600691 = validateParameter(valid_600691, JString, required = false,
                                 default = nil)
  if valid_600691 != nil:
    section.add "X-Amz-Signature", valid_600691
  var valid_600692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "X-Amz-SignedHeaders", valid_600692
  var valid_600693 = header.getOrDefault("X-Amz-Credential")
  valid_600693 = validateParameter(valid_600693, JString, required = false,
                                 default = nil)
  if valid_600693 != nil:
    section.add "X-Amz-Credential", valid_600693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600694: Call_GetDetachLoadBalancerFromSubnets_600680;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_600694.validator(path, query, header, formData, body)
  let scheme = call_600694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600694.url(scheme.get, call_600694.host, call_600694.base,
                         call_600694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600694, url, valid)

proc call*(call_600695: Call_GetDetachLoadBalancerFromSubnets_600680;
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
  var query_600696 = newJObject()
  add(query_600696, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600696, "Action", newJString(Action))
  if Subnets != nil:
    query_600696.add "Subnets", Subnets
  add(query_600696, "Version", newJString(Version))
  result = call_600695.call(nil, query_600696, nil, nil, nil)

var getDetachLoadBalancerFromSubnets* = Call_GetDetachLoadBalancerFromSubnets_600680(
    name: "getDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_GetDetachLoadBalancerFromSubnets_600681, base: "/",
    url: url_GetDetachLoadBalancerFromSubnets_600682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAvailabilityZonesForLoadBalancer_600732 = ref object of OpenApiRestCall_599368
proc url_PostDisableAvailabilityZonesForLoadBalancer_600734(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDisableAvailabilityZonesForLoadBalancer_600733(path: JsonNode;
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
  var valid_600735 = query.getOrDefault("Action")
  valid_600735 = validateParameter(valid_600735, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_600735 != nil:
    section.add "Action", valid_600735
  var valid_600736 = query.getOrDefault("Version")
  valid_600736 = validateParameter(valid_600736, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600736 != nil:
    section.add "Version", valid_600736
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
  var valid_600737 = header.getOrDefault("X-Amz-Date")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-Date", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Security-Token")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Security-Token", valid_600738
  var valid_600739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "X-Amz-Content-Sha256", valid_600739
  var valid_600740 = header.getOrDefault("X-Amz-Algorithm")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "X-Amz-Algorithm", valid_600740
  var valid_600741 = header.getOrDefault("X-Amz-Signature")
  valid_600741 = validateParameter(valid_600741, JString, required = false,
                                 default = nil)
  if valid_600741 != nil:
    section.add "X-Amz-Signature", valid_600741
  var valid_600742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600742 = validateParameter(valid_600742, JString, required = false,
                                 default = nil)
  if valid_600742 != nil:
    section.add "X-Amz-SignedHeaders", valid_600742
  var valid_600743 = header.getOrDefault("X-Amz-Credential")
  valid_600743 = validateParameter(valid_600743, JString, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "X-Amz-Credential", valid_600743
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_600744 = formData.getOrDefault("AvailabilityZones")
  valid_600744 = validateParameter(valid_600744, JArray, required = true, default = nil)
  if valid_600744 != nil:
    section.add "AvailabilityZones", valid_600744
  var valid_600745 = formData.getOrDefault("LoadBalancerName")
  valid_600745 = validateParameter(valid_600745, JString, required = true,
                                 default = nil)
  if valid_600745 != nil:
    section.add "LoadBalancerName", valid_600745
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600746: Call_PostDisableAvailabilityZonesForLoadBalancer_600732;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600746.validator(path, query, header, formData, body)
  let scheme = call_600746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600746.url(scheme.get, call_600746.host, call_600746.base,
                         call_600746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600746, url, valid)

proc call*(call_600747: Call_PostDisableAvailabilityZonesForLoadBalancer_600732;
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
  var query_600748 = newJObject()
  var formData_600749 = newJObject()
  add(query_600748, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_600749.add "AvailabilityZones", AvailabilityZones
  add(formData_600749, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600748, "Version", newJString(Version))
  result = call_600747.call(nil, query_600748, nil, formData_600749, nil)

var postDisableAvailabilityZonesForLoadBalancer* = Call_PostDisableAvailabilityZonesForLoadBalancer_600732(
    name: "postDisableAvailabilityZonesForLoadBalancer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_PostDisableAvailabilityZonesForLoadBalancer_600733,
    base: "/", url: url_PostDisableAvailabilityZonesForLoadBalancer_600734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAvailabilityZonesForLoadBalancer_600715 = ref object of OpenApiRestCall_599368
proc url_GetDisableAvailabilityZonesForLoadBalancer_600717(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDisableAvailabilityZonesForLoadBalancer_600716(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600718 = query.getOrDefault("LoadBalancerName")
  valid_600718 = validateParameter(valid_600718, JString, required = true,
                                 default = nil)
  if valid_600718 != nil:
    section.add "LoadBalancerName", valid_600718
  var valid_600719 = query.getOrDefault("AvailabilityZones")
  valid_600719 = validateParameter(valid_600719, JArray, required = true, default = nil)
  if valid_600719 != nil:
    section.add "AvailabilityZones", valid_600719
  var valid_600720 = query.getOrDefault("Action")
  valid_600720 = validateParameter(valid_600720, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_600720 != nil:
    section.add "Action", valid_600720
  var valid_600721 = query.getOrDefault("Version")
  valid_600721 = validateParameter(valid_600721, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600721 != nil:
    section.add "Version", valid_600721
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
  var valid_600722 = header.getOrDefault("X-Amz-Date")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-Date", valid_600722
  var valid_600723 = header.getOrDefault("X-Amz-Security-Token")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Security-Token", valid_600723
  var valid_600724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600724 = validateParameter(valid_600724, JString, required = false,
                                 default = nil)
  if valid_600724 != nil:
    section.add "X-Amz-Content-Sha256", valid_600724
  var valid_600725 = header.getOrDefault("X-Amz-Algorithm")
  valid_600725 = validateParameter(valid_600725, JString, required = false,
                                 default = nil)
  if valid_600725 != nil:
    section.add "X-Amz-Algorithm", valid_600725
  var valid_600726 = header.getOrDefault("X-Amz-Signature")
  valid_600726 = validateParameter(valid_600726, JString, required = false,
                                 default = nil)
  if valid_600726 != nil:
    section.add "X-Amz-Signature", valid_600726
  var valid_600727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600727 = validateParameter(valid_600727, JString, required = false,
                                 default = nil)
  if valid_600727 != nil:
    section.add "X-Amz-SignedHeaders", valid_600727
  var valid_600728 = header.getOrDefault("X-Amz-Credential")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-Credential", valid_600728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600729: Call_GetDisableAvailabilityZonesForLoadBalancer_600715;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600729.validator(path, query, header, formData, body)
  let scheme = call_600729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600729.url(scheme.get, call_600729.host, call_600729.base,
                         call_600729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600729, url, valid)

proc call*(call_600730: Call_GetDisableAvailabilityZonesForLoadBalancer_600715;
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
  var query_600731 = newJObject()
  add(query_600731, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_600731.add "AvailabilityZones", AvailabilityZones
  add(query_600731, "Action", newJString(Action))
  add(query_600731, "Version", newJString(Version))
  result = call_600730.call(nil, query_600731, nil, nil, nil)

var getDisableAvailabilityZonesForLoadBalancer* = Call_GetDisableAvailabilityZonesForLoadBalancer_600715(
    name: "getDisableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_GetDisableAvailabilityZonesForLoadBalancer_600716,
    base: "/", url: url_GetDisableAvailabilityZonesForLoadBalancer_600717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAvailabilityZonesForLoadBalancer_600767 = ref object of OpenApiRestCall_599368
proc url_PostEnableAvailabilityZonesForLoadBalancer_600769(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostEnableAvailabilityZonesForLoadBalancer_600768(path: JsonNode;
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
  var valid_600770 = query.getOrDefault("Action")
  valid_600770 = validateParameter(valid_600770, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_600770 != nil:
    section.add "Action", valid_600770
  var valid_600771 = query.getOrDefault("Version")
  valid_600771 = validateParameter(valid_600771, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600771 != nil:
    section.add "Version", valid_600771
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
  var valid_600772 = header.getOrDefault("X-Amz-Date")
  valid_600772 = validateParameter(valid_600772, JString, required = false,
                                 default = nil)
  if valid_600772 != nil:
    section.add "X-Amz-Date", valid_600772
  var valid_600773 = header.getOrDefault("X-Amz-Security-Token")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Security-Token", valid_600773
  var valid_600774 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600774 = validateParameter(valid_600774, JString, required = false,
                                 default = nil)
  if valid_600774 != nil:
    section.add "X-Amz-Content-Sha256", valid_600774
  var valid_600775 = header.getOrDefault("X-Amz-Algorithm")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-Algorithm", valid_600775
  var valid_600776 = header.getOrDefault("X-Amz-Signature")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Signature", valid_600776
  var valid_600777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "X-Amz-SignedHeaders", valid_600777
  var valid_600778 = header.getOrDefault("X-Amz-Credential")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "X-Amz-Credential", valid_600778
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_600779 = formData.getOrDefault("AvailabilityZones")
  valid_600779 = validateParameter(valid_600779, JArray, required = true, default = nil)
  if valid_600779 != nil:
    section.add "AvailabilityZones", valid_600779
  var valid_600780 = formData.getOrDefault("LoadBalancerName")
  valid_600780 = validateParameter(valid_600780, JString, required = true,
                                 default = nil)
  if valid_600780 != nil:
    section.add "LoadBalancerName", valid_600780
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600781: Call_PostEnableAvailabilityZonesForLoadBalancer_600767;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600781.validator(path, query, header, formData, body)
  let scheme = call_600781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600781.url(scheme.get, call_600781.host, call_600781.base,
                         call_600781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600781, url, valid)

proc call*(call_600782: Call_PostEnableAvailabilityZonesForLoadBalancer_600767;
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
  var query_600783 = newJObject()
  var formData_600784 = newJObject()
  add(query_600783, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_600784.add "AvailabilityZones", AvailabilityZones
  add(formData_600784, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600783, "Version", newJString(Version))
  result = call_600782.call(nil, query_600783, nil, formData_600784, nil)

var postEnableAvailabilityZonesForLoadBalancer* = Call_PostEnableAvailabilityZonesForLoadBalancer_600767(
    name: "postEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_PostEnableAvailabilityZonesForLoadBalancer_600768,
    base: "/", url: url_PostEnableAvailabilityZonesForLoadBalancer_600769,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAvailabilityZonesForLoadBalancer_600750 = ref object of OpenApiRestCall_599368
proc url_GetEnableAvailabilityZonesForLoadBalancer_600752(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEnableAvailabilityZonesForLoadBalancer_600751(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600753 = query.getOrDefault("LoadBalancerName")
  valid_600753 = validateParameter(valid_600753, JString, required = true,
                                 default = nil)
  if valid_600753 != nil:
    section.add "LoadBalancerName", valid_600753
  var valid_600754 = query.getOrDefault("AvailabilityZones")
  valid_600754 = validateParameter(valid_600754, JArray, required = true, default = nil)
  if valid_600754 != nil:
    section.add "AvailabilityZones", valid_600754
  var valid_600755 = query.getOrDefault("Action")
  valid_600755 = validateParameter(valid_600755, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_600755 != nil:
    section.add "Action", valid_600755
  var valid_600756 = query.getOrDefault("Version")
  valid_600756 = validateParameter(valid_600756, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600756 != nil:
    section.add "Version", valid_600756
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
  var valid_600757 = header.getOrDefault("X-Amz-Date")
  valid_600757 = validateParameter(valid_600757, JString, required = false,
                                 default = nil)
  if valid_600757 != nil:
    section.add "X-Amz-Date", valid_600757
  var valid_600758 = header.getOrDefault("X-Amz-Security-Token")
  valid_600758 = validateParameter(valid_600758, JString, required = false,
                                 default = nil)
  if valid_600758 != nil:
    section.add "X-Amz-Security-Token", valid_600758
  var valid_600759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600759 = validateParameter(valid_600759, JString, required = false,
                                 default = nil)
  if valid_600759 != nil:
    section.add "X-Amz-Content-Sha256", valid_600759
  var valid_600760 = header.getOrDefault("X-Amz-Algorithm")
  valid_600760 = validateParameter(valid_600760, JString, required = false,
                                 default = nil)
  if valid_600760 != nil:
    section.add "X-Amz-Algorithm", valid_600760
  var valid_600761 = header.getOrDefault("X-Amz-Signature")
  valid_600761 = validateParameter(valid_600761, JString, required = false,
                                 default = nil)
  if valid_600761 != nil:
    section.add "X-Amz-Signature", valid_600761
  var valid_600762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-SignedHeaders", valid_600762
  var valid_600763 = header.getOrDefault("X-Amz-Credential")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "X-Amz-Credential", valid_600763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600764: Call_GetEnableAvailabilityZonesForLoadBalancer_600750;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600764.validator(path, query, header, formData, body)
  let scheme = call_600764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600764.url(scheme.get, call_600764.host, call_600764.base,
                         call_600764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600764, url, valid)

proc call*(call_600765: Call_GetEnableAvailabilityZonesForLoadBalancer_600750;
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
  var query_600766 = newJObject()
  add(query_600766, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_600766.add "AvailabilityZones", AvailabilityZones
  add(query_600766, "Action", newJString(Action))
  add(query_600766, "Version", newJString(Version))
  result = call_600765.call(nil, query_600766, nil, nil, nil)

var getEnableAvailabilityZonesForLoadBalancer* = Call_GetEnableAvailabilityZonesForLoadBalancer_600750(
    name: "getEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_GetEnableAvailabilityZonesForLoadBalancer_600751,
    base: "/", url: url_GetEnableAvailabilityZonesForLoadBalancer_600752,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_600806 = ref object of OpenApiRestCall_599368
proc url_PostModifyLoadBalancerAttributes_600808(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyLoadBalancerAttributes_600807(path: JsonNode;
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
  var valid_600809 = query.getOrDefault("Action")
  valid_600809 = validateParameter(valid_600809, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_600809 != nil:
    section.add "Action", valid_600809
  var valid_600810 = query.getOrDefault("Version")
  valid_600810 = validateParameter(valid_600810, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600810 != nil:
    section.add "Version", valid_600810
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
  var valid_600811 = header.getOrDefault("X-Amz-Date")
  valid_600811 = validateParameter(valid_600811, JString, required = false,
                                 default = nil)
  if valid_600811 != nil:
    section.add "X-Amz-Date", valid_600811
  var valid_600812 = header.getOrDefault("X-Amz-Security-Token")
  valid_600812 = validateParameter(valid_600812, JString, required = false,
                                 default = nil)
  if valid_600812 != nil:
    section.add "X-Amz-Security-Token", valid_600812
  var valid_600813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600813 = validateParameter(valid_600813, JString, required = false,
                                 default = nil)
  if valid_600813 != nil:
    section.add "X-Amz-Content-Sha256", valid_600813
  var valid_600814 = header.getOrDefault("X-Amz-Algorithm")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "X-Amz-Algorithm", valid_600814
  var valid_600815 = header.getOrDefault("X-Amz-Signature")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "X-Amz-Signature", valid_600815
  var valid_600816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-SignedHeaders", valid_600816
  var valid_600817 = header.getOrDefault("X-Amz-Credential")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-Credential", valid_600817
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
  var valid_600818 = formData.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_600818 = validateParameter(valid_600818, JArray, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_600818
  var valid_600819 = formData.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_600819 = validateParameter(valid_600819, JString, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_600819
  var valid_600820 = formData.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_600820 = validateParameter(valid_600820, JString, required = false,
                                 default = nil)
  if valid_600820 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_600820
  var valid_600821 = formData.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_600821 = validateParameter(valid_600821, JString, required = false,
                                 default = nil)
  if valid_600821 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_600821
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_600822 = formData.getOrDefault("LoadBalancerName")
  valid_600822 = validateParameter(valid_600822, JString, required = true,
                                 default = nil)
  if valid_600822 != nil:
    section.add "LoadBalancerName", valid_600822
  var valid_600823 = formData.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_600823 = validateParameter(valid_600823, JString, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_600823
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600824: Call_PostModifyLoadBalancerAttributes_600806;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_600824.validator(path, query, header, formData, body)
  let scheme = call_600824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600824.url(scheme.get, call_600824.host, call_600824.base,
                         call_600824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600824, url, valid)

proc call*(call_600825: Call_PostModifyLoadBalancerAttributes_600806;
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
  var query_600826 = newJObject()
  var formData_600827 = newJObject()
  if LoadBalancerAttributesAdditionalAttributes != nil:
    formData_600827.add "LoadBalancerAttributes.AdditionalAttributes",
                       LoadBalancerAttributesAdditionalAttributes
  add(formData_600827, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  add(formData_600827, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_600826, "Action", newJString(Action))
  add(formData_600827, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(formData_600827, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_600827, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_600826, "Version", newJString(Version))
  result = call_600825.call(nil, query_600826, nil, formData_600827, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_600806(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_600807, base: "/",
    url: url_PostModifyLoadBalancerAttributes_600808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_600785 = ref object of OpenApiRestCall_599368
proc url_GetModifyLoadBalancerAttributes_600787(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyLoadBalancerAttributes_600786(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600788 = query.getOrDefault("LoadBalancerName")
  valid_600788 = validateParameter(valid_600788, JString, required = true,
                                 default = nil)
  if valid_600788 != nil:
    section.add "LoadBalancerName", valid_600788
  var valid_600789 = query.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_600789 = validateParameter(valid_600789, JString, required = false,
                                 default = nil)
  if valid_600789 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_600789
  var valid_600790 = query.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_600790 = validateParameter(valid_600790, JString, required = false,
                                 default = nil)
  if valid_600790 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_600790
  var valid_600791 = query.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_600791 = validateParameter(valid_600791, JArray, required = false,
                                 default = nil)
  if valid_600791 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_600791
  var valid_600792 = query.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_600792 = validateParameter(valid_600792, JString, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_600792
  var valid_600793 = query.getOrDefault("Action")
  valid_600793 = validateParameter(valid_600793, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_600793 != nil:
    section.add "Action", valid_600793
  var valid_600794 = query.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_600794
  var valid_600795 = query.getOrDefault("Version")
  valid_600795 = validateParameter(valid_600795, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600795 != nil:
    section.add "Version", valid_600795
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
  var valid_600796 = header.getOrDefault("X-Amz-Date")
  valid_600796 = validateParameter(valid_600796, JString, required = false,
                                 default = nil)
  if valid_600796 != nil:
    section.add "X-Amz-Date", valid_600796
  var valid_600797 = header.getOrDefault("X-Amz-Security-Token")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "X-Amz-Security-Token", valid_600797
  var valid_600798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Content-Sha256", valid_600798
  var valid_600799 = header.getOrDefault("X-Amz-Algorithm")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-Algorithm", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-Signature")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-Signature", valid_600800
  var valid_600801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-SignedHeaders", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-Credential")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-Credential", valid_600802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600803: Call_GetModifyLoadBalancerAttributes_600785;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_600803.validator(path, query, header, formData, body)
  let scheme = call_600803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600803.url(scheme.get, call_600803.host, call_600803.base,
                         call_600803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600803, url, valid)

proc call*(call_600804: Call_GetModifyLoadBalancerAttributes_600785;
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
  var query_600805 = newJObject()
  add(query_600805, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600805, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_600805, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    query_600805.add "LoadBalancerAttributes.AdditionalAttributes",
                    LoadBalancerAttributesAdditionalAttributes
  add(query_600805, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_600805, "Action", newJString(Action))
  add(query_600805, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_600805, "Version", newJString(Version))
  result = call_600804.call(nil, query_600805, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_600785(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_600786, base: "/",
    url: url_GetModifyLoadBalancerAttributes_600787,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterInstancesWithLoadBalancer_600845 = ref object of OpenApiRestCall_599368
proc url_PostRegisterInstancesWithLoadBalancer_600847(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRegisterInstancesWithLoadBalancer_600846(path: JsonNode;
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
  var valid_600848 = query.getOrDefault("Action")
  valid_600848 = validateParameter(valid_600848, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_600848 != nil:
    section.add "Action", valid_600848
  var valid_600849 = query.getOrDefault("Version")
  valid_600849 = validateParameter(valid_600849, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600849 != nil:
    section.add "Version", valid_600849
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
  var valid_600850 = header.getOrDefault("X-Amz-Date")
  valid_600850 = validateParameter(valid_600850, JString, required = false,
                                 default = nil)
  if valid_600850 != nil:
    section.add "X-Amz-Date", valid_600850
  var valid_600851 = header.getOrDefault("X-Amz-Security-Token")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-Security-Token", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Content-Sha256", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-Algorithm")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-Algorithm", valid_600853
  var valid_600854 = header.getOrDefault("X-Amz-Signature")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Signature", valid_600854
  var valid_600855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-SignedHeaders", valid_600855
  var valid_600856 = header.getOrDefault("X-Amz-Credential")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-Credential", valid_600856
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_600857 = formData.getOrDefault("Instances")
  valid_600857 = validateParameter(valid_600857, JArray, required = true, default = nil)
  if valid_600857 != nil:
    section.add "Instances", valid_600857
  var valid_600858 = formData.getOrDefault("LoadBalancerName")
  valid_600858 = validateParameter(valid_600858, JString, required = true,
                                 default = nil)
  if valid_600858 != nil:
    section.add "LoadBalancerName", valid_600858
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600859: Call_PostRegisterInstancesWithLoadBalancer_600845;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600859.validator(path, query, header, formData, body)
  let scheme = call_600859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600859.url(scheme.get, call_600859.host, call_600859.base,
                         call_600859.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600859, url, valid)

proc call*(call_600860: Call_PostRegisterInstancesWithLoadBalancer_600845;
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
  var query_600861 = newJObject()
  var formData_600862 = newJObject()
  if Instances != nil:
    formData_600862.add "Instances", Instances
  add(query_600861, "Action", newJString(Action))
  add(formData_600862, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600861, "Version", newJString(Version))
  result = call_600860.call(nil, query_600861, nil, formData_600862, nil)

var postRegisterInstancesWithLoadBalancer* = Call_PostRegisterInstancesWithLoadBalancer_600845(
    name: "postRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_PostRegisterInstancesWithLoadBalancer_600846, base: "/",
    url: url_PostRegisterInstancesWithLoadBalancer_600847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterInstancesWithLoadBalancer_600828 = ref object of OpenApiRestCall_599368
proc url_GetRegisterInstancesWithLoadBalancer_600830(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRegisterInstancesWithLoadBalancer_600829(path: JsonNode;
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
  var valid_600831 = query.getOrDefault("LoadBalancerName")
  valid_600831 = validateParameter(valid_600831, JString, required = true,
                                 default = nil)
  if valid_600831 != nil:
    section.add "LoadBalancerName", valid_600831
  var valid_600832 = query.getOrDefault("Action")
  valid_600832 = validateParameter(valid_600832, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_600832 != nil:
    section.add "Action", valid_600832
  var valid_600833 = query.getOrDefault("Instances")
  valid_600833 = validateParameter(valid_600833, JArray, required = true, default = nil)
  if valid_600833 != nil:
    section.add "Instances", valid_600833
  var valid_600834 = query.getOrDefault("Version")
  valid_600834 = validateParameter(valid_600834, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600834 != nil:
    section.add "Version", valid_600834
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
  var valid_600835 = header.getOrDefault("X-Amz-Date")
  valid_600835 = validateParameter(valid_600835, JString, required = false,
                                 default = nil)
  if valid_600835 != nil:
    section.add "X-Amz-Date", valid_600835
  var valid_600836 = header.getOrDefault("X-Amz-Security-Token")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "X-Amz-Security-Token", valid_600836
  var valid_600837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-Content-Sha256", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-Algorithm")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-Algorithm", valid_600838
  var valid_600839 = header.getOrDefault("X-Amz-Signature")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-Signature", valid_600839
  var valid_600840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-SignedHeaders", valid_600840
  var valid_600841 = header.getOrDefault("X-Amz-Credential")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-Credential", valid_600841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600842: Call_GetRegisterInstancesWithLoadBalancer_600828;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600842.validator(path, query, header, formData, body)
  let scheme = call_600842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600842.url(scheme.get, call_600842.host, call_600842.base,
                         call_600842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600842, url, valid)

proc call*(call_600843: Call_GetRegisterInstancesWithLoadBalancer_600828;
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
  var query_600844 = newJObject()
  add(query_600844, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600844, "Action", newJString(Action))
  if Instances != nil:
    query_600844.add "Instances", Instances
  add(query_600844, "Version", newJString(Version))
  result = call_600843.call(nil, query_600844, nil, nil, nil)

var getRegisterInstancesWithLoadBalancer* = Call_GetRegisterInstancesWithLoadBalancer_600828(
    name: "getRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_GetRegisterInstancesWithLoadBalancer_600829, base: "/",
    url: url_GetRegisterInstancesWithLoadBalancer_600830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_600880 = ref object of OpenApiRestCall_599368
proc url_PostRemoveTags_600882(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTags_600881(path: JsonNode; query: JsonNode;
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
  var valid_600883 = query.getOrDefault("Action")
  valid_600883 = validateParameter(valid_600883, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_600883 != nil:
    section.add "Action", valid_600883
  var valid_600884 = query.getOrDefault("Version")
  valid_600884 = validateParameter(valid_600884, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600884 != nil:
    section.add "Version", valid_600884
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
  var valid_600885 = header.getOrDefault("X-Amz-Date")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Date", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Security-Token")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Security-Token", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Content-Sha256", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Algorithm")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Algorithm", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Signature")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Signature", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-SignedHeaders", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Credential")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Credential", valid_600891
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_600892 = formData.getOrDefault("Tags")
  valid_600892 = validateParameter(valid_600892, JArray, required = true, default = nil)
  if valid_600892 != nil:
    section.add "Tags", valid_600892
  var valid_600893 = formData.getOrDefault("LoadBalancerNames")
  valid_600893 = validateParameter(valid_600893, JArray, required = true, default = nil)
  if valid_600893 != nil:
    section.add "LoadBalancerNames", valid_600893
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600894: Call_PostRemoveTags_600880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_600894.validator(path, query, header, formData, body)
  let scheme = call_600894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600894.url(scheme.get, call_600894.host, call_600894.base,
                         call_600894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600894, url, valid)

proc call*(call_600895: Call_PostRemoveTags_600880; Tags: JsonNode;
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
  var query_600896 = newJObject()
  var formData_600897 = newJObject()
  if Tags != nil:
    formData_600897.add "Tags", Tags
  add(query_600896, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_600897.add "LoadBalancerNames", LoadBalancerNames
  add(query_600896, "Version", newJString(Version))
  result = call_600895.call(nil, query_600896, nil, formData_600897, nil)

var postRemoveTags* = Call_PostRemoveTags_600880(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_600881,
    base: "/", url: url_PostRemoveTags_600882, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_600863 = ref object of OpenApiRestCall_599368
proc url_GetRemoveTags_600865(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTags_600864(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_600866 = query.getOrDefault("Tags")
  valid_600866 = validateParameter(valid_600866, JArray, required = true, default = nil)
  if valid_600866 != nil:
    section.add "Tags", valid_600866
  var valid_600867 = query.getOrDefault("Action")
  valid_600867 = validateParameter(valid_600867, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_600867 != nil:
    section.add "Action", valid_600867
  var valid_600868 = query.getOrDefault("LoadBalancerNames")
  valid_600868 = validateParameter(valid_600868, JArray, required = true, default = nil)
  if valid_600868 != nil:
    section.add "LoadBalancerNames", valid_600868
  var valid_600869 = query.getOrDefault("Version")
  valid_600869 = validateParameter(valid_600869, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600869 != nil:
    section.add "Version", valid_600869
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
  var valid_600870 = header.getOrDefault("X-Amz-Date")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "X-Amz-Date", valid_600870
  var valid_600871 = header.getOrDefault("X-Amz-Security-Token")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Security-Token", valid_600871
  var valid_600872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Content-Sha256", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Algorithm")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Algorithm", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-Signature")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-Signature", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-SignedHeaders", valid_600875
  var valid_600876 = header.getOrDefault("X-Amz-Credential")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-Credential", valid_600876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600877: Call_GetRemoveTags_600863; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_600877.validator(path, query, header, formData, body)
  let scheme = call_600877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600877.url(scheme.get, call_600877.host, call_600877.base,
                         call_600877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600877, url, valid)

proc call*(call_600878: Call_GetRemoveTags_600863; Tags: JsonNode;
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
  var query_600879 = newJObject()
  if Tags != nil:
    query_600879.add "Tags", Tags
  add(query_600879, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_600879.add "LoadBalancerNames", LoadBalancerNames
  add(query_600879, "Version", newJString(Version))
  result = call_600878.call(nil, query_600879, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_600863(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_600864,
    base: "/", url: url_GetRemoveTags_600865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerListenerSSLCertificate_600916 = ref object of OpenApiRestCall_599368
proc url_PostSetLoadBalancerListenerSSLCertificate_600918(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetLoadBalancerListenerSSLCertificate_600917(path: JsonNode;
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
  var valid_600919 = query.getOrDefault("Action")
  valid_600919 = validateParameter(valid_600919, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_600919 != nil:
    section.add "Action", valid_600919
  var valid_600920 = query.getOrDefault("Version")
  valid_600920 = validateParameter(valid_600920, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600920 != nil:
    section.add "Version", valid_600920
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
  var valid_600921 = header.getOrDefault("X-Amz-Date")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = nil)
  if valid_600921 != nil:
    section.add "X-Amz-Date", valid_600921
  var valid_600922 = header.getOrDefault("X-Amz-Security-Token")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "X-Amz-Security-Token", valid_600922
  var valid_600923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "X-Amz-Content-Sha256", valid_600923
  var valid_600924 = header.getOrDefault("X-Amz-Algorithm")
  valid_600924 = validateParameter(valid_600924, JString, required = false,
                                 default = nil)
  if valid_600924 != nil:
    section.add "X-Amz-Algorithm", valid_600924
  var valid_600925 = header.getOrDefault("X-Amz-Signature")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "X-Amz-Signature", valid_600925
  var valid_600926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600926 = validateParameter(valid_600926, JString, required = false,
                                 default = nil)
  if valid_600926 != nil:
    section.add "X-Amz-SignedHeaders", valid_600926
  var valid_600927 = header.getOrDefault("X-Amz-Credential")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "X-Amz-Credential", valid_600927
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
  var valid_600928 = formData.getOrDefault("LoadBalancerPort")
  valid_600928 = validateParameter(valid_600928, JInt, required = true, default = nil)
  if valid_600928 != nil:
    section.add "LoadBalancerPort", valid_600928
  var valid_600929 = formData.getOrDefault("SSLCertificateId")
  valid_600929 = validateParameter(valid_600929, JString, required = true,
                                 default = nil)
  if valid_600929 != nil:
    section.add "SSLCertificateId", valid_600929
  var valid_600930 = formData.getOrDefault("LoadBalancerName")
  valid_600930 = validateParameter(valid_600930, JString, required = true,
                                 default = nil)
  if valid_600930 != nil:
    section.add "LoadBalancerName", valid_600930
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600931: Call_PostSetLoadBalancerListenerSSLCertificate_600916;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600931.validator(path, query, header, formData, body)
  let scheme = call_600931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600931.url(scheme.get, call_600931.host, call_600931.base,
                         call_600931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600931, url, valid)

proc call*(call_600932: Call_PostSetLoadBalancerListenerSSLCertificate_600916;
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
  var query_600933 = newJObject()
  var formData_600934 = newJObject()
  add(formData_600934, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(formData_600934, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_600933, "Action", newJString(Action))
  add(formData_600934, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600933, "Version", newJString(Version))
  result = call_600932.call(nil, query_600933, nil, formData_600934, nil)

var postSetLoadBalancerListenerSSLCertificate* = Call_PostSetLoadBalancerListenerSSLCertificate_600916(
    name: "postSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_PostSetLoadBalancerListenerSSLCertificate_600917,
    base: "/", url: url_PostSetLoadBalancerListenerSSLCertificate_600918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerListenerSSLCertificate_600898 = ref object of OpenApiRestCall_599368
proc url_GetSetLoadBalancerListenerSSLCertificate_600900(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetLoadBalancerListenerSSLCertificate_600899(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600901 = query.getOrDefault("LoadBalancerName")
  valid_600901 = validateParameter(valid_600901, JString, required = true,
                                 default = nil)
  if valid_600901 != nil:
    section.add "LoadBalancerName", valid_600901
  var valid_600902 = query.getOrDefault("SSLCertificateId")
  valid_600902 = validateParameter(valid_600902, JString, required = true,
                                 default = nil)
  if valid_600902 != nil:
    section.add "SSLCertificateId", valid_600902
  var valid_600903 = query.getOrDefault("LoadBalancerPort")
  valid_600903 = validateParameter(valid_600903, JInt, required = true, default = nil)
  if valid_600903 != nil:
    section.add "LoadBalancerPort", valid_600903
  var valid_600904 = query.getOrDefault("Action")
  valid_600904 = validateParameter(valid_600904, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_600904 != nil:
    section.add "Action", valid_600904
  var valid_600905 = query.getOrDefault("Version")
  valid_600905 = validateParameter(valid_600905, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600905 != nil:
    section.add "Version", valid_600905
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
  var valid_600906 = header.getOrDefault("X-Amz-Date")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Date", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Security-Token")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Security-Token", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Content-Sha256", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Algorithm")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Algorithm", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-Signature")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Signature", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-SignedHeaders", valid_600911
  var valid_600912 = header.getOrDefault("X-Amz-Credential")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-Credential", valid_600912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_GetSetLoadBalancerListenerSSLCertificate_600898;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600913, url, valid)

proc call*(call_600914: Call_GetSetLoadBalancerListenerSSLCertificate_600898;
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
  var query_600915 = newJObject()
  add(query_600915, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600915, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_600915, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_600915, "Action", newJString(Action))
  add(query_600915, "Version", newJString(Version))
  result = call_600914.call(nil, query_600915, nil, nil, nil)

var getSetLoadBalancerListenerSSLCertificate* = Call_GetSetLoadBalancerListenerSSLCertificate_600898(
    name: "getSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_GetSetLoadBalancerListenerSSLCertificate_600899,
    base: "/", url: url_GetSetLoadBalancerListenerSSLCertificate_600900,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesForBackendServer_600953 = ref object of OpenApiRestCall_599368
proc url_PostSetLoadBalancerPoliciesForBackendServer_600955(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetLoadBalancerPoliciesForBackendServer_600954(path: JsonNode;
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
  var valid_600956 = query.getOrDefault("Action")
  valid_600956 = validateParameter(valid_600956, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_600956 != nil:
    section.add "Action", valid_600956
  var valid_600957 = query.getOrDefault("Version")
  valid_600957 = validateParameter(valid_600957, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600957 != nil:
    section.add "Version", valid_600957
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
  var valid_600958 = header.getOrDefault("X-Amz-Date")
  valid_600958 = validateParameter(valid_600958, JString, required = false,
                                 default = nil)
  if valid_600958 != nil:
    section.add "X-Amz-Date", valid_600958
  var valid_600959 = header.getOrDefault("X-Amz-Security-Token")
  valid_600959 = validateParameter(valid_600959, JString, required = false,
                                 default = nil)
  if valid_600959 != nil:
    section.add "X-Amz-Security-Token", valid_600959
  var valid_600960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600960 = validateParameter(valid_600960, JString, required = false,
                                 default = nil)
  if valid_600960 != nil:
    section.add "X-Amz-Content-Sha256", valid_600960
  var valid_600961 = header.getOrDefault("X-Amz-Algorithm")
  valid_600961 = validateParameter(valid_600961, JString, required = false,
                                 default = nil)
  if valid_600961 != nil:
    section.add "X-Amz-Algorithm", valid_600961
  var valid_600962 = header.getOrDefault("X-Amz-Signature")
  valid_600962 = validateParameter(valid_600962, JString, required = false,
                                 default = nil)
  if valid_600962 != nil:
    section.add "X-Amz-Signature", valid_600962
  var valid_600963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600963 = validateParameter(valid_600963, JString, required = false,
                                 default = nil)
  if valid_600963 != nil:
    section.add "X-Amz-SignedHeaders", valid_600963
  var valid_600964 = header.getOrDefault("X-Amz-Credential")
  valid_600964 = validateParameter(valid_600964, JString, required = false,
                                 default = nil)
  if valid_600964 != nil:
    section.add "X-Amz-Credential", valid_600964
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
  var valid_600965 = formData.getOrDefault("PolicyNames")
  valid_600965 = validateParameter(valid_600965, JArray, required = true, default = nil)
  if valid_600965 != nil:
    section.add "PolicyNames", valid_600965
  var valid_600966 = formData.getOrDefault("InstancePort")
  valid_600966 = validateParameter(valid_600966, JInt, required = true, default = nil)
  if valid_600966 != nil:
    section.add "InstancePort", valid_600966
  var valid_600967 = formData.getOrDefault("LoadBalancerName")
  valid_600967 = validateParameter(valid_600967, JString, required = true,
                                 default = nil)
  if valid_600967 != nil:
    section.add "LoadBalancerName", valid_600967
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600968: Call_PostSetLoadBalancerPoliciesForBackendServer_600953;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600968.validator(path, query, header, formData, body)
  let scheme = call_600968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600968.url(scheme.get, call_600968.host, call_600968.base,
                         call_600968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600968, url, valid)

proc call*(call_600969: Call_PostSetLoadBalancerPoliciesForBackendServer_600953;
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
  var query_600970 = newJObject()
  var formData_600971 = newJObject()
  if PolicyNames != nil:
    formData_600971.add "PolicyNames", PolicyNames
  add(formData_600971, "InstancePort", newJInt(InstancePort))
  add(query_600970, "Action", newJString(Action))
  add(formData_600971, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600970, "Version", newJString(Version))
  result = call_600969.call(nil, query_600970, nil, formData_600971, nil)

var postSetLoadBalancerPoliciesForBackendServer* = Call_PostSetLoadBalancerPoliciesForBackendServer_600953(
    name: "postSetLoadBalancerPoliciesForBackendServer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_PostSetLoadBalancerPoliciesForBackendServer_600954,
    base: "/", url: url_PostSetLoadBalancerPoliciesForBackendServer_600955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesForBackendServer_600935 = ref object of OpenApiRestCall_599368
proc url_GetSetLoadBalancerPoliciesForBackendServer_600937(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetLoadBalancerPoliciesForBackendServer_600936(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600938 = query.getOrDefault("LoadBalancerName")
  valid_600938 = validateParameter(valid_600938, JString, required = true,
                                 default = nil)
  if valid_600938 != nil:
    section.add "LoadBalancerName", valid_600938
  var valid_600939 = query.getOrDefault("Action")
  valid_600939 = validateParameter(valid_600939, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_600939 != nil:
    section.add "Action", valid_600939
  var valid_600940 = query.getOrDefault("PolicyNames")
  valid_600940 = validateParameter(valid_600940, JArray, required = true, default = nil)
  if valid_600940 != nil:
    section.add "PolicyNames", valid_600940
  var valid_600941 = query.getOrDefault("Version")
  valid_600941 = validateParameter(valid_600941, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600941 != nil:
    section.add "Version", valid_600941
  var valid_600942 = query.getOrDefault("InstancePort")
  valid_600942 = validateParameter(valid_600942, JInt, required = true, default = nil)
  if valid_600942 != nil:
    section.add "InstancePort", valid_600942
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
  var valid_600943 = header.getOrDefault("X-Amz-Date")
  valid_600943 = validateParameter(valid_600943, JString, required = false,
                                 default = nil)
  if valid_600943 != nil:
    section.add "X-Amz-Date", valid_600943
  var valid_600944 = header.getOrDefault("X-Amz-Security-Token")
  valid_600944 = validateParameter(valid_600944, JString, required = false,
                                 default = nil)
  if valid_600944 != nil:
    section.add "X-Amz-Security-Token", valid_600944
  var valid_600945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600945 = validateParameter(valid_600945, JString, required = false,
                                 default = nil)
  if valid_600945 != nil:
    section.add "X-Amz-Content-Sha256", valid_600945
  var valid_600946 = header.getOrDefault("X-Amz-Algorithm")
  valid_600946 = validateParameter(valid_600946, JString, required = false,
                                 default = nil)
  if valid_600946 != nil:
    section.add "X-Amz-Algorithm", valid_600946
  var valid_600947 = header.getOrDefault("X-Amz-Signature")
  valid_600947 = validateParameter(valid_600947, JString, required = false,
                                 default = nil)
  if valid_600947 != nil:
    section.add "X-Amz-Signature", valid_600947
  var valid_600948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600948 = validateParameter(valid_600948, JString, required = false,
                                 default = nil)
  if valid_600948 != nil:
    section.add "X-Amz-SignedHeaders", valid_600948
  var valid_600949 = header.getOrDefault("X-Amz-Credential")
  valid_600949 = validateParameter(valid_600949, JString, required = false,
                                 default = nil)
  if valid_600949 != nil:
    section.add "X-Amz-Credential", valid_600949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600950: Call_GetSetLoadBalancerPoliciesForBackendServer_600935;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600950.validator(path, query, header, formData, body)
  let scheme = call_600950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600950.url(scheme.get, call_600950.host, call_600950.base,
                         call_600950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600950, url, valid)

proc call*(call_600951: Call_GetSetLoadBalancerPoliciesForBackendServer_600935;
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
  var query_600952 = newJObject()
  add(query_600952, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600952, "Action", newJString(Action))
  if PolicyNames != nil:
    query_600952.add "PolicyNames", PolicyNames
  add(query_600952, "Version", newJString(Version))
  add(query_600952, "InstancePort", newJInt(InstancePort))
  result = call_600951.call(nil, query_600952, nil, nil, nil)

var getSetLoadBalancerPoliciesForBackendServer* = Call_GetSetLoadBalancerPoliciesForBackendServer_600935(
    name: "getSetLoadBalancerPoliciesForBackendServer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_GetSetLoadBalancerPoliciesForBackendServer_600936,
    base: "/", url: url_GetSetLoadBalancerPoliciesForBackendServer_600937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesOfListener_600990 = ref object of OpenApiRestCall_599368
proc url_PostSetLoadBalancerPoliciesOfListener_600992(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetLoadBalancerPoliciesOfListener_600991(path: JsonNode;
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
  var valid_600993 = query.getOrDefault("Action")
  valid_600993 = validateParameter(valid_600993, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_600993 != nil:
    section.add "Action", valid_600993
  var valid_600994 = query.getOrDefault("Version")
  valid_600994 = validateParameter(valid_600994, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600994 != nil:
    section.add "Version", valid_600994
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
  var valid_600995 = header.getOrDefault("X-Amz-Date")
  valid_600995 = validateParameter(valid_600995, JString, required = false,
                                 default = nil)
  if valid_600995 != nil:
    section.add "X-Amz-Date", valid_600995
  var valid_600996 = header.getOrDefault("X-Amz-Security-Token")
  valid_600996 = validateParameter(valid_600996, JString, required = false,
                                 default = nil)
  if valid_600996 != nil:
    section.add "X-Amz-Security-Token", valid_600996
  var valid_600997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600997 = validateParameter(valid_600997, JString, required = false,
                                 default = nil)
  if valid_600997 != nil:
    section.add "X-Amz-Content-Sha256", valid_600997
  var valid_600998 = header.getOrDefault("X-Amz-Algorithm")
  valid_600998 = validateParameter(valid_600998, JString, required = false,
                                 default = nil)
  if valid_600998 != nil:
    section.add "X-Amz-Algorithm", valid_600998
  var valid_600999 = header.getOrDefault("X-Amz-Signature")
  valid_600999 = validateParameter(valid_600999, JString, required = false,
                                 default = nil)
  if valid_600999 != nil:
    section.add "X-Amz-Signature", valid_600999
  var valid_601000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601000 = validateParameter(valid_601000, JString, required = false,
                                 default = nil)
  if valid_601000 != nil:
    section.add "X-Amz-SignedHeaders", valid_601000
  var valid_601001 = header.getOrDefault("X-Amz-Credential")
  valid_601001 = validateParameter(valid_601001, JString, required = false,
                                 default = nil)
  if valid_601001 != nil:
    section.add "X-Amz-Credential", valid_601001
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
  var valid_601002 = formData.getOrDefault("LoadBalancerPort")
  valid_601002 = validateParameter(valid_601002, JInt, required = true, default = nil)
  if valid_601002 != nil:
    section.add "LoadBalancerPort", valid_601002
  var valid_601003 = formData.getOrDefault("PolicyNames")
  valid_601003 = validateParameter(valid_601003, JArray, required = true, default = nil)
  if valid_601003 != nil:
    section.add "PolicyNames", valid_601003
  var valid_601004 = formData.getOrDefault("LoadBalancerName")
  valid_601004 = validateParameter(valid_601004, JString, required = true,
                                 default = nil)
  if valid_601004 != nil:
    section.add "LoadBalancerName", valid_601004
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601005: Call_PostSetLoadBalancerPoliciesOfListener_600990;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601005.validator(path, query, header, formData, body)
  let scheme = call_601005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601005.url(scheme.get, call_601005.host, call_601005.base,
                         call_601005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601005, url, valid)

proc call*(call_601006: Call_PostSetLoadBalancerPoliciesOfListener_600990;
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
  var query_601007 = newJObject()
  var formData_601008 = newJObject()
  add(formData_601008, "LoadBalancerPort", newJInt(LoadBalancerPort))
  if PolicyNames != nil:
    formData_601008.add "PolicyNames", PolicyNames
  add(query_601007, "Action", newJString(Action))
  add(formData_601008, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601007, "Version", newJString(Version))
  result = call_601006.call(nil, query_601007, nil, formData_601008, nil)

var postSetLoadBalancerPoliciesOfListener* = Call_PostSetLoadBalancerPoliciesOfListener_600990(
    name: "postSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_PostSetLoadBalancerPoliciesOfListener_600991, base: "/",
    url: url_PostSetLoadBalancerPoliciesOfListener_600992,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesOfListener_600972 = ref object of OpenApiRestCall_599368
proc url_GetSetLoadBalancerPoliciesOfListener_600974(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetLoadBalancerPoliciesOfListener_600973(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600975 = query.getOrDefault("LoadBalancerName")
  valid_600975 = validateParameter(valid_600975, JString, required = true,
                                 default = nil)
  if valid_600975 != nil:
    section.add "LoadBalancerName", valid_600975
  var valid_600976 = query.getOrDefault("LoadBalancerPort")
  valid_600976 = validateParameter(valid_600976, JInt, required = true, default = nil)
  if valid_600976 != nil:
    section.add "LoadBalancerPort", valid_600976
  var valid_600977 = query.getOrDefault("Action")
  valid_600977 = validateParameter(valid_600977, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_600977 != nil:
    section.add "Action", valid_600977
  var valid_600978 = query.getOrDefault("PolicyNames")
  valid_600978 = validateParameter(valid_600978, JArray, required = true, default = nil)
  if valid_600978 != nil:
    section.add "PolicyNames", valid_600978
  var valid_600979 = query.getOrDefault("Version")
  valid_600979 = validateParameter(valid_600979, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600979 != nil:
    section.add "Version", valid_600979
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
  var valid_600980 = header.getOrDefault("X-Amz-Date")
  valid_600980 = validateParameter(valid_600980, JString, required = false,
                                 default = nil)
  if valid_600980 != nil:
    section.add "X-Amz-Date", valid_600980
  var valid_600981 = header.getOrDefault("X-Amz-Security-Token")
  valid_600981 = validateParameter(valid_600981, JString, required = false,
                                 default = nil)
  if valid_600981 != nil:
    section.add "X-Amz-Security-Token", valid_600981
  var valid_600982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600982 = validateParameter(valid_600982, JString, required = false,
                                 default = nil)
  if valid_600982 != nil:
    section.add "X-Amz-Content-Sha256", valid_600982
  var valid_600983 = header.getOrDefault("X-Amz-Algorithm")
  valid_600983 = validateParameter(valid_600983, JString, required = false,
                                 default = nil)
  if valid_600983 != nil:
    section.add "X-Amz-Algorithm", valid_600983
  var valid_600984 = header.getOrDefault("X-Amz-Signature")
  valid_600984 = validateParameter(valid_600984, JString, required = false,
                                 default = nil)
  if valid_600984 != nil:
    section.add "X-Amz-Signature", valid_600984
  var valid_600985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600985 = validateParameter(valid_600985, JString, required = false,
                                 default = nil)
  if valid_600985 != nil:
    section.add "X-Amz-SignedHeaders", valid_600985
  var valid_600986 = header.getOrDefault("X-Amz-Credential")
  valid_600986 = validateParameter(valid_600986, JString, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "X-Amz-Credential", valid_600986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600987: Call_GetSetLoadBalancerPoliciesOfListener_600972;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600987.validator(path, query, header, formData, body)
  let scheme = call_600987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600987.url(scheme.get, call_600987.host, call_600987.base,
                         call_600987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600987, url, valid)

proc call*(call_600988: Call_GetSetLoadBalancerPoliciesOfListener_600972;
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
  var query_600989 = newJObject()
  add(query_600989, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_600989, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_600989, "Action", newJString(Action))
  if PolicyNames != nil:
    query_600989.add "PolicyNames", PolicyNames
  add(query_600989, "Version", newJString(Version))
  result = call_600988.call(nil, query_600989, nil, nil, nil)

var getSetLoadBalancerPoliciesOfListener* = Call_GetSetLoadBalancerPoliciesOfListener_600972(
    name: "getSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_GetSetLoadBalancerPoliciesOfListener_600973, base: "/",
    url: url_GetSetLoadBalancerPoliciesOfListener_600974,
    schemes: {Scheme.Https, Scheme.Http})
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
