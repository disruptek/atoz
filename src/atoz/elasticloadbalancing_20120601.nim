
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_PostAddTags_601999 = ref object of OpenApiRestCall_601389
proc url_PostAddTags_602001(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTags_602000(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602002 = query.getOrDefault("Action")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_602002 != nil:
    section.add "Action", valid_602002
  var valid_602003 = query.getOrDefault("Version")
  valid_602003 = validateParameter(valid_602003, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602003 != nil:
    section.add "Version", valid_602003
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
  var valid_602004 = header.getOrDefault("X-Amz-Signature")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Signature", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Content-Sha256", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Date")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Date", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Credential")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Credential", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Security-Token")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Security-Token", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Algorithm")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Algorithm", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-SignedHeaders", valid_602010
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Tags: JArray (required)
  ##       : The tags.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_602011 = formData.getOrDefault("LoadBalancerNames")
  valid_602011 = validateParameter(valid_602011, JArray, required = true, default = nil)
  if valid_602011 != nil:
    section.add "LoadBalancerNames", valid_602011
  var valid_602012 = formData.getOrDefault("Tags")
  valid_602012 = validateParameter(valid_602012, JArray, required = true, default = nil)
  if valid_602012 != nil:
    section.add "Tags", valid_602012
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602013: Call_PostAddTags_601999; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602013.validator(path, query, header, formData, body)
  let scheme = call_602013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602013.url(scheme.get, call_602013.host, call_602013.base,
                         call_602013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602013, url, valid)

proc call*(call_602014: Call_PostAddTags_601999; LoadBalancerNames: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2012-06-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   Version: string (required)
  var query_602015 = newJObject()
  var formData_602016 = newJObject()
  if LoadBalancerNames != nil:
    formData_602016.add "LoadBalancerNames", LoadBalancerNames
  add(query_602015, "Action", newJString(Action))
  if Tags != nil:
    formData_602016.add "Tags", Tags
  add(query_602015, "Version", newJString(Version))
  result = call_602014.call(nil, query_602015, nil, formData_602016, nil)

var postAddTags* = Call_PostAddTags_601999(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_602000,
                                        base: "/", url: url_PostAddTags_602001,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_601727 = ref object of OpenApiRestCall_601389
proc url_GetAddTags_601729(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAddTags_601728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601841 = query.getOrDefault("Tags")
  valid_601841 = validateParameter(valid_601841, JArray, required = true, default = nil)
  if valid_601841 != nil:
    section.add "Tags", valid_601841
  var valid_601855 = query.getOrDefault("Action")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_601855 != nil:
    section.add "Action", valid_601855
  var valid_601856 = query.getOrDefault("Version")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601856 != nil:
    section.add "Version", valid_601856
  var valid_601857 = query.getOrDefault("LoadBalancerNames")
  valid_601857 = validateParameter(valid_601857, JArray, required = true, default = nil)
  if valid_601857 != nil:
    section.add "LoadBalancerNames", valid_601857
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
  var valid_601858 = header.getOrDefault("X-Amz-Signature")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Signature", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Content-Sha256", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Date")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Date", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Credential")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Credential", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Security-Token")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Security-Token", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Algorithm")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Algorithm", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-SignedHeaders", valid_601864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601887: Call_GetAddTags_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601887.validator(path, query, header, formData, body)
  let scheme = call_601887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601887.url(scheme.get, call_601887.host, call_601887.base,
                         call_601887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601887, url, valid)

proc call*(call_601958: Call_GetAddTags_601727; Tags: JsonNode;
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
  var query_601959 = newJObject()
  if Tags != nil:
    query_601959.add "Tags", Tags
  add(query_601959, "Action", newJString(Action))
  add(query_601959, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_601959.add "LoadBalancerNames", LoadBalancerNames
  result = call_601958.call(nil, query_601959, nil, nil, nil)

var getAddTags* = Call_GetAddTags_601727(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_601728,
                                      base: "/", url: url_GetAddTags_601729,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplySecurityGroupsToLoadBalancer_602034 = ref object of OpenApiRestCall_601389
proc url_PostApplySecurityGroupsToLoadBalancer_602036(protocol: Scheme;
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

proc validate_PostApplySecurityGroupsToLoadBalancer_602035(path: JsonNode;
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
  var valid_602037 = query.getOrDefault("Action")
  valid_602037 = validateParameter(valid_602037, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_602037 != nil:
    section.add "Action", valid_602037
  var valid_602038 = query.getOrDefault("Version")
  valid_602038 = validateParameter(valid_602038, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602038 != nil:
    section.add "Version", valid_602038
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
  var valid_602039 = header.getOrDefault("X-Amz-Signature")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Signature", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Content-Sha256", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Date")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Date", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Credential")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Credential", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Security-Token")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Security-Token", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Algorithm")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Algorithm", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-SignedHeaders", valid_602045
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_602046 = formData.getOrDefault("SecurityGroups")
  valid_602046 = validateParameter(valid_602046, JArray, required = true, default = nil)
  if valid_602046 != nil:
    section.add "SecurityGroups", valid_602046
  var valid_602047 = formData.getOrDefault("LoadBalancerName")
  valid_602047 = validateParameter(valid_602047, JString, required = true,
                                 default = nil)
  if valid_602047 != nil:
    section.add "LoadBalancerName", valid_602047
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602048: Call_PostApplySecurityGroupsToLoadBalancer_602034;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602048.validator(path, query, header, formData, body)
  let scheme = call_602048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602048.url(scheme.get, call_602048.host, call_602048.base,
                         call_602048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602048, url, valid)

proc call*(call_602049: Call_PostApplySecurityGroupsToLoadBalancer_602034;
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
  var query_602050 = newJObject()
  var formData_602051 = newJObject()
  if SecurityGroups != nil:
    formData_602051.add "SecurityGroups", SecurityGroups
  add(formData_602051, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602050, "Action", newJString(Action))
  add(query_602050, "Version", newJString(Version))
  result = call_602049.call(nil, query_602050, nil, formData_602051, nil)

var postApplySecurityGroupsToLoadBalancer* = Call_PostApplySecurityGroupsToLoadBalancer_602034(
    name: "postApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_PostApplySecurityGroupsToLoadBalancer_602035, base: "/",
    url: url_PostApplySecurityGroupsToLoadBalancer_602036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplySecurityGroupsToLoadBalancer_602017 = ref object of OpenApiRestCall_601389
proc url_GetApplySecurityGroupsToLoadBalancer_602019(protocol: Scheme;
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

proc validate_GetApplySecurityGroupsToLoadBalancer_602018(path: JsonNode;
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
  var valid_602020 = query.getOrDefault("SecurityGroups")
  valid_602020 = validateParameter(valid_602020, JArray, required = true, default = nil)
  if valid_602020 != nil:
    section.add "SecurityGroups", valid_602020
  var valid_602021 = query.getOrDefault("LoadBalancerName")
  valid_602021 = validateParameter(valid_602021, JString, required = true,
                                 default = nil)
  if valid_602021 != nil:
    section.add "LoadBalancerName", valid_602021
  var valid_602022 = query.getOrDefault("Action")
  valid_602022 = validateParameter(valid_602022, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_602022 != nil:
    section.add "Action", valid_602022
  var valid_602023 = query.getOrDefault("Version")
  valid_602023 = validateParameter(valid_602023, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602023 != nil:
    section.add "Version", valid_602023
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
  var valid_602024 = header.getOrDefault("X-Amz-Signature")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Signature", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Content-Sha256", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Date")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Date", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Credential")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Credential", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Security-Token")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Security-Token", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Algorithm")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Algorithm", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-SignedHeaders", valid_602030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602031: Call_GetApplySecurityGroupsToLoadBalancer_602017;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602031.validator(path, query, header, formData, body)
  let scheme = call_602031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602031.url(scheme.get, call_602031.host, call_602031.base,
                         call_602031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602031, url, valid)

proc call*(call_602032: Call_GetApplySecurityGroupsToLoadBalancer_602017;
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
  var query_602033 = newJObject()
  if SecurityGroups != nil:
    query_602033.add "SecurityGroups", SecurityGroups
  add(query_602033, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602033, "Action", newJString(Action))
  add(query_602033, "Version", newJString(Version))
  result = call_602032.call(nil, query_602033, nil, nil, nil)

var getApplySecurityGroupsToLoadBalancer* = Call_GetApplySecurityGroupsToLoadBalancer_602017(
    name: "getApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_GetApplySecurityGroupsToLoadBalancer_602018, base: "/",
    url: url_GetApplySecurityGroupsToLoadBalancer_602019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAttachLoadBalancerToSubnets_602069 = ref object of OpenApiRestCall_601389
proc url_PostAttachLoadBalancerToSubnets_602071(protocol: Scheme; host: string;
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

proc validate_PostAttachLoadBalancerToSubnets_602070(path: JsonNode;
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
  var valid_602072 = query.getOrDefault("Action")
  valid_602072 = validateParameter(valid_602072, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_602072 != nil:
    section.add "Action", valid_602072
  var valid_602073 = query.getOrDefault("Version")
  valid_602073 = validateParameter(valid_602073, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602073 != nil:
    section.add "Version", valid_602073
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
  var valid_602074 = header.getOrDefault("X-Amz-Signature")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Signature", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Content-Sha256", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Date")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Date", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Credential")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Credential", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Security-Token")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Security-Token", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Algorithm")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Algorithm", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-SignedHeaders", valid_602080
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_602081 = formData.getOrDefault("Subnets")
  valid_602081 = validateParameter(valid_602081, JArray, required = true, default = nil)
  if valid_602081 != nil:
    section.add "Subnets", valid_602081
  var valid_602082 = formData.getOrDefault("LoadBalancerName")
  valid_602082 = validateParameter(valid_602082, JString, required = true,
                                 default = nil)
  if valid_602082 != nil:
    section.add "LoadBalancerName", valid_602082
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_PostAttachLoadBalancerToSubnets_602069;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_PostAttachLoadBalancerToSubnets_602069;
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
  var query_602085 = newJObject()
  var formData_602086 = newJObject()
  if Subnets != nil:
    formData_602086.add "Subnets", Subnets
  add(formData_602086, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602085, "Action", newJString(Action))
  add(query_602085, "Version", newJString(Version))
  result = call_602084.call(nil, query_602085, nil, formData_602086, nil)

var postAttachLoadBalancerToSubnets* = Call_PostAttachLoadBalancerToSubnets_602069(
    name: "postAttachLoadBalancerToSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_PostAttachLoadBalancerToSubnets_602070, base: "/",
    url: url_PostAttachLoadBalancerToSubnets_602071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttachLoadBalancerToSubnets_602052 = ref object of OpenApiRestCall_601389
proc url_GetAttachLoadBalancerToSubnets_602054(protocol: Scheme; host: string;
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

proc validate_GetAttachLoadBalancerToSubnets_602053(path: JsonNode;
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
  var valid_602055 = query.getOrDefault("LoadBalancerName")
  valid_602055 = validateParameter(valid_602055, JString, required = true,
                                 default = nil)
  if valid_602055 != nil:
    section.add "LoadBalancerName", valid_602055
  var valid_602056 = query.getOrDefault("Action")
  valid_602056 = validateParameter(valid_602056, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_602056 != nil:
    section.add "Action", valid_602056
  var valid_602057 = query.getOrDefault("Subnets")
  valid_602057 = validateParameter(valid_602057, JArray, required = true, default = nil)
  if valid_602057 != nil:
    section.add "Subnets", valid_602057
  var valid_602058 = query.getOrDefault("Version")
  valid_602058 = validateParameter(valid_602058, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602058 != nil:
    section.add "Version", valid_602058
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
  var valid_602059 = header.getOrDefault("X-Amz-Signature")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Signature", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Content-Sha256", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Date")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Date", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Credential")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Credential", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Security-Token")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Security-Token", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Algorithm")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Algorithm", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-SignedHeaders", valid_602065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602066: Call_GetAttachLoadBalancerToSubnets_602052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602066.validator(path, query, header, formData, body)
  let scheme = call_602066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602066.url(scheme.get, call_602066.host, call_602066.base,
                         call_602066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602066, url, valid)

proc call*(call_602067: Call_GetAttachLoadBalancerToSubnets_602052;
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
  var query_602068 = newJObject()
  add(query_602068, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602068, "Action", newJString(Action))
  if Subnets != nil:
    query_602068.add "Subnets", Subnets
  add(query_602068, "Version", newJString(Version))
  result = call_602067.call(nil, query_602068, nil, nil, nil)

var getAttachLoadBalancerToSubnets* = Call_GetAttachLoadBalancerToSubnets_602052(
    name: "getAttachLoadBalancerToSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_GetAttachLoadBalancerToSubnets_602053, base: "/",
    url: url_GetAttachLoadBalancerToSubnets_602054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfigureHealthCheck_602108 = ref object of OpenApiRestCall_601389
proc url_PostConfigureHealthCheck_602110(protocol: Scheme; host: string;
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

proc validate_PostConfigureHealthCheck_602109(path: JsonNode; query: JsonNode;
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
  var valid_602111 = query.getOrDefault("Action")
  valid_602111 = validateParameter(valid_602111, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_602111 != nil:
    section.add "Action", valid_602111
  var valid_602112 = query.getOrDefault("Version")
  valid_602112 = validateParameter(valid_602112, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602112 != nil:
    section.add "Version", valid_602112
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
  var valid_602113 = header.getOrDefault("X-Amz-Signature")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Signature", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Content-Sha256", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Date")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Date", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Credential")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Credential", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Security-Token")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Security-Token", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Algorithm")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Algorithm", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-SignedHeaders", valid_602119
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
  var valid_602120 = formData.getOrDefault("HealthCheck.Interval")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "HealthCheck.Interval", valid_602120
  var valid_602121 = formData.getOrDefault("HealthCheck.HealthyThreshold")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_602121
  var valid_602122 = formData.getOrDefault("HealthCheck.Timeout")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "HealthCheck.Timeout", valid_602122
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_602123 = formData.getOrDefault("LoadBalancerName")
  valid_602123 = validateParameter(valid_602123, JString, required = true,
                                 default = nil)
  if valid_602123 != nil:
    section.add "LoadBalancerName", valid_602123
  var valid_602124 = formData.getOrDefault("HealthCheck.Target")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "HealthCheck.Target", valid_602124
  var valid_602125 = formData.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_602125
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602126: Call_PostConfigureHealthCheck_602108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602126.validator(path, query, header, formData, body)
  let scheme = call_602126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602126.url(scheme.get, call_602126.host, call_602126.base,
                         call_602126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602126, url, valid)

proc call*(call_602127: Call_PostConfigureHealthCheck_602108;
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
  var query_602128 = newJObject()
  var formData_602129 = newJObject()
  add(formData_602129, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(formData_602129, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(formData_602129, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(formData_602129, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602128, "Action", newJString(Action))
  add(formData_602129, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_602128, "Version", newJString(Version))
  add(formData_602129, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  result = call_602127.call(nil, query_602128, nil, formData_602129, nil)

var postConfigureHealthCheck* = Call_PostConfigureHealthCheck_602108(
    name: "postConfigureHealthCheck", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_PostConfigureHealthCheck_602109, base: "/",
    url: url_PostConfigureHealthCheck_602110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigureHealthCheck_602087 = ref object of OpenApiRestCall_601389
proc url_GetConfigureHealthCheck_602089(protocol: Scheme; host: string; base: string;
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

proc validate_GetConfigureHealthCheck_602088(path: JsonNode; query: JsonNode;
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
  var valid_602090 = query.getOrDefault("HealthCheck.Interval")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "HealthCheck.Interval", valid_602090
  var valid_602091 = query.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_602091
  var valid_602092 = query.getOrDefault("HealthCheck.Timeout")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "HealthCheck.Timeout", valid_602092
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_602093 = query.getOrDefault("LoadBalancerName")
  valid_602093 = validateParameter(valid_602093, JString, required = true,
                                 default = nil)
  if valid_602093 != nil:
    section.add "LoadBalancerName", valid_602093
  var valid_602094 = query.getOrDefault("Action")
  valid_602094 = validateParameter(valid_602094, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_602094 != nil:
    section.add "Action", valid_602094
  var valid_602095 = query.getOrDefault("HealthCheck.Target")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "HealthCheck.Target", valid_602095
  var valid_602096 = query.getOrDefault("HealthCheck.HealthyThreshold")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_602096
  var valid_602097 = query.getOrDefault("Version")
  valid_602097 = validateParameter(valid_602097, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602097 != nil:
    section.add "Version", valid_602097
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
  var valid_602098 = header.getOrDefault("X-Amz-Signature")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Signature", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Content-Sha256", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Date")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Date", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Credential")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Credential", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Security-Token")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Security-Token", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Algorithm")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Algorithm", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-SignedHeaders", valid_602104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602105: Call_GetConfigureHealthCheck_602087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602105.validator(path, query, header, formData, body)
  let scheme = call_602105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602105.url(scheme.get, call_602105.host, call_602105.base,
                         call_602105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602105, url, valid)

proc call*(call_602106: Call_GetConfigureHealthCheck_602087;
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
  var query_602107 = newJObject()
  add(query_602107, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(query_602107, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(query_602107, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_602107, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602107, "Action", newJString(Action))
  add(query_602107, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_602107, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(query_602107, "Version", newJString(Version))
  result = call_602106.call(nil, query_602107, nil, nil, nil)

var getConfigureHealthCheck* = Call_GetConfigureHealthCheck_602087(
    name: "getConfigureHealthCheck", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_GetConfigureHealthCheck_602088, base: "/",
    url: url_GetConfigureHealthCheck_602089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateAppCookieStickinessPolicy_602148 = ref object of OpenApiRestCall_601389
proc url_PostCreateAppCookieStickinessPolicy_602150(protocol: Scheme; host: string;
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

proc validate_PostCreateAppCookieStickinessPolicy_602149(path: JsonNode;
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
  var valid_602151 = query.getOrDefault("Action")
  valid_602151 = validateParameter(valid_602151, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_602151 != nil:
    section.add "Action", valid_602151
  var valid_602152 = query.getOrDefault("Version")
  valid_602152 = validateParameter(valid_602152, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602152 != nil:
    section.add "Version", valid_602152
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
  var valid_602153 = header.getOrDefault("X-Amz-Signature")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Signature", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Content-Sha256", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Date")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Date", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Credential")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Credential", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Security-Token")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Security-Token", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Algorithm")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Algorithm", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-SignedHeaders", valid_602159
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
  var valid_602160 = formData.getOrDefault("CookieName")
  valid_602160 = validateParameter(valid_602160, JString, required = true,
                                 default = nil)
  if valid_602160 != nil:
    section.add "CookieName", valid_602160
  var valid_602161 = formData.getOrDefault("LoadBalancerName")
  valid_602161 = validateParameter(valid_602161, JString, required = true,
                                 default = nil)
  if valid_602161 != nil:
    section.add "LoadBalancerName", valid_602161
  var valid_602162 = formData.getOrDefault("PolicyName")
  valid_602162 = validateParameter(valid_602162, JString, required = true,
                                 default = nil)
  if valid_602162 != nil:
    section.add "PolicyName", valid_602162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602163: Call_PostCreateAppCookieStickinessPolicy_602148;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602163.validator(path, query, header, formData, body)
  let scheme = call_602163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602163.url(scheme.get, call_602163.host, call_602163.base,
                         call_602163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602163, url, valid)

proc call*(call_602164: Call_PostCreateAppCookieStickinessPolicy_602148;
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
  var query_602165 = newJObject()
  var formData_602166 = newJObject()
  add(formData_602166, "CookieName", newJString(CookieName))
  add(formData_602166, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602165, "Action", newJString(Action))
  add(query_602165, "Version", newJString(Version))
  add(formData_602166, "PolicyName", newJString(PolicyName))
  result = call_602164.call(nil, query_602165, nil, formData_602166, nil)

var postCreateAppCookieStickinessPolicy* = Call_PostCreateAppCookieStickinessPolicy_602148(
    name: "postCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_PostCreateAppCookieStickinessPolicy_602149, base: "/",
    url: url_PostCreateAppCookieStickinessPolicy_602150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateAppCookieStickinessPolicy_602130 = ref object of OpenApiRestCall_601389
proc url_GetCreateAppCookieStickinessPolicy_602132(protocol: Scheme; host: string;
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

proc validate_GetCreateAppCookieStickinessPolicy_602131(path: JsonNode;
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
  var valid_602133 = query.getOrDefault("PolicyName")
  valid_602133 = validateParameter(valid_602133, JString, required = true,
                                 default = nil)
  if valid_602133 != nil:
    section.add "PolicyName", valid_602133
  var valid_602134 = query.getOrDefault("CookieName")
  valid_602134 = validateParameter(valid_602134, JString, required = true,
                                 default = nil)
  if valid_602134 != nil:
    section.add "CookieName", valid_602134
  var valid_602135 = query.getOrDefault("LoadBalancerName")
  valid_602135 = validateParameter(valid_602135, JString, required = true,
                                 default = nil)
  if valid_602135 != nil:
    section.add "LoadBalancerName", valid_602135
  var valid_602136 = query.getOrDefault("Action")
  valid_602136 = validateParameter(valid_602136, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_602136 != nil:
    section.add "Action", valid_602136
  var valid_602137 = query.getOrDefault("Version")
  valid_602137 = validateParameter(valid_602137, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602137 != nil:
    section.add "Version", valid_602137
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
  var valid_602138 = header.getOrDefault("X-Amz-Signature")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Signature", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Content-Sha256", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Date")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Date", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Credential")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Credential", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Security-Token")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Security-Token", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Algorithm")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Algorithm", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-SignedHeaders", valid_602144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602145: Call_GetCreateAppCookieStickinessPolicy_602130;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602145.validator(path, query, header, formData, body)
  let scheme = call_602145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602145.url(scheme.get, call_602145.host, call_602145.base,
                         call_602145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602145, url, valid)

proc call*(call_602146: Call_GetCreateAppCookieStickinessPolicy_602130;
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
  var query_602147 = newJObject()
  add(query_602147, "PolicyName", newJString(PolicyName))
  add(query_602147, "CookieName", newJString(CookieName))
  add(query_602147, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602147, "Action", newJString(Action))
  add(query_602147, "Version", newJString(Version))
  result = call_602146.call(nil, query_602147, nil, nil, nil)

var getCreateAppCookieStickinessPolicy* = Call_GetCreateAppCookieStickinessPolicy_602130(
    name: "getCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_GetCreateAppCookieStickinessPolicy_602131, base: "/",
    url: url_GetCreateAppCookieStickinessPolicy_602132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLBCookieStickinessPolicy_602185 = ref object of OpenApiRestCall_601389
proc url_PostCreateLBCookieStickinessPolicy_602187(protocol: Scheme; host: string;
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

proc validate_PostCreateLBCookieStickinessPolicy_602186(path: JsonNode;
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
  var valid_602188 = query.getOrDefault("Action")
  valid_602188 = validateParameter(valid_602188, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_602188 != nil:
    section.add "Action", valid_602188
  var valid_602189 = query.getOrDefault("Version")
  valid_602189 = validateParameter(valid_602189, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602189 != nil:
    section.add "Version", valid_602189
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
  var valid_602190 = header.getOrDefault("X-Amz-Signature")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Signature", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Content-Sha256", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Date")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Date", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Credential")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Credential", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Security-Token")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Security-Token", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Algorithm")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Algorithm", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-SignedHeaders", valid_602196
  result.add "header", section
  ## parameters in `formData` object:
  ##   CookieExpirationPeriod: JInt
  ##                         : The time period, in seconds, after which the cookie should be considered stale. If you do not specify this parameter, the default value is 0, which indicates that the sticky session should last for the duration of the browser session.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  section = newJObject()
  var valid_602197 = formData.getOrDefault("CookieExpirationPeriod")
  valid_602197 = validateParameter(valid_602197, JInt, required = false, default = nil)
  if valid_602197 != nil:
    section.add "CookieExpirationPeriod", valid_602197
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_602198 = formData.getOrDefault("LoadBalancerName")
  valid_602198 = validateParameter(valid_602198, JString, required = true,
                                 default = nil)
  if valid_602198 != nil:
    section.add "LoadBalancerName", valid_602198
  var valid_602199 = formData.getOrDefault("PolicyName")
  valid_602199 = validateParameter(valid_602199, JString, required = true,
                                 default = nil)
  if valid_602199 != nil:
    section.add "PolicyName", valid_602199
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602200: Call_PostCreateLBCookieStickinessPolicy_602185;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602200.validator(path, query, header, formData, body)
  let scheme = call_602200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602200.url(scheme.get, call_602200.host, call_602200.base,
                         call_602200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602200, url, valid)

proc call*(call_602201: Call_PostCreateLBCookieStickinessPolicy_602185;
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
  var query_602202 = newJObject()
  var formData_602203 = newJObject()
  add(formData_602203, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(formData_602203, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602202, "Action", newJString(Action))
  add(query_602202, "Version", newJString(Version))
  add(formData_602203, "PolicyName", newJString(PolicyName))
  result = call_602201.call(nil, query_602202, nil, formData_602203, nil)

var postCreateLBCookieStickinessPolicy* = Call_PostCreateLBCookieStickinessPolicy_602185(
    name: "postCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_PostCreateLBCookieStickinessPolicy_602186, base: "/",
    url: url_PostCreateLBCookieStickinessPolicy_602187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLBCookieStickinessPolicy_602167 = ref object of OpenApiRestCall_601389
proc url_GetCreateLBCookieStickinessPolicy_602169(protocol: Scheme; host: string;
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

proc validate_GetCreateLBCookieStickinessPolicy_602168(path: JsonNode;
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
  var valid_602170 = query.getOrDefault("CookieExpirationPeriod")
  valid_602170 = validateParameter(valid_602170, JInt, required = false, default = nil)
  if valid_602170 != nil:
    section.add "CookieExpirationPeriod", valid_602170
  assert query != nil,
        "query argument is necessary due to required `PolicyName` field"
  var valid_602171 = query.getOrDefault("PolicyName")
  valid_602171 = validateParameter(valid_602171, JString, required = true,
                                 default = nil)
  if valid_602171 != nil:
    section.add "PolicyName", valid_602171
  var valid_602172 = query.getOrDefault("LoadBalancerName")
  valid_602172 = validateParameter(valid_602172, JString, required = true,
                                 default = nil)
  if valid_602172 != nil:
    section.add "LoadBalancerName", valid_602172
  var valid_602173 = query.getOrDefault("Action")
  valid_602173 = validateParameter(valid_602173, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_602173 != nil:
    section.add "Action", valid_602173
  var valid_602174 = query.getOrDefault("Version")
  valid_602174 = validateParameter(valid_602174, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602174 != nil:
    section.add "Version", valid_602174
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
  var valid_602175 = header.getOrDefault("X-Amz-Signature")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Signature", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Content-Sha256", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Date")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Date", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Credential")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Credential", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Security-Token")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Security-Token", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Algorithm")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Algorithm", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-SignedHeaders", valid_602181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602182: Call_GetCreateLBCookieStickinessPolicy_602167;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602182.validator(path, query, header, formData, body)
  let scheme = call_602182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602182.url(scheme.get, call_602182.host, call_602182.base,
                         call_602182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602182, url, valid)

proc call*(call_602183: Call_GetCreateLBCookieStickinessPolicy_602167;
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
  var query_602184 = newJObject()
  add(query_602184, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(query_602184, "PolicyName", newJString(PolicyName))
  add(query_602184, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602184, "Action", newJString(Action))
  add(query_602184, "Version", newJString(Version))
  result = call_602183.call(nil, query_602184, nil, nil, nil)

var getCreateLBCookieStickinessPolicy* = Call_GetCreateLBCookieStickinessPolicy_602167(
    name: "getCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_GetCreateLBCookieStickinessPolicy_602168, base: "/",
    url: url_GetCreateLBCookieStickinessPolicy_602169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_602226 = ref object of OpenApiRestCall_601389
proc url_PostCreateLoadBalancer_602228(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateLoadBalancer_602227(path: JsonNode; query: JsonNode;
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
  var valid_602229 = query.getOrDefault("Action")
  valid_602229 = validateParameter(valid_602229, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_602229 != nil:
    section.add "Action", valid_602229
  var valid_602230 = query.getOrDefault("Version")
  valid_602230 = validateParameter(valid_602230, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602230 != nil:
    section.add "Version", valid_602230
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
  var valid_602231 = header.getOrDefault("X-Amz-Signature")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Signature", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Content-Sha256", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Date")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Date", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Credential")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Credential", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Security-Token")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Security-Token", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Algorithm")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Algorithm", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-SignedHeaders", valid_602237
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
  var valid_602238 = formData.getOrDefault("Scheme")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "Scheme", valid_602238
  var valid_602239 = formData.getOrDefault("SecurityGroups")
  valid_602239 = validateParameter(valid_602239, JArray, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "SecurityGroups", valid_602239
  var valid_602240 = formData.getOrDefault("AvailabilityZones")
  valid_602240 = validateParameter(valid_602240, JArray, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "AvailabilityZones", valid_602240
  var valid_602241 = formData.getOrDefault("Subnets")
  valid_602241 = validateParameter(valid_602241, JArray, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "Subnets", valid_602241
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_602242 = formData.getOrDefault("LoadBalancerName")
  valid_602242 = validateParameter(valid_602242, JString, required = true,
                                 default = nil)
  if valid_602242 != nil:
    section.add "LoadBalancerName", valid_602242
  var valid_602243 = formData.getOrDefault("Listeners")
  valid_602243 = validateParameter(valid_602243, JArray, required = true, default = nil)
  if valid_602243 != nil:
    section.add "Listeners", valid_602243
  var valid_602244 = formData.getOrDefault("Tags")
  valid_602244 = validateParameter(valid_602244, JArray, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "Tags", valid_602244
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602245: Call_PostCreateLoadBalancer_602226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602245.validator(path, query, header, formData, body)
  let scheme = call_602245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602245.url(scheme.get, call_602245.host, call_602245.base,
                         call_602245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602245, url, valid)

proc call*(call_602246: Call_PostCreateLoadBalancer_602226;
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
  var query_602247 = newJObject()
  var formData_602248 = newJObject()
  add(formData_602248, "Scheme", newJString(Scheme))
  if SecurityGroups != nil:
    formData_602248.add "SecurityGroups", SecurityGroups
  if AvailabilityZones != nil:
    formData_602248.add "AvailabilityZones", AvailabilityZones
  if Subnets != nil:
    formData_602248.add "Subnets", Subnets
  add(formData_602248, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_602248.add "Listeners", Listeners
  add(query_602247, "Action", newJString(Action))
  if Tags != nil:
    formData_602248.add "Tags", Tags
  add(query_602247, "Version", newJString(Version))
  result = call_602246.call(nil, query_602247, nil, formData_602248, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_602226(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_602227, base: "/",
    url: url_PostCreateLoadBalancer_602228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_602204 = ref object of OpenApiRestCall_601389
proc url_GetCreateLoadBalancer_602206(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateLoadBalancer_602205(path: JsonNode; query: JsonNode;
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
  var valid_602207 = query.getOrDefault("Tags")
  valid_602207 = validateParameter(valid_602207, JArray, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "Tags", valid_602207
  var valid_602208 = query.getOrDefault("Scheme")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "Scheme", valid_602208
  var valid_602209 = query.getOrDefault("AvailabilityZones")
  valid_602209 = validateParameter(valid_602209, JArray, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "AvailabilityZones", valid_602209
  assert query != nil,
        "query argument is necessary due to required `Listeners` field"
  var valid_602210 = query.getOrDefault("Listeners")
  valid_602210 = validateParameter(valid_602210, JArray, required = true, default = nil)
  if valid_602210 != nil:
    section.add "Listeners", valid_602210
  var valid_602211 = query.getOrDefault("SecurityGroups")
  valid_602211 = validateParameter(valid_602211, JArray, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "SecurityGroups", valid_602211
  var valid_602212 = query.getOrDefault("LoadBalancerName")
  valid_602212 = validateParameter(valid_602212, JString, required = true,
                                 default = nil)
  if valid_602212 != nil:
    section.add "LoadBalancerName", valid_602212
  var valid_602213 = query.getOrDefault("Action")
  valid_602213 = validateParameter(valid_602213, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_602213 != nil:
    section.add "Action", valid_602213
  var valid_602214 = query.getOrDefault("Subnets")
  valid_602214 = validateParameter(valid_602214, JArray, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "Subnets", valid_602214
  var valid_602215 = query.getOrDefault("Version")
  valid_602215 = validateParameter(valid_602215, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602215 != nil:
    section.add "Version", valid_602215
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
  var valid_602216 = header.getOrDefault("X-Amz-Signature")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Signature", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Content-Sha256", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-Date")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Date", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Credential")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Credential", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Security-Token")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Security-Token", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Algorithm")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Algorithm", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-SignedHeaders", valid_602222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602223: Call_GetCreateLoadBalancer_602204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602223.validator(path, query, header, formData, body)
  let scheme = call_602223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602223.url(scheme.get, call_602223.host, call_602223.base,
                         call_602223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602223, url, valid)

proc call*(call_602224: Call_GetCreateLoadBalancer_602204; Listeners: JsonNode;
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
  var query_602225 = newJObject()
  if Tags != nil:
    query_602225.add "Tags", Tags
  add(query_602225, "Scheme", newJString(Scheme))
  if AvailabilityZones != nil:
    query_602225.add "AvailabilityZones", AvailabilityZones
  if Listeners != nil:
    query_602225.add "Listeners", Listeners
  if SecurityGroups != nil:
    query_602225.add "SecurityGroups", SecurityGroups
  add(query_602225, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602225, "Action", newJString(Action))
  if Subnets != nil:
    query_602225.add "Subnets", Subnets
  add(query_602225, "Version", newJString(Version))
  result = call_602224.call(nil, query_602225, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_602204(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_602205, base: "/",
    url: url_GetCreateLoadBalancer_602206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerListeners_602266 = ref object of OpenApiRestCall_601389
proc url_PostCreateLoadBalancerListeners_602268(protocol: Scheme; host: string;
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

proc validate_PostCreateLoadBalancerListeners_602267(path: JsonNode;
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
  var valid_602269 = query.getOrDefault("Action")
  valid_602269 = validateParameter(valid_602269, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_602269 != nil:
    section.add "Action", valid_602269
  var valid_602270 = query.getOrDefault("Version")
  valid_602270 = validateParameter(valid_602270, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602270 != nil:
    section.add "Version", valid_602270
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
  var valid_602271 = header.getOrDefault("X-Amz-Signature")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Signature", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Content-Sha256", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Date")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Date", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Credential")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Credential", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Security-Token")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Security-Token", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Algorithm")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Algorithm", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-SignedHeaders", valid_602277
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_602278 = formData.getOrDefault("LoadBalancerName")
  valid_602278 = validateParameter(valid_602278, JString, required = true,
                                 default = nil)
  if valid_602278 != nil:
    section.add "LoadBalancerName", valid_602278
  var valid_602279 = formData.getOrDefault("Listeners")
  valid_602279 = validateParameter(valid_602279, JArray, required = true, default = nil)
  if valid_602279 != nil:
    section.add "Listeners", valid_602279
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602280: Call_PostCreateLoadBalancerListeners_602266;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602280.validator(path, query, header, formData, body)
  let scheme = call_602280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602280.url(scheme.get, call_602280.host, call_602280.base,
                         call_602280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602280, url, valid)

proc call*(call_602281: Call_PostCreateLoadBalancerListeners_602266;
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
  var query_602282 = newJObject()
  var formData_602283 = newJObject()
  add(formData_602283, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_602283.add "Listeners", Listeners
  add(query_602282, "Action", newJString(Action))
  add(query_602282, "Version", newJString(Version))
  result = call_602281.call(nil, query_602282, nil, formData_602283, nil)

var postCreateLoadBalancerListeners* = Call_PostCreateLoadBalancerListeners_602266(
    name: "postCreateLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_PostCreateLoadBalancerListeners_602267, base: "/",
    url: url_PostCreateLoadBalancerListeners_602268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerListeners_602249 = ref object of OpenApiRestCall_601389
proc url_GetCreateLoadBalancerListeners_602251(protocol: Scheme; host: string;
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

proc validate_GetCreateLoadBalancerListeners_602250(path: JsonNode;
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
  var valid_602252 = query.getOrDefault("Listeners")
  valid_602252 = validateParameter(valid_602252, JArray, required = true, default = nil)
  if valid_602252 != nil:
    section.add "Listeners", valid_602252
  var valid_602253 = query.getOrDefault("LoadBalancerName")
  valid_602253 = validateParameter(valid_602253, JString, required = true,
                                 default = nil)
  if valid_602253 != nil:
    section.add "LoadBalancerName", valid_602253
  var valid_602254 = query.getOrDefault("Action")
  valid_602254 = validateParameter(valid_602254, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_602254 != nil:
    section.add "Action", valid_602254
  var valid_602255 = query.getOrDefault("Version")
  valid_602255 = validateParameter(valid_602255, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602255 != nil:
    section.add "Version", valid_602255
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
  var valid_602256 = header.getOrDefault("X-Amz-Signature")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Signature", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Content-Sha256", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Date")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Date", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Credential")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Credential", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Security-Token")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Security-Token", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Algorithm")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Algorithm", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-SignedHeaders", valid_602262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602263: Call_GetCreateLoadBalancerListeners_602249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602263.validator(path, query, header, formData, body)
  let scheme = call_602263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602263.url(scheme.get, call_602263.host, call_602263.base,
                         call_602263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602263, url, valid)

proc call*(call_602264: Call_GetCreateLoadBalancerListeners_602249;
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
  var query_602265 = newJObject()
  if Listeners != nil:
    query_602265.add "Listeners", Listeners
  add(query_602265, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602265, "Action", newJString(Action))
  add(query_602265, "Version", newJString(Version))
  result = call_602264.call(nil, query_602265, nil, nil, nil)

var getCreateLoadBalancerListeners* = Call_GetCreateLoadBalancerListeners_602249(
    name: "getCreateLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_GetCreateLoadBalancerListeners_602250, base: "/",
    url: url_GetCreateLoadBalancerListeners_602251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerPolicy_602303 = ref object of OpenApiRestCall_601389
proc url_PostCreateLoadBalancerPolicy_602305(protocol: Scheme; host: string;
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

proc validate_PostCreateLoadBalancerPolicy_602304(path: JsonNode; query: JsonNode;
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
  var valid_602306 = query.getOrDefault("Action")
  valid_602306 = validateParameter(valid_602306, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_602306 != nil:
    section.add "Action", valid_602306
  var valid_602307 = query.getOrDefault("Version")
  valid_602307 = validateParameter(valid_602307, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602307 != nil:
    section.add "Version", valid_602307
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
  var valid_602308 = header.getOrDefault("X-Amz-Signature")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Signature", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Content-Sha256", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Date")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Date", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Credential")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Credential", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Security-Token")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Security-Token", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Algorithm")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Algorithm", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-SignedHeaders", valid_602314
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
  var valid_602315 = formData.getOrDefault("PolicyAttributes")
  valid_602315 = validateParameter(valid_602315, JArray, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "PolicyAttributes", valid_602315
  assert formData != nil,
        "formData argument is necessary due to required `PolicyTypeName` field"
  var valid_602316 = formData.getOrDefault("PolicyTypeName")
  valid_602316 = validateParameter(valid_602316, JString, required = true,
                                 default = nil)
  if valid_602316 != nil:
    section.add "PolicyTypeName", valid_602316
  var valid_602317 = formData.getOrDefault("LoadBalancerName")
  valid_602317 = validateParameter(valid_602317, JString, required = true,
                                 default = nil)
  if valid_602317 != nil:
    section.add "LoadBalancerName", valid_602317
  var valid_602318 = formData.getOrDefault("PolicyName")
  valid_602318 = validateParameter(valid_602318, JString, required = true,
                                 default = nil)
  if valid_602318 != nil:
    section.add "PolicyName", valid_602318
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602319: Call_PostCreateLoadBalancerPolicy_602303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_602319.validator(path, query, header, formData, body)
  let scheme = call_602319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602319.url(scheme.get, call_602319.host, call_602319.base,
                         call_602319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602319, url, valid)

proc call*(call_602320: Call_PostCreateLoadBalancerPolicy_602303;
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
  var query_602321 = newJObject()
  var formData_602322 = newJObject()
  if PolicyAttributes != nil:
    formData_602322.add "PolicyAttributes", PolicyAttributes
  add(formData_602322, "PolicyTypeName", newJString(PolicyTypeName))
  add(formData_602322, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602321, "Action", newJString(Action))
  add(query_602321, "Version", newJString(Version))
  add(formData_602322, "PolicyName", newJString(PolicyName))
  result = call_602320.call(nil, query_602321, nil, formData_602322, nil)

var postCreateLoadBalancerPolicy* = Call_PostCreateLoadBalancerPolicy_602303(
    name: "postCreateLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_PostCreateLoadBalancerPolicy_602304, base: "/",
    url: url_PostCreateLoadBalancerPolicy_602305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerPolicy_602284 = ref object of OpenApiRestCall_601389
proc url_GetCreateLoadBalancerPolicy_602286(protocol: Scheme; host: string;
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

proc validate_GetCreateLoadBalancerPolicy_602285(path: JsonNode; query: JsonNode;
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
  var valid_602287 = query.getOrDefault("PolicyAttributes")
  valid_602287 = validateParameter(valid_602287, JArray, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "PolicyAttributes", valid_602287
  assert query != nil,
        "query argument is necessary due to required `PolicyName` field"
  var valid_602288 = query.getOrDefault("PolicyName")
  valid_602288 = validateParameter(valid_602288, JString, required = true,
                                 default = nil)
  if valid_602288 != nil:
    section.add "PolicyName", valid_602288
  var valid_602289 = query.getOrDefault("PolicyTypeName")
  valid_602289 = validateParameter(valid_602289, JString, required = true,
                                 default = nil)
  if valid_602289 != nil:
    section.add "PolicyTypeName", valid_602289
  var valid_602290 = query.getOrDefault("LoadBalancerName")
  valid_602290 = validateParameter(valid_602290, JString, required = true,
                                 default = nil)
  if valid_602290 != nil:
    section.add "LoadBalancerName", valid_602290
  var valid_602291 = query.getOrDefault("Action")
  valid_602291 = validateParameter(valid_602291, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_602291 != nil:
    section.add "Action", valid_602291
  var valid_602292 = query.getOrDefault("Version")
  valid_602292 = validateParameter(valid_602292, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602292 != nil:
    section.add "Version", valid_602292
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
  var valid_602293 = header.getOrDefault("X-Amz-Signature")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Signature", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Content-Sha256", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Date")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Date", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Credential")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Credential", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Security-Token")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Security-Token", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Algorithm")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Algorithm", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-SignedHeaders", valid_602299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602300: Call_GetCreateLoadBalancerPolicy_602284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_602300.validator(path, query, header, formData, body)
  let scheme = call_602300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602300.url(scheme.get, call_602300.host, call_602300.base,
                         call_602300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602300, url, valid)

proc call*(call_602301: Call_GetCreateLoadBalancerPolicy_602284;
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
  var query_602302 = newJObject()
  if PolicyAttributes != nil:
    query_602302.add "PolicyAttributes", PolicyAttributes
  add(query_602302, "PolicyName", newJString(PolicyName))
  add(query_602302, "PolicyTypeName", newJString(PolicyTypeName))
  add(query_602302, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602302, "Action", newJString(Action))
  add(query_602302, "Version", newJString(Version))
  result = call_602301.call(nil, query_602302, nil, nil, nil)

var getCreateLoadBalancerPolicy* = Call_GetCreateLoadBalancerPolicy_602284(
    name: "getCreateLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_GetCreateLoadBalancerPolicy_602285, base: "/",
    url: url_GetCreateLoadBalancerPolicy_602286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_602339 = ref object of OpenApiRestCall_601389
proc url_PostDeleteLoadBalancer_602341(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteLoadBalancer_602340(path: JsonNode; query: JsonNode;
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
  var valid_602342 = query.getOrDefault("Action")
  valid_602342 = validateParameter(valid_602342, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_602342 != nil:
    section.add "Action", valid_602342
  var valid_602343 = query.getOrDefault("Version")
  valid_602343 = validateParameter(valid_602343, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602343 != nil:
    section.add "Version", valid_602343
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
  var valid_602344 = header.getOrDefault("X-Amz-Signature")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Signature", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Content-Sha256", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Date")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Date", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Credential")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Credential", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Security-Token")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Security-Token", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Algorithm")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Algorithm", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-SignedHeaders", valid_602350
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_602351 = formData.getOrDefault("LoadBalancerName")
  valid_602351 = validateParameter(valid_602351, JString, required = true,
                                 default = nil)
  if valid_602351 != nil:
    section.add "LoadBalancerName", valid_602351
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602352: Call_PostDeleteLoadBalancer_602339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_602352.validator(path, query, header, formData, body)
  let scheme = call_602352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602352.url(scheme.get, call_602352.host, call_602352.base,
                         call_602352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602352, url, valid)

proc call*(call_602353: Call_PostDeleteLoadBalancer_602339;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602354 = newJObject()
  var formData_602355 = newJObject()
  add(formData_602355, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602354, "Action", newJString(Action))
  add(query_602354, "Version", newJString(Version))
  result = call_602353.call(nil, query_602354, nil, formData_602355, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_602339(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_602340, base: "/",
    url: url_PostDeleteLoadBalancer_602341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_602323 = ref object of OpenApiRestCall_601389
proc url_GetDeleteLoadBalancer_602325(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteLoadBalancer_602324(path: JsonNode; query: JsonNode;
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
  var valid_602326 = query.getOrDefault("LoadBalancerName")
  valid_602326 = validateParameter(valid_602326, JString, required = true,
                                 default = nil)
  if valid_602326 != nil:
    section.add "LoadBalancerName", valid_602326
  var valid_602327 = query.getOrDefault("Action")
  valid_602327 = validateParameter(valid_602327, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_602327 != nil:
    section.add "Action", valid_602327
  var valid_602328 = query.getOrDefault("Version")
  valid_602328 = validateParameter(valid_602328, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602328 != nil:
    section.add "Version", valid_602328
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
  var valid_602329 = header.getOrDefault("X-Amz-Signature")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Signature", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Content-Sha256", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Date")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Date", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Credential")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Credential", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Security-Token")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Security-Token", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Algorithm")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Algorithm", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-SignedHeaders", valid_602335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602336: Call_GetDeleteLoadBalancer_602323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_602336.validator(path, query, header, formData, body)
  let scheme = call_602336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602336.url(scheme.get, call_602336.host, call_602336.base,
                         call_602336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602336, url, valid)

proc call*(call_602337: Call_GetDeleteLoadBalancer_602323;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602338 = newJObject()
  add(query_602338, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602338, "Action", newJString(Action))
  add(query_602338, "Version", newJString(Version))
  result = call_602337.call(nil, query_602338, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_602323(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_602324, base: "/",
    url: url_GetDeleteLoadBalancer_602325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerListeners_602373 = ref object of OpenApiRestCall_601389
proc url_PostDeleteLoadBalancerListeners_602375(protocol: Scheme; host: string;
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

proc validate_PostDeleteLoadBalancerListeners_602374(path: JsonNode;
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
  var valid_602376 = query.getOrDefault("Action")
  valid_602376 = validateParameter(valid_602376, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_602376 != nil:
    section.add "Action", valid_602376
  var valid_602377 = query.getOrDefault("Version")
  valid_602377 = validateParameter(valid_602377, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602377 != nil:
    section.add "Version", valid_602377
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
  var valid_602378 = header.getOrDefault("X-Amz-Signature")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Signature", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Content-Sha256", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Date")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Date", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Credential")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Credential", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Security-Token")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Security-Token", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Algorithm")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Algorithm", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-SignedHeaders", valid_602384
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerPorts` field"
  var valid_602385 = formData.getOrDefault("LoadBalancerPorts")
  valid_602385 = validateParameter(valid_602385, JArray, required = true, default = nil)
  if valid_602385 != nil:
    section.add "LoadBalancerPorts", valid_602385
  var valid_602386 = formData.getOrDefault("LoadBalancerName")
  valid_602386 = validateParameter(valid_602386, JString, required = true,
                                 default = nil)
  if valid_602386 != nil:
    section.add "LoadBalancerName", valid_602386
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602387: Call_PostDeleteLoadBalancerListeners_602373;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_602387.validator(path, query, header, formData, body)
  let scheme = call_602387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602387.url(scheme.get, call_602387.host, call_602387.base,
                         call_602387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602387, url, valid)

proc call*(call_602388: Call_PostDeleteLoadBalancerListeners_602373;
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
  var query_602389 = newJObject()
  var formData_602390 = newJObject()
  if LoadBalancerPorts != nil:
    formData_602390.add "LoadBalancerPorts", LoadBalancerPorts
  add(formData_602390, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602389, "Action", newJString(Action))
  add(query_602389, "Version", newJString(Version))
  result = call_602388.call(nil, query_602389, nil, formData_602390, nil)

var postDeleteLoadBalancerListeners* = Call_PostDeleteLoadBalancerListeners_602373(
    name: "postDeleteLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_PostDeleteLoadBalancerListeners_602374, base: "/",
    url: url_PostDeleteLoadBalancerListeners_602375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerListeners_602356 = ref object of OpenApiRestCall_601389
proc url_GetDeleteLoadBalancerListeners_602358(protocol: Scheme; host: string;
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

proc validate_GetDeleteLoadBalancerListeners_602357(path: JsonNode;
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
  var valid_602359 = query.getOrDefault("LoadBalancerPorts")
  valid_602359 = validateParameter(valid_602359, JArray, required = true, default = nil)
  if valid_602359 != nil:
    section.add "LoadBalancerPorts", valid_602359
  var valid_602360 = query.getOrDefault("LoadBalancerName")
  valid_602360 = validateParameter(valid_602360, JString, required = true,
                                 default = nil)
  if valid_602360 != nil:
    section.add "LoadBalancerName", valid_602360
  var valid_602361 = query.getOrDefault("Action")
  valid_602361 = validateParameter(valid_602361, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_602361 != nil:
    section.add "Action", valid_602361
  var valid_602362 = query.getOrDefault("Version")
  valid_602362 = validateParameter(valid_602362, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602362 != nil:
    section.add "Version", valid_602362
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
  var valid_602363 = header.getOrDefault("X-Amz-Signature")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Signature", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Content-Sha256", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Date")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Date", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Credential")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Credential", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Security-Token")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Security-Token", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Algorithm")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Algorithm", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-SignedHeaders", valid_602369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602370: Call_GetDeleteLoadBalancerListeners_602356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_602370.validator(path, query, header, formData, body)
  let scheme = call_602370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602370.url(scheme.get, call_602370.host, call_602370.base,
                         call_602370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602370, url, valid)

proc call*(call_602371: Call_GetDeleteLoadBalancerListeners_602356;
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
  var query_602372 = newJObject()
  if LoadBalancerPorts != nil:
    query_602372.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_602372, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602372, "Action", newJString(Action))
  add(query_602372, "Version", newJString(Version))
  result = call_602371.call(nil, query_602372, nil, nil, nil)

var getDeleteLoadBalancerListeners* = Call_GetDeleteLoadBalancerListeners_602356(
    name: "getDeleteLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_GetDeleteLoadBalancerListeners_602357, base: "/",
    url: url_GetDeleteLoadBalancerListeners_602358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerPolicy_602408 = ref object of OpenApiRestCall_601389
proc url_PostDeleteLoadBalancerPolicy_602410(protocol: Scheme; host: string;
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

proc validate_PostDeleteLoadBalancerPolicy_602409(path: JsonNode; query: JsonNode;
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
  var valid_602411 = query.getOrDefault("Action")
  valid_602411 = validateParameter(valid_602411, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_602411 != nil:
    section.add "Action", valid_602411
  var valid_602412 = query.getOrDefault("Version")
  valid_602412 = validateParameter(valid_602412, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602412 != nil:
    section.add "Version", valid_602412
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
  var valid_602413 = header.getOrDefault("X-Amz-Signature")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Signature", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Content-Sha256", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Date")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Date", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Credential")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Credential", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Security-Token")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Security-Token", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Algorithm")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Algorithm", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-SignedHeaders", valid_602419
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_602420 = formData.getOrDefault("LoadBalancerName")
  valid_602420 = validateParameter(valid_602420, JString, required = true,
                                 default = nil)
  if valid_602420 != nil:
    section.add "LoadBalancerName", valid_602420
  var valid_602421 = formData.getOrDefault("PolicyName")
  valid_602421 = validateParameter(valid_602421, JString, required = true,
                                 default = nil)
  if valid_602421 != nil:
    section.add "PolicyName", valid_602421
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602422: Call_PostDeleteLoadBalancerPolicy_602408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_602422.validator(path, query, header, formData, body)
  let scheme = call_602422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602422.url(scheme.get, call_602422.host, call_602422.base,
                         call_602422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602422, url, valid)

proc call*(call_602423: Call_PostDeleteLoadBalancerPolicy_602408;
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
  var query_602424 = newJObject()
  var formData_602425 = newJObject()
  add(formData_602425, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602424, "Action", newJString(Action))
  add(query_602424, "Version", newJString(Version))
  add(formData_602425, "PolicyName", newJString(PolicyName))
  result = call_602423.call(nil, query_602424, nil, formData_602425, nil)

var postDeleteLoadBalancerPolicy* = Call_PostDeleteLoadBalancerPolicy_602408(
    name: "postDeleteLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_PostDeleteLoadBalancerPolicy_602409, base: "/",
    url: url_PostDeleteLoadBalancerPolicy_602410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerPolicy_602391 = ref object of OpenApiRestCall_601389
proc url_GetDeleteLoadBalancerPolicy_602393(protocol: Scheme; host: string;
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

proc validate_GetDeleteLoadBalancerPolicy_602392(path: JsonNode; query: JsonNode;
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
  var valid_602394 = query.getOrDefault("PolicyName")
  valid_602394 = validateParameter(valid_602394, JString, required = true,
                                 default = nil)
  if valid_602394 != nil:
    section.add "PolicyName", valid_602394
  var valid_602395 = query.getOrDefault("LoadBalancerName")
  valid_602395 = validateParameter(valid_602395, JString, required = true,
                                 default = nil)
  if valid_602395 != nil:
    section.add "LoadBalancerName", valid_602395
  var valid_602396 = query.getOrDefault("Action")
  valid_602396 = validateParameter(valid_602396, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_602396 != nil:
    section.add "Action", valid_602396
  var valid_602397 = query.getOrDefault("Version")
  valid_602397 = validateParameter(valid_602397, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602397 != nil:
    section.add "Version", valid_602397
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
  var valid_602398 = header.getOrDefault("X-Amz-Signature")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Signature", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Content-Sha256", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Date")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Date", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Credential")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Credential", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Security-Token")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Security-Token", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Algorithm")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Algorithm", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-SignedHeaders", valid_602404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602405: Call_GetDeleteLoadBalancerPolicy_602391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_602405.validator(path, query, header, formData, body)
  let scheme = call_602405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602405.url(scheme.get, call_602405.host, call_602405.base,
                         call_602405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602405, url, valid)

proc call*(call_602406: Call_GetDeleteLoadBalancerPolicy_602391;
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
  var query_602407 = newJObject()
  add(query_602407, "PolicyName", newJString(PolicyName))
  add(query_602407, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602407, "Action", newJString(Action))
  add(query_602407, "Version", newJString(Version))
  result = call_602406.call(nil, query_602407, nil, nil, nil)

var getDeleteLoadBalancerPolicy* = Call_GetDeleteLoadBalancerPolicy_602391(
    name: "getDeleteLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_GetDeleteLoadBalancerPolicy_602392, base: "/",
    url: url_GetDeleteLoadBalancerPolicy_602393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterInstancesFromLoadBalancer_602443 = ref object of OpenApiRestCall_601389
proc url_PostDeregisterInstancesFromLoadBalancer_602445(protocol: Scheme;
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

proc validate_PostDeregisterInstancesFromLoadBalancer_602444(path: JsonNode;
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
  var valid_602446 = query.getOrDefault("Action")
  valid_602446 = validateParameter(valid_602446, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_602446 != nil:
    section.add "Action", valid_602446
  var valid_602447 = query.getOrDefault("Version")
  valid_602447 = validateParameter(valid_602447, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602447 != nil:
    section.add "Version", valid_602447
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
  var valid_602448 = header.getOrDefault("X-Amz-Signature")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Signature", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Content-Sha256", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Date")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Date", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Credential")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Credential", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Security-Token")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Security-Token", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Algorithm")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Algorithm", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-SignedHeaders", valid_602454
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_602455 = formData.getOrDefault("Instances")
  valid_602455 = validateParameter(valid_602455, JArray, required = true, default = nil)
  if valid_602455 != nil:
    section.add "Instances", valid_602455
  var valid_602456 = formData.getOrDefault("LoadBalancerName")
  valid_602456 = validateParameter(valid_602456, JString, required = true,
                                 default = nil)
  if valid_602456 != nil:
    section.add "LoadBalancerName", valid_602456
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602457: Call_PostDeregisterInstancesFromLoadBalancer_602443;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602457.validator(path, query, header, formData, body)
  let scheme = call_602457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602457.url(scheme.get, call_602457.host, call_602457.base,
                         call_602457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602457, url, valid)

proc call*(call_602458: Call_PostDeregisterInstancesFromLoadBalancer_602443;
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
  var query_602459 = newJObject()
  var formData_602460 = newJObject()
  if Instances != nil:
    formData_602460.add "Instances", Instances
  add(formData_602460, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602459, "Action", newJString(Action))
  add(query_602459, "Version", newJString(Version))
  result = call_602458.call(nil, query_602459, nil, formData_602460, nil)

var postDeregisterInstancesFromLoadBalancer* = Call_PostDeregisterInstancesFromLoadBalancer_602443(
    name: "postDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_PostDeregisterInstancesFromLoadBalancer_602444, base: "/",
    url: url_PostDeregisterInstancesFromLoadBalancer_602445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterInstancesFromLoadBalancer_602426 = ref object of OpenApiRestCall_601389
proc url_GetDeregisterInstancesFromLoadBalancer_602428(protocol: Scheme;
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

proc validate_GetDeregisterInstancesFromLoadBalancer_602427(path: JsonNode;
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
  var valid_602429 = query.getOrDefault("LoadBalancerName")
  valid_602429 = validateParameter(valid_602429, JString, required = true,
                                 default = nil)
  if valid_602429 != nil:
    section.add "LoadBalancerName", valid_602429
  var valid_602430 = query.getOrDefault("Action")
  valid_602430 = validateParameter(valid_602430, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_602430 != nil:
    section.add "Action", valid_602430
  var valid_602431 = query.getOrDefault("Instances")
  valid_602431 = validateParameter(valid_602431, JArray, required = true, default = nil)
  if valid_602431 != nil:
    section.add "Instances", valid_602431
  var valid_602432 = query.getOrDefault("Version")
  valid_602432 = validateParameter(valid_602432, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602432 != nil:
    section.add "Version", valid_602432
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
  var valid_602433 = header.getOrDefault("X-Amz-Signature")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Signature", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Content-Sha256", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Date")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Date", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Credential")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Credential", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Security-Token")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Security-Token", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Algorithm")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Algorithm", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-SignedHeaders", valid_602439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602440: Call_GetDeregisterInstancesFromLoadBalancer_602426;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602440.validator(path, query, header, formData, body)
  let scheme = call_602440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602440.url(scheme.get, call_602440.host, call_602440.base,
                         call_602440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602440, url, valid)

proc call*(call_602441: Call_GetDeregisterInstancesFromLoadBalancer_602426;
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
  var query_602442 = newJObject()
  add(query_602442, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602442, "Action", newJString(Action))
  if Instances != nil:
    query_602442.add "Instances", Instances
  add(query_602442, "Version", newJString(Version))
  result = call_602441.call(nil, query_602442, nil, nil, nil)

var getDeregisterInstancesFromLoadBalancer* = Call_GetDeregisterInstancesFromLoadBalancer_602426(
    name: "getDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_GetDeregisterInstancesFromLoadBalancer_602427, base: "/",
    url: url_GetDeregisterInstancesFromLoadBalancer_602428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_602478 = ref object of OpenApiRestCall_601389
proc url_PostDescribeAccountLimits_602480(protocol: Scheme; host: string;
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

proc validate_PostDescribeAccountLimits_602479(path: JsonNode; query: JsonNode;
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
  var valid_602481 = query.getOrDefault("Action")
  valid_602481 = validateParameter(valid_602481, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_602481 != nil:
    section.add "Action", valid_602481
  var valid_602482 = query.getOrDefault("Version")
  valid_602482 = validateParameter(valid_602482, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602482 != nil:
    section.add "Version", valid_602482
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
  var valid_602483 = header.getOrDefault("X-Amz-Signature")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Signature", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Content-Sha256", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-Date")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-Date", valid_602485
  var valid_602486 = header.getOrDefault("X-Amz-Credential")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Credential", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Security-Token")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Security-Token", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-Algorithm")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Algorithm", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-SignedHeaders", valid_602489
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_602490 = formData.getOrDefault("Marker")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "Marker", valid_602490
  var valid_602491 = formData.getOrDefault("PageSize")
  valid_602491 = validateParameter(valid_602491, JInt, required = false, default = nil)
  if valid_602491 != nil:
    section.add "PageSize", valid_602491
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602492: Call_PostDescribeAccountLimits_602478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602492.validator(path, query, header, formData, body)
  let scheme = call_602492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602492.url(scheme.get, call_602492.host, call_602492.base,
                         call_602492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602492, url, valid)

proc call*(call_602493: Call_PostDescribeAccountLimits_602478; Marker: string = "";
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
  var query_602494 = newJObject()
  var formData_602495 = newJObject()
  add(formData_602495, "Marker", newJString(Marker))
  add(query_602494, "Action", newJString(Action))
  add(formData_602495, "PageSize", newJInt(PageSize))
  add(query_602494, "Version", newJString(Version))
  result = call_602493.call(nil, query_602494, nil, formData_602495, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_602478(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_602479, base: "/",
    url: url_PostDescribeAccountLimits_602480,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_602461 = ref object of OpenApiRestCall_601389
proc url_GetDescribeAccountLimits_602463(protocol: Scheme; host: string;
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

proc validate_GetDescribeAccountLimits_602462(path: JsonNode; query: JsonNode;
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
  var valid_602464 = query.getOrDefault("Marker")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "Marker", valid_602464
  var valid_602465 = query.getOrDefault("PageSize")
  valid_602465 = validateParameter(valid_602465, JInt, required = false, default = nil)
  if valid_602465 != nil:
    section.add "PageSize", valid_602465
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602466 = query.getOrDefault("Action")
  valid_602466 = validateParameter(valid_602466, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_602466 != nil:
    section.add "Action", valid_602466
  var valid_602467 = query.getOrDefault("Version")
  valid_602467 = validateParameter(valid_602467, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602467 != nil:
    section.add "Version", valid_602467
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
  var valid_602468 = header.getOrDefault("X-Amz-Signature")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Signature", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Content-Sha256", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Date")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Date", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-Credential")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Credential", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Security-Token")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Security-Token", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Algorithm")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Algorithm", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-SignedHeaders", valid_602474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602475: Call_GetDescribeAccountLimits_602461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602475.validator(path, query, header, formData, body)
  let scheme = call_602475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602475.url(scheme.get, call_602475.host, call_602475.base,
                         call_602475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602475, url, valid)

proc call*(call_602476: Call_GetDescribeAccountLimits_602461; Marker: string = "";
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
  var query_602477 = newJObject()
  add(query_602477, "Marker", newJString(Marker))
  add(query_602477, "PageSize", newJInt(PageSize))
  add(query_602477, "Action", newJString(Action))
  add(query_602477, "Version", newJString(Version))
  result = call_602476.call(nil, query_602477, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_602461(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_602462, base: "/",
    url: url_GetDescribeAccountLimits_602463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstanceHealth_602513 = ref object of OpenApiRestCall_601389
proc url_PostDescribeInstanceHealth_602515(protocol: Scheme; host: string;
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

proc validate_PostDescribeInstanceHealth_602514(path: JsonNode; query: JsonNode;
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
  var valid_602516 = query.getOrDefault("Action")
  valid_602516 = validateParameter(valid_602516, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_602516 != nil:
    section.add "Action", valid_602516
  var valid_602517 = query.getOrDefault("Version")
  valid_602517 = validateParameter(valid_602517, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602517 != nil:
    section.add "Version", valid_602517
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
  var valid_602518 = header.getOrDefault("X-Amz-Signature")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Signature", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-Content-Sha256", valid_602519
  var valid_602520 = header.getOrDefault("X-Amz-Date")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Date", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Credential")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Credential", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Security-Token")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Security-Token", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Algorithm")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Algorithm", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-SignedHeaders", valid_602524
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_602525 = formData.getOrDefault("Instances")
  valid_602525 = validateParameter(valid_602525, JArray, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "Instances", valid_602525
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_602526 = formData.getOrDefault("LoadBalancerName")
  valid_602526 = validateParameter(valid_602526, JString, required = true,
                                 default = nil)
  if valid_602526 != nil:
    section.add "LoadBalancerName", valid_602526
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602527: Call_PostDescribeInstanceHealth_602513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_602527.validator(path, query, header, formData, body)
  let scheme = call_602527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602527.url(scheme.get, call_602527.host, call_602527.base,
                         call_602527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602527, url, valid)

proc call*(call_602528: Call_PostDescribeInstanceHealth_602513;
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
  var query_602529 = newJObject()
  var formData_602530 = newJObject()
  if Instances != nil:
    formData_602530.add "Instances", Instances
  add(formData_602530, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602529, "Action", newJString(Action))
  add(query_602529, "Version", newJString(Version))
  result = call_602528.call(nil, query_602529, nil, formData_602530, nil)

var postDescribeInstanceHealth* = Call_PostDescribeInstanceHealth_602513(
    name: "postDescribeInstanceHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_PostDescribeInstanceHealth_602514, base: "/",
    url: url_PostDescribeInstanceHealth_602515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstanceHealth_602496 = ref object of OpenApiRestCall_601389
proc url_GetDescribeInstanceHealth_602498(protocol: Scheme; host: string;
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

proc validate_GetDescribeInstanceHealth_602497(path: JsonNode; query: JsonNode;
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
  var valid_602499 = query.getOrDefault("LoadBalancerName")
  valid_602499 = validateParameter(valid_602499, JString, required = true,
                                 default = nil)
  if valid_602499 != nil:
    section.add "LoadBalancerName", valid_602499
  var valid_602500 = query.getOrDefault("Action")
  valid_602500 = validateParameter(valid_602500, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_602500 != nil:
    section.add "Action", valid_602500
  var valid_602501 = query.getOrDefault("Instances")
  valid_602501 = validateParameter(valid_602501, JArray, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "Instances", valid_602501
  var valid_602502 = query.getOrDefault("Version")
  valid_602502 = validateParameter(valid_602502, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602502 != nil:
    section.add "Version", valid_602502
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
  var valid_602503 = header.getOrDefault("X-Amz-Signature")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Signature", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Content-Sha256", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Date")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Date", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-Credential")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Credential", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Security-Token")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Security-Token", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Algorithm")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Algorithm", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-SignedHeaders", valid_602509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602510: Call_GetDescribeInstanceHealth_602496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_602510.validator(path, query, header, formData, body)
  let scheme = call_602510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602510.url(scheme.get, call_602510.host, call_602510.base,
                         call_602510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602510, url, valid)

proc call*(call_602511: Call_GetDescribeInstanceHealth_602496;
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
  var query_602512 = newJObject()
  add(query_602512, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602512, "Action", newJString(Action))
  if Instances != nil:
    query_602512.add "Instances", Instances
  add(query_602512, "Version", newJString(Version))
  result = call_602511.call(nil, query_602512, nil, nil, nil)

var getDescribeInstanceHealth* = Call_GetDescribeInstanceHealth_602496(
    name: "getDescribeInstanceHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_GetDescribeInstanceHealth_602497, base: "/",
    url: url_GetDescribeInstanceHealth_602498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_602547 = ref object of OpenApiRestCall_601389
proc url_PostDescribeLoadBalancerAttributes_602549(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerAttributes_602548(path: JsonNode;
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
  var valid_602550 = query.getOrDefault("Action")
  valid_602550 = validateParameter(valid_602550, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_602550 != nil:
    section.add "Action", valid_602550
  var valid_602551 = query.getOrDefault("Version")
  valid_602551 = validateParameter(valid_602551, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602551 != nil:
    section.add "Version", valid_602551
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
  var valid_602552 = header.getOrDefault("X-Amz-Signature")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-Signature", valid_602552
  var valid_602553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-Content-Sha256", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-Date")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Date", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Credential")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Credential", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Security-Token")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Security-Token", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Algorithm")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Algorithm", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-SignedHeaders", valid_602558
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_602559 = formData.getOrDefault("LoadBalancerName")
  valid_602559 = validateParameter(valid_602559, JString, required = true,
                                 default = nil)
  if valid_602559 != nil:
    section.add "LoadBalancerName", valid_602559
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602560: Call_PostDescribeLoadBalancerAttributes_602547;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_602560.validator(path, query, header, formData, body)
  let scheme = call_602560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602560.url(scheme.get, call_602560.host, call_602560.base,
                         call_602560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602560, url, valid)

proc call*(call_602561: Call_PostDescribeLoadBalancerAttributes_602547;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602562 = newJObject()
  var formData_602563 = newJObject()
  add(formData_602563, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602562, "Action", newJString(Action))
  add(query_602562, "Version", newJString(Version))
  result = call_602561.call(nil, query_602562, nil, formData_602563, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_602547(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_602548, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_602549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_602531 = ref object of OpenApiRestCall_601389
proc url_GetDescribeLoadBalancerAttributes_602533(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerAttributes_602532(path: JsonNode;
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
  var valid_602534 = query.getOrDefault("LoadBalancerName")
  valid_602534 = validateParameter(valid_602534, JString, required = true,
                                 default = nil)
  if valid_602534 != nil:
    section.add "LoadBalancerName", valid_602534
  var valid_602535 = query.getOrDefault("Action")
  valid_602535 = validateParameter(valid_602535, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_602535 != nil:
    section.add "Action", valid_602535
  var valid_602536 = query.getOrDefault("Version")
  valid_602536 = validateParameter(valid_602536, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602536 != nil:
    section.add "Version", valid_602536
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
  var valid_602537 = header.getOrDefault("X-Amz-Signature")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Signature", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-Content-Sha256", valid_602538
  var valid_602539 = header.getOrDefault("X-Amz-Date")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Date", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Credential")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Credential", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Security-Token")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Security-Token", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Algorithm")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Algorithm", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-SignedHeaders", valid_602543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602544: Call_GetDescribeLoadBalancerAttributes_602531;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_602544.validator(path, query, header, formData, body)
  let scheme = call_602544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602544.url(scheme.get, call_602544.host, call_602544.base,
                         call_602544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602544, url, valid)

proc call*(call_602545: Call_GetDescribeLoadBalancerAttributes_602531;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602546 = newJObject()
  add(query_602546, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602546, "Action", newJString(Action))
  add(query_602546, "Version", newJString(Version))
  result = call_602545.call(nil, query_602546, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_602531(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_602532, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_602533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicies_602581 = ref object of OpenApiRestCall_601389
proc url_PostDescribeLoadBalancerPolicies_602583(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerPolicies_602582(path: JsonNode;
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
  var valid_602584 = query.getOrDefault("Action")
  valid_602584 = validateParameter(valid_602584, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_602584 != nil:
    section.add "Action", valid_602584
  var valid_602585 = query.getOrDefault("Version")
  valid_602585 = validateParameter(valid_602585, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602585 != nil:
    section.add "Version", valid_602585
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
  var valid_602586 = header.getOrDefault("X-Amz-Signature")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Signature", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Content-Sha256", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Date")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Date", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-Credential")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Credential", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Security-Token")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Security-Token", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-Algorithm")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Algorithm", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-SignedHeaders", valid_602592
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   LoadBalancerName: JString
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_602593 = formData.getOrDefault("PolicyNames")
  valid_602593 = validateParameter(valid_602593, JArray, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "PolicyNames", valid_602593
  var valid_602594 = formData.getOrDefault("LoadBalancerName")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "LoadBalancerName", valid_602594
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602595: Call_PostDescribeLoadBalancerPolicies_602581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_602595.validator(path, query, header, formData, body)
  let scheme = call_602595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602595.url(scheme.get, call_602595.host, call_602595.base,
                         call_602595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602595, url, valid)

proc call*(call_602596: Call_PostDescribeLoadBalancerPolicies_602581;
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
  var query_602597 = newJObject()
  var formData_602598 = newJObject()
  if PolicyNames != nil:
    formData_602598.add "PolicyNames", PolicyNames
  add(formData_602598, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602597, "Action", newJString(Action))
  add(query_602597, "Version", newJString(Version))
  result = call_602596.call(nil, query_602597, nil, formData_602598, nil)

var postDescribeLoadBalancerPolicies* = Call_PostDescribeLoadBalancerPolicies_602581(
    name: "postDescribeLoadBalancerPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_PostDescribeLoadBalancerPolicies_602582, base: "/",
    url: url_PostDescribeLoadBalancerPolicies_602583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicies_602564 = ref object of OpenApiRestCall_601389
proc url_GetDescribeLoadBalancerPolicies_602566(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerPolicies_602565(path: JsonNode;
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
  var valid_602567 = query.getOrDefault("LoadBalancerName")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "LoadBalancerName", valid_602567
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602568 = query.getOrDefault("Action")
  valid_602568 = validateParameter(valid_602568, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_602568 != nil:
    section.add "Action", valid_602568
  var valid_602569 = query.getOrDefault("Version")
  valid_602569 = validateParameter(valid_602569, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602569 != nil:
    section.add "Version", valid_602569
  var valid_602570 = query.getOrDefault("PolicyNames")
  valid_602570 = validateParameter(valid_602570, JArray, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "PolicyNames", valid_602570
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
  var valid_602571 = header.getOrDefault("X-Amz-Signature")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "X-Amz-Signature", valid_602571
  var valid_602572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "X-Amz-Content-Sha256", valid_602572
  var valid_602573 = header.getOrDefault("X-Amz-Date")
  valid_602573 = validateParameter(valid_602573, JString, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "X-Amz-Date", valid_602573
  var valid_602574 = header.getOrDefault("X-Amz-Credential")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-Credential", valid_602574
  var valid_602575 = header.getOrDefault("X-Amz-Security-Token")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Security-Token", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-Algorithm")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-Algorithm", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-SignedHeaders", valid_602577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602578: Call_GetDescribeLoadBalancerPolicies_602564;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_602578.validator(path, query, header, formData, body)
  let scheme = call_602578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602578.url(scheme.get, call_602578.host, call_602578.base,
                         call_602578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602578, url, valid)

proc call*(call_602579: Call_GetDescribeLoadBalancerPolicies_602564;
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
  var query_602580 = newJObject()
  add(query_602580, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602580, "Action", newJString(Action))
  add(query_602580, "Version", newJString(Version))
  if PolicyNames != nil:
    query_602580.add "PolicyNames", PolicyNames
  result = call_602579.call(nil, query_602580, nil, nil, nil)

var getDescribeLoadBalancerPolicies* = Call_GetDescribeLoadBalancerPolicies_602564(
    name: "getDescribeLoadBalancerPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_GetDescribeLoadBalancerPolicies_602565, base: "/",
    url: url_GetDescribeLoadBalancerPolicies_602566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicyTypes_602615 = ref object of OpenApiRestCall_601389
proc url_PostDescribeLoadBalancerPolicyTypes_602617(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerPolicyTypes_602616(path: JsonNode;
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
  var valid_602618 = query.getOrDefault("Action")
  valid_602618 = validateParameter(valid_602618, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_602618 != nil:
    section.add "Action", valid_602618
  var valid_602619 = query.getOrDefault("Version")
  valid_602619 = validateParameter(valid_602619, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602619 != nil:
    section.add "Version", valid_602619
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
  var valid_602620 = header.getOrDefault("X-Amz-Signature")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "X-Amz-Signature", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-Content-Sha256", valid_602621
  var valid_602622 = header.getOrDefault("X-Amz-Date")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "X-Amz-Date", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Credential")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Credential", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Security-Token")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Security-Token", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Algorithm")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Algorithm", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-SignedHeaders", valid_602626
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  section = newJObject()
  var valid_602627 = formData.getOrDefault("PolicyTypeNames")
  valid_602627 = validateParameter(valid_602627, JArray, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "PolicyTypeNames", valid_602627
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602628: Call_PostDescribeLoadBalancerPolicyTypes_602615;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_602628.validator(path, query, header, formData, body)
  let scheme = call_602628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602628.url(scheme.get, call_602628.host, call_602628.base,
                         call_602628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602628, url, valid)

proc call*(call_602629: Call_PostDescribeLoadBalancerPolicyTypes_602615;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602630 = newJObject()
  var formData_602631 = newJObject()
  if PolicyTypeNames != nil:
    formData_602631.add "PolicyTypeNames", PolicyTypeNames
  add(query_602630, "Action", newJString(Action))
  add(query_602630, "Version", newJString(Version))
  result = call_602629.call(nil, query_602630, nil, formData_602631, nil)

var postDescribeLoadBalancerPolicyTypes* = Call_PostDescribeLoadBalancerPolicyTypes_602615(
    name: "postDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_PostDescribeLoadBalancerPolicyTypes_602616, base: "/",
    url: url_PostDescribeLoadBalancerPolicyTypes_602617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicyTypes_602599 = ref object of OpenApiRestCall_601389
proc url_GetDescribeLoadBalancerPolicyTypes_602601(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerPolicyTypes_602600(path: JsonNode;
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
  var valid_602602 = query.getOrDefault("PolicyTypeNames")
  valid_602602 = validateParameter(valid_602602, JArray, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "PolicyTypeNames", valid_602602
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602603 = query.getOrDefault("Action")
  valid_602603 = validateParameter(valid_602603, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_602603 != nil:
    section.add "Action", valid_602603
  var valid_602604 = query.getOrDefault("Version")
  valid_602604 = validateParameter(valid_602604, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602604 != nil:
    section.add "Version", valid_602604
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
  var valid_602605 = header.getOrDefault("X-Amz-Signature")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Signature", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Content-Sha256", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-Date")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-Date", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-Credential")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Credential", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-Security-Token")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Security-Token", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-Algorithm")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Algorithm", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-SignedHeaders", valid_602611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602612: Call_GetDescribeLoadBalancerPolicyTypes_602599;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_602612.validator(path, query, header, formData, body)
  let scheme = call_602612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602612.url(scheme.get, call_602612.host, call_602612.base,
                         call_602612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602612, url, valid)

proc call*(call_602613: Call_GetDescribeLoadBalancerPolicyTypes_602599;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602614 = newJObject()
  if PolicyTypeNames != nil:
    query_602614.add "PolicyTypeNames", PolicyTypeNames
  add(query_602614, "Action", newJString(Action))
  add(query_602614, "Version", newJString(Version))
  result = call_602613.call(nil, query_602614, nil, nil, nil)

var getDescribeLoadBalancerPolicyTypes* = Call_GetDescribeLoadBalancerPolicyTypes_602599(
    name: "getDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_GetDescribeLoadBalancerPolicyTypes_602600, base: "/",
    url: url_GetDescribeLoadBalancerPolicyTypes_602601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_602650 = ref object of OpenApiRestCall_601389
proc url_PostDescribeLoadBalancers_602652(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancers_602651(path: JsonNode; query: JsonNode;
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
  var valid_602653 = query.getOrDefault("Action")
  valid_602653 = validateParameter(valid_602653, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_602653 != nil:
    section.add "Action", valid_602653
  var valid_602654 = query.getOrDefault("Version")
  valid_602654 = validateParameter(valid_602654, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602654 != nil:
    section.add "Version", valid_602654
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
  var valid_602655 = header.getOrDefault("X-Amz-Signature")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "X-Amz-Signature", valid_602655
  var valid_602656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Content-Sha256", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Date")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Date", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-Credential")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-Credential", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-Security-Token")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-Security-Token", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-Algorithm")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Algorithm", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-SignedHeaders", valid_602661
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  section = newJObject()
  var valid_602662 = formData.getOrDefault("LoadBalancerNames")
  valid_602662 = validateParameter(valid_602662, JArray, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "LoadBalancerNames", valid_602662
  var valid_602663 = formData.getOrDefault("Marker")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "Marker", valid_602663
  var valid_602664 = formData.getOrDefault("PageSize")
  valid_602664 = validateParameter(valid_602664, JInt, required = false, default = nil)
  if valid_602664 != nil:
    section.add "PageSize", valid_602664
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602665: Call_PostDescribeLoadBalancers_602650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_602665.validator(path, query, header, formData, body)
  let scheme = call_602665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602665.url(scheme.get, call_602665.host, call_602665.base,
                         call_602665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602665, url, valid)

proc call*(call_602666: Call_PostDescribeLoadBalancers_602650;
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
  var query_602667 = newJObject()
  var formData_602668 = newJObject()
  if LoadBalancerNames != nil:
    formData_602668.add "LoadBalancerNames", LoadBalancerNames
  add(formData_602668, "Marker", newJString(Marker))
  add(query_602667, "Action", newJString(Action))
  add(formData_602668, "PageSize", newJInt(PageSize))
  add(query_602667, "Version", newJString(Version))
  result = call_602666.call(nil, query_602667, nil, formData_602668, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_602650(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_602651, base: "/",
    url: url_PostDescribeLoadBalancers_602652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_602632 = ref object of OpenApiRestCall_601389
proc url_GetDescribeLoadBalancers_602634(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancers_602633(path: JsonNode; query: JsonNode;
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
  var valid_602635 = query.getOrDefault("Marker")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "Marker", valid_602635
  var valid_602636 = query.getOrDefault("PageSize")
  valid_602636 = validateParameter(valid_602636, JInt, required = false, default = nil)
  if valid_602636 != nil:
    section.add "PageSize", valid_602636
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602637 = query.getOrDefault("Action")
  valid_602637 = validateParameter(valid_602637, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_602637 != nil:
    section.add "Action", valid_602637
  var valid_602638 = query.getOrDefault("Version")
  valid_602638 = validateParameter(valid_602638, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602638 != nil:
    section.add "Version", valid_602638
  var valid_602639 = query.getOrDefault("LoadBalancerNames")
  valid_602639 = validateParameter(valid_602639, JArray, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "LoadBalancerNames", valid_602639
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
  var valid_602640 = header.getOrDefault("X-Amz-Signature")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Signature", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Content-Sha256", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Date")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Date", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Credential")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Credential", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Security-Token")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Security-Token", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-Algorithm")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Algorithm", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-SignedHeaders", valid_602646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602647: Call_GetDescribeLoadBalancers_602632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_602647.validator(path, query, header, formData, body)
  let scheme = call_602647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602647.url(scheme.get, call_602647.host, call_602647.base,
                         call_602647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602647, url, valid)

proc call*(call_602648: Call_GetDescribeLoadBalancers_602632; Marker: string = "";
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
  var query_602649 = newJObject()
  add(query_602649, "Marker", newJString(Marker))
  add(query_602649, "PageSize", newJInt(PageSize))
  add(query_602649, "Action", newJString(Action))
  add(query_602649, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_602649.add "LoadBalancerNames", LoadBalancerNames
  result = call_602648.call(nil, query_602649, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_602632(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_602633, base: "/",
    url: url_GetDescribeLoadBalancers_602634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_602685 = ref object of OpenApiRestCall_601389
proc url_PostDescribeTags_602687(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeTags_602686(path: JsonNode; query: JsonNode;
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
  var valid_602688 = query.getOrDefault("Action")
  valid_602688 = validateParameter(valid_602688, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_602688 != nil:
    section.add "Action", valid_602688
  var valid_602689 = query.getOrDefault("Version")
  valid_602689 = validateParameter(valid_602689, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602689 != nil:
    section.add "Version", valid_602689
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
  var valid_602690 = header.getOrDefault("X-Amz-Signature")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Signature", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Content-Sha256", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Date")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Date", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Credential")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Credential", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-Security-Token")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Security-Token", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-Algorithm")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-Algorithm", valid_602695
  var valid_602696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-SignedHeaders", valid_602696
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_602697 = formData.getOrDefault("LoadBalancerNames")
  valid_602697 = validateParameter(valid_602697, JArray, required = true, default = nil)
  if valid_602697 != nil:
    section.add "LoadBalancerNames", valid_602697
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602698: Call_PostDescribeTags_602685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_602698.validator(path, query, header, formData, body)
  let scheme = call_602698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602698.url(scheme.get, call_602698.host, call_602698.base,
                         call_602698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602698, url, valid)

proc call*(call_602699: Call_PostDescribeTags_602685; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602700 = newJObject()
  var formData_602701 = newJObject()
  if LoadBalancerNames != nil:
    formData_602701.add "LoadBalancerNames", LoadBalancerNames
  add(query_602700, "Action", newJString(Action))
  add(query_602700, "Version", newJString(Version))
  result = call_602699.call(nil, query_602700, nil, formData_602701, nil)

var postDescribeTags* = Call_PostDescribeTags_602685(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_602686,
    base: "/", url: url_PostDescribeTags_602687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_602669 = ref object of OpenApiRestCall_601389
proc url_GetDescribeTags_602671(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTags_602670(path: JsonNode; query: JsonNode;
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
  var valid_602672 = query.getOrDefault("Action")
  valid_602672 = validateParameter(valid_602672, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_602672 != nil:
    section.add "Action", valid_602672
  var valid_602673 = query.getOrDefault("Version")
  valid_602673 = validateParameter(valid_602673, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602673 != nil:
    section.add "Version", valid_602673
  var valid_602674 = query.getOrDefault("LoadBalancerNames")
  valid_602674 = validateParameter(valid_602674, JArray, required = true, default = nil)
  if valid_602674 != nil:
    section.add "LoadBalancerNames", valid_602674
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
  var valid_602675 = header.getOrDefault("X-Amz-Signature")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Signature", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Content-Sha256", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Date")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Date", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Credential")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Credential", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Security-Token")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Security-Token", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-Algorithm")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-Algorithm", valid_602680
  var valid_602681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-SignedHeaders", valid_602681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602682: Call_GetDescribeTags_602669; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_602682.validator(path, query, header, formData, body)
  let scheme = call_602682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602682.url(scheme.get, call_602682.host, call_602682.base,
                         call_602682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602682, url, valid)

proc call*(call_602683: Call_GetDescribeTags_602669; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  var query_602684 = newJObject()
  add(query_602684, "Action", newJString(Action))
  add(query_602684, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_602684.add "LoadBalancerNames", LoadBalancerNames
  result = call_602683.call(nil, query_602684, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_602669(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_602670,
    base: "/", url: url_GetDescribeTags_602671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDetachLoadBalancerFromSubnets_602719 = ref object of OpenApiRestCall_601389
proc url_PostDetachLoadBalancerFromSubnets_602721(protocol: Scheme; host: string;
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

proc validate_PostDetachLoadBalancerFromSubnets_602720(path: JsonNode;
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
  var valid_602722 = query.getOrDefault("Action")
  valid_602722 = validateParameter(valid_602722, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_602722 != nil:
    section.add "Action", valid_602722
  var valid_602723 = query.getOrDefault("Version")
  valid_602723 = validateParameter(valid_602723, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602723 != nil:
    section.add "Version", valid_602723
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
  var valid_602724 = header.getOrDefault("X-Amz-Signature")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-Signature", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Content-Sha256", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-Date")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-Date", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-Credential")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-Credential", valid_602727
  var valid_602728 = header.getOrDefault("X-Amz-Security-Token")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Security-Token", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-Algorithm")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Algorithm", valid_602729
  var valid_602730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "X-Amz-SignedHeaders", valid_602730
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_602731 = formData.getOrDefault("Subnets")
  valid_602731 = validateParameter(valid_602731, JArray, required = true, default = nil)
  if valid_602731 != nil:
    section.add "Subnets", valid_602731
  var valid_602732 = formData.getOrDefault("LoadBalancerName")
  valid_602732 = validateParameter(valid_602732, JString, required = true,
                                 default = nil)
  if valid_602732 != nil:
    section.add "LoadBalancerName", valid_602732
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602733: Call_PostDetachLoadBalancerFromSubnets_602719;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_602733.validator(path, query, header, formData, body)
  let scheme = call_602733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602733.url(scheme.get, call_602733.host, call_602733.base,
                         call_602733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602733, url, valid)

proc call*(call_602734: Call_PostDetachLoadBalancerFromSubnets_602719;
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
  var query_602735 = newJObject()
  var formData_602736 = newJObject()
  if Subnets != nil:
    formData_602736.add "Subnets", Subnets
  add(formData_602736, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602735, "Action", newJString(Action))
  add(query_602735, "Version", newJString(Version))
  result = call_602734.call(nil, query_602735, nil, formData_602736, nil)

var postDetachLoadBalancerFromSubnets* = Call_PostDetachLoadBalancerFromSubnets_602719(
    name: "postDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_PostDetachLoadBalancerFromSubnets_602720, base: "/",
    url: url_PostDetachLoadBalancerFromSubnets_602721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetachLoadBalancerFromSubnets_602702 = ref object of OpenApiRestCall_601389
proc url_GetDetachLoadBalancerFromSubnets_602704(protocol: Scheme; host: string;
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

proc validate_GetDetachLoadBalancerFromSubnets_602703(path: JsonNode;
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
  var valid_602705 = query.getOrDefault("LoadBalancerName")
  valid_602705 = validateParameter(valid_602705, JString, required = true,
                                 default = nil)
  if valid_602705 != nil:
    section.add "LoadBalancerName", valid_602705
  var valid_602706 = query.getOrDefault("Action")
  valid_602706 = validateParameter(valid_602706, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_602706 != nil:
    section.add "Action", valid_602706
  var valid_602707 = query.getOrDefault("Subnets")
  valid_602707 = validateParameter(valid_602707, JArray, required = true, default = nil)
  if valid_602707 != nil:
    section.add "Subnets", valid_602707
  var valid_602708 = query.getOrDefault("Version")
  valid_602708 = validateParameter(valid_602708, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602708 != nil:
    section.add "Version", valid_602708
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
  var valid_602709 = header.getOrDefault("X-Amz-Signature")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Signature", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Content-Sha256", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-Date")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-Date", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-Credential")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-Credential", valid_602712
  var valid_602713 = header.getOrDefault("X-Amz-Security-Token")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Security-Token", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-Algorithm")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Algorithm", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-SignedHeaders", valid_602715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602716: Call_GetDetachLoadBalancerFromSubnets_602702;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_602716.validator(path, query, header, formData, body)
  let scheme = call_602716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602716.url(scheme.get, call_602716.host, call_602716.base,
                         call_602716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602716, url, valid)

proc call*(call_602717: Call_GetDetachLoadBalancerFromSubnets_602702;
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
  var query_602718 = newJObject()
  add(query_602718, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602718, "Action", newJString(Action))
  if Subnets != nil:
    query_602718.add "Subnets", Subnets
  add(query_602718, "Version", newJString(Version))
  result = call_602717.call(nil, query_602718, nil, nil, nil)

var getDetachLoadBalancerFromSubnets* = Call_GetDetachLoadBalancerFromSubnets_602702(
    name: "getDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_GetDetachLoadBalancerFromSubnets_602703, base: "/",
    url: url_GetDetachLoadBalancerFromSubnets_602704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAvailabilityZonesForLoadBalancer_602754 = ref object of OpenApiRestCall_601389
proc url_PostDisableAvailabilityZonesForLoadBalancer_602756(protocol: Scheme;
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

proc validate_PostDisableAvailabilityZonesForLoadBalancer_602755(path: JsonNode;
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
  var valid_602757 = query.getOrDefault("Action")
  valid_602757 = validateParameter(valid_602757, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_602757 != nil:
    section.add "Action", valid_602757
  var valid_602758 = query.getOrDefault("Version")
  valid_602758 = validateParameter(valid_602758, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602758 != nil:
    section.add "Version", valid_602758
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
  var valid_602759 = header.getOrDefault("X-Amz-Signature")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Signature", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-Content-Sha256", valid_602760
  var valid_602761 = header.getOrDefault("X-Amz-Date")
  valid_602761 = validateParameter(valid_602761, JString, required = false,
                                 default = nil)
  if valid_602761 != nil:
    section.add "X-Amz-Date", valid_602761
  var valid_602762 = header.getOrDefault("X-Amz-Credential")
  valid_602762 = validateParameter(valid_602762, JString, required = false,
                                 default = nil)
  if valid_602762 != nil:
    section.add "X-Amz-Credential", valid_602762
  var valid_602763 = header.getOrDefault("X-Amz-Security-Token")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "X-Amz-Security-Token", valid_602763
  var valid_602764 = header.getOrDefault("X-Amz-Algorithm")
  valid_602764 = validateParameter(valid_602764, JString, required = false,
                                 default = nil)
  if valid_602764 != nil:
    section.add "X-Amz-Algorithm", valid_602764
  var valid_602765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "X-Amz-SignedHeaders", valid_602765
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_602766 = formData.getOrDefault("AvailabilityZones")
  valid_602766 = validateParameter(valid_602766, JArray, required = true, default = nil)
  if valid_602766 != nil:
    section.add "AvailabilityZones", valid_602766
  var valid_602767 = formData.getOrDefault("LoadBalancerName")
  valid_602767 = validateParameter(valid_602767, JString, required = true,
                                 default = nil)
  if valid_602767 != nil:
    section.add "LoadBalancerName", valid_602767
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602768: Call_PostDisableAvailabilityZonesForLoadBalancer_602754;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602768.validator(path, query, header, formData, body)
  let scheme = call_602768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602768.url(scheme.get, call_602768.host, call_602768.base,
                         call_602768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602768, url, valid)

proc call*(call_602769: Call_PostDisableAvailabilityZonesForLoadBalancer_602754;
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
  var query_602770 = newJObject()
  var formData_602771 = newJObject()
  if AvailabilityZones != nil:
    formData_602771.add "AvailabilityZones", AvailabilityZones
  add(formData_602771, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602770, "Action", newJString(Action))
  add(query_602770, "Version", newJString(Version))
  result = call_602769.call(nil, query_602770, nil, formData_602771, nil)

var postDisableAvailabilityZonesForLoadBalancer* = Call_PostDisableAvailabilityZonesForLoadBalancer_602754(
    name: "postDisableAvailabilityZonesForLoadBalancer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_PostDisableAvailabilityZonesForLoadBalancer_602755,
    base: "/", url: url_PostDisableAvailabilityZonesForLoadBalancer_602756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAvailabilityZonesForLoadBalancer_602737 = ref object of OpenApiRestCall_601389
proc url_GetDisableAvailabilityZonesForLoadBalancer_602739(protocol: Scheme;
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

proc validate_GetDisableAvailabilityZonesForLoadBalancer_602738(path: JsonNode;
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
  var valid_602740 = query.getOrDefault("AvailabilityZones")
  valid_602740 = validateParameter(valid_602740, JArray, required = true, default = nil)
  if valid_602740 != nil:
    section.add "AvailabilityZones", valid_602740
  var valid_602741 = query.getOrDefault("LoadBalancerName")
  valid_602741 = validateParameter(valid_602741, JString, required = true,
                                 default = nil)
  if valid_602741 != nil:
    section.add "LoadBalancerName", valid_602741
  var valid_602742 = query.getOrDefault("Action")
  valid_602742 = validateParameter(valid_602742, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_602742 != nil:
    section.add "Action", valid_602742
  var valid_602743 = query.getOrDefault("Version")
  valid_602743 = validateParameter(valid_602743, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602743 != nil:
    section.add "Version", valid_602743
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
  var valid_602744 = header.getOrDefault("X-Amz-Signature")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Signature", valid_602744
  var valid_602745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602745 = validateParameter(valid_602745, JString, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "X-Amz-Content-Sha256", valid_602745
  var valid_602746 = header.getOrDefault("X-Amz-Date")
  valid_602746 = validateParameter(valid_602746, JString, required = false,
                                 default = nil)
  if valid_602746 != nil:
    section.add "X-Amz-Date", valid_602746
  var valid_602747 = header.getOrDefault("X-Amz-Credential")
  valid_602747 = validateParameter(valid_602747, JString, required = false,
                                 default = nil)
  if valid_602747 != nil:
    section.add "X-Amz-Credential", valid_602747
  var valid_602748 = header.getOrDefault("X-Amz-Security-Token")
  valid_602748 = validateParameter(valid_602748, JString, required = false,
                                 default = nil)
  if valid_602748 != nil:
    section.add "X-Amz-Security-Token", valid_602748
  var valid_602749 = header.getOrDefault("X-Amz-Algorithm")
  valid_602749 = validateParameter(valid_602749, JString, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "X-Amz-Algorithm", valid_602749
  var valid_602750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-SignedHeaders", valid_602750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602751: Call_GetDisableAvailabilityZonesForLoadBalancer_602737;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602751.validator(path, query, header, formData, body)
  let scheme = call_602751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602751.url(scheme.get, call_602751.host, call_602751.base,
                         call_602751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602751, url, valid)

proc call*(call_602752: Call_GetDisableAvailabilityZonesForLoadBalancer_602737;
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
  var query_602753 = newJObject()
  if AvailabilityZones != nil:
    query_602753.add "AvailabilityZones", AvailabilityZones
  add(query_602753, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602753, "Action", newJString(Action))
  add(query_602753, "Version", newJString(Version))
  result = call_602752.call(nil, query_602753, nil, nil, nil)

var getDisableAvailabilityZonesForLoadBalancer* = Call_GetDisableAvailabilityZonesForLoadBalancer_602737(
    name: "getDisableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_GetDisableAvailabilityZonesForLoadBalancer_602738,
    base: "/", url: url_GetDisableAvailabilityZonesForLoadBalancer_602739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAvailabilityZonesForLoadBalancer_602789 = ref object of OpenApiRestCall_601389
proc url_PostEnableAvailabilityZonesForLoadBalancer_602791(protocol: Scheme;
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

proc validate_PostEnableAvailabilityZonesForLoadBalancer_602790(path: JsonNode;
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
  var valid_602792 = query.getOrDefault("Action")
  valid_602792 = validateParameter(valid_602792, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_602792 != nil:
    section.add "Action", valid_602792
  var valid_602793 = query.getOrDefault("Version")
  valid_602793 = validateParameter(valid_602793, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602793 != nil:
    section.add "Version", valid_602793
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
  var valid_602794 = header.getOrDefault("X-Amz-Signature")
  valid_602794 = validateParameter(valid_602794, JString, required = false,
                                 default = nil)
  if valid_602794 != nil:
    section.add "X-Amz-Signature", valid_602794
  var valid_602795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602795 = validateParameter(valid_602795, JString, required = false,
                                 default = nil)
  if valid_602795 != nil:
    section.add "X-Amz-Content-Sha256", valid_602795
  var valid_602796 = header.getOrDefault("X-Amz-Date")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "X-Amz-Date", valid_602796
  var valid_602797 = header.getOrDefault("X-Amz-Credential")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-Credential", valid_602797
  var valid_602798 = header.getOrDefault("X-Amz-Security-Token")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-Security-Token", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Algorithm")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Algorithm", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-SignedHeaders", valid_602800
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_602801 = formData.getOrDefault("AvailabilityZones")
  valid_602801 = validateParameter(valid_602801, JArray, required = true, default = nil)
  if valid_602801 != nil:
    section.add "AvailabilityZones", valid_602801
  var valid_602802 = formData.getOrDefault("LoadBalancerName")
  valid_602802 = validateParameter(valid_602802, JString, required = true,
                                 default = nil)
  if valid_602802 != nil:
    section.add "LoadBalancerName", valid_602802
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602803: Call_PostEnableAvailabilityZonesForLoadBalancer_602789;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602803.validator(path, query, header, formData, body)
  let scheme = call_602803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602803.url(scheme.get, call_602803.host, call_602803.base,
                         call_602803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602803, url, valid)

proc call*(call_602804: Call_PostEnableAvailabilityZonesForLoadBalancer_602789;
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
  var query_602805 = newJObject()
  var formData_602806 = newJObject()
  if AvailabilityZones != nil:
    formData_602806.add "AvailabilityZones", AvailabilityZones
  add(formData_602806, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602805, "Action", newJString(Action))
  add(query_602805, "Version", newJString(Version))
  result = call_602804.call(nil, query_602805, nil, formData_602806, nil)

var postEnableAvailabilityZonesForLoadBalancer* = Call_PostEnableAvailabilityZonesForLoadBalancer_602789(
    name: "postEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_PostEnableAvailabilityZonesForLoadBalancer_602790,
    base: "/", url: url_PostEnableAvailabilityZonesForLoadBalancer_602791,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAvailabilityZonesForLoadBalancer_602772 = ref object of OpenApiRestCall_601389
proc url_GetEnableAvailabilityZonesForLoadBalancer_602774(protocol: Scheme;
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

proc validate_GetEnableAvailabilityZonesForLoadBalancer_602773(path: JsonNode;
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
  var valid_602775 = query.getOrDefault("AvailabilityZones")
  valid_602775 = validateParameter(valid_602775, JArray, required = true, default = nil)
  if valid_602775 != nil:
    section.add "AvailabilityZones", valid_602775
  var valid_602776 = query.getOrDefault("LoadBalancerName")
  valid_602776 = validateParameter(valid_602776, JString, required = true,
                                 default = nil)
  if valid_602776 != nil:
    section.add "LoadBalancerName", valid_602776
  var valid_602777 = query.getOrDefault("Action")
  valid_602777 = validateParameter(valid_602777, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_602777 != nil:
    section.add "Action", valid_602777
  var valid_602778 = query.getOrDefault("Version")
  valid_602778 = validateParameter(valid_602778, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602778 != nil:
    section.add "Version", valid_602778
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
  var valid_602779 = header.getOrDefault("X-Amz-Signature")
  valid_602779 = validateParameter(valid_602779, JString, required = false,
                                 default = nil)
  if valid_602779 != nil:
    section.add "X-Amz-Signature", valid_602779
  var valid_602780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602780 = validateParameter(valid_602780, JString, required = false,
                                 default = nil)
  if valid_602780 != nil:
    section.add "X-Amz-Content-Sha256", valid_602780
  var valid_602781 = header.getOrDefault("X-Amz-Date")
  valid_602781 = validateParameter(valid_602781, JString, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "X-Amz-Date", valid_602781
  var valid_602782 = header.getOrDefault("X-Amz-Credential")
  valid_602782 = validateParameter(valid_602782, JString, required = false,
                                 default = nil)
  if valid_602782 != nil:
    section.add "X-Amz-Credential", valid_602782
  var valid_602783 = header.getOrDefault("X-Amz-Security-Token")
  valid_602783 = validateParameter(valid_602783, JString, required = false,
                                 default = nil)
  if valid_602783 != nil:
    section.add "X-Amz-Security-Token", valid_602783
  var valid_602784 = header.getOrDefault("X-Amz-Algorithm")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Algorithm", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-SignedHeaders", valid_602785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602786: Call_GetEnableAvailabilityZonesForLoadBalancer_602772;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602786.validator(path, query, header, formData, body)
  let scheme = call_602786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602786.url(scheme.get, call_602786.host, call_602786.base,
                         call_602786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602786, url, valid)

proc call*(call_602787: Call_GetEnableAvailabilityZonesForLoadBalancer_602772;
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
  var query_602788 = newJObject()
  if AvailabilityZones != nil:
    query_602788.add "AvailabilityZones", AvailabilityZones
  add(query_602788, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602788, "Action", newJString(Action))
  add(query_602788, "Version", newJString(Version))
  result = call_602787.call(nil, query_602788, nil, nil, nil)

var getEnableAvailabilityZonesForLoadBalancer* = Call_GetEnableAvailabilityZonesForLoadBalancer_602772(
    name: "getEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_GetEnableAvailabilityZonesForLoadBalancer_602773,
    base: "/", url: url_GetEnableAvailabilityZonesForLoadBalancer_602774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_602828 = ref object of OpenApiRestCall_601389
proc url_PostModifyLoadBalancerAttributes_602830(protocol: Scheme; host: string;
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

proc validate_PostModifyLoadBalancerAttributes_602829(path: JsonNode;
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
  var valid_602831 = query.getOrDefault("Action")
  valid_602831 = validateParameter(valid_602831, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_602831 != nil:
    section.add "Action", valid_602831
  var valid_602832 = query.getOrDefault("Version")
  valid_602832 = validateParameter(valid_602832, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602832 != nil:
    section.add "Version", valid_602832
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
  var valid_602833 = header.getOrDefault("X-Amz-Signature")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Signature", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Content-Sha256", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-Date")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Date", valid_602835
  var valid_602836 = header.getOrDefault("X-Amz-Credential")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-Credential", valid_602836
  var valid_602837 = header.getOrDefault("X-Amz-Security-Token")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-Security-Token", valid_602837
  var valid_602838 = header.getOrDefault("X-Amz-Algorithm")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-Algorithm", valid_602838
  var valid_602839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602839 = validateParameter(valid_602839, JString, required = false,
                                 default = nil)
  if valid_602839 != nil:
    section.add "X-Amz-SignedHeaders", valid_602839
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
  var valid_602840 = formData.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_602840
  var valid_602841 = formData.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_602841 = validateParameter(valid_602841, JArray, required = false,
                                 default = nil)
  if valid_602841 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_602841
  var valid_602842 = formData.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_602842 = validateParameter(valid_602842, JString, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_602842
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_602843 = formData.getOrDefault("LoadBalancerName")
  valid_602843 = validateParameter(valid_602843, JString, required = true,
                                 default = nil)
  if valid_602843 != nil:
    section.add "LoadBalancerName", valid_602843
  var valid_602844 = formData.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_602844
  var valid_602845 = formData.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_602845
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602846: Call_PostModifyLoadBalancerAttributes_602828;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_602846.validator(path, query, header, formData, body)
  let scheme = call_602846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602846.url(scheme.get, call_602846.host, call_602846.base,
                         call_602846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602846, url, valid)

proc call*(call_602847: Call_PostModifyLoadBalancerAttributes_602828;
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
  var query_602848 = newJObject()
  var formData_602849 = newJObject()
  add(formData_602849, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    formData_602849.add "LoadBalancerAttributes.AdditionalAttributes",
                       LoadBalancerAttributesAdditionalAttributes
  add(formData_602849, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(formData_602849, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602848, "Action", newJString(Action))
  add(formData_602849, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_602848, "Version", newJString(Version))
  add(formData_602849, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  result = call_602847.call(nil, query_602848, nil, formData_602849, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_602828(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_602829, base: "/",
    url: url_PostModifyLoadBalancerAttributes_602830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_602807 = ref object of OpenApiRestCall_601389
proc url_GetModifyLoadBalancerAttributes_602809(protocol: Scheme; host: string;
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

proc validate_GetModifyLoadBalancerAttributes_602808(path: JsonNode;
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
  var valid_602810 = query.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_602810
  var valid_602811 = query.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_602811
  var valid_602812 = query.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_602812 = validateParameter(valid_602812, JString, required = false,
                                 default = nil)
  if valid_602812 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_602812
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_602813 = query.getOrDefault("LoadBalancerName")
  valid_602813 = validateParameter(valid_602813, JString, required = true,
                                 default = nil)
  if valid_602813 != nil:
    section.add "LoadBalancerName", valid_602813
  var valid_602814 = query.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_602814
  var valid_602815 = query.getOrDefault("Action")
  valid_602815 = validateParameter(valid_602815, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_602815 != nil:
    section.add "Action", valid_602815
  var valid_602816 = query.getOrDefault("Version")
  valid_602816 = validateParameter(valid_602816, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602816 != nil:
    section.add "Version", valid_602816
  var valid_602817 = query.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_602817 = validateParameter(valid_602817, JArray, required = false,
                                 default = nil)
  if valid_602817 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_602817
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
  var valid_602818 = header.getOrDefault("X-Amz-Signature")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "X-Amz-Signature", valid_602818
  var valid_602819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Content-Sha256", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-Date")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Date", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Credential")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Credential", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-Security-Token")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Security-Token", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-Algorithm")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Algorithm", valid_602823
  var valid_602824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-SignedHeaders", valid_602824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602825: Call_GetModifyLoadBalancerAttributes_602807;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_602825.validator(path, query, header, formData, body)
  let scheme = call_602825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602825.url(scheme.get, call_602825.host, call_602825.base,
                         call_602825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602825, url, valid)

proc call*(call_602826: Call_GetModifyLoadBalancerAttributes_602807;
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
  var query_602827 = newJObject()
  add(query_602827, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_602827, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_602827, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_602827, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602827, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  add(query_602827, "Action", newJString(Action))
  add(query_602827, "Version", newJString(Version))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    query_602827.add "LoadBalancerAttributes.AdditionalAttributes",
                    LoadBalancerAttributesAdditionalAttributes
  result = call_602826.call(nil, query_602827, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_602807(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_602808, base: "/",
    url: url_GetModifyLoadBalancerAttributes_602809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterInstancesWithLoadBalancer_602867 = ref object of OpenApiRestCall_601389
proc url_PostRegisterInstancesWithLoadBalancer_602869(protocol: Scheme;
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

proc validate_PostRegisterInstancesWithLoadBalancer_602868(path: JsonNode;
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
  var valid_602870 = query.getOrDefault("Action")
  valid_602870 = validateParameter(valid_602870, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_602870 != nil:
    section.add "Action", valid_602870
  var valid_602871 = query.getOrDefault("Version")
  valid_602871 = validateParameter(valid_602871, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602871 != nil:
    section.add "Version", valid_602871
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
  var valid_602872 = header.getOrDefault("X-Amz-Signature")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Signature", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Content-Sha256", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Date")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Date", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Credential")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Credential", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Security-Token")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Security-Token", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-Algorithm")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Algorithm", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-SignedHeaders", valid_602878
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_602879 = formData.getOrDefault("Instances")
  valid_602879 = validateParameter(valid_602879, JArray, required = true, default = nil)
  if valid_602879 != nil:
    section.add "Instances", valid_602879
  var valid_602880 = formData.getOrDefault("LoadBalancerName")
  valid_602880 = validateParameter(valid_602880, JString, required = true,
                                 default = nil)
  if valid_602880 != nil:
    section.add "LoadBalancerName", valid_602880
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602881: Call_PostRegisterInstancesWithLoadBalancer_602867;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602881.validator(path, query, header, formData, body)
  let scheme = call_602881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602881.url(scheme.get, call_602881.host, call_602881.base,
                         call_602881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602881, url, valid)

proc call*(call_602882: Call_PostRegisterInstancesWithLoadBalancer_602867;
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
  var query_602883 = newJObject()
  var formData_602884 = newJObject()
  if Instances != nil:
    formData_602884.add "Instances", Instances
  add(formData_602884, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602883, "Action", newJString(Action))
  add(query_602883, "Version", newJString(Version))
  result = call_602882.call(nil, query_602883, nil, formData_602884, nil)

var postRegisterInstancesWithLoadBalancer* = Call_PostRegisterInstancesWithLoadBalancer_602867(
    name: "postRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_PostRegisterInstancesWithLoadBalancer_602868, base: "/",
    url: url_PostRegisterInstancesWithLoadBalancer_602869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterInstancesWithLoadBalancer_602850 = ref object of OpenApiRestCall_601389
proc url_GetRegisterInstancesWithLoadBalancer_602852(protocol: Scheme;
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

proc validate_GetRegisterInstancesWithLoadBalancer_602851(path: JsonNode;
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
  var valid_602853 = query.getOrDefault("LoadBalancerName")
  valid_602853 = validateParameter(valid_602853, JString, required = true,
                                 default = nil)
  if valid_602853 != nil:
    section.add "LoadBalancerName", valid_602853
  var valid_602854 = query.getOrDefault("Action")
  valid_602854 = validateParameter(valid_602854, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_602854 != nil:
    section.add "Action", valid_602854
  var valid_602855 = query.getOrDefault("Instances")
  valid_602855 = validateParameter(valid_602855, JArray, required = true, default = nil)
  if valid_602855 != nil:
    section.add "Instances", valid_602855
  var valid_602856 = query.getOrDefault("Version")
  valid_602856 = validateParameter(valid_602856, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602856 != nil:
    section.add "Version", valid_602856
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
  var valid_602857 = header.getOrDefault("X-Amz-Signature")
  valid_602857 = validateParameter(valid_602857, JString, required = false,
                                 default = nil)
  if valid_602857 != nil:
    section.add "X-Amz-Signature", valid_602857
  var valid_602858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "X-Amz-Content-Sha256", valid_602858
  var valid_602859 = header.getOrDefault("X-Amz-Date")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Date", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-Credential")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-Credential", valid_602860
  var valid_602861 = header.getOrDefault("X-Amz-Security-Token")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-Security-Token", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-Algorithm")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-Algorithm", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-SignedHeaders", valid_602863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602864: Call_GetRegisterInstancesWithLoadBalancer_602850;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602864.validator(path, query, header, formData, body)
  let scheme = call_602864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602864.url(scheme.get, call_602864.host, call_602864.base,
                         call_602864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602864, url, valid)

proc call*(call_602865: Call_GetRegisterInstancesWithLoadBalancer_602850;
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
  var query_602866 = newJObject()
  add(query_602866, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602866, "Action", newJString(Action))
  if Instances != nil:
    query_602866.add "Instances", Instances
  add(query_602866, "Version", newJString(Version))
  result = call_602865.call(nil, query_602866, nil, nil, nil)

var getRegisterInstancesWithLoadBalancer* = Call_GetRegisterInstancesWithLoadBalancer_602850(
    name: "getRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_GetRegisterInstancesWithLoadBalancer_602851, base: "/",
    url: url_GetRegisterInstancesWithLoadBalancer_602852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_602902 = ref object of OpenApiRestCall_601389
proc url_PostRemoveTags_602904(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemoveTags_602903(path: JsonNode; query: JsonNode;
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
  var valid_602905 = query.getOrDefault("Action")
  valid_602905 = validateParameter(valid_602905, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_602905 != nil:
    section.add "Action", valid_602905
  var valid_602906 = query.getOrDefault("Version")
  valid_602906 = validateParameter(valid_602906, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602906 != nil:
    section.add "Version", valid_602906
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
  var valid_602907 = header.getOrDefault("X-Amz-Signature")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Signature", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Content-Sha256", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Date")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Date", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Credential")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Credential", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-Security-Token")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Security-Token", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-Algorithm")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-Algorithm", valid_602912
  var valid_602913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-SignedHeaders", valid_602913
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_602914 = formData.getOrDefault("LoadBalancerNames")
  valid_602914 = validateParameter(valid_602914, JArray, required = true, default = nil)
  if valid_602914 != nil:
    section.add "LoadBalancerNames", valid_602914
  var valid_602915 = formData.getOrDefault("Tags")
  valid_602915 = validateParameter(valid_602915, JArray, required = true, default = nil)
  if valid_602915 != nil:
    section.add "Tags", valid_602915
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602916: Call_PostRemoveTags_602902; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_602916.validator(path, query, header, formData, body)
  let scheme = call_602916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602916.url(scheme.get, call_602916.host, call_602916.base,
                         call_602916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602916, url, valid)

proc call*(call_602917: Call_PostRemoveTags_602902; LoadBalancerNames: JsonNode;
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
  var query_602918 = newJObject()
  var formData_602919 = newJObject()
  if LoadBalancerNames != nil:
    formData_602919.add "LoadBalancerNames", LoadBalancerNames
  add(query_602918, "Action", newJString(Action))
  if Tags != nil:
    formData_602919.add "Tags", Tags
  add(query_602918, "Version", newJString(Version))
  result = call_602917.call(nil, query_602918, nil, formData_602919, nil)

var postRemoveTags* = Call_PostRemoveTags_602902(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_602903,
    base: "/", url: url_PostRemoveTags_602904, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_602885 = ref object of OpenApiRestCall_601389
proc url_GetRemoveTags_602887(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemoveTags_602886(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602888 = query.getOrDefault("Tags")
  valid_602888 = validateParameter(valid_602888, JArray, required = true, default = nil)
  if valid_602888 != nil:
    section.add "Tags", valid_602888
  var valid_602889 = query.getOrDefault("Action")
  valid_602889 = validateParameter(valid_602889, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_602889 != nil:
    section.add "Action", valid_602889
  var valid_602890 = query.getOrDefault("Version")
  valid_602890 = validateParameter(valid_602890, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602890 != nil:
    section.add "Version", valid_602890
  var valid_602891 = query.getOrDefault("LoadBalancerNames")
  valid_602891 = validateParameter(valid_602891, JArray, required = true, default = nil)
  if valid_602891 != nil:
    section.add "LoadBalancerNames", valid_602891
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
  var valid_602892 = header.getOrDefault("X-Amz-Signature")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-Signature", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Content-Sha256", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-Date")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Date", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-Credential")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Credential", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-Security-Token")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Security-Token", valid_602896
  var valid_602897 = header.getOrDefault("X-Amz-Algorithm")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "X-Amz-Algorithm", valid_602897
  var valid_602898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "X-Amz-SignedHeaders", valid_602898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602899: Call_GetRemoveTags_602885; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_602899.validator(path, query, header, formData, body)
  let scheme = call_602899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602899.url(scheme.get, call_602899.host, call_602899.base,
                         call_602899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602899, url, valid)

proc call*(call_602900: Call_GetRemoveTags_602885; Tags: JsonNode;
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
  var query_602901 = newJObject()
  if Tags != nil:
    query_602901.add "Tags", Tags
  add(query_602901, "Action", newJString(Action))
  add(query_602901, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_602901.add "LoadBalancerNames", LoadBalancerNames
  result = call_602900.call(nil, query_602901, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_602885(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_602886,
    base: "/", url: url_GetRemoveTags_602887, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerListenerSSLCertificate_602938 = ref object of OpenApiRestCall_601389
proc url_PostSetLoadBalancerListenerSSLCertificate_602940(protocol: Scheme;
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

proc validate_PostSetLoadBalancerListenerSSLCertificate_602939(path: JsonNode;
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
  var valid_602941 = query.getOrDefault("Action")
  valid_602941 = validateParameter(valid_602941, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_602941 != nil:
    section.add "Action", valid_602941
  var valid_602942 = query.getOrDefault("Version")
  valid_602942 = validateParameter(valid_602942, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602942 != nil:
    section.add "Version", valid_602942
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
  var valid_602943 = header.getOrDefault("X-Amz-Signature")
  valid_602943 = validateParameter(valid_602943, JString, required = false,
                                 default = nil)
  if valid_602943 != nil:
    section.add "X-Amz-Signature", valid_602943
  var valid_602944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602944 = validateParameter(valid_602944, JString, required = false,
                                 default = nil)
  if valid_602944 != nil:
    section.add "X-Amz-Content-Sha256", valid_602944
  var valid_602945 = header.getOrDefault("X-Amz-Date")
  valid_602945 = validateParameter(valid_602945, JString, required = false,
                                 default = nil)
  if valid_602945 != nil:
    section.add "X-Amz-Date", valid_602945
  var valid_602946 = header.getOrDefault("X-Amz-Credential")
  valid_602946 = validateParameter(valid_602946, JString, required = false,
                                 default = nil)
  if valid_602946 != nil:
    section.add "X-Amz-Credential", valid_602946
  var valid_602947 = header.getOrDefault("X-Amz-Security-Token")
  valid_602947 = validateParameter(valid_602947, JString, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "X-Amz-Security-Token", valid_602947
  var valid_602948 = header.getOrDefault("X-Amz-Algorithm")
  valid_602948 = validateParameter(valid_602948, JString, required = false,
                                 default = nil)
  if valid_602948 != nil:
    section.add "X-Amz-Algorithm", valid_602948
  var valid_602949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "X-Amz-SignedHeaders", valid_602949
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
  var valid_602950 = formData.getOrDefault("LoadBalancerName")
  valid_602950 = validateParameter(valid_602950, JString, required = true,
                                 default = nil)
  if valid_602950 != nil:
    section.add "LoadBalancerName", valid_602950
  var valid_602951 = formData.getOrDefault("SSLCertificateId")
  valid_602951 = validateParameter(valid_602951, JString, required = true,
                                 default = nil)
  if valid_602951 != nil:
    section.add "SSLCertificateId", valid_602951
  var valid_602952 = formData.getOrDefault("LoadBalancerPort")
  valid_602952 = validateParameter(valid_602952, JInt, required = true, default = nil)
  if valid_602952 != nil:
    section.add "LoadBalancerPort", valid_602952
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602953: Call_PostSetLoadBalancerListenerSSLCertificate_602938;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602953.validator(path, query, header, formData, body)
  let scheme = call_602953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602953.url(scheme.get, call_602953.host, call_602953.base,
                         call_602953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602953, url, valid)

proc call*(call_602954: Call_PostSetLoadBalancerListenerSSLCertificate_602938;
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
  var query_602955 = newJObject()
  var formData_602956 = newJObject()
  add(formData_602956, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602955, "Action", newJString(Action))
  add(formData_602956, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_602955, "Version", newJString(Version))
  add(formData_602956, "LoadBalancerPort", newJInt(LoadBalancerPort))
  result = call_602954.call(nil, query_602955, nil, formData_602956, nil)

var postSetLoadBalancerListenerSSLCertificate* = Call_PostSetLoadBalancerListenerSSLCertificate_602938(
    name: "postSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_PostSetLoadBalancerListenerSSLCertificate_602939,
    base: "/", url: url_PostSetLoadBalancerListenerSSLCertificate_602940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerListenerSSLCertificate_602920 = ref object of OpenApiRestCall_601389
proc url_GetSetLoadBalancerListenerSSLCertificate_602922(protocol: Scheme;
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

proc validate_GetSetLoadBalancerListenerSSLCertificate_602921(path: JsonNode;
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
  var valid_602923 = query.getOrDefault("LoadBalancerPort")
  valid_602923 = validateParameter(valid_602923, JInt, required = true, default = nil)
  if valid_602923 != nil:
    section.add "LoadBalancerPort", valid_602923
  var valid_602924 = query.getOrDefault("LoadBalancerName")
  valid_602924 = validateParameter(valid_602924, JString, required = true,
                                 default = nil)
  if valid_602924 != nil:
    section.add "LoadBalancerName", valid_602924
  var valid_602925 = query.getOrDefault("Action")
  valid_602925 = validateParameter(valid_602925, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_602925 != nil:
    section.add "Action", valid_602925
  var valid_602926 = query.getOrDefault("Version")
  valid_602926 = validateParameter(valid_602926, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602926 != nil:
    section.add "Version", valid_602926
  var valid_602927 = query.getOrDefault("SSLCertificateId")
  valid_602927 = validateParameter(valid_602927, JString, required = true,
                                 default = nil)
  if valid_602927 != nil:
    section.add "SSLCertificateId", valid_602927
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
  var valid_602928 = header.getOrDefault("X-Amz-Signature")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Signature", valid_602928
  var valid_602929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "X-Amz-Content-Sha256", valid_602929
  var valid_602930 = header.getOrDefault("X-Amz-Date")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Date", valid_602930
  var valid_602931 = header.getOrDefault("X-Amz-Credential")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "X-Amz-Credential", valid_602931
  var valid_602932 = header.getOrDefault("X-Amz-Security-Token")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Security-Token", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Algorithm")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Algorithm", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-SignedHeaders", valid_602934
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602935: Call_GetSetLoadBalancerListenerSSLCertificate_602920;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602935.validator(path, query, header, formData, body)
  let scheme = call_602935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602935.url(scheme.get, call_602935.host, call_602935.base,
                         call_602935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602935, url, valid)

proc call*(call_602936: Call_GetSetLoadBalancerListenerSSLCertificate_602920;
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
  var query_602937 = newJObject()
  add(query_602937, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_602937, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602937, "Action", newJString(Action))
  add(query_602937, "Version", newJString(Version))
  add(query_602937, "SSLCertificateId", newJString(SSLCertificateId))
  result = call_602936.call(nil, query_602937, nil, nil, nil)

var getSetLoadBalancerListenerSSLCertificate* = Call_GetSetLoadBalancerListenerSSLCertificate_602920(
    name: "getSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_GetSetLoadBalancerListenerSSLCertificate_602921,
    base: "/", url: url_GetSetLoadBalancerListenerSSLCertificate_602922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesForBackendServer_602975 = ref object of OpenApiRestCall_601389
proc url_PostSetLoadBalancerPoliciesForBackendServer_602977(protocol: Scheme;
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

proc validate_PostSetLoadBalancerPoliciesForBackendServer_602976(path: JsonNode;
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
  var valid_602978 = query.getOrDefault("Action")
  valid_602978 = validateParameter(valid_602978, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_602978 != nil:
    section.add "Action", valid_602978
  var valid_602979 = query.getOrDefault("Version")
  valid_602979 = validateParameter(valid_602979, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602979 != nil:
    section.add "Version", valid_602979
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
  var valid_602980 = header.getOrDefault("X-Amz-Signature")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "X-Amz-Signature", valid_602980
  var valid_602981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602981 = validateParameter(valid_602981, JString, required = false,
                                 default = nil)
  if valid_602981 != nil:
    section.add "X-Amz-Content-Sha256", valid_602981
  var valid_602982 = header.getOrDefault("X-Amz-Date")
  valid_602982 = validateParameter(valid_602982, JString, required = false,
                                 default = nil)
  if valid_602982 != nil:
    section.add "X-Amz-Date", valid_602982
  var valid_602983 = header.getOrDefault("X-Amz-Credential")
  valid_602983 = validateParameter(valid_602983, JString, required = false,
                                 default = nil)
  if valid_602983 != nil:
    section.add "X-Amz-Credential", valid_602983
  var valid_602984 = header.getOrDefault("X-Amz-Security-Token")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "X-Amz-Security-Token", valid_602984
  var valid_602985 = header.getOrDefault("X-Amz-Algorithm")
  valid_602985 = validateParameter(valid_602985, JString, required = false,
                                 default = nil)
  if valid_602985 != nil:
    section.add "X-Amz-Algorithm", valid_602985
  var valid_602986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602986 = validateParameter(valid_602986, JString, required = false,
                                 default = nil)
  if valid_602986 != nil:
    section.add "X-Amz-SignedHeaders", valid_602986
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
  var valid_602987 = formData.getOrDefault("PolicyNames")
  valid_602987 = validateParameter(valid_602987, JArray, required = true, default = nil)
  if valid_602987 != nil:
    section.add "PolicyNames", valid_602987
  var valid_602988 = formData.getOrDefault("LoadBalancerName")
  valid_602988 = validateParameter(valid_602988, JString, required = true,
                                 default = nil)
  if valid_602988 != nil:
    section.add "LoadBalancerName", valid_602988
  var valid_602989 = formData.getOrDefault("InstancePort")
  valid_602989 = validateParameter(valid_602989, JInt, required = true, default = nil)
  if valid_602989 != nil:
    section.add "InstancePort", valid_602989
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602990: Call_PostSetLoadBalancerPoliciesForBackendServer_602975;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602990.validator(path, query, header, formData, body)
  let scheme = call_602990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602990.url(scheme.get, call_602990.host, call_602990.base,
                         call_602990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602990, url, valid)

proc call*(call_602991: Call_PostSetLoadBalancerPoliciesForBackendServer_602975;
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
  var query_602992 = newJObject()
  var formData_602993 = newJObject()
  if PolicyNames != nil:
    formData_602993.add "PolicyNames", PolicyNames
  add(formData_602993, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602992, "Action", newJString(Action))
  add(formData_602993, "InstancePort", newJInt(InstancePort))
  add(query_602992, "Version", newJString(Version))
  result = call_602991.call(nil, query_602992, nil, formData_602993, nil)

var postSetLoadBalancerPoliciesForBackendServer* = Call_PostSetLoadBalancerPoliciesForBackendServer_602975(
    name: "postSetLoadBalancerPoliciesForBackendServer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_PostSetLoadBalancerPoliciesForBackendServer_602976,
    base: "/", url: url_PostSetLoadBalancerPoliciesForBackendServer_602977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesForBackendServer_602957 = ref object of OpenApiRestCall_601389
proc url_GetSetLoadBalancerPoliciesForBackendServer_602959(protocol: Scheme;
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

proc validate_GetSetLoadBalancerPoliciesForBackendServer_602958(path: JsonNode;
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
  var valid_602960 = query.getOrDefault("InstancePort")
  valid_602960 = validateParameter(valid_602960, JInt, required = true, default = nil)
  if valid_602960 != nil:
    section.add "InstancePort", valid_602960
  var valid_602961 = query.getOrDefault("LoadBalancerName")
  valid_602961 = validateParameter(valid_602961, JString, required = true,
                                 default = nil)
  if valid_602961 != nil:
    section.add "LoadBalancerName", valid_602961
  var valid_602962 = query.getOrDefault("Action")
  valid_602962 = validateParameter(valid_602962, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_602962 != nil:
    section.add "Action", valid_602962
  var valid_602963 = query.getOrDefault("Version")
  valid_602963 = validateParameter(valid_602963, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602963 != nil:
    section.add "Version", valid_602963
  var valid_602964 = query.getOrDefault("PolicyNames")
  valid_602964 = validateParameter(valid_602964, JArray, required = true, default = nil)
  if valid_602964 != nil:
    section.add "PolicyNames", valid_602964
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
  var valid_602965 = header.getOrDefault("X-Amz-Signature")
  valid_602965 = validateParameter(valid_602965, JString, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "X-Amz-Signature", valid_602965
  var valid_602966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602966 = validateParameter(valid_602966, JString, required = false,
                                 default = nil)
  if valid_602966 != nil:
    section.add "X-Amz-Content-Sha256", valid_602966
  var valid_602967 = header.getOrDefault("X-Amz-Date")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "X-Amz-Date", valid_602967
  var valid_602968 = header.getOrDefault("X-Amz-Credential")
  valid_602968 = validateParameter(valid_602968, JString, required = false,
                                 default = nil)
  if valid_602968 != nil:
    section.add "X-Amz-Credential", valid_602968
  var valid_602969 = header.getOrDefault("X-Amz-Security-Token")
  valid_602969 = validateParameter(valid_602969, JString, required = false,
                                 default = nil)
  if valid_602969 != nil:
    section.add "X-Amz-Security-Token", valid_602969
  var valid_602970 = header.getOrDefault("X-Amz-Algorithm")
  valid_602970 = validateParameter(valid_602970, JString, required = false,
                                 default = nil)
  if valid_602970 != nil:
    section.add "X-Amz-Algorithm", valid_602970
  var valid_602971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602971 = validateParameter(valid_602971, JString, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "X-Amz-SignedHeaders", valid_602971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602972: Call_GetSetLoadBalancerPoliciesForBackendServer_602957;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602972.validator(path, query, header, formData, body)
  let scheme = call_602972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602972.url(scheme.get, call_602972.host, call_602972.base,
                         call_602972.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602972, url, valid)

proc call*(call_602973: Call_GetSetLoadBalancerPoliciesForBackendServer_602957;
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
  var query_602974 = newJObject()
  add(query_602974, "InstancePort", newJInt(InstancePort))
  add(query_602974, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602974, "Action", newJString(Action))
  add(query_602974, "Version", newJString(Version))
  if PolicyNames != nil:
    query_602974.add "PolicyNames", PolicyNames
  result = call_602973.call(nil, query_602974, nil, nil, nil)

var getSetLoadBalancerPoliciesForBackendServer* = Call_GetSetLoadBalancerPoliciesForBackendServer_602957(
    name: "getSetLoadBalancerPoliciesForBackendServer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_GetSetLoadBalancerPoliciesForBackendServer_602958,
    base: "/", url: url_GetSetLoadBalancerPoliciesForBackendServer_602959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesOfListener_603012 = ref object of OpenApiRestCall_601389
proc url_PostSetLoadBalancerPoliciesOfListener_603014(protocol: Scheme;
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

proc validate_PostSetLoadBalancerPoliciesOfListener_603013(path: JsonNode;
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
  var valid_603015 = query.getOrDefault("Action")
  valid_603015 = validateParameter(valid_603015, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_603015 != nil:
    section.add "Action", valid_603015
  var valid_603016 = query.getOrDefault("Version")
  valid_603016 = validateParameter(valid_603016, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603016 != nil:
    section.add "Version", valid_603016
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
  var valid_603017 = header.getOrDefault("X-Amz-Signature")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "X-Amz-Signature", valid_603017
  var valid_603018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603018 = validateParameter(valid_603018, JString, required = false,
                                 default = nil)
  if valid_603018 != nil:
    section.add "X-Amz-Content-Sha256", valid_603018
  var valid_603019 = header.getOrDefault("X-Amz-Date")
  valid_603019 = validateParameter(valid_603019, JString, required = false,
                                 default = nil)
  if valid_603019 != nil:
    section.add "X-Amz-Date", valid_603019
  var valid_603020 = header.getOrDefault("X-Amz-Credential")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "X-Amz-Credential", valid_603020
  var valid_603021 = header.getOrDefault("X-Amz-Security-Token")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "X-Amz-Security-Token", valid_603021
  var valid_603022 = header.getOrDefault("X-Amz-Algorithm")
  valid_603022 = validateParameter(valid_603022, JString, required = false,
                                 default = nil)
  if valid_603022 != nil:
    section.add "X-Amz-Algorithm", valid_603022
  var valid_603023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603023 = validateParameter(valid_603023, JString, required = false,
                                 default = nil)
  if valid_603023 != nil:
    section.add "X-Amz-SignedHeaders", valid_603023
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
  var valid_603024 = formData.getOrDefault("PolicyNames")
  valid_603024 = validateParameter(valid_603024, JArray, required = true, default = nil)
  if valid_603024 != nil:
    section.add "PolicyNames", valid_603024
  var valid_603025 = formData.getOrDefault("LoadBalancerName")
  valid_603025 = validateParameter(valid_603025, JString, required = true,
                                 default = nil)
  if valid_603025 != nil:
    section.add "LoadBalancerName", valid_603025
  var valid_603026 = formData.getOrDefault("LoadBalancerPort")
  valid_603026 = validateParameter(valid_603026, JInt, required = true, default = nil)
  if valid_603026 != nil:
    section.add "LoadBalancerPort", valid_603026
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603027: Call_PostSetLoadBalancerPoliciesOfListener_603012;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603027.validator(path, query, header, formData, body)
  let scheme = call_603027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603027.url(scheme.get, call_603027.host, call_603027.base,
                         call_603027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603027, url, valid)

proc call*(call_603028: Call_PostSetLoadBalancerPoliciesOfListener_603012;
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
  var query_603029 = newJObject()
  var formData_603030 = newJObject()
  if PolicyNames != nil:
    formData_603030.add "PolicyNames", PolicyNames
  add(formData_603030, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603029, "Action", newJString(Action))
  add(query_603029, "Version", newJString(Version))
  add(formData_603030, "LoadBalancerPort", newJInt(LoadBalancerPort))
  result = call_603028.call(nil, query_603029, nil, formData_603030, nil)

var postSetLoadBalancerPoliciesOfListener* = Call_PostSetLoadBalancerPoliciesOfListener_603012(
    name: "postSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_PostSetLoadBalancerPoliciesOfListener_603013, base: "/",
    url: url_PostSetLoadBalancerPoliciesOfListener_603014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesOfListener_602994 = ref object of OpenApiRestCall_601389
proc url_GetSetLoadBalancerPoliciesOfListener_602996(protocol: Scheme;
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

proc validate_GetSetLoadBalancerPoliciesOfListener_602995(path: JsonNode;
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
  var valid_602997 = query.getOrDefault("LoadBalancerPort")
  valid_602997 = validateParameter(valid_602997, JInt, required = true, default = nil)
  if valid_602997 != nil:
    section.add "LoadBalancerPort", valid_602997
  var valid_602998 = query.getOrDefault("LoadBalancerName")
  valid_602998 = validateParameter(valid_602998, JString, required = true,
                                 default = nil)
  if valid_602998 != nil:
    section.add "LoadBalancerName", valid_602998
  var valid_602999 = query.getOrDefault("Action")
  valid_602999 = validateParameter(valid_602999, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_602999 != nil:
    section.add "Action", valid_602999
  var valid_603000 = query.getOrDefault("Version")
  valid_603000 = validateParameter(valid_603000, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603000 != nil:
    section.add "Version", valid_603000
  var valid_603001 = query.getOrDefault("PolicyNames")
  valid_603001 = validateParameter(valid_603001, JArray, required = true, default = nil)
  if valid_603001 != nil:
    section.add "PolicyNames", valid_603001
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
  var valid_603002 = header.getOrDefault("X-Amz-Signature")
  valid_603002 = validateParameter(valid_603002, JString, required = false,
                                 default = nil)
  if valid_603002 != nil:
    section.add "X-Amz-Signature", valid_603002
  var valid_603003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603003 = validateParameter(valid_603003, JString, required = false,
                                 default = nil)
  if valid_603003 != nil:
    section.add "X-Amz-Content-Sha256", valid_603003
  var valid_603004 = header.getOrDefault("X-Amz-Date")
  valid_603004 = validateParameter(valid_603004, JString, required = false,
                                 default = nil)
  if valid_603004 != nil:
    section.add "X-Amz-Date", valid_603004
  var valid_603005 = header.getOrDefault("X-Amz-Credential")
  valid_603005 = validateParameter(valid_603005, JString, required = false,
                                 default = nil)
  if valid_603005 != nil:
    section.add "X-Amz-Credential", valid_603005
  var valid_603006 = header.getOrDefault("X-Amz-Security-Token")
  valid_603006 = validateParameter(valid_603006, JString, required = false,
                                 default = nil)
  if valid_603006 != nil:
    section.add "X-Amz-Security-Token", valid_603006
  var valid_603007 = header.getOrDefault("X-Amz-Algorithm")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "X-Amz-Algorithm", valid_603007
  var valid_603008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "X-Amz-SignedHeaders", valid_603008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603009: Call_GetSetLoadBalancerPoliciesOfListener_602994;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603009.validator(path, query, header, formData, body)
  let scheme = call_603009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603009.url(scheme.get, call_603009.host, call_603009.base,
                         call_603009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603009, url, valid)

proc call*(call_603010: Call_GetSetLoadBalancerPoliciesOfListener_602994;
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
  var query_603011 = newJObject()
  add(query_603011, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_603011, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603011, "Action", newJString(Action))
  add(query_603011, "Version", newJString(Version))
  if PolicyNames != nil:
    query_603011.add "PolicyNames", PolicyNames
  result = call_603010.call(nil, query_603011, nil, nil, nil)

var getSetLoadBalancerPoliciesOfListener* = Call_GetSetLoadBalancerPoliciesOfListener_602994(
    name: "getSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_GetSetLoadBalancerPoliciesOfListener_602995, base: "/",
    url: url_GetSetLoadBalancerPoliciesOfListener_602996,
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
