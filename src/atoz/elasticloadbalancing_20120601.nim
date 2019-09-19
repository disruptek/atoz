
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAddTags_601040 = ref object of OpenApiRestCall_600426
proc url_PostAddTags_601042(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddTags_601041(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601043 = query.getOrDefault("Action")
  valid_601043 = validateParameter(valid_601043, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_601043 != nil:
    section.add "Action", valid_601043
  var valid_601044 = query.getOrDefault("Version")
  valid_601044 = validateParameter(valid_601044, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601044 != nil:
    section.add "Version", valid_601044
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
  var valid_601045 = header.getOrDefault("X-Amz-Date")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Date", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Security-Token")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Security-Token", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Content-Sha256", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Algorithm")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Algorithm", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Signature")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Signature", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-SignedHeaders", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Credential")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Credential", valid_601051
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_601052 = formData.getOrDefault("Tags")
  valid_601052 = validateParameter(valid_601052, JArray, required = true, default = nil)
  if valid_601052 != nil:
    section.add "Tags", valid_601052
  var valid_601053 = formData.getOrDefault("LoadBalancerNames")
  valid_601053 = validateParameter(valid_601053, JArray, required = true, default = nil)
  if valid_601053 != nil:
    section.add "LoadBalancerNames", valid_601053
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601054: Call_PostAddTags_601040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601054.validator(path, query, header, formData, body)
  let scheme = call_601054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601054.url(scheme.get, call_601054.host, call_601054.base,
                         call_601054.route, valid.getOrDefault("path"))
  result = hook(call_601054, url, valid)

proc call*(call_601055: Call_PostAddTags_601040; Tags: JsonNode;
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
  var query_601056 = newJObject()
  var formData_601057 = newJObject()
  if Tags != nil:
    formData_601057.add "Tags", Tags
  add(query_601056, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_601057.add "LoadBalancerNames", LoadBalancerNames
  add(query_601056, "Version", newJString(Version))
  result = call_601055.call(nil, query_601056, nil, formData_601057, nil)

var postAddTags* = Call_PostAddTags_601040(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_601041,
                                        base: "/", url: url_PostAddTags_601042,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_600768 = ref object of OpenApiRestCall_600426
proc url_GetAddTags_600770(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddTags_600769(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600882 = query.getOrDefault("Tags")
  valid_600882 = validateParameter(valid_600882, JArray, required = true, default = nil)
  if valid_600882 != nil:
    section.add "Tags", valid_600882
  var valid_600896 = query.getOrDefault("Action")
  valid_600896 = validateParameter(valid_600896, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_600896 != nil:
    section.add "Action", valid_600896
  var valid_600897 = query.getOrDefault("LoadBalancerNames")
  valid_600897 = validateParameter(valid_600897, JArray, required = true, default = nil)
  if valid_600897 != nil:
    section.add "LoadBalancerNames", valid_600897
  var valid_600898 = query.getOrDefault("Version")
  valid_600898 = validateParameter(valid_600898, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_600898 != nil:
    section.add "Version", valid_600898
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
  var valid_600899 = header.getOrDefault("X-Amz-Date")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Date", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Security-Token")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Security-Token", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Content-Sha256", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Algorithm")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Algorithm", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Signature")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Signature", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-SignedHeaders", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Credential")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Credential", valid_600905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600928: Call_GetAddTags_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_600928.validator(path, query, header, formData, body)
  let scheme = call_600928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600928.url(scheme.get, call_600928.host, call_600928.base,
                         call_600928.route, valid.getOrDefault("path"))
  result = hook(call_600928, url, valid)

proc call*(call_600999: Call_GetAddTags_600768; Tags: JsonNode;
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
  var query_601000 = newJObject()
  if Tags != nil:
    query_601000.add "Tags", Tags
  add(query_601000, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_601000.add "LoadBalancerNames", LoadBalancerNames
  add(query_601000, "Version", newJString(Version))
  result = call_600999.call(nil, query_601000, nil, nil, nil)

var getAddTags* = Call_GetAddTags_600768(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_600769,
                                      base: "/", url: url_GetAddTags_600770,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplySecurityGroupsToLoadBalancer_601075 = ref object of OpenApiRestCall_600426
proc url_PostApplySecurityGroupsToLoadBalancer_601077(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostApplySecurityGroupsToLoadBalancer_601076(path: JsonNode;
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
  var valid_601078 = query.getOrDefault("Action")
  valid_601078 = validateParameter(valid_601078, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_601078 != nil:
    section.add "Action", valid_601078
  var valid_601079 = query.getOrDefault("Version")
  valid_601079 = validateParameter(valid_601079, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601079 != nil:
    section.add "Version", valid_601079
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
  var valid_601080 = header.getOrDefault("X-Amz-Date")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Date", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Security-Token")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Security-Token", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Content-Sha256", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Algorithm")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Algorithm", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Signature")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Signature", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-SignedHeaders", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Credential")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Credential", valid_601086
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_601087 = formData.getOrDefault("SecurityGroups")
  valid_601087 = validateParameter(valid_601087, JArray, required = true, default = nil)
  if valid_601087 != nil:
    section.add "SecurityGroups", valid_601087
  var valid_601088 = formData.getOrDefault("LoadBalancerName")
  valid_601088 = validateParameter(valid_601088, JString, required = true,
                                 default = nil)
  if valid_601088 != nil:
    section.add "LoadBalancerName", valid_601088
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601089: Call_PostApplySecurityGroupsToLoadBalancer_601075;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601089.validator(path, query, header, formData, body)
  let scheme = call_601089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601089.url(scheme.get, call_601089.host, call_601089.base,
                         call_601089.route, valid.getOrDefault("path"))
  result = hook(call_601089, url, valid)

proc call*(call_601090: Call_PostApplySecurityGroupsToLoadBalancer_601075;
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
  var query_601091 = newJObject()
  var formData_601092 = newJObject()
  add(query_601091, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_601092.add "SecurityGroups", SecurityGroups
  add(formData_601092, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601091, "Version", newJString(Version))
  result = call_601090.call(nil, query_601091, nil, formData_601092, nil)

var postApplySecurityGroupsToLoadBalancer* = Call_PostApplySecurityGroupsToLoadBalancer_601075(
    name: "postApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_PostApplySecurityGroupsToLoadBalancer_601076, base: "/",
    url: url_PostApplySecurityGroupsToLoadBalancer_601077,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplySecurityGroupsToLoadBalancer_601058 = ref object of OpenApiRestCall_600426
proc url_GetApplySecurityGroupsToLoadBalancer_601060(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApplySecurityGroupsToLoadBalancer_601059(path: JsonNode;
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
  var valid_601061 = query.getOrDefault("LoadBalancerName")
  valid_601061 = validateParameter(valid_601061, JString, required = true,
                                 default = nil)
  if valid_601061 != nil:
    section.add "LoadBalancerName", valid_601061
  var valid_601062 = query.getOrDefault("Action")
  valid_601062 = validateParameter(valid_601062, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_601062 != nil:
    section.add "Action", valid_601062
  var valid_601063 = query.getOrDefault("Version")
  valid_601063 = validateParameter(valid_601063, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601063 != nil:
    section.add "Version", valid_601063
  var valid_601064 = query.getOrDefault("SecurityGroups")
  valid_601064 = validateParameter(valid_601064, JArray, required = true, default = nil)
  if valid_601064 != nil:
    section.add "SecurityGroups", valid_601064
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
  var valid_601065 = header.getOrDefault("X-Amz-Date")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Date", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Security-Token")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Security-Token", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Content-Sha256", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Algorithm")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Algorithm", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Signature")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Signature", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-SignedHeaders", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Credential")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Credential", valid_601071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601072: Call_GetApplySecurityGroupsToLoadBalancer_601058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601072.validator(path, query, header, formData, body)
  let scheme = call_601072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601072.url(scheme.get, call_601072.host, call_601072.base,
                         call_601072.route, valid.getOrDefault("path"))
  result = hook(call_601072, url, valid)

proc call*(call_601073: Call_GetApplySecurityGroupsToLoadBalancer_601058;
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
  var query_601074 = newJObject()
  add(query_601074, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601074, "Action", newJString(Action))
  add(query_601074, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_601074.add "SecurityGroups", SecurityGroups
  result = call_601073.call(nil, query_601074, nil, nil, nil)

var getApplySecurityGroupsToLoadBalancer* = Call_GetApplySecurityGroupsToLoadBalancer_601058(
    name: "getApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_GetApplySecurityGroupsToLoadBalancer_601059, base: "/",
    url: url_GetApplySecurityGroupsToLoadBalancer_601060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAttachLoadBalancerToSubnets_601110 = ref object of OpenApiRestCall_600426
proc url_PostAttachLoadBalancerToSubnets_601112(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAttachLoadBalancerToSubnets_601111(path: JsonNode;
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
  var valid_601113 = query.getOrDefault("Action")
  valid_601113 = validateParameter(valid_601113, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_601113 != nil:
    section.add "Action", valid_601113
  var valid_601114 = query.getOrDefault("Version")
  valid_601114 = validateParameter(valid_601114, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601114 != nil:
    section.add "Version", valid_601114
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
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Content-Sha256", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Algorithm")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Algorithm", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Signature")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Signature", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-SignedHeaders", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Credential")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Credential", valid_601121
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_601122 = formData.getOrDefault("Subnets")
  valid_601122 = validateParameter(valid_601122, JArray, required = true, default = nil)
  if valid_601122 != nil:
    section.add "Subnets", valid_601122
  var valid_601123 = formData.getOrDefault("LoadBalancerName")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = nil)
  if valid_601123 != nil:
    section.add "LoadBalancerName", valid_601123
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_PostAttachLoadBalancerToSubnets_601110;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_PostAttachLoadBalancerToSubnets_601110;
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
  var query_601126 = newJObject()
  var formData_601127 = newJObject()
  add(query_601126, "Action", newJString(Action))
  if Subnets != nil:
    formData_601127.add "Subnets", Subnets
  add(formData_601127, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601126, "Version", newJString(Version))
  result = call_601125.call(nil, query_601126, nil, formData_601127, nil)

var postAttachLoadBalancerToSubnets* = Call_PostAttachLoadBalancerToSubnets_601110(
    name: "postAttachLoadBalancerToSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_PostAttachLoadBalancerToSubnets_601111, base: "/",
    url: url_PostAttachLoadBalancerToSubnets_601112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttachLoadBalancerToSubnets_601093 = ref object of OpenApiRestCall_600426
proc url_GetAttachLoadBalancerToSubnets_601095(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAttachLoadBalancerToSubnets_601094(path: JsonNode;
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
  var valid_601096 = query.getOrDefault("LoadBalancerName")
  valid_601096 = validateParameter(valid_601096, JString, required = true,
                                 default = nil)
  if valid_601096 != nil:
    section.add "LoadBalancerName", valid_601096
  var valid_601097 = query.getOrDefault("Action")
  valid_601097 = validateParameter(valid_601097, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_601097 != nil:
    section.add "Action", valid_601097
  var valid_601098 = query.getOrDefault("Subnets")
  valid_601098 = validateParameter(valid_601098, JArray, required = true, default = nil)
  if valid_601098 != nil:
    section.add "Subnets", valid_601098
  var valid_601099 = query.getOrDefault("Version")
  valid_601099 = validateParameter(valid_601099, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601099 != nil:
    section.add "Version", valid_601099
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
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Content-Sha256", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Algorithm")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Algorithm", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Signature")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Signature", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-SignedHeaders", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Credential")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Credential", valid_601106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601107: Call_GetAttachLoadBalancerToSubnets_601093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601107.validator(path, query, header, formData, body)
  let scheme = call_601107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601107.url(scheme.get, call_601107.host, call_601107.base,
                         call_601107.route, valid.getOrDefault("path"))
  result = hook(call_601107, url, valid)

proc call*(call_601108: Call_GetAttachLoadBalancerToSubnets_601093;
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
  var query_601109 = newJObject()
  add(query_601109, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601109, "Action", newJString(Action))
  if Subnets != nil:
    query_601109.add "Subnets", Subnets
  add(query_601109, "Version", newJString(Version))
  result = call_601108.call(nil, query_601109, nil, nil, nil)

var getAttachLoadBalancerToSubnets* = Call_GetAttachLoadBalancerToSubnets_601093(
    name: "getAttachLoadBalancerToSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_GetAttachLoadBalancerToSubnets_601094, base: "/",
    url: url_GetAttachLoadBalancerToSubnets_601095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfigureHealthCheck_601149 = ref object of OpenApiRestCall_600426
proc url_PostConfigureHealthCheck_601151(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostConfigureHealthCheck_601150(path: JsonNode; query: JsonNode;
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
  var valid_601152 = query.getOrDefault("Action")
  valid_601152 = validateParameter(valid_601152, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_601152 != nil:
    section.add "Action", valid_601152
  var valid_601153 = query.getOrDefault("Version")
  valid_601153 = validateParameter(valid_601153, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601153 != nil:
    section.add "Version", valid_601153
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
  var valid_601154 = header.getOrDefault("X-Amz-Date")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Date", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Security-Token")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Security-Token", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Content-Sha256", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-Algorithm")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Algorithm", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Signature")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Signature", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-SignedHeaders", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Credential")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Credential", valid_601160
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
  var valid_601161 = formData.getOrDefault("HealthCheck.HealthyThreshold")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_601161
  var valid_601162 = formData.getOrDefault("HealthCheck.Interval")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "HealthCheck.Interval", valid_601162
  var valid_601163 = formData.getOrDefault("HealthCheck.Timeout")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "HealthCheck.Timeout", valid_601163
  var valid_601164 = formData.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_601164
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_601165 = formData.getOrDefault("LoadBalancerName")
  valid_601165 = validateParameter(valid_601165, JString, required = true,
                                 default = nil)
  if valid_601165 != nil:
    section.add "LoadBalancerName", valid_601165
  var valid_601166 = formData.getOrDefault("HealthCheck.Target")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "HealthCheck.Target", valid_601166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601167: Call_PostConfigureHealthCheck_601149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601167.validator(path, query, header, formData, body)
  let scheme = call_601167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601167.url(scheme.get, call_601167.host, call_601167.base,
                         call_601167.route, valid.getOrDefault("path"))
  result = hook(call_601167, url, valid)

proc call*(call_601168: Call_PostConfigureHealthCheck_601149;
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
  var query_601169 = newJObject()
  var formData_601170 = newJObject()
  add(formData_601170, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(formData_601170, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(formData_601170, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_601169, "Action", newJString(Action))
  add(formData_601170, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(formData_601170, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_601170, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_601169, "Version", newJString(Version))
  result = call_601168.call(nil, query_601169, nil, formData_601170, nil)

var postConfigureHealthCheck* = Call_PostConfigureHealthCheck_601149(
    name: "postConfigureHealthCheck", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_PostConfigureHealthCheck_601150, base: "/",
    url: url_PostConfigureHealthCheck_601151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigureHealthCheck_601128 = ref object of OpenApiRestCall_600426
proc url_GetConfigureHealthCheck_601130(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConfigureHealthCheck_601129(path: JsonNode; query: JsonNode;
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
  var valid_601131 = query.getOrDefault("HealthCheck.HealthyThreshold")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_601131
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_601132 = query.getOrDefault("LoadBalancerName")
  valid_601132 = validateParameter(valid_601132, JString, required = true,
                                 default = nil)
  if valid_601132 != nil:
    section.add "LoadBalancerName", valid_601132
  var valid_601133 = query.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_601133
  var valid_601134 = query.getOrDefault("HealthCheck.Timeout")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "HealthCheck.Timeout", valid_601134
  var valid_601135 = query.getOrDefault("HealthCheck.Target")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "HealthCheck.Target", valid_601135
  var valid_601136 = query.getOrDefault("Action")
  valid_601136 = validateParameter(valid_601136, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_601136 != nil:
    section.add "Action", valid_601136
  var valid_601137 = query.getOrDefault("HealthCheck.Interval")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "HealthCheck.Interval", valid_601137
  var valid_601138 = query.getOrDefault("Version")
  valid_601138 = validateParameter(valid_601138, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601138 != nil:
    section.add "Version", valid_601138
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
  var valid_601139 = header.getOrDefault("X-Amz-Date")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Date", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Security-Token")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Security-Token", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Content-Sha256", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Algorithm")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Algorithm", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Signature")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Signature", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-SignedHeaders", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Credential")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Credential", valid_601145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601146: Call_GetConfigureHealthCheck_601128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601146.validator(path, query, header, formData, body)
  let scheme = call_601146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601146.url(scheme.get, call_601146.host, call_601146.base,
                         call_601146.route, valid.getOrDefault("path"))
  result = hook(call_601146, url, valid)

proc call*(call_601147: Call_GetConfigureHealthCheck_601128;
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
  var query_601148 = newJObject()
  add(query_601148, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(query_601148, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601148, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(query_601148, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_601148, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_601148, "Action", newJString(Action))
  add(query_601148, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(query_601148, "Version", newJString(Version))
  result = call_601147.call(nil, query_601148, nil, nil, nil)

var getConfigureHealthCheck* = Call_GetConfigureHealthCheck_601128(
    name: "getConfigureHealthCheck", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_GetConfigureHealthCheck_601129, base: "/",
    url: url_GetConfigureHealthCheck_601130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateAppCookieStickinessPolicy_601189 = ref object of OpenApiRestCall_600426
proc url_PostCreateAppCookieStickinessPolicy_601191(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateAppCookieStickinessPolicy_601190(path: JsonNode;
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
  var valid_601192 = query.getOrDefault("Action")
  valid_601192 = validateParameter(valid_601192, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_601192 != nil:
    section.add "Action", valid_601192
  var valid_601193 = query.getOrDefault("Version")
  valid_601193 = validateParameter(valid_601193, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601193 != nil:
    section.add "Version", valid_601193
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
  var valid_601194 = header.getOrDefault("X-Amz-Date")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Date", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Security-Token")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Security-Token", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Content-Sha256", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Algorithm")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Algorithm", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Signature")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Signature", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-SignedHeaders", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Credential")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Credential", valid_601200
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
  var valid_601201 = formData.getOrDefault("PolicyName")
  valid_601201 = validateParameter(valid_601201, JString, required = true,
                                 default = nil)
  if valid_601201 != nil:
    section.add "PolicyName", valid_601201
  var valid_601202 = formData.getOrDefault("CookieName")
  valid_601202 = validateParameter(valid_601202, JString, required = true,
                                 default = nil)
  if valid_601202 != nil:
    section.add "CookieName", valid_601202
  var valid_601203 = formData.getOrDefault("LoadBalancerName")
  valid_601203 = validateParameter(valid_601203, JString, required = true,
                                 default = nil)
  if valid_601203 != nil:
    section.add "LoadBalancerName", valid_601203
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601204: Call_PostCreateAppCookieStickinessPolicy_601189;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601204.validator(path, query, header, formData, body)
  let scheme = call_601204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601204.url(scheme.get, call_601204.host, call_601204.base,
                         call_601204.route, valid.getOrDefault("path"))
  result = hook(call_601204, url, valid)

proc call*(call_601205: Call_PostCreateAppCookieStickinessPolicy_601189;
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
  var query_601206 = newJObject()
  var formData_601207 = newJObject()
  add(formData_601207, "PolicyName", newJString(PolicyName))
  add(formData_601207, "CookieName", newJString(CookieName))
  add(query_601206, "Action", newJString(Action))
  add(formData_601207, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601206, "Version", newJString(Version))
  result = call_601205.call(nil, query_601206, nil, formData_601207, nil)

var postCreateAppCookieStickinessPolicy* = Call_PostCreateAppCookieStickinessPolicy_601189(
    name: "postCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_PostCreateAppCookieStickinessPolicy_601190, base: "/",
    url: url_PostCreateAppCookieStickinessPolicy_601191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateAppCookieStickinessPolicy_601171 = ref object of OpenApiRestCall_600426
proc url_GetCreateAppCookieStickinessPolicy_601173(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateAppCookieStickinessPolicy_601172(path: JsonNode;
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
  var valid_601174 = query.getOrDefault("LoadBalancerName")
  valid_601174 = validateParameter(valid_601174, JString, required = true,
                                 default = nil)
  if valid_601174 != nil:
    section.add "LoadBalancerName", valid_601174
  var valid_601175 = query.getOrDefault("Action")
  valid_601175 = validateParameter(valid_601175, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_601175 != nil:
    section.add "Action", valid_601175
  var valid_601176 = query.getOrDefault("CookieName")
  valid_601176 = validateParameter(valid_601176, JString, required = true,
                                 default = nil)
  if valid_601176 != nil:
    section.add "CookieName", valid_601176
  var valid_601177 = query.getOrDefault("Version")
  valid_601177 = validateParameter(valid_601177, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601177 != nil:
    section.add "Version", valid_601177
  var valid_601178 = query.getOrDefault("PolicyName")
  valid_601178 = validateParameter(valid_601178, JString, required = true,
                                 default = nil)
  if valid_601178 != nil:
    section.add "PolicyName", valid_601178
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
  var valid_601179 = header.getOrDefault("X-Amz-Date")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Date", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Security-Token")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Security-Token", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Content-Sha256", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Algorithm")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Algorithm", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Signature")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Signature", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-SignedHeaders", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Credential")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Credential", valid_601185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601186: Call_GetCreateAppCookieStickinessPolicy_601171;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601186.validator(path, query, header, formData, body)
  let scheme = call_601186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601186.url(scheme.get, call_601186.host, call_601186.base,
                         call_601186.route, valid.getOrDefault("path"))
  result = hook(call_601186, url, valid)

proc call*(call_601187: Call_GetCreateAppCookieStickinessPolicy_601171;
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
  var query_601188 = newJObject()
  add(query_601188, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601188, "Action", newJString(Action))
  add(query_601188, "CookieName", newJString(CookieName))
  add(query_601188, "Version", newJString(Version))
  add(query_601188, "PolicyName", newJString(PolicyName))
  result = call_601187.call(nil, query_601188, nil, nil, nil)

var getCreateAppCookieStickinessPolicy* = Call_GetCreateAppCookieStickinessPolicy_601171(
    name: "getCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_GetCreateAppCookieStickinessPolicy_601172, base: "/",
    url: url_GetCreateAppCookieStickinessPolicy_601173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLBCookieStickinessPolicy_601226 = ref object of OpenApiRestCall_600426
proc url_PostCreateLBCookieStickinessPolicy_601228(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateLBCookieStickinessPolicy_601227(path: JsonNode;
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
  var valid_601229 = query.getOrDefault("Action")
  valid_601229 = validateParameter(valid_601229, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_601229 != nil:
    section.add "Action", valid_601229
  var valid_601230 = query.getOrDefault("Version")
  valid_601230 = validateParameter(valid_601230, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601230 != nil:
    section.add "Version", valid_601230
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
  var valid_601231 = header.getOrDefault("X-Amz-Date")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Date", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Security-Token")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Security-Token", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Content-Sha256", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Algorithm")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Algorithm", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Signature")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Signature", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-SignedHeaders", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Credential")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Credential", valid_601237
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
  var valid_601238 = formData.getOrDefault("PolicyName")
  valid_601238 = validateParameter(valid_601238, JString, required = true,
                                 default = nil)
  if valid_601238 != nil:
    section.add "PolicyName", valid_601238
  var valid_601239 = formData.getOrDefault("LoadBalancerName")
  valid_601239 = validateParameter(valid_601239, JString, required = true,
                                 default = nil)
  if valid_601239 != nil:
    section.add "LoadBalancerName", valid_601239
  var valid_601240 = formData.getOrDefault("CookieExpirationPeriod")
  valid_601240 = validateParameter(valid_601240, JInt, required = false, default = nil)
  if valid_601240 != nil:
    section.add "CookieExpirationPeriod", valid_601240
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601241: Call_PostCreateLBCookieStickinessPolicy_601226;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601241.validator(path, query, header, formData, body)
  let scheme = call_601241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601241.url(scheme.get, call_601241.host, call_601241.base,
                         call_601241.route, valid.getOrDefault("path"))
  result = hook(call_601241, url, valid)

proc call*(call_601242: Call_PostCreateLBCookieStickinessPolicy_601226;
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
  var query_601243 = newJObject()
  var formData_601244 = newJObject()
  add(formData_601244, "PolicyName", newJString(PolicyName))
  add(query_601243, "Action", newJString(Action))
  add(formData_601244, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601243, "Version", newJString(Version))
  add(formData_601244, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  result = call_601242.call(nil, query_601243, nil, formData_601244, nil)

var postCreateLBCookieStickinessPolicy* = Call_PostCreateLBCookieStickinessPolicy_601226(
    name: "postCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_PostCreateLBCookieStickinessPolicy_601227, base: "/",
    url: url_PostCreateLBCookieStickinessPolicy_601228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLBCookieStickinessPolicy_601208 = ref object of OpenApiRestCall_600426
proc url_GetCreateLBCookieStickinessPolicy_601210(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateLBCookieStickinessPolicy_601209(path: JsonNode;
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
  var valid_601211 = query.getOrDefault("CookieExpirationPeriod")
  valid_601211 = validateParameter(valid_601211, JInt, required = false, default = nil)
  if valid_601211 != nil:
    section.add "CookieExpirationPeriod", valid_601211
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_601212 = query.getOrDefault("LoadBalancerName")
  valid_601212 = validateParameter(valid_601212, JString, required = true,
                                 default = nil)
  if valid_601212 != nil:
    section.add "LoadBalancerName", valid_601212
  var valid_601213 = query.getOrDefault("Action")
  valid_601213 = validateParameter(valid_601213, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_601213 != nil:
    section.add "Action", valid_601213
  var valid_601214 = query.getOrDefault("Version")
  valid_601214 = validateParameter(valid_601214, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601214 != nil:
    section.add "Version", valid_601214
  var valid_601215 = query.getOrDefault("PolicyName")
  valid_601215 = validateParameter(valid_601215, JString, required = true,
                                 default = nil)
  if valid_601215 != nil:
    section.add "PolicyName", valid_601215
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
  var valid_601216 = header.getOrDefault("X-Amz-Date")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Date", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Security-Token")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Security-Token", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Content-Sha256", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Algorithm")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Algorithm", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Signature")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Signature", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-SignedHeaders", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Credential")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Credential", valid_601222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601223: Call_GetCreateLBCookieStickinessPolicy_601208;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601223.validator(path, query, header, formData, body)
  let scheme = call_601223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601223.url(scheme.get, call_601223.host, call_601223.base,
                         call_601223.route, valid.getOrDefault("path"))
  result = hook(call_601223, url, valid)

proc call*(call_601224: Call_GetCreateLBCookieStickinessPolicy_601208;
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
  var query_601225 = newJObject()
  add(query_601225, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(query_601225, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601225, "Action", newJString(Action))
  add(query_601225, "Version", newJString(Version))
  add(query_601225, "PolicyName", newJString(PolicyName))
  result = call_601224.call(nil, query_601225, nil, nil, nil)

var getCreateLBCookieStickinessPolicy* = Call_GetCreateLBCookieStickinessPolicy_601208(
    name: "getCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_GetCreateLBCookieStickinessPolicy_601209, base: "/",
    url: url_GetCreateLBCookieStickinessPolicy_601210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_601267 = ref object of OpenApiRestCall_600426
proc url_PostCreateLoadBalancer_601269(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateLoadBalancer_601268(path: JsonNode; query: JsonNode;
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
  var valid_601270 = query.getOrDefault("Action")
  valid_601270 = validateParameter(valid_601270, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_601270 != nil:
    section.add "Action", valid_601270
  var valid_601271 = query.getOrDefault("Version")
  valid_601271 = validateParameter(valid_601271, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601271 != nil:
    section.add "Version", valid_601271
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
  var valid_601272 = header.getOrDefault("X-Amz-Date")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Date", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Security-Token")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Security-Token", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Content-Sha256", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Algorithm")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Algorithm", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Signature")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Signature", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-SignedHeaders", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Credential")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Credential", valid_601278
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
  var valid_601279 = formData.getOrDefault("Tags")
  valid_601279 = validateParameter(valid_601279, JArray, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "Tags", valid_601279
  var valid_601280 = formData.getOrDefault("AvailabilityZones")
  valid_601280 = validateParameter(valid_601280, JArray, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "AvailabilityZones", valid_601280
  var valid_601281 = formData.getOrDefault("Subnets")
  valid_601281 = validateParameter(valid_601281, JArray, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "Subnets", valid_601281
  var valid_601282 = formData.getOrDefault("SecurityGroups")
  valid_601282 = validateParameter(valid_601282, JArray, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "SecurityGroups", valid_601282
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_601283 = formData.getOrDefault("LoadBalancerName")
  valid_601283 = validateParameter(valid_601283, JString, required = true,
                                 default = nil)
  if valid_601283 != nil:
    section.add "LoadBalancerName", valid_601283
  var valid_601284 = formData.getOrDefault("Scheme")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "Scheme", valid_601284
  var valid_601285 = formData.getOrDefault("Listeners")
  valid_601285 = validateParameter(valid_601285, JArray, required = true, default = nil)
  if valid_601285 != nil:
    section.add "Listeners", valid_601285
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601286: Call_PostCreateLoadBalancer_601267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601286.validator(path, query, header, formData, body)
  let scheme = call_601286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601286.url(scheme.get, call_601286.host, call_601286.base,
                         call_601286.route, valid.getOrDefault("path"))
  result = hook(call_601286, url, valid)

proc call*(call_601287: Call_PostCreateLoadBalancer_601267;
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
  var query_601288 = newJObject()
  var formData_601289 = newJObject()
  if Tags != nil:
    formData_601289.add "Tags", Tags
  add(query_601288, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_601289.add "AvailabilityZones", AvailabilityZones
  if Subnets != nil:
    formData_601289.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_601289.add "SecurityGroups", SecurityGroups
  add(formData_601289, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_601289, "Scheme", newJString(Scheme))
  if Listeners != nil:
    formData_601289.add "Listeners", Listeners
  add(query_601288, "Version", newJString(Version))
  result = call_601287.call(nil, query_601288, nil, formData_601289, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_601267(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_601268, base: "/",
    url: url_PostCreateLoadBalancer_601269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_601245 = ref object of OpenApiRestCall_600426
proc url_GetCreateLoadBalancer_601247(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateLoadBalancer_601246(path: JsonNode; query: JsonNode;
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
  var valid_601248 = query.getOrDefault("LoadBalancerName")
  valid_601248 = validateParameter(valid_601248, JString, required = true,
                                 default = nil)
  if valid_601248 != nil:
    section.add "LoadBalancerName", valid_601248
  var valid_601249 = query.getOrDefault("AvailabilityZones")
  valid_601249 = validateParameter(valid_601249, JArray, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "AvailabilityZones", valid_601249
  var valid_601250 = query.getOrDefault("Scheme")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "Scheme", valid_601250
  var valid_601251 = query.getOrDefault("Tags")
  valid_601251 = validateParameter(valid_601251, JArray, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "Tags", valid_601251
  var valid_601252 = query.getOrDefault("Action")
  valid_601252 = validateParameter(valid_601252, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_601252 != nil:
    section.add "Action", valid_601252
  var valid_601253 = query.getOrDefault("Subnets")
  valid_601253 = validateParameter(valid_601253, JArray, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "Subnets", valid_601253
  var valid_601254 = query.getOrDefault("Version")
  valid_601254 = validateParameter(valid_601254, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601254 != nil:
    section.add "Version", valid_601254
  var valid_601255 = query.getOrDefault("Listeners")
  valid_601255 = validateParameter(valid_601255, JArray, required = true, default = nil)
  if valid_601255 != nil:
    section.add "Listeners", valid_601255
  var valid_601256 = query.getOrDefault("SecurityGroups")
  valid_601256 = validateParameter(valid_601256, JArray, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "SecurityGroups", valid_601256
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
  var valid_601257 = header.getOrDefault("X-Amz-Date")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Date", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Security-Token")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Security-Token", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Content-Sha256", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Algorithm")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Algorithm", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Signature")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Signature", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-SignedHeaders", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Credential")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Credential", valid_601263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601264: Call_GetCreateLoadBalancer_601245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601264.validator(path, query, header, formData, body)
  let scheme = call_601264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601264.url(scheme.get, call_601264.host, call_601264.base,
                         call_601264.route, valid.getOrDefault("path"))
  result = hook(call_601264, url, valid)

proc call*(call_601265: Call_GetCreateLoadBalancer_601245;
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
  var query_601266 = newJObject()
  add(query_601266, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_601266.add "AvailabilityZones", AvailabilityZones
  add(query_601266, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_601266.add "Tags", Tags
  add(query_601266, "Action", newJString(Action))
  if Subnets != nil:
    query_601266.add "Subnets", Subnets
  add(query_601266, "Version", newJString(Version))
  if Listeners != nil:
    query_601266.add "Listeners", Listeners
  if SecurityGroups != nil:
    query_601266.add "SecurityGroups", SecurityGroups
  result = call_601265.call(nil, query_601266, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_601245(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_601246, base: "/",
    url: url_GetCreateLoadBalancer_601247, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerListeners_601307 = ref object of OpenApiRestCall_600426
proc url_PostCreateLoadBalancerListeners_601309(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateLoadBalancerListeners_601308(path: JsonNode;
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
  var valid_601310 = query.getOrDefault("Action")
  valid_601310 = validateParameter(valid_601310, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_601310 != nil:
    section.add "Action", valid_601310
  var valid_601311 = query.getOrDefault("Version")
  valid_601311 = validateParameter(valid_601311, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601311 != nil:
    section.add "Version", valid_601311
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
  var valid_601312 = header.getOrDefault("X-Amz-Date")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Date", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Security-Token")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Security-Token", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Content-Sha256", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Algorithm")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Algorithm", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Signature")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Signature", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-SignedHeaders", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Credential")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Credential", valid_601318
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_601319 = formData.getOrDefault("LoadBalancerName")
  valid_601319 = validateParameter(valid_601319, JString, required = true,
                                 default = nil)
  if valid_601319 != nil:
    section.add "LoadBalancerName", valid_601319
  var valid_601320 = formData.getOrDefault("Listeners")
  valid_601320 = validateParameter(valid_601320, JArray, required = true, default = nil)
  if valid_601320 != nil:
    section.add "Listeners", valid_601320
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601321: Call_PostCreateLoadBalancerListeners_601307;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601321.validator(path, query, header, formData, body)
  let scheme = call_601321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601321.url(scheme.get, call_601321.host, call_601321.base,
                         call_601321.route, valid.getOrDefault("path"))
  result = hook(call_601321, url, valid)

proc call*(call_601322: Call_PostCreateLoadBalancerListeners_601307;
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
  var query_601323 = newJObject()
  var formData_601324 = newJObject()
  add(query_601323, "Action", newJString(Action))
  add(formData_601324, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_601324.add "Listeners", Listeners
  add(query_601323, "Version", newJString(Version))
  result = call_601322.call(nil, query_601323, nil, formData_601324, nil)

var postCreateLoadBalancerListeners* = Call_PostCreateLoadBalancerListeners_601307(
    name: "postCreateLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_PostCreateLoadBalancerListeners_601308, base: "/",
    url: url_PostCreateLoadBalancerListeners_601309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerListeners_601290 = ref object of OpenApiRestCall_600426
proc url_GetCreateLoadBalancerListeners_601292(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateLoadBalancerListeners_601291(path: JsonNode;
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
  var valid_601293 = query.getOrDefault("LoadBalancerName")
  valid_601293 = validateParameter(valid_601293, JString, required = true,
                                 default = nil)
  if valid_601293 != nil:
    section.add "LoadBalancerName", valid_601293
  var valid_601294 = query.getOrDefault("Action")
  valid_601294 = validateParameter(valid_601294, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_601294 != nil:
    section.add "Action", valid_601294
  var valid_601295 = query.getOrDefault("Version")
  valid_601295 = validateParameter(valid_601295, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601295 != nil:
    section.add "Version", valid_601295
  var valid_601296 = query.getOrDefault("Listeners")
  valid_601296 = validateParameter(valid_601296, JArray, required = true, default = nil)
  if valid_601296 != nil:
    section.add "Listeners", valid_601296
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
  var valid_601297 = header.getOrDefault("X-Amz-Date")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Date", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Security-Token")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Security-Token", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Content-Sha256", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Algorithm")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Algorithm", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Signature")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Signature", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-SignedHeaders", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Credential")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Credential", valid_601303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601304: Call_GetCreateLoadBalancerListeners_601290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601304.validator(path, query, header, formData, body)
  let scheme = call_601304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601304.url(scheme.get, call_601304.host, call_601304.base,
                         call_601304.route, valid.getOrDefault("path"))
  result = hook(call_601304, url, valid)

proc call*(call_601305: Call_GetCreateLoadBalancerListeners_601290;
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
  var query_601306 = newJObject()
  add(query_601306, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601306, "Action", newJString(Action))
  add(query_601306, "Version", newJString(Version))
  if Listeners != nil:
    query_601306.add "Listeners", Listeners
  result = call_601305.call(nil, query_601306, nil, nil, nil)

var getCreateLoadBalancerListeners* = Call_GetCreateLoadBalancerListeners_601290(
    name: "getCreateLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_GetCreateLoadBalancerListeners_601291, base: "/",
    url: url_GetCreateLoadBalancerListeners_601292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerPolicy_601344 = ref object of OpenApiRestCall_600426
proc url_PostCreateLoadBalancerPolicy_601346(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateLoadBalancerPolicy_601345(path: JsonNode; query: JsonNode;
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
  var valid_601347 = query.getOrDefault("Action")
  valid_601347 = validateParameter(valid_601347, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_601347 != nil:
    section.add "Action", valid_601347
  var valid_601348 = query.getOrDefault("Version")
  valid_601348 = validateParameter(valid_601348, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601348 != nil:
    section.add "Version", valid_601348
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
  var valid_601349 = header.getOrDefault("X-Amz-Date")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Date", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Security-Token")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Security-Token", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Content-Sha256", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Algorithm")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Algorithm", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Signature")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Signature", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-SignedHeaders", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Credential")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Credential", valid_601355
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
  var valid_601356 = formData.getOrDefault("PolicyName")
  valid_601356 = validateParameter(valid_601356, JString, required = true,
                                 default = nil)
  if valid_601356 != nil:
    section.add "PolicyName", valid_601356
  var valid_601357 = formData.getOrDefault("PolicyTypeName")
  valid_601357 = validateParameter(valid_601357, JString, required = true,
                                 default = nil)
  if valid_601357 != nil:
    section.add "PolicyTypeName", valid_601357
  var valid_601358 = formData.getOrDefault("PolicyAttributes")
  valid_601358 = validateParameter(valid_601358, JArray, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "PolicyAttributes", valid_601358
  var valid_601359 = formData.getOrDefault("LoadBalancerName")
  valid_601359 = validateParameter(valid_601359, JString, required = true,
                                 default = nil)
  if valid_601359 != nil:
    section.add "LoadBalancerName", valid_601359
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601360: Call_PostCreateLoadBalancerPolicy_601344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_601360.validator(path, query, header, formData, body)
  let scheme = call_601360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601360.url(scheme.get, call_601360.host, call_601360.base,
                         call_601360.route, valid.getOrDefault("path"))
  result = hook(call_601360, url, valid)

proc call*(call_601361: Call_PostCreateLoadBalancerPolicy_601344;
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
  var query_601362 = newJObject()
  var formData_601363 = newJObject()
  add(formData_601363, "PolicyName", newJString(PolicyName))
  add(formData_601363, "PolicyTypeName", newJString(PolicyTypeName))
  if PolicyAttributes != nil:
    formData_601363.add "PolicyAttributes", PolicyAttributes
  add(query_601362, "Action", newJString(Action))
  add(formData_601363, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601362, "Version", newJString(Version))
  result = call_601361.call(nil, query_601362, nil, formData_601363, nil)

var postCreateLoadBalancerPolicy* = Call_PostCreateLoadBalancerPolicy_601344(
    name: "postCreateLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_PostCreateLoadBalancerPolicy_601345, base: "/",
    url: url_PostCreateLoadBalancerPolicy_601346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerPolicy_601325 = ref object of OpenApiRestCall_600426
proc url_GetCreateLoadBalancerPolicy_601327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateLoadBalancerPolicy_601326(path: JsonNode; query: JsonNode;
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
  var valid_601328 = query.getOrDefault("LoadBalancerName")
  valid_601328 = validateParameter(valid_601328, JString, required = true,
                                 default = nil)
  if valid_601328 != nil:
    section.add "LoadBalancerName", valid_601328
  var valid_601329 = query.getOrDefault("PolicyAttributes")
  valid_601329 = validateParameter(valid_601329, JArray, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "PolicyAttributes", valid_601329
  var valid_601330 = query.getOrDefault("Action")
  valid_601330 = validateParameter(valid_601330, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_601330 != nil:
    section.add "Action", valid_601330
  var valid_601331 = query.getOrDefault("PolicyTypeName")
  valid_601331 = validateParameter(valid_601331, JString, required = true,
                                 default = nil)
  if valid_601331 != nil:
    section.add "PolicyTypeName", valid_601331
  var valid_601332 = query.getOrDefault("Version")
  valid_601332 = validateParameter(valid_601332, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601332 != nil:
    section.add "Version", valid_601332
  var valid_601333 = query.getOrDefault("PolicyName")
  valid_601333 = validateParameter(valid_601333, JString, required = true,
                                 default = nil)
  if valid_601333 != nil:
    section.add "PolicyName", valid_601333
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
  var valid_601334 = header.getOrDefault("X-Amz-Date")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Date", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Security-Token")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Security-Token", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Content-Sha256", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Algorithm")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Algorithm", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Signature")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Signature", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-SignedHeaders", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Credential")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Credential", valid_601340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601341: Call_GetCreateLoadBalancerPolicy_601325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_601341.validator(path, query, header, formData, body)
  let scheme = call_601341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601341.url(scheme.get, call_601341.host, call_601341.base,
                         call_601341.route, valid.getOrDefault("path"))
  result = hook(call_601341, url, valid)

proc call*(call_601342: Call_GetCreateLoadBalancerPolicy_601325;
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
  var query_601343 = newJObject()
  add(query_601343, "LoadBalancerName", newJString(LoadBalancerName))
  if PolicyAttributes != nil:
    query_601343.add "PolicyAttributes", PolicyAttributes
  add(query_601343, "Action", newJString(Action))
  add(query_601343, "PolicyTypeName", newJString(PolicyTypeName))
  add(query_601343, "Version", newJString(Version))
  add(query_601343, "PolicyName", newJString(PolicyName))
  result = call_601342.call(nil, query_601343, nil, nil, nil)

var getCreateLoadBalancerPolicy* = Call_GetCreateLoadBalancerPolicy_601325(
    name: "getCreateLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_GetCreateLoadBalancerPolicy_601326, base: "/",
    url: url_GetCreateLoadBalancerPolicy_601327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_601380 = ref object of OpenApiRestCall_600426
proc url_PostDeleteLoadBalancer_601382(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteLoadBalancer_601381(path: JsonNode; query: JsonNode;
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
  var valid_601383 = query.getOrDefault("Action")
  valid_601383 = validateParameter(valid_601383, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_601383 != nil:
    section.add "Action", valid_601383
  var valid_601384 = query.getOrDefault("Version")
  valid_601384 = validateParameter(valid_601384, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601384 != nil:
    section.add "Version", valid_601384
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
  var valid_601385 = header.getOrDefault("X-Amz-Date")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Date", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Security-Token")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Security-Token", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Content-Sha256", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Algorithm")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Algorithm", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Signature")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Signature", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-SignedHeaders", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-Credential")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Credential", valid_601391
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_601392 = formData.getOrDefault("LoadBalancerName")
  valid_601392 = validateParameter(valid_601392, JString, required = true,
                                 default = nil)
  if valid_601392 != nil:
    section.add "LoadBalancerName", valid_601392
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601393: Call_PostDeleteLoadBalancer_601380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_601393.validator(path, query, header, formData, body)
  let scheme = call_601393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601393.url(scheme.get, call_601393.host, call_601393.base,
                         call_601393.route, valid.getOrDefault("path"))
  result = hook(call_601393, url, valid)

proc call*(call_601394: Call_PostDeleteLoadBalancer_601380;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_601395 = newJObject()
  var formData_601396 = newJObject()
  add(query_601395, "Action", newJString(Action))
  add(formData_601396, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601395, "Version", newJString(Version))
  result = call_601394.call(nil, query_601395, nil, formData_601396, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_601380(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_601381, base: "/",
    url: url_PostDeleteLoadBalancer_601382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_601364 = ref object of OpenApiRestCall_600426
proc url_GetDeleteLoadBalancer_601366(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteLoadBalancer_601365(path: JsonNode; query: JsonNode;
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
  var valid_601367 = query.getOrDefault("LoadBalancerName")
  valid_601367 = validateParameter(valid_601367, JString, required = true,
                                 default = nil)
  if valid_601367 != nil:
    section.add "LoadBalancerName", valid_601367
  var valid_601368 = query.getOrDefault("Action")
  valid_601368 = validateParameter(valid_601368, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_601368 != nil:
    section.add "Action", valid_601368
  var valid_601369 = query.getOrDefault("Version")
  valid_601369 = validateParameter(valid_601369, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601369 != nil:
    section.add "Version", valid_601369
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
  var valid_601370 = header.getOrDefault("X-Amz-Date")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Date", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Security-Token")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Security-Token", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Content-Sha256", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Algorithm")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Algorithm", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Signature")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Signature", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-SignedHeaders", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Credential")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Credential", valid_601376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601377: Call_GetDeleteLoadBalancer_601364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_601377.validator(path, query, header, formData, body)
  let scheme = call_601377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601377.url(scheme.get, call_601377.host, call_601377.base,
                         call_601377.route, valid.getOrDefault("path"))
  result = hook(call_601377, url, valid)

proc call*(call_601378: Call_GetDeleteLoadBalancer_601364;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601379 = newJObject()
  add(query_601379, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601379, "Action", newJString(Action))
  add(query_601379, "Version", newJString(Version))
  result = call_601378.call(nil, query_601379, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_601364(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_601365, base: "/",
    url: url_GetDeleteLoadBalancer_601366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerListeners_601414 = ref object of OpenApiRestCall_600426
proc url_PostDeleteLoadBalancerListeners_601416(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteLoadBalancerListeners_601415(path: JsonNode;
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
  var valid_601417 = query.getOrDefault("Action")
  valid_601417 = validateParameter(valid_601417, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_601417 != nil:
    section.add "Action", valid_601417
  var valid_601418 = query.getOrDefault("Version")
  valid_601418 = validateParameter(valid_601418, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601418 != nil:
    section.add "Version", valid_601418
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
  var valid_601419 = header.getOrDefault("X-Amz-Date")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Date", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Security-Token")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Security-Token", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Content-Sha256", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Algorithm")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Algorithm", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Signature")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Signature", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-SignedHeaders", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Credential")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Credential", valid_601425
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_601426 = formData.getOrDefault("LoadBalancerName")
  valid_601426 = validateParameter(valid_601426, JString, required = true,
                                 default = nil)
  if valid_601426 != nil:
    section.add "LoadBalancerName", valid_601426
  var valid_601427 = formData.getOrDefault("LoadBalancerPorts")
  valid_601427 = validateParameter(valid_601427, JArray, required = true, default = nil)
  if valid_601427 != nil:
    section.add "LoadBalancerPorts", valid_601427
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601428: Call_PostDeleteLoadBalancerListeners_601414;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_601428.validator(path, query, header, formData, body)
  let scheme = call_601428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601428.url(scheme.get, call_601428.host, call_601428.base,
                         call_601428.route, valid.getOrDefault("path"))
  result = hook(call_601428, url, valid)

proc call*(call_601429: Call_PostDeleteLoadBalancerListeners_601414;
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
  var query_601430 = newJObject()
  var formData_601431 = newJObject()
  add(query_601430, "Action", newJString(Action))
  add(formData_601431, "LoadBalancerName", newJString(LoadBalancerName))
  if LoadBalancerPorts != nil:
    formData_601431.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_601430, "Version", newJString(Version))
  result = call_601429.call(nil, query_601430, nil, formData_601431, nil)

var postDeleteLoadBalancerListeners* = Call_PostDeleteLoadBalancerListeners_601414(
    name: "postDeleteLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_PostDeleteLoadBalancerListeners_601415, base: "/",
    url: url_PostDeleteLoadBalancerListeners_601416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerListeners_601397 = ref object of OpenApiRestCall_600426
proc url_GetDeleteLoadBalancerListeners_601399(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteLoadBalancerListeners_601398(path: JsonNode;
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
  var valid_601400 = query.getOrDefault("LoadBalancerName")
  valid_601400 = validateParameter(valid_601400, JString, required = true,
                                 default = nil)
  if valid_601400 != nil:
    section.add "LoadBalancerName", valid_601400
  var valid_601401 = query.getOrDefault("Action")
  valid_601401 = validateParameter(valid_601401, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_601401 != nil:
    section.add "Action", valid_601401
  var valid_601402 = query.getOrDefault("LoadBalancerPorts")
  valid_601402 = validateParameter(valid_601402, JArray, required = true, default = nil)
  if valid_601402 != nil:
    section.add "LoadBalancerPorts", valid_601402
  var valid_601403 = query.getOrDefault("Version")
  valid_601403 = validateParameter(valid_601403, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601403 != nil:
    section.add "Version", valid_601403
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
  var valid_601404 = header.getOrDefault("X-Amz-Date")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Date", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Security-Token")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Security-Token", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Content-Sha256", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Algorithm")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Algorithm", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Signature")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Signature", valid_601408
  var valid_601409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-SignedHeaders", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Credential")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Credential", valid_601410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601411: Call_GetDeleteLoadBalancerListeners_601397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_601411.validator(path, query, header, formData, body)
  let scheme = call_601411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601411.url(scheme.get, call_601411.host, call_601411.base,
                         call_601411.route, valid.getOrDefault("path"))
  result = hook(call_601411, url, valid)

proc call*(call_601412: Call_GetDeleteLoadBalancerListeners_601397;
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
  var query_601413 = newJObject()
  add(query_601413, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601413, "Action", newJString(Action))
  if LoadBalancerPorts != nil:
    query_601413.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_601413, "Version", newJString(Version))
  result = call_601412.call(nil, query_601413, nil, nil, nil)

var getDeleteLoadBalancerListeners* = Call_GetDeleteLoadBalancerListeners_601397(
    name: "getDeleteLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_GetDeleteLoadBalancerListeners_601398, base: "/",
    url: url_GetDeleteLoadBalancerListeners_601399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerPolicy_601449 = ref object of OpenApiRestCall_600426
proc url_PostDeleteLoadBalancerPolicy_601451(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteLoadBalancerPolicy_601450(path: JsonNode; query: JsonNode;
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
  var valid_601452 = query.getOrDefault("Action")
  valid_601452 = validateParameter(valid_601452, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_601452 != nil:
    section.add "Action", valid_601452
  var valid_601453 = query.getOrDefault("Version")
  valid_601453 = validateParameter(valid_601453, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601453 != nil:
    section.add "Version", valid_601453
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
  var valid_601454 = header.getOrDefault("X-Amz-Date")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Date", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Security-Token")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Security-Token", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Content-Sha256", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Algorithm")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Algorithm", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-Signature")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Signature", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-SignedHeaders", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-Credential")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Credential", valid_601460
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PolicyName` field"
  var valid_601461 = formData.getOrDefault("PolicyName")
  valid_601461 = validateParameter(valid_601461, JString, required = true,
                                 default = nil)
  if valid_601461 != nil:
    section.add "PolicyName", valid_601461
  var valid_601462 = formData.getOrDefault("LoadBalancerName")
  valid_601462 = validateParameter(valid_601462, JString, required = true,
                                 default = nil)
  if valid_601462 != nil:
    section.add "LoadBalancerName", valid_601462
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601463: Call_PostDeleteLoadBalancerPolicy_601449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_601463.validator(path, query, header, formData, body)
  let scheme = call_601463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601463.url(scheme.get, call_601463.host, call_601463.base,
                         call_601463.route, valid.getOrDefault("path"))
  result = hook(call_601463, url, valid)

proc call*(call_601464: Call_PostDeleteLoadBalancerPolicy_601449;
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
  var query_601465 = newJObject()
  var formData_601466 = newJObject()
  add(formData_601466, "PolicyName", newJString(PolicyName))
  add(query_601465, "Action", newJString(Action))
  add(formData_601466, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601465, "Version", newJString(Version))
  result = call_601464.call(nil, query_601465, nil, formData_601466, nil)

var postDeleteLoadBalancerPolicy* = Call_PostDeleteLoadBalancerPolicy_601449(
    name: "postDeleteLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_PostDeleteLoadBalancerPolicy_601450, base: "/",
    url: url_PostDeleteLoadBalancerPolicy_601451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerPolicy_601432 = ref object of OpenApiRestCall_600426
proc url_GetDeleteLoadBalancerPolicy_601434(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteLoadBalancerPolicy_601433(path: JsonNode; query: JsonNode;
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
  var valid_601435 = query.getOrDefault("LoadBalancerName")
  valid_601435 = validateParameter(valid_601435, JString, required = true,
                                 default = nil)
  if valid_601435 != nil:
    section.add "LoadBalancerName", valid_601435
  var valid_601436 = query.getOrDefault("Action")
  valid_601436 = validateParameter(valid_601436, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_601436 != nil:
    section.add "Action", valid_601436
  var valid_601437 = query.getOrDefault("Version")
  valid_601437 = validateParameter(valid_601437, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601437 != nil:
    section.add "Version", valid_601437
  var valid_601438 = query.getOrDefault("PolicyName")
  valid_601438 = validateParameter(valid_601438, JString, required = true,
                                 default = nil)
  if valid_601438 != nil:
    section.add "PolicyName", valid_601438
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
  var valid_601439 = header.getOrDefault("X-Amz-Date")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Date", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Security-Token")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Security-Token", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Content-Sha256", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Algorithm")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Algorithm", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Signature")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Signature", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-SignedHeaders", valid_601444
  var valid_601445 = header.getOrDefault("X-Amz-Credential")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-Credential", valid_601445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601446: Call_GetDeleteLoadBalancerPolicy_601432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_601446.validator(path, query, header, formData, body)
  let scheme = call_601446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601446.url(scheme.get, call_601446.host, call_601446.base,
                         call_601446.route, valid.getOrDefault("path"))
  result = hook(call_601446, url, valid)

proc call*(call_601447: Call_GetDeleteLoadBalancerPolicy_601432;
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
  var query_601448 = newJObject()
  add(query_601448, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601448, "Action", newJString(Action))
  add(query_601448, "Version", newJString(Version))
  add(query_601448, "PolicyName", newJString(PolicyName))
  result = call_601447.call(nil, query_601448, nil, nil, nil)

var getDeleteLoadBalancerPolicy* = Call_GetDeleteLoadBalancerPolicy_601432(
    name: "getDeleteLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_GetDeleteLoadBalancerPolicy_601433, base: "/",
    url: url_GetDeleteLoadBalancerPolicy_601434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterInstancesFromLoadBalancer_601484 = ref object of OpenApiRestCall_600426
proc url_PostDeregisterInstancesFromLoadBalancer_601486(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeregisterInstancesFromLoadBalancer_601485(path: JsonNode;
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
  var valid_601487 = query.getOrDefault("Action")
  valid_601487 = validateParameter(valid_601487, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_601487 != nil:
    section.add "Action", valid_601487
  var valid_601488 = query.getOrDefault("Version")
  valid_601488 = validateParameter(valid_601488, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601488 != nil:
    section.add "Version", valid_601488
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
  var valid_601489 = header.getOrDefault("X-Amz-Date")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Date", valid_601489
  var valid_601490 = header.getOrDefault("X-Amz-Security-Token")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-Security-Token", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-Content-Sha256", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-Algorithm")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Algorithm", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Signature")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Signature", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-SignedHeaders", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Credential")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Credential", valid_601495
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_601496 = formData.getOrDefault("Instances")
  valid_601496 = validateParameter(valid_601496, JArray, required = true, default = nil)
  if valid_601496 != nil:
    section.add "Instances", valid_601496
  var valid_601497 = formData.getOrDefault("LoadBalancerName")
  valid_601497 = validateParameter(valid_601497, JString, required = true,
                                 default = nil)
  if valid_601497 != nil:
    section.add "LoadBalancerName", valid_601497
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601498: Call_PostDeregisterInstancesFromLoadBalancer_601484;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601498.validator(path, query, header, formData, body)
  let scheme = call_601498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601498.url(scheme.get, call_601498.host, call_601498.base,
                         call_601498.route, valid.getOrDefault("path"))
  result = hook(call_601498, url, valid)

proc call*(call_601499: Call_PostDeregisterInstancesFromLoadBalancer_601484;
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
  var query_601500 = newJObject()
  var formData_601501 = newJObject()
  if Instances != nil:
    formData_601501.add "Instances", Instances
  add(query_601500, "Action", newJString(Action))
  add(formData_601501, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601500, "Version", newJString(Version))
  result = call_601499.call(nil, query_601500, nil, formData_601501, nil)

var postDeregisterInstancesFromLoadBalancer* = Call_PostDeregisterInstancesFromLoadBalancer_601484(
    name: "postDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_PostDeregisterInstancesFromLoadBalancer_601485, base: "/",
    url: url_PostDeregisterInstancesFromLoadBalancer_601486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterInstancesFromLoadBalancer_601467 = ref object of OpenApiRestCall_600426
proc url_GetDeregisterInstancesFromLoadBalancer_601469(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeregisterInstancesFromLoadBalancer_601468(path: JsonNode;
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
  var valid_601470 = query.getOrDefault("LoadBalancerName")
  valid_601470 = validateParameter(valid_601470, JString, required = true,
                                 default = nil)
  if valid_601470 != nil:
    section.add "LoadBalancerName", valid_601470
  var valid_601471 = query.getOrDefault("Action")
  valid_601471 = validateParameter(valid_601471, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_601471 != nil:
    section.add "Action", valid_601471
  var valid_601472 = query.getOrDefault("Instances")
  valid_601472 = validateParameter(valid_601472, JArray, required = true, default = nil)
  if valid_601472 != nil:
    section.add "Instances", valid_601472
  var valid_601473 = query.getOrDefault("Version")
  valid_601473 = validateParameter(valid_601473, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601473 != nil:
    section.add "Version", valid_601473
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
  var valid_601474 = header.getOrDefault("X-Amz-Date")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Date", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-Security-Token")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Security-Token", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Content-Sha256", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Algorithm")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Algorithm", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Signature")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Signature", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-SignedHeaders", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Credential")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Credential", valid_601480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601481: Call_GetDeregisterInstancesFromLoadBalancer_601467;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601481.validator(path, query, header, formData, body)
  let scheme = call_601481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601481.url(scheme.get, call_601481.host, call_601481.base,
                         call_601481.route, valid.getOrDefault("path"))
  result = hook(call_601481, url, valid)

proc call*(call_601482: Call_GetDeregisterInstancesFromLoadBalancer_601467;
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
  var query_601483 = newJObject()
  add(query_601483, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601483, "Action", newJString(Action))
  if Instances != nil:
    query_601483.add "Instances", Instances
  add(query_601483, "Version", newJString(Version))
  result = call_601482.call(nil, query_601483, nil, nil, nil)

var getDeregisterInstancesFromLoadBalancer* = Call_GetDeregisterInstancesFromLoadBalancer_601467(
    name: "getDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_GetDeregisterInstancesFromLoadBalancer_601468, base: "/",
    url: url_GetDeregisterInstancesFromLoadBalancer_601469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_601519 = ref object of OpenApiRestCall_600426
proc url_PostDescribeAccountLimits_601521(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAccountLimits_601520(path: JsonNode; query: JsonNode;
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
  var valid_601522 = query.getOrDefault("Action")
  valid_601522 = validateParameter(valid_601522, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_601522 != nil:
    section.add "Action", valid_601522
  var valid_601523 = query.getOrDefault("Version")
  valid_601523 = validateParameter(valid_601523, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601523 != nil:
    section.add "Version", valid_601523
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
  var valid_601524 = header.getOrDefault("X-Amz-Date")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Date", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Security-Token")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Security-Token", valid_601525
  var valid_601526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-Content-Sha256", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Algorithm")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Algorithm", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Signature")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Signature", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-SignedHeaders", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Credential")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Credential", valid_601530
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_601531 = formData.getOrDefault("Marker")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "Marker", valid_601531
  var valid_601532 = formData.getOrDefault("PageSize")
  valid_601532 = validateParameter(valid_601532, JInt, required = false, default = nil)
  if valid_601532 != nil:
    section.add "PageSize", valid_601532
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601533: Call_PostDescribeAccountLimits_601519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601533.validator(path, query, header, formData, body)
  let scheme = call_601533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601533.url(scheme.get, call_601533.host, call_601533.base,
                         call_601533.route, valid.getOrDefault("path"))
  result = hook(call_601533, url, valid)

proc call*(call_601534: Call_PostDescribeAccountLimits_601519; Marker: string = "";
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
  var query_601535 = newJObject()
  var formData_601536 = newJObject()
  add(formData_601536, "Marker", newJString(Marker))
  add(query_601535, "Action", newJString(Action))
  add(formData_601536, "PageSize", newJInt(PageSize))
  add(query_601535, "Version", newJString(Version))
  result = call_601534.call(nil, query_601535, nil, formData_601536, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_601519(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_601520, base: "/",
    url: url_PostDescribeAccountLimits_601521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_601502 = ref object of OpenApiRestCall_600426
proc url_GetDescribeAccountLimits_601504(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAccountLimits_601503(path: JsonNode; query: JsonNode;
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
  var valid_601505 = query.getOrDefault("PageSize")
  valid_601505 = validateParameter(valid_601505, JInt, required = false, default = nil)
  if valid_601505 != nil:
    section.add "PageSize", valid_601505
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601506 = query.getOrDefault("Action")
  valid_601506 = validateParameter(valid_601506, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_601506 != nil:
    section.add "Action", valid_601506
  var valid_601507 = query.getOrDefault("Marker")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "Marker", valid_601507
  var valid_601508 = query.getOrDefault("Version")
  valid_601508 = validateParameter(valid_601508, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601508 != nil:
    section.add "Version", valid_601508
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
  var valid_601509 = header.getOrDefault("X-Amz-Date")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-Date", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-Security-Token")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-Security-Token", valid_601510
  var valid_601511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-Content-Sha256", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Algorithm")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Algorithm", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Signature")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Signature", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-SignedHeaders", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Credential")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Credential", valid_601515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601516: Call_GetDescribeAccountLimits_601502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601516.validator(path, query, header, formData, body)
  let scheme = call_601516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601516.url(scheme.get, call_601516.host, call_601516.base,
                         call_601516.route, valid.getOrDefault("path"))
  result = hook(call_601516, url, valid)

proc call*(call_601517: Call_GetDescribeAccountLimits_601502; PageSize: int = 0;
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
  var query_601518 = newJObject()
  add(query_601518, "PageSize", newJInt(PageSize))
  add(query_601518, "Action", newJString(Action))
  add(query_601518, "Marker", newJString(Marker))
  add(query_601518, "Version", newJString(Version))
  result = call_601517.call(nil, query_601518, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_601502(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_601503, base: "/",
    url: url_GetDescribeAccountLimits_601504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstanceHealth_601554 = ref object of OpenApiRestCall_600426
proc url_PostDescribeInstanceHealth_601556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeInstanceHealth_601555(path: JsonNode; query: JsonNode;
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
  var valid_601557 = query.getOrDefault("Action")
  valid_601557 = validateParameter(valid_601557, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_601557 != nil:
    section.add "Action", valid_601557
  var valid_601558 = query.getOrDefault("Version")
  valid_601558 = validateParameter(valid_601558, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601558 != nil:
    section.add "Version", valid_601558
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
  var valid_601559 = header.getOrDefault("X-Amz-Date")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Date", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Security-Token")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Security-Token", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Content-Sha256", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Algorithm")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Algorithm", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-Signature")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Signature", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-SignedHeaders", valid_601564
  var valid_601565 = header.getOrDefault("X-Amz-Credential")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Credential", valid_601565
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_601566 = formData.getOrDefault("Instances")
  valid_601566 = validateParameter(valid_601566, JArray, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "Instances", valid_601566
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_601567 = formData.getOrDefault("LoadBalancerName")
  valid_601567 = validateParameter(valid_601567, JString, required = true,
                                 default = nil)
  if valid_601567 != nil:
    section.add "LoadBalancerName", valid_601567
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601568: Call_PostDescribeInstanceHealth_601554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_601568.validator(path, query, header, formData, body)
  let scheme = call_601568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601568.url(scheme.get, call_601568.host, call_601568.base,
                         call_601568.route, valid.getOrDefault("path"))
  result = hook(call_601568, url, valid)

proc call*(call_601569: Call_PostDescribeInstanceHealth_601554;
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
  var query_601570 = newJObject()
  var formData_601571 = newJObject()
  if Instances != nil:
    formData_601571.add "Instances", Instances
  add(query_601570, "Action", newJString(Action))
  add(formData_601571, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601570, "Version", newJString(Version))
  result = call_601569.call(nil, query_601570, nil, formData_601571, nil)

var postDescribeInstanceHealth* = Call_PostDescribeInstanceHealth_601554(
    name: "postDescribeInstanceHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_PostDescribeInstanceHealth_601555, base: "/",
    url: url_PostDescribeInstanceHealth_601556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstanceHealth_601537 = ref object of OpenApiRestCall_600426
proc url_GetDescribeInstanceHealth_601539(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeInstanceHealth_601538(path: JsonNode; query: JsonNode;
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
  var valid_601540 = query.getOrDefault("LoadBalancerName")
  valid_601540 = validateParameter(valid_601540, JString, required = true,
                                 default = nil)
  if valid_601540 != nil:
    section.add "LoadBalancerName", valid_601540
  var valid_601541 = query.getOrDefault("Action")
  valid_601541 = validateParameter(valid_601541, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_601541 != nil:
    section.add "Action", valid_601541
  var valid_601542 = query.getOrDefault("Instances")
  valid_601542 = validateParameter(valid_601542, JArray, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "Instances", valid_601542
  var valid_601543 = query.getOrDefault("Version")
  valid_601543 = validateParameter(valid_601543, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601543 != nil:
    section.add "Version", valid_601543
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
  var valid_601544 = header.getOrDefault("X-Amz-Date")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-Date", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Security-Token")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Security-Token", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Content-Sha256", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Algorithm")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Algorithm", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-Signature")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Signature", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-SignedHeaders", valid_601549
  var valid_601550 = header.getOrDefault("X-Amz-Credential")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Credential", valid_601550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601551: Call_GetDescribeInstanceHealth_601537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_601551.validator(path, query, header, formData, body)
  let scheme = call_601551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601551.url(scheme.get, call_601551.host, call_601551.base,
                         call_601551.route, valid.getOrDefault("path"))
  result = hook(call_601551, url, valid)

proc call*(call_601552: Call_GetDescribeInstanceHealth_601537;
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
  var query_601553 = newJObject()
  add(query_601553, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601553, "Action", newJString(Action))
  if Instances != nil:
    query_601553.add "Instances", Instances
  add(query_601553, "Version", newJString(Version))
  result = call_601552.call(nil, query_601553, nil, nil, nil)

var getDescribeInstanceHealth* = Call_GetDescribeInstanceHealth_601537(
    name: "getDescribeInstanceHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_GetDescribeInstanceHealth_601538, base: "/",
    url: url_GetDescribeInstanceHealth_601539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_601588 = ref object of OpenApiRestCall_600426
proc url_PostDescribeLoadBalancerAttributes_601590(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancerAttributes_601589(path: JsonNode;
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
  var valid_601591 = query.getOrDefault("Action")
  valid_601591 = validateParameter(valid_601591, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_601591 != nil:
    section.add "Action", valid_601591
  var valid_601592 = query.getOrDefault("Version")
  valid_601592 = validateParameter(valid_601592, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601592 != nil:
    section.add "Version", valid_601592
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
  var valid_601593 = header.getOrDefault("X-Amz-Date")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Date", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Security-Token")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Security-Token", valid_601594
  var valid_601595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-Content-Sha256", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Algorithm")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Algorithm", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-Signature")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Signature", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-SignedHeaders", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-Credential")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-Credential", valid_601599
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_601600 = formData.getOrDefault("LoadBalancerName")
  valid_601600 = validateParameter(valid_601600, JString, required = true,
                                 default = nil)
  if valid_601600 != nil:
    section.add "LoadBalancerName", valid_601600
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601601: Call_PostDescribeLoadBalancerAttributes_601588;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_601601.validator(path, query, header, formData, body)
  let scheme = call_601601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601601.url(scheme.get, call_601601.host, call_601601.base,
                         call_601601.route, valid.getOrDefault("path"))
  result = hook(call_601601, url, valid)

proc call*(call_601602: Call_PostDescribeLoadBalancerAttributes_601588;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_601603 = newJObject()
  var formData_601604 = newJObject()
  add(query_601603, "Action", newJString(Action))
  add(formData_601604, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601603, "Version", newJString(Version))
  result = call_601602.call(nil, query_601603, nil, formData_601604, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_601588(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_601589, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_601590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_601572 = ref object of OpenApiRestCall_600426
proc url_GetDescribeLoadBalancerAttributes_601574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancerAttributes_601573(path: JsonNode;
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
  var valid_601575 = query.getOrDefault("LoadBalancerName")
  valid_601575 = validateParameter(valid_601575, JString, required = true,
                                 default = nil)
  if valid_601575 != nil:
    section.add "LoadBalancerName", valid_601575
  var valid_601576 = query.getOrDefault("Action")
  valid_601576 = validateParameter(valid_601576, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_601576 != nil:
    section.add "Action", valid_601576
  var valid_601577 = query.getOrDefault("Version")
  valid_601577 = validateParameter(valid_601577, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601577 != nil:
    section.add "Version", valid_601577
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
  var valid_601578 = header.getOrDefault("X-Amz-Date")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Date", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Security-Token")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Security-Token", valid_601579
  var valid_601580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-Content-Sha256", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Algorithm")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Algorithm", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Signature")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Signature", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-SignedHeaders", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-Credential")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Credential", valid_601584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601585: Call_GetDescribeLoadBalancerAttributes_601572;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_601585.validator(path, query, header, formData, body)
  let scheme = call_601585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601585.url(scheme.get, call_601585.host, call_601585.base,
                         call_601585.route, valid.getOrDefault("path"))
  result = hook(call_601585, url, valid)

proc call*(call_601586: Call_GetDescribeLoadBalancerAttributes_601572;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601587 = newJObject()
  add(query_601587, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601587, "Action", newJString(Action))
  add(query_601587, "Version", newJString(Version))
  result = call_601586.call(nil, query_601587, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_601572(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_601573, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_601574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicies_601622 = ref object of OpenApiRestCall_600426
proc url_PostDescribeLoadBalancerPolicies_601624(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancerPolicies_601623(path: JsonNode;
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
  var valid_601625 = query.getOrDefault("Action")
  valid_601625 = validateParameter(valid_601625, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_601625 != nil:
    section.add "Action", valid_601625
  var valid_601626 = query.getOrDefault("Version")
  valid_601626 = validateParameter(valid_601626, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601626 != nil:
    section.add "Version", valid_601626
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
  var valid_601627 = header.getOrDefault("X-Amz-Date")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Date", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Security-Token")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Security-Token", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Content-Sha256", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Algorithm")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Algorithm", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-Signature")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Signature", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-SignedHeaders", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-Credential")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Credential", valid_601633
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   LoadBalancerName: JString
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_601634 = formData.getOrDefault("PolicyNames")
  valid_601634 = validateParameter(valid_601634, JArray, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "PolicyNames", valid_601634
  var valid_601635 = formData.getOrDefault("LoadBalancerName")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "LoadBalancerName", valid_601635
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601636: Call_PostDescribeLoadBalancerPolicies_601622;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_601636.validator(path, query, header, formData, body)
  let scheme = call_601636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601636.url(scheme.get, call_601636.host, call_601636.base,
                         call_601636.route, valid.getOrDefault("path"))
  result = hook(call_601636, url, valid)

proc call*(call_601637: Call_PostDescribeLoadBalancerPolicies_601622;
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
  var query_601638 = newJObject()
  var formData_601639 = newJObject()
  if PolicyNames != nil:
    formData_601639.add "PolicyNames", PolicyNames
  add(query_601638, "Action", newJString(Action))
  add(formData_601639, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601638, "Version", newJString(Version))
  result = call_601637.call(nil, query_601638, nil, formData_601639, nil)

var postDescribeLoadBalancerPolicies* = Call_PostDescribeLoadBalancerPolicies_601622(
    name: "postDescribeLoadBalancerPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_PostDescribeLoadBalancerPolicies_601623, base: "/",
    url: url_PostDescribeLoadBalancerPolicies_601624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicies_601605 = ref object of OpenApiRestCall_600426
proc url_GetDescribeLoadBalancerPolicies_601607(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancerPolicies_601606(path: JsonNode;
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
  var valid_601608 = query.getOrDefault("LoadBalancerName")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "LoadBalancerName", valid_601608
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601609 = query.getOrDefault("Action")
  valid_601609 = validateParameter(valid_601609, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_601609 != nil:
    section.add "Action", valid_601609
  var valid_601610 = query.getOrDefault("PolicyNames")
  valid_601610 = validateParameter(valid_601610, JArray, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "PolicyNames", valid_601610
  var valid_601611 = query.getOrDefault("Version")
  valid_601611 = validateParameter(valid_601611, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601611 != nil:
    section.add "Version", valid_601611
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
  var valid_601612 = header.getOrDefault("X-Amz-Date")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Date", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-Security-Token")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Security-Token", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Content-Sha256", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-Algorithm")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-Algorithm", valid_601615
  var valid_601616 = header.getOrDefault("X-Amz-Signature")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-Signature", valid_601616
  var valid_601617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-SignedHeaders", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Credential")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Credential", valid_601618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601619: Call_GetDescribeLoadBalancerPolicies_601605;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_601619.validator(path, query, header, formData, body)
  let scheme = call_601619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601619.url(scheme.get, call_601619.host, call_601619.base,
                         call_601619.route, valid.getOrDefault("path"))
  result = hook(call_601619, url, valid)

proc call*(call_601620: Call_GetDescribeLoadBalancerPolicies_601605;
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
  var query_601621 = newJObject()
  add(query_601621, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601621, "Action", newJString(Action))
  if PolicyNames != nil:
    query_601621.add "PolicyNames", PolicyNames
  add(query_601621, "Version", newJString(Version))
  result = call_601620.call(nil, query_601621, nil, nil, nil)

var getDescribeLoadBalancerPolicies* = Call_GetDescribeLoadBalancerPolicies_601605(
    name: "getDescribeLoadBalancerPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_GetDescribeLoadBalancerPolicies_601606, base: "/",
    url: url_GetDescribeLoadBalancerPolicies_601607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicyTypes_601656 = ref object of OpenApiRestCall_600426
proc url_PostDescribeLoadBalancerPolicyTypes_601658(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancerPolicyTypes_601657(path: JsonNode;
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
  var valid_601659 = query.getOrDefault("Action")
  valid_601659 = validateParameter(valid_601659, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_601659 != nil:
    section.add "Action", valid_601659
  var valid_601660 = query.getOrDefault("Version")
  valid_601660 = validateParameter(valid_601660, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601660 != nil:
    section.add "Version", valid_601660
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
  var valid_601661 = header.getOrDefault("X-Amz-Date")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-Date", valid_601661
  var valid_601662 = header.getOrDefault("X-Amz-Security-Token")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Security-Token", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Content-Sha256", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Algorithm")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Algorithm", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Signature")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Signature", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-SignedHeaders", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-Credential")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Credential", valid_601667
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  section = newJObject()
  var valid_601668 = formData.getOrDefault("PolicyTypeNames")
  valid_601668 = validateParameter(valid_601668, JArray, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "PolicyTypeNames", valid_601668
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601669: Call_PostDescribeLoadBalancerPolicyTypes_601656;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_601669.validator(path, query, header, formData, body)
  let scheme = call_601669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601669.url(scheme.get, call_601669.host, call_601669.base,
                         call_601669.route, valid.getOrDefault("path"))
  result = hook(call_601669, url, valid)

proc call*(call_601670: Call_PostDescribeLoadBalancerPolicyTypes_601656;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601671 = newJObject()
  var formData_601672 = newJObject()
  if PolicyTypeNames != nil:
    formData_601672.add "PolicyTypeNames", PolicyTypeNames
  add(query_601671, "Action", newJString(Action))
  add(query_601671, "Version", newJString(Version))
  result = call_601670.call(nil, query_601671, nil, formData_601672, nil)

var postDescribeLoadBalancerPolicyTypes* = Call_PostDescribeLoadBalancerPolicyTypes_601656(
    name: "postDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_PostDescribeLoadBalancerPolicyTypes_601657, base: "/",
    url: url_PostDescribeLoadBalancerPolicyTypes_601658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicyTypes_601640 = ref object of OpenApiRestCall_600426
proc url_GetDescribeLoadBalancerPolicyTypes_601642(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancerPolicyTypes_601641(path: JsonNode;
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
  var valid_601643 = query.getOrDefault("Action")
  valid_601643 = validateParameter(valid_601643, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_601643 != nil:
    section.add "Action", valid_601643
  var valid_601644 = query.getOrDefault("PolicyTypeNames")
  valid_601644 = validateParameter(valid_601644, JArray, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "PolicyTypeNames", valid_601644
  var valid_601645 = query.getOrDefault("Version")
  valid_601645 = validateParameter(valid_601645, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601645 != nil:
    section.add "Version", valid_601645
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
  var valid_601646 = header.getOrDefault("X-Amz-Date")
  valid_601646 = validateParameter(valid_601646, JString, required = false,
                                 default = nil)
  if valid_601646 != nil:
    section.add "X-Amz-Date", valid_601646
  var valid_601647 = header.getOrDefault("X-Amz-Security-Token")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Security-Token", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Content-Sha256", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Algorithm")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Algorithm", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Signature")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Signature", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-SignedHeaders", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-Credential")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Credential", valid_601652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601653: Call_GetDescribeLoadBalancerPolicyTypes_601640;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_601653.validator(path, query, header, formData, body)
  let scheme = call_601653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601653.url(scheme.get, call_601653.host, call_601653.base,
                         call_601653.route, valid.getOrDefault("path"))
  result = hook(call_601653, url, valid)

proc call*(call_601654: Call_GetDescribeLoadBalancerPolicyTypes_601640;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          PolicyTypeNames: JsonNode = nil; Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   Action: string (required)
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Version: string (required)
  var query_601655 = newJObject()
  add(query_601655, "Action", newJString(Action))
  if PolicyTypeNames != nil:
    query_601655.add "PolicyTypeNames", PolicyTypeNames
  add(query_601655, "Version", newJString(Version))
  result = call_601654.call(nil, query_601655, nil, nil, nil)

var getDescribeLoadBalancerPolicyTypes* = Call_GetDescribeLoadBalancerPolicyTypes_601640(
    name: "getDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_GetDescribeLoadBalancerPolicyTypes_601641, base: "/",
    url: url_GetDescribeLoadBalancerPolicyTypes_601642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_601691 = ref object of OpenApiRestCall_600426
proc url_PostDescribeLoadBalancers_601693(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancers_601692(path: JsonNode; query: JsonNode;
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
  var valid_601694 = query.getOrDefault("Action")
  valid_601694 = validateParameter(valid_601694, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_601694 != nil:
    section.add "Action", valid_601694
  var valid_601695 = query.getOrDefault("Version")
  valid_601695 = validateParameter(valid_601695, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601695 != nil:
    section.add "Version", valid_601695
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
  var valid_601696 = header.getOrDefault("X-Amz-Date")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Date", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Security-Token")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Security-Token", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Content-Sha256", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Algorithm")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Algorithm", valid_601699
  var valid_601700 = header.getOrDefault("X-Amz-Signature")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "X-Amz-Signature", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-SignedHeaders", valid_601701
  var valid_601702 = header.getOrDefault("X-Amz-Credential")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "X-Amz-Credential", valid_601702
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  section = newJObject()
  var valid_601703 = formData.getOrDefault("Marker")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "Marker", valid_601703
  var valid_601704 = formData.getOrDefault("LoadBalancerNames")
  valid_601704 = validateParameter(valid_601704, JArray, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "LoadBalancerNames", valid_601704
  var valid_601705 = formData.getOrDefault("PageSize")
  valid_601705 = validateParameter(valid_601705, JInt, required = false, default = nil)
  if valid_601705 != nil:
    section.add "PageSize", valid_601705
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601706: Call_PostDescribeLoadBalancers_601691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_601706.validator(path, query, header, formData, body)
  let scheme = call_601706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601706.url(scheme.get, call_601706.host, call_601706.base,
                         call_601706.route, valid.getOrDefault("path"))
  result = hook(call_601706, url, valid)

proc call*(call_601707: Call_PostDescribeLoadBalancers_601691; Marker: string = "";
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
  var query_601708 = newJObject()
  var formData_601709 = newJObject()
  add(formData_601709, "Marker", newJString(Marker))
  add(query_601708, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_601709.add "LoadBalancerNames", LoadBalancerNames
  add(formData_601709, "PageSize", newJInt(PageSize))
  add(query_601708, "Version", newJString(Version))
  result = call_601707.call(nil, query_601708, nil, formData_601709, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_601691(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_601692, base: "/",
    url: url_PostDescribeLoadBalancers_601693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_601673 = ref object of OpenApiRestCall_600426
proc url_GetDescribeLoadBalancers_601675(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancers_601674(path: JsonNode; query: JsonNode;
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
  var valid_601676 = query.getOrDefault("PageSize")
  valid_601676 = validateParameter(valid_601676, JInt, required = false, default = nil)
  if valid_601676 != nil:
    section.add "PageSize", valid_601676
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601677 = query.getOrDefault("Action")
  valid_601677 = validateParameter(valid_601677, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_601677 != nil:
    section.add "Action", valid_601677
  var valid_601678 = query.getOrDefault("Marker")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "Marker", valid_601678
  var valid_601679 = query.getOrDefault("LoadBalancerNames")
  valid_601679 = validateParameter(valid_601679, JArray, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "LoadBalancerNames", valid_601679
  var valid_601680 = query.getOrDefault("Version")
  valid_601680 = validateParameter(valid_601680, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601680 != nil:
    section.add "Version", valid_601680
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
  var valid_601681 = header.getOrDefault("X-Amz-Date")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Date", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-Security-Token")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Security-Token", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Content-Sha256", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-Algorithm")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Algorithm", valid_601684
  var valid_601685 = header.getOrDefault("X-Amz-Signature")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "X-Amz-Signature", valid_601685
  var valid_601686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "X-Amz-SignedHeaders", valid_601686
  var valid_601687 = header.getOrDefault("X-Amz-Credential")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-Credential", valid_601687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601688: Call_GetDescribeLoadBalancers_601673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_601688.validator(path, query, header, formData, body)
  let scheme = call_601688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601688.url(scheme.get, call_601688.host, call_601688.base,
                         call_601688.route, valid.getOrDefault("path"))
  result = hook(call_601688, url, valid)

proc call*(call_601689: Call_GetDescribeLoadBalancers_601673; PageSize: int = 0;
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
  var query_601690 = newJObject()
  add(query_601690, "PageSize", newJInt(PageSize))
  add(query_601690, "Action", newJString(Action))
  add(query_601690, "Marker", newJString(Marker))
  if LoadBalancerNames != nil:
    query_601690.add "LoadBalancerNames", LoadBalancerNames
  add(query_601690, "Version", newJString(Version))
  result = call_601689.call(nil, query_601690, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_601673(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_601674, base: "/",
    url: url_GetDescribeLoadBalancers_601675, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_601726 = ref object of OpenApiRestCall_600426
proc url_PostDescribeTags_601728(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTags_601727(path: JsonNode; query: JsonNode;
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
  var valid_601729 = query.getOrDefault("Action")
  valid_601729 = validateParameter(valid_601729, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_601729 != nil:
    section.add "Action", valid_601729
  var valid_601730 = query.getOrDefault("Version")
  valid_601730 = validateParameter(valid_601730, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601730 != nil:
    section.add "Version", valid_601730
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
  var valid_601731 = header.getOrDefault("X-Amz-Date")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Date", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-Security-Token")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-Security-Token", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-Content-Sha256", valid_601733
  var valid_601734 = header.getOrDefault("X-Amz-Algorithm")
  valid_601734 = validateParameter(valid_601734, JString, required = false,
                                 default = nil)
  if valid_601734 != nil:
    section.add "X-Amz-Algorithm", valid_601734
  var valid_601735 = header.getOrDefault("X-Amz-Signature")
  valid_601735 = validateParameter(valid_601735, JString, required = false,
                                 default = nil)
  if valid_601735 != nil:
    section.add "X-Amz-Signature", valid_601735
  var valid_601736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601736 = validateParameter(valid_601736, JString, required = false,
                                 default = nil)
  if valid_601736 != nil:
    section.add "X-Amz-SignedHeaders", valid_601736
  var valid_601737 = header.getOrDefault("X-Amz-Credential")
  valid_601737 = validateParameter(valid_601737, JString, required = false,
                                 default = nil)
  if valid_601737 != nil:
    section.add "X-Amz-Credential", valid_601737
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_601738 = formData.getOrDefault("LoadBalancerNames")
  valid_601738 = validateParameter(valid_601738, JArray, required = true, default = nil)
  if valid_601738 != nil:
    section.add "LoadBalancerNames", valid_601738
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601739: Call_PostDescribeTags_601726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_601739.validator(path, query, header, formData, body)
  let scheme = call_601739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601739.url(scheme.get, call_601739.host, call_601739.base,
                         call_601739.route, valid.getOrDefault("path"))
  result = hook(call_601739, url, valid)

proc call*(call_601740: Call_PostDescribeTags_601726; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_601741 = newJObject()
  var formData_601742 = newJObject()
  add(query_601741, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_601742.add "LoadBalancerNames", LoadBalancerNames
  add(query_601741, "Version", newJString(Version))
  result = call_601740.call(nil, query_601741, nil, formData_601742, nil)

var postDescribeTags* = Call_PostDescribeTags_601726(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_601727,
    base: "/", url: url_PostDescribeTags_601728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_601710 = ref object of OpenApiRestCall_600426
proc url_GetDescribeTags_601712(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTags_601711(path: JsonNode; query: JsonNode;
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
  var valid_601713 = query.getOrDefault("Action")
  valid_601713 = validateParameter(valid_601713, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_601713 != nil:
    section.add "Action", valid_601713
  var valid_601714 = query.getOrDefault("LoadBalancerNames")
  valid_601714 = validateParameter(valid_601714, JArray, required = true, default = nil)
  if valid_601714 != nil:
    section.add "LoadBalancerNames", valid_601714
  var valid_601715 = query.getOrDefault("Version")
  valid_601715 = validateParameter(valid_601715, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601715 != nil:
    section.add "Version", valid_601715
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
  var valid_601716 = header.getOrDefault("X-Amz-Date")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-Date", valid_601716
  var valid_601717 = header.getOrDefault("X-Amz-Security-Token")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-Security-Token", valid_601717
  var valid_601718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "X-Amz-Content-Sha256", valid_601718
  var valid_601719 = header.getOrDefault("X-Amz-Algorithm")
  valid_601719 = validateParameter(valid_601719, JString, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "X-Amz-Algorithm", valid_601719
  var valid_601720 = header.getOrDefault("X-Amz-Signature")
  valid_601720 = validateParameter(valid_601720, JString, required = false,
                                 default = nil)
  if valid_601720 != nil:
    section.add "X-Amz-Signature", valid_601720
  var valid_601721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601721 = validateParameter(valid_601721, JString, required = false,
                                 default = nil)
  if valid_601721 != nil:
    section.add "X-Amz-SignedHeaders", valid_601721
  var valid_601722 = header.getOrDefault("X-Amz-Credential")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Credential", valid_601722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601723: Call_GetDescribeTags_601710; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_601723.validator(path, query, header, formData, body)
  let scheme = call_601723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601723.url(scheme.get, call_601723.host, call_601723.base,
                         call_601723.route, valid.getOrDefault("path"))
  result = hook(call_601723, url, valid)

proc call*(call_601724: Call_GetDescribeTags_601710; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_601725 = newJObject()
  add(query_601725, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_601725.add "LoadBalancerNames", LoadBalancerNames
  add(query_601725, "Version", newJString(Version))
  result = call_601724.call(nil, query_601725, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_601710(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_601711,
    base: "/", url: url_GetDescribeTags_601712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDetachLoadBalancerFromSubnets_601760 = ref object of OpenApiRestCall_600426
proc url_PostDetachLoadBalancerFromSubnets_601762(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDetachLoadBalancerFromSubnets_601761(path: JsonNode;
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
  var valid_601763 = query.getOrDefault("Action")
  valid_601763 = validateParameter(valid_601763, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_601763 != nil:
    section.add "Action", valid_601763
  var valid_601764 = query.getOrDefault("Version")
  valid_601764 = validateParameter(valid_601764, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601764 != nil:
    section.add "Version", valid_601764
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
  var valid_601765 = header.getOrDefault("X-Amz-Date")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-Date", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-Security-Token")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-Security-Token", valid_601766
  var valid_601767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "X-Amz-Content-Sha256", valid_601767
  var valid_601768 = header.getOrDefault("X-Amz-Algorithm")
  valid_601768 = validateParameter(valid_601768, JString, required = false,
                                 default = nil)
  if valid_601768 != nil:
    section.add "X-Amz-Algorithm", valid_601768
  var valid_601769 = header.getOrDefault("X-Amz-Signature")
  valid_601769 = validateParameter(valid_601769, JString, required = false,
                                 default = nil)
  if valid_601769 != nil:
    section.add "X-Amz-Signature", valid_601769
  var valid_601770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601770 = validateParameter(valid_601770, JString, required = false,
                                 default = nil)
  if valid_601770 != nil:
    section.add "X-Amz-SignedHeaders", valid_601770
  var valid_601771 = header.getOrDefault("X-Amz-Credential")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "X-Amz-Credential", valid_601771
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_601772 = formData.getOrDefault("Subnets")
  valid_601772 = validateParameter(valid_601772, JArray, required = true, default = nil)
  if valid_601772 != nil:
    section.add "Subnets", valid_601772
  var valid_601773 = formData.getOrDefault("LoadBalancerName")
  valid_601773 = validateParameter(valid_601773, JString, required = true,
                                 default = nil)
  if valid_601773 != nil:
    section.add "LoadBalancerName", valid_601773
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601774: Call_PostDetachLoadBalancerFromSubnets_601760;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_601774.validator(path, query, header, formData, body)
  let scheme = call_601774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601774.url(scheme.get, call_601774.host, call_601774.base,
                         call_601774.route, valid.getOrDefault("path"))
  result = hook(call_601774, url, valid)

proc call*(call_601775: Call_PostDetachLoadBalancerFromSubnets_601760;
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
  var query_601776 = newJObject()
  var formData_601777 = newJObject()
  add(query_601776, "Action", newJString(Action))
  if Subnets != nil:
    formData_601777.add "Subnets", Subnets
  add(formData_601777, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601776, "Version", newJString(Version))
  result = call_601775.call(nil, query_601776, nil, formData_601777, nil)

var postDetachLoadBalancerFromSubnets* = Call_PostDetachLoadBalancerFromSubnets_601760(
    name: "postDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_PostDetachLoadBalancerFromSubnets_601761, base: "/",
    url: url_PostDetachLoadBalancerFromSubnets_601762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetachLoadBalancerFromSubnets_601743 = ref object of OpenApiRestCall_600426
proc url_GetDetachLoadBalancerFromSubnets_601745(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDetachLoadBalancerFromSubnets_601744(path: JsonNode;
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
  var valid_601746 = query.getOrDefault("LoadBalancerName")
  valid_601746 = validateParameter(valid_601746, JString, required = true,
                                 default = nil)
  if valid_601746 != nil:
    section.add "LoadBalancerName", valid_601746
  var valid_601747 = query.getOrDefault("Action")
  valid_601747 = validateParameter(valid_601747, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_601747 != nil:
    section.add "Action", valid_601747
  var valid_601748 = query.getOrDefault("Subnets")
  valid_601748 = validateParameter(valid_601748, JArray, required = true, default = nil)
  if valid_601748 != nil:
    section.add "Subnets", valid_601748
  var valid_601749 = query.getOrDefault("Version")
  valid_601749 = validateParameter(valid_601749, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601749 != nil:
    section.add "Version", valid_601749
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
  var valid_601750 = header.getOrDefault("X-Amz-Date")
  valid_601750 = validateParameter(valid_601750, JString, required = false,
                                 default = nil)
  if valid_601750 != nil:
    section.add "X-Amz-Date", valid_601750
  var valid_601751 = header.getOrDefault("X-Amz-Security-Token")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "X-Amz-Security-Token", valid_601751
  var valid_601752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601752 = validateParameter(valid_601752, JString, required = false,
                                 default = nil)
  if valid_601752 != nil:
    section.add "X-Amz-Content-Sha256", valid_601752
  var valid_601753 = header.getOrDefault("X-Amz-Algorithm")
  valid_601753 = validateParameter(valid_601753, JString, required = false,
                                 default = nil)
  if valid_601753 != nil:
    section.add "X-Amz-Algorithm", valid_601753
  var valid_601754 = header.getOrDefault("X-Amz-Signature")
  valid_601754 = validateParameter(valid_601754, JString, required = false,
                                 default = nil)
  if valid_601754 != nil:
    section.add "X-Amz-Signature", valid_601754
  var valid_601755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601755 = validateParameter(valid_601755, JString, required = false,
                                 default = nil)
  if valid_601755 != nil:
    section.add "X-Amz-SignedHeaders", valid_601755
  var valid_601756 = header.getOrDefault("X-Amz-Credential")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "X-Amz-Credential", valid_601756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601757: Call_GetDetachLoadBalancerFromSubnets_601743;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_601757.validator(path, query, header, formData, body)
  let scheme = call_601757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601757.url(scheme.get, call_601757.host, call_601757.base,
                         call_601757.route, valid.getOrDefault("path"))
  result = hook(call_601757, url, valid)

proc call*(call_601758: Call_GetDetachLoadBalancerFromSubnets_601743;
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
  var query_601759 = newJObject()
  add(query_601759, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601759, "Action", newJString(Action))
  if Subnets != nil:
    query_601759.add "Subnets", Subnets
  add(query_601759, "Version", newJString(Version))
  result = call_601758.call(nil, query_601759, nil, nil, nil)

var getDetachLoadBalancerFromSubnets* = Call_GetDetachLoadBalancerFromSubnets_601743(
    name: "getDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_GetDetachLoadBalancerFromSubnets_601744, base: "/",
    url: url_GetDetachLoadBalancerFromSubnets_601745,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAvailabilityZonesForLoadBalancer_601795 = ref object of OpenApiRestCall_600426
proc url_PostDisableAvailabilityZonesForLoadBalancer_601797(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDisableAvailabilityZonesForLoadBalancer_601796(path: JsonNode;
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
  var valid_601798 = query.getOrDefault("Action")
  valid_601798 = validateParameter(valid_601798, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_601798 != nil:
    section.add "Action", valid_601798
  var valid_601799 = query.getOrDefault("Version")
  valid_601799 = validateParameter(valid_601799, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601799 != nil:
    section.add "Version", valid_601799
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
  var valid_601800 = header.getOrDefault("X-Amz-Date")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-Date", valid_601800
  var valid_601801 = header.getOrDefault("X-Amz-Security-Token")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "X-Amz-Security-Token", valid_601801
  var valid_601802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601802 = validateParameter(valid_601802, JString, required = false,
                                 default = nil)
  if valid_601802 != nil:
    section.add "X-Amz-Content-Sha256", valid_601802
  var valid_601803 = header.getOrDefault("X-Amz-Algorithm")
  valid_601803 = validateParameter(valid_601803, JString, required = false,
                                 default = nil)
  if valid_601803 != nil:
    section.add "X-Amz-Algorithm", valid_601803
  var valid_601804 = header.getOrDefault("X-Amz-Signature")
  valid_601804 = validateParameter(valid_601804, JString, required = false,
                                 default = nil)
  if valid_601804 != nil:
    section.add "X-Amz-Signature", valid_601804
  var valid_601805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601805 = validateParameter(valid_601805, JString, required = false,
                                 default = nil)
  if valid_601805 != nil:
    section.add "X-Amz-SignedHeaders", valid_601805
  var valid_601806 = header.getOrDefault("X-Amz-Credential")
  valid_601806 = validateParameter(valid_601806, JString, required = false,
                                 default = nil)
  if valid_601806 != nil:
    section.add "X-Amz-Credential", valid_601806
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_601807 = formData.getOrDefault("AvailabilityZones")
  valid_601807 = validateParameter(valid_601807, JArray, required = true, default = nil)
  if valid_601807 != nil:
    section.add "AvailabilityZones", valid_601807
  var valid_601808 = formData.getOrDefault("LoadBalancerName")
  valid_601808 = validateParameter(valid_601808, JString, required = true,
                                 default = nil)
  if valid_601808 != nil:
    section.add "LoadBalancerName", valid_601808
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601809: Call_PostDisableAvailabilityZonesForLoadBalancer_601795;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601809.validator(path, query, header, formData, body)
  let scheme = call_601809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601809.url(scheme.get, call_601809.host, call_601809.base,
                         call_601809.route, valid.getOrDefault("path"))
  result = hook(call_601809, url, valid)

proc call*(call_601810: Call_PostDisableAvailabilityZonesForLoadBalancer_601795;
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
  var query_601811 = newJObject()
  var formData_601812 = newJObject()
  add(query_601811, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_601812.add "AvailabilityZones", AvailabilityZones
  add(formData_601812, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601811, "Version", newJString(Version))
  result = call_601810.call(nil, query_601811, nil, formData_601812, nil)

var postDisableAvailabilityZonesForLoadBalancer* = Call_PostDisableAvailabilityZonesForLoadBalancer_601795(
    name: "postDisableAvailabilityZonesForLoadBalancer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_PostDisableAvailabilityZonesForLoadBalancer_601796,
    base: "/", url: url_PostDisableAvailabilityZonesForLoadBalancer_601797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAvailabilityZonesForLoadBalancer_601778 = ref object of OpenApiRestCall_600426
proc url_GetDisableAvailabilityZonesForLoadBalancer_601780(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDisableAvailabilityZonesForLoadBalancer_601779(path: JsonNode;
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
  var valid_601781 = query.getOrDefault("LoadBalancerName")
  valid_601781 = validateParameter(valid_601781, JString, required = true,
                                 default = nil)
  if valid_601781 != nil:
    section.add "LoadBalancerName", valid_601781
  var valid_601782 = query.getOrDefault("AvailabilityZones")
  valid_601782 = validateParameter(valid_601782, JArray, required = true, default = nil)
  if valid_601782 != nil:
    section.add "AvailabilityZones", valid_601782
  var valid_601783 = query.getOrDefault("Action")
  valid_601783 = validateParameter(valid_601783, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_601783 != nil:
    section.add "Action", valid_601783
  var valid_601784 = query.getOrDefault("Version")
  valid_601784 = validateParameter(valid_601784, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601784 != nil:
    section.add "Version", valid_601784
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
  var valid_601785 = header.getOrDefault("X-Amz-Date")
  valid_601785 = validateParameter(valid_601785, JString, required = false,
                                 default = nil)
  if valid_601785 != nil:
    section.add "X-Amz-Date", valid_601785
  var valid_601786 = header.getOrDefault("X-Amz-Security-Token")
  valid_601786 = validateParameter(valid_601786, JString, required = false,
                                 default = nil)
  if valid_601786 != nil:
    section.add "X-Amz-Security-Token", valid_601786
  var valid_601787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601787 = validateParameter(valid_601787, JString, required = false,
                                 default = nil)
  if valid_601787 != nil:
    section.add "X-Amz-Content-Sha256", valid_601787
  var valid_601788 = header.getOrDefault("X-Amz-Algorithm")
  valid_601788 = validateParameter(valid_601788, JString, required = false,
                                 default = nil)
  if valid_601788 != nil:
    section.add "X-Amz-Algorithm", valid_601788
  var valid_601789 = header.getOrDefault("X-Amz-Signature")
  valid_601789 = validateParameter(valid_601789, JString, required = false,
                                 default = nil)
  if valid_601789 != nil:
    section.add "X-Amz-Signature", valid_601789
  var valid_601790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601790 = validateParameter(valid_601790, JString, required = false,
                                 default = nil)
  if valid_601790 != nil:
    section.add "X-Amz-SignedHeaders", valid_601790
  var valid_601791 = header.getOrDefault("X-Amz-Credential")
  valid_601791 = validateParameter(valid_601791, JString, required = false,
                                 default = nil)
  if valid_601791 != nil:
    section.add "X-Amz-Credential", valid_601791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601792: Call_GetDisableAvailabilityZonesForLoadBalancer_601778;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601792.validator(path, query, header, formData, body)
  let scheme = call_601792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601792.url(scheme.get, call_601792.host, call_601792.base,
                         call_601792.route, valid.getOrDefault("path"))
  result = hook(call_601792, url, valid)

proc call*(call_601793: Call_GetDisableAvailabilityZonesForLoadBalancer_601778;
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
  var query_601794 = newJObject()
  add(query_601794, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_601794.add "AvailabilityZones", AvailabilityZones
  add(query_601794, "Action", newJString(Action))
  add(query_601794, "Version", newJString(Version))
  result = call_601793.call(nil, query_601794, nil, nil, nil)

var getDisableAvailabilityZonesForLoadBalancer* = Call_GetDisableAvailabilityZonesForLoadBalancer_601778(
    name: "getDisableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_GetDisableAvailabilityZonesForLoadBalancer_601779,
    base: "/", url: url_GetDisableAvailabilityZonesForLoadBalancer_601780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAvailabilityZonesForLoadBalancer_601830 = ref object of OpenApiRestCall_600426
proc url_PostEnableAvailabilityZonesForLoadBalancer_601832(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostEnableAvailabilityZonesForLoadBalancer_601831(path: JsonNode;
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
  var valid_601833 = query.getOrDefault("Action")
  valid_601833 = validateParameter(valid_601833, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_601833 != nil:
    section.add "Action", valid_601833
  var valid_601834 = query.getOrDefault("Version")
  valid_601834 = validateParameter(valid_601834, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601834 != nil:
    section.add "Version", valid_601834
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
  var valid_601835 = header.getOrDefault("X-Amz-Date")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "X-Amz-Date", valid_601835
  var valid_601836 = header.getOrDefault("X-Amz-Security-Token")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-Security-Token", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-Content-Sha256", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-Algorithm")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-Algorithm", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Signature")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Signature", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-SignedHeaders", valid_601840
  var valid_601841 = header.getOrDefault("X-Amz-Credential")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Credential", valid_601841
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_601842 = formData.getOrDefault("AvailabilityZones")
  valid_601842 = validateParameter(valid_601842, JArray, required = true, default = nil)
  if valid_601842 != nil:
    section.add "AvailabilityZones", valid_601842
  var valid_601843 = formData.getOrDefault("LoadBalancerName")
  valid_601843 = validateParameter(valid_601843, JString, required = true,
                                 default = nil)
  if valid_601843 != nil:
    section.add "LoadBalancerName", valid_601843
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601844: Call_PostEnableAvailabilityZonesForLoadBalancer_601830;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601844.validator(path, query, header, formData, body)
  let scheme = call_601844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601844.url(scheme.get, call_601844.host, call_601844.base,
                         call_601844.route, valid.getOrDefault("path"))
  result = hook(call_601844, url, valid)

proc call*(call_601845: Call_PostEnableAvailabilityZonesForLoadBalancer_601830;
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
  var query_601846 = newJObject()
  var formData_601847 = newJObject()
  add(query_601846, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_601847.add "AvailabilityZones", AvailabilityZones
  add(formData_601847, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601846, "Version", newJString(Version))
  result = call_601845.call(nil, query_601846, nil, formData_601847, nil)

var postEnableAvailabilityZonesForLoadBalancer* = Call_PostEnableAvailabilityZonesForLoadBalancer_601830(
    name: "postEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_PostEnableAvailabilityZonesForLoadBalancer_601831,
    base: "/", url: url_PostEnableAvailabilityZonesForLoadBalancer_601832,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAvailabilityZonesForLoadBalancer_601813 = ref object of OpenApiRestCall_600426
proc url_GetEnableAvailabilityZonesForLoadBalancer_601815(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetEnableAvailabilityZonesForLoadBalancer_601814(path: JsonNode;
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
  var valid_601816 = query.getOrDefault("LoadBalancerName")
  valid_601816 = validateParameter(valid_601816, JString, required = true,
                                 default = nil)
  if valid_601816 != nil:
    section.add "LoadBalancerName", valid_601816
  var valid_601817 = query.getOrDefault("AvailabilityZones")
  valid_601817 = validateParameter(valid_601817, JArray, required = true, default = nil)
  if valid_601817 != nil:
    section.add "AvailabilityZones", valid_601817
  var valid_601818 = query.getOrDefault("Action")
  valid_601818 = validateParameter(valid_601818, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_601818 != nil:
    section.add "Action", valid_601818
  var valid_601819 = query.getOrDefault("Version")
  valid_601819 = validateParameter(valid_601819, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601819 != nil:
    section.add "Version", valid_601819
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
  var valid_601820 = header.getOrDefault("X-Amz-Date")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = nil)
  if valid_601820 != nil:
    section.add "X-Amz-Date", valid_601820
  var valid_601821 = header.getOrDefault("X-Amz-Security-Token")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-Security-Token", valid_601821
  var valid_601822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "X-Amz-Content-Sha256", valid_601822
  var valid_601823 = header.getOrDefault("X-Amz-Algorithm")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "X-Amz-Algorithm", valid_601823
  var valid_601824 = header.getOrDefault("X-Amz-Signature")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "X-Amz-Signature", valid_601824
  var valid_601825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "X-Amz-SignedHeaders", valid_601825
  var valid_601826 = header.getOrDefault("X-Amz-Credential")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-Credential", valid_601826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601827: Call_GetEnableAvailabilityZonesForLoadBalancer_601813;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601827.validator(path, query, header, formData, body)
  let scheme = call_601827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601827.url(scheme.get, call_601827.host, call_601827.base,
                         call_601827.route, valid.getOrDefault("path"))
  result = hook(call_601827, url, valid)

proc call*(call_601828: Call_GetEnableAvailabilityZonesForLoadBalancer_601813;
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
  var query_601829 = newJObject()
  add(query_601829, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_601829.add "AvailabilityZones", AvailabilityZones
  add(query_601829, "Action", newJString(Action))
  add(query_601829, "Version", newJString(Version))
  result = call_601828.call(nil, query_601829, nil, nil, nil)

var getEnableAvailabilityZonesForLoadBalancer* = Call_GetEnableAvailabilityZonesForLoadBalancer_601813(
    name: "getEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_GetEnableAvailabilityZonesForLoadBalancer_601814,
    base: "/", url: url_GetEnableAvailabilityZonesForLoadBalancer_601815,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_601869 = ref object of OpenApiRestCall_600426
proc url_PostModifyLoadBalancerAttributes_601871(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyLoadBalancerAttributes_601870(path: JsonNode;
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
  var valid_601872 = query.getOrDefault("Action")
  valid_601872 = validateParameter(valid_601872, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_601872 != nil:
    section.add "Action", valid_601872
  var valid_601873 = query.getOrDefault("Version")
  valid_601873 = validateParameter(valid_601873, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601873 != nil:
    section.add "Version", valid_601873
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
  var valid_601874 = header.getOrDefault("X-Amz-Date")
  valid_601874 = validateParameter(valid_601874, JString, required = false,
                                 default = nil)
  if valid_601874 != nil:
    section.add "X-Amz-Date", valid_601874
  var valid_601875 = header.getOrDefault("X-Amz-Security-Token")
  valid_601875 = validateParameter(valid_601875, JString, required = false,
                                 default = nil)
  if valid_601875 != nil:
    section.add "X-Amz-Security-Token", valid_601875
  var valid_601876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601876 = validateParameter(valid_601876, JString, required = false,
                                 default = nil)
  if valid_601876 != nil:
    section.add "X-Amz-Content-Sha256", valid_601876
  var valid_601877 = header.getOrDefault("X-Amz-Algorithm")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "X-Amz-Algorithm", valid_601877
  var valid_601878 = header.getOrDefault("X-Amz-Signature")
  valid_601878 = validateParameter(valid_601878, JString, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "X-Amz-Signature", valid_601878
  var valid_601879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601879 = validateParameter(valid_601879, JString, required = false,
                                 default = nil)
  if valid_601879 != nil:
    section.add "X-Amz-SignedHeaders", valid_601879
  var valid_601880 = header.getOrDefault("X-Amz-Credential")
  valid_601880 = validateParameter(valid_601880, JString, required = false,
                                 default = nil)
  if valid_601880 != nil:
    section.add "X-Amz-Credential", valid_601880
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
  var valid_601881 = formData.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_601881 = validateParameter(valid_601881, JArray, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_601881
  var valid_601882 = formData.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_601882 = validateParameter(valid_601882, JString, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_601882
  var valid_601883 = formData.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_601883 = validateParameter(valid_601883, JString, required = false,
                                 default = nil)
  if valid_601883 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_601883
  var valid_601884 = formData.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_601884
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_601885 = formData.getOrDefault("LoadBalancerName")
  valid_601885 = validateParameter(valid_601885, JString, required = true,
                                 default = nil)
  if valid_601885 != nil:
    section.add "LoadBalancerName", valid_601885
  var valid_601886 = formData.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_601886
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601887: Call_PostModifyLoadBalancerAttributes_601869;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_601887.validator(path, query, header, formData, body)
  let scheme = call_601887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601887.url(scheme.get, call_601887.host, call_601887.base,
                         call_601887.route, valid.getOrDefault("path"))
  result = hook(call_601887, url, valid)

proc call*(call_601888: Call_PostModifyLoadBalancerAttributes_601869;
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
  var query_601889 = newJObject()
  var formData_601890 = newJObject()
  if LoadBalancerAttributesAdditionalAttributes != nil:
    formData_601890.add "LoadBalancerAttributes.AdditionalAttributes",
                       LoadBalancerAttributesAdditionalAttributes
  add(formData_601890, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  add(formData_601890, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_601889, "Action", newJString(Action))
  add(formData_601890, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(formData_601890, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_601890, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_601889, "Version", newJString(Version))
  result = call_601888.call(nil, query_601889, nil, formData_601890, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_601869(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_601870, base: "/",
    url: url_PostModifyLoadBalancerAttributes_601871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_601848 = ref object of OpenApiRestCall_600426
proc url_GetModifyLoadBalancerAttributes_601850(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyLoadBalancerAttributes_601849(path: JsonNode;
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
  var valid_601851 = query.getOrDefault("LoadBalancerName")
  valid_601851 = validateParameter(valid_601851, JString, required = true,
                                 default = nil)
  if valid_601851 != nil:
    section.add "LoadBalancerName", valid_601851
  var valid_601852 = query.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_601852
  var valid_601853 = query.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_601853
  var valid_601854 = query.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_601854 = validateParameter(valid_601854, JArray, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_601854
  var valid_601855 = query.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_601855
  var valid_601856 = query.getOrDefault("Action")
  valid_601856 = validateParameter(valid_601856, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_601856 != nil:
    section.add "Action", valid_601856
  var valid_601857 = query.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_601857
  var valid_601858 = query.getOrDefault("Version")
  valid_601858 = validateParameter(valid_601858, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601858 != nil:
    section.add "Version", valid_601858
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
  var valid_601859 = header.getOrDefault("X-Amz-Date")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Date", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Security-Token")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Security-Token", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Content-Sha256", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Algorithm")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Algorithm", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Signature")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Signature", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-SignedHeaders", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-Credential")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-Credential", valid_601865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601866: Call_GetModifyLoadBalancerAttributes_601848;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_601866.validator(path, query, header, formData, body)
  let scheme = call_601866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601866.url(scheme.get, call_601866.host, call_601866.base,
                         call_601866.route, valid.getOrDefault("path"))
  result = hook(call_601866, url, valid)

proc call*(call_601867: Call_GetModifyLoadBalancerAttributes_601848;
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
  var query_601868 = newJObject()
  add(query_601868, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601868, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_601868, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    query_601868.add "LoadBalancerAttributes.AdditionalAttributes",
                    LoadBalancerAttributesAdditionalAttributes
  add(query_601868, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_601868, "Action", newJString(Action))
  add(query_601868, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_601868, "Version", newJString(Version))
  result = call_601867.call(nil, query_601868, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_601848(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_601849, base: "/",
    url: url_GetModifyLoadBalancerAttributes_601850,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterInstancesWithLoadBalancer_601908 = ref object of OpenApiRestCall_600426
proc url_PostRegisterInstancesWithLoadBalancer_601910(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRegisterInstancesWithLoadBalancer_601909(path: JsonNode;
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
  var valid_601911 = query.getOrDefault("Action")
  valid_601911 = validateParameter(valid_601911, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_601911 != nil:
    section.add "Action", valid_601911
  var valid_601912 = query.getOrDefault("Version")
  valid_601912 = validateParameter(valid_601912, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601912 != nil:
    section.add "Version", valid_601912
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
  var valid_601913 = header.getOrDefault("X-Amz-Date")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-Date", valid_601913
  var valid_601914 = header.getOrDefault("X-Amz-Security-Token")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-Security-Token", valid_601914
  var valid_601915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-Content-Sha256", valid_601915
  var valid_601916 = header.getOrDefault("X-Amz-Algorithm")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "X-Amz-Algorithm", valid_601916
  var valid_601917 = header.getOrDefault("X-Amz-Signature")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "X-Amz-Signature", valid_601917
  var valid_601918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601918 = validateParameter(valid_601918, JString, required = false,
                                 default = nil)
  if valid_601918 != nil:
    section.add "X-Amz-SignedHeaders", valid_601918
  var valid_601919 = header.getOrDefault("X-Amz-Credential")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Credential", valid_601919
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_601920 = formData.getOrDefault("Instances")
  valid_601920 = validateParameter(valid_601920, JArray, required = true, default = nil)
  if valid_601920 != nil:
    section.add "Instances", valid_601920
  var valid_601921 = formData.getOrDefault("LoadBalancerName")
  valid_601921 = validateParameter(valid_601921, JString, required = true,
                                 default = nil)
  if valid_601921 != nil:
    section.add "LoadBalancerName", valid_601921
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601922: Call_PostRegisterInstancesWithLoadBalancer_601908;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601922.validator(path, query, header, formData, body)
  let scheme = call_601922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601922.url(scheme.get, call_601922.host, call_601922.base,
                         call_601922.route, valid.getOrDefault("path"))
  result = hook(call_601922, url, valid)

proc call*(call_601923: Call_PostRegisterInstancesWithLoadBalancer_601908;
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
  var query_601924 = newJObject()
  var formData_601925 = newJObject()
  if Instances != nil:
    formData_601925.add "Instances", Instances
  add(query_601924, "Action", newJString(Action))
  add(formData_601925, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601924, "Version", newJString(Version))
  result = call_601923.call(nil, query_601924, nil, formData_601925, nil)

var postRegisterInstancesWithLoadBalancer* = Call_PostRegisterInstancesWithLoadBalancer_601908(
    name: "postRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_PostRegisterInstancesWithLoadBalancer_601909, base: "/",
    url: url_PostRegisterInstancesWithLoadBalancer_601910,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterInstancesWithLoadBalancer_601891 = ref object of OpenApiRestCall_600426
proc url_GetRegisterInstancesWithLoadBalancer_601893(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRegisterInstancesWithLoadBalancer_601892(path: JsonNode;
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
  var valid_601894 = query.getOrDefault("LoadBalancerName")
  valid_601894 = validateParameter(valid_601894, JString, required = true,
                                 default = nil)
  if valid_601894 != nil:
    section.add "LoadBalancerName", valid_601894
  var valid_601895 = query.getOrDefault("Action")
  valid_601895 = validateParameter(valid_601895, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_601895 != nil:
    section.add "Action", valid_601895
  var valid_601896 = query.getOrDefault("Instances")
  valid_601896 = validateParameter(valid_601896, JArray, required = true, default = nil)
  if valid_601896 != nil:
    section.add "Instances", valid_601896
  var valid_601897 = query.getOrDefault("Version")
  valid_601897 = validateParameter(valid_601897, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601897 != nil:
    section.add "Version", valid_601897
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
  var valid_601898 = header.getOrDefault("X-Amz-Date")
  valid_601898 = validateParameter(valid_601898, JString, required = false,
                                 default = nil)
  if valid_601898 != nil:
    section.add "X-Amz-Date", valid_601898
  var valid_601899 = header.getOrDefault("X-Amz-Security-Token")
  valid_601899 = validateParameter(valid_601899, JString, required = false,
                                 default = nil)
  if valid_601899 != nil:
    section.add "X-Amz-Security-Token", valid_601899
  var valid_601900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601900 = validateParameter(valid_601900, JString, required = false,
                                 default = nil)
  if valid_601900 != nil:
    section.add "X-Amz-Content-Sha256", valid_601900
  var valid_601901 = header.getOrDefault("X-Amz-Algorithm")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "X-Amz-Algorithm", valid_601901
  var valid_601902 = header.getOrDefault("X-Amz-Signature")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "X-Amz-Signature", valid_601902
  var valid_601903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601903 = validateParameter(valid_601903, JString, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "X-Amz-SignedHeaders", valid_601903
  var valid_601904 = header.getOrDefault("X-Amz-Credential")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "X-Amz-Credential", valid_601904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601905: Call_GetRegisterInstancesWithLoadBalancer_601891;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601905.validator(path, query, header, formData, body)
  let scheme = call_601905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601905.url(scheme.get, call_601905.host, call_601905.base,
                         call_601905.route, valid.getOrDefault("path"))
  result = hook(call_601905, url, valid)

proc call*(call_601906: Call_GetRegisterInstancesWithLoadBalancer_601891;
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
  var query_601907 = newJObject()
  add(query_601907, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601907, "Action", newJString(Action))
  if Instances != nil:
    query_601907.add "Instances", Instances
  add(query_601907, "Version", newJString(Version))
  result = call_601906.call(nil, query_601907, nil, nil, nil)

var getRegisterInstancesWithLoadBalancer* = Call_GetRegisterInstancesWithLoadBalancer_601891(
    name: "getRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_GetRegisterInstancesWithLoadBalancer_601892, base: "/",
    url: url_GetRegisterInstancesWithLoadBalancer_601893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_601943 = ref object of OpenApiRestCall_600426
proc url_PostRemoveTags_601945(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTags_601944(path: JsonNode; query: JsonNode;
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
  var valid_601946 = query.getOrDefault("Action")
  valid_601946 = validateParameter(valid_601946, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_601946 != nil:
    section.add "Action", valid_601946
  var valid_601947 = query.getOrDefault("Version")
  valid_601947 = validateParameter(valid_601947, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601947 != nil:
    section.add "Version", valid_601947
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
  var valid_601948 = header.getOrDefault("X-Amz-Date")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "X-Amz-Date", valid_601948
  var valid_601949 = header.getOrDefault("X-Amz-Security-Token")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "X-Amz-Security-Token", valid_601949
  var valid_601950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Content-Sha256", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-Algorithm")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Algorithm", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-Signature")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-Signature", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-SignedHeaders", valid_601953
  var valid_601954 = header.getOrDefault("X-Amz-Credential")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "X-Amz-Credential", valid_601954
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_601955 = formData.getOrDefault("Tags")
  valid_601955 = validateParameter(valid_601955, JArray, required = true, default = nil)
  if valid_601955 != nil:
    section.add "Tags", valid_601955
  var valid_601956 = formData.getOrDefault("LoadBalancerNames")
  valid_601956 = validateParameter(valid_601956, JArray, required = true, default = nil)
  if valid_601956 != nil:
    section.add "LoadBalancerNames", valid_601956
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601957: Call_PostRemoveTags_601943; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_601957.validator(path, query, header, formData, body)
  let scheme = call_601957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601957.url(scheme.get, call_601957.host, call_601957.base,
                         call_601957.route, valid.getOrDefault("path"))
  result = hook(call_601957, url, valid)

proc call*(call_601958: Call_PostRemoveTags_601943; Tags: JsonNode;
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
  var query_601959 = newJObject()
  var formData_601960 = newJObject()
  if Tags != nil:
    formData_601960.add "Tags", Tags
  add(query_601959, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_601960.add "LoadBalancerNames", LoadBalancerNames
  add(query_601959, "Version", newJString(Version))
  result = call_601958.call(nil, query_601959, nil, formData_601960, nil)

var postRemoveTags* = Call_PostRemoveTags_601943(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_601944,
    base: "/", url: url_PostRemoveTags_601945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_601926 = ref object of OpenApiRestCall_600426
proc url_GetRemoveTags_601928(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTags_601927(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601929 = query.getOrDefault("Tags")
  valid_601929 = validateParameter(valid_601929, JArray, required = true, default = nil)
  if valid_601929 != nil:
    section.add "Tags", valid_601929
  var valid_601930 = query.getOrDefault("Action")
  valid_601930 = validateParameter(valid_601930, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_601930 != nil:
    section.add "Action", valid_601930
  var valid_601931 = query.getOrDefault("LoadBalancerNames")
  valid_601931 = validateParameter(valid_601931, JArray, required = true, default = nil)
  if valid_601931 != nil:
    section.add "LoadBalancerNames", valid_601931
  var valid_601932 = query.getOrDefault("Version")
  valid_601932 = validateParameter(valid_601932, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601932 != nil:
    section.add "Version", valid_601932
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
  var valid_601933 = header.getOrDefault("X-Amz-Date")
  valid_601933 = validateParameter(valid_601933, JString, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "X-Amz-Date", valid_601933
  var valid_601934 = header.getOrDefault("X-Amz-Security-Token")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-Security-Token", valid_601934
  var valid_601935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-Content-Sha256", valid_601935
  var valid_601936 = header.getOrDefault("X-Amz-Algorithm")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "X-Amz-Algorithm", valid_601936
  var valid_601937 = header.getOrDefault("X-Amz-Signature")
  valid_601937 = validateParameter(valid_601937, JString, required = false,
                                 default = nil)
  if valid_601937 != nil:
    section.add "X-Amz-Signature", valid_601937
  var valid_601938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "X-Amz-SignedHeaders", valid_601938
  var valid_601939 = header.getOrDefault("X-Amz-Credential")
  valid_601939 = validateParameter(valid_601939, JString, required = false,
                                 default = nil)
  if valid_601939 != nil:
    section.add "X-Amz-Credential", valid_601939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601940: Call_GetRemoveTags_601926; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_601940.validator(path, query, header, formData, body)
  let scheme = call_601940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601940.url(scheme.get, call_601940.host, call_601940.base,
                         call_601940.route, valid.getOrDefault("path"))
  result = hook(call_601940, url, valid)

proc call*(call_601941: Call_GetRemoveTags_601926; Tags: JsonNode;
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
  var query_601942 = newJObject()
  if Tags != nil:
    query_601942.add "Tags", Tags
  add(query_601942, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_601942.add "LoadBalancerNames", LoadBalancerNames
  add(query_601942, "Version", newJString(Version))
  result = call_601941.call(nil, query_601942, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_601926(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_601927,
    base: "/", url: url_GetRemoveTags_601928, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerListenerSSLCertificate_601979 = ref object of OpenApiRestCall_600426
proc url_PostSetLoadBalancerListenerSSLCertificate_601981(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetLoadBalancerListenerSSLCertificate_601980(path: JsonNode;
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
  var valid_601982 = query.getOrDefault("Action")
  valid_601982 = validateParameter(valid_601982, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_601982 != nil:
    section.add "Action", valid_601982
  var valid_601983 = query.getOrDefault("Version")
  valid_601983 = validateParameter(valid_601983, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601983 != nil:
    section.add "Version", valid_601983
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
  var valid_601984 = header.getOrDefault("X-Amz-Date")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "X-Amz-Date", valid_601984
  var valid_601985 = header.getOrDefault("X-Amz-Security-Token")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "X-Amz-Security-Token", valid_601985
  var valid_601986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "X-Amz-Content-Sha256", valid_601986
  var valid_601987 = header.getOrDefault("X-Amz-Algorithm")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Algorithm", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-Signature")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Signature", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-SignedHeaders", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Credential")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Credential", valid_601990
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
  var valid_601991 = formData.getOrDefault("LoadBalancerPort")
  valid_601991 = validateParameter(valid_601991, JInt, required = true, default = nil)
  if valid_601991 != nil:
    section.add "LoadBalancerPort", valid_601991
  var valid_601992 = formData.getOrDefault("SSLCertificateId")
  valid_601992 = validateParameter(valid_601992, JString, required = true,
                                 default = nil)
  if valid_601992 != nil:
    section.add "SSLCertificateId", valid_601992
  var valid_601993 = formData.getOrDefault("LoadBalancerName")
  valid_601993 = validateParameter(valid_601993, JString, required = true,
                                 default = nil)
  if valid_601993 != nil:
    section.add "LoadBalancerName", valid_601993
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601994: Call_PostSetLoadBalancerListenerSSLCertificate_601979;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601994.validator(path, query, header, formData, body)
  let scheme = call_601994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601994.url(scheme.get, call_601994.host, call_601994.base,
                         call_601994.route, valid.getOrDefault("path"))
  result = hook(call_601994, url, valid)

proc call*(call_601995: Call_PostSetLoadBalancerListenerSSLCertificate_601979;
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
  var query_601996 = newJObject()
  var formData_601997 = newJObject()
  add(formData_601997, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(formData_601997, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_601996, "Action", newJString(Action))
  add(formData_601997, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601996, "Version", newJString(Version))
  result = call_601995.call(nil, query_601996, nil, formData_601997, nil)

var postSetLoadBalancerListenerSSLCertificate* = Call_PostSetLoadBalancerListenerSSLCertificate_601979(
    name: "postSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_PostSetLoadBalancerListenerSSLCertificate_601980,
    base: "/", url: url_PostSetLoadBalancerListenerSSLCertificate_601981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerListenerSSLCertificate_601961 = ref object of OpenApiRestCall_600426
proc url_GetSetLoadBalancerListenerSSLCertificate_601963(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetLoadBalancerListenerSSLCertificate_601962(path: JsonNode;
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
  var valid_601964 = query.getOrDefault("LoadBalancerName")
  valid_601964 = validateParameter(valid_601964, JString, required = true,
                                 default = nil)
  if valid_601964 != nil:
    section.add "LoadBalancerName", valid_601964
  var valid_601965 = query.getOrDefault("SSLCertificateId")
  valid_601965 = validateParameter(valid_601965, JString, required = true,
                                 default = nil)
  if valid_601965 != nil:
    section.add "SSLCertificateId", valid_601965
  var valid_601966 = query.getOrDefault("LoadBalancerPort")
  valid_601966 = validateParameter(valid_601966, JInt, required = true, default = nil)
  if valid_601966 != nil:
    section.add "LoadBalancerPort", valid_601966
  var valid_601967 = query.getOrDefault("Action")
  valid_601967 = validateParameter(valid_601967, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_601967 != nil:
    section.add "Action", valid_601967
  var valid_601968 = query.getOrDefault("Version")
  valid_601968 = validateParameter(valid_601968, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_601968 != nil:
    section.add "Version", valid_601968
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
  var valid_601969 = header.getOrDefault("X-Amz-Date")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "X-Amz-Date", valid_601969
  var valid_601970 = header.getOrDefault("X-Amz-Security-Token")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "X-Amz-Security-Token", valid_601970
  var valid_601971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "X-Amz-Content-Sha256", valid_601971
  var valid_601972 = header.getOrDefault("X-Amz-Algorithm")
  valid_601972 = validateParameter(valid_601972, JString, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "X-Amz-Algorithm", valid_601972
  var valid_601973 = header.getOrDefault("X-Amz-Signature")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "X-Amz-Signature", valid_601973
  var valid_601974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "X-Amz-SignedHeaders", valid_601974
  var valid_601975 = header.getOrDefault("X-Amz-Credential")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "X-Amz-Credential", valid_601975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601976: Call_GetSetLoadBalancerListenerSSLCertificate_601961;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_601976.validator(path, query, header, formData, body)
  let scheme = call_601976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601976.url(scheme.get, call_601976.host, call_601976.base,
                         call_601976.route, valid.getOrDefault("path"))
  result = hook(call_601976, url, valid)

proc call*(call_601977: Call_GetSetLoadBalancerListenerSSLCertificate_601961;
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
  var query_601978 = newJObject()
  add(query_601978, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_601978, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_601978, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_601978, "Action", newJString(Action))
  add(query_601978, "Version", newJString(Version))
  result = call_601977.call(nil, query_601978, nil, nil, nil)

var getSetLoadBalancerListenerSSLCertificate* = Call_GetSetLoadBalancerListenerSSLCertificate_601961(
    name: "getSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_GetSetLoadBalancerListenerSSLCertificate_601962,
    base: "/", url: url_GetSetLoadBalancerListenerSSLCertificate_601963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesForBackendServer_602016 = ref object of OpenApiRestCall_600426
proc url_PostSetLoadBalancerPoliciesForBackendServer_602018(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetLoadBalancerPoliciesForBackendServer_602017(path: JsonNode;
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
  var valid_602019 = query.getOrDefault("Action")
  valid_602019 = validateParameter(valid_602019, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_602019 != nil:
    section.add "Action", valid_602019
  var valid_602020 = query.getOrDefault("Version")
  valid_602020 = validateParameter(valid_602020, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602020 != nil:
    section.add "Version", valid_602020
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
  var valid_602021 = header.getOrDefault("X-Amz-Date")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Date", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Security-Token")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Security-Token", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Content-Sha256", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Algorithm")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Algorithm", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Signature")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Signature", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-SignedHeaders", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Credential")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Credential", valid_602027
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
  var valid_602028 = formData.getOrDefault("PolicyNames")
  valid_602028 = validateParameter(valid_602028, JArray, required = true, default = nil)
  if valid_602028 != nil:
    section.add "PolicyNames", valid_602028
  var valid_602029 = formData.getOrDefault("InstancePort")
  valid_602029 = validateParameter(valid_602029, JInt, required = true, default = nil)
  if valid_602029 != nil:
    section.add "InstancePort", valid_602029
  var valid_602030 = formData.getOrDefault("LoadBalancerName")
  valid_602030 = validateParameter(valid_602030, JString, required = true,
                                 default = nil)
  if valid_602030 != nil:
    section.add "LoadBalancerName", valid_602030
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602031: Call_PostSetLoadBalancerPoliciesForBackendServer_602016;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602031.validator(path, query, header, formData, body)
  let scheme = call_602031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602031.url(scheme.get, call_602031.host, call_602031.base,
                         call_602031.route, valid.getOrDefault("path"))
  result = hook(call_602031, url, valid)

proc call*(call_602032: Call_PostSetLoadBalancerPoliciesForBackendServer_602016;
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
  var query_602033 = newJObject()
  var formData_602034 = newJObject()
  if PolicyNames != nil:
    formData_602034.add "PolicyNames", PolicyNames
  add(formData_602034, "InstancePort", newJInt(InstancePort))
  add(query_602033, "Action", newJString(Action))
  add(formData_602034, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602033, "Version", newJString(Version))
  result = call_602032.call(nil, query_602033, nil, formData_602034, nil)

var postSetLoadBalancerPoliciesForBackendServer* = Call_PostSetLoadBalancerPoliciesForBackendServer_602016(
    name: "postSetLoadBalancerPoliciesForBackendServer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_PostSetLoadBalancerPoliciesForBackendServer_602017,
    base: "/", url: url_PostSetLoadBalancerPoliciesForBackendServer_602018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesForBackendServer_601998 = ref object of OpenApiRestCall_600426
proc url_GetSetLoadBalancerPoliciesForBackendServer_602000(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetLoadBalancerPoliciesForBackendServer_601999(path: JsonNode;
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
  var valid_602001 = query.getOrDefault("LoadBalancerName")
  valid_602001 = validateParameter(valid_602001, JString, required = true,
                                 default = nil)
  if valid_602001 != nil:
    section.add "LoadBalancerName", valid_602001
  var valid_602002 = query.getOrDefault("Action")
  valid_602002 = validateParameter(valid_602002, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_602002 != nil:
    section.add "Action", valid_602002
  var valid_602003 = query.getOrDefault("PolicyNames")
  valid_602003 = validateParameter(valid_602003, JArray, required = true, default = nil)
  if valid_602003 != nil:
    section.add "PolicyNames", valid_602003
  var valid_602004 = query.getOrDefault("Version")
  valid_602004 = validateParameter(valid_602004, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602004 != nil:
    section.add "Version", valid_602004
  var valid_602005 = query.getOrDefault("InstancePort")
  valid_602005 = validateParameter(valid_602005, JInt, required = true, default = nil)
  if valid_602005 != nil:
    section.add "InstancePort", valid_602005
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
  var valid_602006 = header.getOrDefault("X-Amz-Date")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Date", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Security-Token")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Security-Token", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Content-Sha256", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Algorithm")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Algorithm", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Signature")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Signature", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-SignedHeaders", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Credential")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Credential", valid_602012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602013: Call_GetSetLoadBalancerPoliciesForBackendServer_601998;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602013.validator(path, query, header, formData, body)
  let scheme = call_602013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602013.url(scheme.get, call_602013.host, call_602013.base,
                         call_602013.route, valid.getOrDefault("path"))
  result = hook(call_602013, url, valid)

proc call*(call_602014: Call_GetSetLoadBalancerPoliciesForBackendServer_601998;
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
  var query_602015 = newJObject()
  add(query_602015, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602015, "Action", newJString(Action))
  if PolicyNames != nil:
    query_602015.add "PolicyNames", PolicyNames
  add(query_602015, "Version", newJString(Version))
  add(query_602015, "InstancePort", newJInt(InstancePort))
  result = call_602014.call(nil, query_602015, nil, nil, nil)

var getSetLoadBalancerPoliciesForBackendServer* = Call_GetSetLoadBalancerPoliciesForBackendServer_601998(
    name: "getSetLoadBalancerPoliciesForBackendServer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_GetSetLoadBalancerPoliciesForBackendServer_601999,
    base: "/", url: url_GetSetLoadBalancerPoliciesForBackendServer_602000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesOfListener_602053 = ref object of OpenApiRestCall_600426
proc url_PostSetLoadBalancerPoliciesOfListener_602055(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetLoadBalancerPoliciesOfListener_602054(path: JsonNode;
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
  var valid_602056 = query.getOrDefault("Action")
  valid_602056 = validateParameter(valid_602056, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_602056 != nil:
    section.add "Action", valid_602056
  var valid_602057 = query.getOrDefault("Version")
  valid_602057 = validateParameter(valid_602057, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602057 != nil:
    section.add "Version", valid_602057
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
  var valid_602058 = header.getOrDefault("X-Amz-Date")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Date", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Security-Token")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Security-Token", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Content-Sha256", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Algorithm")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Algorithm", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Signature")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Signature", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-SignedHeaders", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Credential")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Credential", valid_602064
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
  var valid_602065 = formData.getOrDefault("LoadBalancerPort")
  valid_602065 = validateParameter(valid_602065, JInt, required = true, default = nil)
  if valid_602065 != nil:
    section.add "LoadBalancerPort", valid_602065
  var valid_602066 = formData.getOrDefault("PolicyNames")
  valid_602066 = validateParameter(valid_602066, JArray, required = true, default = nil)
  if valid_602066 != nil:
    section.add "PolicyNames", valid_602066
  var valid_602067 = formData.getOrDefault("LoadBalancerName")
  valid_602067 = validateParameter(valid_602067, JString, required = true,
                                 default = nil)
  if valid_602067 != nil:
    section.add "LoadBalancerName", valid_602067
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_PostSetLoadBalancerPoliciesOfListener_602053;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"))
  result = hook(call_602068, url, valid)

proc call*(call_602069: Call_PostSetLoadBalancerPoliciesOfListener_602053;
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
  var query_602070 = newJObject()
  var formData_602071 = newJObject()
  add(formData_602071, "LoadBalancerPort", newJInt(LoadBalancerPort))
  if PolicyNames != nil:
    formData_602071.add "PolicyNames", PolicyNames
  add(query_602070, "Action", newJString(Action))
  add(formData_602071, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602070, "Version", newJString(Version))
  result = call_602069.call(nil, query_602070, nil, formData_602071, nil)

var postSetLoadBalancerPoliciesOfListener* = Call_PostSetLoadBalancerPoliciesOfListener_602053(
    name: "postSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_PostSetLoadBalancerPoliciesOfListener_602054, base: "/",
    url: url_PostSetLoadBalancerPoliciesOfListener_602055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesOfListener_602035 = ref object of OpenApiRestCall_600426
proc url_GetSetLoadBalancerPoliciesOfListener_602037(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetLoadBalancerPoliciesOfListener_602036(path: JsonNode;
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
  var valid_602038 = query.getOrDefault("LoadBalancerName")
  valid_602038 = validateParameter(valid_602038, JString, required = true,
                                 default = nil)
  if valid_602038 != nil:
    section.add "LoadBalancerName", valid_602038
  var valid_602039 = query.getOrDefault("LoadBalancerPort")
  valid_602039 = validateParameter(valid_602039, JInt, required = true, default = nil)
  if valid_602039 != nil:
    section.add "LoadBalancerPort", valid_602039
  var valid_602040 = query.getOrDefault("Action")
  valid_602040 = validateParameter(valid_602040, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_602040 != nil:
    section.add "Action", valid_602040
  var valid_602041 = query.getOrDefault("PolicyNames")
  valid_602041 = validateParameter(valid_602041, JArray, required = true, default = nil)
  if valid_602041 != nil:
    section.add "PolicyNames", valid_602041
  var valid_602042 = query.getOrDefault("Version")
  valid_602042 = validateParameter(valid_602042, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602042 != nil:
    section.add "Version", valid_602042
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
  var valid_602043 = header.getOrDefault("X-Amz-Date")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Date", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Security-Token")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Security-Token", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Content-Sha256", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Algorithm")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Algorithm", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Signature")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Signature", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-SignedHeaders", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Credential")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Credential", valid_602049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602050: Call_GetSetLoadBalancerPoliciesOfListener_602035;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602050.validator(path, query, header, formData, body)
  let scheme = call_602050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602050.url(scheme.get, call_602050.host, call_602050.base,
                         call_602050.route, valid.getOrDefault("path"))
  result = hook(call_602050, url, valid)

proc call*(call_602051: Call_GetSetLoadBalancerPoliciesOfListener_602035;
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
  var query_602052 = newJObject()
  add(query_602052, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_602052, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_602052, "Action", newJString(Action))
  if PolicyNames != nil:
    query_602052.add "PolicyNames", PolicyNames
  add(query_602052, "Version", newJString(Version))
  result = call_602051.call(nil, query_602052, nil, nil, nil)

var getSetLoadBalancerPoliciesOfListener* = Call_GetSetLoadBalancerPoliciesOfListener_602035(
    name: "getSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_GetSetLoadBalancerPoliciesOfListener_602036, base: "/",
    url: url_GetSetLoadBalancerPoliciesOfListener_602037,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
