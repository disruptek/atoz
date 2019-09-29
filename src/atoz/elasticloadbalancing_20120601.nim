
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
  Call_PostAddTags_594046 = ref object of OpenApiRestCall_593437
proc url_PostAddTags_594048(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTags_594047(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594049 = query.getOrDefault("Action")
  valid_594049 = validateParameter(valid_594049, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_594049 != nil:
    section.add "Action", valid_594049
  var valid_594050 = query.getOrDefault("Version")
  valid_594050 = validateParameter(valid_594050, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594050 != nil:
    section.add "Version", valid_594050
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
  var valid_594051 = header.getOrDefault("X-Amz-Date")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Date", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Security-Token")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Security-Token", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Content-Sha256", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Algorithm")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Algorithm", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Signature")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Signature", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-SignedHeaders", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Credential")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Credential", valid_594057
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_594058 = formData.getOrDefault("Tags")
  valid_594058 = validateParameter(valid_594058, JArray, required = true, default = nil)
  if valid_594058 != nil:
    section.add "Tags", valid_594058
  var valid_594059 = formData.getOrDefault("LoadBalancerNames")
  valid_594059 = validateParameter(valid_594059, JArray, required = true, default = nil)
  if valid_594059 != nil:
    section.add "LoadBalancerNames", valid_594059
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594060: Call_PostAddTags_594046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594060.validator(path, query, header, formData, body)
  let scheme = call_594060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594060.url(scheme.get, call_594060.host, call_594060.base,
                         call_594060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594060, url, valid)

proc call*(call_594061: Call_PostAddTags_594046; Tags: JsonNode;
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
  var query_594062 = newJObject()
  var formData_594063 = newJObject()
  if Tags != nil:
    formData_594063.add "Tags", Tags
  add(query_594062, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_594063.add "LoadBalancerNames", LoadBalancerNames
  add(query_594062, "Version", newJString(Version))
  result = call_594061.call(nil, query_594062, nil, formData_594063, nil)

var postAddTags* = Call_PostAddTags_594046(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_594047,
                                        base: "/", url: url_PostAddTags_594048,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_593774 = ref object of OpenApiRestCall_593437
proc url_GetAddTags_593776(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTags_593775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593888 = query.getOrDefault("Tags")
  valid_593888 = validateParameter(valid_593888, JArray, required = true, default = nil)
  if valid_593888 != nil:
    section.add "Tags", valid_593888
  var valid_593902 = query.getOrDefault("Action")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_593902 != nil:
    section.add "Action", valid_593902
  var valid_593903 = query.getOrDefault("LoadBalancerNames")
  valid_593903 = validateParameter(valid_593903, JArray, required = true, default = nil)
  if valid_593903 != nil:
    section.add "LoadBalancerNames", valid_593903
  var valid_593904 = query.getOrDefault("Version")
  valid_593904 = validateParameter(valid_593904, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_593904 != nil:
    section.add "Version", valid_593904
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
  var valid_593905 = header.getOrDefault("X-Amz-Date")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Date", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Security-Token")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Security-Token", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Content-Sha256", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Algorithm")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Algorithm", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Signature")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Signature", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-SignedHeaders", valid_593910
  var valid_593911 = header.getOrDefault("X-Amz-Credential")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "X-Amz-Credential", valid_593911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593934: Call_GetAddTags_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_593934.validator(path, query, header, formData, body)
  let scheme = call_593934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593934.url(scheme.get, call_593934.host, call_593934.base,
                         call_593934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593934, url, valid)

proc call*(call_594005: Call_GetAddTags_593774; Tags: JsonNode;
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
  var query_594006 = newJObject()
  if Tags != nil:
    query_594006.add "Tags", Tags
  add(query_594006, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_594006.add "LoadBalancerNames", LoadBalancerNames
  add(query_594006, "Version", newJString(Version))
  result = call_594005.call(nil, query_594006, nil, nil, nil)

var getAddTags* = Call_GetAddTags_593774(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_593775,
                                      base: "/", url: url_GetAddTags_593776,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplySecurityGroupsToLoadBalancer_594081 = ref object of OpenApiRestCall_593437
proc url_PostApplySecurityGroupsToLoadBalancer_594083(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostApplySecurityGroupsToLoadBalancer_594082(path: JsonNode;
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
  var valid_594084 = query.getOrDefault("Action")
  valid_594084 = validateParameter(valid_594084, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_594084 != nil:
    section.add "Action", valid_594084
  var valid_594085 = query.getOrDefault("Version")
  valid_594085 = validateParameter(valid_594085, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594085 != nil:
    section.add "Version", valid_594085
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
  var valid_594086 = header.getOrDefault("X-Amz-Date")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Date", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Security-Token")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Security-Token", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Content-Sha256", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Algorithm")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Algorithm", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Signature")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Signature", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-SignedHeaders", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Credential")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Credential", valid_594092
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_594093 = formData.getOrDefault("SecurityGroups")
  valid_594093 = validateParameter(valid_594093, JArray, required = true, default = nil)
  if valid_594093 != nil:
    section.add "SecurityGroups", valid_594093
  var valid_594094 = formData.getOrDefault("LoadBalancerName")
  valid_594094 = validateParameter(valid_594094, JString, required = true,
                                 default = nil)
  if valid_594094 != nil:
    section.add "LoadBalancerName", valid_594094
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594095: Call_PostApplySecurityGroupsToLoadBalancer_594081;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594095.validator(path, query, header, formData, body)
  let scheme = call_594095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594095.url(scheme.get, call_594095.host, call_594095.base,
                         call_594095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594095, url, valid)

proc call*(call_594096: Call_PostApplySecurityGroupsToLoadBalancer_594081;
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
  var query_594097 = newJObject()
  var formData_594098 = newJObject()
  add(query_594097, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_594098.add "SecurityGroups", SecurityGroups
  add(formData_594098, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594097, "Version", newJString(Version))
  result = call_594096.call(nil, query_594097, nil, formData_594098, nil)

var postApplySecurityGroupsToLoadBalancer* = Call_PostApplySecurityGroupsToLoadBalancer_594081(
    name: "postApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_PostApplySecurityGroupsToLoadBalancer_594082, base: "/",
    url: url_PostApplySecurityGroupsToLoadBalancer_594083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplySecurityGroupsToLoadBalancer_594064 = ref object of OpenApiRestCall_593437
proc url_GetApplySecurityGroupsToLoadBalancer_594066(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApplySecurityGroupsToLoadBalancer_594065(path: JsonNode;
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
  var valid_594067 = query.getOrDefault("LoadBalancerName")
  valid_594067 = validateParameter(valid_594067, JString, required = true,
                                 default = nil)
  if valid_594067 != nil:
    section.add "LoadBalancerName", valid_594067
  var valid_594068 = query.getOrDefault("Action")
  valid_594068 = validateParameter(valid_594068, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_594068 != nil:
    section.add "Action", valid_594068
  var valid_594069 = query.getOrDefault("Version")
  valid_594069 = validateParameter(valid_594069, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594069 != nil:
    section.add "Version", valid_594069
  var valid_594070 = query.getOrDefault("SecurityGroups")
  valid_594070 = validateParameter(valid_594070, JArray, required = true, default = nil)
  if valid_594070 != nil:
    section.add "SecurityGroups", valid_594070
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
  var valid_594071 = header.getOrDefault("X-Amz-Date")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Date", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Security-Token")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Security-Token", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Content-Sha256", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Algorithm")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Algorithm", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Signature")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Signature", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-SignedHeaders", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Credential")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Credential", valid_594077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594078: Call_GetApplySecurityGroupsToLoadBalancer_594064;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594078.validator(path, query, header, formData, body)
  let scheme = call_594078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594078.url(scheme.get, call_594078.host, call_594078.base,
                         call_594078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594078, url, valid)

proc call*(call_594079: Call_GetApplySecurityGroupsToLoadBalancer_594064;
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
  var query_594080 = newJObject()
  add(query_594080, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594080, "Action", newJString(Action))
  add(query_594080, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_594080.add "SecurityGroups", SecurityGroups
  result = call_594079.call(nil, query_594080, nil, nil, nil)

var getApplySecurityGroupsToLoadBalancer* = Call_GetApplySecurityGroupsToLoadBalancer_594064(
    name: "getApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_GetApplySecurityGroupsToLoadBalancer_594065, base: "/",
    url: url_GetApplySecurityGroupsToLoadBalancer_594066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAttachLoadBalancerToSubnets_594116 = ref object of OpenApiRestCall_593437
proc url_PostAttachLoadBalancerToSubnets_594118(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAttachLoadBalancerToSubnets_594117(path: JsonNode;
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
  var valid_594119 = query.getOrDefault("Action")
  valid_594119 = validateParameter(valid_594119, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_594119 != nil:
    section.add "Action", valid_594119
  var valid_594120 = query.getOrDefault("Version")
  valid_594120 = validateParameter(valid_594120, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594120 != nil:
    section.add "Version", valid_594120
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
  var valid_594123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Content-Sha256", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Algorithm")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Algorithm", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Signature")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Signature", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-SignedHeaders", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Credential")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Credential", valid_594127
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_594128 = formData.getOrDefault("Subnets")
  valid_594128 = validateParameter(valid_594128, JArray, required = true, default = nil)
  if valid_594128 != nil:
    section.add "Subnets", valid_594128
  var valid_594129 = formData.getOrDefault("LoadBalancerName")
  valid_594129 = validateParameter(valid_594129, JString, required = true,
                                 default = nil)
  if valid_594129 != nil:
    section.add "LoadBalancerName", valid_594129
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_PostAttachLoadBalancerToSubnets_594116;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_PostAttachLoadBalancerToSubnets_594116;
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
  var query_594132 = newJObject()
  var formData_594133 = newJObject()
  add(query_594132, "Action", newJString(Action))
  if Subnets != nil:
    formData_594133.add "Subnets", Subnets
  add(formData_594133, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594132, "Version", newJString(Version))
  result = call_594131.call(nil, query_594132, nil, formData_594133, nil)

var postAttachLoadBalancerToSubnets* = Call_PostAttachLoadBalancerToSubnets_594116(
    name: "postAttachLoadBalancerToSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_PostAttachLoadBalancerToSubnets_594117, base: "/",
    url: url_PostAttachLoadBalancerToSubnets_594118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttachLoadBalancerToSubnets_594099 = ref object of OpenApiRestCall_593437
proc url_GetAttachLoadBalancerToSubnets_594101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAttachLoadBalancerToSubnets_594100(path: JsonNode;
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
  var valid_594102 = query.getOrDefault("LoadBalancerName")
  valid_594102 = validateParameter(valid_594102, JString, required = true,
                                 default = nil)
  if valid_594102 != nil:
    section.add "LoadBalancerName", valid_594102
  var valid_594103 = query.getOrDefault("Action")
  valid_594103 = validateParameter(valid_594103, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_594103 != nil:
    section.add "Action", valid_594103
  var valid_594104 = query.getOrDefault("Subnets")
  valid_594104 = validateParameter(valid_594104, JArray, required = true, default = nil)
  if valid_594104 != nil:
    section.add "Subnets", valid_594104
  var valid_594105 = query.getOrDefault("Version")
  valid_594105 = validateParameter(valid_594105, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594105 != nil:
    section.add "Version", valid_594105
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
  var valid_594108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Content-Sha256", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Algorithm")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Algorithm", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Signature")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Signature", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-SignedHeaders", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Credential")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Credential", valid_594112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594113: Call_GetAttachLoadBalancerToSubnets_594099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594113.validator(path, query, header, formData, body)
  let scheme = call_594113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594113.url(scheme.get, call_594113.host, call_594113.base,
                         call_594113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594113, url, valid)

proc call*(call_594114: Call_GetAttachLoadBalancerToSubnets_594099;
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
  var query_594115 = newJObject()
  add(query_594115, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594115, "Action", newJString(Action))
  if Subnets != nil:
    query_594115.add "Subnets", Subnets
  add(query_594115, "Version", newJString(Version))
  result = call_594114.call(nil, query_594115, nil, nil, nil)

var getAttachLoadBalancerToSubnets* = Call_GetAttachLoadBalancerToSubnets_594099(
    name: "getAttachLoadBalancerToSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_GetAttachLoadBalancerToSubnets_594100, base: "/",
    url: url_GetAttachLoadBalancerToSubnets_594101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfigureHealthCheck_594155 = ref object of OpenApiRestCall_593437
proc url_PostConfigureHealthCheck_594157(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostConfigureHealthCheck_594156(path: JsonNode; query: JsonNode;
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
  var valid_594158 = query.getOrDefault("Action")
  valid_594158 = validateParameter(valid_594158, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_594158 != nil:
    section.add "Action", valid_594158
  var valid_594159 = query.getOrDefault("Version")
  valid_594159 = validateParameter(valid_594159, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594159 != nil:
    section.add "Version", valid_594159
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
  var valid_594160 = header.getOrDefault("X-Amz-Date")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Date", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Security-Token")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Security-Token", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Content-Sha256", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Algorithm")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Algorithm", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Signature")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Signature", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-SignedHeaders", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Credential")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Credential", valid_594166
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
  var valid_594167 = formData.getOrDefault("HealthCheck.HealthyThreshold")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_594167
  var valid_594168 = formData.getOrDefault("HealthCheck.Interval")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "HealthCheck.Interval", valid_594168
  var valid_594169 = formData.getOrDefault("HealthCheck.Timeout")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "HealthCheck.Timeout", valid_594169
  var valid_594170 = formData.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_594170
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_594171 = formData.getOrDefault("LoadBalancerName")
  valid_594171 = validateParameter(valid_594171, JString, required = true,
                                 default = nil)
  if valid_594171 != nil:
    section.add "LoadBalancerName", valid_594171
  var valid_594172 = formData.getOrDefault("HealthCheck.Target")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "HealthCheck.Target", valid_594172
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594173: Call_PostConfigureHealthCheck_594155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594173.validator(path, query, header, formData, body)
  let scheme = call_594173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594173.url(scheme.get, call_594173.host, call_594173.base,
                         call_594173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594173, url, valid)

proc call*(call_594174: Call_PostConfigureHealthCheck_594155;
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
  var query_594175 = newJObject()
  var formData_594176 = newJObject()
  add(formData_594176, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(formData_594176, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(formData_594176, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_594175, "Action", newJString(Action))
  add(formData_594176, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(formData_594176, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_594176, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_594175, "Version", newJString(Version))
  result = call_594174.call(nil, query_594175, nil, formData_594176, nil)

var postConfigureHealthCheck* = Call_PostConfigureHealthCheck_594155(
    name: "postConfigureHealthCheck", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_PostConfigureHealthCheck_594156, base: "/",
    url: url_PostConfigureHealthCheck_594157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigureHealthCheck_594134 = ref object of OpenApiRestCall_593437
proc url_GetConfigureHealthCheck_594136(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConfigureHealthCheck_594135(path: JsonNode; query: JsonNode;
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
  var valid_594137 = query.getOrDefault("HealthCheck.HealthyThreshold")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_594137
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_594138 = query.getOrDefault("LoadBalancerName")
  valid_594138 = validateParameter(valid_594138, JString, required = true,
                                 default = nil)
  if valid_594138 != nil:
    section.add "LoadBalancerName", valid_594138
  var valid_594139 = query.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_594139
  var valid_594140 = query.getOrDefault("HealthCheck.Timeout")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "HealthCheck.Timeout", valid_594140
  var valid_594141 = query.getOrDefault("HealthCheck.Target")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "HealthCheck.Target", valid_594141
  var valid_594142 = query.getOrDefault("Action")
  valid_594142 = validateParameter(valid_594142, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_594142 != nil:
    section.add "Action", valid_594142
  var valid_594143 = query.getOrDefault("HealthCheck.Interval")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "HealthCheck.Interval", valid_594143
  var valid_594144 = query.getOrDefault("Version")
  valid_594144 = validateParameter(valid_594144, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594144 != nil:
    section.add "Version", valid_594144
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
  var valid_594145 = header.getOrDefault("X-Amz-Date")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Date", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Security-Token")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Security-Token", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Content-Sha256", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Algorithm")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Algorithm", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Signature")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Signature", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-SignedHeaders", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Credential")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Credential", valid_594151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594152: Call_GetConfigureHealthCheck_594134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594152.validator(path, query, header, formData, body)
  let scheme = call_594152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594152.url(scheme.get, call_594152.host, call_594152.base,
                         call_594152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594152, url, valid)

proc call*(call_594153: Call_GetConfigureHealthCheck_594134;
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
  var query_594154 = newJObject()
  add(query_594154, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(query_594154, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594154, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(query_594154, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_594154, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_594154, "Action", newJString(Action))
  add(query_594154, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(query_594154, "Version", newJString(Version))
  result = call_594153.call(nil, query_594154, nil, nil, nil)

var getConfigureHealthCheck* = Call_GetConfigureHealthCheck_594134(
    name: "getConfigureHealthCheck", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_GetConfigureHealthCheck_594135, base: "/",
    url: url_GetConfigureHealthCheck_594136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateAppCookieStickinessPolicy_594195 = ref object of OpenApiRestCall_593437
proc url_PostCreateAppCookieStickinessPolicy_594197(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateAppCookieStickinessPolicy_594196(path: JsonNode;
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
  var valid_594198 = query.getOrDefault("Action")
  valid_594198 = validateParameter(valid_594198, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_594198 != nil:
    section.add "Action", valid_594198
  var valid_594199 = query.getOrDefault("Version")
  valid_594199 = validateParameter(valid_594199, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594199 != nil:
    section.add "Version", valid_594199
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
  var valid_594200 = header.getOrDefault("X-Amz-Date")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Date", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Security-Token")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Security-Token", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-Content-Sha256", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Algorithm")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Algorithm", valid_594203
  var valid_594204 = header.getOrDefault("X-Amz-Signature")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "X-Amz-Signature", valid_594204
  var valid_594205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-SignedHeaders", valid_594205
  var valid_594206 = header.getOrDefault("X-Amz-Credential")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Credential", valid_594206
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
  var valid_594207 = formData.getOrDefault("PolicyName")
  valid_594207 = validateParameter(valid_594207, JString, required = true,
                                 default = nil)
  if valid_594207 != nil:
    section.add "PolicyName", valid_594207
  var valid_594208 = formData.getOrDefault("CookieName")
  valid_594208 = validateParameter(valid_594208, JString, required = true,
                                 default = nil)
  if valid_594208 != nil:
    section.add "CookieName", valid_594208
  var valid_594209 = formData.getOrDefault("LoadBalancerName")
  valid_594209 = validateParameter(valid_594209, JString, required = true,
                                 default = nil)
  if valid_594209 != nil:
    section.add "LoadBalancerName", valid_594209
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594210: Call_PostCreateAppCookieStickinessPolicy_594195;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594210.validator(path, query, header, formData, body)
  let scheme = call_594210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594210.url(scheme.get, call_594210.host, call_594210.base,
                         call_594210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594210, url, valid)

proc call*(call_594211: Call_PostCreateAppCookieStickinessPolicy_594195;
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
  var query_594212 = newJObject()
  var formData_594213 = newJObject()
  add(formData_594213, "PolicyName", newJString(PolicyName))
  add(formData_594213, "CookieName", newJString(CookieName))
  add(query_594212, "Action", newJString(Action))
  add(formData_594213, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594212, "Version", newJString(Version))
  result = call_594211.call(nil, query_594212, nil, formData_594213, nil)

var postCreateAppCookieStickinessPolicy* = Call_PostCreateAppCookieStickinessPolicy_594195(
    name: "postCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_PostCreateAppCookieStickinessPolicy_594196, base: "/",
    url: url_PostCreateAppCookieStickinessPolicy_594197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateAppCookieStickinessPolicy_594177 = ref object of OpenApiRestCall_593437
proc url_GetCreateAppCookieStickinessPolicy_594179(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateAppCookieStickinessPolicy_594178(path: JsonNode;
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
  var valid_594180 = query.getOrDefault("LoadBalancerName")
  valid_594180 = validateParameter(valid_594180, JString, required = true,
                                 default = nil)
  if valid_594180 != nil:
    section.add "LoadBalancerName", valid_594180
  var valid_594181 = query.getOrDefault("Action")
  valid_594181 = validateParameter(valid_594181, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_594181 != nil:
    section.add "Action", valid_594181
  var valid_594182 = query.getOrDefault("CookieName")
  valid_594182 = validateParameter(valid_594182, JString, required = true,
                                 default = nil)
  if valid_594182 != nil:
    section.add "CookieName", valid_594182
  var valid_594183 = query.getOrDefault("Version")
  valid_594183 = validateParameter(valid_594183, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594183 != nil:
    section.add "Version", valid_594183
  var valid_594184 = query.getOrDefault("PolicyName")
  valid_594184 = validateParameter(valid_594184, JString, required = true,
                                 default = nil)
  if valid_594184 != nil:
    section.add "PolicyName", valid_594184
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
  var valid_594185 = header.getOrDefault("X-Amz-Date")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Date", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Security-Token")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Security-Token", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-Content-Sha256", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Algorithm")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Algorithm", valid_594188
  var valid_594189 = header.getOrDefault("X-Amz-Signature")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "X-Amz-Signature", valid_594189
  var valid_594190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-SignedHeaders", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Credential")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Credential", valid_594191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594192: Call_GetCreateAppCookieStickinessPolicy_594177;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594192.validator(path, query, header, formData, body)
  let scheme = call_594192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594192.url(scheme.get, call_594192.host, call_594192.base,
                         call_594192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594192, url, valid)

proc call*(call_594193: Call_GetCreateAppCookieStickinessPolicy_594177;
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
  var query_594194 = newJObject()
  add(query_594194, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594194, "Action", newJString(Action))
  add(query_594194, "CookieName", newJString(CookieName))
  add(query_594194, "Version", newJString(Version))
  add(query_594194, "PolicyName", newJString(PolicyName))
  result = call_594193.call(nil, query_594194, nil, nil, nil)

var getCreateAppCookieStickinessPolicy* = Call_GetCreateAppCookieStickinessPolicy_594177(
    name: "getCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_GetCreateAppCookieStickinessPolicy_594178, base: "/",
    url: url_GetCreateAppCookieStickinessPolicy_594179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLBCookieStickinessPolicy_594232 = ref object of OpenApiRestCall_593437
proc url_PostCreateLBCookieStickinessPolicy_594234(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLBCookieStickinessPolicy_594233(path: JsonNode;
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
  var valid_594235 = query.getOrDefault("Action")
  valid_594235 = validateParameter(valid_594235, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_594235 != nil:
    section.add "Action", valid_594235
  var valid_594236 = query.getOrDefault("Version")
  valid_594236 = validateParameter(valid_594236, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594236 != nil:
    section.add "Version", valid_594236
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
  var valid_594237 = header.getOrDefault("X-Amz-Date")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Date", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Security-Token")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Security-Token", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Content-Sha256", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Algorithm")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Algorithm", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Signature")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Signature", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-SignedHeaders", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Credential")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Credential", valid_594243
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
  var valid_594244 = formData.getOrDefault("PolicyName")
  valid_594244 = validateParameter(valid_594244, JString, required = true,
                                 default = nil)
  if valid_594244 != nil:
    section.add "PolicyName", valid_594244
  var valid_594245 = formData.getOrDefault("LoadBalancerName")
  valid_594245 = validateParameter(valid_594245, JString, required = true,
                                 default = nil)
  if valid_594245 != nil:
    section.add "LoadBalancerName", valid_594245
  var valid_594246 = formData.getOrDefault("CookieExpirationPeriod")
  valid_594246 = validateParameter(valid_594246, JInt, required = false, default = nil)
  if valid_594246 != nil:
    section.add "CookieExpirationPeriod", valid_594246
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594247: Call_PostCreateLBCookieStickinessPolicy_594232;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594247.validator(path, query, header, formData, body)
  let scheme = call_594247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594247.url(scheme.get, call_594247.host, call_594247.base,
                         call_594247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594247, url, valid)

proc call*(call_594248: Call_PostCreateLBCookieStickinessPolicy_594232;
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
  var query_594249 = newJObject()
  var formData_594250 = newJObject()
  add(formData_594250, "PolicyName", newJString(PolicyName))
  add(query_594249, "Action", newJString(Action))
  add(formData_594250, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594249, "Version", newJString(Version))
  add(formData_594250, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  result = call_594248.call(nil, query_594249, nil, formData_594250, nil)

var postCreateLBCookieStickinessPolicy* = Call_PostCreateLBCookieStickinessPolicy_594232(
    name: "postCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_PostCreateLBCookieStickinessPolicy_594233, base: "/",
    url: url_PostCreateLBCookieStickinessPolicy_594234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLBCookieStickinessPolicy_594214 = ref object of OpenApiRestCall_593437
proc url_GetCreateLBCookieStickinessPolicy_594216(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLBCookieStickinessPolicy_594215(path: JsonNode;
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
  var valid_594217 = query.getOrDefault("CookieExpirationPeriod")
  valid_594217 = validateParameter(valid_594217, JInt, required = false, default = nil)
  if valid_594217 != nil:
    section.add "CookieExpirationPeriod", valid_594217
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_594218 = query.getOrDefault("LoadBalancerName")
  valid_594218 = validateParameter(valid_594218, JString, required = true,
                                 default = nil)
  if valid_594218 != nil:
    section.add "LoadBalancerName", valid_594218
  var valid_594219 = query.getOrDefault("Action")
  valid_594219 = validateParameter(valid_594219, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_594219 != nil:
    section.add "Action", valid_594219
  var valid_594220 = query.getOrDefault("Version")
  valid_594220 = validateParameter(valid_594220, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594220 != nil:
    section.add "Version", valid_594220
  var valid_594221 = query.getOrDefault("PolicyName")
  valid_594221 = validateParameter(valid_594221, JString, required = true,
                                 default = nil)
  if valid_594221 != nil:
    section.add "PolicyName", valid_594221
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
  var valid_594222 = header.getOrDefault("X-Amz-Date")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-Date", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Security-Token")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Security-Token", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Content-Sha256", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Algorithm")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Algorithm", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Signature")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Signature", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-SignedHeaders", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Credential")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Credential", valid_594228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594229: Call_GetCreateLBCookieStickinessPolicy_594214;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594229.validator(path, query, header, formData, body)
  let scheme = call_594229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594229.url(scheme.get, call_594229.host, call_594229.base,
                         call_594229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594229, url, valid)

proc call*(call_594230: Call_GetCreateLBCookieStickinessPolicy_594214;
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
  var query_594231 = newJObject()
  add(query_594231, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(query_594231, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594231, "Action", newJString(Action))
  add(query_594231, "Version", newJString(Version))
  add(query_594231, "PolicyName", newJString(PolicyName))
  result = call_594230.call(nil, query_594231, nil, nil, nil)

var getCreateLBCookieStickinessPolicy* = Call_GetCreateLBCookieStickinessPolicy_594214(
    name: "getCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_GetCreateLBCookieStickinessPolicy_594215, base: "/",
    url: url_GetCreateLBCookieStickinessPolicy_594216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_594273 = ref object of OpenApiRestCall_593437
proc url_PostCreateLoadBalancer_594275(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLoadBalancer_594274(path: JsonNode; query: JsonNode;
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
  var valid_594276 = query.getOrDefault("Action")
  valid_594276 = validateParameter(valid_594276, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_594276 != nil:
    section.add "Action", valid_594276
  var valid_594277 = query.getOrDefault("Version")
  valid_594277 = validateParameter(valid_594277, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594277 != nil:
    section.add "Version", valid_594277
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
  var valid_594278 = header.getOrDefault("X-Amz-Date")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Date", valid_594278
  var valid_594279 = header.getOrDefault("X-Amz-Security-Token")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "X-Amz-Security-Token", valid_594279
  var valid_594280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "X-Amz-Content-Sha256", valid_594280
  var valid_594281 = header.getOrDefault("X-Amz-Algorithm")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Algorithm", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-Signature")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-Signature", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-SignedHeaders", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-Credential")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-Credential", valid_594284
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
  var valid_594285 = formData.getOrDefault("Tags")
  valid_594285 = validateParameter(valid_594285, JArray, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "Tags", valid_594285
  var valid_594286 = formData.getOrDefault("AvailabilityZones")
  valid_594286 = validateParameter(valid_594286, JArray, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "AvailabilityZones", valid_594286
  var valid_594287 = formData.getOrDefault("Subnets")
  valid_594287 = validateParameter(valid_594287, JArray, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "Subnets", valid_594287
  var valid_594288 = formData.getOrDefault("SecurityGroups")
  valid_594288 = validateParameter(valid_594288, JArray, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "SecurityGroups", valid_594288
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_594289 = formData.getOrDefault("LoadBalancerName")
  valid_594289 = validateParameter(valid_594289, JString, required = true,
                                 default = nil)
  if valid_594289 != nil:
    section.add "LoadBalancerName", valid_594289
  var valid_594290 = formData.getOrDefault("Scheme")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "Scheme", valid_594290
  var valid_594291 = formData.getOrDefault("Listeners")
  valid_594291 = validateParameter(valid_594291, JArray, required = true, default = nil)
  if valid_594291 != nil:
    section.add "Listeners", valid_594291
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594292: Call_PostCreateLoadBalancer_594273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594292.validator(path, query, header, formData, body)
  let scheme = call_594292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594292.url(scheme.get, call_594292.host, call_594292.base,
                         call_594292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594292, url, valid)

proc call*(call_594293: Call_PostCreateLoadBalancer_594273;
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
  var query_594294 = newJObject()
  var formData_594295 = newJObject()
  if Tags != nil:
    formData_594295.add "Tags", Tags
  add(query_594294, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_594295.add "AvailabilityZones", AvailabilityZones
  if Subnets != nil:
    formData_594295.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_594295.add "SecurityGroups", SecurityGroups
  add(formData_594295, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_594295, "Scheme", newJString(Scheme))
  if Listeners != nil:
    formData_594295.add "Listeners", Listeners
  add(query_594294, "Version", newJString(Version))
  result = call_594293.call(nil, query_594294, nil, formData_594295, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_594273(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_594274, base: "/",
    url: url_PostCreateLoadBalancer_594275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_594251 = ref object of OpenApiRestCall_593437
proc url_GetCreateLoadBalancer_594253(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLoadBalancer_594252(path: JsonNode; query: JsonNode;
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
  var valid_594254 = query.getOrDefault("LoadBalancerName")
  valid_594254 = validateParameter(valid_594254, JString, required = true,
                                 default = nil)
  if valid_594254 != nil:
    section.add "LoadBalancerName", valid_594254
  var valid_594255 = query.getOrDefault("AvailabilityZones")
  valid_594255 = validateParameter(valid_594255, JArray, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "AvailabilityZones", valid_594255
  var valid_594256 = query.getOrDefault("Scheme")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "Scheme", valid_594256
  var valid_594257 = query.getOrDefault("Tags")
  valid_594257 = validateParameter(valid_594257, JArray, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "Tags", valid_594257
  var valid_594258 = query.getOrDefault("Action")
  valid_594258 = validateParameter(valid_594258, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_594258 != nil:
    section.add "Action", valid_594258
  var valid_594259 = query.getOrDefault("Subnets")
  valid_594259 = validateParameter(valid_594259, JArray, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "Subnets", valid_594259
  var valid_594260 = query.getOrDefault("Version")
  valid_594260 = validateParameter(valid_594260, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594260 != nil:
    section.add "Version", valid_594260
  var valid_594261 = query.getOrDefault("Listeners")
  valid_594261 = validateParameter(valid_594261, JArray, required = true, default = nil)
  if valid_594261 != nil:
    section.add "Listeners", valid_594261
  var valid_594262 = query.getOrDefault("SecurityGroups")
  valid_594262 = validateParameter(valid_594262, JArray, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "SecurityGroups", valid_594262
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
  var valid_594263 = header.getOrDefault("X-Amz-Date")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Date", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Security-Token")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Security-Token", valid_594264
  var valid_594265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Content-Sha256", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Algorithm")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Algorithm", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Signature")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Signature", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-SignedHeaders", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Credential")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Credential", valid_594269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594270: Call_GetCreateLoadBalancer_594251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594270.validator(path, query, header, formData, body)
  let scheme = call_594270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594270.url(scheme.get, call_594270.host, call_594270.base,
                         call_594270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594270, url, valid)

proc call*(call_594271: Call_GetCreateLoadBalancer_594251;
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
  var query_594272 = newJObject()
  add(query_594272, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_594272.add "AvailabilityZones", AvailabilityZones
  add(query_594272, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_594272.add "Tags", Tags
  add(query_594272, "Action", newJString(Action))
  if Subnets != nil:
    query_594272.add "Subnets", Subnets
  add(query_594272, "Version", newJString(Version))
  if Listeners != nil:
    query_594272.add "Listeners", Listeners
  if SecurityGroups != nil:
    query_594272.add "SecurityGroups", SecurityGroups
  result = call_594271.call(nil, query_594272, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_594251(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_594252, base: "/",
    url: url_GetCreateLoadBalancer_594253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerListeners_594313 = ref object of OpenApiRestCall_593437
proc url_PostCreateLoadBalancerListeners_594315(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLoadBalancerListeners_594314(path: JsonNode;
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
  var valid_594316 = query.getOrDefault("Action")
  valid_594316 = validateParameter(valid_594316, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_594316 != nil:
    section.add "Action", valid_594316
  var valid_594317 = query.getOrDefault("Version")
  valid_594317 = validateParameter(valid_594317, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594317 != nil:
    section.add "Version", valid_594317
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
  var valid_594318 = header.getOrDefault("X-Amz-Date")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Date", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Security-Token")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Security-Token", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Content-Sha256", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Algorithm")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Algorithm", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-Signature")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-Signature", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-SignedHeaders", valid_594323
  var valid_594324 = header.getOrDefault("X-Amz-Credential")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-Credential", valid_594324
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_594325 = formData.getOrDefault("LoadBalancerName")
  valid_594325 = validateParameter(valid_594325, JString, required = true,
                                 default = nil)
  if valid_594325 != nil:
    section.add "LoadBalancerName", valid_594325
  var valid_594326 = formData.getOrDefault("Listeners")
  valid_594326 = validateParameter(valid_594326, JArray, required = true, default = nil)
  if valid_594326 != nil:
    section.add "Listeners", valid_594326
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594327: Call_PostCreateLoadBalancerListeners_594313;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594327.validator(path, query, header, formData, body)
  let scheme = call_594327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594327.url(scheme.get, call_594327.host, call_594327.base,
                         call_594327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594327, url, valid)

proc call*(call_594328: Call_PostCreateLoadBalancerListeners_594313;
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
  var query_594329 = newJObject()
  var formData_594330 = newJObject()
  add(query_594329, "Action", newJString(Action))
  add(formData_594330, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_594330.add "Listeners", Listeners
  add(query_594329, "Version", newJString(Version))
  result = call_594328.call(nil, query_594329, nil, formData_594330, nil)

var postCreateLoadBalancerListeners* = Call_PostCreateLoadBalancerListeners_594313(
    name: "postCreateLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_PostCreateLoadBalancerListeners_594314, base: "/",
    url: url_PostCreateLoadBalancerListeners_594315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerListeners_594296 = ref object of OpenApiRestCall_593437
proc url_GetCreateLoadBalancerListeners_594298(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLoadBalancerListeners_594297(path: JsonNode;
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
  var valid_594299 = query.getOrDefault("LoadBalancerName")
  valid_594299 = validateParameter(valid_594299, JString, required = true,
                                 default = nil)
  if valid_594299 != nil:
    section.add "LoadBalancerName", valid_594299
  var valid_594300 = query.getOrDefault("Action")
  valid_594300 = validateParameter(valid_594300, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_594300 != nil:
    section.add "Action", valid_594300
  var valid_594301 = query.getOrDefault("Version")
  valid_594301 = validateParameter(valid_594301, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594301 != nil:
    section.add "Version", valid_594301
  var valid_594302 = query.getOrDefault("Listeners")
  valid_594302 = validateParameter(valid_594302, JArray, required = true, default = nil)
  if valid_594302 != nil:
    section.add "Listeners", valid_594302
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
  var valid_594303 = header.getOrDefault("X-Amz-Date")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Date", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Security-Token")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Security-Token", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Content-Sha256", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Algorithm")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Algorithm", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Signature")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Signature", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-SignedHeaders", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Credential")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Credential", valid_594309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594310: Call_GetCreateLoadBalancerListeners_594296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594310.validator(path, query, header, formData, body)
  let scheme = call_594310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594310.url(scheme.get, call_594310.host, call_594310.base,
                         call_594310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594310, url, valid)

proc call*(call_594311: Call_GetCreateLoadBalancerListeners_594296;
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
  var query_594312 = newJObject()
  add(query_594312, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594312, "Action", newJString(Action))
  add(query_594312, "Version", newJString(Version))
  if Listeners != nil:
    query_594312.add "Listeners", Listeners
  result = call_594311.call(nil, query_594312, nil, nil, nil)

var getCreateLoadBalancerListeners* = Call_GetCreateLoadBalancerListeners_594296(
    name: "getCreateLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_GetCreateLoadBalancerListeners_594297, base: "/",
    url: url_GetCreateLoadBalancerListeners_594298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerPolicy_594350 = ref object of OpenApiRestCall_593437
proc url_PostCreateLoadBalancerPolicy_594352(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLoadBalancerPolicy_594351(path: JsonNode; query: JsonNode;
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
  var valid_594353 = query.getOrDefault("Action")
  valid_594353 = validateParameter(valid_594353, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_594353 != nil:
    section.add "Action", valid_594353
  var valid_594354 = query.getOrDefault("Version")
  valid_594354 = validateParameter(valid_594354, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594354 != nil:
    section.add "Version", valid_594354
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
  var valid_594355 = header.getOrDefault("X-Amz-Date")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Date", valid_594355
  var valid_594356 = header.getOrDefault("X-Amz-Security-Token")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "X-Amz-Security-Token", valid_594356
  var valid_594357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "X-Amz-Content-Sha256", valid_594357
  var valid_594358 = header.getOrDefault("X-Amz-Algorithm")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-Algorithm", valid_594358
  var valid_594359 = header.getOrDefault("X-Amz-Signature")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Signature", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-SignedHeaders", valid_594360
  var valid_594361 = header.getOrDefault("X-Amz-Credential")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Credential", valid_594361
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
  var valid_594362 = formData.getOrDefault("PolicyName")
  valid_594362 = validateParameter(valid_594362, JString, required = true,
                                 default = nil)
  if valid_594362 != nil:
    section.add "PolicyName", valid_594362
  var valid_594363 = formData.getOrDefault("PolicyTypeName")
  valid_594363 = validateParameter(valid_594363, JString, required = true,
                                 default = nil)
  if valid_594363 != nil:
    section.add "PolicyTypeName", valid_594363
  var valid_594364 = formData.getOrDefault("PolicyAttributes")
  valid_594364 = validateParameter(valid_594364, JArray, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "PolicyAttributes", valid_594364
  var valid_594365 = formData.getOrDefault("LoadBalancerName")
  valid_594365 = validateParameter(valid_594365, JString, required = true,
                                 default = nil)
  if valid_594365 != nil:
    section.add "LoadBalancerName", valid_594365
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594366: Call_PostCreateLoadBalancerPolicy_594350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_594366.validator(path, query, header, formData, body)
  let scheme = call_594366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594366.url(scheme.get, call_594366.host, call_594366.base,
                         call_594366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594366, url, valid)

proc call*(call_594367: Call_PostCreateLoadBalancerPolicy_594350;
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
  var query_594368 = newJObject()
  var formData_594369 = newJObject()
  add(formData_594369, "PolicyName", newJString(PolicyName))
  add(formData_594369, "PolicyTypeName", newJString(PolicyTypeName))
  if PolicyAttributes != nil:
    formData_594369.add "PolicyAttributes", PolicyAttributes
  add(query_594368, "Action", newJString(Action))
  add(formData_594369, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594368, "Version", newJString(Version))
  result = call_594367.call(nil, query_594368, nil, formData_594369, nil)

var postCreateLoadBalancerPolicy* = Call_PostCreateLoadBalancerPolicy_594350(
    name: "postCreateLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_PostCreateLoadBalancerPolicy_594351, base: "/",
    url: url_PostCreateLoadBalancerPolicy_594352,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerPolicy_594331 = ref object of OpenApiRestCall_593437
proc url_GetCreateLoadBalancerPolicy_594333(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLoadBalancerPolicy_594332(path: JsonNode; query: JsonNode;
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
  var valid_594334 = query.getOrDefault("LoadBalancerName")
  valid_594334 = validateParameter(valid_594334, JString, required = true,
                                 default = nil)
  if valid_594334 != nil:
    section.add "LoadBalancerName", valid_594334
  var valid_594335 = query.getOrDefault("PolicyAttributes")
  valid_594335 = validateParameter(valid_594335, JArray, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "PolicyAttributes", valid_594335
  var valid_594336 = query.getOrDefault("Action")
  valid_594336 = validateParameter(valid_594336, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_594336 != nil:
    section.add "Action", valid_594336
  var valid_594337 = query.getOrDefault("PolicyTypeName")
  valid_594337 = validateParameter(valid_594337, JString, required = true,
                                 default = nil)
  if valid_594337 != nil:
    section.add "PolicyTypeName", valid_594337
  var valid_594338 = query.getOrDefault("Version")
  valid_594338 = validateParameter(valid_594338, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594338 != nil:
    section.add "Version", valid_594338
  var valid_594339 = query.getOrDefault("PolicyName")
  valid_594339 = validateParameter(valid_594339, JString, required = true,
                                 default = nil)
  if valid_594339 != nil:
    section.add "PolicyName", valid_594339
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
  var valid_594340 = header.getOrDefault("X-Amz-Date")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-Date", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Security-Token")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Security-Token", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Content-Sha256", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-Algorithm")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Algorithm", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Signature")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Signature", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-SignedHeaders", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Credential")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Credential", valid_594346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594347: Call_GetCreateLoadBalancerPolicy_594331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_594347.validator(path, query, header, formData, body)
  let scheme = call_594347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594347.url(scheme.get, call_594347.host, call_594347.base,
                         call_594347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594347, url, valid)

proc call*(call_594348: Call_GetCreateLoadBalancerPolicy_594331;
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
  var query_594349 = newJObject()
  add(query_594349, "LoadBalancerName", newJString(LoadBalancerName))
  if PolicyAttributes != nil:
    query_594349.add "PolicyAttributes", PolicyAttributes
  add(query_594349, "Action", newJString(Action))
  add(query_594349, "PolicyTypeName", newJString(PolicyTypeName))
  add(query_594349, "Version", newJString(Version))
  add(query_594349, "PolicyName", newJString(PolicyName))
  result = call_594348.call(nil, query_594349, nil, nil, nil)

var getCreateLoadBalancerPolicy* = Call_GetCreateLoadBalancerPolicy_594331(
    name: "getCreateLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_GetCreateLoadBalancerPolicy_594332, base: "/",
    url: url_GetCreateLoadBalancerPolicy_594333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_594386 = ref object of OpenApiRestCall_593437
proc url_PostDeleteLoadBalancer_594388(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteLoadBalancer_594387(path: JsonNode; query: JsonNode;
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
  var valid_594389 = query.getOrDefault("Action")
  valid_594389 = validateParameter(valid_594389, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_594389 != nil:
    section.add "Action", valid_594389
  var valid_594390 = query.getOrDefault("Version")
  valid_594390 = validateParameter(valid_594390, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594390 != nil:
    section.add "Version", valid_594390
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
  var valid_594391 = header.getOrDefault("X-Amz-Date")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Date", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Security-Token")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Security-Token", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Content-Sha256", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Algorithm")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Algorithm", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Signature")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Signature", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-SignedHeaders", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Credential")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Credential", valid_594397
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_594398 = formData.getOrDefault("LoadBalancerName")
  valid_594398 = validateParameter(valid_594398, JString, required = true,
                                 default = nil)
  if valid_594398 != nil:
    section.add "LoadBalancerName", valid_594398
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594399: Call_PostDeleteLoadBalancer_594386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_594399.validator(path, query, header, formData, body)
  let scheme = call_594399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594399.url(scheme.get, call_594399.host, call_594399.base,
                         call_594399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594399, url, valid)

proc call*(call_594400: Call_PostDeleteLoadBalancer_594386;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_594401 = newJObject()
  var formData_594402 = newJObject()
  add(query_594401, "Action", newJString(Action))
  add(formData_594402, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594401, "Version", newJString(Version))
  result = call_594400.call(nil, query_594401, nil, formData_594402, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_594386(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_594387, base: "/",
    url: url_PostDeleteLoadBalancer_594388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_594370 = ref object of OpenApiRestCall_593437
proc url_GetDeleteLoadBalancer_594372(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteLoadBalancer_594371(path: JsonNode; query: JsonNode;
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
  var valid_594373 = query.getOrDefault("LoadBalancerName")
  valid_594373 = validateParameter(valid_594373, JString, required = true,
                                 default = nil)
  if valid_594373 != nil:
    section.add "LoadBalancerName", valid_594373
  var valid_594374 = query.getOrDefault("Action")
  valid_594374 = validateParameter(valid_594374, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_594374 != nil:
    section.add "Action", valid_594374
  var valid_594375 = query.getOrDefault("Version")
  valid_594375 = validateParameter(valid_594375, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594375 != nil:
    section.add "Version", valid_594375
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
  var valid_594376 = header.getOrDefault("X-Amz-Date")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "X-Amz-Date", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Security-Token")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Security-Token", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Content-Sha256", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Algorithm")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Algorithm", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Signature")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Signature", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-SignedHeaders", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Credential")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Credential", valid_594382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594383: Call_GetDeleteLoadBalancer_594370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_594383.validator(path, query, header, formData, body)
  let scheme = call_594383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594383.url(scheme.get, call_594383.host, call_594383.base,
                         call_594383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594383, url, valid)

proc call*(call_594384: Call_GetDeleteLoadBalancer_594370;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594385 = newJObject()
  add(query_594385, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594385, "Action", newJString(Action))
  add(query_594385, "Version", newJString(Version))
  result = call_594384.call(nil, query_594385, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_594370(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_594371, base: "/",
    url: url_GetDeleteLoadBalancer_594372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerListeners_594420 = ref object of OpenApiRestCall_593437
proc url_PostDeleteLoadBalancerListeners_594422(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteLoadBalancerListeners_594421(path: JsonNode;
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
  var valid_594423 = query.getOrDefault("Action")
  valid_594423 = validateParameter(valid_594423, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_594423 != nil:
    section.add "Action", valid_594423
  var valid_594424 = query.getOrDefault("Version")
  valid_594424 = validateParameter(valid_594424, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594424 != nil:
    section.add "Version", valid_594424
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
  var valid_594425 = header.getOrDefault("X-Amz-Date")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Date", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Security-Token")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Security-Token", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Content-Sha256", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Algorithm")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Algorithm", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Signature")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Signature", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-SignedHeaders", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-Credential")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Credential", valid_594431
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_594432 = formData.getOrDefault("LoadBalancerName")
  valid_594432 = validateParameter(valid_594432, JString, required = true,
                                 default = nil)
  if valid_594432 != nil:
    section.add "LoadBalancerName", valid_594432
  var valid_594433 = formData.getOrDefault("LoadBalancerPorts")
  valid_594433 = validateParameter(valid_594433, JArray, required = true, default = nil)
  if valid_594433 != nil:
    section.add "LoadBalancerPorts", valid_594433
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594434: Call_PostDeleteLoadBalancerListeners_594420;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_594434.validator(path, query, header, formData, body)
  let scheme = call_594434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594434.url(scheme.get, call_594434.host, call_594434.base,
                         call_594434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594434, url, valid)

proc call*(call_594435: Call_PostDeleteLoadBalancerListeners_594420;
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
  var query_594436 = newJObject()
  var formData_594437 = newJObject()
  add(query_594436, "Action", newJString(Action))
  add(formData_594437, "LoadBalancerName", newJString(LoadBalancerName))
  if LoadBalancerPorts != nil:
    formData_594437.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_594436, "Version", newJString(Version))
  result = call_594435.call(nil, query_594436, nil, formData_594437, nil)

var postDeleteLoadBalancerListeners* = Call_PostDeleteLoadBalancerListeners_594420(
    name: "postDeleteLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_PostDeleteLoadBalancerListeners_594421, base: "/",
    url: url_PostDeleteLoadBalancerListeners_594422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerListeners_594403 = ref object of OpenApiRestCall_593437
proc url_GetDeleteLoadBalancerListeners_594405(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteLoadBalancerListeners_594404(path: JsonNode;
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
  var valid_594406 = query.getOrDefault("LoadBalancerName")
  valid_594406 = validateParameter(valid_594406, JString, required = true,
                                 default = nil)
  if valid_594406 != nil:
    section.add "LoadBalancerName", valid_594406
  var valid_594407 = query.getOrDefault("Action")
  valid_594407 = validateParameter(valid_594407, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_594407 != nil:
    section.add "Action", valid_594407
  var valid_594408 = query.getOrDefault("LoadBalancerPorts")
  valid_594408 = validateParameter(valid_594408, JArray, required = true, default = nil)
  if valid_594408 != nil:
    section.add "LoadBalancerPorts", valid_594408
  var valid_594409 = query.getOrDefault("Version")
  valid_594409 = validateParameter(valid_594409, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594409 != nil:
    section.add "Version", valid_594409
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
  var valid_594410 = header.getOrDefault("X-Amz-Date")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Date", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Security-Token")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Security-Token", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Content-Sha256", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Algorithm")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Algorithm", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Signature")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Signature", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-SignedHeaders", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-Credential")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-Credential", valid_594416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594417: Call_GetDeleteLoadBalancerListeners_594403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_594417.validator(path, query, header, formData, body)
  let scheme = call_594417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594417.url(scheme.get, call_594417.host, call_594417.base,
                         call_594417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594417, url, valid)

proc call*(call_594418: Call_GetDeleteLoadBalancerListeners_594403;
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
  var query_594419 = newJObject()
  add(query_594419, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594419, "Action", newJString(Action))
  if LoadBalancerPorts != nil:
    query_594419.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_594419, "Version", newJString(Version))
  result = call_594418.call(nil, query_594419, nil, nil, nil)

var getDeleteLoadBalancerListeners* = Call_GetDeleteLoadBalancerListeners_594403(
    name: "getDeleteLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_GetDeleteLoadBalancerListeners_594404, base: "/",
    url: url_GetDeleteLoadBalancerListeners_594405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerPolicy_594455 = ref object of OpenApiRestCall_593437
proc url_PostDeleteLoadBalancerPolicy_594457(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteLoadBalancerPolicy_594456(path: JsonNode; query: JsonNode;
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
  var valid_594458 = query.getOrDefault("Action")
  valid_594458 = validateParameter(valid_594458, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_594458 != nil:
    section.add "Action", valid_594458
  var valid_594459 = query.getOrDefault("Version")
  valid_594459 = validateParameter(valid_594459, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594459 != nil:
    section.add "Version", valid_594459
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
  var valid_594460 = header.getOrDefault("X-Amz-Date")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Date", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-Security-Token")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-Security-Token", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-Content-Sha256", valid_594462
  var valid_594463 = header.getOrDefault("X-Amz-Algorithm")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-Algorithm", valid_594463
  var valid_594464 = header.getOrDefault("X-Amz-Signature")
  valid_594464 = validateParameter(valid_594464, JString, required = false,
                                 default = nil)
  if valid_594464 != nil:
    section.add "X-Amz-Signature", valid_594464
  var valid_594465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "X-Amz-SignedHeaders", valid_594465
  var valid_594466 = header.getOrDefault("X-Amz-Credential")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Credential", valid_594466
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PolicyName` field"
  var valid_594467 = formData.getOrDefault("PolicyName")
  valid_594467 = validateParameter(valid_594467, JString, required = true,
                                 default = nil)
  if valid_594467 != nil:
    section.add "PolicyName", valid_594467
  var valid_594468 = formData.getOrDefault("LoadBalancerName")
  valid_594468 = validateParameter(valid_594468, JString, required = true,
                                 default = nil)
  if valid_594468 != nil:
    section.add "LoadBalancerName", valid_594468
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594469: Call_PostDeleteLoadBalancerPolicy_594455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_594469.validator(path, query, header, formData, body)
  let scheme = call_594469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594469.url(scheme.get, call_594469.host, call_594469.base,
                         call_594469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594469, url, valid)

proc call*(call_594470: Call_PostDeleteLoadBalancerPolicy_594455;
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
  var query_594471 = newJObject()
  var formData_594472 = newJObject()
  add(formData_594472, "PolicyName", newJString(PolicyName))
  add(query_594471, "Action", newJString(Action))
  add(formData_594472, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594471, "Version", newJString(Version))
  result = call_594470.call(nil, query_594471, nil, formData_594472, nil)

var postDeleteLoadBalancerPolicy* = Call_PostDeleteLoadBalancerPolicy_594455(
    name: "postDeleteLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_PostDeleteLoadBalancerPolicy_594456, base: "/",
    url: url_PostDeleteLoadBalancerPolicy_594457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerPolicy_594438 = ref object of OpenApiRestCall_593437
proc url_GetDeleteLoadBalancerPolicy_594440(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteLoadBalancerPolicy_594439(path: JsonNode; query: JsonNode;
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
  var valid_594441 = query.getOrDefault("LoadBalancerName")
  valid_594441 = validateParameter(valid_594441, JString, required = true,
                                 default = nil)
  if valid_594441 != nil:
    section.add "LoadBalancerName", valid_594441
  var valid_594442 = query.getOrDefault("Action")
  valid_594442 = validateParameter(valid_594442, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_594442 != nil:
    section.add "Action", valid_594442
  var valid_594443 = query.getOrDefault("Version")
  valid_594443 = validateParameter(valid_594443, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594443 != nil:
    section.add "Version", valid_594443
  var valid_594444 = query.getOrDefault("PolicyName")
  valid_594444 = validateParameter(valid_594444, JString, required = true,
                                 default = nil)
  if valid_594444 != nil:
    section.add "PolicyName", valid_594444
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
  var valid_594445 = header.getOrDefault("X-Amz-Date")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Date", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-Security-Token")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-Security-Token", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Content-Sha256", valid_594447
  var valid_594448 = header.getOrDefault("X-Amz-Algorithm")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "X-Amz-Algorithm", valid_594448
  var valid_594449 = header.getOrDefault("X-Amz-Signature")
  valid_594449 = validateParameter(valid_594449, JString, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "X-Amz-Signature", valid_594449
  var valid_594450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "X-Amz-SignedHeaders", valid_594450
  var valid_594451 = header.getOrDefault("X-Amz-Credential")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Credential", valid_594451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594452: Call_GetDeleteLoadBalancerPolicy_594438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_594452.validator(path, query, header, formData, body)
  let scheme = call_594452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594452.url(scheme.get, call_594452.host, call_594452.base,
                         call_594452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594452, url, valid)

proc call*(call_594453: Call_GetDeleteLoadBalancerPolicy_594438;
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
  var query_594454 = newJObject()
  add(query_594454, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594454, "Action", newJString(Action))
  add(query_594454, "Version", newJString(Version))
  add(query_594454, "PolicyName", newJString(PolicyName))
  result = call_594453.call(nil, query_594454, nil, nil, nil)

var getDeleteLoadBalancerPolicy* = Call_GetDeleteLoadBalancerPolicy_594438(
    name: "getDeleteLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_GetDeleteLoadBalancerPolicy_594439, base: "/",
    url: url_GetDeleteLoadBalancerPolicy_594440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterInstancesFromLoadBalancer_594490 = ref object of OpenApiRestCall_593437
proc url_PostDeregisterInstancesFromLoadBalancer_594492(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeregisterInstancesFromLoadBalancer_594491(path: JsonNode;
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
  var valid_594493 = query.getOrDefault("Action")
  valid_594493 = validateParameter(valid_594493, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_594493 != nil:
    section.add "Action", valid_594493
  var valid_594494 = query.getOrDefault("Version")
  valid_594494 = validateParameter(valid_594494, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594494 != nil:
    section.add "Version", valid_594494
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
  var valid_594495 = header.getOrDefault("X-Amz-Date")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "X-Amz-Date", valid_594495
  var valid_594496 = header.getOrDefault("X-Amz-Security-Token")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-Security-Token", valid_594496
  var valid_594497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594497 = validateParameter(valid_594497, JString, required = false,
                                 default = nil)
  if valid_594497 != nil:
    section.add "X-Amz-Content-Sha256", valid_594497
  var valid_594498 = header.getOrDefault("X-Amz-Algorithm")
  valid_594498 = validateParameter(valid_594498, JString, required = false,
                                 default = nil)
  if valid_594498 != nil:
    section.add "X-Amz-Algorithm", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Signature")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Signature", valid_594499
  var valid_594500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-SignedHeaders", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Credential")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Credential", valid_594501
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_594502 = formData.getOrDefault("Instances")
  valid_594502 = validateParameter(valid_594502, JArray, required = true, default = nil)
  if valid_594502 != nil:
    section.add "Instances", valid_594502
  var valid_594503 = formData.getOrDefault("LoadBalancerName")
  valid_594503 = validateParameter(valid_594503, JString, required = true,
                                 default = nil)
  if valid_594503 != nil:
    section.add "LoadBalancerName", valid_594503
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594504: Call_PostDeregisterInstancesFromLoadBalancer_594490;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594504.validator(path, query, header, formData, body)
  let scheme = call_594504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594504.url(scheme.get, call_594504.host, call_594504.base,
                         call_594504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594504, url, valid)

proc call*(call_594505: Call_PostDeregisterInstancesFromLoadBalancer_594490;
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
  var query_594506 = newJObject()
  var formData_594507 = newJObject()
  if Instances != nil:
    formData_594507.add "Instances", Instances
  add(query_594506, "Action", newJString(Action))
  add(formData_594507, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594506, "Version", newJString(Version))
  result = call_594505.call(nil, query_594506, nil, formData_594507, nil)

var postDeregisterInstancesFromLoadBalancer* = Call_PostDeregisterInstancesFromLoadBalancer_594490(
    name: "postDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_PostDeregisterInstancesFromLoadBalancer_594491, base: "/",
    url: url_PostDeregisterInstancesFromLoadBalancer_594492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterInstancesFromLoadBalancer_594473 = ref object of OpenApiRestCall_593437
proc url_GetDeregisterInstancesFromLoadBalancer_594475(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeregisterInstancesFromLoadBalancer_594474(path: JsonNode;
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
  var valid_594476 = query.getOrDefault("LoadBalancerName")
  valid_594476 = validateParameter(valid_594476, JString, required = true,
                                 default = nil)
  if valid_594476 != nil:
    section.add "LoadBalancerName", valid_594476
  var valid_594477 = query.getOrDefault("Action")
  valid_594477 = validateParameter(valid_594477, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_594477 != nil:
    section.add "Action", valid_594477
  var valid_594478 = query.getOrDefault("Instances")
  valid_594478 = validateParameter(valid_594478, JArray, required = true, default = nil)
  if valid_594478 != nil:
    section.add "Instances", valid_594478
  var valid_594479 = query.getOrDefault("Version")
  valid_594479 = validateParameter(valid_594479, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594479 != nil:
    section.add "Version", valid_594479
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
  var valid_594480 = header.getOrDefault("X-Amz-Date")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-Date", valid_594480
  var valid_594481 = header.getOrDefault("X-Amz-Security-Token")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Security-Token", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Content-Sha256", valid_594482
  var valid_594483 = header.getOrDefault("X-Amz-Algorithm")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "X-Amz-Algorithm", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-Signature")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Signature", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-SignedHeaders", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Credential")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Credential", valid_594486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594487: Call_GetDeregisterInstancesFromLoadBalancer_594473;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594487.validator(path, query, header, formData, body)
  let scheme = call_594487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594487.url(scheme.get, call_594487.host, call_594487.base,
                         call_594487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594487, url, valid)

proc call*(call_594488: Call_GetDeregisterInstancesFromLoadBalancer_594473;
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
  var query_594489 = newJObject()
  add(query_594489, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594489, "Action", newJString(Action))
  if Instances != nil:
    query_594489.add "Instances", Instances
  add(query_594489, "Version", newJString(Version))
  result = call_594488.call(nil, query_594489, nil, nil, nil)

var getDeregisterInstancesFromLoadBalancer* = Call_GetDeregisterInstancesFromLoadBalancer_594473(
    name: "getDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_GetDeregisterInstancesFromLoadBalancer_594474, base: "/",
    url: url_GetDeregisterInstancesFromLoadBalancer_594475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_594525 = ref object of OpenApiRestCall_593437
proc url_PostDescribeAccountLimits_594527(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAccountLimits_594526(path: JsonNode; query: JsonNode;
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
  var valid_594528 = query.getOrDefault("Action")
  valid_594528 = validateParameter(valid_594528, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_594528 != nil:
    section.add "Action", valid_594528
  var valid_594529 = query.getOrDefault("Version")
  valid_594529 = validateParameter(valid_594529, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594529 != nil:
    section.add "Version", valid_594529
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
  var valid_594530 = header.getOrDefault("X-Amz-Date")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-Date", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Security-Token")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Security-Token", valid_594531
  var valid_594532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-Content-Sha256", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Algorithm")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Algorithm", valid_594533
  var valid_594534 = header.getOrDefault("X-Amz-Signature")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Signature", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-SignedHeaders", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Credential")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Credential", valid_594536
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_594537 = formData.getOrDefault("Marker")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "Marker", valid_594537
  var valid_594538 = formData.getOrDefault("PageSize")
  valid_594538 = validateParameter(valid_594538, JInt, required = false, default = nil)
  if valid_594538 != nil:
    section.add "PageSize", valid_594538
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594539: Call_PostDescribeAccountLimits_594525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594539.validator(path, query, header, formData, body)
  let scheme = call_594539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594539.url(scheme.get, call_594539.host, call_594539.base,
                         call_594539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594539, url, valid)

proc call*(call_594540: Call_PostDescribeAccountLimits_594525; Marker: string = "";
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
  var query_594541 = newJObject()
  var formData_594542 = newJObject()
  add(formData_594542, "Marker", newJString(Marker))
  add(query_594541, "Action", newJString(Action))
  add(formData_594542, "PageSize", newJInt(PageSize))
  add(query_594541, "Version", newJString(Version))
  result = call_594540.call(nil, query_594541, nil, formData_594542, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_594525(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_594526, base: "/",
    url: url_PostDescribeAccountLimits_594527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_594508 = ref object of OpenApiRestCall_593437
proc url_GetDescribeAccountLimits_594510(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAccountLimits_594509(path: JsonNode; query: JsonNode;
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
  var valid_594511 = query.getOrDefault("PageSize")
  valid_594511 = validateParameter(valid_594511, JInt, required = false, default = nil)
  if valid_594511 != nil:
    section.add "PageSize", valid_594511
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594512 = query.getOrDefault("Action")
  valid_594512 = validateParameter(valid_594512, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_594512 != nil:
    section.add "Action", valid_594512
  var valid_594513 = query.getOrDefault("Marker")
  valid_594513 = validateParameter(valid_594513, JString, required = false,
                                 default = nil)
  if valid_594513 != nil:
    section.add "Marker", valid_594513
  var valid_594514 = query.getOrDefault("Version")
  valid_594514 = validateParameter(valid_594514, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594514 != nil:
    section.add "Version", valid_594514
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
  var valid_594515 = header.getOrDefault("X-Amz-Date")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-Date", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Security-Token")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Security-Token", valid_594516
  var valid_594517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-Content-Sha256", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Algorithm")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Algorithm", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Signature")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Signature", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-SignedHeaders", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Credential")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Credential", valid_594521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594522: Call_GetDescribeAccountLimits_594508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594522.validator(path, query, header, formData, body)
  let scheme = call_594522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594522.url(scheme.get, call_594522.host, call_594522.base,
                         call_594522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594522, url, valid)

proc call*(call_594523: Call_GetDescribeAccountLimits_594508; PageSize: int = 0;
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
  var query_594524 = newJObject()
  add(query_594524, "PageSize", newJInt(PageSize))
  add(query_594524, "Action", newJString(Action))
  add(query_594524, "Marker", newJString(Marker))
  add(query_594524, "Version", newJString(Version))
  result = call_594523.call(nil, query_594524, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_594508(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_594509, base: "/",
    url: url_GetDescribeAccountLimits_594510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstanceHealth_594560 = ref object of OpenApiRestCall_593437
proc url_PostDescribeInstanceHealth_594562(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeInstanceHealth_594561(path: JsonNode; query: JsonNode;
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
  var valid_594563 = query.getOrDefault("Action")
  valid_594563 = validateParameter(valid_594563, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_594563 != nil:
    section.add "Action", valid_594563
  var valid_594564 = query.getOrDefault("Version")
  valid_594564 = validateParameter(valid_594564, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594564 != nil:
    section.add "Version", valid_594564
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
  var valid_594565 = header.getOrDefault("X-Amz-Date")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-Date", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-Security-Token")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-Security-Token", valid_594566
  var valid_594567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Content-Sha256", valid_594567
  var valid_594568 = header.getOrDefault("X-Amz-Algorithm")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-Algorithm", valid_594568
  var valid_594569 = header.getOrDefault("X-Amz-Signature")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "X-Amz-Signature", valid_594569
  var valid_594570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-SignedHeaders", valid_594570
  var valid_594571 = header.getOrDefault("X-Amz-Credential")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Credential", valid_594571
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_594572 = formData.getOrDefault("Instances")
  valid_594572 = validateParameter(valid_594572, JArray, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "Instances", valid_594572
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_594573 = formData.getOrDefault("LoadBalancerName")
  valid_594573 = validateParameter(valid_594573, JString, required = true,
                                 default = nil)
  if valid_594573 != nil:
    section.add "LoadBalancerName", valid_594573
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594574: Call_PostDescribeInstanceHealth_594560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_594574.validator(path, query, header, formData, body)
  let scheme = call_594574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594574.url(scheme.get, call_594574.host, call_594574.base,
                         call_594574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594574, url, valid)

proc call*(call_594575: Call_PostDescribeInstanceHealth_594560;
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
  var query_594576 = newJObject()
  var formData_594577 = newJObject()
  if Instances != nil:
    formData_594577.add "Instances", Instances
  add(query_594576, "Action", newJString(Action))
  add(formData_594577, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594576, "Version", newJString(Version))
  result = call_594575.call(nil, query_594576, nil, formData_594577, nil)

var postDescribeInstanceHealth* = Call_PostDescribeInstanceHealth_594560(
    name: "postDescribeInstanceHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_PostDescribeInstanceHealth_594561, base: "/",
    url: url_PostDescribeInstanceHealth_594562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstanceHealth_594543 = ref object of OpenApiRestCall_593437
proc url_GetDescribeInstanceHealth_594545(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeInstanceHealth_594544(path: JsonNode; query: JsonNode;
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
  var valid_594546 = query.getOrDefault("LoadBalancerName")
  valid_594546 = validateParameter(valid_594546, JString, required = true,
                                 default = nil)
  if valid_594546 != nil:
    section.add "LoadBalancerName", valid_594546
  var valid_594547 = query.getOrDefault("Action")
  valid_594547 = validateParameter(valid_594547, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_594547 != nil:
    section.add "Action", valid_594547
  var valid_594548 = query.getOrDefault("Instances")
  valid_594548 = validateParameter(valid_594548, JArray, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "Instances", valid_594548
  var valid_594549 = query.getOrDefault("Version")
  valid_594549 = validateParameter(valid_594549, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594549 != nil:
    section.add "Version", valid_594549
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
  var valid_594550 = header.getOrDefault("X-Amz-Date")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Date", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Security-Token")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Security-Token", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Content-Sha256", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-Algorithm")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Algorithm", valid_594553
  var valid_594554 = header.getOrDefault("X-Amz-Signature")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-Signature", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-SignedHeaders", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-Credential")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Credential", valid_594556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594557: Call_GetDescribeInstanceHealth_594543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_594557.validator(path, query, header, formData, body)
  let scheme = call_594557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594557.url(scheme.get, call_594557.host, call_594557.base,
                         call_594557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594557, url, valid)

proc call*(call_594558: Call_GetDescribeInstanceHealth_594543;
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
  var query_594559 = newJObject()
  add(query_594559, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594559, "Action", newJString(Action))
  if Instances != nil:
    query_594559.add "Instances", Instances
  add(query_594559, "Version", newJString(Version))
  result = call_594558.call(nil, query_594559, nil, nil, nil)

var getDescribeInstanceHealth* = Call_GetDescribeInstanceHealth_594543(
    name: "getDescribeInstanceHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_GetDescribeInstanceHealth_594544, base: "/",
    url: url_GetDescribeInstanceHealth_594545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_594594 = ref object of OpenApiRestCall_593437
proc url_PostDescribeLoadBalancerAttributes_594596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancerAttributes_594595(path: JsonNode;
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
  var valid_594597 = query.getOrDefault("Action")
  valid_594597 = validateParameter(valid_594597, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_594597 != nil:
    section.add "Action", valid_594597
  var valid_594598 = query.getOrDefault("Version")
  valid_594598 = validateParameter(valid_594598, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594598 != nil:
    section.add "Version", valid_594598
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
  var valid_594599 = header.getOrDefault("X-Amz-Date")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "X-Amz-Date", valid_594599
  var valid_594600 = header.getOrDefault("X-Amz-Security-Token")
  valid_594600 = validateParameter(valid_594600, JString, required = false,
                                 default = nil)
  if valid_594600 != nil:
    section.add "X-Amz-Security-Token", valid_594600
  var valid_594601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-Content-Sha256", valid_594601
  var valid_594602 = header.getOrDefault("X-Amz-Algorithm")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-Algorithm", valid_594602
  var valid_594603 = header.getOrDefault("X-Amz-Signature")
  valid_594603 = validateParameter(valid_594603, JString, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "X-Amz-Signature", valid_594603
  var valid_594604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-SignedHeaders", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-Credential")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Credential", valid_594605
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_594606 = formData.getOrDefault("LoadBalancerName")
  valid_594606 = validateParameter(valid_594606, JString, required = true,
                                 default = nil)
  if valid_594606 != nil:
    section.add "LoadBalancerName", valid_594606
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594607: Call_PostDescribeLoadBalancerAttributes_594594;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_594607.validator(path, query, header, formData, body)
  let scheme = call_594607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594607.url(scheme.get, call_594607.host, call_594607.base,
                         call_594607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594607, url, valid)

proc call*(call_594608: Call_PostDescribeLoadBalancerAttributes_594594;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_594609 = newJObject()
  var formData_594610 = newJObject()
  add(query_594609, "Action", newJString(Action))
  add(formData_594610, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594609, "Version", newJString(Version))
  result = call_594608.call(nil, query_594609, nil, formData_594610, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_594594(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_594595, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_594596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_594578 = ref object of OpenApiRestCall_593437
proc url_GetDescribeLoadBalancerAttributes_594580(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancerAttributes_594579(path: JsonNode;
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
  var valid_594581 = query.getOrDefault("LoadBalancerName")
  valid_594581 = validateParameter(valid_594581, JString, required = true,
                                 default = nil)
  if valid_594581 != nil:
    section.add "LoadBalancerName", valid_594581
  var valid_594582 = query.getOrDefault("Action")
  valid_594582 = validateParameter(valid_594582, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_594582 != nil:
    section.add "Action", valid_594582
  var valid_594583 = query.getOrDefault("Version")
  valid_594583 = validateParameter(valid_594583, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594583 != nil:
    section.add "Version", valid_594583
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
  var valid_594584 = header.getOrDefault("X-Amz-Date")
  valid_594584 = validateParameter(valid_594584, JString, required = false,
                                 default = nil)
  if valid_594584 != nil:
    section.add "X-Amz-Date", valid_594584
  var valid_594585 = header.getOrDefault("X-Amz-Security-Token")
  valid_594585 = validateParameter(valid_594585, JString, required = false,
                                 default = nil)
  if valid_594585 != nil:
    section.add "X-Amz-Security-Token", valid_594585
  var valid_594586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "X-Amz-Content-Sha256", valid_594586
  var valid_594587 = header.getOrDefault("X-Amz-Algorithm")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "X-Amz-Algorithm", valid_594587
  var valid_594588 = header.getOrDefault("X-Amz-Signature")
  valid_594588 = validateParameter(valid_594588, JString, required = false,
                                 default = nil)
  if valid_594588 != nil:
    section.add "X-Amz-Signature", valid_594588
  var valid_594589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-SignedHeaders", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Credential")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Credential", valid_594590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594591: Call_GetDescribeLoadBalancerAttributes_594578;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_594591.validator(path, query, header, formData, body)
  let scheme = call_594591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594591.url(scheme.get, call_594591.host, call_594591.base,
                         call_594591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594591, url, valid)

proc call*(call_594592: Call_GetDescribeLoadBalancerAttributes_594578;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594593 = newJObject()
  add(query_594593, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594593, "Action", newJString(Action))
  add(query_594593, "Version", newJString(Version))
  result = call_594592.call(nil, query_594593, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_594578(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_594579, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_594580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicies_594628 = ref object of OpenApiRestCall_593437
proc url_PostDescribeLoadBalancerPolicies_594630(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancerPolicies_594629(path: JsonNode;
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
  var valid_594631 = query.getOrDefault("Action")
  valid_594631 = validateParameter(valid_594631, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_594631 != nil:
    section.add "Action", valid_594631
  var valid_594632 = query.getOrDefault("Version")
  valid_594632 = validateParameter(valid_594632, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594632 != nil:
    section.add "Version", valid_594632
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
  var valid_594633 = header.getOrDefault("X-Amz-Date")
  valid_594633 = validateParameter(valid_594633, JString, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "X-Amz-Date", valid_594633
  var valid_594634 = header.getOrDefault("X-Amz-Security-Token")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "X-Amz-Security-Token", valid_594634
  var valid_594635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "X-Amz-Content-Sha256", valid_594635
  var valid_594636 = header.getOrDefault("X-Amz-Algorithm")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "X-Amz-Algorithm", valid_594636
  var valid_594637 = header.getOrDefault("X-Amz-Signature")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-Signature", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-SignedHeaders", valid_594638
  var valid_594639 = header.getOrDefault("X-Amz-Credential")
  valid_594639 = validateParameter(valid_594639, JString, required = false,
                                 default = nil)
  if valid_594639 != nil:
    section.add "X-Amz-Credential", valid_594639
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   LoadBalancerName: JString
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_594640 = formData.getOrDefault("PolicyNames")
  valid_594640 = validateParameter(valid_594640, JArray, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "PolicyNames", valid_594640
  var valid_594641 = formData.getOrDefault("LoadBalancerName")
  valid_594641 = validateParameter(valid_594641, JString, required = false,
                                 default = nil)
  if valid_594641 != nil:
    section.add "LoadBalancerName", valid_594641
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594642: Call_PostDescribeLoadBalancerPolicies_594628;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_594642.validator(path, query, header, formData, body)
  let scheme = call_594642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594642.url(scheme.get, call_594642.host, call_594642.base,
                         call_594642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594642, url, valid)

proc call*(call_594643: Call_PostDescribeLoadBalancerPolicies_594628;
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
  var query_594644 = newJObject()
  var formData_594645 = newJObject()
  if PolicyNames != nil:
    formData_594645.add "PolicyNames", PolicyNames
  add(query_594644, "Action", newJString(Action))
  add(formData_594645, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594644, "Version", newJString(Version))
  result = call_594643.call(nil, query_594644, nil, formData_594645, nil)

var postDescribeLoadBalancerPolicies* = Call_PostDescribeLoadBalancerPolicies_594628(
    name: "postDescribeLoadBalancerPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_PostDescribeLoadBalancerPolicies_594629, base: "/",
    url: url_PostDescribeLoadBalancerPolicies_594630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicies_594611 = ref object of OpenApiRestCall_593437
proc url_GetDescribeLoadBalancerPolicies_594613(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancerPolicies_594612(path: JsonNode;
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
  var valid_594614 = query.getOrDefault("LoadBalancerName")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "LoadBalancerName", valid_594614
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594615 = query.getOrDefault("Action")
  valid_594615 = validateParameter(valid_594615, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_594615 != nil:
    section.add "Action", valid_594615
  var valid_594616 = query.getOrDefault("PolicyNames")
  valid_594616 = validateParameter(valid_594616, JArray, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "PolicyNames", valid_594616
  var valid_594617 = query.getOrDefault("Version")
  valid_594617 = validateParameter(valid_594617, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594617 != nil:
    section.add "Version", valid_594617
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
  var valid_594618 = header.getOrDefault("X-Amz-Date")
  valid_594618 = validateParameter(valid_594618, JString, required = false,
                                 default = nil)
  if valid_594618 != nil:
    section.add "X-Amz-Date", valid_594618
  var valid_594619 = header.getOrDefault("X-Amz-Security-Token")
  valid_594619 = validateParameter(valid_594619, JString, required = false,
                                 default = nil)
  if valid_594619 != nil:
    section.add "X-Amz-Security-Token", valid_594619
  var valid_594620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594620 = validateParameter(valid_594620, JString, required = false,
                                 default = nil)
  if valid_594620 != nil:
    section.add "X-Amz-Content-Sha256", valid_594620
  var valid_594621 = header.getOrDefault("X-Amz-Algorithm")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "X-Amz-Algorithm", valid_594621
  var valid_594622 = header.getOrDefault("X-Amz-Signature")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-Signature", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-SignedHeaders", valid_594623
  var valid_594624 = header.getOrDefault("X-Amz-Credential")
  valid_594624 = validateParameter(valid_594624, JString, required = false,
                                 default = nil)
  if valid_594624 != nil:
    section.add "X-Amz-Credential", valid_594624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594625: Call_GetDescribeLoadBalancerPolicies_594611;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_594625.validator(path, query, header, formData, body)
  let scheme = call_594625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594625.url(scheme.get, call_594625.host, call_594625.base,
                         call_594625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594625, url, valid)

proc call*(call_594626: Call_GetDescribeLoadBalancerPolicies_594611;
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
  var query_594627 = newJObject()
  add(query_594627, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594627, "Action", newJString(Action))
  if PolicyNames != nil:
    query_594627.add "PolicyNames", PolicyNames
  add(query_594627, "Version", newJString(Version))
  result = call_594626.call(nil, query_594627, nil, nil, nil)

var getDescribeLoadBalancerPolicies* = Call_GetDescribeLoadBalancerPolicies_594611(
    name: "getDescribeLoadBalancerPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_GetDescribeLoadBalancerPolicies_594612, base: "/",
    url: url_GetDescribeLoadBalancerPolicies_594613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicyTypes_594662 = ref object of OpenApiRestCall_593437
proc url_PostDescribeLoadBalancerPolicyTypes_594664(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancerPolicyTypes_594663(path: JsonNode;
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
  var valid_594665 = query.getOrDefault("Action")
  valid_594665 = validateParameter(valid_594665, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_594665 != nil:
    section.add "Action", valid_594665
  var valid_594666 = query.getOrDefault("Version")
  valid_594666 = validateParameter(valid_594666, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594666 != nil:
    section.add "Version", valid_594666
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
  var valid_594667 = header.getOrDefault("X-Amz-Date")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-Date", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Security-Token")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Security-Token", valid_594668
  var valid_594669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594669 = validateParameter(valid_594669, JString, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "X-Amz-Content-Sha256", valid_594669
  var valid_594670 = header.getOrDefault("X-Amz-Algorithm")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-Algorithm", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Signature")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Signature", valid_594671
  var valid_594672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-SignedHeaders", valid_594672
  var valid_594673 = header.getOrDefault("X-Amz-Credential")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-Credential", valid_594673
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  section = newJObject()
  var valid_594674 = formData.getOrDefault("PolicyTypeNames")
  valid_594674 = validateParameter(valid_594674, JArray, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "PolicyTypeNames", valid_594674
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594675: Call_PostDescribeLoadBalancerPolicyTypes_594662;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_594675.validator(path, query, header, formData, body)
  let scheme = call_594675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594675.url(scheme.get, call_594675.host, call_594675.base,
                         call_594675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594675, url, valid)

proc call*(call_594676: Call_PostDescribeLoadBalancerPolicyTypes_594662;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594677 = newJObject()
  var formData_594678 = newJObject()
  if PolicyTypeNames != nil:
    formData_594678.add "PolicyTypeNames", PolicyTypeNames
  add(query_594677, "Action", newJString(Action))
  add(query_594677, "Version", newJString(Version))
  result = call_594676.call(nil, query_594677, nil, formData_594678, nil)

var postDescribeLoadBalancerPolicyTypes* = Call_PostDescribeLoadBalancerPolicyTypes_594662(
    name: "postDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_PostDescribeLoadBalancerPolicyTypes_594663, base: "/",
    url: url_PostDescribeLoadBalancerPolicyTypes_594664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicyTypes_594646 = ref object of OpenApiRestCall_593437
proc url_GetDescribeLoadBalancerPolicyTypes_594648(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancerPolicyTypes_594647(path: JsonNode;
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
  var valid_594649 = query.getOrDefault("Action")
  valid_594649 = validateParameter(valid_594649, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_594649 != nil:
    section.add "Action", valid_594649
  var valid_594650 = query.getOrDefault("PolicyTypeNames")
  valid_594650 = validateParameter(valid_594650, JArray, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "PolicyTypeNames", valid_594650
  var valid_594651 = query.getOrDefault("Version")
  valid_594651 = validateParameter(valid_594651, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594651 != nil:
    section.add "Version", valid_594651
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
  var valid_594652 = header.getOrDefault("X-Amz-Date")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-Date", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Security-Token")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Security-Token", valid_594653
  var valid_594654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594654 = validateParameter(valid_594654, JString, required = false,
                                 default = nil)
  if valid_594654 != nil:
    section.add "X-Amz-Content-Sha256", valid_594654
  var valid_594655 = header.getOrDefault("X-Amz-Algorithm")
  valid_594655 = validateParameter(valid_594655, JString, required = false,
                                 default = nil)
  if valid_594655 != nil:
    section.add "X-Amz-Algorithm", valid_594655
  var valid_594656 = header.getOrDefault("X-Amz-Signature")
  valid_594656 = validateParameter(valid_594656, JString, required = false,
                                 default = nil)
  if valid_594656 != nil:
    section.add "X-Amz-Signature", valid_594656
  var valid_594657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-SignedHeaders", valid_594657
  var valid_594658 = header.getOrDefault("X-Amz-Credential")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-Credential", valid_594658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594659: Call_GetDescribeLoadBalancerPolicyTypes_594646;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_594659.validator(path, query, header, formData, body)
  let scheme = call_594659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594659.url(scheme.get, call_594659.host, call_594659.base,
                         call_594659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594659, url, valid)

proc call*(call_594660: Call_GetDescribeLoadBalancerPolicyTypes_594646;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          PolicyTypeNames: JsonNode = nil; Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   Action: string (required)
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Version: string (required)
  var query_594661 = newJObject()
  add(query_594661, "Action", newJString(Action))
  if PolicyTypeNames != nil:
    query_594661.add "PolicyTypeNames", PolicyTypeNames
  add(query_594661, "Version", newJString(Version))
  result = call_594660.call(nil, query_594661, nil, nil, nil)

var getDescribeLoadBalancerPolicyTypes* = Call_GetDescribeLoadBalancerPolicyTypes_594646(
    name: "getDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_GetDescribeLoadBalancerPolicyTypes_594647, base: "/",
    url: url_GetDescribeLoadBalancerPolicyTypes_594648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_594697 = ref object of OpenApiRestCall_593437
proc url_PostDescribeLoadBalancers_594699(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancers_594698(path: JsonNode; query: JsonNode;
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
  var valid_594700 = query.getOrDefault("Action")
  valid_594700 = validateParameter(valid_594700, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_594700 != nil:
    section.add "Action", valid_594700
  var valid_594701 = query.getOrDefault("Version")
  valid_594701 = validateParameter(valid_594701, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594701 != nil:
    section.add "Version", valid_594701
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
  var valid_594702 = header.getOrDefault("X-Amz-Date")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Date", valid_594702
  var valid_594703 = header.getOrDefault("X-Amz-Security-Token")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-Security-Token", valid_594703
  var valid_594704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594704 = validateParameter(valid_594704, JString, required = false,
                                 default = nil)
  if valid_594704 != nil:
    section.add "X-Amz-Content-Sha256", valid_594704
  var valid_594705 = header.getOrDefault("X-Amz-Algorithm")
  valid_594705 = validateParameter(valid_594705, JString, required = false,
                                 default = nil)
  if valid_594705 != nil:
    section.add "X-Amz-Algorithm", valid_594705
  var valid_594706 = header.getOrDefault("X-Amz-Signature")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-Signature", valid_594706
  var valid_594707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "X-Amz-SignedHeaders", valid_594707
  var valid_594708 = header.getOrDefault("X-Amz-Credential")
  valid_594708 = validateParameter(valid_594708, JString, required = false,
                                 default = nil)
  if valid_594708 != nil:
    section.add "X-Amz-Credential", valid_594708
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  section = newJObject()
  var valid_594709 = formData.getOrDefault("Marker")
  valid_594709 = validateParameter(valid_594709, JString, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "Marker", valid_594709
  var valid_594710 = formData.getOrDefault("LoadBalancerNames")
  valid_594710 = validateParameter(valid_594710, JArray, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "LoadBalancerNames", valid_594710
  var valid_594711 = formData.getOrDefault("PageSize")
  valid_594711 = validateParameter(valid_594711, JInt, required = false, default = nil)
  if valid_594711 != nil:
    section.add "PageSize", valid_594711
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594712: Call_PostDescribeLoadBalancers_594697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_594712.validator(path, query, header, formData, body)
  let scheme = call_594712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594712.url(scheme.get, call_594712.host, call_594712.base,
                         call_594712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594712, url, valid)

proc call*(call_594713: Call_PostDescribeLoadBalancers_594697; Marker: string = "";
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
  var query_594714 = newJObject()
  var formData_594715 = newJObject()
  add(formData_594715, "Marker", newJString(Marker))
  add(query_594714, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_594715.add "LoadBalancerNames", LoadBalancerNames
  add(formData_594715, "PageSize", newJInt(PageSize))
  add(query_594714, "Version", newJString(Version))
  result = call_594713.call(nil, query_594714, nil, formData_594715, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_594697(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_594698, base: "/",
    url: url_PostDescribeLoadBalancers_594699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_594679 = ref object of OpenApiRestCall_593437
proc url_GetDescribeLoadBalancers_594681(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancers_594680(path: JsonNode; query: JsonNode;
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
  var valid_594682 = query.getOrDefault("PageSize")
  valid_594682 = validateParameter(valid_594682, JInt, required = false, default = nil)
  if valid_594682 != nil:
    section.add "PageSize", valid_594682
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594683 = query.getOrDefault("Action")
  valid_594683 = validateParameter(valid_594683, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_594683 != nil:
    section.add "Action", valid_594683
  var valid_594684 = query.getOrDefault("Marker")
  valid_594684 = validateParameter(valid_594684, JString, required = false,
                                 default = nil)
  if valid_594684 != nil:
    section.add "Marker", valid_594684
  var valid_594685 = query.getOrDefault("LoadBalancerNames")
  valid_594685 = validateParameter(valid_594685, JArray, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "LoadBalancerNames", valid_594685
  var valid_594686 = query.getOrDefault("Version")
  valid_594686 = validateParameter(valid_594686, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594686 != nil:
    section.add "Version", valid_594686
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
  var valid_594687 = header.getOrDefault("X-Amz-Date")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-Date", valid_594687
  var valid_594688 = header.getOrDefault("X-Amz-Security-Token")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-Security-Token", valid_594688
  var valid_594689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594689 = validateParameter(valid_594689, JString, required = false,
                                 default = nil)
  if valid_594689 != nil:
    section.add "X-Amz-Content-Sha256", valid_594689
  var valid_594690 = header.getOrDefault("X-Amz-Algorithm")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "X-Amz-Algorithm", valid_594690
  var valid_594691 = header.getOrDefault("X-Amz-Signature")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "X-Amz-Signature", valid_594691
  var valid_594692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "X-Amz-SignedHeaders", valid_594692
  var valid_594693 = header.getOrDefault("X-Amz-Credential")
  valid_594693 = validateParameter(valid_594693, JString, required = false,
                                 default = nil)
  if valid_594693 != nil:
    section.add "X-Amz-Credential", valid_594693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594694: Call_GetDescribeLoadBalancers_594679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_594694.validator(path, query, header, formData, body)
  let scheme = call_594694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594694.url(scheme.get, call_594694.host, call_594694.base,
                         call_594694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594694, url, valid)

proc call*(call_594695: Call_GetDescribeLoadBalancers_594679; PageSize: int = 0;
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
  var query_594696 = newJObject()
  add(query_594696, "PageSize", newJInt(PageSize))
  add(query_594696, "Action", newJString(Action))
  add(query_594696, "Marker", newJString(Marker))
  if LoadBalancerNames != nil:
    query_594696.add "LoadBalancerNames", LoadBalancerNames
  add(query_594696, "Version", newJString(Version))
  result = call_594695.call(nil, query_594696, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_594679(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_594680, base: "/",
    url: url_GetDescribeLoadBalancers_594681, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_594732 = ref object of OpenApiRestCall_593437
proc url_PostDescribeTags_594734(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTags_594733(path: JsonNode; query: JsonNode;
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
  var valid_594735 = query.getOrDefault("Action")
  valid_594735 = validateParameter(valid_594735, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_594735 != nil:
    section.add "Action", valid_594735
  var valid_594736 = query.getOrDefault("Version")
  valid_594736 = validateParameter(valid_594736, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594736 != nil:
    section.add "Version", valid_594736
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
  var valid_594737 = header.getOrDefault("X-Amz-Date")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "X-Amz-Date", valid_594737
  var valid_594738 = header.getOrDefault("X-Amz-Security-Token")
  valid_594738 = validateParameter(valid_594738, JString, required = false,
                                 default = nil)
  if valid_594738 != nil:
    section.add "X-Amz-Security-Token", valid_594738
  var valid_594739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "X-Amz-Content-Sha256", valid_594739
  var valid_594740 = header.getOrDefault("X-Amz-Algorithm")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-Algorithm", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-Signature")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-Signature", valid_594741
  var valid_594742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-SignedHeaders", valid_594742
  var valid_594743 = header.getOrDefault("X-Amz-Credential")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Credential", valid_594743
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_594744 = formData.getOrDefault("LoadBalancerNames")
  valid_594744 = validateParameter(valid_594744, JArray, required = true, default = nil)
  if valid_594744 != nil:
    section.add "LoadBalancerNames", valid_594744
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594745: Call_PostDescribeTags_594732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_594745.validator(path, query, header, formData, body)
  let scheme = call_594745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594745.url(scheme.get, call_594745.host, call_594745.base,
                         call_594745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594745, url, valid)

proc call*(call_594746: Call_PostDescribeTags_594732; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_594747 = newJObject()
  var formData_594748 = newJObject()
  add(query_594747, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_594748.add "LoadBalancerNames", LoadBalancerNames
  add(query_594747, "Version", newJString(Version))
  result = call_594746.call(nil, query_594747, nil, formData_594748, nil)

var postDescribeTags* = Call_PostDescribeTags_594732(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_594733,
    base: "/", url: url_PostDescribeTags_594734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_594716 = ref object of OpenApiRestCall_593437
proc url_GetDescribeTags_594718(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTags_594717(path: JsonNode; query: JsonNode;
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
  var valid_594719 = query.getOrDefault("Action")
  valid_594719 = validateParameter(valid_594719, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_594719 != nil:
    section.add "Action", valid_594719
  var valid_594720 = query.getOrDefault("LoadBalancerNames")
  valid_594720 = validateParameter(valid_594720, JArray, required = true, default = nil)
  if valid_594720 != nil:
    section.add "LoadBalancerNames", valid_594720
  var valid_594721 = query.getOrDefault("Version")
  valid_594721 = validateParameter(valid_594721, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594721 != nil:
    section.add "Version", valid_594721
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
  var valid_594722 = header.getOrDefault("X-Amz-Date")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Date", valid_594722
  var valid_594723 = header.getOrDefault("X-Amz-Security-Token")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "X-Amz-Security-Token", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Content-Sha256", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-Algorithm")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-Algorithm", valid_594725
  var valid_594726 = header.getOrDefault("X-Amz-Signature")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "X-Amz-Signature", valid_594726
  var valid_594727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594727 = validateParameter(valid_594727, JString, required = false,
                                 default = nil)
  if valid_594727 != nil:
    section.add "X-Amz-SignedHeaders", valid_594727
  var valid_594728 = header.getOrDefault("X-Amz-Credential")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Credential", valid_594728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594729: Call_GetDescribeTags_594716; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_594729.validator(path, query, header, formData, body)
  let scheme = call_594729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594729.url(scheme.get, call_594729.host, call_594729.base,
                         call_594729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594729, url, valid)

proc call*(call_594730: Call_GetDescribeTags_594716; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_594731 = newJObject()
  add(query_594731, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_594731.add "LoadBalancerNames", LoadBalancerNames
  add(query_594731, "Version", newJString(Version))
  result = call_594730.call(nil, query_594731, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_594716(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_594717,
    base: "/", url: url_GetDescribeTags_594718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDetachLoadBalancerFromSubnets_594766 = ref object of OpenApiRestCall_593437
proc url_PostDetachLoadBalancerFromSubnets_594768(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDetachLoadBalancerFromSubnets_594767(path: JsonNode;
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
  var valid_594769 = query.getOrDefault("Action")
  valid_594769 = validateParameter(valid_594769, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_594769 != nil:
    section.add "Action", valid_594769
  var valid_594770 = query.getOrDefault("Version")
  valid_594770 = validateParameter(valid_594770, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594770 != nil:
    section.add "Version", valid_594770
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
  var valid_594771 = header.getOrDefault("X-Amz-Date")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "X-Amz-Date", valid_594771
  var valid_594772 = header.getOrDefault("X-Amz-Security-Token")
  valid_594772 = validateParameter(valid_594772, JString, required = false,
                                 default = nil)
  if valid_594772 != nil:
    section.add "X-Amz-Security-Token", valid_594772
  var valid_594773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594773 = validateParameter(valid_594773, JString, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "X-Amz-Content-Sha256", valid_594773
  var valid_594774 = header.getOrDefault("X-Amz-Algorithm")
  valid_594774 = validateParameter(valid_594774, JString, required = false,
                                 default = nil)
  if valid_594774 != nil:
    section.add "X-Amz-Algorithm", valid_594774
  var valid_594775 = header.getOrDefault("X-Amz-Signature")
  valid_594775 = validateParameter(valid_594775, JString, required = false,
                                 default = nil)
  if valid_594775 != nil:
    section.add "X-Amz-Signature", valid_594775
  var valid_594776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "X-Amz-SignedHeaders", valid_594776
  var valid_594777 = header.getOrDefault("X-Amz-Credential")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Credential", valid_594777
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_594778 = formData.getOrDefault("Subnets")
  valid_594778 = validateParameter(valid_594778, JArray, required = true, default = nil)
  if valid_594778 != nil:
    section.add "Subnets", valid_594778
  var valid_594779 = formData.getOrDefault("LoadBalancerName")
  valid_594779 = validateParameter(valid_594779, JString, required = true,
                                 default = nil)
  if valid_594779 != nil:
    section.add "LoadBalancerName", valid_594779
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594780: Call_PostDetachLoadBalancerFromSubnets_594766;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_594780.validator(path, query, header, formData, body)
  let scheme = call_594780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594780.url(scheme.get, call_594780.host, call_594780.base,
                         call_594780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594780, url, valid)

proc call*(call_594781: Call_PostDetachLoadBalancerFromSubnets_594766;
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
  var query_594782 = newJObject()
  var formData_594783 = newJObject()
  add(query_594782, "Action", newJString(Action))
  if Subnets != nil:
    formData_594783.add "Subnets", Subnets
  add(formData_594783, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594782, "Version", newJString(Version))
  result = call_594781.call(nil, query_594782, nil, formData_594783, nil)

var postDetachLoadBalancerFromSubnets* = Call_PostDetachLoadBalancerFromSubnets_594766(
    name: "postDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_PostDetachLoadBalancerFromSubnets_594767, base: "/",
    url: url_PostDetachLoadBalancerFromSubnets_594768,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetachLoadBalancerFromSubnets_594749 = ref object of OpenApiRestCall_593437
proc url_GetDetachLoadBalancerFromSubnets_594751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDetachLoadBalancerFromSubnets_594750(path: JsonNode;
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
  var valid_594752 = query.getOrDefault("LoadBalancerName")
  valid_594752 = validateParameter(valid_594752, JString, required = true,
                                 default = nil)
  if valid_594752 != nil:
    section.add "LoadBalancerName", valid_594752
  var valid_594753 = query.getOrDefault("Action")
  valid_594753 = validateParameter(valid_594753, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_594753 != nil:
    section.add "Action", valid_594753
  var valid_594754 = query.getOrDefault("Subnets")
  valid_594754 = validateParameter(valid_594754, JArray, required = true, default = nil)
  if valid_594754 != nil:
    section.add "Subnets", valid_594754
  var valid_594755 = query.getOrDefault("Version")
  valid_594755 = validateParameter(valid_594755, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594755 != nil:
    section.add "Version", valid_594755
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
  var valid_594756 = header.getOrDefault("X-Amz-Date")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-Date", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-Security-Token")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-Security-Token", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-Content-Sha256", valid_594758
  var valid_594759 = header.getOrDefault("X-Amz-Algorithm")
  valid_594759 = validateParameter(valid_594759, JString, required = false,
                                 default = nil)
  if valid_594759 != nil:
    section.add "X-Amz-Algorithm", valid_594759
  var valid_594760 = header.getOrDefault("X-Amz-Signature")
  valid_594760 = validateParameter(valid_594760, JString, required = false,
                                 default = nil)
  if valid_594760 != nil:
    section.add "X-Amz-Signature", valid_594760
  var valid_594761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "X-Amz-SignedHeaders", valid_594761
  var valid_594762 = header.getOrDefault("X-Amz-Credential")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Credential", valid_594762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594763: Call_GetDetachLoadBalancerFromSubnets_594749;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_594763.validator(path, query, header, formData, body)
  let scheme = call_594763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594763.url(scheme.get, call_594763.host, call_594763.base,
                         call_594763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594763, url, valid)

proc call*(call_594764: Call_GetDetachLoadBalancerFromSubnets_594749;
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
  var query_594765 = newJObject()
  add(query_594765, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594765, "Action", newJString(Action))
  if Subnets != nil:
    query_594765.add "Subnets", Subnets
  add(query_594765, "Version", newJString(Version))
  result = call_594764.call(nil, query_594765, nil, nil, nil)

var getDetachLoadBalancerFromSubnets* = Call_GetDetachLoadBalancerFromSubnets_594749(
    name: "getDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_GetDetachLoadBalancerFromSubnets_594750, base: "/",
    url: url_GetDetachLoadBalancerFromSubnets_594751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAvailabilityZonesForLoadBalancer_594801 = ref object of OpenApiRestCall_593437
proc url_PostDisableAvailabilityZonesForLoadBalancer_594803(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDisableAvailabilityZonesForLoadBalancer_594802(path: JsonNode;
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
  var valid_594804 = query.getOrDefault("Action")
  valid_594804 = validateParameter(valid_594804, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_594804 != nil:
    section.add "Action", valid_594804
  var valid_594805 = query.getOrDefault("Version")
  valid_594805 = validateParameter(valid_594805, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594805 != nil:
    section.add "Version", valid_594805
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
  var valid_594806 = header.getOrDefault("X-Amz-Date")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "X-Amz-Date", valid_594806
  var valid_594807 = header.getOrDefault("X-Amz-Security-Token")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "X-Amz-Security-Token", valid_594807
  var valid_594808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594808 = validateParameter(valid_594808, JString, required = false,
                                 default = nil)
  if valid_594808 != nil:
    section.add "X-Amz-Content-Sha256", valid_594808
  var valid_594809 = header.getOrDefault("X-Amz-Algorithm")
  valid_594809 = validateParameter(valid_594809, JString, required = false,
                                 default = nil)
  if valid_594809 != nil:
    section.add "X-Amz-Algorithm", valid_594809
  var valid_594810 = header.getOrDefault("X-Amz-Signature")
  valid_594810 = validateParameter(valid_594810, JString, required = false,
                                 default = nil)
  if valid_594810 != nil:
    section.add "X-Amz-Signature", valid_594810
  var valid_594811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "X-Amz-SignedHeaders", valid_594811
  var valid_594812 = header.getOrDefault("X-Amz-Credential")
  valid_594812 = validateParameter(valid_594812, JString, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "X-Amz-Credential", valid_594812
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_594813 = formData.getOrDefault("AvailabilityZones")
  valid_594813 = validateParameter(valid_594813, JArray, required = true, default = nil)
  if valid_594813 != nil:
    section.add "AvailabilityZones", valid_594813
  var valid_594814 = formData.getOrDefault("LoadBalancerName")
  valid_594814 = validateParameter(valid_594814, JString, required = true,
                                 default = nil)
  if valid_594814 != nil:
    section.add "LoadBalancerName", valid_594814
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594815: Call_PostDisableAvailabilityZonesForLoadBalancer_594801;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594815.validator(path, query, header, formData, body)
  let scheme = call_594815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594815.url(scheme.get, call_594815.host, call_594815.base,
                         call_594815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594815, url, valid)

proc call*(call_594816: Call_PostDisableAvailabilityZonesForLoadBalancer_594801;
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
  var query_594817 = newJObject()
  var formData_594818 = newJObject()
  add(query_594817, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_594818.add "AvailabilityZones", AvailabilityZones
  add(formData_594818, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594817, "Version", newJString(Version))
  result = call_594816.call(nil, query_594817, nil, formData_594818, nil)

var postDisableAvailabilityZonesForLoadBalancer* = Call_PostDisableAvailabilityZonesForLoadBalancer_594801(
    name: "postDisableAvailabilityZonesForLoadBalancer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_PostDisableAvailabilityZonesForLoadBalancer_594802,
    base: "/", url: url_PostDisableAvailabilityZonesForLoadBalancer_594803,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAvailabilityZonesForLoadBalancer_594784 = ref object of OpenApiRestCall_593437
proc url_GetDisableAvailabilityZonesForLoadBalancer_594786(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDisableAvailabilityZonesForLoadBalancer_594785(path: JsonNode;
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
  var valid_594787 = query.getOrDefault("LoadBalancerName")
  valid_594787 = validateParameter(valid_594787, JString, required = true,
                                 default = nil)
  if valid_594787 != nil:
    section.add "LoadBalancerName", valid_594787
  var valid_594788 = query.getOrDefault("AvailabilityZones")
  valid_594788 = validateParameter(valid_594788, JArray, required = true, default = nil)
  if valid_594788 != nil:
    section.add "AvailabilityZones", valid_594788
  var valid_594789 = query.getOrDefault("Action")
  valid_594789 = validateParameter(valid_594789, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_594789 != nil:
    section.add "Action", valid_594789
  var valid_594790 = query.getOrDefault("Version")
  valid_594790 = validateParameter(valid_594790, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594790 != nil:
    section.add "Version", valid_594790
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
  var valid_594791 = header.getOrDefault("X-Amz-Date")
  valid_594791 = validateParameter(valid_594791, JString, required = false,
                                 default = nil)
  if valid_594791 != nil:
    section.add "X-Amz-Date", valid_594791
  var valid_594792 = header.getOrDefault("X-Amz-Security-Token")
  valid_594792 = validateParameter(valid_594792, JString, required = false,
                                 default = nil)
  if valid_594792 != nil:
    section.add "X-Amz-Security-Token", valid_594792
  var valid_594793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594793 = validateParameter(valid_594793, JString, required = false,
                                 default = nil)
  if valid_594793 != nil:
    section.add "X-Amz-Content-Sha256", valid_594793
  var valid_594794 = header.getOrDefault("X-Amz-Algorithm")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-Algorithm", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-Signature")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Signature", valid_594795
  var valid_594796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-SignedHeaders", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Credential")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Credential", valid_594797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594798: Call_GetDisableAvailabilityZonesForLoadBalancer_594784;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594798.validator(path, query, header, formData, body)
  let scheme = call_594798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594798.url(scheme.get, call_594798.host, call_594798.base,
                         call_594798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594798, url, valid)

proc call*(call_594799: Call_GetDisableAvailabilityZonesForLoadBalancer_594784;
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
  var query_594800 = newJObject()
  add(query_594800, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_594800.add "AvailabilityZones", AvailabilityZones
  add(query_594800, "Action", newJString(Action))
  add(query_594800, "Version", newJString(Version))
  result = call_594799.call(nil, query_594800, nil, nil, nil)

var getDisableAvailabilityZonesForLoadBalancer* = Call_GetDisableAvailabilityZonesForLoadBalancer_594784(
    name: "getDisableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_GetDisableAvailabilityZonesForLoadBalancer_594785,
    base: "/", url: url_GetDisableAvailabilityZonesForLoadBalancer_594786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAvailabilityZonesForLoadBalancer_594836 = ref object of OpenApiRestCall_593437
proc url_PostEnableAvailabilityZonesForLoadBalancer_594838(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostEnableAvailabilityZonesForLoadBalancer_594837(path: JsonNode;
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
  var valid_594839 = query.getOrDefault("Action")
  valid_594839 = validateParameter(valid_594839, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_594839 != nil:
    section.add "Action", valid_594839
  var valid_594840 = query.getOrDefault("Version")
  valid_594840 = validateParameter(valid_594840, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594840 != nil:
    section.add "Version", valid_594840
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
  var valid_594841 = header.getOrDefault("X-Amz-Date")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-Date", valid_594841
  var valid_594842 = header.getOrDefault("X-Amz-Security-Token")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Security-Token", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-Content-Sha256", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-Algorithm")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-Algorithm", valid_594844
  var valid_594845 = header.getOrDefault("X-Amz-Signature")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Signature", valid_594845
  var valid_594846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-SignedHeaders", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-Credential")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-Credential", valid_594847
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_594848 = formData.getOrDefault("AvailabilityZones")
  valid_594848 = validateParameter(valid_594848, JArray, required = true, default = nil)
  if valid_594848 != nil:
    section.add "AvailabilityZones", valid_594848
  var valid_594849 = formData.getOrDefault("LoadBalancerName")
  valid_594849 = validateParameter(valid_594849, JString, required = true,
                                 default = nil)
  if valid_594849 != nil:
    section.add "LoadBalancerName", valid_594849
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594850: Call_PostEnableAvailabilityZonesForLoadBalancer_594836;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594850.validator(path, query, header, formData, body)
  let scheme = call_594850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594850.url(scheme.get, call_594850.host, call_594850.base,
                         call_594850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594850, url, valid)

proc call*(call_594851: Call_PostEnableAvailabilityZonesForLoadBalancer_594836;
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
  var query_594852 = newJObject()
  var formData_594853 = newJObject()
  add(query_594852, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_594853.add "AvailabilityZones", AvailabilityZones
  add(formData_594853, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594852, "Version", newJString(Version))
  result = call_594851.call(nil, query_594852, nil, formData_594853, nil)

var postEnableAvailabilityZonesForLoadBalancer* = Call_PostEnableAvailabilityZonesForLoadBalancer_594836(
    name: "postEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_PostEnableAvailabilityZonesForLoadBalancer_594837,
    base: "/", url: url_PostEnableAvailabilityZonesForLoadBalancer_594838,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAvailabilityZonesForLoadBalancer_594819 = ref object of OpenApiRestCall_593437
proc url_GetEnableAvailabilityZonesForLoadBalancer_594821(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetEnableAvailabilityZonesForLoadBalancer_594820(path: JsonNode;
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
  var valid_594822 = query.getOrDefault("LoadBalancerName")
  valid_594822 = validateParameter(valid_594822, JString, required = true,
                                 default = nil)
  if valid_594822 != nil:
    section.add "LoadBalancerName", valid_594822
  var valid_594823 = query.getOrDefault("AvailabilityZones")
  valid_594823 = validateParameter(valid_594823, JArray, required = true, default = nil)
  if valid_594823 != nil:
    section.add "AvailabilityZones", valid_594823
  var valid_594824 = query.getOrDefault("Action")
  valid_594824 = validateParameter(valid_594824, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_594824 != nil:
    section.add "Action", valid_594824
  var valid_594825 = query.getOrDefault("Version")
  valid_594825 = validateParameter(valid_594825, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594825 != nil:
    section.add "Version", valid_594825
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
  var valid_594826 = header.getOrDefault("X-Amz-Date")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "X-Amz-Date", valid_594826
  var valid_594827 = header.getOrDefault("X-Amz-Security-Token")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Security-Token", valid_594827
  var valid_594828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594828 = validateParameter(valid_594828, JString, required = false,
                                 default = nil)
  if valid_594828 != nil:
    section.add "X-Amz-Content-Sha256", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-Algorithm")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-Algorithm", valid_594829
  var valid_594830 = header.getOrDefault("X-Amz-Signature")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Signature", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-SignedHeaders", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-Credential")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-Credential", valid_594832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594833: Call_GetEnableAvailabilityZonesForLoadBalancer_594819;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594833.validator(path, query, header, formData, body)
  let scheme = call_594833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594833.url(scheme.get, call_594833.host, call_594833.base,
                         call_594833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594833, url, valid)

proc call*(call_594834: Call_GetEnableAvailabilityZonesForLoadBalancer_594819;
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
  var query_594835 = newJObject()
  add(query_594835, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_594835.add "AvailabilityZones", AvailabilityZones
  add(query_594835, "Action", newJString(Action))
  add(query_594835, "Version", newJString(Version))
  result = call_594834.call(nil, query_594835, nil, nil, nil)

var getEnableAvailabilityZonesForLoadBalancer* = Call_GetEnableAvailabilityZonesForLoadBalancer_594819(
    name: "getEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_GetEnableAvailabilityZonesForLoadBalancer_594820,
    base: "/", url: url_GetEnableAvailabilityZonesForLoadBalancer_594821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_594875 = ref object of OpenApiRestCall_593437
proc url_PostModifyLoadBalancerAttributes_594877(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyLoadBalancerAttributes_594876(path: JsonNode;
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
  var valid_594878 = query.getOrDefault("Action")
  valid_594878 = validateParameter(valid_594878, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_594878 != nil:
    section.add "Action", valid_594878
  var valid_594879 = query.getOrDefault("Version")
  valid_594879 = validateParameter(valid_594879, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594879 != nil:
    section.add "Version", valid_594879
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
  var valid_594880 = header.getOrDefault("X-Amz-Date")
  valid_594880 = validateParameter(valid_594880, JString, required = false,
                                 default = nil)
  if valid_594880 != nil:
    section.add "X-Amz-Date", valid_594880
  var valid_594881 = header.getOrDefault("X-Amz-Security-Token")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Security-Token", valid_594881
  var valid_594882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594882 = validateParameter(valid_594882, JString, required = false,
                                 default = nil)
  if valid_594882 != nil:
    section.add "X-Amz-Content-Sha256", valid_594882
  var valid_594883 = header.getOrDefault("X-Amz-Algorithm")
  valid_594883 = validateParameter(valid_594883, JString, required = false,
                                 default = nil)
  if valid_594883 != nil:
    section.add "X-Amz-Algorithm", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Signature")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Signature", valid_594884
  var valid_594885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "X-Amz-SignedHeaders", valid_594885
  var valid_594886 = header.getOrDefault("X-Amz-Credential")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-Credential", valid_594886
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
  var valid_594887 = formData.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_594887 = validateParameter(valid_594887, JArray, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_594887
  var valid_594888 = formData.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_594888 = validateParameter(valid_594888, JString, required = false,
                                 default = nil)
  if valid_594888 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_594888
  var valid_594889 = formData.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_594889 = validateParameter(valid_594889, JString, required = false,
                                 default = nil)
  if valid_594889 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_594889
  var valid_594890 = formData.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_594890 = validateParameter(valid_594890, JString, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_594890
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_594891 = formData.getOrDefault("LoadBalancerName")
  valid_594891 = validateParameter(valid_594891, JString, required = true,
                                 default = nil)
  if valid_594891 != nil:
    section.add "LoadBalancerName", valid_594891
  var valid_594892 = formData.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_594892 = validateParameter(valid_594892, JString, required = false,
                                 default = nil)
  if valid_594892 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_594892
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594893: Call_PostModifyLoadBalancerAttributes_594875;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_594893.validator(path, query, header, formData, body)
  let scheme = call_594893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594893.url(scheme.get, call_594893.host, call_594893.base,
                         call_594893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594893, url, valid)

proc call*(call_594894: Call_PostModifyLoadBalancerAttributes_594875;
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
  var query_594895 = newJObject()
  var formData_594896 = newJObject()
  if LoadBalancerAttributesAdditionalAttributes != nil:
    formData_594896.add "LoadBalancerAttributes.AdditionalAttributes",
                       LoadBalancerAttributesAdditionalAttributes
  add(formData_594896, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  add(formData_594896, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_594895, "Action", newJString(Action))
  add(formData_594896, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(formData_594896, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_594896, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_594895, "Version", newJString(Version))
  result = call_594894.call(nil, query_594895, nil, formData_594896, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_594875(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_594876, base: "/",
    url: url_PostModifyLoadBalancerAttributes_594877,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_594854 = ref object of OpenApiRestCall_593437
proc url_GetModifyLoadBalancerAttributes_594856(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyLoadBalancerAttributes_594855(path: JsonNode;
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
  var valid_594857 = query.getOrDefault("LoadBalancerName")
  valid_594857 = validateParameter(valid_594857, JString, required = true,
                                 default = nil)
  if valid_594857 != nil:
    section.add "LoadBalancerName", valid_594857
  var valid_594858 = query.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_594858 = validateParameter(valid_594858, JString, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_594858
  var valid_594859 = query.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_594859
  var valid_594860 = query.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_594860 = validateParameter(valid_594860, JArray, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_594860
  var valid_594861 = query.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_594861
  var valid_594862 = query.getOrDefault("Action")
  valid_594862 = validateParameter(valid_594862, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_594862 != nil:
    section.add "Action", valid_594862
  var valid_594863 = query.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_594863
  var valid_594864 = query.getOrDefault("Version")
  valid_594864 = validateParameter(valid_594864, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594864 != nil:
    section.add "Version", valid_594864
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
  var valid_594865 = header.getOrDefault("X-Amz-Date")
  valid_594865 = validateParameter(valid_594865, JString, required = false,
                                 default = nil)
  if valid_594865 != nil:
    section.add "X-Amz-Date", valid_594865
  var valid_594866 = header.getOrDefault("X-Amz-Security-Token")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "X-Amz-Security-Token", valid_594866
  var valid_594867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-Content-Sha256", valid_594867
  var valid_594868 = header.getOrDefault("X-Amz-Algorithm")
  valid_594868 = validateParameter(valid_594868, JString, required = false,
                                 default = nil)
  if valid_594868 != nil:
    section.add "X-Amz-Algorithm", valid_594868
  var valid_594869 = header.getOrDefault("X-Amz-Signature")
  valid_594869 = validateParameter(valid_594869, JString, required = false,
                                 default = nil)
  if valid_594869 != nil:
    section.add "X-Amz-Signature", valid_594869
  var valid_594870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594870 = validateParameter(valid_594870, JString, required = false,
                                 default = nil)
  if valid_594870 != nil:
    section.add "X-Amz-SignedHeaders", valid_594870
  var valid_594871 = header.getOrDefault("X-Amz-Credential")
  valid_594871 = validateParameter(valid_594871, JString, required = false,
                                 default = nil)
  if valid_594871 != nil:
    section.add "X-Amz-Credential", valid_594871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594872: Call_GetModifyLoadBalancerAttributes_594854;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_594872.validator(path, query, header, formData, body)
  let scheme = call_594872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594872.url(scheme.get, call_594872.host, call_594872.base,
                         call_594872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594872, url, valid)

proc call*(call_594873: Call_GetModifyLoadBalancerAttributes_594854;
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
  var query_594874 = newJObject()
  add(query_594874, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594874, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_594874, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    query_594874.add "LoadBalancerAttributes.AdditionalAttributes",
                    LoadBalancerAttributesAdditionalAttributes
  add(query_594874, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_594874, "Action", newJString(Action))
  add(query_594874, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_594874, "Version", newJString(Version))
  result = call_594873.call(nil, query_594874, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_594854(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_594855, base: "/",
    url: url_GetModifyLoadBalancerAttributes_594856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterInstancesWithLoadBalancer_594914 = ref object of OpenApiRestCall_593437
proc url_PostRegisterInstancesWithLoadBalancer_594916(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRegisterInstancesWithLoadBalancer_594915(path: JsonNode;
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
  var valid_594917 = query.getOrDefault("Action")
  valid_594917 = validateParameter(valid_594917, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_594917 != nil:
    section.add "Action", valid_594917
  var valid_594918 = query.getOrDefault("Version")
  valid_594918 = validateParameter(valid_594918, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594918 != nil:
    section.add "Version", valid_594918
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
  var valid_594919 = header.getOrDefault("X-Amz-Date")
  valid_594919 = validateParameter(valid_594919, JString, required = false,
                                 default = nil)
  if valid_594919 != nil:
    section.add "X-Amz-Date", valid_594919
  var valid_594920 = header.getOrDefault("X-Amz-Security-Token")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "X-Amz-Security-Token", valid_594920
  var valid_594921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594921 = validateParameter(valid_594921, JString, required = false,
                                 default = nil)
  if valid_594921 != nil:
    section.add "X-Amz-Content-Sha256", valid_594921
  var valid_594922 = header.getOrDefault("X-Amz-Algorithm")
  valid_594922 = validateParameter(valid_594922, JString, required = false,
                                 default = nil)
  if valid_594922 != nil:
    section.add "X-Amz-Algorithm", valid_594922
  var valid_594923 = header.getOrDefault("X-Amz-Signature")
  valid_594923 = validateParameter(valid_594923, JString, required = false,
                                 default = nil)
  if valid_594923 != nil:
    section.add "X-Amz-Signature", valid_594923
  var valid_594924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594924 = validateParameter(valid_594924, JString, required = false,
                                 default = nil)
  if valid_594924 != nil:
    section.add "X-Amz-SignedHeaders", valid_594924
  var valid_594925 = header.getOrDefault("X-Amz-Credential")
  valid_594925 = validateParameter(valid_594925, JString, required = false,
                                 default = nil)
  if valid_594925 != nil:
    section.add "X-Amz-Credential", valid_594925
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_594926 = formData.getOrDefault("Instances")
  valid_594926 = validateParameter(valid_594926, JArray, required = true, default = nil)
  if valid_594926 != nil:
    section.add "Instances", valid_594926
  var valid_594927 = formData.getOrDefault("LoadBalancerName")
  valid_594927 = validateParameter(valid_594927, JString, required = true,
                                 default = nil)
  if valid_594927 != nil:
    section.add "LoadBalancerName", valid_594927
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594928: Call_PostRegisterInstancesWithLoadBalancer_594914;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594928.validator(path, query, header, formData, body)
  let scheme = call_594928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594928.url(scheme.get, call_594928.host, call_594928.base,
                         call_594928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594928, url, valid)

proc call*(call_594929: Call_PostRegisterInstancesWithLoadBalancer_594914;
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
  var query_594930 = newJObject()
  var formData_594931 = newJObject()
  if Instances != nil:
    formData_594931.add "Instances", Instances
  add(query_594930, "Action", newJString(Action))
  add(formData_594931, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594930, "Version", newJString(Version))
  result = call_594929.call(nil, query_594930, nil, formData_594931, nil)

var postRegisterInstancesWithLoadBalancer* = Call_PostRegisterInstancesWithLoadBalancer_594914(
    name: "postRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_PostRegisterInstancesWithLoadBalancer_594915, base: "/",
    url: url_PostRegisterInstancesWithLoadBalancer_594916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterInstancesWithLoadBalancer_594897 = ref object of OpenApiRestCall_593437
proc url_GetRegisterInstancesWithLoadBalancer_594899(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRegisterInstancesWithLoadBalancer_594898(path: JsonNode;
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
  var valid_594900 = query.getOrDefault("LoadBalancerName")
  valid_594900 = validateParameter(valid_594900, JString, required = true,
                                 default = nil)
  if valid_594900 != nil:
    section.add "LoadBalancerName", valid_594900
  var valid_594901 = query.getOrDefault("Action")
  valid_594901 = validateParameter(valid_594901, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_594901 != nil:
    section.add "Action", valid_594901
  var valid_594902 = query.getOrDefault("Instances")
  valid_594902 = validateParameter(valid_594902, JArray, required = true, default = nil)
  if valid_594902 != nil:
    section.add "Instances", valid_594902
  var valid_594903 = query.getOrDefault("Version")
  valid_594903 = validateParameter(valid_594903, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594903 != nil:
    section.add "Version", valid_594903
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
  var valid_594904 = header.getOrDefault("X-Amz-Date")
  valid_594904 = validateParameter(valid_594904, JString, required = false,
                                 default = nil)
  if valid_594904 != nil:
    section.add "X-Amz-Date", valid_594904
  var valid_594905 = header.getOrDefault("X-Amz-Security-Token")
  valid_594905 = validateParameter(valid_594905, JString, required = false,
                                 default = nil)
  if valid_594905 != nil:
    section.add "X-Amz-Security-Token", valid_594905
  var valid_594906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "X-Amz-Content-Sha256", valid_594906
  var valid_594907 = header.getOrDefault("X-Amz-Algorithm")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "X-Amz-Algorithm", valid_594907
  var valid_594908 = header.getOrDefault("X-Amz-Signature")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "X-Amz-Signature", valid_594908
  var valid_594909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "X-Amz-SignedHeaders", valid_594909
  var valid_594910 = header.getOrDefault("X-Amz-Credential")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-Credential", valid_594910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594911: Call_GetRegisterInstancesWithLoadBalancer_594897;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594911.validator(path, query, header, formData, body)
  let scheme = call_594911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594911.url(scheme.get, call_594911.host, call_594911.base,
                         call_594911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594911, url, valid)

proc call*(call_594912: Call_GetRegisterInstancesWithLoadBalancer_594897;
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
  var query_594913 = newJObject()
  add(query_594913, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594913, "Action", newJString(Action))
  if Instances != nil:
    query_594913.add "Instances", Instances
  add(query_594913, "Version", newJString(Version))
  result = call_594912.call(nil, query_594913, nil, nil, nil)

var getRegisterInstancesWithLoadBalancer* = Call_GetRegisterInstancesWithLoadBalancer_594897(
    name: "getRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_GetRegisterInstancesWithLoadBalancer_594898, base: "/",
    url: url_GetRegisterInstancesWithLoadBalancer_594899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_594949 = ref object of OpenApiRestCall_593437
proc url_PostRemoveTags_594951(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTags_594950(path: JsonNode; query: JsonNode;
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
  var valid_594952 = query.getOrDefault("Action")
  valid_594952 = validateParameter(valid_594952, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_594952 != nil:
    section.add "Action", valid_594952
  var valid_594953 = query.getOrDefault("Version")
  valid_594953 = validateParameter(valid_594953, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594953 != nil:
    section.add "Version", valid_594953
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
  var valid_594954 = header.getOrDefault("X-Amz-Date")
  valid_594954 = validateParameter(valid_594954, JString, required = false,
                                 default = nil)
  if valid_594954 != nil:
    section.add "X-Amz-Date", valid_594954
  var valid_594955 = header.getOrDefault("X-Amz-Security-Token")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "X-Amz-Security-Token", valid_594955
  var valid_594956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Content-Sha256", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-Algorithm")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Algorithm", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-Signature")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-Signature", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-SignedHeaders", valid_594959
  var valid_594960 = header.getOrDefault("X-Amz-Credential")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-Credential", valid_594960
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_594961 = formData.getOrDefault("Tags")
  valid_594961 = validateParameter(valid_594961, JArray, required = true, default = nil)
  if valid_594961 != nil:
    section.add "Tags", valid_594961
  var valid_594962 = formData.getOrDefault("LoadBalancerNames")
  valid_594962 = validateParameter(valid_594962, JArray, required = true, default = nil)
  if valid_594962 != nil:
    section.add "LoadBalancerNames", valid_594962
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594963: Call_PostRemoveTags_594949; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_594963.validator(path, query, header, formData, body)
  let scheme = call_594963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594963.url(scheme.get, call_594963.host, call_594963.base,
                         call_594963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594963, url, valid)

proc call*(call_594964: Call_PostRemoveTags_594949; Tags: JsonNode;
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
  var query_594965 = newJObject()
  var formData_594966 = newJObject()
  if Tags != nil:
    formData_594966.add "Tags", Tags
  add(query_594965, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_594966.add "LoadBalancerNames", LoadBalancerNames
  add(query_594965, "Version", newJString(Version))
  result = call_594964.call(nil, query_594965, nil, formData_594966, nil)

var postRemoveTags* = Call_PostRemoveTags_594949(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_594950,
    base: "/", url: url_PostRemoveTags_594951, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_594932 = ref object of OpenApiRestCall_593437
proc url_GetRemoveTags_594934(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTags_594933(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594935 = query.getOrDefault("Tags")
  valid_594935 = validateParameter(valid_594935, JArray, required = true, default = nil)
  if valid_594935 != nil:
    section.add "Tags", valid_594935
  var valid_594936 = query.getOrDefault("Action")
  valid_594936 = validateParameter(valid_594936, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_594936 != nil:
    section.add "Action", valid_594936
  var valid_594937 = query.getOrDefault("LoadBalancerNames")
  valid_594937 = validateParameter(valid_594937, JArray, required = true, default = nil)
  if valid_594937 != nil:
    section.add "LoadBalancerNames", valid_594937
  var valid_594938 = query.getOrDefault("Version")
  valid_594938 = validateParameter(valid_594938, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594938 != nil:
    section.add "Version", valid_594938
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
  var valid_594939 = header.getOrDefault("X-Amz-Date")
  valid_594939 = validateParameter(valid_594939, JString, required = false,
                                 default = nil)
  if valid_594939 != nil:
    section.add "X-Amz-Date", valid_594939
  var valid_594940 = header.getOrDefault("X-Amz-Security-Token")
  valid_594940 = validateParameter(valid_594940, JString, required = false,
                                 default = nil)
  if valid_594940 != nil:
    section.add "X-Amz-Security-Token", valid_594940
  var valid_594941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "X-Amz-Content-Sha256", valid_594941
  var valid_594942 = header.getOrDefault("X-Amz-Algorithm")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "X-Amz-Algorithm", valid_594942
  var valid_594943 = header.getOrDefault("X-Amz-Signature")
  valid_594943 = validateParameter(valid_594943, JString, required = false,
                                 default = nil)
  if valid_594943 != nil:
    section.add "X-Amz-Signature", valid_594943
  var valid_594944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "X-Amz-SignedHeaders", valid_594944
  var valid_594945 = header.getOrDefault("X-Amz-Credential")
  valid_594945 = validateParameter(valid_594945, JString, required = false,
                                 default = nil)
  if valid_594945 != nil:
    section.add "X-Amz-Credential", valid_594945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594946: Call_GetRemoveTags_594932; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_594946.validator(path, query, header, formData, body)
  let scheme = call_594946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594946.url(scheme.get, call_594946.host, call_594946.base,
                         call_594946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594946, url, valid)

proc call*(call_594947: Call_GetRemoveTags_594932; Tags: JsonNode;
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
  var query_594948 = newJObject()
  if Tags != nil:
    query_594948.add "Tags", Tags
  add(query_594948, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_594948.add "LoadBalancerNames", LoadBalancerNames
  add(query_594948, "Version", newJString(Version))
  result = call_594947.call(nil, query_594948, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_594932(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_594933,
    base: "/", url: url_GetRemoveTags_594934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerListenerSSLCertificate_594985 = ref object of OpenApiRestCall_593437
proc url_PostSetLoadBalancerListenerSSLCertificate_594987(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetLoadBalancerListenerSSLCertificate_594986(path: JsonNode;
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
  var valid_594988 = query.getOrDefault("Action")
  valid_594988 = validateParameter(valid_594988, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_594988 != nil:
    section.add "Action", valid_594988
  var valid_594989 = query.getOrDefault("Version")
  valid_594989 = validateParameter(valid_594989, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594989 != nil:
    section.add "Version", valid_594989
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
  var valid_594990 = header.getOrDefault("X-Amz-Date")
  valid_594990 = validateParameter(valid_594990, JString, required = false,
                                 default = nil)
  if valid_594990 != nil:
    section.add "X-Amz-Date", valid_594990
  var valid_594991 = header.getOrDefault("X-Amz-Security-Token")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "X-Amz-Security-Token", valid_594991
  var valid_594992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "X-Amz-Content-Sha256", valid_594992
  var valid_594993 = header.getOrDefault("X-Amz-Algorithm")
  valid_594993 = validateParameter(valid_594993, JString, required = false,
                                 default = nil)
  if valid_594993 != nil:
    section.add "X-Amz-Algorithm", valid_594993
  var valid_594994 = header.getOrDefault("X-Amz-Signature")
  valid_594994 = validateParameter(valid_594994, JString, required = false,
                                 default = nil)
  if valid_594994 != nil:
    section.add "X-Amz-Signature", valid_594994
  var valid_594995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594995 = validateParameter(valid_594995, JString, required = false,
                                 default = nil)
  if valid_594995 != nil:
    section.add "X-Amz-SignedHeaders", valid_594995
  var valid_594996 = header.getOrDefault("X-Amz-Credential")
  valid_594996 = validateParameter(valid_594996, JString, required = false,
                                 default = nil)
  if valid_594996 != nil:
    section.add "X-Amz-Credential", valid_594996
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
  var valid_594997 = formData.getOrDefault("LoadBalancerPort")
  valid_594997 = validateParameter(valid_594997, JInt, required = true, default = nil)
  if valid_594997 != nil:
    section.add "LoadBalancerPort", valid_594997
  var valid_594998 = formData.getOrDefault("SSLCertificateId")
  valid_594998 = validateParameter(valid_594998, JString, required = true,
                                 default = nil)
  if valid_594998 != nil:
    section.add "SSLCertificateId", valid_594998
  var valid_594999 = formData.getOrDefault("LoadBalancerName")
  valid_594999 = validateParameter(valid_594999, JString, required = true,
                                 default = nil)
  if valid_594999 != nil:
    section.add "LoadBalancerName", valid_594999
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595000: Call_PostSetLoadBalancerListenerSSLCertificate_594985;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_595000.validator(path, query, header, formData, body)
  let scheme = call_595000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595000.url(scheme.get, call_595000.host, call_595000.base,
                         call_595000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595000, url, valid)

proc call*(call_595001: Call_PostSetLoadBalancerListenerSSLCertificate_594985;
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
  var query_595002 = newJObject()
  var formData_595003 = newJObject()
  add(formData_595003, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(formData_595003, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_595002, "Action", newJString(Action))
  add(formData_595003, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_595002, "Version", newJString(Version))
  result = call_595001.call(nil, query_595002, nil, formData_595003, nil)

var postSetLoadBalancerListenerSSLCertificate* = Call_PostSetLoadBalancerListenerSSLCertificate_594985(
    name: "postSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_PostSetLoadBalancerListenerSSLCertificate_594986,
    base: "/", url: url_PostSetLoadBalancerListenerSSLCertificate_594987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerListenerSSLCertificate_594967 = ref object of OpenApiRestCall_593437
proc url_GetSetLoadBalancerListenerSSLCertificate_594969(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetLoadBalancerListenerSSLCertificate_594968(path: JsonNode;
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
  var valid_594970 = query.getOrDefault("LoadBalancerName")
  valid_594970 = validateParameter(valid_594970, JString, required = true,
                                 default = nil)
  if valid_594970 != nil:
    section.add "LoadBalancerName", valid_594970
  var valid_594971 = query.getOrDefault("SSLCertificateId")
  valid_594971 = validateParameter(valid_594971, JString, required = true,
                                 default = nil)
  if valid_594971 != nil:
    section.add "SSLCertificateId", valid_594971
  var valid_594972 = query.getOrDefault("LoadBalancerPort")
  valid_594972 = validateParameter(valid_594972, JInt, required = true, default = nil)
  if valid_594972 != nil:
    section.add "LoadBalancerPort", valid_594972
  var valid_594973 = query.getOrDefault("Action")
  valid_594973 = validateParameter(valid_594973, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_594973 != nil:
    section.add "Action", valid_594973
  var valid_594974 = query.getOrDefault("Version")
  valid_594974 = validateParameter(valid_594974, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_594974 != nil:
    section.add "Version", valid_594974
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
  var valid_594975 = header.getOrDefault("X-Amz-Date")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "X-Amz-Date", valid_594975
  var valid_594976 = header.getOrDefault("X-Amz-Security-Token")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-Security-Token", valid_594976
  var valid_594977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "X-Amz-Content-Sha256", valid_594977
  var valid_594978 = header.getOrDefault("X-Amz-Algorithm")
  valid_594978 = validateParameter(valid_594978, JString, required = false,
                                 default = nil)
  if valid_594978 != nil:
    section.add "X-Amz-Algorithm", valid_594978
  var valid_594979 = header.getOrDefault("X-Amz-Signature")
  valid_594979 = validateParameter(valid_594979, JString, required = false,
                                 default = nil)
  if valid_594979 != nil:
    section.add "X-Amz-Signature", valid_594979
  var valid_594980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594980 = validateParameter(valid_594980, JString, required = false,
                                 default = nil)
  if valid_594980 != nil:
    section.add "X-Amz-SignedHeaders", valid_594980
  var valid_594981 = header.getOrDefault("X-Amz-Credential")
  valid_594981 = validateParameter(valid_594981, JString, required = false,
                                 default = nil)
  if valid_594981 != nil:
    section.add "X-Amz-Credential", valid_594981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594982: Call_GetSetLoadBalancerListenerSSLCertificate_594967;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_594982.validator(path, query, header, formData, body)
  let scheme = call_594982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594982.url(scheme.get, call_594982.host, call_594982.base,
                         call_594982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594982, url, valid)

proc call*(call_594983: Call_GetSetLoadBalancerListenerSSLCertificate_594967;
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
  var query_594984 = newJObject()
  add(query_594984, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_594984, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_594984, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_594984, "Action", newJString(Action))
  add(query_594984, "Version", newJString(Version))
  result = call_594983.call(nil, query_594984, nil, nil, nil)

var getSetLoadBalancerListenerSSLCertificate* = Call_GetSetLoadBalancerListenerSSLCertificate_594967(
    name: "getSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_GetSetLoadBalancerListenerSSLCertificate_594968,
    base: "/", url: url_GetSetLoadBalancerListenerSSLCertificate_594969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesForBackendServer_595022 = ref object of OpenApiRestCall_593437
proc url_PostSetLoadBalancerPoliciesForBackendServer_595024(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetLoadBalancerPoliciesForBackendServer_595023(path: JsonNode;
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
  var valid_595025 = query.getOrDefault("Action")
  valid_595025 = validateParameter(valid_595025, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_595025 != nil:
    section.add "Action", valid_595025
  var valid_595026 = query.getOrDefault("Version")
  valid_595026 = validateParameter(valid_595026, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_595026 != nil:
    section.add "Version", valid_595026
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
  var valid_595027 = header.getOrDefault("X-Amz-Date")
  valid_595027 = validateParameter(valid_595027, JString, required = false,
                                 default = nil)
  if valid_595027 != nil:
    section.add "X-Amz-Date", valid_595027
  var valid_595028 = header.getOrDefault("X-Amz-Security-Token")
  valid_595028 = validateParameter(valid_595028, JString, required = false,
                                 default = nil)
  if valid_595028 != nil:
    section.add "X-Amz-Security-Token", valid_595028
  var valid_595029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595029 = validateParameter(valid_595029, JString, required = false,
                                 default = nil)
  if valid_595029 != nil:
    section.add "X-Amz-Content-Sha256", valid_595029
  var valid_595030 = header.getOrDefault("X-Amz-Algorithm")
  valid_595030 = validateParameter(valid_595030, JString, required = false,
                                 default = nil)
  if valid_595030 != nil:
    section.add "X-Amz-Algorithm", valid_595030
  var valid_595031 = header.getOrDefault("X-Amz-Signature")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "X-Amz-Signature", valid_595031
  var valid_595032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "X-Amz-SignedHeaders", valid_595032
  var valid_595033 = header.getOrDefault("X-Amz-Credential")
  valid_595033 = validateParameter(valid_595033, JString, required = false,
                                 default = nil)
  if valid_595033 != nil:
    section.add "X-Amz-Credential", valid_595033
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
  var valid_595034 = formData.getOrDefault("PolicyNames")
  valid_595034 = validateParameter(valid_595034, JArray, required = true, default = nil)
  if valid_595034 != nil:
    section.add "PolicyNames", valid_595034
  var valid_595035 = formData.getOrDefault("InstancePort")
  valid_595035 = validateParameter(valid_595035, JInt, required = true, default = nil)
  if valid_595035 != nil:
    section.add "InstancePort", valid_595035
  var valid_595036 = formData.getOrDefault("LoadBalancerName")
  valid_595036 = validateParameter(valid_595036, JString, required = true,
                                 default = nil)
  if valid_595036 != nil:
    section.add "LoadBalancerName", valid_595036
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595037: Call_PostSetLoadBalancerPoliciesForBackendServer_595022;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_595037.validator(path, query, header, formData, body)
  let scheme = call_595037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595037.url(scheme.get, call_595037.host, call_595037.base,
                         call_595037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595037, url, valid)

proc call*(call_595038: Call_PostSetLoadBalancerPoliciesForBackendServer_595022;
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
  var query_595039 = newJObject()
  var formData_595040 = newJObject()
  if PolicyNames != nil:
    formData_595040.add "PolicyNames", PolicyNames
  add(formData_595040, "InstancePort", newJInt(InstancePort))
  add(query_595039, "Action", newJString(Action))
  add(formData_595040, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_595039, "Version", newJString(Version))
  result = call_595038.call(nil, query_595039, nil, formData_595040, nil)

var postSetLoadBalancerPoliciesForBackendServer* = Call_PostSetLoadBalancerPoliciesForBackendServer_595022(
    name: "postSetLoadBalancerPoliciesForBackendServer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_PostSetLoadBalancerPoliciesForBackendServer_595023,
    base: "/", url: url_PostSetLoadBalancerPoliciesForBackendServer_595024,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesForBackendServer_595004 = ref object of OpenApiRestCall_593437
proc url_GetSetLoadBalancerPoliciesForBackendServer_595006(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetLoadBalancerPoliciesForBackendServer_595005(path: JsonNode;
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
  var valid_595007 = query.getOrDefault("LoadBalancerName")
  valid_595007 = validateParameter(valid_595007, JString, required = true,
                                 default = nil)
  if valid_595007 != nil:
    section.add "LoadBalancerName", valid_595007
  var valid_595008 = query.getOrDefault("Action")
  valid_595008 = validateParameter(valid_595008, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_595008 != nil:
    section.add "Action", valid_595008
  var valid_595009 = query.getOrDefault("PolicyNames")
  valid_595009 = validateParameter(valid_595009, JArray, required = true, default = nil)
  if valid_595009 != nil:
    section.add "PolicyNames", valid_595009
  var valid_595010 = query.getOrDefault("Version")
  valid_595010 = validateParameter(valid_595010, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_595010 != nil:
    section.add "Version", valid_595010
  var valid_595011 = query.getOrDefault("InstancePort")
  valid_595011 = validateParameter(valid_595011, JInt, required = true, default = nil)
  if valid_595011 != nil:
    section.add "InstancePort", valid_595011
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
  var valid_595012 = header.getOrDefault("X-Amz-Date")
  valid_595012 = validateParameter(valid_595012, JString, required = false,
                                 default = nil)
  if valid_595012 != nil:
    section.add "X-Amz-Date", valid_595012
  var valid_595013 = header.getOrDefault("X-Amz-Security-Token")
  valid_595013 = validateParameter(valid_595013, JString, required = false,
                                 default = nil)
  if valid_595013 != nil:
    section.add "X-Amz-Security-Token", valid_595013
  var valid_595014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595014 = validateParameter(valid_595014, JString, required = false,
                                 default = nil)
  if valid_595014 != nil:
    section.add "X-Amz-Content-Sha256", valid_595014
  var valid_595015 = header.getOrDefault("X-Amz-Algorithm")
  valid_595015 = validateParameter(valid_595015, JString, required = false,
                                 default = nil)
  if valid_595015 != nil:
    section.add "X-Amz-Algorithm", valid_595015
  var valid_595016 = header.getOrDefault("X-Amz-Signature")
  valid_595016 = validateParameter(valid_595016, JString, required = false,
                                 default = nil)
  if valid_595016 != nil:
    section.add "X-Amz-Signature", valid_595016
  var valid_595017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595017 = validateParameter(valid_595017, JString, required = false,
                                 default = nil)
  if valid_595017 != nil:
    section.add "X-Amz-SignedHeaders", valid_595017
  var valid_595018 = header.getOrDefault("X-Amz-Credential")
  valid_595018 = validateParameter(valid_595018, JString, required = false,
                                 default = nil)
  if valid_595018 != nil:
    section.add "X-Amz-Credential", valid_595018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595019: Call_GetSetLoadBalancerPoliciesForBackendServer_595004;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_595019.validator(path, query, header, formData, body)
  let scheme = call_595019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595019.url(scheme.get, call_595019.host, call_595019.base,
                         call_595019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595019, url, valid)

proc call*(call_595020: Call_GetSetLoadBalancerPoliciesForBackendServer_595004;
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
  var query_595021 = newJObject()
  add(query_595021, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_595021, "Action", newJString(Action))
  if PolicyNames != nil:
    query_595021.add "PolicyNames", PolicyNames
  add(query_595021, "Version", newJString(Version))
  add(query_595021, "InstancePort", newJInt(InstancePort))
  result = call_595020.call(nil, query_595021, nil, nil, nil)

var getSetLoadBalancerPoliciesForBackendServer* = Call_GetSetLoadBalancerPoliciesForBackendServer_595004(
    name: "getSetLoadBalancerPoliciesForBackendServer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_GetSetLoadBalancerPoliciesForBackendServer_595005,
    base: "/", url: url_GetSetLoadBalancerPoliciesForBackendServer_595006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesOfListener_595059 = ref object of OpenApiRestCall_593437
proc url_PostSetLoadBalancerPoliciesOfListener_595061(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetLoadBalancerPoliciesOfListener_595060(path: JsonNode;
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
  var valid_595062 = query.getOrDefault("Action")
  valid_595062 = validateParameter(valid_595062, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_595062 != nil:
    section.add "Action", valid_595062
  var valid_595063 = query.getOrDefault("Version")
  valid_595063 = validateParameter(valid_595063, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_595063 != nil:
    section.add "Version", valid_595063
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
  var valid_595064 = header.getOrDefault("X-Amz-Date")
  valid_595064 = validateParameter(valid_595064, JString, required = false,
                                 default = nil)
  if valid_595064 != nil:
    section.add "X-Amz-Date", valid_595064
  var valid_595065 = header.getOrDefault("X-Amz-Security-Token")
  valid_595065 = validateParameter(valid_595065, JString, required = false,
                                 default = nil)
  if valid_595065 != nil:
    section.add "X-Amz-Security-Token", valid_595065
  var valid_595066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595066 = validateParameter(valid_595066, JString, required = false,
                                 default = nil)
  if valid_595066 != nil:
    section.add "X-Amz-Content-Sha256", valid_595066
  var valid_595067 = header.getOrDefault("X-Amz-Algorithm")
  valid_595067 = validateParameter(valid_595067, JString, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "X-Amz-Algorithm", valid_595067
  var valid_595068 = header.getOrDefault("X-Amz-Signature")
  valid_595068 = validateParameter(valid_595068, JString, required = false,
                                 default = nil)
  if valid_595068 != nil:
    section.add "X-Amz-Signature", valid_595068
  var valid_595069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595069 = validateParameter(valid_595069, JString, required = false,
                                 default = nil)
  if valid_595069 != nil:
    section.add "X-Amz-SignedHeaders", valid_595069
  var valid_595070 = header.getOrDefault("X-Amz-Credential")
  valid_595070 = validateParameter(valid_595070, JString, required = false,
                                 default = nil)
  if valid_595070 != nil:
    section.add "X-Amz-Credential", valid_595070
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
  var valid_595071 = formData.getOrDefault("LoadBalancerPort")
  valid_595071 = validateParameter(valid_595071, JInt, required = true, default = nil)
  if valid_595071 != nil:
    section.add "LoadBalancerPort", valid_595071
  var valid_595072 = formData.getOrDefault("PolicyNames")
  valid_595072 = validateParameter(valid_595072, JArray, required = true, default = nil)
  if valid_595072 != nil:
    section.add "PolicyNames", valid_595072
  var valid_595073 = formData.getOrDefault("LoadBalancerName")
  valid_595073 = validateParameter(valid_595073, JString, required = true,
                                 default = nil)
  if valid_595073 != nil:
    section.add "LoadBalancerName", valid_595073
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595074: Call_PostSetLoadBalancerPoliciesOfListener_595059;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_595074.validator(path, query, header, formData, body)
  let scheme = call_595074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595074.url(scheme.get, call_595074.host, call_595074.base,
                         call_595074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595074, url, valid)

proc call*(call_595075: Call_PostSetLoadBalancerPoliciesOfListener_595059;
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
  var query_595076 = newJObject()
  var formData_595077 = newJObject()
  add(formData_595077, "LoadBalancerPort", newJInt(LoadBalancerPort))
  if PolicyNames != nil:
    formData_595077.add "PolicyNames", PolicyNames
  add(query_595076, "Action", newJString(Action))
  add(formData_595077, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_595076, "Version", newJString(Version))
  result = call_595075.call(nil, query_595076, nil, formData_595077, nil)

var postSetLoadBalancerPoliciesOfListener* = Call_PostSetLoadBalancerPoliciesOfListener_595059(
    name: "postSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_PostSetLoadBalancerPoliciesOfListener_595060, base: "/",
    url: url_PostSetLoadBalancerPoliciesOfListener_595061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesOfListener_595041 = ref object of OpenApiRestCall_593437
proc url_GetSetLoadBalancerPoliciesOfListener_595043(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetLoadBalancerPoliciesOfListener_595042(path: JsonNode;
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
  var valid_595044 = query.getOrDefault("LoadBalancerName")
  valid_595044 = validateParameter(valid_595044, JString, required = true,
                                 default = nil)
  if valid_595044 != nil:
    section.add "LoadBalancerName", valid_595044
  var valid_595045 = query.getOrDefault("LoadBalancerPort")
  valid_595045 = validateParameter(valid_595045, JInt, required = true, default = nil)
  if valid_595045 != nil:
    section.add "LoadBalancerPort", valid_595045
  var valid_595046 = query.getOrDefault("Action")
  valid_595046 = validateParameter(valid_595046, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_595046 != nil:
    section.add "Action", valid_595046
  var valid_595047 = query.getOrDefault("PolicyNames")
  valid_595047 = validateParameter(valid_595047, JArray, required = true, default = nil)
  if valid_595047 != nil:
    section.add "PolicyNames", valid_595047
  var valid_595048 = query.getOrDefault("Version")
  valid_595048 = validateParameter(valid_595048, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_595048 != nil:
    section.add "Version", valid_595048
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
  var valid_595049 = header.getOrDefault("X-Amz-Date")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-Date", valid_595049
  var valid_595050 = header.getOrDefault("X-Amz-Security-Token")
  valid_595050 = validateParameter(valid_595050, JString, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "X-Amz-Security-Token", valid_595050
  var valid_595051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "X-Amz-Content-Sha256", valid_595051
  var valid_595052 = header.getOrDefault("X-Amz-Algorithm")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "X-Amz-Algorithm", valid_595052
  var valid_595053 = header.getOrDefault("X-Amz-Signature")
  valid_595053 = validateParameter(valid_595053, JString, required = false,
                                 default = nil)
  if valid_595053 != nil:
    section.add "X-Amz-Signature", valid_595053
  var valid_595054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595054 = validateParameter(valid_595054, JString, required = false,
                                 default = nil)
  if valid_595054 != nil:
    section.add "X-Amz-SignedHeaders", valid_595054
  var valid_595055 = header.getOrDefault("X-Amz-Credential")
  valid_595055 = validateParameter(valid_595055, JString, required = false,
                                 default = nil)
  if valid_595055 != nil:
    section.add "X-Amz-Credential", valid_595055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595056: Call_GetSetLoadBalancerPoliciesOfListener_595041;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_595056.validator(path, query, header, formData, body)
  let scheme = call_595056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595056.url(scheme.get, call_595056.host, call_595056.base,
                         call_595056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595056, url, valid)

proc call*(call_595057: Call_GetSetLoadBalancerPoliciesOfListener_595041;
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
  var query_595058 = newJObject()
  add(query_595058, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_595058, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_595058, "Action", newJString(Action))
  if PolicyNames != nil:
    query_595058.add "PolicyNames", PolicyNames
  add(query_595058, "Version", newJString(Version))
  result = call_595057.call(nil, query_595058, nil, nil, nil)

var getSetLoadBalancerPoliciesOfListener* = Call_GetSetLoadBalancerPoliciesOfListener_595041(
    name: "getSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_GetSetLoadBalancerPoliciesOfListener_595042, base: "/",
    url: url_GetSetLoadBalancerPoliciesOfListener_595043,
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
