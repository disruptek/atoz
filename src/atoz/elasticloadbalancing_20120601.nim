
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddTags_592975 = ref object of OpenApiRestCall_592364
proc url_PostAddTags_592977(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTags_592976(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592978 = query.getOrDefault("Action")
  valid_592978 = validateParameter(valid_592978, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_592978 != nil:
    section.add "Action", valid_592978
  var valid_592979 = query.getOrDefault("Version")
  valid_592979 = validateParameter(valid_592979, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_592979 != nil:
    section.add "Version", valid_592979
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
  var valid_592980 = header.getOrDefault("X-Amz-Signature")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Signature", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Content-Sha256", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Date")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Date", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Credential")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Credential", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Security-Token")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Security-Token", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Algorithm")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Algorithm", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-SignedHeaders", valid_592986
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Tags: JArray (required)
  ##       : The tags.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_592987 = formData.getOrDefault("LoadBalancerNames")
  valid_592987 = validateParameter(valid_592987, JArray, required = true, default = nil)
  if valid_592987 != nil:
    section.add "LoadBalancerNames", valid_592987
  var valid_592988 = formData.getOrDefault("Tags")
  valid_592988 = validateParameter(valid_592988, JArray, required = true, default = nil)
  if valid_592988 != nil:
    section.add "Tags", valid_592988
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592989: Call_PostAddTags_592975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_592989.validator(path, query, header, formData, body)
  let scheme = call_592989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592989.url(scheme.get, call_592989.host, call_592989.base,
                         call_592989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592989, url, valid)

proc call*(call_592990: Call_PostAddTags_592975; LoadBalancerNames: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2012-06-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   Version: string (required)
  var query_592991 = newJObject()
  var formData_592992 = newJObject()
  if LoadBalancerNames != nil:
    formData_592992.add "LoadBalancerNames", LoadBalancerNames
  add(query_592991, "Action", newJString(Action))
  if Tags != nil:
    formData_592992.add "Tags", Tags
  add(query_592991, "Version", newJString(Version))
  result = call_592990.call(nil, query_592991, nil, formData_592992, nil)

var postAddTags* = Call_PostAddTags_592975(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_592976,
                                        base: "/", url: url_PostAddTags_592977,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_592703 = ref object of OpenApiRestCall_592364
proc url_GetAddTags_592705(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTags_592704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592817 = query.getOrDefault("Tags")
  valid_592817 = validateParameter(valid_592817, JArray, required = true, default = nil)
  if valid_592817 != nil:
    section.add "Tags", valid_592817
  var valid_592831 = query.getOrDefault("Action")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_592831 != nil:
    section.add "Action", valid_592831
  var valid_592832 = query.getOrDefault("Version")
  valid_592832 = validateParameter(valid_592832, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_592832 != nil:
    section.add "Version", valid_592832
  var valid_592833 = query.getOrDefault("LoadBalancerNames")
  valid_592833 = validateParameter(valid_592833, JArray, required = true, default = nil)
  if valid_592833 != nil:
    section.add "LoadBalancerNames", valid_592833
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
  var valid_592834 = header.getOrDefault("X-Amz-Signature")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Signature", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Content-Sha256", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Date")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Date", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Credential")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Credential", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Security-Token")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Security-Token", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-Algorithm")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-Algorithm", valid_592839
  var valid_592840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592840 = validateParameter(valid_592840, JString, required = false,
                                 default = nil)
  if valid_592840 != nil:
    section.add "X-Amz-SignedHeaders", valid_592840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592863: Call_GetAddTags_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_592863.validator(path, query, header, formData, body)
  let scheme = call_592863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592863.url(scheme.get, call_592863.host, call_592863.base,
                         call_592863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592863, url, valid)

proc call*(call_592934: Call_GetAddTags_592703; Tags: JsonNode;
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
  var query_592935 = newJObject()
  if Tags != nil:
    query_592935.add "Tags", Tags
  add(query_592935, "Action", newJString(Action))
  add(query_592935, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_592935.add "LoadBalancerNames", LoadBalancerNames
  result = call_592934.call(nil, query_592935, nil, nil, nil)

var getAddTags* = Call_GetAddTags_592703(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_592704,
                                      base: "/", url: url_GetAddTags_592705,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplySecurityGroupsToLoadBalancer_593010 = ref object of OpenApiRestCall_592364
proc url_PostApplySecurityGroupsToLoadBalancer_593012(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostApplySecurityGroupsToLoadBalancer_593011(path: JsonNode;
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
  var valid_593013 = query.getOrDefault("Action")
  valid_593013 = validateParameter(valid_593013, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_593013 != nil:
    section.add "Action", valid_593013
  var valid_593014 = query.getOrDefault("Version")
  valid_593014 = validateParameter(valid_593014, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593014 != nil:
    section.add "Version", valid_593014
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
  var valid_593015 = header.getOrDefault("X-Amz-Signature")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Signature", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Content-Sha256", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Date")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Date", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Credential")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Credential", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Security-Token")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Security-Token", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Algorithm")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Algorithm", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-SignedHeaders", valid_593021
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_593022 = formData.getOrDefault("SecurityGroups")
  valid_593022 = validateParameter(valid_593022, JArray, required = true, default = nil)
  if valid_593022 != nil:
    section.add "SecurityGroups", valid_593022
  var valid_593023 = formData.getOrDefault("LoadBalancerName")
  valid_593023 = validateParameter(valid_593023, JString, required = true,
                                 default = nil)
  if valid_593023 != nil:
    section.add "LoadBalancerName", valid_593023
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593024: Call_PostApplySecurityGroupsToLoadBalancer_593010;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593024.validator(path, query, header, formData, body)
  let scheme = call_593024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593024.url(scheme.get, call_593024.host, call_593024.base,
                         call_593024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593024, url, valid)

proc call*(call_593025: Call_PostApplySecurityGroupsToLoadBalancer_593010;
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
  var query_593026 = newJObject()
  var formData_593027 = newJObject()
  if SecurityGroups != nil:
    formData_593027.add "SecurityGroups", SecurityGroups
  add(formData_593027, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593026, "Action", newJString(Action))
  add(query_593026, "Version", newJString(Version))
  result = call_593025.call(nil, query_593026, nil, formData_593027, nil)

var postApplySecurityGroupsToLoadBalancer* = Call_PostApplySecurityGroupsToLoadBalancer_593010(
    name: "postApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_PostApplySecurityGroupsToLoadBalancer_593011, base: "/",
    url: url_PostApplySecurityGroupsToLoadBalancer_593012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplySecurityGroupsToLoadBalancer_592993 = ref object of OpenApiRestCall_592364
proc url_GetApplySecurityGroupsToLoadBalancer_592995(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApplySecurityGroupsToLoadBalancer_592994(path: JsonNode;
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
  var valid_592996 = query.getOrDefault("SecurityGroups")
  valid_592996 = validateParameter(valid_592996, JArray, required = true, default = nil)
  if valid_592996 != nil:
    section.add "SecurityGroups", valid_592996
  var valid_592997 = query.getOrDefault("LoadBalancerName")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = nil)
  if valid_592997 != nil:
    section.add "LoadBalancerName", valid_592997
  var valid_592998 = query.getOrDefault("Action")
  valid_592998 = validateParameter(valid_592998, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_592998 != nil:
    section.add "Action", valid_592998
  var valid_592999 = query.getOrDefault("Version")
  valid_592999 = validateParameter(valid_592999, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_592999 != nil:
    section.add "Version", valid_592999
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
  var valid_593000 = header.getOrDefault("X-Amz-Signature")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Signature", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Content-Sha256", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Date")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Date", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Credential")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Credential", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Security-Token")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Security-Token", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Algorithm")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Algorithm", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-SignedHeaders", valid_593006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593007: Call_GetApplySecurityGroupsToLoadBalancer_592993;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593007.validator(path, query, header, formData, body)
  let scheme = call_593007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593007.url(scheme.get, call_593007.host, call_593007.base,
                         call_593007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593007, url, valid)

proc call*(call_593008: Call_GetApplySecurityGroupsToLoadBalancer_592993;
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
  var query_593009 = newJObject()
  if SecurityGroups != nil:
    query_593009.add "SecurityGroups", SecurityGroups
  add(query_593009, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593009, "Action", newJString(Action))
  add(query_593009, "Version", newJString(Version))
  result = call_593008.call(nil, query_593009, nil, nil, nil)

var getApplySecurityGroupsToLoadBalancer* = Call_GetApplySecurityGroupsToLoadBalancer_592993(
    name: "getApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_GetApplySecurityGroupsToLoadBalancer_592994, base: "/",
    url: url_GetApplySecurityGroupsToLoadBalancer_592995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAttachLoadBalancerToSubnets_593045 = ref object of OpenApiRestCall_592364
proc url_PostAttachLoadBalancerToSubnets_593047(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAttachLoadBalancerToSubnets_593046(path: JsonNode;
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
  var valid_593048 = query.getOrDefault("Action")
  valid_593048 = validateParameter(valid_593048, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_593048 != nil:
    section.add "Action", valid_593048
  var valid_593049 = query.getOrDefault("Version")
  valid_593049 = validateParameter(valid_593049, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593049 != nil:
    section.add "Version", valid_593049
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
  var valid_593050 = header.getOrDefault("X-Amz-Signature")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Signature", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Content-Sha256", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Date")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Date", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Credential")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Credential", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Security-Token")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Security-Token", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Algorithm")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Algorithm", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-SignedHeaders", valid_593056
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_593057 = formData.getOrDefault("Subnets")
  valid_593057 = validateParameter(valid_593057, JArray, required = true, default = nil)
  if valid_593057 != nil:
    section.add "Subnets", valid_593057
  var valid_593058 = formData.getOrDefault("LoadBalancerName")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = nil)
  if valid_593058 != nil:
    section.add "LoadBalancerName", valid_593058
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593059: Call_PostAttachLoadBalancerToSubnets_593045;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_PostAttachLoadBalancerToSubnets_593045;
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
  var query_593061 = newJObject()
  var formData_593062 = newJObject()
  if Subnets != nil:
    formData_593062.add "Subnets", Subnets
  add(formData_593062, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593061, "Action", newJString(Action))
  add(query_593061, "Version", newJString(Version))
  result = call_593060.call(nil, query_593061, nil, formData_593062, nil)

var postAttachLoadBalancerToSubnets* = Call_PostAttachLoadBalancerToSubnets_593045(
    name: "postAttachLoadBalancerToSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_PostAttachLoadBalancerToSubnets_593046, base: "/",
    url: url_PostAttachLoadBalancerToSubnets_593047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttachLoadBalancerToSubnets_593028 = ref object of OpenApiRestCall_592364
proc url_GetAttachLoadBalancerToSubnets_593030(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAttachLoadBalancerToSubnets_593029(path: JsonNode;
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
  var valid_593031 = query.getOrDefault("LoadBalancerName")
  valid_593031 = validateParameter(valid_593031, JString, required = true,
                                 default = nil)
  if valid_593031 != nil:
    section.add "LoadBalancerName", valid_593031
  var valid_593032 = query.getOrDefault("Action")
  valid_593032 = validateParameter(valid_593032, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_593032 != nil:
    section.add "Action", valid_593032
  var valid_593033 = query.getOrDefault("Subnets")
  valid_593033 = validateParameter(valid_593033, JArray, required = true, default = nil)
  if valid_593033 != nil:
    section.add "Subnets", valid_593033
  var valid_593034 = query.getOrDefault("Version")
  valid_593034 = validateParameter(valid_593034, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593034 != nil:
    section.add "Version", valid_593034
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
  var valid_593035 = header.getOrDefault("X-Amz-Signature")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Signature", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Content-Sha256", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Date")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Date", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Credential")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Credential", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Security-Token")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Security-Token", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Algorithm")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Algorithm", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-SignedHeaders", valid_593041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593042: Call_GetAttachLoadBalancerToSubnets_593028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593042.validator(path, query, header, formData, body)
  let scheme = call_593042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593042.url(scheme.get, call_593042.host, call_593042.base,
                         call_593042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593042, url, valid)

proc call*(call_593043: Call_GetAttachLoadBalancerToSubnets_593028;
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
  var query_593044 = newJObject()
  add(query_593044, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593044, "Action", newJString(Action))
  if Subnets != nil:
    query_593044.add "Subnets", Subnets
  add(query_593044, "Version", newJString(Version))
  result = call_593043.call(nil, query_593044, nil, nil, nil)

var getAttachLoadBalancerToSubnets* = Call_GetAttachLoadBalancerToSubnets_593028(
    name: "getAttachLoadBalancerToSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_GetAttachLoadBalancerToSubnets_593029, base: "/",
    url: url_GetAttachLoadBalancerToSubnets_593030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfigureHealthCheck_593084 = ref object of OpenApiRestCall_592364
proc url_PostConfigureHealthCheck_593086(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostConfigureHealthCheck_593085(path: JsonNode; query: JsonNode;
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
  var valid_593087 = query.getOrDefault("Action")
  valid_593087 = validateParameter(valid_593087, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_593087 != nil:
    section.add "Action", valid_593087
  var valid_593088 = query.getOrDefault("Version")
  valid_593088 = validateParameter(valid_593088, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593088 != nil:
    section.add "Version", valid_593088
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
  var valid_593089 = header.getOrDefault("X-Amz-Signature")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Signature", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Content-Sha256", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Date")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Date", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Credential")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Credential", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Security-Token")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Security-Token", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Algorithm")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Algorithm", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-SignedHeaders", valid_593095
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
  var valid_593096 = formData.getOrDefault("HealthCheck.Interval")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "HealthCheck.Interval", valid_593096
  var valid_593097 = formData.getOrDefault("HealthCheck.HealthyThreshold")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_593097
  var valid_593098 = formData.getOrDefault("HealthCheck.Timeout")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "HealthCheck.Timeout", valid_593098
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_593099 = formData.getOrDefault("LoadBalancerName")
  valid_593099 = validateParameter(valid_593099, JString, required = true,
                                 default = nil)
  if valid_593099 != nil:
    section.add "LoadBalancerName", valid_593099
  var valid_593100 = formData.getOrDefault("HealthCheck.Target")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "HealthCheck.Target", valid_593100
  var valid_593101 = formData.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_593101
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593102: Call_PostConfigureHealthCheck_593084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593102.validator(path, query, header, formData, body)
  let scheme = call_593102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593102.url(scheme.get, call_593102.host, call_593102.base,
                         call_593102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593102, url, valid)

proc call*(call_593103: Call_PostConfigureHealthCheck_593084;
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
  var query_593104 = newJObject()
  var formData_593105 = newJObject()
  add(formData_593105, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(formData_593105, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(formData_593105, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(formData_593105, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593104, "Action", newJString(Action))
  add(formData_593105, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_593104, "Version", newJString(Version))
  add(formData_593105, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  result = call_593103.call(nil, query_593104, nil, formData_593105, nil)

var postConfigureHealthCheck* = Call_PostConfigureHealthCheck_593084(
    name: "postConfigureHealthCheck", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_PostConfigureHealthCheck_593085, base: "/",
    url: url_PostConfigureHealthCheck_593086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigureHealthCheck_593063 = ref object of OpenApiRestCall_592364
proc url_GetConfigureHealthCheck_593065(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConfigureHealthCheck_593064(path: JsonNode; query: JsonNode;
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
  var valid_593066 = query.getOrDefault("HealthCheck.Interval")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "HealthCheck.Interval", valid_593066
  var valid_593067 = query.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_593067
  var valid_593068 = query.getOrDefault("HealthCheck.Timeout")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "HealthCheck.Timeout", valid_593068
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_593069 = query.getOrDefault("LoadBalancerName")
  valid_593069 = validateParameter(valid_593069, JString, required = true,
                                 default = nil)
  if valid_593069 != nil:
    section.add "LoadBalancerName", valid_593069
  var valid_593070 = query.getOrDefault("Action")
  valid_593070 = validateParameter(valid_593070, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_593070 != nil:
    section.add "Action", valid_593070
  var valid_593071 = query.getOrDefault("HealthCheck.Target")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "HealthCheck.Target", valid_593071
  var valid_593072 = query.getOrDefault("HealthCheck.HealthyThreshold")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_593072
  var valid_593073 = query.getOrDefault("Version")
  valid_593073 = validateParameter(valid_593073, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593073 != nil:
    section.add "Version", valid_593073
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
  var valid_593074 = header.getOrDefault("X-Amz-Signature")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Signature", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Content-Sha256", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Date")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Date", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Credential")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Credential", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Security-Token")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Security-Token", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Algorithm")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Algorithm", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-SignedHeaders", valid_593080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593081: Call_GetConfigureHealthCheck_593063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593081.validator(path, query, header, formData, body)
  let scheme = call_593081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593081.url(scheme.get, call_593081.host, call_593081.base,
                         call_593081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593081, url, valid)

proc call*(call_593082: Call_GetConfigureHealthCheck_593063;
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
  var query_593083 = newJObject()
  add(query_593083, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(query_593083, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(query_593083, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_593083, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593083, "Action", newJString(Action))
  add(query_593083, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_593083, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(query_593083, "Version", newJString(Version))
  result = call_593082.call(nil, query_593083, nil, nil, nil)

var getConfigureHealthCheck* = Call_GetConfigureHealthCheck_593063(
    name: "getConfigureHealthCheck", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_GetConfigureHealthCheck_593064, base: "/",
    url: url_GetConfigureHealthCheck_593065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateAppCookieStickinessPolicy_593124 = ref object of OpenApiRestCall_592364
proc url_PostCreateAppCookieStickinessPolicy_593126(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateAppCookieStickinessPolicy_593125(path: JsonNode;
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
  var valid_593127 = query.getOrDefault("Action")
  valid_593127 = validateParameter(valid_593127, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_593127 != nil:
    section.add "Action", valid_593127
  var valid_593128 = query.getOrDefault("Version")
  valid_593128 = validateParameter(valid_593128, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593128 != nil:
    section.add "Version", valid_593128
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
  var valid_593129 = header.getOrDefault("X-Amz-Signature")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Signature", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Content-Sha256", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Date")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Date", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Credential")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Credential", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Security-Token")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Security-Token", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-Algorithm")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Algorithm", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-SignedHeaders", valid_593135
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
  var valid_593136 = formData.getOrDefault("CookieName")
  valid_593136 = validateParameter(valid_593136, JString, required = true,
                                 default = nil)
  if valid_593136 != nil:
    section.add "CookieName", valid_593136
  var valid_593137 = formData.getOrDefault("LoadBalancerName")
  valid_593137 = validateParameter(valid_593137, JString, required = true,
                                 default = nil)
  if valid_593137 != nil:
    section.add "LoadBalancerName", valid_593137
  var valid_593138 = formData.getOrDefault("PolicyName")
  valid_593138 = validateParameter(valid_593138, JString, required = true,
                                 default = nil)
  if valid_593138 != nil:
    section.add "PolicyName", valid_593138
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593139: Call_PostCreateAppCookieStickinessPolicy_593124;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593139.validator(path, query, header, formData, body)
  let scheme = call_593139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593139.url(scheme.get, call_593139.host, call_593139.base,
                         call_593139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593139, url, valid)

proc call*(call_593140: Call_PostCreateAppCookieStickinessPolicy_593124;
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
  var query_593141 = newJObject()
  var formData_593142 = newJObject()
  add(formData_593142, "CookieName", newJString(CookieName))
  add(formData_593142, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593141, "Action", newJString(Action))
  add(query_593141, "Version", newJString(Version))
  add(formData_593142, "PolicyName", newJString(PolicyName))
  result = call_593140.call(nil, query_593141, nil, formData_593142, nil)

var postCreateAppCookieStickinessPolicy* = Call_PostCreateAppCookieStickinessPolicy_593124(
    name: "postCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_PostCreateAppCookieStickinessPolicy_593125, base: "/",
    url: url_PostCreateAppCookieStickinessPolicy_593126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateAppCookieStickinessPolicy_593106 = ref object of OpenApiRestCall_592364
proc url_GetCreateAppCookieStickinessPolicy_593108(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateAppCookieStickinessPolicy_593107(path: JsonNode;
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
  var valid_593109 = query.getOrDefault("PolicyName")
  valid_593109 = validateParameter(valid_593109, JString, required = true,
                                 default = nil)
  if valid_593109 != nil:
    section.add "PolicyName", valid_593109
  var valid_593110 = query.getOrDefault("CookieName")
  valid_593110 = validateParameter(valid_593110, JString, required = true,
                                 default = nil)
  if valid_593110 != nil:
    section.add "CookieName", valid_593110
  var valid_593111 = query.getOrDefault("LoadBalancerName")
  valid_593111 = validateParameter(valid_593111, JString, required = true,
                                 default = nil)
  if valid_593111 != nil:
    section.add "LoadBalancerName", valid_593111
  var valid_593112 = query.getOrDefault("Action")
  valid_593112 = validateParameter(valid_593112, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_593112 != nil:
    section.add "Action", valid_593112
  var valid_593113 = query.getOrDefault("Version")
  valid_593113 = validateParameter(valid_593113, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593113 != nil:
    section.add "Version", valid_593113
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
  var valid_593114 = header.getOrDefault("X-Amz-Signature")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Signature", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Content-Sha256", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Date")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Date", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Credential")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Credential", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Security-Token")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Security-Token", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Algorithm")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Algorithm", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-SignedHeaders", valid_593120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593121: Call_GetCreateAppCookieStickinessPolicy_593106;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593121.validator(path, query, header, formData, body)
  let scheme = call_593121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593121.url(scheme.get, call_593121.host, call_593121.base,
                         call_593121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593121, url, valid)

proc call*(call_593122: Call_GetCreateAppCookieStickinessPolicy_593106;
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
  var query_593123 = newJObject()
  add(query_593123, "PolicyName", newJString(PolicyName))
  add(query_593123, "CookieName", newJString(CookieName))
  add(query_593123, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593123, "Action", newJString(Action))
  add(query_593123, "Version", newJString(Version))
  result = call_593122.call(nil, query_593123, nil, nil, nil)

var getCreateAppCookieStickinessPolicy* = Call_GetCreateAppCookieStickinessPolicy_593106(
    name: "getCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_GetCreateAppCookieStickinessPolicy_593107, base: "/",
    url: url_GetCreateAppCookieStickinessPolicy_593108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLBCookieStickinessPolicy_593161 = ref object of OpenApiRestCall_592364
proc url_PostCreateLBCookieStickinessPolicy_593163(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLBCookieStickinessPolicy_593162(path: JsonNode;
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
  var valid_593164 = query.getOrDefault("Action")
  valid_593164 = validateParameter(valid_593164, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_593164 != nil:
    section.add "Action", valid_593164
  var valid_593165 = query.getOrDefault("Version")
  valid_593165 = validateParameter(valid_593165, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593165 != nil:
    section.add "Version", valid_593165
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
  var valid_593166 = header.getOrDefault("X-Amz-Signature")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Signature", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Content-Sha256", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Date")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Date", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Credential")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Credential", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Security-Token")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Security-Token", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Algorithm")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Algorithm", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-SignedHeaders", valid_593172
  result.add "header", section
  ## parameters in `formData` object:
  ##   CookieExpirationPeriod: JInt
  ##                         : The time period, in seconds, after which the cookie should be considered stale. If you do not specify this parameter, the default value is 0, which indicates that the sticky session should last for the duration of the browser session.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  section = newJObject()
  var valid_593173 = formData.getOrDefault("CookieExpirationPeriod")
  valid_593173 = validateParameter(valid_593173, JInt, required = false, default = nil)
  if valid_593173 != nil:
    section.add "CookieExpirationPeriod", valid_593173
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_593174 = formData.getOrDefault("LoadBalancerName")
  valid_593174 = validateParameter(valid_593174, JString, required = true,
                                 default = nil)
  if valid_593174 != nil:
    section.add "LoadBalancerName", valid_593174
  var valid_593175 = formData.getOrDefault("PolicyName")
  valid_593175 = validateParameter(valid_593175, JString, required = true,
                                 default = nil)
  if valid_593175 != nil:
    section.add "PolicyName", valid_593175
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593176: Call_PostCreateLBCookieStickinessPolicy_593161;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593176.validator(path, query, header, formData, body)
  let scheme = call_593176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593176.url(scheme.get, call_593176.host, call_593176.base,
                         call_593176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593176, url, valid)

proc call*(call_593177: Call_PostCreateLBCookieStickinessPolicy_593161;
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
  var query_593178 = newJObject()
  var formData_593179 = newJObject()
  add(formData_593179, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(formData_593179, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593178, "Action", newJString(Action))
  add(query_593178, "Version", newJString(Version))
  add(formData_593179, "PolicyName", newJString(PolicyName))
  result = call_593177.call(nil, query_593178, nil, formData_593179, nil)

var postCreateLBCookieStickinessPolicy* = Call_PostCreateLBCookieStickinessPolicy_593161(
    name: "postCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_PostCreateLBCookieStickinessPolicy_593162, base: "/",
    url: url_PostCreateLBCookieStickinessPolicy_593163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLBCookieStickinessPolicy_593143 = ref object of OpenApiRestCall_592364
proc url_GetCreateLBCookieStickinessPolicy_593145(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLBCookieStickinessPolicy_593144(path: JsonNode;
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
  var valid_593146 = query.getOrDefault("CookieExpirationPeriod")
  valid_593146 = validateParameter(valid_593146, JInt, required = false, default = nil)
  if valid_593146 != nil:
    section.add "CookieExpirationPeriod", valid_593146
  assert query != nil,
        "query argument is necessary due to required `PolicyName` field"
  var valid_593147 = query.getOrDefault("PolicyName")
  valid_593147 = validateParameter(valid_593147, JString, required = true,
                                 default = nil)
  if valid_593147 != nil:
    section.add "PolicyName", valid_593147
  var valid_593148 = query.getOrDefault("LoadBalancerName")
  valid_593148 = validateParameter(valid_593148, JString, required = true,
                                 default = nil)
  if valid_593148 != nil:
    section.add "LoadBalancerName", valid_593148
  var valid_593149 = query.getOrDefault("Action")
  valid_593149 = validateParameter(valid_593149, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_593149 != nil:
    section.add "Action", valid_593149
  var valid_593150 = query.getOrDefault("Version")
  valid_593150 = validateParameter(valid_593150, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593150 != nil:
    section.add "Version", valid_593150
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
  var valid_593151 = header.getOrDefault("X-Amz-Signature")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Signature", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Content-Sha256", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Date")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Date", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Credential")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Credential", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Security-Token")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Security-Token", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Algorithm")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Algorithm", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-SignedHeaders", valid_593157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593158: Call_GetCreateLBCookieStickinessPolicy_593143;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593158.validator(path, query, header, formData, body)
  let scheme = call_593158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593158.url(scheme.get, call_593158.host, call_593158.base,
                         call_593158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593158, url, valid)

proc call*(call_593159: Call_GetCreateLBCookieStickinessPolicy_593143;
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
  var query_593160 = newJObject()
  add(query_593160, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(query_593160, "PolicyName", newJString(PolicyName))
  add(query_593160, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593160, "Action", newJString(Action))
  add(query_593160, "Version", newJString(Version))
  result = call_593159.call(nil, query_593160, nil, nil, nil)

var getCreateLBCookieStickinessPolicy* = Call_GetCreateLBCookieStickinessPolicy_593143(
    name: "getCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_GetCreateLBCookieStickinessPolicy_593144, base: "/",
    url: url_GetCreateLBCookieStickinessPolicy_593145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_593202 = ref object of OpenApiRestCall_592364
proc url_PostCreateLoadBalancer_593204(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLoadBalancer_593203(path: JsonNode; query: JsonNode;
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
  var valid_593205 = query.getOrDefault("Action")
  valid_593205 = validateParameter(valid_593205, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_593205 != nil:
    section.add "Action", valid_593205
  var valid_593206 = query.getOrDefault("Version")
  valid_593206 = validateParameter(valid_593206, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593206 != nil:
    section.add "Version", valid_593206
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
  var valid_593207 = header.getOrDefault("X-Amz-Signature")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Signature", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Content-Sha256", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Date")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Date", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Credential")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Credential", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-Security-Token")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Security-Token", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-Algorithm")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-Algorithm", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-SignedHeaders", valid_593213
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
  var valid_593214 = formData.getOrDefault("Scheme")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "Scheme", valid_593214
  var valid_593215 = formData.getOrDefault("SecurityGroups")
  valid_593215 = validateParameter(valid_593215, JArray, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "SecurityGroups", valid_593215
  var valid_593216 = formData.getOrDefault("AvailabilityZones")
  valid_593216 = validateParameter(valid_593216, JArray, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "AvailabilityZones", valid_593216
  var valid_593217 = formData.getOrDefault("Subnets")
  valid_593217 = validateParameter(valid_593217, JArray, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "Subnets", valid_593217
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_593218 = formData.getOrDefault("LoadBalancerName")
  valid_593218 = validateParameter(valid_593218, JString, required = true,
                                 default = nil)
  if valid_593218 != nil:
    section.add "LoadBalancerName", valid_593218
  var valid_593219 = formData.getOrDefault("Listeners")
  valid_593219 = validateParameter(valid_593219, JArray, required = true, default = nil)
  if valid_593219 != nil:
    section.add "Listeners", valid_593219
  var valid_593220 = formData.getOrDefault("Tags")
  valid_593220 = validateParameter(valid_593220, JArray, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "Tags", valid_593220
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593221: Call_PostCreateLoadBalancer_593202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593221.validator(path, query, header, formData, body)
  let scheme = call_593221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593221.url(scheme.get, call_593221.host, call_593221.base,
                         call_593221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593221, url, valid)

proc call*(call_593222: Call_PostCreateLoadBalancer_593202;
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
  var query_593223 = newJObject()
  var formData_593224 = newJObject()
  add(formData_593224, "Scheme", newJString(Scheme))
  if SecurityGroups != nil:
    formData_593224.add "SecurityGroups", SecurityGroups
  if AvailabilityZones != nil:
    formData_593224.add "AvailabilityZones", AvailabilityZones
  if Subnets != nil:
    formData_593224.add "Subnets", Subnets
  add(formData_593224, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_593224.add "Listeners", Listeners
  add(query_593223, "Action", newJString(Action))
  if Tags != nil:
    formData_593224.add "Tags", Tags
  add(query_593223, "Version", newJString(Version))
  result = call_593222.call(nil, query_593223, nil, formData_593224, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_593202(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_593203, base: "/",
    url: url_PostCreateLoadBalancer_593204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_593180 = ref object of OpenApiRestCall_592364
proc url_GetCreateLoadBalancer_593182(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLoadBalancer_593181(path: JsonNode; query: JsonNode;
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
  var valid_593183 = query.getOrDefault("Tags")
  valid_593183 = validateParameter(valid_593183, JArray, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "Tags", valid_593183
  var valid_593184 = query.getOrDefault("Scheme")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "Scheme", valid_593184
  var valid_593185 = query.getOrDefault("AvailabilityZones")
  valid_593185 = validateParameter(valid_593185, JArray, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "AvailabilityZones", valid_593185
  assert query != nil,
        "query argument is necessary due to required `Listeners` field"
  var valid_593186 = query.getOrDefault("Listeners")
  valid_593186 = validateParameter(valid_593186, JArray, required = true, default = nil)
  if valid_593186 != nil:
    section.add "Listeners", valid_593186
  var valid_593187 = query.getOrDefault("SecurityGroups")
  valid_593187 = validateParameter(valid_593187, JArray, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "SecurityGroups", valid_593187
  var valid_593188 = query.getOrDefault("LoadBalancerName")
  valid_593188 = validateParameter(valid_593188, JString, required = true,
                                 default = nil)
  if valid_593188 != nil:
    section.add "LoadBalancerName", valid_593188
  var valid_593189 = query.getOrDefault("Action")
  valid_593189 = validateParameter(valid_593189, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_593189 != nil:
    section.add "Action", valid_593189
  var valid_593190 = query.getOrDefault("Subnets")
  valid_593190 = validateParameter(valid_593190, JArray, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "Subnets", valid_593190
  var valid_593191 = query.getOrDefault("Version")
  valid_593191 = validateParameter(valid_593191, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593191 != nil:
    section.add "Version", valid_593191
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
  var valid_593192 = header.getOrDefault("X-Amz-Signature")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Signature", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Content-Sha256", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Date")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Date", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Credential")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Credential", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Security-Token")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Security-Token", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Algorithm")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Algorithm", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-SignedHeaders", valid_593198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593199: Call_GetCreateLoadBalancer_593180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593199.validator(path, query, header, formData, body)
  let scheme = call_593199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593199.url(scheme.get, call_593199.host, call_593199.base,
                         call_593199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593199, url, valid)

proc call*(call_593200: Call_GetCreateLoadBalancer_593180; Listeners: JsonNode;
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
  var query_593201 = newJObject()
  if Tags != nil:
    query_593201.add "Tags", Tags
  add(query_593201, "Scheme", newJString(Scheme))
  if AvailabilityZones != nil:
    query_593201.add "AvailabilityZones", AvailabilityZones
  if Listeners != nil:
    query_593201.add "Listeners", Listeners
  if SecurityGroups != nil:
    query_593201.add "SecurityGroups", SecurityGroups
  add(query_593201, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593201, "Action", newJString(Action))
  if Subnets != nil:
    query_593201.add "Subnets", Subnets
  add(query_593201, "Version", newJString(Version))
  result = call_593200.call(nil, query_593201, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_593180(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_593181, base: "/",
    url: url_GetCreateLoadBalancer_593182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerListeners_593242 = ref object of OpenApiRestCall_592364
proc url_PostCreateLoadBalancerListeners_593244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLoadBalancerListeners_593243(path: JsonNode;
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
  var valid_593245 = query.getOrDefault("Action")
  valid_593245 = validateParameter(valid_593245, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_593245 != nil:
    section.add "Action", valid_593245
  var valid_593246 = query.getOrDefault("Version")
  valid_593246 = validateParameter(valid_593246, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593246 != nil:
    section.add "Version", valid_593246
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
  var valid_593247 = header.getOrDefault("X-Amz-Signature")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Signature", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Content-Sha256", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Date")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Date", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-Credential")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Credential", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Security-Token")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Security-Token", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Algorithm")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Algorithm", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-SignedHeaders", valid_593253
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_593254 = formData.getOrDefault("LoadBalancerName")
  valid_593254 = validateParameter(valid_593254, JString, required = true,
                                 default = nil)
  if valid_593254 != nil:
    section.add "LoadBalancerName", valid_593254
  var valid_593255 = formData.getOrDefault("Listeners")
  valid_593255 = validateParameter(valid_593255, JArray, required = true, default = nil)
  if valid_593255 != nil:
    section.add "Listeners", valid_593255
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593256: Call_PostCreateLoadBalancerListeners_593242;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593256.validator(path, query, header, formData, body)
  let scheme = call_593256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593256.url(scheme.get, call_593256.host, call_593256.base,
                         call_593256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593256, url, valid)

proc call*(call_593257: Call_PostCreateLoadBalancerListeners_593242;
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
  var query_593258 = newJObject()
  var formData_593259 = newJObject()
  add(formData_593259, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_593259.add "Listeners", Listeners
  add(query_593258, "Action", newJString(Action))
  add(query_593258, "Version", newJString(Version))
  result = call_593257.call(nil, query_593258, nil, formData_593259, nil)

var postCreateLoadBalancerListeners* = Call_PostCreateLoadBalancerListeners_593242(
    name: "postCreateLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_PostCreateLoadBalancerListeners_593243, base: "/",
    url: url_PostCreateLoadBalancerListeners_593244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerListeners_593225 = ref object of OpenApiRestCall_592364
proc url_GetCreateLoadBalancerListeners_593227(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLoadBalancerListeners_593226(path: JsonNode;
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
  var valid_593228 = query.getOrDefault("Listeners")
  valid_593228 = validateParameter(valid_593228, JArray, required = true, default = nil)
  if valid_593228 != nil:
    section.add "Listeners", valid_593228
  var valid_593229 = query.getOrDefault("LoadBalancerName")
  valid_593229 = validateParameter(valid_593229, JString, required = true,
                                 default = nil)
  if valid_593229 != nil:
    section.add "LoadBalancerName", valid_593229
  var valid_593230 = query.getOrDefault("Action")
  valid_593230 = validateParameter(valid_593230, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_593230 != nil:
    section.add "Action", valid_593230
  var valid_593231 = query.getOrDefault("Version")
  valid_593231 = validateParameter(valid_593231, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593231 != nil:
    section.add "Version", valid_593231
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
  var valid_593232 = header.getOrDefault("X-Amz-Signature")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Signature", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Content-Sha256", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Date")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Date", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Credential")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Credential", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Security-Token")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Security-Token", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Algorithm")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Algorithm", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-SignedHeaders", valid_593238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593239: Call_GetCreateLoadBalancerListeners_593225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593239.validator(path, query, header, formData, body)
  let scheme = call_593239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593239.url(scheme.get, call_593239.host, call_593239.base,
                         call_593239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593239, url, valid)

proc call*(call_593240: Call_GetCreateLoadBalancerListeners_593225;
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
  var query_593241 = newJObject()
  if Listeners != nil:
    query_593241.add "Listeners", Listeners
  add(query_593241, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593241, "Action", newJString(Action))
  add(query_593241, "Version", newJString(Version))
  result = call_593240.call(nil, query_593241, nil, nil, nil)

var getCreateLoadBalancerListeners* = Call_GetCreateLoadBalancerListeners_593225(
    name: "getCreateLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_GetCreateLoadBalancerListeners_593226, base: "/",
    url: url_GetCreateLoadBalancerListeners_593227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerPolicy_593279 = ref object of OpenApiRestCall_592364
proc url_PostCreateLoadBalancerPolicy_593281(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLoadBalancerPolicy_593280(path: JsonNode; query: JsonNode;
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
  var valid_593282 = query.getOrDefault("Action")
  valid_593282 = validateParameter(valid_593282, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_593282 != nil:
    section.add "Action", valid_593282
  var valid_593283 = query.getOrDefault("Version")
  valid_593283 = validateParameter(valid_593283, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593283 != nil:
    section.add "Version", valid_593283
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
  var valid_593284 = header.getOrDefault("X-Amz-Signature")
  valid_593284 = validateParameter(valid_593284, JString, required = false,
                                 default = nil)
  if valid_593284 != nil:
    section.add "X-Amz-Signature", valid_593284
  var valid_593285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "X-Amz-Content-Sha256", valid_593285
  var valid_593286 = header.getOrDefault("X-Amz-Date")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Date", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Credential")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Credential", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Security-Token")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Security-Token", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Algorithm")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Algorithm", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-SignedHeaders", valid_593290
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
  var valid_593291 = formData.getOrDefault("PolicyAttributes")
  valid_593291 = validateParameter(valid_593291, JArray, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "PolicyAttributes", valid_593291
  assert formData != nil,
        "formData argument is necessary due to required `PolicyTypeName` field"
  var valid_593292 = formData.getOrDefault("PolicyTypeName")
  valid_593292 = validateParameter(valid_593292, JString, required = true,
                                 default = nil)
  if valid_593292 != nil:
    section.add "PolicyTypeName", valid_593292
  var valid_593293 = formData.getOrDefault("LoadBalancerName")
  valid_593293 = validateParameter(valid_593293, JString, required = true,
                                 default = nil)
  if valid_593293 != nil:
    section.add "LoadBalancerName", valid_593293
  var valid_593294 = formData.getOrDefault("PolicyName")
  valid_593294 = validateParameter(valid_593294, JString, required = true,
                                 default = nil)
  if valid_593294 != nil:
    section.add "PolicyName", valid_593294
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593295: Call_PostCreateLoadBalancerPolicy_593279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_593295.validator(path, query, header, formData, body)
  let scheme = call_593295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593295.url(scheme.get, call_593295.host, call_593295.base,
                         call_593295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593295, url, valid)

proc call*(call_593296: Call_PostCreateLoadBalancerPolicy_593279;
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
  var query_593297 = newJObject()
  var formData_593298 = newJObject()
  if PolicyAttributes != nil:
    formData_593298.add "PolicyAttributes", PolicyAttributes
  add(formData_593298, "PolicyTypeName", newJString(PolicyTypeName))
  add(formData_593298, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593297, "Action", newJString(Action))
  add(query_593297, "Version", newJString(Version))
  add(formData_593298, "PolicyName", newJString(PolicyName))
  result = call_593296.call(nil, query_593297, nil, formData_593298, nil)

var postCreateLoadBalancerPolicy* = Call_PostCreateLoadBalancerPolicy_593279(
    name: "postCreateLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_PostCreateLoadBalancerPolicy_593280, base: "/",
    url: url_PostCreateLoadBalancerPolicy_593281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerPolicy_593260 = ref object of OpenApiRestCall_592364
proc url_GetCreateLoadBalancerPolicy_593262(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLoadBalancerPolicy_593261(path: JsonNode; query: JsonNode;
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
  var valid_593263 = query.getOrDefault("PolicyAttributes")
  valid_593263 = validateParameter(valid_593263, JArray, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "PolicyAttributes", valid_593263
  assert query != nil,
        "query argument is necessary due to required `PolicyName` field"
  var valid_593264 = query.getOrDefault("PolicyName")
  valid_593264 = validateParameter(valid_593264, JString, required = true,
                                 default = nil)
  if valid_593264 != nil:
    section.add "PolicyName", valid_593264
  var valid_593265 = query.getOrDefault("PolicyTypeName")
  valid_593265 = validateParameter(valid_593265, JString, required = true,
                                 default = nil)
  if valid_593265 != nil:
    section.add "PolicyTypeName", valid_593265
  var valid_593266 = query.getOrDefault("LoadBalancerName")
  valid_593266 = validateParameter(valid_593266, JString, required = true,
                                 default = nil)
  if valid_593266 != nil:
    section.add "LoadBalancerName", valid_593266
  var valid_593267 = query.getOrDefault("Action")
  valid_593267 = validateParameter(valid_593267, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_593267 != nil:
    section.add "Action", valid_593267
  var valid_593268 = query.getOrDefault("Version")
  valid_593268 = validateParameter(valid_593268, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593268 != nil:
    section.add "Version", valid_593268
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
  var valid_593269 = header.getOrDefault("X-Amz-Signature")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Signature", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-Content-Sha256", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Date")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Date", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Credential")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Credential", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Security-Token")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Security-Token", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Algorithm")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Algorithm", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-SignedHeaders", valid_593275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593276: Call_GetCreateLoadBalancerPolicy_593260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_593276.validator(path, query, header, formData, body)
  let scheme = call_593276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593276.url(scheme.get, call_593276.host, call_593276.base,
                         call_593276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593276, url, valid)

proc call*(call_593277: Call_GetCreateLoadBalancerPolicy_593260;
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
  var query_593278 = newJObject()
  if PolicyAttributes != nil:
    query_593278.add "PolicyAttributes", PolicyAttributes
  add(query_593278, "PolicyName", newJString(PolicyName))
  add(query_593278, "PolicyTypeName", newJString(PolicyTypeName))
  add(query_593278, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593278, "Action", newJString(Action))
  add(query_593278, "Version", newJString(Version))
  result = call_593277.call(nil, query_593278, nil, nil, nil)

var getCreateLoadBalancerPolicy* = Call_GetCreateLoadBalancerPolicy_593260(
    name: "getCreateLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_GetCreateLoadBalancerPolicy_593261, base: "/",
    url: url_GetCreateLoadBalancerPolicy_593262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_593315 = ref object of OpenApiRestCall_592364
proc url_PostDeleteLoadBalancer_593317(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteLoadBalancer_593316(path: JsonNode; query: JsonNode;
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
  var valid_593318 = query.getOrDefault("Action")
  valid_593318 = validateParameter(valid_593318, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_593318 != nil:
    section.add "Action", valid_593318
  var valid_593319 = query.getOrDefault("Version")
  valid_593319 = validateParameter(valid_593319, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593319 != nil:
    section.add "Version", valid_593319
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
  var valid_593320 = header.getOrDefault("X-Amz-Signature")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Signature", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Content-Sha256", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Date")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Date", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Credential")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Credential", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Security-Token")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Security-Token", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Algorithm")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Algorithm", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-SignedHeaders", valid_593326
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_593327 = formData.getOrDefault("LoadBalancerName")
  valid_593327 = validateParameter(valid_593327, JString, required = true,
                                 default = nil)
  if valid_593327 != nil:
    section.add "LoadBalancerName", valid_593327
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593328: Call_PostDeleteLoadBalancer_593315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_593328.validator(path, query, header, formData, body)
  let scheme = call_593328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593328.url(scheme.get, call_593328.host, call_593328.base,
                         call_593328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593328, url, valid)

proc call*(call_593329: Call_PostDeleteLoadBalancer_593315;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593330 = newJObject()
  var formData_593331 = newJObject()
  add(formData_593331, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593330, "Action", newJString(Action))
  add(query_593330, "Version", newJString(Version))
  result = call_593329.call(nil, query_593330, nil, formData_593331, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_593315(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_593316, base: "/",
    url: url_PostDeleteLoadBalancer_593317, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_593299 = ref object of OpenApiRestCall_592364
proc url_GetDeleteLoadBalancer_593301(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteLoadBalancer_593300(path: JsonNode; query: JsonNode;
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
  var valid_593302 = query.getOrDefault("LoadBalancerName")
  valid_593302 = validateParameter(valid_593302, JString, required = true,
                                 default = nil)
  if valid_593302 != nil:
    section.add "LoadBalancerName", valid_593302
  var valid_593303 = query.getOrDefault("Action")
  valid_593303 = validateParameter(valid_593303, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_593303 != nil:
    section.add "Action", valid_593303
  var valid_593304 = query.getOrDefault("Version")
  valid_593304 = validateParameter(valid_593304, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593304 != nil:
    section.add "Version", valid_593304
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
  var valid_593305 = header.getOrDefault("X-Amz-Signature")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Signature", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Content-Sha256", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Date")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Date", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Credential")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Credential", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Security-Token")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Security-Token", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Algorithm")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Algorithm", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-SignedHeaders", valid_593311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593312: Call_GetDeleteLoadBalancer_593299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_593312.validator(path, query, header, formData, body)
  let scheme = call_593312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593312.url(scheme.get, call_593312.host, call_593312.base,
                         call_593312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593312, url, valid)

proc call*(call_593313: Call_GetDeleteLoadBalancer_593299;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593314 = newJObject()
  add(query_593314, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593314, "Action", newJString(Action))
  add(query_593314, "Version", newJString(Version))
  result = call_593313.call(nil, query_593314, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_593299(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_593300, base: "/",
    url: url_GetDeleteLoadBalancer_593301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerListeners_593349 = ref object of OpenApiRestCall_592364
proc url_PostDeleteLoadBalancerListeners_593351(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteLoadBalancerListeners_593350(path: JsonNode;
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
  var valid_593352 = query.getOrDefault("Action")
  valid_593352 = validateParameter(valid_593352, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_593352 != nil:
    section.add "Action", valid_593352
  var valid_593353 = query.getOrDefault("Version")
  valid_593353 = validateParameter(valid_593353, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593353 != nil:
    section.add "Version", valid_593353
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
  var valid_593354 = header.getOrDefault("X-Amz-Signature")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Signature", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Content-Sha256", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Date")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Date", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Credential")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Credential", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Security-Token")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Security-Token", valid_593358
  var valid_593359 = header.getOrDefault("X-Amz-Algorithm")
  valid_593359 = validateParameter(valid_593359, JString, required = false,
                                 default = nil)
  if valid_593359 != nil:
    section.add "X-Amz-Algorithm", valid_593359
  var valid_593360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "X-Amz-SignedHeaders", valid_593360
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerPorts` field"
  var valid_593361 = formData.getOrDefault("LoadBalancerPorts")
  valid_593361 = validateParameter(valid_593361, JArray, required = true, default = nil)
  if valid_593361 != nil:
    section.add "LoadBalancerPorts", valid_593361
  var valid_593362 = formData.getOrDefault("LoadBalancerName")
  valid_593362 = validateParameter(valid_593362, JString, required = true,
                                 default = nil)
  if valid_593362 != nil:
    section.add "LoadBalancerName", valid_593362
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593363: Call_PostDeleteLoadBalancerListeners_593349;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_593363.validator(path, query, header, formData, body)
  let scheme = call_593363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593363.url(scheme.get, call_593363.host, call_593363.base,
                         call_593363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593363, url, valid)

proc call*(call_593364: Call_PostDeleteLoadBalancerListeners_593349;
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
  var query_593365 = newJObject()
  var formData_593366 = newJObject()
  if LoadBalancerPorts != nil:
    formData_593366.add "LoadBalancerPorts", LoadBalancerPorts
  add(formData_593366, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593365, "Action", newJString(Action))
  add(query_593365, "Version", newJString(Version))
  result = call_593364.call(nil, query_593365, nil, formData_593366, nil)

var postDeleteLoadBalancerListeners* = Call_PostDeleteLoadBalancerListeners_593349(
    name: "postDeleteLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_PostDeleteLoadBalancerListeners_593350, base: "/",
    url: url_PostDeleteLoadBalancerListeners_593351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerListeners_593332 = ref object of OpenApiRestCall_592364
proc url_GetDeleteLoadBalancerListeners_593334(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteLoadBalancerListeners_593333(path: JsonNode;
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
  var valid_593335 = query.getOrDefault("LoadBalancerPorts")
  valid_593335 = validateParameter(valid_593335, JArray, required = true, default = nil)
  if valid_593335 != nil:
    section.add "LoadBalancerPorts", valid_593335
  var valid_593336 = query.getOrDefault("LoadBalancerName")
  valid_593336 = validateParameter(valid_593336, JString, required = true,
                                 default = nil)
  if valid_593336 != nil:
    section.add "LoadBalancerName", valid_593336
  var valid_593337 = query.getOrDefault("Action")
  valid_593337 = validateParameter(valid_593337, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_593337 != nil:
    section.add "Action", valid_593337
  var valid_593338 = query.getOrDefault("Version")
  valid_593338 = validateParameter(valid_593338, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593338 != nil:
    section.add "Version", valid_593338
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
  var valid_593339 = header.getOrDefault("X-Amz-Signature")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Signature", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Content-Sha256", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Date")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Date", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-Credential")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-Credential", valid_593342
  var valid_593343 = header.getOrDefault("X-Amz-Security-Token")
  valid_593343 = validateParameter(valid_593343, JString, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "X-Amz-Security-Token", valid_593343
  var valid_593344 = header.getOrDefault("X-Amz-Algorithm")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "X-Amz-Algorithm", valid_593344
  var valid_593345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "X-Amz-SignedHeaders", valid_593345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593346: Call_GetDeleteLoadBalancerListeners_593332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_593346.validator(path, query, header, formData, body)
  let scheme = call_593346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593346.url(scheme.get, call_593346.host, call_593346.base,
                         call_593346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593346, url, valid)

proc call*(call_593347: Call_GetDeleteLoadBalancerListeners_593332;
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
  var query_593348 = newJObject()
  if LoadBalancerPorts != nil:
    query_593348.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_593348, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593348, "Action", newJString(Action))
  add(query_593348, "Version", newJString(Version))
  result = call_593347.call(nil, query_593348, nil, nil, nil)

var getDeleteLoadBalancerListeners* = Call_GetDeleteLoadBalancerListeners_593332(
    name: "getDeleteLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_GetDeleteLoadBalancerListeners_593333, base: "/",
    url: url_GetDeleteLoadBalancerListeners_593334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerPolicy_593384 = ref object of OpenApiRestCall_592364
proc url_PostDeleteLoadBalancerPolicy_593386(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteLoadBalancerPolicy_593385(path: JsonNode; query: JsonNode;
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
  var valid_593387 = query.getOrDefault("Action")
  valid_593387 = validateParameter(valid_593387, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_593387 != nil:
    section.add "Action", valid_593387
  var valid_593388 = query.getOrDefault("Version")
  valid_593388 = validateParameter(valid_593388, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593388 != nil:
    section.add "Version", valid_593388
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
  var valid_593389 = header.getOrDefault("X-Amz-Signature")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Signature", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Content-Sha256", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-Date")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-Date", valid_593391
  var valid_593392 = header.getOrDefault("X-Amz-Credential")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Credential", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-Security-Token")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-Security-Token", valid_593393
  var valid_593394 = header.getOrDefault("X-Amz-Algorithm")
  valid_593394 = validateParameter(valid_593394, JString, required = false,
                                 default = nil)
  if valid_593394 != nil:
    section.add "X-Amz-Algorithm", valid_593394
  var valid_593395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593395 = validateParameter(valid_593395, JString, required = false,
                                 default = nil)
  if valid_593395 != nil:
    section.add "X-Amz-SignedHeaders", valid_593395
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_593396 = formData.getOrDefault("LoadBalancerName")
  valid_593396 = validateParameter(valid_593396, JString, required = true,
                                 default = nil)
  if valid_593396 != nil:
    section.add "LoadBalancerName", valid_593396
  var valid_593397 = formData.getOrDefault("PolicyName")
  valid_593397 = validateParameter(valid_593397, JString, required = true,
                                 default = nil)
  if valid_593397 != nil:
    section.add "PolicyName", valid_593397
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593398: Call_PostDeleteLoadBalancerPolicy_593384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_593398.validator(path, query, header, formData, body)
  let scheme = call_593398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593398.url(scheme.get, call_593398.host, call_593398.base,
                         call_593398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593398, url, valid)

proc call*(call_593399: Call_PostDeleteLoadBalancerPolicy_593384;
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
  var query_593400 = newJObject()
  var formData_593401 = newJObject()
  add(formData_593401, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593400, "Action", newJString(Action))
  add(query_593400, "Version", newJString(Version))
  add(formData_593401, "PolicyName", newJString(PolicyName))
  result = call_593399.call(nil, query_593400, nil, formData_593401, nil)

var postDeleteLoadBalancerPolicy* = Call_PostDeleteLoadBalancerPolicy_593384(
    name: "postDeleteLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_PostDeleteLoadBalancerPolicy_593385, base: "/",
    url: url_PostDeleteLoadBalancerPolicy_593386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerPolicy_593367 = ref object of OpenApiRestCall_592364
proc url_GetDeleteLoadBalancerPolicy_593369(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteLoadBalancerPolicy_593368(path: JsonNode; query: JsonNode;
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
  var valid_593370 = query.getOrDefault("PolicyName")
  valid_593370 = validateParameter(valid_593370, JString, required = true,
                                 default = nil)
  if valid_593370 != nil:
    section.add "PolicyName", valid_593370
  var valid_593371 = query.getOrDefault("LoadBalancerName")
  valid_593371 = validateParameter(valid_593371, JString, required = true,
                                 default = nil)
  if valid_593371 != nil:
    section.add "LoadBalancerName", valid_593371
  var valid_593372 = query.getOrDefault("Action")
  valid_593372 = validateParameter(valid_593372, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_593372 != nil:
    section.add "Action", valid_593372
  var valid_593373 = query.getOrDefault("Version")
  valid_593373 = validateParameter(valid_593373, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593373 != nil:
    section.add "Version", valid_593373
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
  var valid_593374 = header.getOrDefault("X-Amz-Signature")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Signature", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Content-Sha256", valid_593375
  var valid_593376 = header.getOrDefault("X-Amz-Date")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-Date", valid_593376
  var valid_593377 = header.getOrDefault("X-Amz-Credential")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-Credential", valid_593377
  var valid_593378 = header.getOrDefault("X-Amz-Security-Token")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-Security-Token", valid_593378
  var valid_593379 = header.getOrDefault("X-Amz-Algorithm")
  valid_593379 = validateParameter(valid_593379, JString, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "X-Amz-Algorithm", valid_593379
  var valid_593380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593380 = validateParameter(valid_593380, JString, required = false,
                                 default = nil)
  if valid_593380 != nil:
    section.add "X-Amz-SignedHeaders", valid_593380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593381: Call_GetDeleteLoadBalancerPolicy_593367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_593381.validator(path, query, header, formData, body)
  let scheme = call_593381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593381.url(scheme.get, call_593381.host, call_593381.base,
                         call_593381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593381, url, valid)

proc call*(call_593382: Call_GetDeleteLoadBalancerPolicy_593367;
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
  var query_593383 = newJObject()
  add(query_593383, "PolicyName", newJString(PolicyName))
  add(query_593383, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593383, "Action", newJString(Action))
  add(query_593383, "Version", newJString(Version))
  result = call_593382.call(nil, query_593383, nil, nil, nil)

var getDeleteLoadBalancerPolicy* = Call_GetDeleteLoadBalancerPolicy_593367(
    name: "getDeleteLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_GetDeleteLoadBalancerPolicy_593368, base: "/",
    url: url_GetDeleteLoadBalancerPolicy_593369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterInstancesFromLoadBalancer_593419 = ref object of OpenApiRestCall_592364
proc url_PostDeregisterInstancesFromLoadBalancer_593421(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeregisterInstancesFromLoadBalancer_593420(path: JsonNode;
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
  var valid_593422 = query.getOrDefault("Action")
  valid_593422 = validateParameter(valid_593422, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_593422 != nil:
    section.add "Action", valid_593422
  var valid_593423 = query.getOrDefault("Version")
  valid_593423 = validateParameter(valid_593423, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593423 != nil:
    section.add "Version", valid_593423
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
  var valid_593424 = header.getOrDefault("X-Amz-Signature")
  valid_593424 = validateParameter(valid_593424, JString, required = false,
                                 default = nil)
  if valid_593424 != nil:
    section.add "X-Amz-Signature", valid_593424
  var valid_593425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593425 = validateParameter(valid_593425, JString, required = false,
                                 default = nil)
  if valid_593425 != nil:
    section.add "X-Amz-Content-Sha256", valid_593425
  var valid_593426 = header.getOrDefault("X-Amz-Date")
  valid_593426 = validateParameter(valid_593426, JString, required = false,
                                 default = nil)
  if valid_593426 != nil:
    section.add "X-Amz-Date", valid_593426
  var valid_593427 = header.getOrDefault("X-Amz-Credential")
  valid_593427 = validateParameter(valid_593427, JString, required = false,
                                 default = nil)
  if valid_593427 != nil:
    section.add "X-Amz-Credential", valid_593427
  var valid_593428 = header.getOrDefault("X-Amz-Security-Token")
  valid_593428 = validateParameter(valid_593428, JString, required = false,
                                 default = nil)
  if valid_593428 != nil:
    section.add "X-Amz-Security-Token", valid_593428
  var valid_593429 = header.getOrDefault("X-Amz-Algorithm")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Algorithm", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-SignedHeaders", valid_593430
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_593431 = formData.getOrDefault("Instances")
  valid_593431 = validateParameter(valid_593431, JArray, required = true, default = nil)
  if valid_593431 != nil:
    section.add "Instances", valid_593431
  var valid_593432 = formData.getOrDefault("LoadBalancerName")
  valid_593432 = validateParameter(valid_593432, JString, required = true,
                                 default = nil)
  if valid_593432 != nil:
    section.add "LoadBalancerName", valid_593432
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593433: Call_PostDeregisterInstancesFromLoadBalancer_593419;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593433.validator(path, query, header, formData, body)
  let scheme = call_593433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593433.url(scheme.get, call_593433.host, call_593433.base,
                         call_593433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593433, url, valid)

proc call*(call_593434: Call_PostDeregisterInstancesFromLoadBalancer_593419;
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
  var query_593435 = newJObject()
  var formData_593436 = newJObject()
  if Instances != nil:
    formData_593436.add "Instances", Instances
  add(formData_593436, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593435, "Action", newJString(Action))
  add(query_593435, "Version", newJString(Version))
  result = call_593434.call(nil, query_593435, nil, formData_593436, nil)

var postDeregisterInstancesFromLoadBalancer* = Call_PostDeregisterInstancesFromLoadBalancer_593419(
    name: "postDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_PostDeregisterInstancesFromLoadBalancer_593420, base: "/",
    url: url_PostDeregisterInstancesFromLoadBalancer_593421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterInstancesFromLoadBalancer_593402 = ref object of OpenApiRestCall_592364
proc url_GetDeregisterInstancesFromLoadBalancer_593404(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeregisterInstancesFromLoadBalancer_593403(path: JsonNode;
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
  var valid_593405 = query.getOrDefault("LoadBalancerName")
  valid_593405 = validateParameter(valid_593405, JString, required = true,
                                 default = nil)
  if valid_593405 != nil:
    section.add "LoadBalancerName", valid_593405
  var valid_593406 = query.getOrDefault("Action")
  valid_593406 = validateParameter(valid_593406, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_593406 != nil:
    section.add "Action", valid_593406
  var valid_593407 = query.getOrDefault("Instances")
  valid_593407 = validateParameter(valid_593407, JArray, required = true, default = nil)
  if valid_593407 != nil:
    section.add "Instances", valid_593407
  var valid_593408 = query.getOrDefault("Version")
  valid_593408 = validateParameter(valid_593408, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593408 != nil:
    section.add "Version", valid_593408
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
  var valid_593409 = header.getOrDefault("X-Amz-Signature")
  valid_593409 = validateParameter(valid_593409, JString, required = false,
                                 default = nil)
  if valid_593409 != nil:
    section.add "X-Amz-Signature", valid_593409
  var valid_593410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593410 = validateParameter(valid_593410, JString, required = false,
                                 default = nil)
  if valid_593410 != nil:
    section.add "X-Amz-Content-Sha256", valid_593410
  var valid_593411 = header.getOrDefault("X-Amz-Date")
  valid_593411 = validateParameter(valid_593411, JString, required = false,
                                 default = nil)
  if valid_593411 != nil:
    section.add "X-Amz-Date", valid_593411
  var valid_593412 = header.getOrDefault("X-Amz-Credential")
  valid_593412 = validateParameter(valid_593412, JString, required = false,
                                 default = nil)
  if valid_593412 != nil:
    section.add "X-Amz-Credential", valid_593412
  var valid_593413 = header.getOrDefault("X-Amz-Security-Token")
  valid_593413 = validateParameter(valid_593413, JString, required = false,
                                 default = nil)
  if valid_593413 != nil:
    section.add "X-Amz-Security-Token", valid_593413
  var valid_593414 = header.getOrDefault("X-Amz-Algorithm")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Algorithm", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-SignedHeaders", valid_593415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593416: Call_GetDeregisterInstancesFromLoadBalancer_593402;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593416.validator(path, query, header, formData, body)
  let scheme = call_593416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593416.url(scheme.get, call_593416.host, call_593416.base,
                         call_593416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593416, url, valid)

proc call*(call_593417: Call_GetDeregisterInstancesFromLoadBalancer_593402;
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
  var query_593418 = newJObject()
  add(query_593418, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593418, "Action", newJString(Action))
  if Instances != nil:
    query_593418.add "Instances", Instances
  add(query_593418, "Version", newJString(Version))
  result = call_593417.call(nil, query_593418, nil, nil, nil)

var getDeregisterInstancesFromLoadBalancer* = Call_GetDeregisterInstancesFromLoadBalancer_593402(
    name: "getDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_GetDeregisterInstancesFromLoadBalancer_593403, base: "/",
    url: url_GetDeregisterInstancesFromLoadBalancer_593404,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_593454 = ref object of OpenApiRestCall_592364
proc url_PostDescribeAccountLimits_593456(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAccountLimits_593455(path: JsonNode; query: JsonNode;
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
  var valid_593457 = query.getOrDefault("Action")
  valid_593457 = validateParameter(valid_593457, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_593457 != nil:
    section.add "Action", valid_593457
  var valid_593458 = query.getOrDefault("Version")
  valid_593458 = validateParameter(valid_593458, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593458 != nil:
    section.add "Version", valid_593458
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
  var valid_593459 = header.getOrDefault("X-Amz-Signature")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-Signature", valid_593459
  var valid_593460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-Content-Sha256", valid_593460
  var valid_593461 = header.getOrDefault("X-Amz-Date")
  valid_593461 = validateParameter(valid_593461, JString, required = false,
                                 default = nil)
  if valid_593461 != nil:
    section.add "X-Amz-Date", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-Credential")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Credential", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-Security-Token")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-Security-Token", valid_593463
  var valid_593464 = header.getOrDefault("X-Amz-Algorithm")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "X-Amz-Algorithm", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-SignedHeaders", valid_593465
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_593466 = formData.getOrDefault("Marker")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "Marker", valid_593466
  var valid_593467 = formData.getOrDefault("PageSize")
  valid_593467 = validateParameter(valid_593467, JInt, required = false, default = nil)
  if valid_593467 != nil:
    section.add "PageSize", valid_593467
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593468: Call_PostDescribeAccountLimits_593454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593468.validator(path, query, header, formData, body)
  let scheme = call_593468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593468.url(scheme.get, call_593468.host, call_593468.base,
                         call_593468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593468, url, valid)

proc call*(call_593469: Call_PostDescribeAccountLimits_593454; Marker: string = "";
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
  var query_593470 = newJObject()
  var formData_593471 = newJObject()
  add(formData_593471, "Marker", newJString(Marker))
  add(query_593470, "Action", newJString(Action))
  add(formData_593471, "PageSize", newJInt(PageSize))
  add(query_593470, "Version", newJString(Version))
  result = call_593469.call(nil, query_593470, nil, formData_593471, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_593454(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_593455, base: "/",
    url: url_PostDescribeAccountLimits_593456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_593437 = ref object of OpenApiRestCall_592364
proc url_GetDescribeAccountLimits_593439(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAccountLimits_593438(path: JsonNode; query: JsonNode;
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
  var valid_593440 = query.getOrDefault("Marker")
  valid_593440 = validateParameter(valid_593440, JString, required = false,
                                 default = nil)
  if valid_593440 != nil:
    section.add "Marker", valid_593440
  var valid_593441 = query.getOrDefault("PageSize")
  valid_593441 = validateParameter(valid_593441, JInt, required = false, default = nil)
  if valid_593441 != nil:
    section.add "PageSize", valid_593441
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593442 = query.getOrDefault("Action")
  valid_593442 = validateParameter(valid_593442, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_593442 != nil:
    section.add "Action", valid_593442
  var valid_593443 = query.getOrDefault("Version")
  valid_593443 = validateParameter(valid_593443, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593443 != nil:
    section.add "Version", valid_593443
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
  var valid_593444 = header.getOrDefault("X-Amz-Signature")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-Signature", valid_593444
  var valid_593445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "X-Amz-Content-Sha256", valid_593445
  var valid_593446 = header.getOrDefault("X-Amz-Date")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Date", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-Credential")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Credential", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Security-Token")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Security-Token", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Algorithm")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Algorithm", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-SignedHeaders", valid_593450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593451: Call_GetDescribeAccountLimits_593437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593451.validator(path, query, header, formData, body)
  let scheme = call_593451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593451.url(scheme.get, call_593451.host, call_593451.base,
                         call_593451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593451, url, valid)

proc call*(call_593452: Call_GetDescribeAccountLimits_593437; Marker: string = "";
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
  var query_593453 = newJObject()
  add(query_593453, "Marker", newJString(Marker))
  add(query_593453, "PageSize", newJInt(PageSize))
  add(query_593453, "Action", newJString(Action))
  add(query_593453, "Version", newJString(Version))
  result = call_593452.call(nil, query_593453, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_593437(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_593438, base: "/",
    url: url_GetDescribeAccountLimits_593439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstanceHealth_593489 = ref object of OpenApiRestCall_592364
proc url_PostDescribeInstanceHealth_593491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeInstanceHealth_593490(path: JsonNode; query: JsonNode;
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
  var valid_593492 = query.getOrDefault("Action")
  valid_593492 = validateParameter(valid_593492, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_593492 != nil:
    section.add "Action", valid_593492
  var valid_593493 = query.getOrDefault("Version")
  valid_593493 = validateParameter(valid_593493, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593493 != nil:
    section.add "Version", valid_593493
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
  var valid_593494 = header.getOrDefault("X-Amz-Signature")
  valid_593494 = validateParameter(valid_593494, JString, required = false,
                                 default = nil)
  if valid_593494 != nil:
    section.add "X-Amz-Signature", valid_593494
  var valid_593495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "X-Amz-Content-Sha256", valid_593495
  var valid_593496 = header.getOrDefault("X-Amz-Date")
  valid_593496 = validateParameter(valid_593496, JString, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "X-Amz-Date", valid_593496
  var valid_593497 = header.getOrDefault("X-Amz-Credential")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "X-Amz-Credential", valid_593497
  var valid_593498 = header.getOrDefault("X-Amz-Security-Token")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Security-Token", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Algorithm")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Algorithm", valid_593499
  var valid_593500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-SignedHeaders", valid_593500
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_593501 = formData.getOrDefault("Instances")
  valid_593501 = validateParameter(valid_593501, JArray, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "Instances", valid_593501
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_593502 = formData.getOrDefault("LoadBalancerName")
  valid_593502 = validateParameter(valid_593502, JString, required = true,
                                 default = nil)
  if valid_593502 != nil:
    section.add "LoadBalancerName", valid_593502
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593503: Call_PostDescribeInstanceHealth_593489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_593503.validator(path, query, header, formData, body)
  let scheme = call_593503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593503.url(scheme.get, call_593503.host, call_593503.base,
                         call_593503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593503, url, valid)

proc call*(call_593504: Call_PostDescribeInstanceHealth_593489;
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
  var query_593505 = newJObject()
  var formData_593506 = newJObject()
  if Instances != nil:
    formData_593506.add "Instances", Instances
  add(formData_593506, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593505, "Action", newJString(Action))
  add(query_593505, "Version", newJString(Version))
  result = call_593504.call(nil, query_593505, nil, formData_593506, nil)

var postDescribeInstanceHealth* = Call_PostDescribeInstanceHealth_593489(
    name: "postDescribeInstanceHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_PostDescribeInstanceHealth_593490, base: "/",
    url: url_PostDescribeInstanceHealth_593491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstanceHealth_593472 = ref object of OpenApiRestCall_592364
proc url_GetDescribeInstanceHealth_593474(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeInstanceHealth_593473(path: JsonNode; query: JsonNode;
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
  var valid_593475 = query.getOrDefault("LoadBalancerName")
  valid_593475 = validateParameter(valid_593475, JString, required = true,
                                 default = nil)
  if valid_593475 != nil:
    section.add "LoadBalancerName", valid_593475
  var valid_593476 = query.getOrDefault("Action")
  valid_593476 = validateParameter(valid_593476, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_593476 != nil:
    section.add "Action", valid_593476
  var valid_593477 = query.getOrDefault("Instances")
  valid_593477 = validateParameter(valid_593477, JArray, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "Instances", valid_593477
  var valid_593478 = query.getOrDefault("Version")
  valid_593478 = validateParameter(valid_593478, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593478 != nil:
    section.add "Version", valid_593478
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
  var valid_593479 = header.getOrDefault("X-Amz-Signature")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Signature", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-Content-Sha256", valid_593480
  var valid_593481 = header.getOrDefault("X-Amz-Date")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "X-Amz-Date", valid_593481
  var valid_593482 = header.getOrDefault("X-Amz-Credential")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-Credential", valid_593482
  var valid_593483 = header.getOrDefault("X-Amz-Security-Token")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-Security-Token", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-Algorithm")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-Algorithm", valid_593484
  var valid_593485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-SignedHeaders", valid_593485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593486: Call_GetDescribeInstanceHealth_593472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_593486.validator(path, query, header, formData, body)
  let scheme = call_593486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593486.url(scheme.get, call_593486.host, call_593486.base,
                         call_593486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593486, url, valid)

proc call*(call_593487: Call_GetDescribeInstanceHealth_593472;
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
  var query_593488 = newJObject()
  add(query_593488, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593488, "Action", newJString(Action))
  if Instances != nil:
    query_593488.add "Instances", Instances
  add(query_593488, "Version", newJString(Version))
  result = call_593487.call(nil, query_593488, nil, nil, nil)

var getDescribeInstanceHealth* = Call_GetDescribeInstanceHealth_593472(
    name: "getDescribeInstanceHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_GetDescribeInstanceHealth_593473, base: "/",
    url: url_GetDescribeInstanceHealth_593474,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_593523 = ref object of OpenApiRestCall_592364
proc url_PostDescribeLoadBalancerAttributes_593525(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancerAttributes_593524(path: JsonNode;
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
  var valid_593526 = query.getOrDefault("Action")
  valid_593526 = validateParameter(valid_593526, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_593526 != nil:
    section.add "Action", valid_593526
  var valid_593527 = query.getOrDefault("Version")
  valid_593527 = validateParameter(valid_593527, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593527 != nil:
    section.add "Version", valid_593527
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
  var valid_593528 = header.getOrDefault("X-Amz-Signature")
  valid_593528 = validateParameter(valid_593528, JString, required = false,
                                 default = nil)
  if valid_593528 != nil:
    section.add "X-Amz-Signature", valid_593528
  var valid_593529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593529 = validateParameter(valid_593529, JString, required = false,
                                 default = nil)
  if valid_593529 != nil:
    section.add "X-Amz-Content-Sha256", valid_593529
  var valid_593530 = header.getOrDefault("X-Amz-Date")
  valid_593530 = validateParameter(valid_593530, JString, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "X-Amz-Date", valid_593530
  var valid_593531 = header.getOrDefault("X-Amz-Credential")
  valid_593531 = validateParameter(valid_593531, JString, required = false,
                                 default = nil)
  if valid_593531 != nil:
    section.add "X-Amz-Credential", valid_593531
  var valid_593532 = header.getOrDefault("X-Amz-Security-Token")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "X-Amz-Security-Token", valid_593532
  var valid_593533 = header.getOrDefault("X-Amz-Algorithm")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-Algorithm", valid_593533
  var valid_593534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "X-Amz-SignedHeaders", valid_593534
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_593535 = formData.getOrDefault("LoadBalancerName")
  valid_593535 = validateParameter(valid_593535, JString, required = true,
                                 default = nil)
  if valid_593535 != nil:
    section.add "LoadBalancerName", valid_593535
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593536: Call_PostDescribeLoadBalancerAttributes_593523;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_593536.validator(path, query, header, formData, body)
  let scheme = call_593536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593536.url(scheme.get, call_593536.host, call_593536.base,
                         call_593536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593536, url, valid)

proc call*(call_593537: Call_PostDescribeLoadBalancerAttributes_593523;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593538 = newJObject()
  var formData_593539 = newJObject()
  add(formData_593539, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593538, "Action", newJString(Action))
  add(query_593538, "Version", newJString(Version))
  result = call_593537.call(nil, query_593538, nil, formData_593539, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_593523(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_593524, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_593525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_593507 = ref object of OpenApiRestCall_592364
proc url_GetDescribeLoadBalancerAttributes_593509(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancerAttributes_593508(path: JsonNode;
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
  var valid_593510 = query.getOrDefault("LoadBalancerName")
  valid_593510 = validateParameter(valid_593510, JString, required = true,
                                 default = nil)
  if valid_593510 != nil:
    section.add "LoadBalancerName", valid_593510
  var valid_593511 = query.getOrDefault("Action")
  valid_593511 = validateParameter(valid_593511, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_593511 != nil:
    section.add "Action", valid_593511
  var valid_593512 = query.getOrDefault("Version")
  valid_593512 = validateParameter(valid_593512, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593512 != nil:
    section.add "Version", valid_593512
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
  var valid_593513 = header.getOrDefault("X-Amz-Signature")
  valid_593513 = validateParameter(valid_593513, JString, required = false,
                                 default = nil)
  if valid_593513 != nil:
    section.add "X-Amz-Signature", valid_593513
  var valid_593514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593514 = validateParameter(valid_593514, JString, required = false,
                                 default = nil)
  if valid_593514 != nil:
    section.add "X-Amz-Content-Sha256", valid_593514
  var valid_593515 = header.getOrDefault("X-Amz-Date")
  valid_593515 = validateParameter(valid_593515, JString, required = false,
                                 default = nil)
  if valid_593515 != nil:
    section.add "X-Amz-Date", valid_593515
  var valid_593516 = header.getOrDefault("X-Amz-Credential")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "X-Amz-Credential", valid_593516
  var valid_593517 = header.getOrDefault("X-Amz-Security-Token")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-Security-Token", valid_593517
  var valid_593518 = header.getOrDefault("X-Amz-Algorithm")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Algorithm", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-SignedHeaders", valid_593519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593520: Call_GetDescribeLoadBalancerAttributes_593507;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_593520.validator(path, query, header, formData, body)
  let scheme = call_593520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593520.url(scheme.get, call_593520.host, call_593520.base,
                         call_593520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593520, url, valid)

proc call*(call_593521: Call_GetDescribeLoadBalancerAttributes_593507;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593522 = newJObject()
  add(query_593522, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593522, "Action", newJString(Action))
  add(query_593522, "Version", newJString(Version))
  result = call_593521.call(nil, query_593522, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_593507(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_593508, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_593509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicies_593557 = ref object of OpenApiRestCall_592364
proc url_PostDescribeLoadBalancerPolicies_593559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancerPolicies_593558(path: JsonNode;
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
  var valid_593560 = query.getOrDefault("Action")
  valid_593560 = validateParameter(valid_593560, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_593560 != nil:
    section.add "Action", valid_593560
  var valid_593561 = query.getOrDefault("Version")
  valid_593561 = validateParameter(valid_593561, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593561 != nil:
    section.add "Version", valid_593561
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
  var valid_593562 = header.getOrDefault("X-Amz-Signature")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "X-Amz-Signature", valid_593562
  var valid_593563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593563 = validateParameter(valid_593563, JString, required = false,
                                 default = nil)
  if valid_593563 != nil:
    section.add "X-Amz-Content-Sha256", valid_593563
  var valid_593564 = header.getOrDefault("X-Amz-Date")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "X-Amz-Date", valid_593564
  var valid_593565 = header.getOrDefault("X-Amz-Credential")
  valid_593565 = validateParameter(valid_593565, JString, required = false,
                                 default = nil)
  if valid_593565 != nil:
    section.add "X-Amz-Credential", valid_593565
  var valid_593566 = header.getOrDefault("X-Amz-Security-Token")
  valid_593566 = validateParameter(valid_593566, JString, required = false,
                                 default = nil)
  if valid_593566 != nil:
    section.add "X-Amz-Security-Token", valid_593566
  var valid_593567 = header.getOrDefault("X-Amz-Algorithm")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-Algorithm", valid_593567
  var valid_593568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593568 = validateParameter(valid_593568, JString, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "X-Amz-SignedHeaders", valid_593568
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   LoadBalancerName: JString
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_593569 = formData.getOrDefault("PolicyNames")
  valid_593569 = validateParameter(valid_593569, JArray, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "PolicyNames", valid_593569
  var valid_593570 = formData.getOrDefault("LoadBalancerName")
  valid_593570 = validateParameter(valid_593570, JString, required = false,
                                 default = nil)
  if valid_593570 != nil:
    section.add "LoadBalancerName", valid_593570
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593571: Call_PostDescribeLoadBalancerPolicies_593557;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_593571.validator(path, query, header, formData, body)
  let scheme = call_593571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593571.url(scheme.get, call_593571.host, call_593571.base,
                         call_593571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593571, url, valid)

proc call*(call_593572: Call_PostDescribeLoadBalancerPolicies_593557;
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
  var query_593573 = newJObject()
  var formData_593574 = newJObject()
  if PolicyNames != nil:
    formData_593574.add "PolicyNames", PolicyNames
  add(formData_593574, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593573, "Action", newJString(Action))
  add(query_593573, "Version", newJString(Version))
  result = call_593572.call(nil, query_593573, nil, formData_593574, nil)

var postDescribeLoadBalancerPolicies* = Call_PostDescribeLoadBalancerPolicies_593557(
    name: "postDescribeLoadBalancerPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_PostDescribeLoadBalancerPolicies_593558, base: "/",
    url: url_PostDescribeLoadBalancerPolicies_593559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicies_593540 = ref object of OpenApiRestCall_592364
proc url_GetDescribeLoadBalancerPolicies_593542(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancerPolicies_593541(path: JsonNode;
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
  var valid_593543 = query.getOrDefault("LoadBalancerName")
  valid_593543 = validateParameter(valid_593543, JString, required = false,
                                 default = nil)
  if valid_593543 != nil:
    section.add "LoadBalancerName", valid_593543
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593544 = query.getOrDefault("Action")
  valid_593544 = validateParameter(valid_593544, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_593544 != nil:
    section.add "Action", valid_593544
  var valid_593545 = query.getOrDefault("Version")
  valid_593545 = validateParameter(valid_593545, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593545 != nil:
    section.add "Version", valid_593545
  var valid_593546 = query.getOrDefault("PolicyNames")
  valid_593546 = validateParameter(valid_593546, JArray, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "PolicyNames", valid_593546
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
  var valid_593547 = header.getOrDefault("X-Amz-Signature")
  valid_593547 = validateParameter(valid_593547, JString, required = false,
                                 default = nil)
  if valid_593547 != nil:
    section.add "X-Amz-Signature", valid_593547
  var valid_593548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593548 = validateParameter(valid_593548, JString, required = false,
                                 default = nil)
  if valid_593548 != nil:
    section.add "X-Amz-Content-Sha256", valid_593548
  var valid_593549 = header.getOrDefault("X-Amz-Date")
  valid_593549 = validateParameter(valid_593549, JString, required = false,
                                 default = nil)
  if valid_593549 != nil:
    section.add "X-Amz-Date", valid_593549
  var valid_593550 = header.getOrDefault("X-Amz-Credential")
  valid_593550 = validateParameter(valid_593550, JString, required = false,
                                 default = nil)
  if valid_593550 != nil:
    section.add "X-Amz-Credential", valid_593550
  var valid_593551 = header.getOrDefault("X-Amz-Security-Token")
  valid_593551 = validateParameter(valid_593551, JString, required = false,
                                 default = nil)
  if valid_593551 != nil:
    section.add "X-Amz-Security-Token", valid_593551
  var valid_593552 = header.getOrDefault("X-Amz-Algorithm")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "X-Amz-Algorithm", valid_593552
  var valid_593553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593553 = validateParameter(valid_593553, JString, required = false,
                                 default = nil)
  if valid_593553 != nil:
    section.add "X-Amz-SignedHeaders", valid_593553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593554: Call_GetDescribeLoadBalancerPolicies_593540;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_593554.validator(path, query, header, formData, body)
  let scheme = call_593554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593554.url(scheme.get, call_593554.host, call_593554.base,
                         call_593554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593554, url, valid)

proc call*(call_593555: Call_GetDescribeLoadBalancerPolicies_593540;
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
  var query_593556 = newJObject()
  add(query_593556, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593556, "Action", newJString(Action))
  add(query_593556, "Version", newJString(Version))
  if PolicyNames != nil:
    query_593556.add "PolicyNames", PolicyNames
  result = call_593555.call(nil, query_593556, nil, nil, nil)

var getDescribeLoadBalancerPolicies* = Call_GetDescribeLoadBalancerPolicies_593540(
    name: "getDescribeLoadBalancerPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_GetDescribeLoadBalancerPolicies_593541, base: "/",
    url: url_GetDescribeLoadBalancerPolicies_593542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicyTypes_593591 = ref object of OpenApiRestCall_592364
proc url_PostDescribeLoadBalancerPolicyTypes_593593(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancerPolicyTypes_593592(path: JsonNode;
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
  var valid_593594 = query.getOrDefault("Action")
  valid_593594 = validateParameter(valid_593594, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_593594 != nil:
    section.add "Action", valid_593594
  var valid_593595 = query.getOrDefault("Version")
  valid_593595 = validateParameter(valid_593595, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593595 != nil:
    section.add "Version", valid_593595
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
  var valid_593596 = header.getOrDefault("X-Amz-Signature")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "X-Amz-Signature", valid_593596
  var valid_593597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "X-Amz-Content-Sha256", valid_593597
  var valid_593598 = header.getOrDefault("X-Amz-Date")
  valid_593598 = validateParameter(valid_593598, JString, required = false,
                                 default = nil)
  if valid_593598 != nil:
    section.add "X-Amz-Date", valid_593598
  var valid_593599 = header.getOrDefault("X-Amz-Credential")
  valid_593599 = validateParameter(valid_593599, JString, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "X-Amz-Credential", valid_593599
  var valid_593600 = header.getOrDefault("X-Amz-Security-Token")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-Security-Token", valid_593600
  var valid_593601 = header.getOrDefault("X-Amz-Algorithm")
  valid_593601 = validateParameter(valid_593601, JString, required = false,
                                 default = nil)
  if valid_593601 != nil:
    section.add "X-Amz-Algorithm", valid_593601
  var valid_593602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "X-Amz-SignedHeaders", valid_593602
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  section = newJObject()
  var valid_593603 = formData.getOrDefault("PolicyTypeNames")
  valid_593603 = validateParameter(valid_593603, JArray, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "PolicyTypeNames", valid_593603
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593604: Call_PostDescribeLoadBalancerPolicyTypes_593591;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_593604.validator(path, query, header, formData, body)
  let scheme = call_593604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593604.url(scheme.get, call_593604.host, call_593604.base,
                         call_593604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593604, url, valid)

proc call*(call_593605: Call_PostDescribeLoadBalancerPolicyTypes_593591;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593606 = newJObject()
  var formData_593607 = newJObject()
  if PolicyTypeNames != nil:
    formData_593607.add "PolicyTypeNames", PolicyTypeNames
  add(query_593606, "Action", newJString(Action))
  add(query_593606, "Version", newJString(Version))
  result = call_593605.call(nil, query_593606, nil, formData_593607, nil)

var postDescribeLoadBalancerPolicyTypes* = Call_PostDescribeLoadBalancerPolicyTypes_593591(
    name: "postDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_PostDescribeLoadBalancerPolicyTypes_593592, base: "/",
    url: url_PostDescribeLoadBalancerPolicyTypes_593593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicyTypes_593575 = ref object of OpenApiRestCall_592364
proc url_GetDescribeLoadBalancerPolicyTypes_593577(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancerPolicyTypes_593576(path: JsonNode;
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
  var valid_593578 = query.getOrDefault("PolicyTypeNames")
  valid_593578 = validateParameter(valid_593578, JArray, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "PolicyTypeNames", valid_593578
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593579 = query.getOrDefault("Action")
  valid_593579 = validateParameter(valid_593579, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_593579 != nil:
    section.add "Action", valid_593579
  var valid_593580 = query.getOrDefault("Version")
  valid_593580 = validateParameter(valid_593580, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593580 != nil:
    section.add "Version", valid_593580
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
  var valid_593581 = header.getOrDefault("X-Amz-Signature")
  valid_593581 = validateParameter(valid_593581, JString, required = false,
                                 default = nil)
  if valid_593581 != nil:
    section.add "X-Amz-Signature", valid_593581
  var valid_593582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593582 = validateParameter(valid_593582, JString, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "X-Amz-Content-Sha256", valid_593582
  var valid_593583 = header.getOrDefault("X-Amz-Date")
  valid_593583 = validateParameter(valid_593583, JString, required = false,
                                 default = nil)
  if valid_593583 != nil:
    section.add "X-Amz-Date", valid_593583
  var valid_593584 = header.getOrDefault("X-Amz-Credential")
  valid_593584 = validateParameter(valid_593584, JString, required = false,
                                 default = nil)
  if valid_593584 != nil:
    section.add "X-Amz-Credential", valid_593584
  var valid_593585 = header.getOrDefault("X-Amz-Security-Token")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "X-Amz-Security-Token", valid_593585
  var valid_593586 = header.getOrDefault("X-Amz-Algorithm")
  valid_593586 = validateParameter(valid_593586, JString, required = false,
                                 default = nil)
  if valid_593586 != nil:
    section.add "X-Amz-Algorithm", valid_593586
  var valid_593587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-SignedHeaders", valid_593587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593588: Call_GetDescribeLoadBalancerPolicyTypes_593575;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_593588.validator(path, query, header, formData, body)
  let scheme = call_593588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593588.url(scheme.get, call_593588.host, call_593588.base,
                         call_593588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593588, url, valid)

proc call*(call_593589: Call_GetDescribeLoadBalancerPolicyTypes_593575;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593590 = newJObject()
  if PolicyTypeNames != nil:
    query_593590.add "PolicyTypeNames", PolicyTypeNames
  add(query_593590, "Action", newJString(Action))
  add(query_593590, "Version", newJString(Version))
  result = call_593589.call(nil, query_593590, nil, nil, nil)

var getDescribeLoadBalancerPolicyTypes* = Call_GetDescribeLoadBalancerPolicyTypes_593575(
    name: "getDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_GetDescribeLoadBalancerPolicyTypes_593576, base: "/",
    url: url_GetDescribeLoadBalancerPolicyTypes_593577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_593626 = ref object of OpenApiRestCall_592364
proc url_PostDescribeLoadBalancers_593628(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancers_593627(path: JsonNode; query: JsonNode;
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
  var valid_593629 = query.getOrDefault("Action")
  valid_593629 = validateParameter(valid_593629, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_593629 != nil:
    section.add "Action", valid_593629
  var valid_593630 = query.getOrDefault("Version")
  valid_593630 = validateParameter(valid_593630, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593630 != nil:
    section.add "Version", valid_593630
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
  var valid_593631 = header.getOrDefault("X-Amz-Signature")
  valid_593631 = validateParameter(valid_593631, JString, required = false,
                                 default = nil)
  if valid_593631 != nil:
    section.add "X-Amz-Signature", valid_593631
  var valid_593632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593632 = validateParameter(valid_593632, JString, required = false,
                                 default = nil)
  if valid_593632 != nil:
    section.add "X-Amz-Content-Sha256", valid_593632
  var valid_593633 = header.getOrDefault("X-Amz-Date")
  valid_593633 = validateParameter(valid_593633, JString, required = false,
                                 default = nil)
  if valid_593633 != nil:
    section.add "X-Amz-Date", valid_593633
  var valid_593634 = header.getOrDefault("X-Amz-Credential")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "X-Amz-Credential", valid_593634
  var valid_593635 = header.getOrDefault("X-Amz-Security-Token")
  valid_593635 = validateParameter(valid_593635, JString, required = false,
                                 default = nil)
  if valid_593635 != nil:
    section.add "X-Amz-Security-Token", valid_593635
  var valid_593636 = header.getOrDefault("X-Amz-Algorithm")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "X-Amz-Algorithm", valid_593636
  var valid_593637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-SignedHeaders", valid_593637
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  section = newJObject()
  var valid_593638 = formData.getOrDefault("LoadBalancerNames")
  valid_593638 = validateParameter(valid_593638, JArray, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "LoadBalancerNames", valid_593638
  var valid_593639 = formData.getOrDefault("Marker")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "Marker", valid_593639
  var valid_593640 = formData.getOrDefault("PageSize")
  valid_593640 = validateParameter(valid_593640, JInt, required = false, default = nil)
  if valid_593640 != nil:
    section.add "PageSize", valid_593640
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593641: Call_PostDescribeLoadBalancers_593626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_593641.validator(path, query, header, formData, body)
  let scheme = call_593641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593641.url(scheme.get, call_593641.host, call_593641.base,
                         call_593641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593641, url, valid)

proc call*(call_593642: Call_PostDescribeLoadBalancers_593626;
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
  var query_593643 = newJObject()
  var formData_593644 = newJObject()
  if LoadBalancerNames != nil:
    formData_593644.add "LoadBalancerNames", LoadBalancerNames
  add(formData_593644, "Marker", newJString(Marker))
  add(query_593643, "Action", newJString(Action))
  add(formData_593644, "PageSize", newJInt(PageSize))
  add(query_593643, "Version", newJString(Version))
  result = call_593642.call(nil, query_593643, nil, formData_593644, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_593626(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_593627, base: "/",
    url: url_PostDescribeLoadBalancers_593628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_593608 = ref object of OpenApiRestCall_592364
proc url_GetDescribeLoadBalancers_593610(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancers_593609(path: JsonNode; query: JsonNode;
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
  var valid_593611 = query.getOrDefault("Marker")
  valid_593611 = validateParameter(valid_593611, JString, required = false,
                                 default = nil)
  if valid_593611 != nil:
    section.add "Marker", valid_593611
  var valid_593612 = query.getOrDefault("PageSize")
  valid_593612 = validateParameter(valid_593612, JInt, required = false, default = nil)
  if valid_593612 != nil:
    section.add "PageSize", valid_593612
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593613 = query.getOrDefault("Action")
  valid_593613 = validateParameter(valid_593613, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_593613 != nil:
    section.add "Action", valid_593613
  var valid_593614 = query.getOrDefault("Version")
  valid_593614 = validateParameter(valid_593614, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593614 != nil:
    section.add "Version", valid_593614
  var valid_593615 = query.getOrDefault("LoadBalancerNames")
  valid_593615 = validateParameter(valid_593615, JArray, required = false,
                                 default = nil)
  if valid_593615 != nil:
    section.add "LoadBalancerNames", valid_593615
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
  var valid_593616 = header.getOrDefault("X-Amz-Signature")
  valid_593616 = validateParameter(valid_593616, JString, required = false,
                                 default = nil)
  if valid_593616 != nil:
    section.add "X-Amz-Signature", valid_593616
  var valid_593617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593617 = validateParameter(valid_593617, JString, required = false,
                                 default = nil)
  if valid_593617 != nil:
    section.add "X-Amz-Content-Sha256", valid_593617
  var valid_593618 = header.getOrDefault("X-Amz-Date")
  valid_593618 = validateParameter(valid_593618, JString, required = false,
                                 default = nil)
  if valid_593618 != nil:
    section.add "X-Amz-Date", valid_593618
  var valid_593619 = header.getOrDefault("X-Amz-Credential")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-Credential", valid_593619
  var valid_593620 = header.getOrDefault("X-Amz-Security-Token")
  valid_593620 = validateParameter(valid_593620, JString, required = false,
                                 default = nil)
  if valid_593620 != nil:
    section.add "X-Amz-Security-Token", valid_593620
  var valid_593621 = header.getOrDefault("X-Amz-Algorithm")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Algorithm", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-SignedHeaders", valid_593622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593623: Call_GetDescribeLoadBalancers_593608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_593623.validator(path, query, header, formData, body)
  let scheme = call_593623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593623.url(scheme.get, call_593623.host, call_593623.base,
                         call_593623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593623, url, valid)

proc call*(call_593624: Call_GetDescribeLoadBalancers_593608; Marker: string = "";
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
  var query_593625 = newJObject()
  add(query_593625, "Marker", newJString(Marker))
  add(query_593625, "PageSize", newJInt(PageSize))
  add(query_593625, "Action", newJString(Action))
  add(query_593625, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_593625.add "LoadBalancerNames", LoadBalancerNames
  result = call_593624.call(nil, query_593625, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_593608(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_593609, base: "/",
    url: url_GetDescribeLoadBalancers_593610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_593661 = ref object of OpenApiRestCall_592364
proc url_PostDescribeTags_593663(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTags_593662(path: JsonNode; query: JsonNode;
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
  var valid_593664 = query.getOrDefault("Action")
  valid_593664 = validateParameter(valid_593664, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_593664 != nil:
    section.add "Action", valid_593664
  var valid_593665 = query.getOrDefault("Version")
  valid_593665 = validateParameter(valid_593665, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593665 != nil:
    section.add "Version", valid_593665
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
  var valid_593666 = header.getOrDefault("X-Amz-Signature")
  valid_593666 = validateParameter(valid_593666, JString, required = false,
                                 default = nil)
  if valid_593666 != nil:
    section.add "X-Amz-Signature", valid_593666
  var valid_593667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593667 = validateParameter(valid_593667, JString, required = false,
                                 default = nil)
  if valid_593667 != nil:
    section.add "X-Amz-Content-Sha256", valid_593667
  var valid_593668 = header.getOrDefault("X-Amz-Date")
  valid_593668 = validateParameter(valid_593668, JString, required = false,
                                 default = nil)
  if valid_593668 != nil:
    section.add "X-Amz-Date", valid_593668
  var valid_593669 = header.getOrDefault("X-Amz-Credential")
  valid_593669 = validateParameter(valid_593669, JString, required = false,
                                 default = nil)
  if valid_593669 != nil:
    section.add "X-Amz-Credential", valid_593669
  var valid_593670 = header.getOrDefault("X-Amz-Security-Token")
  valid_593670 = validateParameter(valid_593670, JString, required = false,
                                 default = nil)
  if valid_593670 != nil:
    section.add "X-Amz-Security-Token", valid_593670
  var valid_593671 = header.getOrDefault("X-Amz-Algorithm")
  valid_593671 = validateParameter(valid_593671, JString, required = false,
                                 default = nil)
  if valid_593671 != nil:
    section.add "X-Amz-Algorithm", valid_593671
  var valid_593672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593672 = validateParameter(valid_593672, JString, required = false,
                                 default = nil)
  if valid_593672 != nil:
    section.add "X-Amz-SignedHeaders", valid_593672
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_593673 = formData.getOrDefault("LoadBalancerNames")
  valid_593673 = validateParameter(valid_593673, JArray, required = true, default = nil)
  if valid_593673 != nil:
    section.add "LoadBalancerNames", valid_593673
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593674: Call_PostDescribeTags_593661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_593674.validator(path, query, header, formData, body)
  let scheme = call_593674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593674.url(scheme.get, call_593674.host, call_593674.base,
                         call_593674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593674, url, valid)

proc call*(call_593675: Call_PostDescribeTags_593661; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593676 = newJObject()
  var formData_593677 = newJObject()
  if LoadBalancerNames != nil:
    formData_593677.add "LoadBalancerNames", LoadBalancerNames
  add(query_593676, "Action", newJString(Action))
  add(query_593676, "Version", newJString(Version))
  result = call_593675.call(nil, query_593676, nil, formData_593677, nil)

var postDescribeTags* = Call_PostDescribeTags_593661(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_593662,
    base: "/", url: url_PostDescribeTags_593663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_593645 = ref object of OpenApiRestCall_592364
proc url_GetDescribeTags_593647(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTags_593646(path: JsonNode; query: JsonNode;
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
  var valid_593648 = query.getOrDefault("Action")
  valid_593648 = validateParameter(valid_593648, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_593648 != nil:
    section.add "Action", valid_593648
  var valid_593649 = query.getOrDefault("Version")
  valid_593649 = validateParameter(valid_593649, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593649 != nil:
    section.add "Version", valid_593649
  var valid_593650 = query.getOrDefault("LoadBalancerNames")
  valid_593650 = validateParameter(valid_593650, JArray, required = true, default = nil)
  if valid_593650 != nil:
    section.add "LoadBalancerNames", valid_593650
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
  var valid_593651 = header.getOrDefault("X-Amz-Signature")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "X-Amz-Signature", valid_593651
  var valid_593652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "X-Amz-Content-Sha256", valid_593652
  var valid_593653 = header.getOrDefault("X-Amz-Date")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Date", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-Credential")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-Credential", valid_593654
  var valid_593655 = header.getOrDefault("X-Amz-Security-Token")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "X-Amz-Security-Token", valid_593655
  var valid_593656 = header.getOrDefault("X-Amz-Algorithm")
  valid_593656 = validateParameter(valid_593656, JString, required = false,
                                 default = nil)
  if valid_593656 != nil:
    section.add "X-Amz-Algorithm", valid_593656
  var valid_593657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593657 = validateParameter(valid_593657, JString, required = false,
                                 default = nil)
  if valid_593657 != nil:
    section.add "X-Amz-SignedHeaders", valid_593657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593658: Call_GetDescribeTags_593645; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_593658.validator(path, query, header, formData, body)
  let scheme = call_593658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593658.url(scheme.get, call_593658.host, call_593658.base,
                         call_593658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593658, url, valid)

proc call*(call_593659: Call_GetDescribeTags_593645; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  var query_593660 = newJObject()
  add(query_593660, "Action", newJString(Action))
  add(query_593660, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_593660.add "LoadBalancerNames", LoadBalancerNames
  result = call_593659.call(nil, query_593660, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_593645(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_593646,
    base: "/", url: url_GetDescribeTags_593647, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDetachLoadBalancerFromSubnets_593695 = ref object of OpenApiRestCall_592364
proc url_PostDetachLoadBalancerFromSubnets_593697(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDetachLoadBalancerFromSubnets_593696(path: JsonNode;
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
  var valid_593698 = query.getOrDefault("Action")
  valid_593698 = validateParameter(valid_593698, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_593698 != nil:
    section.add "Action", valid_593698
  var valid_593699 = query.getOrDefault("Version")
  valid_593699 = validateParameter(valid_593699, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593699 != nil:
    section.add "Version", valid_593699
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
  var valid_593700 = header.getOrDefault("X-Amz-Signature")
  valid_593700 = validateParameter(valid_593700, JString, required = false,
                                 default = nil)
  if valid_593700 != nil:
    section.add "X-Amz-Signature", valid_593700
  var valid_593701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593701 = validateParameter(valid_593701, JString, required = false,
                                 default = nil)
  if valid_593701 != nil:
    section.add "X-Amz-Content-Sha256", valid_593701
  var valid_593702 = header.getOrDefault("X-Amz-Date")
  valid_593702 = validateParameter(valid_593702, JString, required = false,
                                 default = nil)
  if valid_593702 != nil:
    section.add "X-Amz-Date", valid_593702
  var valid_593703 = header.getOrDefault("X-Amz-Credential")
  valid_593703 = validateParameter(valid_593703, JString, required = false,
                                 default = nil)
  if valid_593703 != nil:
    section.add "X-Amz-Credential", valid_593703
  var valid_593704 = header.getOrDefault("X-Amz-Security-Token")
  valid_593704 = validateParameter(valid_593704, JString, required = false,
                                 default = nil)
  if valid_593704 != nil:
    section.add "X-Amz-Security-Token", valid_593704
  var valid_593705 = header.getOrDefault("X-Amz-Algorithm")
  valid_593705 = validateParameter(valid_593705, JString, required = false,
                                 default = nil)
  if valid_593705 != nil:
    section.add "X-Amz-Algorithm", valid_593705
  var valid_593706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593706 = validateParameter(valid_593706, JString, required = false,
                                 default = nil)
  if valid_593706 != nil:
    section.add "X-Amz-SignedHeaders", valid_593706
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_593707 = formData.getOrDefault("Subnets")
  valid_593707 = validateParameter(valid_593707, JArray, required = true, default = nil)
  if valid_593707 != nil:
    section.add "Subnets", valid_593707
  var valid_593708 = formData.getOrDefault("LoadBalancerName")
  valid_593708 = validateParameter(valid_593708, JString, required = true,
                                 default = nil)
  if valid_593708 != nil:
    section.add "LoadBalancerName", valid_593708
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593709: Call_PostDetachLoadBalancerFromSubnets_593695;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_593709.validator(path, query, header, formData, body)
  let scheme = call_593709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593709.url(scheme.get, call_593709.host, call_593709.base,
                         call_593709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593709, url, valid)

proc call*(call_593710: Call_PostDetachLoadBalancerFromSubnets_593695;
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
  var query_593711 = newJObject()
  var formData_593712 = newJObject()
  if Subnets != nil:
    formData_593712.add "Subnets", Subnets
  add(formData_593712, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593711, "Action", newJString(Action))
  add(query_593711, "Version", newJString(Version))
  result = call_593710.call(nil, query_593711, nil, formData_593712, nil)

var postDetachLoadBalancerFromSubnets* = Call_PostDetachLoadBalancerFromSubnets_593695(
    name: "postDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_PostDetachLoadBalancerFromSubnets_593696, base: "/",
    url: url_PostDetachLoadBalancerFromSubnets_593697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetachLoadBalancerFromSubnets_593678 = ref object of OpenApiRestCall_592364
proc url_GetDetachLoadBalancerFromSubnets_593680(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDetachLoadBalancerFromSubnets_593679(path: JsonNode;
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
  var valid_593681 = query.getOrDefault("LoadBalancerName")
  valid_593681 = validateParameter(valid_593681, JString, required = true,
                                 default = nil)
  if valid_593681 != nil:
    section.add "LoadBalancerName", valid_593681
  var valid_593682 = query.getOrDefault("Action")
  valid_593682 = validateParameter(valid_593682, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_593682 != nil:
    section.add "Action", valid_593682
  var valid_593683 = query.getOrDefault("Subnets")
  valid_593683 = validateParameter(valid_593683, JArray, required = true, default = nil)
  if valid_593683 != nil:
    section.add "Subnets", valid_593683
  var valid_593684 = query.getOrDefault("Version")
  valid_593684 = validateParameter(valid_593684, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593684 != nil:
    section.add "Version", valid_593684
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
  var valid_593685 = header.getOrDefault("X-Amz-Signature")
  valid_593685 = validateParameter(valid_593685, JString, required = false,
                                 default = nil)
  if valid_593685 != nil:
    section.add "X-Amz-Signature", valid_593685
  var valid_593686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593686 = validateParameter(valid_593686, JString, required = false,
                                 default = nil)
  if valid_593686 != nil:
    section.add "X-Amz-Content-Sha256", valid_593686
  var valid_593687 = header.getOrDefault("X-Amz-Date")
  valid_593687 = validateParameter(valid_593687, JString, required = false,
                                 default = nil)
  if valid_593687 != nil:
    section.add "X-Amz-Date", valid_593687
  var valid_593688 = header.getOrDefault("X-Amz-Credential")
  valid_593688 = validateParameter(valid_593688, JString, required = false,
                                 default = nil)
  if valid_593688 != nil:
    section.add "X-Amz-Credential", valid_593688
  var valid_593689 = header.getOrDefault("X-Amz-Security-Token")
  valid_593689 = validateParameter(valid_593689, JString, required = false,
                                 default = nil)
  if valid_593689 != nil:
    section.add "X-Amz-Security-Token", valid_593689
  var valid_593690 = header.getOrDefault("X-Amz-Algorithm")
  valid_593690 = validateParameter(valid_593690, JString, required = false,
                                 default = nil)
  if valid_593690 != nil:
    section.add "X-Amz-Algorithm", valid_593690
  var valid_593691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593691 = validateParameter(valid_593691, JString, required = false,
                                 default = nil)
  if valid_593691 != nil:
    section.add "X-Amz-SignedHeaders", valid_593691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593692: Call_GetDetachLoadBalancerFromSubnets_593678;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_593692.validator(path, query, header, formData, body)
  let scheme = call_593692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593692.url(scheme.get, call_593692.host, call_593692.base,
                         call_593692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593692, url, valid)

proc call*(call_593693: Call_GetDetachLoadBalancerFromSubnets_593678;
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
  var query_593694 = newJObject()
  add(query_593694, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593694, "Action", newJString(Action))
  if Subnets != nil:
    query_593694.add "Subnets", Subnets
  add(query_593694, "Version", newJString(Version))
  result = call_593693.call(nil, query_593694, nil, nil, nil)

var getDetachLoadBalancerFromSubnets* = Call_GetDetachLoadBalancerFromSubnets_593678(
    name: "getDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_GetDetachLoadBalancerFromSubnets_593679, base: "/",
    url: url_GetDetachLoadBalancerFromSubnets_593680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAvailabilityZonesForLoadBalancer_593730 = ref object of OpenApiRestCall_592364
proc url_PostDisableAvailabilityZonesForLoadBalancer_593732(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDisableAvailabilityZonesForLoadBalancer_593731(path: JsonNode;
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
  var valid_593733 = query.getOrDefault("Action")
  valid_593733 = validateParameter(valid_593733, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_593733 != nil:
    section.add "Action", valid_593733
  var valid_593734 = query.getOrDefault("Version")
  valid_593734 = validateParameter(valid_593734, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593734 != nil:
    section.add "Version", valid_593734
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
  var valid_593735 = header.getOrDefault("X-Amz-Signature")
  valid_593735 = validateParameter(valid_593735, JString, required = false,
                                 default = nil)
  if valid_593735 != nil:
    section.add "X-Amz-Signature", valid_593735
  var valid_593736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593736 = validateParameter(valid_593736, JString, required = false,
                                 default = nil)
  if valid_593736 != nil:
    section.add "X-Amz-Content-Sha256", valid_593736
  var valid_593737 = header.getOrDefault("X-Amz-Date")
  valid_593737 = validateParameter(valid_593737, JString, required = false,
                                 default = nil)
  if valid_593737 != nil:
    section.add "X-Amz-Date", valid_593737
  var valid_593738 = header.getOrDefault("X-Amz-Credential")
  valid_593738 = validateParameter(valid_593738, JString, required = false,
                                 default = nil)
  if valid_593738 != nil:
    section.add "X-Amz-Credential", valid_593738
  var valid_593739 = header.getOrDefault("X-Amz-Security-Token")
  valid_593739 = validateParameter(valid_593739, JString, required = false,
                                 default = nil)
  if valid_593739 != nil:
    section.add "X-Amz-Security-Token", valid_593739
  var valid_593740 = header.getOrDefault("X-Amz-Algorithm")
  valid_593740 = validateParameter(valid_593740, JString, required = false,
                                 default = nil)
  if valid_593740 != nil:
    section.add "X-Amz-Algorithm", valid_593740
  var valid_593741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593741 = validateParameter(valid_593741, JString, required = false,
                                 default = nil)
  if valid_593741 != nil:
    section.add "X-Amz-SignedHeaders", valid_593741
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_593742 = formData.getOrDefault("AvailabilityZones")
  valid_593742 = validateParameter(valid_593742, JArray, required = true, default = nil)
  if valid_593742 != nil:
    section.add "AvailabilityZones", valid_593742
  var valid_593743 = formData.getOrDefault("LoadBalancerName")
  valid_593743 = validateParameter(valid_593743, JString, required = true,
                                 default = nil)
  if valid_593743 != nil:
    section.add "LoadBalancerName", valid_593743
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593744: Call_PostDisableAvailabilityZonesForLoadBalancer_593730;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593744.validator(path, query, header, formData, body)
  let scheme = call_593744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593744.url(scheme.get, call_593744.host, call_593744.base,
                         call_593744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593744, url, valid)

proc call*(call_593745: Call_PostDisableAvailabilityZonesForLoadBalancer_593730;
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
  var query_593746 = newJObject()
  var formData_593747 = newJObject()
  if AvailabilityZones != nil:
    formData_593747.add "AvailabilityZones", AvailabilityZones
  add(formData_593747, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593746, "Action", newJString(Action))
  add(query_593746, "Version", newJString(Version))
  result = call_593745.call(nil, query_593746, nil, formData_593747, nil)

var postDisableAvailabilityZonesForLoadBalancer* = Call_PostDisableAvailabilityZonesForLoadBalancer_593730(
    name: "postDisableAvailabilityZonesForLoadBalancer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_PostDisableAvailabilityZonesForLoadBalancer_593731,
    base: "/", url: url_PostDisableAvailabilityZonesForLoadBalancer_593732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAvailabilityZonesForLoadBalancer_593713 = ref object of OpenApiRestCall_592364
proc url_GetDisableAvailabilityZonesForLoadBalancer_593715(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDisableAvailabilityZonesForLoadBalancer_593714(path: JsonNode;
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
  var valid_593716 = query.getOrDefault("AvailabilityZones")
  valid_593716 = validateParameter(valid_593716, JArray, required = true, default = nil)
  if valid_593716 != nil:
    section.add "AvailabilityZones", valid_593716
  var valid_593717 = query.getOrDefault("LoadBalancerName")
  valid_593717 = validateParameter(valid_593717, JString, required = true,
                                 default = nil)
  if valid_593717 != nil:
    section.add "LoadBalancerName", valid_593717
  var valid_593718 = query.getOrDefault("Action")
  valid_593718 = validateParameter(valid_593718, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_593718 != nil:
    section.add "Action", valid_593718
  var valid_593719 = query.getOrDefault("Version")
  valid_593719 = validateParameter(valid_593719, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593719 != nil:
    section.add "Version", valid_593719
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
  var valid_593720 = header.getOrDefault("X-Amz-Signature")
  valid_593720 = validateParameter(valid_593720, JString, required = false,
                                 default = nil)
  if valid_593720 != nil:
    section.add "X-Amz-Signature", valid_593720
  var valid_593721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593721 = validateParameter(valid_593721, JString, required = false,
                                 default = nil)
  if valid_593721 != nil:
    section.add "X-Amz-Content-Sha256", valid_593721
  var valid_593722 = header.getOrDefault("X-Amz-Date")
  valid_593722 = validateParameter(valid_593722, JString, required = false,
                                 default = nil)
  if valid_593722 != nil:
    section.add "X-Amz-Date", valid_593722
  var valid_593723 = header.getOrDefault("X-Amz-Credential")
  valid_593723 = validateParameter(valid_593723, JString, required = false,
                                 default = nil)
  if valid_593723 != nil:
    section.add "X-Amz-Credential", valid_593723
  var valid_593724 = header.getOrDefault("X-Amz-Security-Token")
  valid_593724 = validateParameter(valid_593724, JString, required = false,
                                 default = nil)
  if valid_593724 != nil:
    section.add "X-Amz-Security-Token", valid_593724
  var valid_593725 = header.getOrDefault("X-Amz-Algorithm")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "X-Amz-Algorithm", valid_593725
  var valid_593726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = nil)
  if valid_593726 != nil:
    section.add "X-Amz-SignedHeaders", valid_593726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593727: Call_GetDisableAvailabilityZonesForLoadBalancer_593713;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593727.validator(path, query, header, formData, body)
  let scheme = call_593727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593727.url(scheme.get, call_593727.host, call_593727.base,
                         call_593727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593727, url, valid)

proc call*(call_593728: Call_GetDisableAvailabilityZonesForLoadBalancer_593713;
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
  var query_593729 = newJObject()
  if AvailabilityZones != nil:
    query_593729.add "AvailabilityZones", AvailabilityZones
  add(query_593729, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593729, "Action", newJString(Action))
  add(query_593729, "Version", newJString(Version))
  result = call_593728.call(nil, query_593729, nil, nil, nil)

var getDisableAvailabilityZonesForLoadBalancer* = Call_GetDisableAvailabilityZonesForLoadBalancer_593713(
    name: "getDisableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_GetDisableAvailabilityZonesForLoadBalancer_593714,
    base: "/", url: url_GetDisableAvailabilityZonesForLoadBalancer_593715,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAvailabilityZonesForLoadBalancer_593765 = ref object of OpenApiRestCall_592364
proc url_PostEnableAvailabilityZonesForLoadBalancer_593767(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostEnableAvailabilityZonesForLoadBalancer_593766(path: JsonNode;
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
  var valid_593768 = query.getOrDefault("Action")
  valid_593768 = validateParameter(valid_593768, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_593768 != nil:
    section.add "Action", valid_593768
  var valid_593769 = query.getOrDefault("Version")
  valid_593769 = validateParameter(valid_593769, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593769 != nil:
    section.add "Version", valid_593769
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
  var valid_593770 = header.getOrDefault("X-Amz-Signature")
  valid_593770 = validateParameter(valid_593770, JString, required = false,
                                 default = nil)
  if valid_593770 != nil:
    section.add "X-Amz-Signature", valid_593770
  var valid_593771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593771 = validateParameter(valid_593771, JString, required = false,
                                 default = nil)
  if valid_593771 != nil:
    section.add "X-Amz-Content-Sha256", valid_593771
  var valid_593772 = header.getOrDefault("X-Amz-Date")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "X-Amz-Date", valid_593772
  var valid_593773 = header.getOrDefault("X-Amz-Credential")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "X-Amz-Credential", valid_593773
  var valid_593774 = header.getOrDefault("X-Amz-Security-Token")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "X-Amz-Security-Token", valid_593774
  var valid_593775 = header.getOrDefault("X-Amz-Algorithm")
  valid_593775 = validateParameter(valid_593775, JString, required = false,
                                 default = nil)
  if valid_593775 != nil:
    section.add "X-Amz-Algorithm", valid_593775
  var valid_593776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "X-Amz-SignedHeaders", valid_593776
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_593777 = formData.getOrDefault("AvailabilityZones")
  valid_593777 = validateParameter(valid_593777, JArray, required = true, default = nil)
  if valid_593777 != nil:
    section.add "AvailabilityZones", valid_593777
  var valid_593778 = formData.getOrDefault("LoadBalancerName")
  valid_593778 = validateParameter(valid_593778, JString, required = true,
                                 default = nil)
  if valid_593778 != nil:
    section.add "LoadBalancerName", valid_593778
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593779: Call_PostEnableAvailabilityZonesForLoadBalancer_593765;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593779.validator(path, query, header, formData, body)
  let scheme = call_593779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593779.url(scheme.get, call_593779.host, call_593779.base,
                         call_593779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593779, url, valid)

proc call*(call_593780: Call_PostEnableAvailabilityZonesForLoadBalancer_593765;
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
  var query_593781 = newJObject()
  var formData_593782 = newJObject()
  if AvailabilityZones != nil:
    formData_593782.add "AvailabilityZones", AvailabilityZones
  add(formData_593782, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593781, "Action", newJString(Action))
  add(query_593781, "Version", newJString(Version))
  result = call_593780.call(nil, query_593781, nil, formData_593782, nil)

var postEnableAvailabilityZonesForLoadBalancer* = Call_PostEnableAvailabilityZonesForLoadBalancer_593765(
    name: "postEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_PostEnableAvailabilityZonesForLoadBalancer_593766,
    base: "/", url: url_PostEnableAvailabilityZonesForLoadBalancer_593767,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAvailabilityZonesForLoadBalancer_593748 = ref object of OpenApiRestCall_592364
proc url_GetEnableAvailabilityZonesForLoadBalancer_593750(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetEnableAvailabilityZonesForLoadBalancer_593749(path: JsonNode;
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
  var valid_593751 = query.getOrDefault("AvailabilityZones")
  valid_593751 = validateParameter(valid_593751, JArray, required = true, default = nil)
  if valid_593751 != nil:
    section.add "AvailabilityZones", valid_593751
  var valid_593752 = query.getOrDefault("LoadBalancerName")
  valid_593752 = validateParameter(valid_593752, JString, required = true,
                                 default = nil)
  if valid_593752 != nil:
    section.add "LoadBalancerName", valid_593752
  var valid_593753 = query.getOrDefault("Action")
  valid_593753 = validateParameter(valid_593753, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_593753 != nil:
    section.add "Action", valid_593753
  var valid_593754 = query.getOrDefault("Version")
  valid_593754 = validateParameter(valid_593754, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593754 != nil:
    section.add "Version", valid_593754
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
  var valid_593755 = header.getOrDefault("X-Amz-Signature")
  valid_593755 = validateParameter(valid_593755, JString, required = false,
                                 default = nil)
  if valid_593755 != nil:
    section.add "X-Amz-Signature", valid_593755
  var valid_593756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593756 = validateParameter(valid_593756, JString, required = false,
                                 default = nil)
  if valid_593756 != nil:
    section.add "X-Amz-Content-Sha256", valid_593756
  var valid_593757 = header.getOrDefault("X-Amz-Date")
  valid_593757 = validateParameter(valid_593757, JString, required = false,
                                 default = nil)
  if valid_593757 != nil:
    section.add "X-Amz-Date", valid_593757
  var valid_593758 = header.getOrDefault("X-Amz-Credential")
  valid_593758 = validateParameter(valid_593758, JString, required = false,
                                 default = nil)
  if valid_593758 != nil:
    section.add "X-Amz-Credential", valid_593758
  var valid_593759 = header.getOrDefault("X-Amz-Security-Token")
  valid_593759 = validateParameter(valid_593759, JString, required = false,
                                 default = nil)
  if valid_593759 != nil:
    section.add "X-Amz-Security-Token", valid_593759
  var valid_593760 = header.getOrDefault("X-Amz-Algorithm")
  valid_593760 = validateParameter(valid_593760, JString, required = false,
                                 default = nil)
  if valid_593760 != nil:
    section.add "X-Amz-Algorithm", valid_593760
  var valid_593761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593761 = validateParameter(valid_593761, JString, required = false,
                                 default = nil)
  if valid_593761 != nil:
    section.add "X-Amz-SignedHeaders", valid_593761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593762: Call_GetEnableAvailabilityZonesForLoadBalancer_593748;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593762.validator(path, query, header, formData, body)
  let scheme = call_593762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593762.url(scheme.get, call_593762.host, call_593762.base,
                         call_593762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593762, url, valid)

proc call*(call_593763: Call_GetEnableAvailabilityZonesForLoadBalancer_593748;
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
  var query_593764 = newJObject()
  if AvailabilityZones != nil:
    query_593764.add "AvailabilityZones", AvailabilityZones
  add(query_593764, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593764, "Action", newJString(Action))
  add(query_593764, "Version", newJString(Version))
  result = call_593763.call(nil, query_593764, nil, nil, nil)

var getEnableAvailabilityZonesForLoadBalancer* = Call_GetEnableAvailabilityZonesForLoadBalancer_593748(
    name: "getEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_GetEnableAvailabilityZonesForLoadBalancer_593749,
    base: "/", url: url_GetEnableAvailabilityZonesForLoadBalancer_593750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_593804 = ref object of OpenApiRestCall_592364
proc url_PostModifyLoadBalancerAttributes_593806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyLoadBalancerAttributes_593805(path: JsonNode;
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
  var valid_593807 = query.getOrDefault("Action")
  valid_593807 = validateParameter(valid_593807, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_593807 != nil:
    section.add "Action", valid_593807
  var valid_593808 = query.getOrDefault("Version")
  valid_593808 = validateParameter(valid_593808, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593808 != nil:
    section.add "Version", valid_593808
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
  var valid_593809 = header.getOrDefault("X-Amz-Signature")
  valid_593809 = validateParameter(valid_593809, JString, required = false,
                                 default = nil)
  if valid_593809 != nil:
    section.add "X-Amz-Signature", valid_593809
  var valid_593810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593810 = validateParameter(valid_593810, JString, required = false,
                                 default = nil)
  if valid_593810 != nil:
    section.add "X-Amz-Content-Sha256", valid_593810
  var valid_593811 = header.getOrDefault("X-Amz-Date")
  valid_593811 = validateParameter(valid_593811, JString, required = false,
                                 default = nil)
  if valid_593811 != nil:
    section.add "X-Amz-Date", valid_593811
  var valid_593812 = header.getOrDefault("X-Amz-Credential")
  valid_593812 = validateParameter(valid_593812, JString, required = false,
                                 default = nil)
  if valid_593812 != nil:
    section.add "X-Amz-Credential", valid_593812
  var valid_593813 = header.getOrDefault("X-Amz-Security-Token")
  valid_593813 = validateParameter(valid_593813, JString, required = false,
                                 default = nil)
  if valid_593813 != nil:
    section.add "X-Amz-Security-Token", valid_593813
  var valid_593814 = header.getOrDefault("X-Amz-Algorithm")
  valid_593814 = validateParameter(valid_593814, JString, required = false,
                                 default = nil)
  if valid_593814 != nil:
    section.add "X-Amz-Algorithm", valid_593814
  var valid_593815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593815 = validateParameter(valid_593815, JString, required = false,
                                 default = nil)
  if valid_593815 != nil:
    section.add "X-Amz-SignedHeaders", valid_593815
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
  var valid_593816 = formData.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_593816 = validateParameter(valid_593816, JString, required = false,
                                 default = nil)
  if valid_593816 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_593816
  var valid_593817 = formData.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_593817 = validateParameter(valid_593817, JArray, required = false,
                                 default = nil)
  if valid_593817 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_593817
  var valid_593818 = formData.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_593818 = validateParameter(valid_593818, JString, required = false,
                                 default = nil)
  if valid_593818 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_593818
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_593819 = formData.getOrDefault("LoadBalancerName")
  valid_593819 = validateParameter(valid_593819, JString, required = true,
                                 default = nil)
  if valid_593819 != nil:
    section.add "LoadBalancerName", valid_593819
  var valid_593820 = formData.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_593820 = validateParameter(valid_593820, JString, required = false,
                                 default = nil)
  if valid_593820 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_593820
  var valid_593821 = formData.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = nil)
  if valid_593821 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_593821
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593822: Call_PostModifyLoadBalancerAttributes_593804;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_593822.validator(path, query, header, formData, body)
  let scheme = call_593822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593822.url(scheme.get, call_593822.host, call_593822.base,
                         call_593822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593822, url, valid)

proc call*(call_593823: Call_PostModifyLoadBalancerAttributes_593804;
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
  var query_593824 = newJObject()
  var formData_593825 = newJObject()
  add(formData_593825, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    formData_593825.add "LoadBalancerAttributes.AdditionalAttributes",
                       LoadBalancerAttributesAdditionalAttributes
  add(formData_593825, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(formData_593825, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593824, "Action", newJString(Action))
  add(formData_593825, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_593824, "Version", newJString(Version))
  add(formData_593825, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  result = call_593823.call(nil, query_593824, nil, formData_593825, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_593804(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_593805, base: "/",
    url: url_PostModifyLoadBalancerAttributes_593806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_593783 = ref object of OpenApiRestCall_592364
proc url_GetModifyLoadBalancerAttributes_593785(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyLoadBalancerAttributes_593784(path: JsonNode;
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
  var valid_593786 = query.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_593786
  var valid_593787 = query.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_593787
  var valid_593788 = query.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_593788 = validateParameter(valid_593788, JString, required = false,
                                 default = nil)
  if valid_593788 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_593788
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_593789 = query.getOrDefault("LoadBalancerName")
  valid_593789 = validateParameter(valid_593789, JString, required = true,
                                 default = nil)
  if valid_593789 != nil:
    section.add "LoadBalancerName", valid_593789
  var valid_593790 = query.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_593790
  var valid_593791 = query.getOrDefault("Action")
  valid_593791 = validateParameter(valid_593791, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_593791 != nil:
    section.add "Action", valid_593791
  var valid_593792 = query.getOrDefault("Version")
  valid_593792 = validateParameter(valid_593792, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593792 != nil:
    section.add "Version", valid_593792
  var valid_593793 = query.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_593793 = validateParameter(valid_593793, JArray, required = false,
                                 default = nil)
  if valid_593793 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_593793
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
  var valid_593794 = header.getOrDefault("X-Amz-Signature")
  valid_593794 = validateParameter(valid_593794, JString, required = false,
                                 default = nil)
  if valid_593794 != nil:
    section.add "X-Amz-Signature", valid_593794
  var valid_593795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593795 = validateParameter(valid_593795, JString, required = false,
                                 default = nil)
  if valid_593795 != nil:
    section.add "X-Amz-Content-Sha256", valid_593795
  var valid_593796 = header.getOrDefault("X-Amz-Date")
  valid_593796 = validateParameter(valid_593796, JString, required = false,
                                 default = nil)
  if valid_593796 != nil:
    section.add "X-Amz-Date", valid_593796
  var valid_593797 = header.getOrDefault("X-Amz-Credential")
  valid_593797 = validateParameter(valid_593797, JString, required = false,
                                 default = nil)
  if valid_593797 != nil:
    section.add "X-Amz-Credential", valid_593797
  var valid_593798 = header.getOrDefault("X-Amz-Security-Token")
  valid_593798 = validateParameter(valid_593798, JString, required = false,
                                 default = nil)
  if valid_593798 != nil:
    section.add "X-Amz-Security-Token", valid_593798
  var valid_593799 = header.getOrDefault("X-Amz-Algorithm")
  valid_593799 = validateParameter(valid_593799, JString, required = false,
                                 default = nil)
  if valid_593799 != nil:
    section.add "X-Amz-Algorithm", valid_593799
  var valid_593800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593800 = validateParameter(valid_593800, JString, required = false,
                                 default = nil)
  if valid_593800 != nil:
    section.add "X-Amz-SignedHeaders", valid_593800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593801: Call_GetModifyLoadBalancerAttributes_593783;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_593801.validator(path, query, header, formData, body)
  let scheme = call_593801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593801.url(scheme.get, call_593801.host, call_593801.base,
                         call_593801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593801, url, valid)

proc call*(call_593802: Call_GetModifyLoadBalancerAttributes_593783;
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
  var query_593803 = newJObject()
  add(query_593803, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_593803, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_593803, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_593803, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593803, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  add(query_593803, "Action", newJString(Action))
  add(query_593803, "Version", newJString(Version))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    query_593803.add "LoadBalancerAttributes.AdditionalAttributes",
                    LoadBalancerAttributesAdditionalAttributes
  result = call_593802.call(nil, query_593803, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_593783(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_593784, base: "/",
    url: url_GetModifyLoadBalancerAttributes_593785,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterInstancesWithLoadBalancer_593843 = ref object of OpenApiRestCall_592364
proc url_PostRegisterInstancesWithLoadBalancer_593845(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRegisterInstancesWithLoadBalancer_593844(path: JsonNode;
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
  var valid_593846 = query.getOrDefault("Action")
  valid_593846 = validateParameter(valid_593846, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_593846 != nil:
    section.add "Action", valid_593846
  var valid_593847 = query.getOrDefault("Version")
  valid_593847 = validateParameter(valid_593847, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593847 != nil:
    section.add "Version", valid_593847
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
  var valid_593848 = header.getOrDefault("X-Amz-Signature")
  valid_593848 = validateParameter(valid_593848, JString, required = false,
                                 default = nil)
  if valid_593848 != nil:
    section.add "X-Amz-Signature", valid_593848
  var valid_593849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593849 = validateParameter(valid_593849, JString, required = false,
                                 default = nil)
  if valid_593849 != nil:
    section.add "X-Amz-Content-Sha256", valid_593849
  var valid_593850 = header.getOrDefault("X-Amz-Date")
  valid_593850 = validateParameter(valid_593850, JString, required = false,
                                 default = nil)
  if valid_593850 != nil:
    section.add "X-Amz-Date", valid_593850
  var valid_593851 = header.getOrDefault("X-Amz-Credential")
  valid_593851 = validateParameter(valid_593851, JString, required = false,
                                 default = nil)
  if valid_593851 != nil:
    section.add "X-Amz-Credential", valid_593851
  var valid_593852 = header.getOrDefault("X-Amz-Security-Token")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "X-Amz-Security-Token", valid_593852
  var valid_593853 = header.getOrDefault("X-Amz-Algorithm")
  valid_593853 = validateParameter(valid_593853, JString, required = false,
                                 default = nil)
  if valid_593853 != nil:
    section.add "X-Amz-Algorithm", valid_593853
  var valid_593854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "X-Amz-SignedHeaders", valid_593854
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_593855 = formData.getOrDefault("Instances")
  valid_593855 = validateParameter(valid_593855, JArray, required = true, default = nil)
  if valid_593855 != nil:
    section.add "Instances", valid_593855
  var valid_593856 = formData.getOrDefault("LoadBalancerName")
  valid_593856 = validateParameter(valid_593856, JString, required = true,
                                 default = nil)
  if valid_593856 != nil:
    section.add "LoadBalancerName", valid_593856
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593857: Call_PostRegisterInstancesWithLoadBalancer_593843;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593857.validator(path, query, header, formData, body)
  let scheme = call_593857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593857.url(scheme.get, call_593857.host, call_593857.base,
                         call_593857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593857, url, valid)

proc call*(call_593858: Call_PostRegisterInstancesWithLoadBalancer_593843;
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
  var query_593859 = newJObject()
  var formData_593860 = newJObject()
  if Instances != nil:
    formData_593860.add "Instances", Instances
  add(formData_593860, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593859, "Action", newJString(Action))
  add(query_593859, "Version", newJString(Version))
  result = call_593858.call(nil, query_593859, nil, formData_593860, nil)

var postRegisterInstancesWithLoadBalancer* = Call_PostRegisterInstancesWithLoadBalancer_593843(
    name: "postRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_PostRegisterInstancesWithLoadBalancer_593844, base: "/",
    url: url_PostRegisterInstancesWithLoadBalancer_593845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterInstancesWithLoadBalancer_593826 = ref object of OpenApiRestCall_592364
proc url_GetRegisterInstancesWithLoadBalancer_593828(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRegisterInstancesWithLoadBalancer_593827(path: JsonNode;
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
  var valid_593829 = query.getOrDefault("LoadBalancerName")
  valid_593829 = validateParameter(valid_593829, JString, required = true,
                                 default = nil)
  if valid_593829 != nil:
    section.add "LoadBalancerName", valid_593829
  var valid_593830 = query.getOrDefault("Action")
  valid_593830 = validateParameter(valid_593830, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_593830 != nil:
    section.add "Action", valid_593830
  var valid_593831 = query.getOrDefault("Instances")
  valid_593831 = validateParameter(valid_593831, JArray, required = true, default = nil)
  if valid_593831 != nil:
    section.add "Instances", valid_593831
  var valid_593832 = query.getOrDefault("Version")
  valid_593832 = validateParameter(valid_593832, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593832 != nil:
    section.add "Version", valid_593832
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
  var valid_593833 = header.getOrDefault("X-Amz-Signature")
  valid_593833 = validateParameter(valid_593833, JString, required = false,
                                 default = nil)
  if valid_593833 != nil:
    section.add "X-Amz-Signature", valid_593833
  var valid_593834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593834 = validateParameter(valid_593834, JString, required = false,
                                 default = nil)
  if valid_593834 != nil:
    section.add "X-Amz-Content-Sha256", valid_593834
  var valid_593835 = header.getOrDefault("X-Amz-Date")
  valid_593835 = validateParameter(valid_593835, JString, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "X-Amz-Date", valid_593835
  var valid_593836 = header.getOrDefault("X-Amz-Credential")
  valid_593836 = validateParameter(valid_593836, JString, required = false,
                                 default = nil)
  if valid_593836 != nil:
    section.add "X-Amz-Credential", valid_593836
  var valid_593837 = header.getOrDefault("X-Amz-Security-Token")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-Security-Token", valid_593837
  var valid_593838 = header.getOrDefault("X-Amz-Algorithm")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "X-Amz-Algorithm", valid_593838
  var valid_593839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "X-Amz-SignedHeaders", valid_593839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593840: Call_GetRegisterInstancesWithLoadBalancer_593826;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593840.validator(path, query, header, formData, body)
  let scheme = call_593840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593840.url(scheme.get, call_593840.host, call_593840.base,
                         call_593840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593840, url, valid)

proc call*(call_593841: Call_GetRegisterInstancesWithLoadBalancer_593826;
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
  var query_593842 = newJObject()
  add(query_593842, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593842, "Action", newJString(Action))
  if Instances != nil:
    query_593842.add "Instances", Instances
  add(query_593842, "Version", newJString(Version))
  result = call_593841.call(nil, query_593842, nil, nil, nil)

var getRegisterInstancesWithLoadBalancer* = Call_GetRegisterInstancesWithLoadBalancer_593826(
    name: "getRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_GetRegisterInstancesWithLoadBalancer_593827, base: "/",
    url: url_GetRegisterInstancesWithLoadBalancer_593828,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_593878 = ref object of OpenApiRestCall_592364
proc url_PostRemoveTags_593880(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTags_593879(path: JsonNode; query: JsonNode;
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
  var valid_593881 = query.getOrDefault("Action")
  valid_593881 = validateParameter(valid_593881, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_593881 != nil:
    section.add "Action", valid_593881
  var valid_593882 = query.getOrDefault("Version")
  valid_593882 = validateParameter(valid_593882, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593882 != nil:
    section.add "Version", valid_593882
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
  var valid_593883 = header.getOrDefault("X-Amz-Signature")
  valid_593883 = validateParameter(valid_593883, JString, required = false,
                                 default = nil)
  if valid_593883 != nil:
    section.add "X-Amz-Signature", valid_593883
  var valid_593884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593884 = validateParameter(valid_593884, JString, required = false,
                                 default = nil)
  if valid_593884 != nil:
    section.add "X-Amz-Content-Sha256", valid_593884
  var valid_593885 = header.getOrDefault("X-Amz-Date")
  valid_593885 = validateParameter(valid_593885, JString, required = false,
                                 default = nil)
  if valid_593885 != nil:
    section.add "X-Amz-Date", valid_593885
  var valid_593886 = header.getOrDefault("X-Amz-Credential")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "X-Amz-Credential", valid_593886
  var valid_593887 = header.getOrDefault("X-Amz-Security-Token")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "X-Amz-Security-Token", valid_593887
  var valid_593888 = header.getOrDefault("X-Amz-Algorithm")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Algorithm", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-SignedHeaders", valid_593889
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_593890 = formData.getOrDefault("LoadBalancerNames")
  valid_593890 = validateParameter(valid_593890, JArray, required = true, default = nil)
  if valid_593890 != nil:
    section.add "LoadBalancerNames", valid_593890
  var valid_593891 = formData.getOrDefault("Tags")
  valid_593891 = validateParameter(valid_593891, JArray, required = true, default = nil)
  if valid_593891 != nil:
    section.add "Tags", valid_593891
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593892: Call_PostRemoveTags_593878; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_593892.validator(path, query, header, formData, body)
  let scheme = call_593892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593892.url(scheme.get, call_593892.host, call_593892.base,
                         call_593892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593892, url, valid)

proc call*(call_593893: Call_PostRemoveTags_593878; LoadBalancerNames: JsonNode;
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
  var query_593894 = newJObject()
  var formData_593895 = newJObject()
  if LoadBalancerNames != nil:
    formData_593895.add "LoadBalancerNames", LoadBalancerNames
  add(query_593894, "Action", newJString(Action))
  if Tags != nil:
    formData_593895.add "Tags", Tags
  add(query_593894, "Version", newJString(Version))
  result = call_593893.call(nil, query_593894, nil, formData_593895, nil)

var postRemoveTags* = Call_PostRemoveTags_593878(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_593879,
    base: "/", url: url_PostRemoveTags_593880, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_593861 = ref object of OpenApiRestCall_592364
proc url_GetRemoveTags_593863(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTags_593862(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593864 = query.getOrDefault("Tags")
  valid_593864 = validateParameter(valid_593864, JArray, required = true, default = nil)
  if valid_593864 != nil:
    section.add "Tags", valid_593864
  var valid_593865 = query.getOrDefault("Action")
  valid_593865 = validateParameter(valid_593865, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_593865 != nil:
    section.add "Action", valid_593865
  var valid_593866 = query.getOrDefault("Version")
  valid_593866 = validateParameter(valid_593866, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593866 != nil:
    section.add "Version", valid_593866
  var valid_593867 = query.getOrDefault("LoadBalancerNames")
  valid_593867 = validateParameter(valid_593867, JArray, required = true, default = nil)
  if valid_593867 != nil:
    section.add "LoadBalancerNames", valid_593867
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
  var valid_593868 = header.getOrDefault("X-Amz-Signature")
  valid_593868 = validateParameter(valid_593868, JString, required = false,
                                 default = nil)
  if valid_593868 != nil:
    section.add "X-Amz-Signature", valid_593868
  var valid_593869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593869 = validateParameter(valid_593869, JString, required = false,
                                 default = nil)
  if valid_593869 != nil:
    section.add "X-Amz-Content-Sha256", valid_593869
  var valid_593870 = header.getOrDefault("X-Amz-Date")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "X-Amz-Date", valid_593870
  var valid_593871 = header.getOrDefault("X-Amz-Credential")
  valid_593871 = validateParameter(valid_593871, JString, required = false,
                                 default = nil)
  if valid_593871 != nil:
    section.add "X-Amz-Credential", valid_593871
  var valid_593872 = header.getOrDefault("X-Amz-Security-Token")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "X-Amz-Security-Token", valid_593872
  var valid_593873 = header.getOrDefault("X-Amz-Algorithm")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "X-Amz-Algorithm", valid_593873
  var valid_593874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593874 = validateParameter(valid_593874, JString, required = false,
                                 default = nil)
  if valid_593874 != nil:
    section.add "X-Amz-SignedHeaders", valid_593874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593875: Call_GetRemoveTags_593861; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_593875.validator(path, query, header, formData, body)
  let scheme = call_593875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593875.url(scheme.get, call_593875.host, call_593875.base,
                         call_593875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593875, url, valid)

proc call*(call_593876: Call_GetRemoveTags_593861; Tags: JsonNode;
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
  var query_593877 = newJObject()
  if Tags != nil:
    query_593877.add "Tags", Tags
  add(query_593877, "Action", newJString(Action))
  add(query_593877, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_593877.add "LoadBalancerNames", LoadBalancerNames
  result = call_593876.call(nil, query_593877, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_593861(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_593862,
    base: "/", url: url_GetRemoveTags_593863, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerListenerSSLCertificate_593914 = ref object of OpenApiRestCall_592364
proc url_PostSetLoadBalancerListenerSSLCertificate_593916(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetLoadBalancerListenerSSLCertificate_593915(path: JsonNode;
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
  var valid_593917 = query.getOrDefault("Action")
  valid_593917 = validateParameter(valid_593917, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_593917 != nil:
    section.add "Action", valid_593917
  var valid_593918 = query.getOrDefault("Version")
  valid_593918 = validateParameter(valid_593918, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593918 != nil:
    section.add "Version", valid_593918
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
  var valid_593919 = header.getOrDefault("X-Amz-Signature")
  valid_593919 = validateParameter(valid_593919, JString, required = false,
                                 default = nil)
  if valid_593919 != nil:
    section.add "X-Amz-Signature", valid_593919
  var valid_593920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593920 = validateParameter(valid_593920, JString, required = false,
                                 default = nil)
  if valid_593920 != nil:
    section.add "X-Amz-Content-Sha256", valid_593920
  var valid_593921 = header.getOrDefault("X-Amz-Date")
  valid_593921 = validateParameter(valid_593921, JString, required = false,
                                 default = nil)
  if valid_593921 != nil:
    section.add "X-Amz-Date", valid_593921
  var valid_593922 = header.getOrDefault("X-Amz-Credential")
  valid_593922 = validateParameter(valid_593922, JString, required = false,
                                 default = nil)
  if valid_593922 != nil:
    section.add "X-Amz-Credential", valid_593922
  var valid_593923 = header.getOrDefault("X-Amz-Security-Token")
  valid_593923 = validateParameter(valid_593923, JString, required = false,
                                 default = nil)
  if valid_593923 != nil:
    section.add "X-Amz-Security-Token", valid_593923
  var valid_593924 = header.getOrDefault("X-Amz-Algorithm")
  valid_593924 = validateParameter(valid_593924, JString, required = false,
                                 default = nil)
  if valid_593924 != nil:
    section.add "X-Amz-Algorithm", valid_593924
  var valid_593925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593925 = validateParameter(valid_593925, JString, required = false,
                                 default = nil)
  if valid_593925 != nil:
    section.add "X-Amz-SignedHeaders", valid_593925
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
  var valid_593926 = formData.getOrDefault("LoadBalancerName")
  valid_593926 = validateParameter(valid_593926, JString, required = true,
                                 default = nil)
  if valid_593926 != nil:
    section.add "LoadBalancerName", valid_593926
  var valid_593927 = formData.getOrDefault("SSLCertificateId")
  valid_593927 = validateParameter(valid_593927, JString, required = true,
                                 default = nil)
  if valid_593927 != nil:
    section.add "SSLCertificateId", valid_593927
  var valid_593928 = formData.getOrDefault("LoadBalancerPort")
  valid_593928 = validateParameter(valid_593928, JInt, required = true, default = nil)
  if valid_593928 != nil:
    section.add "LoadBalancerPort", valid_593928
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593929: Call_PostSetLoadBalancerListenerSSLCertificate_593914;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593929.validator(path, query, header, formData, body)
  let scheme = call_593929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593929.url(scheme.get, call_593929.host, call_593929.base,
                         call_593929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593929, url, valid)

proc call*(call_593930: Call_PostSetLoadBalancerListenerSSLCertificate_593914;
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
  var query_593931 = newJObject()
  var formData_593932 = newJObject()
  add(formData_593932, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593931, "Action", newJString(Action))
  add(formData_593932, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_593931, "Version", newJString(Version))
  add(formData_593932, "LoadBalancerPort", newJInt(LoadBalancerPort))
  result = call_593930.call(nil, query_593931, nil, formData_593932, nil)

var postSetLoadBalancerListenerSSLCertificate* = Call_PostSetLoadBalancerListenerSSLCertificate_593914(
    name: "postSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_PostSetLoadBalancerListenerSSLCertificate_593915,
    base: "/", url: url_PostSetLoadBalancerListenerSSLCertificate_593916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerListenerSSLCertificate_593896 = ref object of OpenApiRestCall_592364
proc url_GetSetLoadBalancerListenerSSLCertificate_593898(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetLoadBalancerListenerSSLCertificate_593897(path: JsonNode;
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
  var valid_593899 = query.getOrDefault("LoadBalancerPort")
  valid_593899 = validateParameter(valid_593899, JInt, required = true, default = nil)
  if valid_593899 != nil:
    section.add "LoadBalancerPort", valid_593899
  var valid_593900 = query.getOrDefault("LoadBalancerName")
  valid_593900 = validateParameter(valid_593900, JString, required = true,
                                 default = nil)
  if valid_593900 != nil:
    section.add "LoadBalancerName", valid_593900
  var valid_593901 = query.getOrDefault("Action")
  valid_593901 = validateParameter(valid_593901, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_593901 != nil:
    section.add "Action", valid_593901
  var valid_593902 = query.getOrDefault("Version")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593902 != nil:
    section.add "Version", valid_593902
  var valid_593903 = query.getOrDefault("SSLCertificateId")
  valid_593903 = validateParameter(valid_593903, JString, required = true,
                                 default = nil)
  if valid_593903 != nil:
    section.add "SSLCertificateId", valid_593903
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
  var valid_593904 = header.getOrDefault("X-Amz-Signature")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Signature", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Content-Sha256", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Date")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Date", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Credential")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Credential", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Security-Token")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Security-Token", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Algorithm")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Algorithm", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-SignedHeaders", valid_593910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593911: Call_GetSetLoadBalancerListenerSSLCertificate_593896;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593911.validator(path, query, header, formData, body)
  let scheme = call_593911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593911.url(scheme.get, call_593911.host, call_593911.base,
                         call_593911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593911, url, valid)

proc call*(call_593912: Call_GetSetLoadBalancerListenerSSLCertificate_593896;
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
  var query_593913 = newJObject()
  add(query_593913, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_593913, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593913, "Action", newJString(Action))
  add(query_593913, "Version", newJString(Version))
  add(query_593913, "SSLCertificateId", newJString(SSLCertificateId))
  result = call_593912.call(nil, query_593913, nil, nil, nil)

var getSetLoadBalancerListenerSSLCertificate* = Call_GetSetLoadBalancerListenerSSLCertificate_593896(
    name: "getSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_GetSetLoadBalancerListenerSSLCertificate_593897,
    base: "/", url: url_GetSetLoadBalancerListenerSSLCertificate_593898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesForBackendServer_593951 = ref object of OpenApiRestCall_592364
proc url_PostSetLoadBalancerPoliciesForBackendServer_593953(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetLoadBalancerPoliciesForBackendServer_593952(path: JsonNode;
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
  var valid_593954 = query.getOrDefault("Action")
  valid_593954 = validateParameter(valid_593954, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_593954 != nil:
    section.add "Action", valid_593954
  var valid_593955 = query.getOrDefault("Version")
  valid_593955 = validateParameter(valid_593955, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593955 != nil:
    section.add "Version", valid_593955
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
  var valid_593956 = header.getOrDefault("X-Amz-Signature")
  valid_593956 = validateParameter(valid_593956, JString, required = false,
                                 default = nil)
  if valid_593956 != nil:
    section.add "X-Amz-Signature", valid_593956
  var valid_593957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593957 = validateParameter(valid_593957, JString, required = false,
                                 default = nil)
  if valid_593957 != nil:
    section.add "X-Amz-Content-Sha256", valid_593957
  var valid_593958 = header.getOrDefault("X-Amz-Date")
  valid_593958 = validateParameter(valid_593958, JString, required = false,
                                 default = nil)
  if valid_593958 != nil:
    section.add "X-Amz-Date", valid_593958
  var valid_593959 = header.getOrDefault("X-Amz-Credential")
  valid_593959 = validateParameter(valid_593959, JString, required = false,
                                 default = nil)
  if valid_593959 != nil:
    section.add "X-Amz-Credential", valid_593959
  var valid_593960 = header.getOrDefault("X-Amz-Security-Token")
  valid_593960 = validateParameter(valid_593960, JString, required = false,
                                 default = nil)
  if valid_593960 != nil:
    section.add "X-Amz-Security-Token", valid_593960
  var valid_593961 = header.getOrDefault("X-Amz-Algorithm")
  valid_593961 = validateParameter(valid_593961, JString, required = false,
                                 default = nil)
  if valid_593961 != nil:
    section.add "X-Amz-Algorithm", valid_593961
  var valid_593962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593962 = validateParameter(valid_593962, JString, required = false,
                                 default = nil)
  if valid_593962 != nil:
    section.add "X-Amz-SignedHeaders", valid_593962
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
  var valid_593963 = formData.getOrDefault("PolicyNames")
  valid_593963 = validateParameter(valid_593963, JArray, required = true, default = nil)
  if valid_593963 != nil:
    section.add "PolicyNames", valid_593963
  var valid_593964 = formData.getOrDefault("LoadBalancerName")
  valid_593964 = validateParameter(valid_593964, JString, required = true,
                                 default = nil)
  if valid_593964 != nil:
    section.add "LoadBalancerName", valid_593964
  var valid_593965 = formData.getOrDefault("InstancePort")
  valid_593965 = validateParameter(valid_593965, JInt, required = true, default = nil)
  if valid_593965 != nil:
    section.add "InstancePort", valid_593965
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593966: Call_PostSetLoadBalancerPoliciesForBackendServer_593951;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593966.validator(path, query, header, formData, body)
  let scheme = call_593966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593966.url(scheme.get, call_593966.host, call_593966.base,
                         call_593966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593966, url, valid)

proc call*(call_593967: Call_PostSetLoadBalancerPoliciesForBackendServer_593951;
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
  var query_593968 = newJObject()
  var formData_593969 = newJObject()
  if PolicyNames != nil:
    formData_593969.add "PolicyNames", PolicyNames
  add(formData_593969, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593968, "Action", newJString(Action))
  add(formData_593969, "InstancePort", newJInt(InstancePort))
  add(query_593968, "Version", newJString(Version))
  result = call_593967.call(nil, query_593968, nil, formData_593969, nil)

var postSetLoadBalancerPoliciesForBackendServer* = Call_PostSetLoadBalancerPoliciesForBackendServer_593951(
    name: "postSetLoadBalancerPoliciesForBackendServer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_PostSetLoadBalancerPoliciesForBackendServer_593952,
    base: "/", url: url_PostSetLoadBalancerPoliciesForBackendServer_593953,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesForBackendServer_593933 = ref object of OpenApiRestCall_592364
proc url_GetSetLoadBalancerPoliciesForBackendServer_593935(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetLoadBalancerPoliciesForBackendServer_593934(path: JsonNode;
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
  var valid_593936 = query.getOrDefault("InstancePort")
  valid_593936 = validateParameter(valid_593936, JInt, required = true, default = nil)
  if valid_593936 != nil:
    section.add "InstancePort", valid_593936
  var valid_593937 = query.getOrDefault("LoadBalancerName")
  valid_593937 = validateParameter(valid_593937, JString, required = true,
                                 default = nil)
  if valid_593937 != nil:
    section.add "LoadBalancerName", valid_593937
  var valid_593938 = query.getOrDefault("Action")
  valid_593938 = validateParameter(valid_593938, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_593938 != nil:
    section.add "Action", valid_593938
  var valid_593939 = query.getOrDefault("Version")
  valid_593939 = validateParameter(valid_593939, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593939 != nil:
    section.add "Version", valid_593939
  var valid_593940 = query.getOrDefault("PolicyNames")
  valid_593940 = validateParameter(valid_593940, JArray, required = true, default = nil)
  if valid_593940 != nil:
    section.add "PolicyNames", valid_593940
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
  var valid_593941 = header.getOrDefault("X-Amz-Signature")
  valid_593941 = validateParameter(valid_593941, JString, required = false,
                                 default = nil)
  if valid_593941 != nil:
    section.add "X-Amz-Signature", valid_593941
  var valid_593942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593942 = validateParameter(valid_593942, JString, required = false,
                                 default = nil)
  if valid_593942 != nil:
    section.add "X-Amz-Content-Sha256", valid_593942
  var valid_593943 = header.getOrDefault("X-Amz-Date")
  valid_593943 = validateParameter(valid_593943, JString, required = false,
                                 default = nil)
  if valid_593943 != nil:
    section.add "X-Amz-Date", valid_593943
  var valid_593944 = header.getOrDefault("X-Amz-Credential")
  valid_593944 = validateParameter(valid_593944, JString, required = false,
                                 default = nil)
  if valid_593944 != nil:
    section.add "X-Amz-Credential", valid_593944
  var valid_593945 = header.getOrDefault("X-Amz-Security-Token")
  valid_593945 = validateParameter(valid_593945, JString, required = false,
                                 default = nil)
  if valid_593945 != nil:
    section.add "X-Amz-Security-Token", valid_593945
  var valid_593946 = header.getOrDefault("X-Amz-Algorithm")
  valid_593946 = validateParameter(valid_593946, JString, required = false,
                                 default = nil)
  if valid_593946 != nil:
    section.add "X-Amz-Algorithm", valid_593946
  var valid_593947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593947 = validateParameter(valid_593947, JString, required = false,
                                 default = nil)
  if valid_593947 != nil:
    section.add "X-Amz-SignedHeaders", valid_593947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593948: Call_GetSetLoadBalancerPoliciesForBackendServer_593933;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593948.validator(path, query, header, formData, body)
  let scheme = call_593948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593948.url(scheme.get, call_593948.host, call_593948.base,
                         call_593948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593948, url, valid)

proc call*(call_593949: Call_GetSetLoadBalancerPoliciesForBackendServer_593933;
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
  var query_593950 = newJObject()
  add(query_593950, "InstancePort", newJInt(InstancePort))
  add(query_593950, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593950, "Action", newJString(Action))
  add(query_593950, "Version", newJString(Version))
  if PolicyNames != nil:
    query_593950.add "PolicyNames", PolicyNames
  result = call_593949.call(nil, query_593950, nil, nil, nil)

var getSetLoadBalancerPoliciesForBackendServer* = Call_GetSetLoadBalancerPoliciesForBackendServer_593933(
    name: "getSetLoadBalancerPoliciesForBackendServer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_GetSetLoadBalancerPoliciesForBackendServer_593934,
    base: "/", url: url_GetSetLoadBalancerPoliciesForBackendServer_593935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesOfListener_593988 = ref object of OpenApiRestCall_592364
proc url_PostSetLoadBalancerPoliciesOfListener_593990(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetLoadBalancerPoliciesOfListener_593989(path: JsonNode;
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
  var valid_593991 = query.getOrDefault("Action")
  valid_593991 = validateParameter(valid_593991, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_593991 != nil:
    section.add "Action", valid_593991
  var valid_593992 = query.getOrDefault("Version")
  valid_593992 = validateParameter(valid_593992, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593992 != nil:
    section.add "Version", valid_593992
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
  var valid_593993 = header.getOrDefault("X-Amz-Signature")
  valid_593993 = validateParameter(valid_593993, JString, required = false,
                                 default = nil)
  if valid_593993 != nil:
    section.add "X-Amz-Signature", valid_593993
  var valid_593994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593994 = validateParameter(valid_593994, JString, required = false,
                                 default = nil)
  if valid_593994 != nil:
    section.add "X-Amz-Content-Sha256", valid_593994
  var valid_593995 = header.getOrDefault("X-Amz-Date")
  valid_593995 = validateParameter(valid_593995, JString, required = false,
                                 default = nil)
  if valid_593995 != nil:
    section.add "X-Amz-Date", valid_593995
  var valid_593996 = header.getOrDefault("X-Amz-Credential")
  valid_593996 = validateParameter(valid_593996, JString, required = false,
                                 default = nil)
  if valid_593996 != nil:
    section.add "X-Amz-Credential", valid_593996
  var valid_593997 = header.getOrDefault("X-Amz-Security-Token")
  valid_593997 = validateParameter(valid_593997, JString, required = false,
                                 default = nil)
  if valid_593997 != nil:
    section.add "X-Amz-Security-Token", valid_593997
  var valid_593998 = header.getOrDefault("X-Amz-Algorithm")
  valid_593998 = validateParameter(valid_593998, JString, required = false,
                                 default = nil)
  if valid_593998 != nil:
    section.add "X-Amz-Algorithm", valid_593998
  var valid_593999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593999 = validateParameter(valid_593999, JString, required = false,
                                 default = nil)
  if valid_593999 != nil:
    section.add "X-Amz-SignedHeaders", valid_593999
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
  var valid_594000 = formData.getOrDefault("PolicyNames")
  valid_594000 = validateParameter(valid_594000, JArray, required = true, default = nil)
  if valid_594000 != nil:
    section.add "PolicyNames", valid_594000
  var valid_594001 = formData.getOrDefault("LoadBalancerName")
  valid_594001 = validateParameter(valid_594001, JString, required = true,
                                 default = nil)
  if valid_594001 != nil:
    section.add "LoadBalancerName", valid_594001
  var valid_594002 = formData.getOrDefault("LoadBalancerPort")
  valid_594002 = validateParameter(valid_594002, JInt, required = true, default = nil)
  if valid_594002 != nil:
    section.add "LoadBalancerPort", valid_594002
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594003: Call_PostSetLoadBalancerPoliciesOfListener_593988;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594003.validator(path, query, header, formData, body)
  let scheme = call_594003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594003.url(scheme.get, call_594003.host, call_594003.base,
                         call_594003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594003, url, valid)

proc call*(call_594004: Call_PostSetLoadBalancerPoliciesOfListener_593988;
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
  var query_594005 = newJObject()
  var formData_594006 = newJObject()
  if PolicyNames != nil:
    formData_594006.add "PolicyNames", PolicyNames
  add(formData_594006, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594005, "Action", newJString(Action))
  add(query_594005, "Version", newJString(Version))
  add(formData_594006, "LoadBalancerPort", newJInt(LoadBalancerPort))
  result = call_594004.call(nil, query_594005, nil, formData_594006, nil)

var postSetLoadBalancerPoliciesOfListener* = Call_PostSetLoadBalancerPoliciesOfListener_593988(
    name: "postSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_PostSetLoadBalancerPoliciesOfListener_593989, base: "/",
    url: url_PostSetLoadBalancerPoliciesOfListener_593990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesOfListener_593970 = ref object of OpenApiRestCall_592364
proc url_GetSetLoadBalancerPoliciesOfListener_593972(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetLoadBalancerPoliciesOfListener_593971(path: JsonNode;
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
  var valid_593973 = query.getOrDefault("LoadBalancerPort")
  valid_593973 = validateParameter(valid_593973, JInt, required = true, default = nil)
  if valid_593973 != nil:
    section.add "LoadBalancerPort", valid_593973
  var valid_593974 = query.getOrDefault("LoadBalancerName")
  valid_593974 = validateParameter(valid_593974, JString, required = true,
                                 default = nil)
  if valid_593974 != nil:
    section.add "LoadBalancerName", valid_593974
  var valid_593975 = query.getOrDefault("Action")
  valid_593975 = validateParameter(valid_593975, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_593975 != nil:
    section.add "Action", valid_593975
  var valid_593976 = query.getOrDefault("Version")
  valid_593976 = validateParameter(valid_593976, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593976 != nil:
    section.add "Version", valid_593976
  var valid_593977 = query.getOrDefault("PolicyNames")
  valid_593977 = validateParameter(valid_593977, JArray, required = true, default = nil)
  if valid_593977 != nil:
    section.add "PolicyNames", valid_593977
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
  var valid_593978 = header.getOrDefault("X-Amz-Signature")
  valid_593978 = validateParameter(valid_593978, JString, required = false,
                                 default = nil)
  if valid_593978 != nil:
    section.add "X-Amz-Signature", valid_593978
  var valid_593979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593979 = validateParameter(valid_593979, JString, required = false,
                                 default = nil)
  if valid_593979 != nil:
    section.add "X-Amz-Content-Sha256", valid_593979
  var valid_593980 = header.getOrDefault("X-Amz-Date")
  valid_593980 = validateParameter(valid_593980, JString, required = false,
                                 default = nil)
  if valid_593980 != nil:
    section.add "X-Amz-Date", valid_593980
  var valid_593981 = header.getOrDefault("X-Amz-Credential")
  valid_593981 = validateParameter(valid_593981, JString, required = false,
                                 default = nil)
  if valid_593981 != nil:
    section.add "X-Amz-Credential", valid_593981
  var valid_593982 = header.getOrDefault("X-Amz-Security-Token")
  valid_593982 = validateParameter(valid_593982, JString, required = false,
                                 default = nil)
  if valid_593982 != nil:
    section.add "X-Amz-Security-Token", valid_593982
  var valid_593983 = header.getOrDefault("X-Amz-Algorithm")
  valid_593983 = validateParameter(valid_593983, JString, required = false,
                                 default = nil)
  if valid_593983 != nil:
    section.add "X-Amz-Algorithm", valid_593983
  var valid_593984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593984 = validateParameter(valid_593984, JString, required = false,
                                 default = nil)
  if valid_593984 != nil:
    section.add "X-Amz-SignedHeaders", valid_593984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593985: Call_GetSetLoadBalancerPoliciesOfListener_593970;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593985.validator(path, query, header, formData, body)
  let scheme = call_593985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593985.url(scheme.get, call_593985.host, call_593985.base,
                         call_593985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593985, url, valid)

proc call*(call_593986: Call_GetSetLoadBalancerPoliciesOfListener_593970;
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
  var query_593987 = newJObject()
  add(query_593987, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_593987, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_593987, "Action", newJString(Action))
  add(query_593987, "Version", newJString(Version))
  if PolicyNames != nil:
    query_593987.add "PolicyNames", PolicyNames
  result = call_593986.call(nil, query_593987, nil, nil, nil)

var getSetLoadBalancerPoliciesOfListener* = Call_GetSetLoadBalancerPoliciesOfListener_593970(
    name: "getSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_GetSetLoadBalancerPoliciesOfListener_593971, base: "/",
    url: url_GetSetLoadBalancerPoliciesOfListener_593972,
    schemes: {Scheme.Https, Scheme.Http})
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
