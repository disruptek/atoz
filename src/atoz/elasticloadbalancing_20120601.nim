
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
  Call_PostAddTags_613268 = ref object of OpenApiRestCall_612658
proc url_PostAddTags_613270(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTags_613269(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613271 = query.getOrDefault("Action")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_613271 != nil:
    section.add "Action", valid_613271
  var valid_613272 = query.getOrDefault("Version")
  valid_613272 = validateParameter(valid_613272, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613272 != nil:
    section.add "Version", valid_613272
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
  var valid_613273 = header.getOrDefault("X-Amz-Signature")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Signature", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Content-Sha256", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Date")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Date", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Credential")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Credential", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Security-Token")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Security-Token", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Algorithm")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Algorithm", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-SignedHeaders", valid_613279
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Tags: JArray (required)
  ##       : The tags.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_613280 = formData.getOrDefault("LoadBalancerNames")
  valid_613280 = validateParameter(valid_613280, JArray, required = true, default = nil)
  if valid_613280 != nil:
    section.add "LoadBalancerNames", valid_613280
  var valid_613281 = formData.getOrDefault("Tags")
  valid_613281 = validateParameter(valid_613281, JArray, required = true, default = nil)
  if valid_613281 != nil:
    section.add "Tags", valid_613281
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613282: Call_PostAddTags_613268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613282.validator(path, query, header, formData, body)
  let scheme = call_613282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613282.url(scheme.get, call_613282.host, call_613282.base,
                         call_613282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613282, url, valid)

proc call*(call_613283: Call_PostAddTags_613268; LoadBalancerNames: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2012-06-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   Version: string (required)
  var query_613284 = newJObject()
  var formData_613285 = newJObject()
  if LoadBalancerNames != nil:
    formData_613285.add "LoadBalancerNames", LoadBalancerNames
  add(query_613284, "Action", newJString(Action))
  if Tags != nil:
    formData_613285.add "Tags", Tags
  add(query_613284, "Version", newJString(Version))
  result = call_613283.call(nil, query_613284, nil, formData_613285, nil)

var postAddTags* = Call_PostAddTags_613268(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_613269,
                                        base: "/", url: url_PostAddTags_613270,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_612996 = ref object of OpenApiRestCall_612658
proc url_GetAddTags_612998(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAddTags_612997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613110 = query.getOrDefault("Tags")
  valid_613110 = validateParameter(valid_613110, JArray, required = true, default = nil)
  if valid_613110 != nil:
    section.add "Tags", valid_613110
  var valid_613124 = query.getOrDefault("Action")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_613124 != nil:
    section.add "Action", valid_613124
  var valid_613125 = query.getOrDefault("Version")
  valid_613125 = validateParameter(valid_613125, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613125 != nil:
    section.add "Version", valid_613125
  var valid_613126 = query.getOrDefault("LoadBalancerNames")
  valid_613126 = validateParameter(valid_613126, JArray, required = true, default = nil)
  if valid_613126 != nil:
    section.add "LoadBalancerNames", valid_613126
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
  var valid_613127 = header.getOrDefault("X-Amz-Signature")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Signature", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Content-Sha256", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Date")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Date", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Credential")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Credential", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Security-Token")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Security-Token", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-Algorithm")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-Algorithm", valid_613132
  var valid_613133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613133 = validateParameter(valid_613133, JString, required = false,
                                 default = nil)
  if valid_613133 != nil:
    section.add "X-Amz-SignedHeaders", valid_613133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613156: Call_GetAddTags_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613156.validator(path, query, header, formData, body)
  let scheme = call_613156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613156.url(scheme.get, call_613156.host, call_613156.base,
                         call_613156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613156, url, valid)

proc call*(call_613227: Call_GetAddTags_612996; Tags: JsonNode;
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
  var query_613228 = newJObject()
  if Tags != nil:
    query_613228.add "Tags", Tags
  add(query_613228, "Action", newJString(Action))
  add(query_613228, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_613228.add "LoadBalancerNames", LoadBalancerNames
  result = call_613227.call(nil, query_613228, nil, nil, nil)

var getAddTags* = Call_GetAddTags_612996(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_612997,
                                      base: "/", url: url_GetAddTags_612998,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplySecurityGroupsToLoadBalancer_613303 = ref object of OpenApiRestCall_612658
proc url_PostApplySecurityGroupsToLoadBalancer_613305(protocol: Scheme;
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

proc validate_PostApplySecurityGroupsToLoadBalancer_613304(path: JsonNode;
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
  var valid_613306 = query.getOrDefault("Action")
  valid_613306 = validateParameter(valid_613306, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_613306 != nil:
    section.add "Action", valid_613306
  var valid_613307 = query.getOrDefault("Version")
  valid_613307 = validateParameter(valid_613307, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613307 != nil:
    section.add "Version", valid_613307
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
  var valid_613308 = header.getOrDefault("X-Amz-Signature")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Signature", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Content-Sha256", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Date")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Date", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Credential")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Credential", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Security-Token")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Security-Token", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Algorithm")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Algorithm", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-SignedHeaders", valid_613314
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_613315 = formData.getOrDefault("SecurityGroups")
  valid_613315 = validateParameter(valid_613315, JArray, required = true, default = nil)
  if valid_613315 != nil:
    section.add "SecurityGroups", valid_613315
  var valid_613316 = formData.getOrDefault("LoadBalancerName")
  valid_613316 = validateParameter(valid_613316, JString, required = true,
                                 default = nil)
  if valid_613316 != nil:
    section.add "LoadBalancerName", valid_613316
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613317: Call_PostApplySecurityGroupsToLoadBalancer_613303;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613317.validator(path, query, header, formData, body)
  let scheme = call_613317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613317.url(scheme.get, call_613317.host, call_613317.base,
                         call_613317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613317, url, valid)

proc call*(call_613318: Call_PostApplySecurityGroupsToLoadBalancer_613303;
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
  var query_613319 = newJObject()
  var formData_613320 = newJObject()
  if SecurityGroups != nil:
    formData_613320.add "SecurityGroups", SecurityGroups
  add(formData_613320, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613319, "Action", newJString(Action))
  add(query_613319, "Version", newJString(Version))
  result = call_613318.call(nil, query_613319, nil, formData_613320, nil)

var postApplySecurityGroupsToLoadBalancer* = Call_PostApplySecurityGroupsToLoadBalancer_613303(
    name: "postApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_PostApplySecurityGroupsToLoadBalancer_613304, base: "/",
    url: url_PostApplySecurityGroupsToLoadBalancer_613305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplySecurityGroupsToLoadBalancer_613286 = ref object of OpenApiRestCall_612658
proc url_GetApplySecurityGroupsToLoadBalancer_613288(protocol: Scheme;
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

proc validate_GetApplySecurityGroupsToLoadBalancer_613287(path: JsonNode;
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
  var valid_613289 = query.getOrDefault("SecurityGroups")
  valid_613289 = validateParameter(valid_613289, JArray, required = true, default = nil)
  if valid_613289 != nil:
    section.add "SecurityGroups", valid_613289
  var valid_613290 = query.getOrDefault("LoadBalancerName")
  valid_613290 = validateParameter(valid_613290, JString, required = true,
                                 default = nil)
  if valid_613290 != nil:
    section.add "LoadBalancerName", valid_613290
  var valid_613291 = query.getOrDefault("Action")
  valid_613291 = validateParameter(valid_613291, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_613291 != nil:
    section.add "Action", valid_613291
  var valid_613292 = query.getOrDefault("Version")
  valid_613292 = validateParameter(valid_613292, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613292 != nil:
    section.add "Version", valid_613292
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
  var valid_613293 = header.getOrDefault("X-Amz-Signature")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Signature", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Content-Sha256", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Date")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Date", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Credential")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Credential", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Security-Token")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Security-Token", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Algorithm")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Algorithm", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-SignedHeaders", valid_613299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613300: Call_GetApplySecurityGroupsToLoadBalancer_613286;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613300.validator(path, query, header, formData, body)
  let scheme = call_613300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613300.url(scheme.get, call_613300.host, call_613300.base,
                         call_613300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613300, url, valid)

proc call*(call_613301: Call_GetApplySecurityGroupsToLoadBalancer_613286;
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
  var query_613302 = newJObject()
  if SecurityGroups != nil:
    query_613302.add "SecurityGroups", SecurityGroups
  add(query_613302, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613302, "Action", newJString(Action))
  add(query_613302, "Version", newJString(Version))
  result = call_613301.call(nil, query_613302, nil, nil, nil)

var getApplySecurityGroupsToLoadBalancer* = Call_GetApplySecurityGroupsToLoadBalancer_613286(
    name: "getApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_GetApplySecurityGroupsToLoadBalancer_613287, base: "/",
    url: url_GetApplySecurityGroupsToLoadBalancer_613288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAttachLoadBalancerToSubnets_613338 = ref object of OpenApiRestCall_612658
proc url_PostAttachLoadBalancerToSubnets_613340(protocol: Scheme; host: string;
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

proc validate_PostAttachLoadBalancerToSubnets_613339(path: JsonNode;
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
  var valid_613341 = query.getOrDefault("Action")
  valid_613341 = validateParameter(valid_613341, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_613341 != nil:
    section.add "Action", valid_613341
  var valid_613342 = query.getOrDefault("Version")
  valid_613342 = validateParameter(valid_613342, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613342 != nil:
    section.add "Version", valid_613342
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
  var valid_613343 = header.getOrDefault("X-Amz-Signature")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Signature", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Content-Sha256", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Date")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Date", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Credential")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Credential", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Security-Token")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Security-Token", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Algorithm")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Algorithm", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-SignedHeaders", valid_613349
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_613350 = formData.getOrDefault("Subnets")
  valid_613350 = validateParameter(valid_613350, JArray, required = true, default = nil)
  if valid_613350 != nil:
    section.add "Subnets", valid_613350
  var valid_613351 = formData.getOrDefault("LoadBalancerName")
  valid_613351 = validateParameter(valid_613351, JString, required = true,
                                 default = nil)
  if valid_613351 != nil:
    section.add "LoadBalancerName", valid_613351
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_PostAttachLoadBalancerToSubnets_613338;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_PostAttachLoadBalancerToSubnets_613338;
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
  var query_613354 = newJObject()
  var formData_613355 = newJObject()
  if Subnets != nil:
    formData_613355.add "Subnets", Subnets
  add(formData_613355, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613354, "Action", newJString(Action))
  add(query_613354, "Version", newJString(Version))
  result = call_613353.call(nil, query_613354, nil, formData_613355, nil)

var postAttachLoadBalancerToSubnets* = Call_PostAttachLoadBalancerToSubnets_613338(
    name: "postAttachLoadBalancerToSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_PostAttachLoadBalancerToSubnets_613339, base: "/",
    url: url_PostAttachLoadBalancerToSubnets_613340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttachLoadBalancerToSubnets_613321 = ref object of OpenApiRestCall_612658
proc url_GetAttachLoadBalancerToSubnets_613323(protocol: Scheme; host: string;
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

proc validate_GetAttachLoadBalancerToSubnets_613322(path: JsonNode;
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
  var valid_613324 = query.getOrDefault("LoadBalancerName")
  valid_613324 = validateParameter(valid_613324, JString, required = true,
                                 default = nil)
  if valid_613324 != nil:
    section.add "LoadBalancerName", valid_613324
  var valid_613325 = query.getOrDefault("Action")
  valid_613325 = validateParameter(valid_613325, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_613325 != nil:
    section.add "Action", valid_613325
  var valid_613326 = query.getOrDefault("Subnets")
  valid_613326 = validateParameter(valid_613326, JArray, required = true, default = nil)
  if valid_613326 != nil:
    section.add "Subnets", valid_613326
  var valid_613327 = query.getOrDefault("Version")
  valid_613327 = validateParameter(valid_613327, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613327 != nil:
    section.add "Version", valid_613327
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
  var valid_613328 = header.getOrDefault("X-Amz-Signature")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Signature", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Content-Sha256", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Date")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Date", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Credential")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Credential", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Security-Token")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Security-Token", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Algorithm")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Algorithm", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-SignedHeaders", valid_613334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613335: Call_GetAttachLoadBalancerToSubnets_613321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613335.validator(path, query, header, formData, body)
  let scheme = call_613335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613335.url(scheme.get, call_613335.host, call_613335.base,
                         call_613335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613335, url, valid)

proc call*(call_613336: Call_GetAttachLoadBalancerToSubnets_613321;
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
  var query_613337 = newJObject()
  add(query_613337, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613337, "Action", newJString(Action))
  if Subnets != nil:
    query_613337.add "Subnets", Subnets
  add(query_613337, "Version", newJString(Version))
  result = call_613336.call(nil, query_613337, nil, nil, nil)

var getAttachLoadBalancerToSubnets* = Call_GetAttachLoadBalancerToSubnets_613321(
    name: "getAttachLoadBalancerToSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_GetAttachLoadBalancerToSubnets_613322, base: "/",
    url: url_GetAttachLoadBalancerToSubnets_613323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfigureHealthCheck_613377 = ref object of OpenApiRestCall_612658
proc url_PostConfigureHealthCheck_613379(protocol: Scheme; host: string;
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

proc validate_PostConfigureHealthCheck_613378(path: JsonNode; query: JsonNode;
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
  var valid_613380 = query.getOrDefault("Action")
  valid_613380 = validateParameter(valid_613380, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_613380 != nil:
    section.add "Action", valid_613380
  var valid_613381 = query.getOrDefault("Version")
  valid_613381 = validateParameter(valid_613381, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613381 != nil:
    section.add "Version", valid_613381
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
  var valid_613382 = header.getOrDefault("X-Amz-Signature")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Signature", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Content-Sha256", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Date")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Date", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-Credential")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Credential", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Security-Token")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Security-Token", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Algorithm")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Algorithm", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-SignedHeaders", valid_613388
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
  var valid_613389 = formData.getOrDefault("HealthCheck.Interval")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "HealthCheck.Interval", valid_613389
  var valid_613390 = formData.getOrDefault("HealthCheck.HealthyThreshold")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_613390
  var valid_613391 = formData.getOrDefault("HealthCheck.Timeout")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "HealthCheck.Timeout", valid_613391
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_613392 = formData.getOrDefault("LoadBalancerName")
  valid_613392 = validateParameter(valid_613392, JString, required = true,
                                 default = nil)
  if valid_613392 != nil:
    section.add "LoadBalancerName", valid_613392
  var valid_613393 = formData.getOrDefault("HealthCheck.Target")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "HealthCheck.Target", valid_613393
  var valid_613394 = formData.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_613394
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613395: Call_PostConfigureHealthCheck_613377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613395.validator(path, query, header, formData, body)
  let scheme = call_613395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613395.url(scheme.get, call_613395.host, call_613395.base,
                         call_613395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613395, url, valid)

proc call*(call_613396: Call_PostConfigureHealthCheck_613377;
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
  var query_613397 = newJObject()
  var formData_613398 = newJObject()
  add(formData_613398, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(formData_613398, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(formData_613398, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(formData_613398, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613397, "Action", newJString(Action))
  add(formData_613398, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_613397, "Version", newJString(Version))
  add(formData_613398, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  result = call_613396.call(nil, query_613397, nil, formData_613398, nil)

var postConfigureHealthCheck* = Call_PostConfigureHealthCheck_613377(
    name: "postConfigureHealthCheck", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_PostConfigureHealthCheck_613378, base: "/",
    url: url_PostConfigureHealthCheck_613379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigureHealthCheck_613356 = ref object of OpenApiRestCall_612658
proc url_GetConfigureHealthCheck_613358(protocol: Scheme; host: string; base: string;
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

proc validate_GetConfigureHealthCheck_613357(path: JsonNode; query: JsonNode;
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
  var valid_613359 = query.getOrDefault("HealthCheck.Interval")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "HealthCheck.Interval", valid_613359
  var valid_613360 = query.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_613360
  var valid_613361 = query.getOrDefault("HealthCheck.Timeout")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "HealthCheck.Timeout", valid_613361
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_613362 = query.getOrDefault("LoadBalancerName")
  valid_613362 = validateParameter(valid_613362, JString, required = true,
                                 default = nil)
  if valid_613362 != nil:
    section.add "LoadBalancerName", valid_613362
  var valid_613363 = query.getOrDefault("Action")
  valid_613363 = validateParameter(valid_613363, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_613363 != nil:
    section.add "Action", valid_613363
  var valid_613364 = query.getOrDefault("HealthCheck.Target")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "HealthCheck.Target", valid_613364
  var valid_613365 = query.getOrDefault("HealthCheck.HealthyThreshold")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_613365
  var valid_613366 = query.getOrDefault("Version")
  valid_613366 = validateParameter(valid_613366, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613366 != nil:
    section.add "Version", valid_613366
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
  var valid_613367 = header.getOrDefault("X-Amz-Signature")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Signature", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Content-Sha256", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Date")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Date", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Credential")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Credential", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Security-Token")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Security-Token", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Algorithm")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Algorithm", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-SignedHeaders", valid_613373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613374: Call_GetConfigureHealthCheck_613356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613374.validator(path, query, header, formData, body)
  let scheme = call_613374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613374.url(scheme.get, call_613374.host, call_613374.base,
                         call_613374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613374, url, valid)

proc call*(call_613375: Call_GetConfigureHealthCheck_613356;
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
  var query_613376 = newJObject()
  add(query_613376, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(query_613376, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(query_613376, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_613376, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613376, "Action", newJString(Action))
  add(query_613376, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_613376, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(query_613376, "Version", newJString(Version))
  result = call_613375.call(nil, query_613376, nil, nil, nil)

var getConfigureHealthCheck* = Call_GetConfigureHealthCheck_613356(
    name: "getConfigureHealthCheck", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_GetConfigureHealthCheck_613357, base: "/",
    url: url_GetConfigureHealthCheck_613358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateAppCookieStickinessPolicy_613417 = ref object of OpenApiRestCall_612658
proc url_PostCreateAppCookieStickinessPolicy_613419(protocol: Scheme; host: string;
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

proc validate_PostCreateAppCookieStickinessPolicy_613418(path: JsonNode;
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
  var valid_613420 = query.getOrDefault("Action")
  valid_613420 = validateParameter(valid_613420, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_613420 != nil:
    section.add "Action", valid_613420
  var valid_613421 = query.getOrDefault("Version")
  valid_613421 = validateParameter(valid_613421, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613421 != nil:
    section.add "Version", valid_613421
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
  var valid_613422 = header.getOrDefault("X-Amz-Signature")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Signature", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Content-Sha256", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Date")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Date", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Credential")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Credential", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Security-Token")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Security-Token", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-Algorithm")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Algorithm", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-SignedHeaders", valid_613428
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
  var valid_613429 = formData.getOrDefault("CookieName")
  valid_613429 = validateParameter(valid_613429, JString, required = true,
                                 default = nil)
  if valid_613429 != nil:
    section.add "CookieName", valid_613429
  var valid_613430 = formData.getOrDefault("LoadBalancerName")
  valid_613430 = validateParameter(valid_613430, JString, required = true,
                                 default = nil)
  if valid_613430 != nil:
    section.add "LoadBalancerName", valid_613430
  var valid_613431 = formData.getOrDefault("PolicyName")
  valid_613431 = validateParameter(valid_613431, JString, required = true,
                                 default = nil)
  if valid_613431 != nil:
    section.add "PolicyName", valid_613431
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613432: Call_PostCreateAppCookieStickinessPolicy_613417;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613432.validator(path, query, header, formData, body)
  let scheme = call_613432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613432.url(scheme.get, call_613432.host, call_613432.base,
                         call_613432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613432, url, valid)

proc call*(call_613433: Call_PostCreateAppCookieStickinessPolicy_613417;
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
  var query_613434 = newJObject()
  var formData_613435 = newJObject()
  add(formData_613435, "CookieName", newJString(CookieName))
  add(formData_613435, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613434, "Action", newJString(Action))
  add(query_613434, "Version", newJString(Version))
  add(formData_613435, "PolicyName", newJString(PolicyName))
  result = call_613433.call(nil, query_613434, nil, formData_613435, nil)

var postCreateAppCookieStickinessPolicy* = Call_PostCreateAppCookieStickinessPolicy_613417(
    name: "postCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_PostCreateAppCookieStickinessPolicy_613418, base: "/",
    url: url_PostCreateAppCookieStickinessPolicy_613419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateAppCookieStickinessPolicy_613399 = ref object of OpenApiRestCall_612658
proc url_GetCreateAppCookieStickinessPolicy_613401(protocol: Scheme; host: string;
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

proc validate_GetCreateAppCookieStickinessPolicy_613400(path: JsonNode;
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
  var valid_613402 = query.getOrDefault("PolicyName")
  valid_613402 = validateParameter(valid_613402, JString, required = true,
                                 default = nil)
  if valid_613402 != nil:
    section.add "PolicyName", valid_613402
  var valid_613403 = query.getOrDefault("CookieName")
  valid_613403 = validateParameter(valid_613403, JString, required = true,
                                 default = nil)
  if valid_613403 != nil:
    section.add "CookieName", valid_613403
  var valid_613404 = query.getOrDefault("LoadBalancerName")
  valid_613404 = validateParameter(valid_613404, JString, required = true,
                                 default = nil)
  if valid_613404 != nil:
    section.add "LoadBalancerName", valid_613404
  var valid_613405 = query.getOrDefault("Action")
  valid_613405 = validateParameter(valid_613405, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_613405 != nil:
    section.add "Action", valid_613405
  var valid_613406 = query.getOrDefault("Version")
  valid_613406 = validateParameter(valid_613406, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613406 != nil:
    section.add "Version", valid_613406
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
  var valid_613407 = header.getOrDefault("X-Amz-Signature")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Signature", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Content-Sha256", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Date")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Date", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Credential")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Credential", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Security-Token")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Security-Token", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Algorithm")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Algorithm", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-SignedHeaders", valid_613413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613414: Call_GetCreateAppCookieStickinessPolicy_613399;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613414.validator(path, query, header, formData, body)
  let scheme = call_613414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613414.url(scheme.get, call_613414.host, call_613414.base,
                         call_613414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613414, url, valid)

proc call*(call_613415: Call_GetCreateAppCookieStickinessPolicy_613399;
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
  var query_613416 = newJObject()
  add(query_613416, "PolicyName", newJString(PolicyName))
  add(query_613416, "CookieName", newJString(CookieName))
  add(query_613416, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613416, "Action", newJString(Action))
  add(query_613416, "Version", newJString(Version))
  result = call_613415.call(nil, query_613416, nil, nil, nil)

var getCreateAppCookieStickinessPolicy* = Call_GetCreateAppCookieStickinessPolicy_613399(
    name: "getCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_GetCreateAppCookieStickinessPolicy_613400, base: "/",
    url: url_GetCreateAppCookieStickinessPolicy_613401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLBCookieStickinessPolicy_613454 = ref object of OpenApiRestCall_612658
proc url_PostCreateLBCookieStickinessPolicy_613456(protocol: Scheme; host: string;
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

proc validate_PostCreateLBCookieStickinessPolicy_613455(path: JsonNode;
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
  var valid_613457 = query.getOrDefault("Action")
  valid_613457 = validateParameter(valid_613457, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_613457 != nil:
    section.add "Action", valid_613457
  var valid_613458 = query.getOrDefault("Version")
  valid_613458 = validateParameter(valid_613458, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613458 != nil:
    section.add "Version", valid_613458
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
  var valid_613459 = header.getOrDefault("X-Amz-Signature")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Signature", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Content-Sha256", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Date")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Date", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Credential")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Credential", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Security-Token")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Security-Token", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Algorithm")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Algorithm", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-SignedHeaders", valid_613465
  result.add "header", section
  ## parameters in `formData` object:
  ##   CookieExpirationPeriod: JInt
  ##                         : The time period, in seconds, after which the cookie should be considered stale. If you do not specify this parameter, the default value is 0, which indicates that the sticky session should last for the duration of the browser session.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  section = newJObject()
  var valid_613466 = formData.getOrDefault("CookieExpirationPeriod")
  valid_613466 = validateParameter(valid_613466, JInt, required = false, default = nil)
  if valid_613466 != nil:
    section.add "CookieExpirationPeriod", valid_613466
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_613467 = formData.getOrDefault("LoadBalancerName")
  valid_613467 = validateParameter(valid_613467, JString, required = true,
                                 default = nil)
  if valid_613467 != nil:
    section.add "LoadBalancerName", valid_613467
  var valid_613468 = formData.getOrDefault("PolicyName")
  valid_613468 = validateParameter(valid_613468, JString, required = true,
                                 default = nil)
  if valid_613468 != nil:
    section.add "PolicyName", valid_613468
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613469: Call_PostCreateLBCookieStickinessPolicy_613454;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613469.validator(path, query, header, formData, body)
  let scheme = call_613469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613469.url(scheme.get, call_613469.host, call_613469.base,
                         call_613469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613469, url, valid)

proc call*(call_613470: Call_PostCreateLBCookieStickinessPolicy_613454;
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
  var query_613471 = newJObject()
  var formData_613472 = newJObject()
  add(formData_613472, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(formData_613472, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613471, "Action", newJString(Action))
  add(query_613471, "Version", newJString(Version))
  add(formData_613472, "PolicyName", newJString(PolicyName))
  result = call_613470.call(nil, query_613471, nil, formData_613472, nil)

var postCreateLBCookieStickinessPolicy* = Call_PostCreateLBCookieStickinessPolicy_613454(
    name: "postCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_PostCreateLBCookieStickinessPolicy_613455, base: "/",
    url: url_PostCreateLBCookieStickinessPolicy_613456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLBCookieStickinessPolicy_613436 = ref object of OpenApiRestCall_612658
proc url_GetCreateLBCookieStickinessPolicy_613438(protocol: Scheme; host: string;
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

proc validate_GetCreateLBCookieStickinessPolicy_613437(path: JsonNode;
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
  var valid_613439 = query.getOrDefault("CookieExpirationPeriod")
  valid_613439 = validateParameter(valid_613439, JInt, required = false, default = nil)
  if valid_613439 != nil:
    section.add "CookieExpirationPeriod", valid_613439
  assert query != nil,
        "query argument is necessary due to required `PolicyName` field"
  var valid_613440 = query.getOrDefault("PolicyName")
  valid_613440 = validateParameter(valid_613440, JString, required = true,
                                 default = nil)
  if valid_613440 != nil:
    section.add "PolicyName", valid_613440
  var valid_613441 = query.getOrDefault("LoadBalancerName")
  valid_613441 = validateParameter(valid_613441, JString, required = true,
                                 default = nil)
  if valid_613441 != nil:
    section.add "LoadBalancerName", valid_613441
  var valid_613442 = query.getOrDefault("Action")
  valid_613442 = validateParameter(valid_613442, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_613442 != nil:
    section.add "Action", valid_613442
  var valid_613443 = query.getOrDefault("Version")
  valid_613443 = validateParameter(valid_613443, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613443 != nil:
    section.add "Version", valid_613443
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
  var valid_613444 = header.getOrDefault("X-Amz-Signature")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Signature", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Content-Sha256", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Date")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Date", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Credential")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Credential", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Security-Token")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Security-Token", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Algorithm")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Algorithm", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-SignedHeaders", valid_613450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613451: Call_GetCreateLBCookieStickinessPolicy_613436;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613451.validator(path, query, header, formData, body)
  let scheme = call_613451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613451.url(scheme.get, call_613451.host, call_613451.base,
                         call_613451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613451, url, valid)

proc call*(call_613452: Call_GetCreateLBCookieStickinessPolicy_613436;
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
  var query_613453 = newJObject()
  add(query_613453, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(query_613453, "PolicyName", newJString(PolicyName))
  add(query_613453, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613453, "Action", newJString(Action))
  add(query_613453, "Version", newJString(Version))
  result = call_613452.call(nil, query_613453, nil, nil, nil)

var getCreateLBCookieStickinessPolicy* = Call_GetCreateLBCookieStickinessPolicy_613436(
    name: "getCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_GetCreateLBCookieStickinessPolicy_613437, base: "/",
    url: url_GetCreateLBCookieStickinessPolicy_613438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_613495 = ref object of OpenApiRestCall_612658
proc url_PostCreateLoadBalancer_613497(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateLoadBalancer_613496(path: JsonNode; query: JsonNode;
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
  var valid_613498 = query.getOrDefault("Action")
  valid_613498 = validateParameter(valid_613498, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_613498 != nil:
    section.add "Action", valid_613498
  var valid_613499 = query.getOrDefault("Version")
  valid_613499 = validateParameter(valid_613499, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613499 != nil:
    section.add "Version", valid_613499
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
  var valid_613500 = header.getOrDefault("X-Amz-Signature")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Signature", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Content-Sha256", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Date")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Date", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Credential")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Credential", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Security-Token")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Security-Token", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Algorithm")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Algorithm", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-SignedHeaders", valid_613506
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
  var valid_613507 = formData.getOrDefault("Scheme")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "Scheme", valid_613507
  var valid_613508 = formData.getOrDefault("SecurityGroups")
  valid_613508 = validateParameter(valid_613508, JArray, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "SecurityGroups", valid_613508
  var valid_613509 = formData.getOrDefault("AvailabilityZones")
  valid_613509 = validateParameter(valid_613509, JArray, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "AvailabilityZones", valid_613509
  var valid_613510 = formData.getOrDefault("Subnets")
  valid_613510 = validateParameter(valid_613510, JArray, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "Subnets", valid_613510
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_613511 = formData.getOrDefault("LoadBalancerName")
  valid_613511 = validateParameter(valid_613511, JString, required = true,
                                 default = nil)
  if valid_613511 != nil:
    section.add "LoadBalancerName", valid_613511
  var valid_613512 = formData.getOrDefault("Listeners")
  valid_613512 = validateParameter(valid_613512, JArray, required = true, default = nil)
  if valid_613512 != nil:
    section.add "Listeners", valid_613512
  var valid_613513 = formData.getOrDefault("Tags")
  valid_613513 = validateParameter(valid_613513, JArray, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "Tags", valid_613513
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613514: Call_PostCreateLoadBalancer_613495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613514.validator(path, query, header, formData, body)
  let scheme = call_613514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613514.url(scheme.get, call_613514.host, call_613514.base,
                         call_613514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613514, url, valid)

proc call*(call_613515: Call_PostCreateLoadBalancer_613495;
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
  var query_613516 = newJObject()
  var formData_613517 = newJObject()
  add(formData_613517, "Scheme", newJString(Scheme))
  if SecurityGroups != nil:
    formData_613517.add "SecurityGroups", SecurityGroups
  if AvailabilityZones != nil:
    formData_613517.add "AvailabilityZones", AvailabilityZones
  if Subnets != nil:
    formData_613517.add "Subnets", Subnets
  add(formData_613517, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_613517.add "Listeners", Listeners
  add(query_613516, "Action", newJString(Action))
  if Tags != nil:
    formData_613517.add "Tags", Tags
  add(query_613516, "Version", newJString(Version))
  result = call_613515.call(nil, query_613516, nil, formData_613517, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_613495(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_613496, base: "/",
    url: url_PostCreateLoadBalancer_613497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_613473 = ref object of OpenApiRestCall_612658
proc url_GetCreateLoadBalancer_613475(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateLoadBalancer_613474(path: JsonNode; query: JsonNode;
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
  var valid_613476 = query.getOrDefault("Tags")
  valid_613476 = validateParameter(valid_613476, JArray, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "Tags", valid_613476
  var valid_613477 = query.getOrDefault("Scheme")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "Scheme", valid_613477
  var valid_613478 = query.getOrDefault("AvailabilityZones")
  valid_613478 = validateParameter(valid_613478, JArray, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "AvailabilityZones", valid_613478
  assert query != nil,
        "query argument is necessary due to required `Listeners` field"
  var valid_613479 = query.getOrDefault("Listeners")
  valid_613479 = validateParameter(valid_613479, JArray, required = true, default = nil)
  if valid_613479 != nil:
    section.add "Listeners", valid_613479
  var valid_613480 = query.getOrDefault("SecurityGroups")
  valid_613480 = validateParameter(valid_613480, JArray, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "SecurityGroups", valid_613480
  var valid_613481 = query.getOrDefault("LoadBalancerName")
  valid_613481 = validateParameter(valid_613481, JString, required = true,
                                 default = nil)
  if valid_613481 != nil:
    section.add "LoadBalancerName", valid_613481
  var valid_613482 = query.getOrDefault("Action")
  valid_613482 = validateParameter(valid_613482, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_613482 != nil:
    section.add "Action", valid_613482
  var valid_613483 = query.getOrDefault("Subnets")
  valid_613483 = validateParameter(valid_613483, JArray, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "Subnets", valid_613483
  var valid_613484 = query.getOrDefault("Version")
  valid_613484 = validateParameter(valid_613484, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613484 != nil:
    section.add "Version", valid_613484
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
  var valid_613485 = header.getOrDefault("X-Amz-Signature")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Signature", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Content-Sha256", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Date")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Date", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Credential")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Credential", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Security-Token")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Security-Token", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Algorithm")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Algorithm", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-SignedHeaders", valid_613491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613492: Call_GetCreateLoadBalancer_613473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613492.validator(path, query, header, formData, body)
  let scheme = call_613492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613492.url(scheme.get, call_613492.host, call_613492.base,
                         call_613492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613492, url, valid)

proc call*(call_613493: Call_GetCreateLoadBalancer_613473; Listeners: JsonNode;
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
  var query_613494 = newJObject()
  if Tags != nil:
    query_613494.add "Tags", Tags
  add(query_613494, "Scheme", newJString(Scheme))
  if AvailabilityZones != nil:
    query_613494.add "AvailabilityZones", AvailabilityZones
  if Listeners != nil:
    query_613494.add "Listeners", Listeners
  if SecurityGroups != nil:
    query_613494.add "SecurityGroups", SecurityGroups
  add(query_613494, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613494, "Action", newJString(Action))
  if Subnets != nil:
    query_613494.add "Subnets", Subnets
  add(query_613494, "Version", newJString(Version))
  result = call_613493.call(nil, query_613494, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_613473(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_613474, base: "/",
    url: url_GetCreateLoadBalancer_613475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerListeners_613535 = ref object of OpenApiRestCall_612658
proc url_PostCreateLoadBalancerListeners_613537(protocol: Scheme; host: string;
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

proc validate_PostCreateLoadBalancerListeners_613536(path: JsonNode;
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
  var valid_613538 = query.getOrDefault("Action")
  valid_613538 = validateParameter(valid_613538, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_613538 != nil:
    section.add "Action", valid_613538
  var valid_613539 = query.getOrDefault("Version")
  valid_613539 = validateParameter(valid_613539, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613539 != nil:
    section.add "Version", valid_613539
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
  var valid_613540 = header.getOrDefault("X-Amz-Signature")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Signature", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Content-Sha256", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Date")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Date", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Credential")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Credential", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Security-Token")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Security-Token", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Algorithm")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Algorithm", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-SignedHeaders", valid_613546
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_613547 = formData.getOrDefault("LoadBalancerName")
  valid_613547 = validateParameter(valid_613547, JString, required = true,
                                 default = nil)
  if valid_613547 != nil:
    section.add "LoadBalancerName", valid_613547
  var valid_613548 = formData.getOrDefault("Listeners")
  valid_613548 = validateParameter(valid_613548, JArray, required = true, default = nil)
  if valid_613548 != nil:
    section.add "Listeners", valid_613548
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613549: Call_PostCreateLoadBalancerListeners_613535;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613549.validator(path, query, header, formData, body)
  let scheme = call_613549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613549.url(scheme.get, call_613549.host, call_613549.base,
                         call_613549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613549, url, valid)

proc call*(call_613550: Call_PostCreateLoadBalancerListeners_613535;
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
  var query_613551 = newJObject()
  var formData_613552 = newJObject()
  add(formData_613552, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_613552.add "Listeners", Listeners
  add(query_613551, "Action", newJString(Action))
  add(query_613551, "Version", newJString(Version))
  result = call_613550.call(nil, query_613551, nil, formData_613552, nil)

var postCreateLoadBalancerListeners* = Call_PostCreateLoadBalancerListeners_613535(
    name: "postCreateLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_PostCreateLoadBalancerListeners_613536, base: "/",
    url: url_PostCreateLoadBalancerListeners_613537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerListeners_613518 = ref object of OpenApiRestCall_612658
proc url_GetCreateLoadBalancerListeners_613520(protocol: Scheme; host: string;
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

proc validate_GetCreateLoadBalancerListeners_613519(path: JsonNode;
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
  var valid_613521 = query.getOrDefault("Listeners")
  valid_613521 = validateParameter(valid_613521, JArray, required = true, default = nil)
  if valid_613521 != nil:
    section.add "Listeners", valid_613521
  var valid_613522 = query.getOrDefault("LoadBalancerName")
  valid_613522 = validateParameter(valid_613522, JString, required = true,
                                 default = nil)
  if valid_613522 != nil:
    section.add "LoadBalancerName", valid_613522
  var valid_613523 = query.getOrDefault("Action")
  valid_613523 = validateParameter(valid_613523, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_613523 != nil:
    section.add "Action", valid_613523
  var valid_613524 = query.getOrDefault("Version")
  valid_613524 = validateParameter(valid_613524, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613524 != nil:
    section.add "Version", valid_613524
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
  var valid_613525 = header.getOrDefault("X-Amz-Signature")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Signature", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Content-Sha256", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Date")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Date", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Credential")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Credential", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Security-Token")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Security-Token", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Algorithm")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Algorithm", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-SignedHeaders", valid_613531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613532: Call_GetCreateLoadBalancerListeners_613518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613532.validator(path, query, header, formData, body)
  let scheme = call_613532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613532.url(scheme.get, call_613532.host, call_613532.base,
                         call_613532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613532, url, valid)

proc call*(call_613533: Call_GetCreateLoadBalancerListeners_613518;
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
  var query_613534 = newJObject()
  if Listeners != nil:
    query_613534.add "Listeners", Listeners
  add(query_613534, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613534, "Action", newJString(Action))
  add(query_613534, "Version", newJString(Version))
  result = call_613533.call(nil, query_613534, nil, nil, nil)

var getCreateLoadBalancerListeners* = Call_GetCreateLoadBalancerListeners_613518(
    name: "getCreateLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_GetCreateLoadBalancerListeners_613519, base: "/",
    url: url_GetCreateLoadBalancerListeners_613520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerPolicy_613572 = ref object of OpenApiRestCall_612658
proc url_PostCreateLoadBalancerPolicy_613574(protocol: Scheme; host: string;
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

proc validate_PostCreateLoadBalancerPolicy_613573(path: JsonNode; query: JsonNode;
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
  var valid_613575 = query.getOrDefault("Action")
  valid_613575 = validateParameter(valid_613575, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_613575 != nil:
    section.add "Action", valid_613575
  var valid_613576 = query.getOrDefault("Version")
  valid_613576 = validateParameter(valid_613576, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613576 != nil:
    section.add "Version", valid_613576
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
  var valid_613577 = header.getOrDefault("X-Amz-Signature")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Signature", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Content-Sha256", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-Date")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Date", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Credential")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Credential", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Security-Token")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Security-Token", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-Algorithm")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Algorithm", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-SignedHeaders", valid_613583
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
  var valid_613584 = formData.getOrDefault("PolicyAttributes")
  valid_613584 = validateParameter(valid_613584, JArray, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "PolicyAttributes", valid_613584
  assert formData != nil,
        "formData argument is necessary due to required `PolicyTypeName` field"
  var valid_613585 = formData.getOrDefault("PolicyTypeName")
  valid_613585 = validateParameter(valid_613585, JString, required = true,
                                 default = nil)
  if valid_613585 != nil:
    section.add "PolicyTypeName", valid_613585
  var valid_613586 = formData.getOrDefault("LoadBalancerName")
  valid_613586 = validateParameter(valid_613586, JString, required = true,
                                 default = nil)
  if valid_613586 != nil:
    section.add "LoadBalancerName", valid_613586
  var valid_613587 = formData.getOrDefault("PolicyName")
  valid_613587 = validateParameter(valid_613587, JString, required = true,
                                 default = nil)
  if valid_613587 != nil:
    section.add "PolicyName", valid_613587
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613588: Call_PostCreateLoadBalancerPolicy_613572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_613588.validator(path, query, header, formData, body)
  let scheme = call_613588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613588.url(scheme.get, call_613588.host, call_613588.base,
                         call_613588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613588, url, valid)

proc call*(call_613589: Call_PostCreateLoadBalancerPolicy_613572;
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
  var query_613590 = newJObject()
  var formData_613591 = newJObject()
  if PolicyAttributes != nil:
    formData_613591.add "PolicyAttributes", PolicyAttributes
  add(formData_613591, "PolicyTypeName", newJString(PolicyTypeName))
  add(formData_613591, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613590, "Action", newJString(Action))
  add(query_613590, "Version", newJString(Version))
  add(formData_613591, "PolicyName", newJString(PolicyName))
  result = call_613589.call(nil, query_613590, nil, formData_613591, nil)

var postCreateLoadBalancerPolicy* = Call_PostCreateLoadBalancerPolicy_613572(
    name: "postCreateLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_PostCreateLoadBalancerPolicy_613573, base: "/",
    url: url_PostCreateLoadBalancerPolicy_613574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerPolicy_613553 = ref object of OpenApiRestCall_612658
proc url_GetCreateLoadBalancerPolicy_613555(protocol: Scheme; host: string;
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

proc validate_GetCreateLoadBalancerPolicy_613554(path: JsonNode; query: JsonNode;
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
  var valid_613556 = query.getOrDefault("PolicyAttributes")
  valid_613556 = validateParameter(valid_613556, JArray, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "PolicyAttributes", valid_613556
  assert query != nil,
        "query argument is necessary due to required `PolicyName` field"
  var valid_613557 = query.getOrDefault("PolicyName")
  valid_613557 = validateParameter(valid_613557, JString, required = true,
                                 default = nil)
  if valid_613557 != nil:
    section.add "PolicyName", valid_613557
  var valid_613558 = query.getOrDefault("PolicyTypeName")
  valid_613558 = validateParameter(valid_613558, JString, required = true,
                                 default = nil)
  if valid_613558 != nil:
    section.add "PolicyTypeName", valid_613558
  var valid_613559 = query.getOrDefault("LoadBalancerName")
  valid_613559 = validateParameter(valid_613559, JString, required = true,
                                 default = nil)
  if valid_613559 != nil:
    section.add "LoadBalancerName", valid_613559
  var valid_613560 = query.getOrDefault("Action")
  valid_613560 = validateParameter(valid_613560, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_613560 != nil:
    section.add "Action", valid_613560
  var valid_613561 = query.getOrDefault("Version")
  valid_613561 = validateParameter(valid_613561, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613561 != nil:
    section.add "Version", valid_613561
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
  var valid_613562 = header.getOrDefault("X-Amz-Signature")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Signature", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Content-Sha256", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-Date")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Date", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-Credential")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Credential", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Security-Token")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Security-Token", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Algorithm")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Algorithm", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-SignedHeaders", valid_613568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613569: Call_GetCreateLoadBalancerPolicy_613553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_613569.validator(path, query, header, formData, body)
  let scheme = call_613569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613569.url(scheme.get, call_613569.host, call_613569.base,
                         call_613569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613569, url, valid)

proc call*(call_613570: Call_GetCreateLoadBalancerPolicy_613553;
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
  var query_613571 = newJObject()
  if PolicyAttributes != nil:
    query_613571.add "PolicyAttributes", PolicyAttributes
  add(query_613571, "PolicyName", newJString(PolicyName))
  add(query_613571, "PolicyTypeName", newJString(PolicyTypeName))
  add(query_613571, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613571, "Action", newJString(Action))
  add(query_613571, "Version", newJString(Version))
  result = call_613570.call(nil, query_613571, nil, nil, nil)

var getCreateLoadBalancerPolicy* = Call_GetCreateLoadBalancerPolicy_613553(
    name: "getCreateLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_GetCreateLoadBalancerPolicy_613554, base: "/",
    url: url_GetCreateLoadBalancerPolicy_613555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_613608 = ref object of OpenApiRestCall_612658
proc url_PostDeleteLoadBalancer_613610(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteLoadBalancer_613609(path: JsonNode; query: JsonNode;
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
  var valid_613611 = query.getOrDefault("Action")
  valid_613611 = validateParameter(valid_613611, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_613611 != nil:
    section.add "Action", valid_613611
  var valid_613612 = query.getOrDefault("Version")
  valid_613612 = validateParameter(valid_613612, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613612 != nil:
    section.add "Version", valid_613612
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
  var valid_613613 = header.getOrDefault("X-Amz-Signature")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-Signature", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Content-Sha256", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Date")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Date", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Credential")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Credential", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Security-Token")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Security-Token", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Algorithm")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Algorithm", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-SignedHeaders", valid_613619
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_613620 = formData.getOrDefault("LoadBalancerName")
  valid_613620 = validateParameter(valid_613620, JString, required = true,
                                 default = nil)
  if valid_613620 != nil:
    section.add "LoadBalancerName", valid_613620
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613621: Call_PostDeleteLoadBalancer_613608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_613621.validator(path, query, header, formData, body)
  let scheme = call_613621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613621.url(scheme.get, call_613621.host, call_613621.base,
                         call_613621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613621, url, valid)

proc call*(call_613622: Call_PostDeleteLoadBalancer_613608;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613623 = newJObject()
  var formData_613624 = newJObject()
  add(formData_613624, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613623, "Action", newJString(Action))
  add(query_613623, "Version", newJString(Version))
  result = call_613622.call(nil, query_613623, nil, formData_613624, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_613608(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_613609, base: "/",
    url: url_PostDeleteLoadBalancer_613610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_613592 = ref object of OpenApiRestCall_612658
proc url_GetDeleteLoadBalancer_613594(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteLoadBalancer_613593(path: JsonNode; query: JsonNode;
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
  var valid_613595 = query.getOrDefault("LoadBalancerName")
  valid_613595 = validateParameter(valid_613595, JString, required = true,
                                 default = nil)
  if valid_613595 != nil:
    section.add "LoadBalancerName", valid_613595
  var valid_613596 = query.getOrDefault("Action")
  valid_613596 = validateParameter(valid_613596, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_613596 != nil:
    section.add "Action", valid_613596
  var valid_613597 = query.getOrDefault("Version")
  valid_613597 = validateParameter(valid_613597, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613597 != nil:
    section.add "Version", valid_613597
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
  var valid_613598 = header.getOrDefault("X-Amz-Signature")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "X-Amz-Signature", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Content-Sha256", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Date")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Date", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Credential")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Credential", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Security-Token")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Security-Token", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Algorithm")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Algorithm", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-SignedHeaders", valid_613604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613605: Call_GetDeleteLoadBalancer_613592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_613605.validator(path, query, header, formData, body)
  let scheme = call_613605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613605.url(scheme.get, call_613605.host, call_613605.base,
                         call_613605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613605, url, valid)

proc call*(call_613606: Call_GetDeleteLoadBalancer_613592;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613607 = newJObject()
  add(query_613607, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613607, "Action", newJString(Action))
  add(query_613607, "Version", newJString(Version))
  result = call_613606.call(nil, query_613607, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_613592(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_613593, base: "/",
    url: url_GetDeleteLoadBalancer_613594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerListeners_613642 = ref object of OpenApiRestCall_612658
proc url_PostDeleteLoadBalancerListeners_613644(protocol: Scheme; host: string;
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

proc validate_PostDeleteLoadBalancerListeners_613643(path: JsonNode;
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
  var valid_613645 = query.getOrDefault("Action")
  valid_613645 = validateParameter(valid_613645, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_613645 != nil:
    section.add "Action", valid_613645
  var valid_613646 = query.getOrDefault("Version")
  valid_613646 = validateParameter(valid_613646, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613646 != nil:
    section.add "Version", valid_613646
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
  var valid_613647 = header.getOrDefault("X-Amz-Signature")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Signature", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Content-Sha256", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Date")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Date", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-Credential")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Credential", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Security-Token")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Security-Token", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Algorithm")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Algorithm", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-SignedHeaders", valid_613653
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerPorts` field"
  var valid_613654 = formData.getOrDefault("LoadBalancerPorts")
  valid_613654 = validateParameter(valid_613654, JArray, required = true, default = nil)
  if valid_613654 != nil:
    section.add "LoadBalancerPorts", valid_613654
  var valid_613655 = formData.getOrDefault("LoadBalancerName")
  valid_613655 = validateParameter(valid_613655, JString, required = true,
                                 default = nil)
  if valid_613655 != nil:
    section.add "LoadBalancerName", valid_613655
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613656: Call_PostDeleteLoadBalancerListeners_613642;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_613656.validator(path, query, header, formData, body)
  let scheme = call_613656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613656.url(scheme.get, call_613656.host, call_613656.base,
                         call_613656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613656, url, valid)

proc call*(call_613657: Call_PostDeleteLoadBalancerListeners_613642;
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
  var query_613658 = newJObject()
  var formData_613659 = newJObject()
  if LoadBalancerPorts != nil:
    formData_613659.add "LoadBalancerPorts", LoadBalancerPorts
  add(formData_613659, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613658, "Action", newJString(Action))
  add(query_613658, "Version", newJString(Version))
  result = call_613657.call(nil, query_613658, nil, formData_613659, nil)

var postDeleteLoadBalancerListeners* = Call_PostDeleteLoadBalancerListeners_613642(
    name: "postDeleteLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_PostDeleteLoadBalancerListeners_613643, base: "/",
    url: url_PostDeleteLoadBalancerListeners_613644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerListeners_613625 = ref object of OpenApiRestCall_612658
proc url_GetDeleteLoadBalancerListeners_613627(protocol: Scheme; host: string;
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

proc validate_GetDeleteLoadBalancerListeners_613626(path: JsonNode;
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
  var valid_613628 = query.getOrDefault("LoadBalancerPorts")
  valid_613628 = validateParameter(valid_613628, JArray, required = true, default = nil)
  if valid_613628 != nil:
    section.add "LoadBalancerPorts", valid_613628
  var valid_613629 = query.getOrDefault("LoadBalancerName")
  valid_613629 = validateParameter(valid_613629, JString, required = true,
                                 default = nil)
  if valid_613629 != nil:
    section.add "LoadBalancerName", valid_613629
  var valid_613630 = query.getOrDefault("Action")
  valid_613630 = validateParameter(valid_613630, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_613630 != nil:
    section.add "Action", valid_613630
  var valid_613631 = query.getOrDefault("Version")
  valid_613631 = validateParameter(valid_613631, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613631 != nil:
    section.add "Version", valid_613631
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
  var valid_613632 = header.getOrDefault("X-Amz-Signature")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Signature", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Content-Sha256", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Date")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Date", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Credential")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Credential", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Security-Token")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Security-Token", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Algorithm")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Algorithm", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-SignedHeaders", valid_613638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613639: Call_GetDeleteLoadBalancerListeners_613625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_613639.validator(path, query, header, formData, body)
  let scheme = call_613639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613639.url(scheme.get, call_613639.host, call_613639.base,
                         call_613639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613639, url, valid)

proc call*(call_613640: Call_GetDeleteLoadBalancerListeners_613625;
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
  var query_613641 = newJObject()
  if LoadBalancerPorts != nil:
    query_613641.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_613641, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613641, "Action", newJString(Action))
  add(query_613641, "Version", newJString(Version))
  result = call_613640.call(nil, query_613641, nil, nil, nil)

var getDeleteLoadBalancerListeners* = Call_GetDeleteLoadBalancerListeners_613625(
    name: "getDeleteLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_GetDeleteLoadBalancerListeners_613626, base: "/",
    url: url_GetDeleteLoadBalancerListeners_613627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerPolicy_613677 = ref object of OpenApiRestCall_612658
proc url_PostDeleteLoadBalancerPolicy_613679(protocol: Scheme; host: string;
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

proc validate_PostDeleteLoadBalancerPolicy_613678(path: JsonNode; query: JsonNode;
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
  var valid_613680 = query.getOrDefault("Action")
  valid_613680 = validateParameter(valid_613680, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_613680 != nil:
    section.add "Action", valid_613680
  var valid_613681 = query.getOrDefault("Version")
  valid_613681 = validateParameter(valid_613681, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613681 != nil:
    section.add "Version", valid_613681
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
  var valid_613682 = header.getOrDefault("X-Amz-Signature")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Signature", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Content-Sha256", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Date")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Date", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Credential")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Credential", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Security-Token")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Security-Token", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Algorithm")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Algorithm", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-SignedHeaders", valid_613688
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_613689 = formData.getOrDefault("LoadBalancerName")
  valid_613689 = validateParameter(valid_613689, JString, required = true,
                                 default = nil)
  if valid_613689 != nil:
    section.add "LoadBalancerName", valid_613689
  var valid_613690 = formData.getOrDefault("PolicyName")
  valid_613690 = validateParameter(valid_613690, JString, required = true,
                                 default = nil)
  if valid_613690 != nil:
    section.add "PolicyName", valid_613690
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613691: Call_PostDeleteLoadBalancerPolicy_613677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_613691.validator(path, query, header, formData, body)
  let scheme = call_613691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613691.url(scheme.get, call_613691.host, call_613691.base,
                         call_613691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613691, url, valid)

proc call*(call_613692: Call_PostDeleteLoadBalancerPolicy_613677;
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
  var query_613693 = newJObject()
  var formData_613694 = newJObject()
  add(formData_613694, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613693, "Action", newJString(Action))
  add(query_613693, "Version", newJString(Version))
  add(formData_613694, "PolicyName", newJString(PolicyName))
  result = call_613692.call(nil, query_613693, nil, formData_613694, nil)

var postDeleteLoadBalancerPolicy* = Call_PostDeleteLoadBalancerPolicy_613677(
    name: "postDeleteLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_PostDeleteLoadBalancerPolicy_613678, base: "/",
    url: url_PostDeleteLoadBalancerPolicy_613679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerPolicy_613660 = ref object of OpenApiRestCall_612658
proc url_GetDeleteLoadBalancerPolicy_613662(protocol: Scheme; host: string;
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

proc validate_GetDeleteLoadBalancerPolicy_613661(path: JsonNode; query: JsonNode;
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
  var valid_613663 = query.getOrDefault("PolicyName")
  valid_613663 = validateParameter(valid_613663, JString, required = true,
                                 default = nil)
  if valid_613663 != nil:
    section.add "PolicyName", valid_613663
  var valid_613664 = query.getOrDefault("LoadBalancerName")
  valid_613664 = validateParameter(valid_613664, JString, required = true,
                                 default = nil)
  if valid_613664 != nil:
    section.add "LoadBalancerName", valid_613664
  var valid_613665 = query.getOrDefault("Action")
  valid_613665 = validateParameter(valid_613665, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_613665 != nil:
    section.add "Action", valid_613665
  var valid_613666 = query.getOrDefault("Version")
  valid_613666 = validateParameter(valid_613666, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613666 != nil:
    section.add "Version", valid_613666
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
  var valid_613667 = header.getOrDefault("X-Amz-Signature")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Signature", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Content-Sha256", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Date")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Date", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Credential")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Credential", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Security-Token")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Security-Token", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Algorithm")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Algorithm", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-SignedHeaders", valid_613673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613674: Call_GetDeleteLoadBalancerPolicy_613660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_613674.validator(path, query, header, formData, body)
  let scheme = call_613674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613674.url(scheme.get, call_613674.host, call_613674.base,
                         call_613674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613674, url, valid)

proc call*(call_613675: Call_GetDeleteLoadBalancerPolicy_613660;
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
  var query_613676 = newJObject()
  add(query_613676, "PolicyName", newJString(PolicyName))
  add(query_613676, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613676, "Action", newJString(Action))
  add(query_613676, "Version", newJString(Version))
  result = call_613675.call(nil, query_613676, nil, nil, nil)

var getDeleteLoadBalancerPolicy* = Call_GetDeleteLoadBalancerPolicy_613660(
    name: "getDeleteLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_GetDeleteLoadBalancerPolicy_613661, base: "/",
    url: url_GetDeleteLoadBalancerPolicy_613662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterInstancesFromLoadBalancer_613712 = ref object of OpenApiRestCall_612658
proc url_PostDeregisterInstancesFromLoadBalancer_613714(protocol: Scheme;
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

proc validate_PostDeregisterInstancesFromLoadBalancer_613713(path: JsonNode;
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
  var valid_613715 = query.getOrDefault("Action")
  valid_613715 = validateParameter(valid_613715, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_613715 != nil:
    section.add "Action", valid_613715
  var valid_613716 = query.getOrDefault("Version")
  valid_613716 = validateParameter(valid_613716, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613716 != nil:
    section.add "Version", valid_613716
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
  var valid_613717 = header.getOrDefault("X-Amz-Signature")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Signature", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-Content-Sha256", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Date")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Date", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Credential")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Credential", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Security-Token")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Security-Token", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Algorithm")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Algorithm", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-SignedHeaders", valid_613723
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_613724 = formData.getOrDefault("Instances")
  valid_613724 = validateParameter(valid_613724, JArray, required = true, default = nil)
  if valid_613724 != nil:
    section.add "Instances", valid_613724
  var valid_613725 = formData.getOrDefault("LoadBalancerName")
  valid_613725 = validateParameter(valid_613725, JString, required = true,
                                 default = nil)
  if valid_613725 != nil:
    section.add "LoadBalancerName", valid_613725
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613726: Call_PostDeregisterInstancesFromLoadBalancer_613712;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613726.validator(path, query, header, formData, body)
  let scheme = call_613726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613726.url(scheme.get, call_613726.host, call_613726.base,
                         call_613726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613726, url, valid)

proc call*(call_613727: Call_PostDeregisterInstancesFromLoadBalancer_613712;
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
  var query_613728 = newJObject()
  var formData_613729 = newJObject()
  if Instances != nil:
    formData_613729.add "Instances", Instances
  add(formData_613729, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613728, "Action", newJString(Action))
  add(query_613728, "Version", newJString(Version))
  result = call_613727.call(nil, query_613728, nil, formData_613729, nil)

var postDeregisterInstancesFromLoadBalancer* = Call_PostDeregisterInstancesFromLoadBalancer_613712(
    name: "postDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_PostDeregisterInstancesFromLoadBalancer_613713, base: "/",
    url: url_PostDeregisterInstancesFromLoadBalancer_613714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterInstancesFromLoadBalancer_613695 = ref object of OpenApiRestCall_612658
proc url_GetDeregisterInstancesFromLoadBalancer_613697(protocol: Scheme;
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

proc validate_GetDeregisterInstancesFromLoadBalancer_613696(path: JsonNode;
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
  var valid_613698 = query.getOrDefault("LoadBalancerName")
  valid_613698 = validateParameter(valid_613698, JString, required = true,
                                 default = nil)
  if valid_613698 != nil:
    section.add "LoadBalancerName", valid_613698
  var valid_613699 = query.getOrDefault("Action")
  valid_613699 = validateParameter(valid_613699, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_613699 != nil:
    section.add "Action", valid_613699
  var valid_613700 = query.getOrDefault("Instances")
  valid_613700 = validateParameter(valid_613700, JArray, required = true, default = nil)
  if valid_613700 != nil:
    section.add "Instances", valid_613700
  var valid_613701 = query.getOrDefault("Version")
  valid_613701 = validateParameter(valid_613701, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613701 != nil:
    section.add "Version", valid_613701
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
  var valid_613702 = header.getOrDefault("X-Amz-Signature")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Signature", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Content-Sha256", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Date")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Date", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Credential")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Credential", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Security-Token")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Security-Token", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Algorithm")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Algorithm", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-SignedHeaders", valid_613708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613709: Call_GetDeregisterInstancesFromLoadBalancer_613695;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613709.validator(path, query, header, formData, body)
  let scheme = call_613709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613709.url(scheme.get, call_613709.host, call_613709.base,
                         call_613709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613709, url, valid)

proc call*(call_613710: Call_GetDeregisterInstancesFromLoadBalancer_613695;
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
  var query_613711 = newJObject()
  add(query_613711, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613711, "Action", newJString(Action))
  if Instances != nil:
    query_613711.add "Instances", Instances
  add(query_613711, "Version", newJString(Version))
  result = call_613710.call(nil, query_613711, nil, nil, nil)

var getDeregisterInstancesFromLoadBalancer* = Call_GetDeregisterInstancesFromLoadBalancer_613695(
    name: "getDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_GetDeregisterInstancesFromLoadBalancer_613696, base: "/",
    url: url_GetDeregisterInstancesFromLoadBalancer_613697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_613747 = ref object of OpenApiRestCall_612658
proc url_PostDescribeAccountLimits_613749(protocol: Scheme; host: string;
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

proc validate_PostDescribeAccountLimits_613748(path: JsonNode; query: JsonNode;
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
  var valid_613750 = query.getOrDefault("Action")
  valid_613750 = validateParameter(valid_613750, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_613750 != nil:
    section.add "Action", valid_613750
  var valid_613751 = query.getOrDefault("Version")
  valid_613751 = validateParameter(valid_613751, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613751 != nil:
    section.add "Version", valid_613751
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
  var valid_613752 = header.getOrDefault("X-Amz-Signature")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Signature", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Content-Sha256", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Date")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Date", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-Credential")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-Credential", valid_613755
  var valid_613756 = header.getOrDefault("X-Amz-Security-Token")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Security-Token", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Algorithm")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Algorithm", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-SignedHeaders", valid_613758
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_613759 = formData.getOrDefault("Marker")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "Marker", valid_613759
  var valid_613760 = formData.getOrDefault("PageSize")
  valid_613760 = validateParameter(valid_613760, JInt, required = false, default = nil)
  if valid_613760 != nil:
    section.add "PageSize", valid_613760
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613761: Call_PostDescribeAccountLimits_613747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613761.validator(path, query, header, formData, body)
  let scheme = call_613761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613761.url(scheme.get, call_613761.host, call_613761.base,
                         call_613761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613761, url, valid)

proc call*(call_613762: Call_PostDescribeAccountLimits_613747; Marker: string = "";
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
  var query_613763 = newJObject()
  var formData_613764 = newJObject()
  add(formData_613764, "Marker", newJString(Marker))
  add(query_613763, "Action", newJString(Action))
  add(formData_613764, "PageSize", newJInt(PageSize))
  add(query_613763, "Version", newJString(Version))
  result = call_613762.call(nil, query_613763, nil, formData_613764, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_613747(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_613748, base: "/",
    url: url_PostDescribeAccountLimits_613749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_613730 = ref object of OpenApiRestCall_612658
proc url_GetDescribeAccountLimits_613732(protocol: Scheme; host: string;
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

proc validate_GetDescribeAccountLimits_613731(path: JsonNode; query: JsonNode;
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
  var valid_613733 = query.getOrDefault("Marker")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "Marker", valid_613733
  var valid_613734 = query.getOrDefault("PageSize")
  valid_613734 = validateParameter(valid_613734, JInt, required = false, default = nil)
  if valid_613734 != nil:
    section.add "PageSize", valid_613734
  var valid_613735 = query.getOrDefault("Action")
  valid_613735 = validateParameter(valid_613735, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_613735 != nil:
    section.add "Action", valid_613735
  var valid_613736 = query.getOrDefault("Version")
  valid_613736 = validateParameter(valid_613736, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613736 != nil:
    section.add "Version", valid_613736
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
  var valid_613737 = header.getOrDefault("X-Amz-Signature")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Signature", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Content-Sha256", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Date")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Date", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-Credential")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Credential", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Security-Token")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Security-Token", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Algorithm")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Algorithm", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-SignedHeaders", valid_613743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613744: Call_GetDescribeAccountLimits_613730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_613744.validator(path, query, header, formData, body)
  let scheme = call_613744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613744.url(scheme.get, call_613744.host, call_613744.base,
                         call_613744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613744, url, valid)

proc call*(call_613745: Call_GetDescribeAccountLimits_613730; Marker: string = "";
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
  var query_613746 = newJObject()
  add(query_613746, "Marker", newJString(Marker))
  add(query_613746, "PageSize", newJInt(PageSize))
  add(query_613746, "Action", newJString(Action))
  add(query_613746, "Version", newJString(Version))
  result = call_613745.call(nil, query_613746, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_613730(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_613731, base: "/",
    url: url_GetDescribeAccountLimits_613732, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstanceHealth_613782 = ref object of OpenApiRestCall_612658
proc url_PostDescribeInstanceHealth_613784(protocol: Scheme; host: string;
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

proc validate_PostDescribeInstanceHealth_613783(path: JsonNode; query: JsonNode;
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
  var valid_613785 = query.getOrDefault("Action")
  valid_613785 = validateParameter(valid_613785, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_613785 != nil:
    section.add "Action", valid_613785
  var valid_613786 = query.getOrDefault("Version")
  valid_613786 = validateParameter(valid_613786, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613786 != nil:
    section.add "Version", valid_613786
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
  var valid_613787 = header.getOrDefault("X-Amz-Signature")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-Signature", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Content-Sha256", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-Date")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-Date", valid_613789
  var valid_613790 = header.getOrDefault("X-Amz-Credential")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-Credential", valid_613790
  var valid_613791 = header.getOrDefault("X-Amz-Security-Token")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Security-Token", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Algorithm")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Algorithm", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-SignedHeaders", valid_613793
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_613794 = formData.getOrDefault("Instances")
  valid_613794 = validateParameter(valid_613794, JArray, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "Instances", valid_613794
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_613795 = formData.getOrDefault("LoadBalancerName")
  valid_613795 = validateParameter(valid_613795, JString, required = true,
                                 default = nil)
  if valid_613795 != nil:
    section.add "LoadBalancerName", valid_613795
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613796: Call_PostDescribeInstanceHealth_613782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_613796.validator(path, query, header, formData, body)
  let scheme = call_613796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613796.url(scheme.get, call_613796.host, call_613796.base,
                         call_613796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613796, url, valid)

proc call*(call_613797: Call_PostDescribeInstanceHealth_613782;
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
  var query_613798 = newJObject()
  var formData_613799 = newJObject()
  if Instances != nil:
    formData_613799.add "Instances", Instances
  add(formData_613799, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613798, "Action", newJString(Action))
  add(query_613798, "Version", newJString(Version))
  result = call_613797.call(nil, query_613798, nil, formData_613799, nil)

var postDescribeInstanceHealth* = Call_PostDescribeInstanceHealth_613782(
    name: "postDescribeInstanceHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_PostDescribeInstanceHealth_613783, base: "/",
    url: url_PostDescribeInstanceHealth_613784,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstanceHealth_613765 = ref object of OpenApiRestCall_612658
proc url_GetDescribeInstanceHealth_613767(protocol: Scheme; host: string;
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

proc validate_GetDescribeInstanceHealth_613766(path: JsonNode; query: JsonNode;
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
  var valid_613768 = query.getOrDefault("LoadBalancerName")
  valid_613768 = validateParameter(valid_613768, JString, required = true,
                                 default = nil)
  if valid_613768 != nil:
    section.add "LoadBalancerName", valid_613768
  var valid_613769 = query.getOrDefault("Action")
  valid_613769 = validateParameter(valid_613769, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_613769 != nil:
    section.add "Action", valid_613769
  var valid_613770 = query.getOrDefault("Instances")
  valid_613770 = validateParameter(valid_613770, JArray, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "Instances", valid_613770
  var valid_613771 = query.getOrDefault("Version")
  valid_613771 = validateParameter(valid_613771, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613771 != nil:
    section.add "Version", valid_613771
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
  var valid_613772 = header.getOrDefault("X-Amz-Signature")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Signature", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Content-Sha256", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-Date")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Date", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-Credential")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Credential", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-Security-Token")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Security-Token", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Algorithm")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Algorithm", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-SignedHeaders", valid_613778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613779: Call_GetDescribeInstanceHealth_613765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_613779.validator(path, query, header, formData, body)
  let scheme = call_613779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613779.url(scheme.get, call_613779.host, call_613779.base,
                         call_613779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613779, url, valid)

proc call*(call_613780: Call_GetDescribeInstanceHealth_613765;
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
  var query_613781 = newJObject()
  add(query_613781, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613781, "Action", newJString(Action))
  if Instances != nil:
    query_613781.add "Instances", Instances
  add(query_613781, "Version", newJString(Version))
  result = call_613780.call(nil, query_613781, nil, nil, nil)

var getDescribeInstanceHealth* = Call_GetDescribeInstanceHealth_613765(
    name: "getDescribeInstanceHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_GetDescribeInstanceHealth_613766, base: "/",
    url: url_GetDescribeInstanceHealth_613767,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_613816 = ref object of OpenApiRestCall_612658
proc url_PostDescribeLoadBalancerAttributes_613818(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerAttributes_613817(path: JsonNode;
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
  var valid_613819 = query.getOrDefault("Action")
  valid_613819 = validateParameter(valid_613819, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_613819 != nil:
    section.add "Action", valid_613819
  var valid_613820 = query.getOrDefault("Version")
  valid_613820 = validateParameter(valid_613820, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613820 != nil:
    section.add "Version", valid_613820
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
  var valid_613821 = header.getOrDefault("X-Amz-Signature")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "X-Amz-Signature", valid_613821
  var valid_613822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "X-Amz-Content-Sha256", valid_613822
  var valid_613823 = header.getOrDefault("X-Amz-Date")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "X-Amz-Date", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-Credential")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Credential", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-Security-Token")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Security-Token", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Algorithm")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Algorithm", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-SignedHeaders", valid_613827
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_613828 = formData.getOrDefault("LoadBalancerName")
  valid_613828 = validateParameter(valid_613828, JString, required = true,
                                 default = nil)
  if valid_613828 != nil:
    section.add "LoadBalancerName", valid_613828
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613829: Call_PostDescribeLoadBalancerAttributes_613816;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_613829.validator(path, query, header, formData, body)
  let scheme = call_613829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613829.url(scheme.get, call_613829.host, call_613829.base,
                         call_613829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613829, url, valid)

proc call*(call_613830: Call_PostDescribeLoadBalancerAttributes_613816;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613831 = newJObject()
  var formData_613832 = newJObject()
  add(formData_613832, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613831, "Action", newJString(Action))
  add(query_613831, "Version", newJString(Version))
  result = call_613830.call(nil, query_613831, nil, formData_613832, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_613816(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_613817, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_613818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_613800 = ref object of OpenApiRestCall_612658
proc url_GetDescribeLoadBalancerAttributes_613802(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerAttributes_613801(path: JsonNode;
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
  var valid_613803 = query.getOrDefault("LoadBalancerName")
  valid_613803 = validateParameter(valid_613803, JString, required = true,
                                 default = nil)
  if valid_613803 != nil:
    section.add "LoadBalancerName", valid_613803
  var valid_613804 = query.getOrDefault("Action")
  valid_613804 = validateParameter(valid_613804, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_613804 != nil:
    section.add "Action", valid_613804
  var valid_613805 = query.getOrDefault("Version")
  valid_613805 = validateParameter(valid_613805, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613805 != nil:
    section.add "Version", valid_613805
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
  var valid_613806 = header.getOrDefault("X-Amz-Signature")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "X-Amz-Signature", valid_613806
  var valid_613807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = nil)
  if valid_613807 != nil:
    section.add "X-Amz-Content-Sha256", valid_613807
  var valid_613808 = header.getOrDefault("X-Amz-Date")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-Date", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Credential")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Credential", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Security-Token")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Security-Token", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Algorithm")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Algorithm", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-SignedHeaders", valid_613812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613813: Call_GetDescribeLoadBalancerAttributes_613800;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_613813.validator(path, query, header, formData, body)
  let scheme = call_613813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613813.url(scheme.get, call_613813.host, call_613813.base,
                         call_613813.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613813, url, valid)

proc call*(call_613814: Call_GetDescribeLoadBalancerAttributes_613800;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613815 = newJObject()
  add(query_613815, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613815, "Action", newJString(Action))
  add(query_613815, "Version", newJString(Version))
  result = call_613814.call(nil, query_613815, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_613800(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_613801, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_613802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicies_613850 = ref object of OpenApiRestCall_612658
proc url_PostDescribeLoadBalancerPolicies_613852(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerPolicies_613851(path: JsonNode;
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
  var valid_613853 = query.getOrDefault("Action")
  valid_613853 = validateParameter(valid_613853, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_613853 != nil:
    section.add "Action", valid_613853
  var valid_613854 = query.getOrDefault("Version")
  valid_613854 = validateParameter(valid_613854, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613854 != nil:
    section.add "Version", valid_613854
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
  var valid_613855 = header.getOrDefault("X-Amz-Signature")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-Signature", valid_613855
  var valid_613856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-Content-Sha256", valid_613856
  var valid_613857 = header.getOrDefault("X-Amz-Date")
  valid_613857 = validateParameter(valid_613857, JString, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "X-Amz-Date", valid_613857
  var valid_613858 = header.getOrDefault("X-Amz-Credential")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "X-Amz-Credential", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Security-Token")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Security-Token", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-Algorithm")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-Algorithm", valid_613860
  var valid_613861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613861 = validateParameter(valid_613861, JString, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "X-Amz-SignedHeaders", valid_613861
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   LoadBalancerName: JString
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_613862 = formData.getOrDefault("PolicyNames")
  valid_613862 = validateParameter(valid_613862, JArray, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "PolicyNames", valid_613862
  var valid_613863 = formData.getOrDefault("LoadBalancerName")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "LoadBalancerName", valid_613863
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613864: Call_PostDescribeLoadBalancerPolicies_613850;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_613864.validator(path, query, header, formData, body)
  let scheme = call_613864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613864.url(scheme.get, call_613864.host, call_613864.base,
                         call_613864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613864, url, valid)

proc call*(call_613865: Call_PostDescribeLoadBalancerPolicies_613850;
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
  var query_613866 = newJObject()
  var formData_613867 = newJObject()
  if PolicyNames != nil:
    formData_613867.add "PolicyNames", PolicyNames
  add(formData_613867, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613866, "Action", newJString(Action))
  add(query_613866, "Version", newJString(Version))
  result = call_613865.call(nil, query_613866, nil, formData_613867, nil)

var postDescribeLoadBalancerPolicies* = Call_PostDescribeLoadBalancerPolicies_613850(
    name: "postDescribeLoadBalancerPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_PostDescribeLoadBalancerPolicies_613851, base: "/",
    url: url_PostDescribeLoadBalancerPolicies_613852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicies_613833 = ref object of OpenApiRestCall_612658
proc url_GetDescribeLoadBalancerPolicies_613835(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerPolicies_613834(path: JsonNode;
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
  var valid_613836 = query.getOrDefault("LoadBalancerName")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "LoadBalancerName", valid_613836
  var valid_613837 = query.getOrDefault("Action")
  valid_613837 = validateParameter(valid_613837, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_613837 != nil:
    section.add "Action", valid_613837
  var valid_613838 = query.getOrDefault("Version")
  valid_613838 = validateParameter(valid_613838, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613838 != nil:
    section.add "Version", valid_613838
  var valid_613839 = query.getOrDefault("PolicyNames")
  valid_613839 = validateParameter(valid_613839, JArray, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "PolicyNames", valid_613839
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
  var valid_613840 = header.getOrDefault("X-Amz-Signature")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "X-Amz-Signature", valid_613840
  var valid_613841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613841 = validateParameter(valid_613841, JString, required = false,
                                 default = nil)
  if valid_613841 != nil:
    section.add "X-Amz-Content-Sha256", valid_613841
  var valid_613842 = header.getOrDefault("X-Amz-Date")
  valid_613842 = validateParameter(valid_613842, JString, required = false,
                                 default = nil)
  if valid_613842 != nil:
    section.add "X-Amz-Date", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-Credential")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Credential", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Security-Token")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Security-Token", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-Algorithm")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Algorithm", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-SignedHeaders", valid_613846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613847: Call_GetDescribeLoadBalancerPolicies_613833;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_613847.validator(path, query, header, formData, body)
  let scheme = call_613847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613847.url(scheme.get, call_613847.host, call_613847.base,
                         call_613847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613847, url, valid)

proc call*(call_613848: Call_GetDescribeLoadBalancerPolicies_613833;
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
  var query_613849 = newJObject()
  add(query_613849, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613849, "Action", newJString(Action))
  add(query_613849, "Version", newJString(Version))
  if PolicyNames != nil:
    query_613849.add "PolicyNames", PolicyNames
  result = call_613848.call(nil, query_613849, nil, nil, nil)

var getDescribeLoadBalancerPolicies* = Call_GetDescribeLoadBalancerPolicies_613833(
    name: "getDescribeLoadBalancerPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_GetDescribeLoadBalancerPolicies_613834, base: "/",
    url: url_GetDescribeLoadBalancerPolicies_613835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicyTypes_613884 = ref object of OpenApiRestCall_612658
proc url_PostDescribeLoadBalancerPolicyTypes_613886(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancerPolicyTypes_613885(path: JsonNode;
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
  var valid_613887 = query.getOrDefault("Action")
  valid_613887 = validateParameter(valid_613887, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_613887 != nil:
    section.add "Action", valid_613887
  var valid_613888 = query.getOrDefault("Version")
  valid_613888 = validateParameter(valid_613888, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613888 != nil:
    section.add "Version", valid_613888
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
  var valid_613889 = header.getOrDefault("X-Amz-Signature")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Signature", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-Content-Sha256", valid_613890
  var valid_613891 = header.getOrDefault("X-Amz-Date")
  valid_613891 = validateParameter(valid_613891, JString, required = false,
                                 default = nil)
  if valid_613891 != nil:
    section.add "X-Amz-Date", valid_613891
  var valid_613892 = header.getOrDefault("X-Amz-Credential")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Credential", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Security-Token")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Security-Token", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Algorithm")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Algorithm", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-SignedHeaders", valid_613895
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  section = newJObject()
  var valid_613896 = formData.getOrDefault("PolicyTypeNames")
  valid_613896 = validateParameter(valid_613896, JArray, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "PolicyTypeNames", valid_613896
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613897: Call_PostDescribeLoadBalancerPolicyTypes_613884;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_613897.validator(path, query, header, formData, body)
  let scheme = call_613897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613897.url(scheme.get, call_613897.host, call_613897.base,
                         call_613897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613897, url, valid)

proc call*(call_613898: Call_PostDescribeLoadBalancerPolicyTypes_613884;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613899 = newJObject()
  var formData_613900 = newJObject()
  if PolicyTypeNames != nil:
    formData_613900.add "PolicyTypeNames", PolicyTypeNames
  add(query_613899, "Action", newJString(Action))
  add(query_613899, "Version", newJString(Version))
  result = call_613898.call(nil, query_613899, nil, formData_613900, nil)

var postDescribeLoadBalancerPolicyTypes* = Call_PostDescribeLoadBalancerPolicyTypes_613884(
    name: "postDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_PostDescribeLoadBalancerPolicyTypes_613885, base: "/",
    url: url_PostDescribeLoadBalancerPolicyTypes_613886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicyTypes_613868 = ref object of OpenApiRestCall_612658
proc url_GetDescribeLoadBalancerPolicyTypes_613870(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancerPolicyTypes_613869(path: JsonNode;
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
  var valid_613871 = query.getOrDefault("PolicyTypeNames")
  valid_613871 = validateParameter(valid_613871, JArray, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "PolicyTypeNames", valid_613871
  var valid_613872 = query.getOrDefault("Action")
  valid_613872 = validateParameter(valid_613872, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_613872 != nil:
    section.add "Action", valid_613872
  var valid_613873 = query.getOrDefault("Version")
  valid_613873 = validateParameter(valid_613873, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613873 != nil:
    section.add "Version", valid_613873
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
  var valid_613874 = header.getOrDefault("X-Amz-Signature")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Signature", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-Content-Sha256", valid_613875
  var valid_613876 = header.getOrDefault("X-Amz-Date")
  valid_613876 = validateParameter(valid_613876, JString, required = false,
                                 default = nil)
  if valid_613876 != nil:
    section.add "X-Amz-Date", valid_613876
  var valid_613877 = header.getOrDefault("X-Amz-Credential")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Credential", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Security-Token")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Security-Token", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Algorithm")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Algorithm", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-SignedHeaders", valid_613880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613881: Call_GetDescribeLoadBalancerPolicyTypes_613868;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_613881.validator(path, query, header, formData, body)
  let scheme = call_613881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613881.url(scheme.get, call_613881.host, call_613881.base,
                         call_613881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613881, url, valid)

proc call*(call_613882: Call_GetDescribeLoadBalancerPolicyTypes_613868;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613883 = newJObject()
  if PolicyTypeNames != nil:
    query_613883.add "PolicyTypeNames", PolicyTypeNames
  add(query_613883, "Action", newJString(Action))
  add(query_613883, "Version", newJString(Version))
  result = call_613882.call(nil, query_613883, nil, nil, nil)

var getDescribeLoadBalancerPolicyTypes* = Call_GetDescribeLoadBalancerPolicyTypes_613868(
    name: "getDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_GetDescribeLoadBalancerPolicyTypes_613869, base: "/",
    url: url_GetDescribeLoadBalancerPolicyTypes_613870,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_613919 = ref object of OpenApiRestCall_612658
proc url_PostDescribeLoadBalancers_613921(protocol: Scheme; host: string;
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

proc validate_PostDescribeLoadBalancers_613920(path: JsonNode; query: JsonNode;
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
  var valid_613922 = query.getOrDefault("Action")
  valid_613922 = validateParameter(valid_613922, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_613922 != nil:
    section.add "Action", valid_613922
  var valid_613923 = query.getOrDefault("Version")
  valid_613923 = validateParameter(valid_613923, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613923 != nil:
    section.add "Version", valid_613923
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
  var valid_613924 = header.getOrDefault("X-Amz-Signature")
  valid_613924 = validateParameter(valid_613924, JString, required = false,
                                 default = nil)
  if valid_613924 != nil:
    section.add "X-Amz-Signature", valid_613924
  var valid_613925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Content-Sha256", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Date")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Date", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Credential")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Credential", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-Security-Token")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-Security-Token", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-Algorithm")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Algorithm", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-SignedHeaders", valid_613930
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  section = newJObject()
  var valid_613931 = formData.getOrDefault("LoadBalancerNames")
  valid_613931 = validateParameter(valid_613931, JArray, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "LoadBalancerNames", valid_613931
  var valid_613932 = formData.getOrDefault("Marker")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "Marker", valid_613932
  var valid_613933 = formData.getOrDefault("PageSize")
  valid_613933 = validateParameter(valid_613933, JInt, required = false, default = nil)
  if valid_613933 != nil:
    section.add "PageSize", valid_613933
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613934: Call_PostDescribeLoadBalancers_613919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_613934.validator(path, query, header, formData, body)
  let scheme = call_613934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613934.url(scheme.get, call_613934.host, call_613934.base,
                         call_613934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613934, url, valid)

proc call*(call_613935: Call_PostDescribeLoadBalancers_613919;
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
  var query_613936 = newJObject()
  var formData_613937 = newJObject()
  if LoadBalancerNames != nil:
    formData_613937.add "LoadBalancerNames", LoadBalancerNames
  add(formData_613937, "Marker", newJString(Marker))
  add(query_613936, "Action", newJString(Action))
  add(formData_613937, "PageSize", newJInt(PageSize))
  add(query_613936, "Version", newJString(Version))
  result = call_613935.call(nil, query_613936, nil, formData_613937, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_613919(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_613920, base: "/",
    url: url_PostDescribeLoadBalancers_613921,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_613901 = ref object of OpenApiRestCall_612658
proc url_GetDescribeLoadBalancers_613903(protocol: Scheme; host: string;
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

proc validate_GetDescribeLoadBalancers_613902(path: JsonNode; query: JsonNode;
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
  var valid_613904 = query.getOrDefault("Marker")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "Marker", valid_613904
  var valid_613905 = query.getOrDefault("PageSize")
  valid_613905 = validateParameter(valid_613905, JInt, required = false, default = nil)
  if valid_613905 != nil:
    section.add "PageSize", valid_613905
  var valid_613906 = query.getOrDefault("Action")
  valid_613906 = validateParameter(valid_613906, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_613906 != nil:
    section.add "Action", valid_613906
  var valid_613907 = query.getOrDefault("Version")
  valid_613907 = validateParameter(valid_613907, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613907 != nil:
    section.add "Version", valid_613907
  var valid_613908 = query.getOrDefault("LoadBalancerNames")
  valid_613908 = validateParameter(valid_613908, JArray, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "LoadBalancerNames", valid_613908
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
  var valid_613909 = header.getOrDefault("X-Amz-Signature")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-Signature", valid_613909
  var valid_613910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Content-Sha256", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Date")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Date", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-Credential")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Credential", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Security-Token")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Security-Token", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-Algorithm")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Algorithm", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-SignedHeaders", valid_613915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613916: Call_GetDescribeLoadBalancers_613901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_613916.validator(path, query, header, formData, body)
  let scheme = call_613916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613916.url(scheme.get, call_613916.host, call_613916.base,
                         call_613916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613916, url, valid)

proc call*(call_613917: Call_GetDescribeLoadBalancers_613901; Marker: string = "";
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
  var query_613918 = newJObject()
  add(query_613918, "Marker", newJString(Marker))
  add(query_613918, "PageSize", newJInt(PageSize))
  add(query_613918, "Action", newJString(Action))
  add(query_613918, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_613918.add "LoadBalancerNames", LoadBalancerNames
  result = call_613917.call(nil, query_613918, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_613901(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_613902, base: "/",
    url: url_GetDescribeLoadBalancers_613903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_613954 = ref object of OpenApiRestCall_612658
proc url_PostDescribeTags_613956(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeTags_613955(path: JsonNode; query: JsonNode;
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
  var valid_613957 = query.getOrDefault("Action")
  valid_613957 = validateParameter(valid_613957, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_613957 != nil:
    section.add "Action", valid_613957
  var valid_613958 = query.getOrDefault("Version")
  valid_613958 = validateParameter(valid_613958, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613958 != nil:
    section.add "Version", valid_613958
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
  var valid_613959 = header.getOrDefault("X-Amz-Signature")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Signature", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Content-Sha256", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Date")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Date", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Credential")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Credential", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-Security-Token")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Security-Token", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-Algorithm")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-Algorithm", valid_613964
  var valid_613965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-SignedHeaders", valid_613965
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_613966 = formData.getOrDefault("LoadBalancerNames")
  valid_613966 = validateParameter(valid_613966, JArray, required = true, default = nil)
  if valid_613966 != nil:
    section.add "LoadBalancerNames", valid_613966
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613967: Call_PostDescribeTags_613954; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_613967.validator(path, query, header, formData, body)
  let scheme = call_613967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613967.url(scheme.get, call_613967.host, call_613967.base,
                         call_613967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613967, url, valid)

proc call*(call_613968: Call_PostDescribeTags_613954; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613969 = newJObject()
  var formData_613970 = newJObject()
  if LoadBalancerNames != nil:
    formData_613970.add "LoadBalancerNames", LoadBalancerNames
  add(query_613969, "Action", newJString(Action))
  add(query_613969, "Version", newJString(Version))
  result = call_613968.call(nil, query_613969, nil, formData_613970, nil)

var postDescribeTags* = Call_PostDescribeTags_613954(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_613955,
    base: "/", url: url_PostDescribeTags_613956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_613938 = ref object of OpenApiRestCall_612658
proc url_GetDescribeTags_613940(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeTags_613939(path: JsonNode; query: JsonNode;
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
  var valid_613941 = query.getOrDefault("Action")
  valid_613941 = validateParameter(valid_613941, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_613941 != nil:
    section.add "Action", valid_613941
  var valid_613942 = query.getOrDefault("Version")
  valid_613942 = validateParameter(valid_613942, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613942 != nil:
    section.add "Version", valid_613942
  var valid_613943 = query.getOrDefault("LoadBalancerNames")
  valid_613943 = validateParameter(valid_613943, JArray, required = true, default = nil)
  if valid_613943 != nil:
    section.add "LoadBalancerNames", valid_613943
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
  var valid_613944 = header.getOrDefault("X-Amz-Signature")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Signature", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Content-Sha256", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Date")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Date", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Credential")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Credential", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-Security-Token")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-Security-Token", valid_613948
  var valid_613949 = header.getOrDefault("X-Amz-Algorithm")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-Algorithm", valid_613949
  var valid_613950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-SignedHeaders", valid_613950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613951: Call_GetDescribeTags_613938; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_613951.validator(path, query, header, formData, body)
  let scheme = call_613951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613951.url(scheme.get, call_613951.host, call_613951.base,
                         call_613951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613951, url, valid)

proc call*(call_613952: Call_GetDescribeTags_613938; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  var query_613953 = newJObject()
  add(query_613953, "Action", newJString(Action))
  add(query_613953, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_613953.add "LoadBalancerNames", LoadBalancerNames
  result = call_613952.call(nil, query_613953, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_613938(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_613939,
    base: "/", url: url_GetDescribeTags_613940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDetachLoadBalancerFromSubnets_613988 = ref object of OpenApiRestCall_612658
proc url_PostDetachLoadBalancerFromSubnets_613990(protocol: Scheme; host: string;
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

proc validate_PostDetachLoadBalancerFromSubnets_613989(path: JsonNode;
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
  var valid_613991 = query.getOrDefault("Action")
  valid_613991 = validateParameter(valid_613991, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_613991 != nil:
    section.add "Action", valid_613991
  var valid_613992 = query.getOrDefault("Version")
  valid_613992 = validateParameter(valid_613992, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613992 != nil:
    section.add "Version", valid_613992
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
  var valid_613993 = header.getOrDefault("X-Amz-Signature")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Signature", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Content-Sha256", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-Date")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Date", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-Credential")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-Credential", valid_613996
  var valid_613997 = header.getOrDefault("X-Amz-Security-Token")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "X-Amz-Security-Token", valid_613997
  var valid_613998 = header.getOrDefault("X-Amz-Algorithm")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-Algorithm", valid_613998
  var valid_613999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "X-Amz-SignedHeaders", valid_613999
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_614000 = formData.getOrDefault("Subnets")
  valid_614000 = validateParameter(valid_614000, JArray, required = true, default = nil)
  if valid_614000 != nil:
    section.add "Subnets", valid_614000
  var valid_614001 = formData.getOrDefault("LoadBalancerName")
  valid_614001 = validateParameter(valid_614001, JString, required = true,
                                 default = nil)
  if valid_614001 != nil:
    section.add "LoadBalancerName", valid_614001
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614002: Call_PostDetachLoadBalancerFromSubnets_613988;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_614002.validator(path, query, header, formData, body)
  let scheme = call_614002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614002.url(scheme.get, call_614002.host, call_614002.base,
                         call_614002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614002, url, valid)

proc call*(call_614003: Call_PostDetachLoadBalancerFromSubnets_613988;
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
  var query_614004 = newJObject()
  var formData_614005 = newJObject()
  if Subnets != nil:
    formData_614005.add "Subnets", Subnets
  add(formData_614005, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614004, "Action", newJString(Action))
  add(query_614004, "Version", newJString(Version))
  result = call_614003.call(nil, query_614004, nil, formData_614005, nil)

var postDetachLoadBalancerFromSubnets* = Call_PostDetachLoadBalancerFromSubnets_613988(
    name: "postDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_PostDetachLoadBalancerFromSubnets_613989, base: "/",
    url: url_PostDetachLoadBalancerFromSubnets_613990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetachLoadBalancerFromSubnets_613971 = ref object of OpenApiRestCall_612658
proc url_GetDetachLoadBalancerFromSubnets_613973(protocol: Scheme; host: string;
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

proc validate_GetDetachLoadBalancerFromSubnets_613972(path: JsonNode;
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
  var valid_613974 = query.getOrDefault("LoadBalancerName")
  valid_613974 = validateParameter(valid_613974, JString, required = true,
                                 default = nil)
  if valid_613974 != nil:
    section.add "LoadBalancerName", valid_613974
  var valid_613975 = query.getOrDefault("Action")
  valid_613975 = validateParameter(valid_613975, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_613975 != nil:
    section.add "Action", valid_613975
  var valid_613976 = query.getOrDefault("Subnets")
  valid_613976 = validateParameter(valid_613976, JArray, required = true, default = nil)
  if valid_613976 != nil:
    section.add "Subnets", valid_613976
  var valid_613977 = query.getOrDefault("Version")
  valid_613977 = validateParameter(valid_613977, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_613977 != nil:
    section.add "Version", valid_613977
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
  var valid_613978 = header.getOrDefault("X-Amz-Signature")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Signature", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Content-Sha256", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-Date")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-Date", valid_613980
  var valid_613981 = header.getOrDefault("X-Amz-Credential")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-Credential", valid_613981
  var valid_613982 = header.getOrDefault("X-Amz-Security-Token")
  valid_613982 = validateParameter(valid_613982, JString, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "X-Amz-Security-Token", valid_613982
  var valid_613983 = header.getOrDefault("X-Amz-Algorithm")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "X-Amz-Algorithm", valid_613983
  var valid_613984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613984 = validateParameter(valid_613984, JString, required = false,
                                 default = nil)
  if valid_613984 != nil:
    section.add "X-Amz-SignedHeaders", valid_613984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613985: Call_GetDetachLoadBalancerFromSubnets_613971;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_613985.validator(path, query, header, formData, body)
  let scheme = call_613985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613985.url(scheme.get, call_613985.host, call_613985.base,
                         call_613985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613985, url, valid)

proc call*(call_613986: Call_GetDetachLoadBalancerFromSubnets_613971;
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
  var query_613987 = newJObject()
  add(query_613987, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_613987, "Action", newJString(Action))
  if Subnets != nil:
    query_613987.add "Subnets", Subnets
  add(query_613987, "Version", newJString(Version))
  result = call_613986.call(nil, query_613987, nil, nil, nil)

var getDetachLoadBalancerFromSubnets* = Call_GetDetachLoadBalancerFromSubnets_613971(
    name: "getDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_GetDetachLoadBalancerFromSubnets_613972, base: "/",
    url: url_GetDetachLoadBalancerFromSubnets_613973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAvailabilityZonesForLoadBalancer_614023 = ref object of OpenApiRestCall_612658
proc url_PostDisableAvailabilityZonesForLoadBalancer_614025(protocol: Scheme;
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

proc validate_PostDisableAvailabilityZonesForLoadBalancer_614024(path: JsonNode;
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
  var valid_614026 = query.getOrDefault("Action")
  valid_614026 = validateParameter(valid_614026, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_614026 != nil:
    section.add "Action", valid_614026
  var valid_614027 = query.getOrDefault("Version")
  valid_614027 = validateParameter(valid_614027, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614027 != nil:
    section.add "Version", valid_614027
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
  var valid_614028 = header.getOrDefault("X-Amz-Signature")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Signature", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-Content-Sha256", valid_614029
  var valid_614030 = header.getOrDefault("X-Amz-Date")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "X-Amz-Date", valid_614030
  var valid_614031 = header.getOrDefault("X-Amz-Credential")
  valid_614031 = validateParameter(valid_614031, JString, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "X-Amz-Credential", valid_614031
  var valid_614032 = header.getOrDefault("X-Amz-Security-Token")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "X-Amz-Security-Token", valid_614032
  var valid_614033 = header.getOrDefault("X-Amz-Algorithm")
  valid_614033 = validateParameter(valid_614033, JString, required = false,
                                 default = nil)
  if valid_614033 != nil:
    section.add "X-Amz-Algorithm", valid_614033
  var valid_614034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "X-Amz-SignedHeaders", valid_614034
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_614035 = formData.getOrDefault("AvailabilityZones")
  valid_614035 = validateParameter(valid_614035, JArray, required = true, default = nil)
  if valid_614035 != nil:
    section.add "AvailabilityZones", valid_614035
  var valid_614036 = formData.getOrDefault("LoadBalancerName")
  valid_614036 = validateParameter(valid_614036, JString, required = true,
                                 default = nil)
  if valid_614036 != nil:
    section.add "LoadBalancerName", valid_614036
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614037: Call_PostDisableAvailabilityZonesForLoadBalancer_614023;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_614037.validator(path, query, header, formData, body)
  let scheme = call_614037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614037.url(scheme.get, call_614037.host, call_614037.base,
                         call_614037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614037, url, valid)

proc call*(call_614038: Call_PostDisableAvailabilityZonesForLoadBalancer_614023;
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
  var query_614039 = newJObject()
  var formData_614040 = newJObject()
  if AvailabilityZones != nil:
    formData_614040.add "AvailabilityZones", AvailabilityZones
  add(formData_614040, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614039, "Action", newJString(Action))
  add(query_614039, "Version", newJString(Version))
  result = call_614038.call(nil, query_614039, nil, formData_614040, nil)

var postDisableAvailabilityZonesForLoadBalancer* = Call_PostDisableAvailabilityZonesForLoadBalancer_614023(
    name: "postDisableAvailabilityZonesForLoadBalancer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_PostDisableAvailabilityZonesForLoadBalancer_614024,
    base: "/", url: url_PostDisableAvailabilityZonesForLoadBalancer_614025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAvailabilityZonesForLoadBalancer_614006 = ref object of OpenApiRestCall_612658
proc url_GetDisableAvailabilityZonesForLoadBalancer_614008(protocol: Scheme;
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

proc validate_GetDisableAvailabilityZonesForLoadBalancer_614007(path: JsonNode;
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
  var valid_614009 = query.getOrDefault("AvailabilityZones")
  valid_614009 = validateParameter(valid_614009, JArray, required = true, default = nil)
  if valid_614009 != nil:
    section.add "AvailabilityZones", valid_614009
  var valid_614010 = query.getOrDefault("LoadBalancerName")
  valid_614010 = validateParameter(valid_614010, JString, required = true,
                                 default = nil)
  if valid_614010 != nil:
    section.add "LoadBalancerName", valid_614010
  var valid_614011 = query.getOrDefault("Action")
  valid_614011 = validateParameter(valid_614011, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_614011 != nil:
    section.add "Action", valid_614011
  var valid_614012 = query.getOrDefault("Version")
  valid_614012 = validateParameter(valid_614012, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614012 != nil:
    section.add "Version", valid_614012
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
  var valid_614013 = header.getOrDefault("X-Amz-Signature")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Signature", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-Content-Sha256", valid_614014
  var valid_614015 = header.getOrDefault("X-Amz-Date")
  valid_614015 = validateParameter(valid_614015, JString, required = false,
                                 default = nil)
  if valid_614015 != nil:
    section.add "X-Amz-Date", valid_614015
  var valid_614016 = header.getOrDefault("X-Amz-Credential")
  valid_614016 = validateParameter(valid_614016, JString, required = false,
                                 default = nil)
  if valid_614016 != nil:
    section.add "X-Amz-Credential", valid_614016
  var valid_614017 = header.getOrDefault("X-Amz-Security-Token")
  valid_614017 = validateParameter(valid_614017, JString, required = false,
                                 default = nil)
  if valid_614017 != nil:
    section.add "X-Amz-Security-Token", valid_614017
  var valid_614018 = header.getOrDefault("X-Amz-Algorithm")
  valid_614018 = validateParameter(valid_614018, JString, required = false,
                                 default = nil)
  if valid_614018 != nil:
    section.add "X-Amz-Algorithm", valid_614018
  var valid_614019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "X-Amz-SignedHeaders", valid_614019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614020: Call_GetDisableAvailabilityZonesForLoadBalancer_614006;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_614020.validator(path, query, header, formData, body)
  let scheme = call_614020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614020.url(scheme.get, call_614020.host, call_614020.base,
                         call_614020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614020, url, valid)

proc call*(call_614021: Call_GetDisableAvailabilityZonesForLoadBalancer_614006;
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
  var query_614022 = newJObject()
  if AvailabilityZones != nil:
    query_614022.add "AvailabilityZones", AvailabilityZones
  add(query_614022, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614022, "Action", newJString(Action))
  add(query_614022, "Version", newJString(Version))
  result = call_614021.call(nil, query_614022, nil, nil, nil)

var getDisableAvailabilityZonesForLoadBalancer* = Call_GetDisableAvailabilityZonesForLoadBalancer_614006(
    name: "getDisableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_GetDisableAvailabilityZonesForLoadBalancer_614007,
    base: "/", url: url_GetDisableAvailabilityZonesForLoadBalancer_614008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAvailabilityZonesForLoadBalancer_614058 = ref object of OpenApiRestCall_612658
proc url_PostEnableAvailabilityZonesForLoadBalancer_614060(protocol: Scheme;
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

proc validate_PostEnableAvailabilityZonesForLoadBalancer_614059(path: JsonNode;
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
  var valid_614061 = query.getOrDefault("Action")
  valid_614061 = validateParameter(valid_614061, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_614061 != nil:
    section.add "Action", valid_614061
  var valid_614062 = query.getOrDefault("Version")
  valid_614062 = validateParameter(valid_614062, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614062 != nil:
    section.add "Version", valid_614062
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
  var valid_614063 = header.getOrDefault("X-Amz-Signature")
  valid_614063 = validateParameter(valid_614063, JString, required = false,
                                 default = nil)
  if valid_614063 != nil:
    section.add "X-Amz-Signature", valid_614063
  var valid_614064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614064 = validateParameter(valid_614064, JString, required = false,
                                 default = nil)
  if valid_614064 != nil:
    section.add "X-Amz-Content-Sha256", valid_614064
  var valid_614065 = header.getOrDefault("X-Amz-Date")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "X-Amz-Date", valid_614065
  var valid_614066 = header.getOrDefault("X-Amz-Credential")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Credential", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-Security-Token")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Security-Token", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Algorithm")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Algorithm", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-SignedHeaders", valid_614069
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_614070 = formData.getOrDefault("AvailabilityZones")
  valid_614070 = validateParameter(valid_614070, JArray, required = true, default = nil)
  if valid_614070 != nil:
    section.add "AvailabilityZones", valid_614070
  var valid_614071 = formData.getOrDefault("LoadBalancerName")
  valid_614071 = validateParameter(valid_614071, JString, required = true,
                                 default = nil)
  if valid_614071 != nil:
    section.add "LoadBalancerName", valid_614071
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614072: Call_PostEnableAvailabilityZonesForLoadBalancer_614058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_614072.validator(path, query, header, formData, body)
  let scheme = call_614072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614072.url(scheme.get, call_614072.host, call_614072.base,
                         call_614072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614072, url, valid)

proc call*(call_614073: Call_PostEnableAvailabilityZonesForLoadBalancer_614058;
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
  var query_614074 = newJObject()
  var formData_614075 = newJObject()
  if AvailabilityZones != nil:
    formData_614075.add "AvailabilityZones", AvailabilityZones
  add(formData_614075, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614074, "Action", newJString(Action))
  add(query_614074, "Version", newJString(Version))
  result = call_614073.call(nil, query_614074, nil, formData_614075, nil)

var postEnableAvailabilityZonesForLoadBalancer* = Call_PostEnableAvailabilityZonesForLoadBalancer_614058(
    name: "postEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_PostEnableAvailabilityZonesForLoadBalancer_614059,
    base: "/", url: url_PostEnableAvailabilityZonesForLoadBalancer_614060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAvailabilityZonesForLoadBalancer_614041 = ref object of OpenApiRestCall_612658
proc url_GetEnableAvailabilityZonesForLoadBalancer_614043(protocol: Scheme;
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

proc validate_GetEnableAvailabilityZonesForLoadBalancer_614042(path: JsonNode;
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
  var valid_614044 = query.getOrDefault("AvailabilityZones")
  valid_614044 = validateParameter(valid_614044, JArray, required = true, default = nil)
  if valid_614044 != nil:
    section.add "AvailabilityZones", valid_614044
  var valid_614045 = query.getOrDefault("LoadBalancerName")
  valid_614045 = validateParameter(valid_614045, JString, required = true,
                                 default = nil)
  if valid_614045 != nil:
    section.add "LoadBalancerName", valid_614045
  var valid_614046 = query.getOrDefault("Action")
  valid_614046 = validateParameter(valid_614046, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_614046 != nil:
    section.add "Action", valid_614046
  var valid_614047 = query.getOrDefault("Version")
  valid_614047 = validateParameter(valid_614047, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614047 != nil:
    section.add "Version", valid_614047
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
  var valid_614048 = header.getOrDefault("X-Amz-Signature")
  valid_614048 = validateParameter(valid_614048, JString, required = false,
                                 default = nil)
  if valid_614048 != nil:
    section.add "X-Amz-Signature", valid_614048
  var valid_614049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "X-Amz-Content-Sha256", valid_614049
  var valid_614050 = header.getOrDefault("X-Amz-Date")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "X-Amz-Date", valid_614050
  var valid_614051 = header.getOrDefault("X-Amz-Credential")
  valid_614051 = validateParameter(valid_614051, JString, required = false,
                                 default = nil)
  if valid_614051 != nil:
    section.add "X-Amz-Credential", valid_614051
  var valid_614052 = header.getOrDefault("X-Amz-Security-Token")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = nil)
  if valid_614052 != nil:
    section.add "X-Amz-Security-Token", valid_614052
  var valid_614053 = header.getOrDefault("X-Amz-Algorithm")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "X-Amz-Algorithm", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-SignedHeaders", valid_614054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614055: Call_GetEnableAvailabilityZonesForLoadBalancer_614041;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_614055.validator(path, query, header, formData, body)
  let scheme = call_614055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614055.url(scheme.get, call_614055.host, call_614055.base,
                         call_614055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614055, url, valid)

proc call*(call_614056: Call_GetEnableAvailabilityZonesForLoadBalancer_614041;
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
  var query_614057 = newJObject()
  if AvailabilityZones != nil:
    query_614057.add "AvailabilityZones", AvailabilityZones
  add(query_614057, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614057, "Action", newJString(Action))
  add(query_614057, "Version", newJString(Version))
  result = call_614056.call(nil, query_614057, nil, nil, nil)

var getEnableAvailabilityZonesForLoadBalancer* = Call_GetEnableAvailabilityZonesForLoadBalancer_614041(
    name: "getEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_GetEnableAvailabilityZonesForLoadBalancer_614042,
    base: "/", url: url_GetEnableAvailabilityZonesForLoadBalancer_614043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_614097 = ref object of OpenApiRestCall_612658
proc url_PostModifyLoadBalancerAttributes_614099(protocol: Scheme; host: string;
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

proc validate_PostModifyLoadBalancerAttributes_614098(path: JsonNode;
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
  var valid_614100 = query.getOrDefault("Action")
  valid_614100 = validateParameter(valid_614100, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_614100 != nil:
    section.add "Action", valid_614100
  var valid_614101 = query.getOrDefault("Version")
  valid_614101 = validateParameter(valid_614101, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614101 != nil:
    section.add "Version", valid_614101
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
  var valid_614102 = header.getOrDefault("X-Amz-Signature")
  valid_614102 = validateParameter(valid_614102, JString, required = false,
                                 default = nil)
  if valid_614102 != nil:
    section.add "X-Amz-Signature", valid_614102
  var valid_614103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-Content-Sha256", valid_614103
  var valid_614104 = header.getOrDefault("X-Amz-Date")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-Date", valid_614104
  var valid_614105 = header.getOrDefault("X-Amz-Credential")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-Credential", valid_614105
  var valid_614106 = header.getOrDefault("X-Amz-Security-Token")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-Security-Token", valid_614106
  var valid_614107 = header.getOrDefault("X-Amz-Algorithm")
  valid_614107 = validateParameter(valid_614107, JString, required = false,
                                 default = nil)
  if valid_614107 != nil:
    section.add "X-Amz-Algorithm", valid_614107
  var valid_614108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "X-Amz-SignedHeaders", valid_614108
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
  var valid_614109 = formData.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_614109
  var valid_614110 = formData.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_614110 = validateParameter(valid_614110, JArray, required = false,
                                 default = nil)
  if valid_614110 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_614110
  var valid_614111 = formData.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_614111 = validateParameter(valid_614111, JString, required = false,
                                 default = nil)
  if valid_614111 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_614111
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_614112 = formData.getOrDefault("LoadBalancerName")
  valid_614112 = validateParameter(valid_614112, JString, required = true,
                                 default = nil)
  if valid_614112 != nil:
    section.add "LoadBalancerName", valid_614112
  var valid_614113 = formData.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_614113 = validateParameter(valid_614113, JString, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_614113
  var valid_614114 = formData.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_614114
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614115: Call_PostModifyLoadBalancerAttributes_614097;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_614115.validator(path, query, header, formData, body)
  let scheme = call_614115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614115.url(scheme.get, call_614115.host, call_614115.base,
                         call_614115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614115, url, valid)

proc call*(call_614116: Call_PostModifyLoadBalancerAttributes_614097;
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
  var query_614117 = newJObject()
  var formData_614118 = newJObject()
  add(formData_614118, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    formData_614118.add "LoadBalancerAttributes.AdditionalAttributes",
                       LoadBalancerAttributesAdditionalAttributes
  add(formData_614118, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(formData_614118, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614117, "Action", newJString(Action))
  add(formData_614118, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_614117, "Version", newJString(Version))
  add(formData_614118, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  result = call_614116.call(nil, query_614117, nil, formData_614118, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_614097(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_614098, base: "/",
    url: url_PostModifyLoadBalancerAttributes_614099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_614076 = ref object of OpenApiRestCall_612658
proc url_GetModifyLoadBalancerAttributes_614078(protocol: Scheme; host: string;
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

proc validate_GetModifyLoadBalancerAttributes_614077(path: JsonNode;
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
  var valid_614079 = query.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_614079
  var valid_614080 = query.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_614080
  var valid_614081 = query.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_614081 = validateParameter(valid_614081, JString, required = false,
                                 default = nil)
  if valid_614081 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_614081
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_614082 = query.getOrDefault("LoadBalancerName")
  valid_614082 = validateParameter(valid_614082, JString, required = true,
                                 default = nil)
  if valid_614082 != nil:
    section.add "LoadBalancerName", valid_614082
  var valid_614083 = query.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_614083 = validateParameter(valid_614083, JString, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_614083
  var valid_614084 = query.getOrDefault("Action")
  valid_614084 = validateParameter(valid_614084, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_614084 != nil:
    section.add "Action", valid_614084
  var valid_614085 = query.getOrDefault("Version")
  valid_614085 = validateParameter(valid_614085, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614085 != nil:
    section.add "Version", valid_614085
  var valid_614086 = query.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_614086 = validateParameter(valid_614086, JArray, required = false,
                                 default = nil)
  if valid_614086 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_614086
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
  var valid_614087 = header.getOrDefault("X-Amz-Signature")
  valid_614087 = validateParameter(valid_614087, JString, required = false,
                                 default = nil)
  if valid_614087 != nil:
    section.add "X-Amz-Signature", valid_614087
  var valid_614088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614088 = validateParameter(valid_614088, JString, required = false,
                                 default = nil)
  if valid_614088 != nil:
    section.add "X-Amz-Content-Sha256", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-Date")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-Date", valid_614089
  var valid_614090 = header.getOrDefault("X-Amz-Credential")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Credential", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-Security-Token")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Security-Token", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-Algorithm")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-Algorithm", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-SignedHeaders", valid_614093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614094: Call_GetModifyLoadBalancerAttributes_614076;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_614094.validator(path, query, header, formData, body)
  let scheme = call_614094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614094.url(scheme.get, call_614094.host, call_614094.base,
                         call_614094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614094, url, valid)

proc call*(call_614095: Call_GetModifyLoadBalancerAttributes_614076;
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
  var query_614096 = newJObject()
  add(query_614096, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_614096, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_614096, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_614096, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614096, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  add(query_614096, "Action", newJString(Action))
  add(query_614096, "Version", newJString(Version))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    query_614096.add "LoadBalancerAttributes.AdditionalAttributes",
                    LoadBalancerAttributesAdditionalAttributes
  result = call_614095.call(nil, query_614096, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_614076(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_614077, base: "/",
    url: url_GetModifyLoadBalancerAttributes_614078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterInstancesWithLoadBalancer_614136 = ref object of OpenApiRestCall_612658
proc url_PostRegisterInstancesWithLoadBalancer_614138(protocol: Scheme;
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

proc validate_PostRegisterInstancesWithLoadBalancer_614137(path: JsonNode;
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
  var valid_614139 = query.getOrDefault("Action")
  valid_614139 = validateParameter(valid_614139, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_614139 != nil:
    section.add "Action", valid_614139
  var valid_614140 = query.getOrDefault("Version")
  valid_614140 = validateParameter(valid_614140, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614140 != nil:
    section.add "Version", valid_614140
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
  var valid_614141 = header.getOrDefault("X-Amz-Signature")
  valid_614141 = validateParameter(valid_614141, JString, required = false,
                                 default = nil)
  if valid_614141 != nil:
    section.add "X-Amz-Signature", valid_614141
  var valid_614142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614142 = validateParameter(valid_614142, JString, required = false,
                                 default = nil)
  if valid_614142 != nil:
    section.add "X-Amz-Content-Sha256", valid_614142
  var valid_614143 = header.getOrDefault("X-Amz-Date")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-Date", valid_614143
  var valid_614144 = header.getOrDefault("X-Amz-Credential")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "X-Amz-Credential", valid_614144
  var valid_614145 = header.getOrDefault("X-Amz-Security-Token")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-Security-Token", valid_614145
  var valid_614146 = header.getOrDefault("X-Amz-Algorithm")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-Algorithm", valid_614146
  var valid_614147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-SignedHeaders", valid_614147
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_614148 = formData.getOrDefault("Instances")
  valid_614148 = validateParameter(valid_614148, JArray, required = true, default = nil)
  if valid_614148 != nil:
    section.add "Instances", valid_614148
  var valid_614149 = formData.getOrDefault("LoadBalancerName")
  valid_614149 = validateParameter(valid_614149, JString, required = true,
                                 default = nil)
  if valid_614149 != nil:
    section.add "LoadBalancerName", valid_614149
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614150: Call_PostRegisterInstancesWithLoadBalancer_614136;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_614150.validator(path, query, header, formData, body)
  let scheme = call_614150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614150.url(scheme.get, call_614150.host, call_614150.base,
                         call_614150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614150, url, valid)

proc call*(call_614151: Call_PostRegisterInstancesWithLoadBalancer_614136;
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
  var query_614152 = newJObject()
  var formData_614153 = newJObject()
  if Instances != nil:
    formData_614153.add "Instances", Instances
  add(formData_614153, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614152, "Action", newJString(Action))
  add(query_614152, "Version", newJString(Version))
  result = call_614151.call(nil, query_614152, nil, formData_614153, nil)

var postRegisterInstancesWithLoadBalancer* = Call_PostRegisterInstancesWithLoadBalancer_614136(
    name: "postRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_PostRegisterInstancesWithLoadBalancer_614137, base: "/",
    url: url_PostRegisterInstancesWithLoadBalancer_614138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterInstancesWithLoadBalancer_614119 = ref object of OpenApiRestCall_612658
proc url_GetRegisterInstancesWithLoadBalancer_614121(protocol: Scheme;
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

proc validate_GetRegisterInstancesWithLoadBalancer_614120(path: JsonNode;
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
  var valid_614122 = query.getOrDefault("LoadBalancerName")
  valid_614122 = validateParameter(valid_614122, JString, required = true,
                                 default = nil)
  if valid_614122 != nil:
    section.add "LoadBalancerName", valid_614122
  var valid_614123 = query.getOrDefault("Action")
  valid_614123 = validateParameter(valid_614123, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_614123 != nil:
    section.add "Action", valid_614123
  var valid_614124 = query.getOrDefault("Instances")
  valid_614124 = validateParameter(valid_614124, JArray, required = true, default = nil)
  if valid_614124 != nil:
    section.add "Instances", valid_614124
  var valid_614125 = query.getOrDefault("Version")
  valid_614125 = validateParameter(valid_614125, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614125 != nil:
    section.add "Version", valid_614125
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
  var valid_614126 = header.getOrDefault("X-Amz-Signature")
  valid_614126 = validateParameter(valid_614126, JString, required = false,
                                 default = nil)
  if valid_614126 != nil:
    section.add "X-Amz-Signature", valid_614126
  var valid_614127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614127 = validateParameter(valid_614127, JString, required = false,
                                 default = nil)
  if valid_614127 != nil:
    section.add "X-Amz-Content-Sha256", valid_614127
  var valid_614128 = header.getOrDefault("X-Amz-Date")
  valid_614128 = validateParameter(valid_614128, JString, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "X-Amz-Date", valid_614128
  var valid_614129 = header.getOrDefault("X-Amz-Credential")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "X-Amz-Credential", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-Security-Token")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-Security-Token", valid_614130
  var valid_614131 = header.getOrDefault("X-Amz-Algorithm")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "X-Amz-Algorithm", valid_614131
  var valid_614132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-SignedHeaders", valid_614132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614133: Call_GetRegisterInstancesWithLoadBalancer_614119;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_614133.validator(path, query, header, formData, body)
  let scheme = call_614133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614133.url(scheme.get, call_614133.host, call_614133.base,
                         call_614133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614133, url, valid)

proc call*(call_614134: Call_GetRegisterInstancesWithLoadBalancer_614119;
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
  var query_614135 = newJObject()
  add(query_614135, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614135, "Action", newJString(Action))
  if Instances != nil:
    query_614135.add "Instances", Instances
  add(query_614135, "Version", newJString(Version))
  result = call_614134.call(nil, query_614135, nil, nil, nil)

var getRegisterInstancesWithLoadBalancer* = Call_GetRegisterInstancesWithLoadBalancer_614119(
    name: "getRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_GetRegisterInstancesWithLoadBalancer_614120, base: "/",
    url: url_GetRegisterInstancesWithLoadBalancer_614121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_614171 = ref object of OpenApiRestCall_612658
proc url_PostRemoveTags_614173(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemoveTags_614172(path: JsonNode; query: JsonNode;
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
  var valid_614174 = query.getOrDefault("Action")
  valid_614174 = validateParameter(valid_614174, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_614174 != nil:
    section.add "Action", valid_614174
  var valid_614175 = query.getOrDefault("Version")
  valid_614175 = validateParameter(valid_614175, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614175 != nil:
    section.add "Version", valid_614175
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
  var valid_614176 = header.getOrDefault("X-Amz-Signature")
  valid_614176 = validateParameter(valid_614176, JString, required = false,
                                 default = nil)
  if valid_614176 != nil:
    section.add "X-Amz-Signature", valid_614176
  var valid_614177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614177 = validateParameter(valid_614177, JString, required = false,
                                 default = nil)
  if valid_614177 != nil:
    section.add "X-Amz-Content-Sha256", valid_614177
  var valid_614178 = header.getOrDefault("X-Amz-Date")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "X-Amz-Date", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Credential")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Credential", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Security-Token")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Security-Token", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Algorithm")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Algorithm", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-SignedHeaders", valid_614182
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_614183 = formData.getOrDefault("LoadBalancerNames")
  valid_614183 = validateParameter(valid_614183, JArray, required = true, default = nil)
  if valid_614183 != nil:
    section.add "LoadBalancerNames", valid_614183
  var valid_614184 = formData.getOrDefault("Tags")
  valid_614184 = validateParameter(valid_614184, JArray, required = true, default = nil)
  if valid_614184 != nil:
    section.add "Tags", valid_614184
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614185: Call_PostRemoveTags_614171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_614185.validator(path, query, header, formData, body)
  let scheme = call_614185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614185.url(scheme.get, call_614185.host, call_614185.base,
                         call_614185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614185, url, valid)

proc call*(call_614186: Call_PostRemoveTags_614171; LoadBalancerNames: JsonNode;
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
  var query_614187 = newJObject()
  var formData_614188 = newJObject()
  if LoadBalancerNames != nil:
    formData_614188.add "LoadBalancerNames", LoadBalancerNames
  add(query_614187, "Action", newJString(Action))
  if Tags != nil:
    formData_614188.add "Tags", Tags
  add(query_614187, "Version", newJString(Version))
  result = call_614186.call(nil, query_614187, nil, formData_614188, nil)

var postRemoveTags* = Call_PostRemoveTags_614171(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_614172,
    base: "/", url: url_PostRemoveTags_614173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_614154 = ref object of OpenApiRestCall_612658
proc url_GetRemoveTags_614156(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemoveTags_614155(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614157 = query.getOrDefault("Tags")
  valid_614157 = validateParameter(valid_614157, JArray, required = true, default = nil)
  if valid_614157 != nil:
    section.add "Tags", valid_614157
  var valid_614158 = query.getOrDefault("Action")
  valid_614158 = validateParameter(valid_614158, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_614158 != nil:
    section.add "Action", valid_614158
  var valid_614159 = query.getOrDefault("Version")
  valid_614159 = validateParameter(valid_614159, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614159 != nil:
    section.add "Version", valid_614159
  var valid_614160 = query.getOrDefault("LoadBalancerNames")
  valid_614160 = validateParameter(valid_614160, JArray, required = true, default = nil)
  if valid_614160 != nil:
    section.add "LoadBalancerNames", valid_614160
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
  var valid_614161 = header.getOrDefault("X-Amz-Signature")
  valid_614161 = validateParameter(valid_614161, JString, required = false,
                                 default = nil)
  if valid_614161 != nil:
    section.add "X-Amz-Signature", valid_614161
  var valid_614162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614162 = validateParameter(valid_614162, JString, required = false,
                                 default = nil)
  if valid_614162 != nil:
    section.add "X-Amz-Content-Sha256", valid_614162
  var valid_614163 = header.getOrDefault("X-Amz-Date")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "X-Amz-Date", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Credential")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Credential", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Security-Token")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Security-Token", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-Algorithm")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-Algorithm", valid_614166
  var valid_614167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "X-Amz-SignedHeaders", valid_614167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614168: Call_GetRemoveTags_614154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_614168.validator(path, query, header, formData, body)
  let scheme = call_614168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614168.url(scheme.get, call_614168.host, call_614168.base,
                         call_614168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614168, url, valid)

proc call*(call_614169: Call_GetRemoveTags_614154; Tags: JsonNode;
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
  var query_614170 = newJObject()
  if Tags != nil:
    query_614170.add "Tags", Tags
  add(query_614170, "Action", newJString(Action))
  add(query_614170, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_614170.add "LoadBalancerNames", LoadBalancerNames
  result = call_614169.call(nil, query_614170, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_614154(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_614155,
    base: "/", url: url_GetRemoveTags_614156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerListenerSSLCertificate_614207 = ref object of OpenApiRestCall_612658
proc url_PostSetLoadBalancerListenerSSLCertificate_614209(protocol: Scheme;
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

proc validate_PostSetLoadBalancerListenerSSLCertificate_614208(path: JsonNode;
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
  var valid_614210 = query.getOrDefault("Action")
  valid_614210 = validateParameter(valid_614210, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_614210 != nil:
    section.add "Action", valid_614210
  var valid_614211 = query.getOrDefault("Version")
  valid_614211 = validateParameter(valid_614211, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614211 != nil:
    section.add "Version", valid_614211
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
  var valid_614212 = header.getOrDefault("X-Amz-Signature")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "X-Amz-Signature", valid_614212
  var valid_614213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614213 = validateParameter(valid_614213, JString, required = false,
                                 default = nil)
  if valid_614213 != nil:
    section.add "X-Amz-Content-Sha256", valid_614213
  var valid_614214 = header.getOrDefault("X-Amz-Date")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "X-Amz-Date", valid_614214
  var valid_614215 = header.getOrDefault("X-Amz-Credential")
  valid_614215 = validateParameter(valid_614215, JString, required = false,
                                 default = nil)
  if valid_614215 != nil:
    section.add "X-Amz-Credential", valid_614215
  var valid_614216 = header.getOrDefault("X-Amz-Security-Token")
  valid_614216 = validateParameter(valid_614216, JString, required = false,
                                 default = nil)
  if valid_614216 != nil:
    section.add "X-Amz-Security-Token", valid_614216
  var valid_614217 = header.getOrDefault("X-Amz-Algorithm")
  valid_614217 = validateParameter(valid_614217, JString, required = false,
                                 default = nil)
  if valid_614217 != nil:
    section.add "X-Amz-Algorithm", valid_614217
  var valid_614218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614218 = validateParameter(valid_614218, JString, required = false,
                                 default = nil)
  if valid_614218 != nil:
    section.add "X-Amz-SignedHeaders", valid_614218
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
  var valid_614219 = formData.getOrDefault("LoadBalancerName")
  valid_614219 = validateParameter(valid_614219, JString, required = true,
                                 default = nil)
  if valid_614219 != nil:
    section.add "LoadBalancerName", valid_614219
  var valid_614220 = formData.getOrDefault("SSLCertificateId")
  valid_614220 = validateParameter(valid_614220, JString, required = true,
                                 default = nil)
  if valid_614220 != nil:
    section.add "SSLCertificateId", valid_614220
  var valid_614221 = formData.getOrDefault("LoadBalancerPort")
  valid_614221 = validateParameter(valid_614221, JInt, required = true, default = nil)
  if valid_614221 != nil:
    section.add "LoadBalancerPort", valid_614221
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614222: Call_PostSetLoadBalancerListenerSSLCertificate_614207;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_614222.validator(path, query, header, formData, body)
  let scheme = call_614222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614222.url(scheme.get, call_614222.host, call_614222.base,
                         call_614222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614222, url, valid)

proc call*(call_614223: Call_PostSetLoadBalancerListenerSSLCertificate_614207;
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
  var query_614224 = newJObject()
  var formData_614225 = newJObject()
  add(formData_614225, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614224, "Action", newJString(Action))
  add(formData_614225, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_614224, "Version", newJString(Version))
  add(formData_614225, "LoadBalancerPort", newJInt(LoadBalancerPort))
  result = call_614223.call(nil, query_614224, nil, formData_614225, nil)

var postSetLoadBalancerListenerSSLCertificate* = Call_PostSetLoadBalancerListenerSSLCertificate_614207(
    name: "postSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_PostSetLoadBalancerListenerSSLCertificate_614208,
    base: "/", url: url_PostSetLoadBalancerListenerSSLCertificate_614209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerListenerSSLCertificate_614189 = ref object of OpenApiRestCall_612658
proc url_GetSetLoadBalancerListenerSSLCertificate_614191(protocol: Scheme;
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

proc validate_GetSetLoadBalancerListenerSSLCertificate_614190(path: JsonNode;
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
  var valid_614192 = query.getOrDefault("LoadBalancerPort")
  valid_614192 = validateParameter(valid_614192, JInt, required = true, default = nil)
  if valid_614192 != nil:
    section.add "LoadBalancerPort", valid_614192
  var valid_614193 = query.getOrDefault("LoadBalancerName")
  valid_614193 = validateParameter(valid_614193, JString, required = true,
                                 default = nil)
  if valid_614193 != nil:
    section.add "LoadBalancerName", valid_614193
  var valid_614194 = query.getOrDefault("Action")
  valid_614194 = validateParameter(valid_614194, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_614194 != nil:
    section.add "Action", valid_614194
  var valid_614195 = query.getOrDefault("Version")
  valid_614195 = validateParameter(valid_614195, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614195 != nil:
    section.add "Version", valid_614195
  var valid_614196 = query.getOrDefault("SSLCertificateId")
  valid_614196 = validateParameter(valid_614196, JString, required = true,
                                 default = nil)
  if valid_614196 != nil:
    section.add "SSLCertificateId", valid_614196
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
  var valid_614197 = header.getOrDefault("X-Amz-Signature")
  valid_614197 = validateParameter(valid_614197, JString, required = false,
                                 default = nil)
  if valid_614197 != nil:
    section.add "X-Amz-Signature", valid_614197
  var valid_614198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614198 = validateParameter(valid_614198, JString, required = false,
                                 default = nil)
  if valid_614198 != nil:
    section.add "X-Amz-Content-Sha256", valid_614198
  var valid_614199 = header.getOrDefault("X-Amz-Date")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-Date", valid_614199
  var valid_614200 = header.getOrDefault("X-Amz-Credential")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-Credential", valid_614200
  var valid_614201 = header.getOrDefault("X-Amz-Security-Token")
  valid_614201 = validateParameter(valid_614201, JString, required = false,
                                 default = nil)
  if valid_614201 != nil:
    section.add "X-Amz-Security-Token", valid_614201
  var valid_614202 = header.getOrDefault("X-Amz-Algorithm")
  valid_614202 = validateParameter(valid_614202, JString, required = false,
                                 default = nil)
  if valid_614202 != nil:
    section.add "X-Amz-Algorithm", valid_614202
  var valid_614203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614203 = validateParameter(valid_614203, JString, required = false,
                                 default = nil)
  if valid_614203 != nil:
    section.add "X-Amz-SignedHeaders", valid_614203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614204: Call_GetSetLoadBalancerListenerSSLCertificate_614189;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_614204.validator(path, query, header, formData, body)
  let scheme = call_614204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614204.url(scheme.get, call_614204.host, call_614204.base,
                         call_614204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614204, url, valid)

proc call*(call_614205: Call_GetSetLoadBalancerListenerSSLCertificate_614189;
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
  var query_614206 = newJObject()
  add(query_614206, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_614206, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614206, "Action", newJString(Action))
  add(query_614206, "Version", newJString(Version))
  add(query_614206, "SSLCertificateId", newJString(SSLCertificateId))
  result = call_614205.call(nil, query_614206, nil, nil, nil)

var getSetLoadBalancerListenerSSLCertificate* = Call_GetSetLoadBalancerListenerSSLCertificate_614189(
    name: "getSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_GetSetLoadBalancerListenerSSLCertificate_614190,
    base: "/", url: url_GetSetLoadBalancerListenerSSLCertificate_614191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesForBackendServer_614244 = ref object of OpenApiRestCall_612658
proc url_PostSetLoadBalancerPoliciesForBackendServer_614246(protocol: Scheme;
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

proc validate_PostSetLoadBalancerPoliciesForBackendServer_614245(path: JsonNode;
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
  var valid_614247 = query.getOrDefault("Action")
  valid_614247 = validateParameter(valid_614247, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_614247 != nil:
    section.add "Action", valid_614247
  var valid_614248 = query.getOrDefault("Version")
  valid_614248 = validateParameter(valid_614248, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614248 != nil:
    section.add "Version", valid_614248
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
  var valid_614249 = header.getOrDefault("X-Amz-Signature")
  valid_614249 = validateParameter(valid_614249, JString, required = false,
                                 default = nil)
  if valid_614249 != nil:
    section.add "X-Amz-Signature", valid_614249
  var valid_614250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614250 = validateParameter(valid_614250, JString, required = false,
                                 default = nil)
  if valid_614250 != nil:
    section.add "X-Amz-Content-Sha256", valid_614250
  var valid_614251 = header.getOrDefault("X-Amz-Date")
  valid_614251 = validateParameter(valid_614251, JString, required = false,
                                 default = nil)
  if valid_614251 != nil:
    section.add "X-Amz-Date", valid_614251
  var valid_614252 = header.getOrDefault("X-Amz-Credential")
  valid_614252 = validateParameter(valid_614252, JString, required = false,
                                 default = nil)
  if valid_614252 != nil:
    section.add "X-Amz-Credential", valid_614252
  var valid_614253 = header.getOrDefault("X-Amz-Security-Token")
  valid_614253 = validateParameter(valid_614253, JString, required = false,
                                 default = nil)
  if valid_614253 != nil:
    section.add "X-Amz-Security-Token", valid_614253
  var valid_614254 = header.getOrDefault("X-Amz-Algorithm")
  valid_614254 = validateParameter(valid_614254, JString, required = false,
                                 default = nil)
  if valid_614254 != nil:
    section.add "X-Amz-Algorithm", valid_614254
  var valid_614255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614255 = validateParameter(valid_614255, JString, required = false,
                                 default = nil)
  if valid_614255 != nil:
    section.add "X-Amz-SignedHeaders", valid_614255
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
  var valid_614256 = formData.getOrDefault("PolicyNames")
  valid_614256 = validateParameter(valid_614256, JArray, required = true, default = nil)
  if valid_614256 != nil:
    section.add "PolicyNames", valid_614256
  var valid_614257 = formData.getOrDefault("LoadBalancerName")
  valid_614257 = validateParameter(valid_614257, JString, required = true,
                                 default = nil)
  if valid_614257 != nil:
    section.add "LoadBalancerName", valid_614257
  var valid_614258 = formData.getOrDefault("InstancePort")
  valid_614258 = validateParameter(valid_614258, JInt, required = true, default = nil)
  if valid_614258 != nil:
    section.add "InstancePort", valid_614258
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614259: Call_PostSetLoadBalancerPoliciesForBackendServer_614244;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_614259.validator(path, query, header, formData, body)
  let scheme = call_614259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614259.url(scheme.get, call_614259.host, call_614259.base,
                         call_614259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614259, url, valid)

proc call*(call_614260: Call_PostSetLoadBalancerPoliciesForBackendServer_614244;
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
  var query_614261 = newJObject()
  var formData_614262 = newJObject()
  if PolicyNames != nil:
    formData_614262.add "PolicyNames", PolicyNames
  add(formData_614262, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614261, "Action", newJString(Action))
  add(formData_614262, "InstancePort", newJInt(InstancePort))
  add(query_614261, "Version", newJString(Version))
  result = call_614260.call(nil, query_614261, nil, formData_614262, nil)

var postSetLoadBalancerPoliciesForBackendServer* = Call_PostSetLoadBalancerPoliciesForBackendServer_614244(
    name: "postSetLoadBalancerPoliciesForBackendServer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_PostSetLoadBalancerPoliciesForBackendServer_614245,
    base: "/", url: url_PostSetLoadBalancerPoliciesForBackendServer_614246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesForBackendServer_614226 = ref object of OpenApiRestCall_612658
proc url_GetSetLoadBalancerPoliciesForBackendServer_614228(protocol: Scheme;
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

proc validate_GetSetLoadBalancerPoliciesForBackendServer_614227(path: JsonNode;
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
  var valid_614229 = query.getOrDefault("InstancePort")
  valid_614229 = validateParameter(valid_614229, JInt, required = true, default = nil)
  if valid_614229 != nil:
    section.add "InstancePort", valid_614229
  var valid_614230 = query.getOrDefault("LoadBalancerName")
  valid_614230 = validateParameter(valid_614230, JString, required = true,
                                 default = nil)
  if valid_614230 != nil:
    section.add "LoadBalancerName", valid_614230
  var valid_614231 = query.getOrDefault("Action")
  valid_614231 = validateParameter(valid_614231, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_614231 != nil:
    section.add "Action", valid_614231
  var valid_614232 = query.getOrDefault("Version")
  valid_614232 = validateParameter(valid_614232, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614232 != nil:
    section.add "Version", valid_614232
  var valid_614233 = query.getOrDefault("PolicyNames")
  valid_614233 = validateParameter(valid_614233, JArray, required = true, default = nil)
  if valid_614233 != nil:
    section.add "PolicyNames", valid_614233
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
  var valid_614234 = header.getOrDefault("X-Amz-Signature")
  valid_614234 = validateParameter(valid_614234, JString, required = false,
                                 default = nil)
  if valid_614234 != nil:
    section.add "X-Amz-Signature", valid_614234
  var valid_614235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614235 = validateParameter(valid_614235, JString, required = false,
                                 default = nil)
  if valid_614235 != nil:
    section.add "X-Amz-Content-Sha256", valid_614235
  var valid_614236 = header.getOrDefault("X-Amz-Date")
  valid_614236 = validateParameter(valid_614236, JString, required = false,
                                 default = nil)
  if valid_614236 != nil:
    section.add "X-Amz-Date", valid_614236
  var valid_614237 = header.getOrDefault("X-Amz-Credential")
  valid_614237 = validateParameter(valid_614237, JString, required = false,
                                 default = nil)
  if valid_614237 != nil:
    section.add "X-Amz-Credential", valid_614237
  var valid_614238 = header.getOrDefault("X-Amz-Security-Token")
  valid_614238 = validateParameter(valid_614238, JString, required = false,
                                 default = nil)
  if valid_614238 != nil:
    section.add "X-Amz-Security-Token", valid_614238
  var valid_614239 = header.getOrDefault("X-Amz-Algorithm")
  valid_614239 = validateParameter(valid_614239, JString, required = false,
                                 default = nil)
  if valid_614239 != nil:
    section.add "X-Amz-Algorithm", valid_614239
  var valid_614240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614240 = validateParameter(valid_614240, JString, required = false,
                                 default = nil)
  if valid_614240 != nil:
    section.add "X-Amz-SignedHeaders", valid_614240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614241: Call_GetSetLoadBalancerPoliciesForBackendServer_614226;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_614241.validator(path, query, header, formData, body)
  let scheme = call_614241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614241.url(scheme.get, call_614241.host, call_614241.base,
                         call_614241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614241, url, valid)

proc call*(call_614242: Call_GetSetLoadBalancerPoliciesForBackendServer_614226;
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
  var query_614243 = newJObject()
  add(query_614243, "InstancePort", newJInt(InstancePort))
  add(query_614243, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614243, "Action", newJString(Action))
  add(query_614243, "Version", newJString(Version))
  if PolicyNames != nil:
    query_614243.add "PolicyNames", PolicyNames
  result = call_614242.call(nil, query_614243, nil, nil, nil)

var getSetLoadBalancerPoliciesForBackendServer* = Call_GetSetLoadBalancerPoliciesForBackendServer_614226(
    name: "getSetLoadBalancerPoliciesForBackendServer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_GetSetLoadBalancerPoliciesForBackendServer_614227,
    base: "/", url: url_GetSetLoadBalancerPoliciesForBackendServer_614228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesOfListener_614281 = ref object of OpenApiRestCall_612658
proc url_PostSetLoadBalancerPoliciesOfListener_614283(protocol: Scheme;
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

proc validate_PostSetLoadBalancerPoliciesOfListener_614282(path: JsonNode;
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
  var valid_614284 = query.getOrDefault("Action")
  valid_614284 = validateParameter(valid_614284, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_614284 != nil:
    section.add "Action", valid_614284
  var valid_614285 = query.getOrDefault("Version")
  valid_614285 = validateParameter(valid_614285, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614285 != nil:
    section.add "Version", valid_614285
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
  var valid_614286 = header.getOrDefault("X-Amz-Signature")
  valid_614286 = validateParameter(valid_614286, JString, required = false,
                                 default = nil)
  if valid_614286 != nil:
    section.add "X-Amz-Signature", valid_614286
  var valid_614287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614287 = validateParameter(valid_614287, JString, required = false,
                                 default = nil)
  if valid_614287 != nil:
    section.add "X-Amz-Content-Sha256", valid_614287
  var valid_614288 = header.getOrDefault("X-Amz-Date")
  valid_614288 = validateParameter(valid_614288, JString, required = false,
                                 default = nil)
  if valid_614288 != nil:
    section.add "X-Amz-Date", valid_614288
  var valid_614289 = header.getOrDefault("X-Amz-Credential")
  valid_614289 = validateParameter(valid_614289, JString, required = false,
                                 default = nil)
  if valid_614289 != nil:
    section.add "X-Amz-Credential", valid_614289
  var valid_614290 = header.getOrDefault("X-Amz-Security-Token")
  valid_614290 = validateParameter(valid_614290, JString, required = false,
                                 default = nil)
  if valid_614290 != nil:
    section.add "X-Amz-Security-Token", valid_614290
  var valid_614291 = header.getOrDefault("X-Amz-Algorithm")
  valid_614291 = validateParameter(valid_614291, JString, required = false,
                                 default = nil)
  if valid_614291 != nil:
    section.add "X-Amz-Algorithm", valid_614291
  var valid_614292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614292 = validateParameter(valid_614292, JString, required = false,
                                 default = nil)
  if valid_614292 != nil:
    section.add "X-Amz-SignedHeaders", valid_614292
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
  var valid_614293 = formData.getOrDefault("PolicyNames")
  valid_614293 = validateParameter(valid_614293, JArray, required = true, default = nil)
  if valid_614293 != nil:
    section.add "PolicyNames", valid_614293
  var valid_614294 = formData.getOrDefault("LoadBalancerName")
  valid_614294 = validateParameter(valid_614294, JString, required = true,
                                 default = nil)
  if valid_614294 != nil:
    section.add "LoadBalancerName", valid_614294
  var valid_614295 = formData.getOrDefault("LoadBalancerPort")
  valid_614295 = validateParameter(valid_614295, JInt, required = true, default = nil)
  if valid_614295 != nil:
    section.add "LoadBalancerPort", valid_614295
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614296: Call_PostSetLoadBalancerPoliciesOfListener_614281;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_614296.validator(path, query, header, formData, body)
  let scheme = call_614296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614296.url(scheme.get, call_614296.host, call_614296.base,
                         call_614296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614296, url, valid)

proc call*(call_614297: Call_PostSetLoadBalancerPoliciesOfListener_614281;
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
  var query_614298 = newJObject()
  var formData_614299 = newJObject()
  if PolicyNames != nil:
    formData_614299.add "PolicyNames", PolicyNames
  add(formData_614299, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614298, "Action", newJString(Action))
  add(query_614298, "Version", newJString(Version))
  add(formData_614299, "LoadBalancerPort", newJInt(LoadBalancerPort))
  result = call_614297.call(nil, query_614298, nil, formData_614299, nil)

var postSetLoadBalancerPoliciesOfListener* = Call_PostSetLoadBalancerPoliciesOfListener_614281(
    name: "postSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_PostSetLoadBalancerPoliciesOfListener_614282, base: "/",
    url: url_PostSetLoadBalancerPoliciesOfListener_614283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesOfListener_614263 = ref object of OpenApiRestCall_612658
proc url_GetSetLoadBalancerPoliciesOfListener_614265(protocol: Scheme;
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

proc validate_GetSetLoadBalancerPoliciesOfListener_614264(path: JsonNode;
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
  var valid_614266 = query.getOrDefault("LoadBalancerPort")
  valid_614266 = validateParameter(valid_614266, JInt, required = true, default = nil)
  if valid_614266 != nil:
    section.add "LoadBalancerPort", valid_614266
  var valid_614267 = query.getOrDefault("LoadBalancerName")
  valid_614267 = validateParameter(valid_614267, JString, required = true,
                                 default = nil)
  if valid_614267 != nil:
    section.add "LoadBalancerName", valid_614267
  var valid_614268 = query.getOrDefault("Action")
  valid_614268 = validateParameter(valid_614268, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_614268 != nil:
    section.add "Action", valid_614268
  var valid_614269 = query.getOrDefault("Version")
  valid_614269 = validateParameter(valid_614269, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_614269 != nil:
    section.add "Version", valid_614269
  var valid_614270 = query.getOrDefault("PolicyNames")
  valid_614270 = validateParameter(valid_614270, JArray, required = true, default = nil)
  if valid_614270 != nil:
    section.add "PolicyNames", valid_614270
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
  var valid_614271 = header.getOrDefault("X-Amz-Signature")
  valid_614271 = validateParameter(valid_614271, JString, required = false,
                                 default = nil)
  if valid_614271 != nil:
    section.add "X-Amz-Signature", valid_614271
  var valid_614272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614272 = validateParameter(valid_614272, JString, required = false,
                                 default = nil)
  if valid_614272 != nil:
    section.add "X-Amz-Content-Sha256", valid_614272
  var valid_614273 = header.getOrDefault("X-Amz-Date")
  valid_614273 = validateParameter(valid_614273, JString, required = false,
                                 default = nil)
  if valid_614273 != nil:
    section.add "X-Amz-Date", valid_614273
  var valid_614274 = header.getOrDefault("X-Amz-Credential")
  valid_614274 = validateParameter(valid_614274, JString, required = false,
                                 default = nil)
  if valid_614274 != nil:
    section.add "X-Amz-Credential", valid_614274
  var valid_614275 = header.getOrDefault("X-Amz-Security-Token")
  valid_614275 = validateParameter(valid_614275, JString, required = false,
                                 default = nil)
  if valid_614275 != nil:
    section.add "X-Amz-Security-Token", valid_614275
  var valid_614276 = header.getOrDefault("X-Amz-Algorithm")
  valid_614276 = validateParameter(valid_614276, JString, required = false,
                                 default = nil)
  if valid_614276 != nil:
    section.add "X-Amz-Algorithm", valid_614276
  var valid_614277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614277 = validateParameter(valid_614277, JString, required = false,
                                 default = nil)
  if valid_614277 != nil:
    section.add "X-Amz-SignedHeaders", valid_614277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614278: Call_GetSetLoadBalancerPoliciesOfListener_614263;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_614278.validator(path, query, header, formData, body)
  let scheme = call_614278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614278.url(scheme.get, call_614278.host, call_614278.base,
                         call_614278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614278, url, valid)

proc call*(call_614279: Call_GetSetLoadBalancerPoliciesOfListener_614263;
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
  var query_614280 = newJObject()
  add(query_614280, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_614280, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_614280, "Action", newJString(Action))
  add(query_614280, "Version", newJString(Version))
  if PolicyNames != nil:
    query_614280.add "PolicyNames", PolicyNames
  result = call_614279.call(nil, query_614280, nil, nil, nil)

var getSetLoadBalancerPoliciesOfListener* = Call_GetSetLoadBalancerPoliciesOfListener_614263(
    name: "getSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_GetSetLoadBalancerPoliciesOfListener_614264, base: "/",
    url: url_GetSetLoadBalancerPoliciesOfListener_614265,
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
