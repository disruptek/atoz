
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddTags_611268 = ref object of OpenApiRestCall_610658
proc url_PostAddTags_611270(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTags_611269(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611271 = query.getOrDefault("Action")
  valid_611271 = validateParameter(valid_611271, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_611271 != nil:
    section.add "Action", valid_611271
  var valid_611272 = query.getOrDefault("Version")
  valid_611272 = validateParameter(valid_611272, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611272 != nil:
    section.add "Version", valid_611272
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
  var valid_611273 = header.getOrDefault("X-Amz-Signature")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Signature", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Content-Sha256", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Date")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Date", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Credential")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Credential", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Security-Token")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Security-Token", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Algorithm")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Algorithm", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-SignedHeaders", valid_611279
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Tags: JArray (required)
  ##       : The tags.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_611280 = formData.getOrDefault("LoadBalancerNames")
  valid_611280 = validateParameter(valid_611280, JArray, required = true, default = nil)
  if valid_611280 != nil:
    section.add "LoadBalancerNames", valid_611280
  var valid_611281 = formData.getOrDefault("Tags")
  valid_611281 = validateParameter(valid_611281, JArray, required = true, default = nil)
  if valid_611281 != nil:
    section.add "Tags", valid_611281
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611282: Call_PostAddTags_611268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611282.validator(path, query, header, formData, body)
  let scheme = call_611282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611282.url(scheme.get, call_611282.host, call_611282.base,
                         call_611282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611282, url, valid)

proc call*(call_611283: Call_PostAddTags_611268; LoadBalancerNames: JsonNode;
          Tags: JsonNode; Action: string = "AddTags"; Version: string = "2012-06-01"): Recallable =
  ## postAddTags
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   Version: string (required)
  var query_611284 = newJObject()
  var formData_611285 = newJObject()
  if LoadBalancerNames != nil:
    formData_611285.add "LoadBalancerNames", LoadBalancerNames
  add(query_611284, "Action", newJString(Action))
  if Tags != nil:
    formData_611285.add "Tags", Tags
  add(query_611284, "Version", newJString(Version))
  result = call_611283.call(nil, query_611284, nil, formData_611285, nil)

var postAddTags* = Call_PostAddTags_611268(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_611269,
                                        base: "/", url: url_PostAddTags_611270,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_610996 = ref object of OpenApiRestCall_610658
proc url_GetAddTags_610998(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTags_610997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611110 = query.getOrDefault("Tags")
  valid_611110 = validateParameter(valid_611110, JArray, required = true, default = nil)
  if valid_611110 != nil:
    section.add "Tags", valid_611110
  var valid_611124 = query.getOrDefault("Action")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_611124 != nil:
    section.add "Action", valid_611124
  var valid_611125 = query.getOrDefault("Version")
  valid_611125 = validateParameter(valid_611125, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611125 != nil:
    section.add "Version", valid_611125
  var valid_611126 = query.getOrDefault("LoadBalancerNames")
  valid_611126 = validateParameter(valid_611126, JArray, required = true, default = nil)
  if valid_611126 != nil:
    section.add "LoadBalancerNames", valid_611126
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
  var valid_611127 = header.getOrDefault("X-Amz-Signature")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Signature", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Content-Sha256", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Date")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Date", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Credential")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Credential", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-Security-Token")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-Security-Token", valid_611131
  var valid_611132 = header.getOrDefault("X-Amz-Algorithm")
  valid_611132 = validateParameter(valid_611132, JString, required = false,
                                 default = nil)
  if valid_611132 != nil:
    section.add "X-Amz-Algorithm", valid_611132
  var valid_611133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611133 = validateParameter(valid_611133, JString, required = false,
                                 default = nil)
  if valid_611133 != nil:
    section.add "X-Amz-SignedHeaders", valid_611133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611156: Call_GetAddTags_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611156.validator(path, query, header, formData, body)
  let scheme = call_611156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611156.url(scheme.get, call_611156.host, call_611156.base,
                         call_611156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611156, url, valid)

proc call*(call_611227: Call_GetAddTags_610996; Tags: JsonNode;
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
  var query_611228 = newJObject()
  if Tags != nil:
    query_611228.add "Tags", Tags
  add(query_611228, "Action", newJString(Action))
  add(query_611228, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_611228.add "LoadBalancerNames", LoadBalancerNames
  result = call_611227.call(nil, query_611228, nil, nil, nil)

var getAddTags* = Call_GetAddTags_610996(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_610997,
                                      base: "/", url: url_GetAddTags_610998,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplySecurityGroupsToLoadBalancer_611303 = ref object of OpenApiRestCall_610658
proc url_PostApplySecurityGroupsToLoadBalancer_611305(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostApplySecurityGroupsToLoadBalancer_611304(path: JsonNode;
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
  var valid_611306 = query.getOrDefault("Action")
  valid_611306 = validateParameter(valid_611306, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_611306 != nil:
    section.add "Action", valid_611306
  var valid_611307 = query.getOrDefault("Version")
  valid_611307 = validateParameter(valid_611307, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611307 != nil:
    section.add "Version", valid_611307
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
  var valid_611308 = header.getOrDefault("X-Amz-Signature")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Signature", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Content-Sha256", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Date")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Date", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Credential")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Credential", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Security-Token")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Security-Token", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Algorithm")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Algorithm", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-SignedHeaders", valid_611314
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_611315 = formData.getOrDefault("SecurityGroups")
  valid_611315 = validateParameter(valid_611315, JArray, required = true, default = nil)
  if valid_611315 != nil:
    section.add "SecurityGroups", valid_611315
  var valid_611316 = formData.getOrDefault("LoadBalancerName")
  valid_611316 = validateParameter(valid_611316, JString, required = true,
                                 default = nil)
  if valid_611316 != nil:
    section.add "LoadBalancerName", valid_611316
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611317: Call_PostApplySecurityGroupsToLoadBalancer_611303;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611317.validator(path, query, header, formData, body)
  let scheme = call_611317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611317.url(scheme.get, call_611317.host, call_611317.base,
                         call_611317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611317, url, valid)

proc call*(call_611318: Call_PostApplySecurityGroupsToLoadBalancer_611303;
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
  var query_611319 = newJObject()
  var formData_611320 = newJObject()
  if SecurityGroups != nil:
    formData_611320.add "SecurityGroups", SecurityGroups
  add(formData_611320, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611319, "Action", newJString(Action))
  add(query_611319, "Version", newJString(Version))
  result = call_611318.call(nil, query_611319, nil, formData_611320, nil)

var postApplySecurityGroupsToLoadBalancer* = Call_PostApplySecurityGroupsToLoadBalancer_611303(
    name: "postApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_PostApplySecurityGroupsToLoadBalancer_611304, base: "/",
    url: url_PostApplySecurityGroupsToLoadBalancer_611305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplySecurityGroupsToLoadBalancer_611286 = ref object of OpenApiRestCall_610658
proc url_GetApplySecurityGroupsToLoadBalancer_611288(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplySecurityGroupsToLoadBalancer_611287(path: JsonNode;
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
  var valid_611289 = query.getOrDefault("SecurityGroups")
  valid_611289 = validateParameter(valid_611289, JArray, required = true, default = nil)
  if valid_611289 != nil:
    section.add "SecurityGroups", valid_611289
  var valid_611290 = query.getOrDefault("LoadBalancerName")
  valid_611290 = validateParameter(valid_611290, JString, required = true,
                                 default = nil)
  if valid_611290 != nil:
    section.add "LoadBalancerName", valid_611290
  var valid_611291 = query.getOrDefault("Action")
  valid_611291 = validateParameter(valid_611291, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_611291 != nil:
    section.add "Action", valid_611291
  var valid_611292 = query.getOrDefault("Version")
  valid_611292 = validateParameter(valid_611292, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611292 != nil:
    section.add "Version", valid_611292
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
  var valid_611293 = header.getOrDefault("X-Amz-Signature")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Signature", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Content-Sha256", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Date")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Date", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Credential")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Credential", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Security-Token")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Security-Token", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Algorithm")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Algorithm", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-SignedHeaders", valid_611299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611300: Call_GetApplySecurityGroupsToLoadBalancer_611286;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611300.validator(path, query, header, formData, body)
  let scheme = call_611300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611300.url(scheme.get, call_611300.host, call_611300.base,
                         call_611300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611300, url, valid)

proc call*(call_611301: Call_GetApplySecurityGroupsToLoadBalancer_611286;
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
  var query_611302 = newJObject()
  if SecurityGroups != nil:
    query_611302.add "SecurityGroups", SecurityGroups
  add(query_611302, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611302, "Action", newJString(Action))
  add(query_611302, "Version", newJString(Version))
  result = call_611301.call(nil, query_611302, nil, nil, nil)

var getApplySecurityGroupsToLoadBalancer* = Call_GetApplySecurityGroupsToLoadBalancer_611286(
    name: "getApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_GetApplySecurityGroupsToLoadBalancer_611287, base: "/",
    url: url_GetApplySecurityGroupsToLoadBalancer_611288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAttachLoadBalancerToSubnets_611338 = ref object of OpenApiRestCall_610658
proc url_PostAttachLoadBalancerToSubnets_611340(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAttachLoadBalancerToSubnets_611339(path: JsonNode;
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
  var valid_611341 = query.getOrDefault("Action")
  valid_611341 = validateParameter(valid_611341, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_611341 != nil:
    section.add "Action", valid_611341
  var valid_611342 = query.getOrDefault("Version")
  valid_611342 = validateParameter(valid_611342, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611342 != nil:
    section.add "Version", valid_611342
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
  var valid_611343 = header.getOrDefault("X-Amz-Signature")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Signature", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Content-Sha256", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Date")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Date", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Credential")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Credential", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Security-Token")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Security-Token", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Algorithm")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Algorithm", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-SignedHeaders", valid_611349
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_611350 = formData.getOrDefault("Subnets")
  valid_611350 = validateParameter(valid_611350, JArray, required = true, default = nil)
  if valid_611350 != nil:
    section.add "Subnets", valid_611350
  var valid_611351 = formData.getOrDefault("LoadBalancerName")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = nil)
  if valid_611351 != nil:
    section.add "LoadBalancerName", valid_611351
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611352: Call_PostAttachLoadBalancerToSubnets_611338;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_PostAttachLoadBalancerToSubnets_611338;
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
  var query_611354 = newJObject()
  var formData_611355 = newJObject()
  if Subnets != nil:
    formData_611355.add "Subnets", Subnets
  add(formData_611355, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611354, "Action", newJString(Action))
  add(query_611354, "Version", newJString(Version))
  result = call_611353.call(nil, query_611354, nil, formData_611355, nil)

var postAttachLoadBalancerToSubnets* = Call_PostAttachLoadBalancerToSubnets_611338(
    name: "postAttachLoadBalancerToSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_PostAttachLoadBalancerToSubnets_611339, base: "/",
    url: url_PostAttachLoadBalancerToSubnets_611340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttachLoadBalancerToSubnets_611321 = ref object of OpenApiRestCall_610658
proc url_GetAttachLoadBalancerToSubnets_611323(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAttachLoadBalancerToSubnets_611322(path: JsonNode;
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
  var valid_611324 = query.getOrDefault("LoadBalancerName")
  valid_611324 = validateParameter(valid_611324, JString, required = true,
                                 default = nil)
  if valid_611324 != nil:
    section.add "LoadBalancerName", valid_611324
  var valid_611325 = query.getOrDefault("Action")
  valid_611325 = validateParameter(valid_611325, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_611325 != nil:
    section.add "Action", valid_611325
  var valid_611326 = query.getOrDefault("Subnets")
  valid_611326 = validateParameter(valid_611326, JArray, required = true, default = nil)
  if valid_611326 != nil:
    section.add "Subnets", valid_611326
  var valid_611327 = query.getOrDefault("Version")
  valid_611327 = validateParameter(valid_611327, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611327 != nil:
    section.add "Version", valid_611327
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
  var valid_611328 = header.getOrDefault("X-Amz-Signature")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Signature", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Content-Sha256", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Date")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Date", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Credential")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Credential", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Security-Token")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Security-Token", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Algorithm")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Algorithm", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-SignedHeaders", valid_611334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611335: Call_GetAttachLoadBalancerToSubnets_611321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611335.validator(path, query, header, formData, body)
  let scheme = call_611335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611335.url(scheme.get, call_611335.host, call_611335.base,
                         call_611335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611335, url, valid)

proc call*(call_611336: Call_GetAttachLoadBalancerToSubnets_611321;
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
  var query_611337 = newJObject()
  add(query_611337, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611337, "Action", newJString(Action))
  if Subnets != nil:
    query_611337.add "Subnets", Subnets
  add(query_611337, "Version", newJString(Version))
  result = call_611336.call(nil, query_611337, nil, nil, nil)

var getAttachLoadBalancerToSubnets* = Call_GetAttachLoadBalancerToSubnets_611321(
    name: "getAttachLoadBalancerToSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_GetAttachLoadBalancerToSubnets_611322, base: "/",
    url: url_GetAttachLoadBalancerToSubnets_611323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfigureHealthCheck_611377 = ref object of OpenApiRestCall_610658
proc url_PostConfigureHealthCheck_611379(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostConfigureHealthCheck_611378(path: JsonNode; query: JsonNode;
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
  var valid_611380 = query.getOrDefault("Action")
  valid_611380 = validateParameter(valid_611380, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_611380 != nil:
    section.add "Action", valid_611380
  var valid_611381 = query.getOrDefault("Version")
  valid_611381 = validateParameter(valid_611381, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611381 != nil:
    section.add "Version", valid_611381
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
  var valid_611382 = header.getOrDefault("X-Amz-Signature")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Signature", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Content-Sha256", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Date")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Date", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Credential")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Credential", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Security-Token")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Security-Token", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Algorithm")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Algorithm", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-SignedHeaders", valid_611388
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
  var valid_611389 = formData.getOrDefault("HealthCheck.Interval")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "HealthCheck.Interval", valid_611389
  var valid_611390 = formData.getOrDefault("HealthCheck.HealthyThreshold")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_611390
  var valid_611391 = formData.getOrDefault("HealthCheck.Timeout")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "HealthCheck.Timeout", valid_611391
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_611392 = formData.getOrDefault("LoadBalancerName")
  valid_611392 = validateParameter(valid_611392, JString, required = true,
                                 default = nil)
  if valid_611392 != nil:
    section.add "LoadBalancerName", valid_611392
  var valid_611393 = formData.getOrDefault("HealthCheck.Target")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "HealthCheck.Target", valid_611393
  var valid_611394 = formData.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_611394
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611395: Call_PostConfigureHealthCheck_611377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611395.validator(path, query, header, formData, body)
  let scheme = call_611395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611395.url(scheme.get, call_611395.host, call_611395.base,
                         call_611395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611395, url, valid)

proc call*(call_611396: Call_PostConfigureHealthCheck_611377;
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
  var query_611397 = newJObject()
  var formData_611398 = newJObject()
  add(formData_611398, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(formData_611398, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(formData_611398, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(formData_611398, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611397, "Action", newJString(Action))
  add(formData_611398, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_611397, "Version", newJString(Version))
  add(formData_611398, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  result = call_611396.call(nil, query_611397, nil, formData_611398, nil)

var postConfigureHealthCheck* = Call_PostConfigureHealthCheck_611377(
    name: "postConfigureHealthCheck", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_PostConfigureHealthCheck_611378, base: "/",
    url: url_PostConfigureHealthCheck_611379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigureHealthCheck_611356 = ref object of OpenApiRestCall_610658
proc url_GetConfigureHealthCheck_611358(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConfigureHealthCheck_611357(path: JsonNode; query: JsonNode;
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
  var valid_611359 = query.getOrDefault("HealthCheck.Interval")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "HealthCheck.Interval", valid_611359
  var valid_611360 = query.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_611360
  var valid_611361 = query.getOrDefault("HealthCheck.Timeout")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "HealthCheck.Timeout", valid_611361
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_611362 = query.getOrDefault("LoadBalancerName")
  valid_611362 = validateParameter(valid_611362, JString, required = true,
                                 default = nil)
  if valid_611362 != nil:
    section.add "LoadBalancerName", valid_611362
  var valid_611363 = query.getOrDefault("Action")
  valid_611363 = validateParameter(valid_611363, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_611363 != nil:
    section.add "Action", valid_611363
  var valid_611364 = query.getOrDefault("HealthCheck.Target")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "HealthCheck.Target", valid_611364
  var valid_611365 = query.getOrDefault("HealthCheck.HealthyThreshold")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_611365
  var valid_611366 = query.getOrDefault("Version")
  valid_611366 = validateParameter(valid_611366, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611366 != nil:
    section.add "Version", valid_611366
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
  var valid_611367 = header.getOrDefault("X-Amz-Signature")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Signature", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Content-Sha256", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Date")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Date", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Credential")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Credential", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Security-Token")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Security-Token", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Algorithm")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Algorithm", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-SignedHeaders", valid_611373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611374: Call_GetConfigureHealthCheck_611356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611374.validator(path, query, header, formData, body)
  let scheme = call_611374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611374.url(scheme.get, call_611374.host, call_611374.base,
                         call_611374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611374, url, valid)

proc call*(call_611375: Call_GetConfigureHealthCheck_611356;
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
  var query_611376 = newJObject()
  add(query_611376, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(query_611376, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(query_611376, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_611376, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611376, "Action", newJString(Action))
  add(query_611376, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_611376, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(query_611376, "Version", newJString(Version))
  result = call_611375.call(nil, query_611376, nil, nil, nil)

var getConfigureHealthCheck* = Call_GetConfigureHealthCheck_611356(
    name: "getConfigureHealthCheck", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_GetConfigureHealthCheck_611357, base: "/",
    url: url_GetConfigureHealthCheck_611358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateAppCookieStickinessPolicy_611417 = ref object of OpenApiRestCall_610658
proc url_PostCreateAppCookieStickinessPolicy_611419(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateAppCookieStickinessPolicy_611418(path: JsonNode;
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
  var valid_611420 = query.getOrDefault("Action")
  valid_611420 = validateParameter(valid_611420, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_611420 != nil:
    section.add "Action", valid_611420
  var valid_611421 = query.getOrDefault("Version")
  valid_611421 = validateParameter(valid_611421, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611421 != nil:
    section.add "Version", valid_611421
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
  var valid_611422 = header.getOrDefault("X-Amz-Signature")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Signature", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Content-Sha256", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Date")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Date", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Credential")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Credential", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Security-Token")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Security-Token", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Algorithm")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Algorithm", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-SignedHeaders", valid_611428
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
  var valid_611429 = formData.getOrDefault("CookieName")
  valid_611429 = validateParameter(valid_611429, JString, required = true,
                                 default = nil)
  if valid_611429 != nil:
    section.add "CookieName", valid_611429
  var valid_611430 = formData.getOrDefault("LoadBalancerName")
  valid_611430 = validateParameter(valid_611430, JString, required = true,
                                 default = nil)
  if valid_611430 != nil:
    section.add "LoadBalancerName", valid_611430
  var valid_611431 = formData.getOrDefault("PolicyName")
  valid_611431 = validateParameter(valid_611431, JString, required = true,
                                 default = nil)
  if valid_611431 != nil:
    section.add "PolicyName", valid_611431
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611432: Call_PostCreateAppCookieStickinessPolicy_611417;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611432.validator(path, query, header, formData, body)
  let scheme = call_611432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611432.url(scheme.get, call_611432.host, call_611432.base,
                         call_611432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611432, url, valid)

proc call*(call_611433: Call_PostCreateAppCookieStickinessPolicy_611417;
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
  var query_611434 = newJObject()
  var formData_611435 = newJObject()
  add(formData_611435, "CookieName", newJString(CookieName))
  add(formData_611435, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611434, "Action", newJString(Action))
  add(query_611434, "Version", newJString(Version))
  add(formData_611435, "PolicyName", newJString(PolicyName))
  result = call_611433.call(nil, query_611434, nil, formData_611435, nil)

var postCreateAppCookieStickinessPolicy* = Call_PostCreateAppCookieStickinessPolicy_611417(
    name: "postCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_PostCreateAppCookieStickinessPolicy_611418, base: "/",
    url: url_PostCreateAppCookieStickinessPolicy_611419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateAppCookieStickinessPolicy_611399 = ref object of OpenApiRestCall_610658
proc url_GetCreateAppCookieStickinessPolicy_611401(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateAppCookieStickinessPolicy_611400(path: JsonNode;
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
  var valid_611402 = query.getOrDefault("PolicyName")
  valid_611402 = validateParameter(valid_611402, JString, required = true,
                                 default = nil)
  if valid_611402 != nil:
    section.add "PolicyName", valid_611402
  var valid_611403 = query.getOrDefault("CookieName")
  valid_611403 = validateParameter(valid_611403, JString, required = true,
                                 default = nil)
  if valid_611403 != nil:
    section.add "CookieName", valid_611403
  var valid_611404 = query.getOrDefault("LoadBalancerName")
  valid_611404 = validateParameter(valid_611404, JString, required = true,
                                 default = nil)
  if valid_611404 != nil:
    section.add "LoadBalancerName", valid_611404
  var valid_611405 = query.getOrDefault("Action")
  valid_611405 = validateParameter(valid_611405, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_611405 != nil:
    section.add "Action", valid_611405
  var valid_611406 = query.getOrDefault("Version")
  valid_611406 = validateParameter(valid_611406, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611406 != nil:
    section.add "Version", valid_611406
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
  var valid_611407 = header.getOrDefault("X-Amz-Signature")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Signature", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Content-Sha256", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Date")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Date", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Credential")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Credential", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Security-Token")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Security-Token", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Algorithm")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Algorithm", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-SignedHeaders", valid_611413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611414: Call_GetCreateAppCookieStickinessPolicy_611399;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611414.validator(path, query, header, formData, body)
  let scheme = call_611414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611414.url(scheme.get, call_611414.host, call_611414.base,
                         call_611414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611414, url, valid)

proc call*(call_611415: Call_GetCreateAppCookieStickinessPolicy_611399;
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
  var query_611416 = newJObject()
  add(query_611416, "PolicyName", newJString(PolicyName))
  add(query_611416, "CookieName", newJString(CookieName))
  add(query_611416, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611416, "Action", newJString(Action))
  add(query_611416, "Version", newJString(Version))
  result = call_611415.call(nil, query_611416, nil, nil, nil)

var getCreateAppCookieStickinessPolicy* = Call_GetCreateAppCookieStickinessPolicy_611399(
    name: "getCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_GetCreateAppCookieStickinessPolicy_611400, base: "/",
    url: url_GetCreateAppCookieStickinessPolicy_611401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLBCookieStickinessPolicy_611454 = ref object of OpenApiRestCall_610658
proc url_PostCreateLBCookieStickinessPolicy_611456(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLBCookieStickinessPolicy_611455(path: JsonNode;
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
  var valid_611457 = query.getOrDefault("Action")
  valid_611457 = validateParameter(valid_611457, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_611457 != nil:
    section.add "Action", valid_611457
  var valid_611458 = query.getOrDefault("Version")
  valid_611458 = validateParameter(valid_611458, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611458 != nil:
    section.add "Version", valid_611458
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
  var valid_611459 = header.getOrDefault("X-Amz-Signature")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Signature", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Content-Sha256", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-Date")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Date", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-Credential")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Credential", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Security-Token")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Security-Token", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Algorithm")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Algorithm", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-SignedHeaders", valid_611465
  result.add "header", section
  ## parameters in `formData` object:
  ##   CookieExpirationPeriod: JInt
  ##                         : The time period, in seconds, after which the cookie should be considered stale. If you do not specify this parameter, the default value is 0, which indicates that the sticky session should last for the duration of the browser session.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyName: JString (required)
  ##             : The name of the policy being created. Policy names must consist of alphanumeric characters and dashes (-). This name must be unique within the set of policies for this load balancer.
  section = newJObject()
  var valid_611466 = formData.getOrDefault("CookieExpirationPeriod")
  valid_611466 = validateParameter(valid_611466, JInt, required = false, default = nil)
  if valid_611466 != nil:
    section.add "CookieExpirationPeriod", valid_611466
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_611467 = formData.getOrDefault("LoadBalancerName")
  valid_611467 = validateParameter(valid_611467, JString, required = true,
                                 default = nil)
  if valid_611467 != nil:
    section.add "LoadBalancerName", valid_611467
  var valid_611468 = formData.getOrDefault("PolicyName")
  valid_611468 = validateParameter(valid_611468, JString, required = true,
                                 default = nil)
  if valid_611468 != nil:
    section.add "PolicyName", valid_611468
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611469: Call_PostCreateLBCookieStickinessPolicy_611454;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611469.validator(path, query, header, formData, body)
  let scheme = call_611469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611469.url(scheme.get, call_611469.host, call_611469.base,
                         call_611469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611469, url, valid)

proc call*(call_611470: Call_PostCreateLBCookieStickinessPolicy_611454;
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
  var query_611471 = newJObject()
  var formData_611472 = newJObject()
  add(formData_611472, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(formData_611472, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611471, "Action", newJString(Action))
  add(query_611471, "Version", newJString(Version))
  add(formData_611472, "PolicyName", newJString(PolicyName))
  result = call_611470.call(nil, query_611471, nil, formData_611472, nil)

var postCreateLBCookieStickinessPolicy* = Call_PostCreateLBCookieStickinessPolicy_611454(
    name: "postCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_PostCreateLBCookieStickinessPolicy_611455, base: "/",
    url: url_PostCreateLBCookieStickinessPolicy_611456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLBCookieStickinessPolicy_611436 = ref object of OpenApiRestCall_610658
proc url_GetCreateLBCookieStickinessPolicy_611438(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLBCookieStickinessPolicy_611437(path: JsonNode;
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
  var valid_611439 = query.getOrDefault("CookieExpirationPeriod")
  valid_611439 = validateParameter(valid_611439, JInt, required = false, default = nil)
  if valid_611439 != nil:
    section.add "CookieExpirationPeriod", valid_611439
  assert query != nil,
        "query argument is necessary due to required `PolicyName` field"
  var valid_611440 = query.getOrDefault("PolicyName")
  valid_611440 = validateParameter(valid_611440, JString, required = true,
                                 default = nil)
  if valid_611440 != nil:
    section.add "PolicyName", valid_611440
  var valid_611441 = query.getOrDefault("LoadBalancerName")
  valid_611441 = validateParameter(valid_611441, JString, required = true,
                                 default = nil)
  if valid_611441 != nil:
    section.add "LoadBalancerName", valid_611441
  var valid_611442 = query.getOrDefault("Action")
  valid_611442 = validateParameter(valid_611442, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_611442 != nil:
    section.add "Action", valid_611442
  var valid_611443 = query.getOrDefault("Version")
  valid_611443 = validateParameter(valid_611443, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611443 != nil:
    section.add "Version", valid_611443
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
  var valid_611444 = header.getOrDefault("X-Amz-Signature")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Signature", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Content-Sha256", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Date")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Date", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Credential")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Credential", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Security-Token")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Security-Token", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Algorithm")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Algorithm", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-SignedHeaders", valid_611450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611451: Call_GetCreateLBCookieStickinessPolicy_611436;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611451.validator(path, query, header, formData, body)
  let scheme = call_611451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611451.url(scheme.get, call_611451.host, call_611451.base,
                         call_611451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611451, url, valid)

proc call*(call_611452: Call_GetCreateLBCookieStickinessPolicy_611436;
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
  var query_611453 = newJObject()
  add(query_611453, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(query_611453, "PolicyName", newJString(PolicyName))
  add(query_611453, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611453, "Action", newJString(Action))
  add(query_611453, "Version", newJString(Version))
  result = call_611452.call(nil, query_611453, nil, nil, nil)

var getCreateLBCookieStickinessPolicy* = Call_GetCreateLBCookieStickinessPolicy_611436(
    name: "getCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_GetCreateLBCookieStickinessPolicy_611437, base: "/",
    url: url_GetCreateLBCookieStickinessPolicy_611438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_611495 = ref object of OpenApiRestCall_610658
proc url_PostCreateLoadBalancer_611497(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLoadBalancer_611496(path: JsonNode; query: JsonNode;
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
  var valid_611498 = query.getOrDefault("Action")
  valid_611498 = validateParameter(valid_611498, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_611498 != nil:
    section.add "Action", valid_611498
  var valid_611499 = query.getOrDefault("Version")
  valid_611499 = validateParameter(valid_611499, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611499 != nil:
    section.add "Version", valid_611499
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
  var valid_611500 = header.getOrDefault("X-Amz-Signature")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Signature", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Content-Sha256", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Date")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Date", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Credential")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Credential", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Security-Token")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Security-Token", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Algorithm")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Algorithm", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-SignedHeaders", valid_611506
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
  var valid_611507 = formData.getOrDefault("Scheme")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "Scheme", valid_611507
  var valid_611508 = formData.getOrDefault("SecurityGroups")
  valid_611508 = validateParameter(valid_611508, JArray, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "SecurityGroups", valid_611508
  var valid_611509 = formData.getOrDefault("AvailabilityZones")
  valid_611509 = validateParameter(valid_611509, JArray, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "AvailabilityZones", valid_611509
  var valid_611510 = formData.getOrDefault("Subnets")
  valid_611510 = validateParameter(valid_611510, JArray, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "Subnets", valid_611510
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_611511 = formData.getOrDefault("LoadBalancerName")
  valid_611511 = validateParameter(valid_611511, JString, required = true,
                                 default = nil)
  if valid_611511 != nil:
    section.add "LoadBalancerName", valid_611511
  var valid_611512 = formData.getOrDefault("Listeners")
  valid_611512 = validateParameter(valid_611512, JArray, required = true, default = nil)
  if valid_611512 != nil:
    section.add "Listeners", valid_611512
  var valid_611513 = formData.getOrDefault("Tags")
  valid_611513 = validateParameter(valid_611513, JArray, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "Tags", valid_611513
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611514: Call_PostCreateLoadBalancer_611495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611514.validator(path, query, header, formData, body)
  let scheme = call_611514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611514.url(scheme.get, call_611514.host, call_611514.base,
                         call_611514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611514, url, valid)

proc call*(call_611515: Call_PostCreateLoadBalancer_611495;
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
  var query_611516 = newJObject()
  var formData_611517 = newJObject()
  add(formData_611517, "Scheme", newJString(Scheme))
  if SecurityGroups != nil:
    formData_611517.add "SecurityGroups", SecurityGroups
  if AvailabilityZones != nil:
    formData_611517.add "AvailabilityZones", AvailabilityZones
  if Subnets != nil:
    formData_611517.add "Subnets", Subnets
  add(formData_611517, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_611517.add "Listeners", Listeners
  add(query_611516, "Action", newJString(Action))
  if Tags != nil:
    formData_611517.add "Tags", Tags
  add(query_611516, "Version", newJString(Version))
  result = call_611515.call(nil, query_611516, nil, formData_611517, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_611495(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_611496, base: "/",
    url: url_PostCreateLoadBalancer_611497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_611473 = ref object of OpenApiRestCall_610658
proc url_GetCreateLoadBalancer_611475(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLoadBalancer_611474(path: JsonNode; query: JsonNode;
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
  var valid_611476 = query.getOrDefault("Tags")
  valid_611476 = validateParameter(valid_611476, JArray, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "Tags", valid_611476
  var valid_611477 = query.getOrDefault("Scheme")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "Scheme", valid_611477
  var valid_611478 = query.getOrDefault("AvailabilityZones")
  valid_611478 = validateParameter(valid_611478, JArray, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "AvailabilityZones", valid_611478
  assert query != nil,
        "query argument is necessary due to required `Listeners` field"
  var valid_611479 = query.getOrDefault("Listeners")
  valid_611479 = validateParameter(valid_611479, JArray, required = true, default = nil)
  if valid_611479 != nil:
    section.add "Listeners", valid_611479
  var valid_611480 = query.getOrDefault("SecurityGroups")
  valid_611480 = validateParameter(valid_611480, JArray, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "SecurityGroups", valid_611480
  var valid_611481 = query.getOrDefault("LoadBalancerName")
  valid_611481 = validateParameter(valid_611481, JString, required = true,
                                 default = nil)
  if valid_611481 != nil:
    section.add "LoadBalancerName", valid_611481
  var valid_611482 = query.getOrDefault("Action")
  valid_611482 = validateParameter(valid_611482, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_611482 != nil:
    section.add "Action", valid_611482
  var valid_611483 = query.getOrDefault("Subnets")
  valid_611483 = validateParameter(valid_611483, JArray, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "Subnets", valid_611483
  var valid_611484 = query.getOrDefault("Version")
  valid_611484 = validateParameter(valid_611484, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611484 != nil:
    section.add "Version", valid_611484
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
  var valid_611485 = header.getOrDefault("X-Amz-Signature")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Signature", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Content-Sha256", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-Date")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Date", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Credential")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Credential", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Security-Token")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Security-Token", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Algorithm")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Algorithm", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-SignedHeaders", valid_611491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611492: Call_GetCreateLoadBalancer_611473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611492.validator(path, query, header, formData, body)
  let scheme = call_611492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611492.url(scheme.get, call_611492.host, call_611492.base,
                         call_611492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611492, url, valid)

proc call*(call_611493: Call_GetCreateLoadBalancer_611473; Listeners: JsonNode;
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
  var query_611494 = newJObject()
  if Tags != nil:
    query_611494.add "Tags", Tags
  add(query_611494, "Scheme", newJString(Scheme))
  if AvailabilityZones != nil:
    query_611494.add "AvailabilityZones", AvailabilityZones
  if Listeners != nil:
    query_611494.add "Listeners", Listeners
  if SecurityGroups != nil:
    query_611494.add "SecurityGroups", SecurityGroups
  add(query_611494, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611494, "Action", newJString(Action))
  if Subnets != nil:
    query_611494.add "Subnets", Subnets
  add(query_611494, "Version", newJString(Version))
  result = call_611493.call(nil, query_611494, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_611473(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_611474, base: "/",
    url: url_GetCreateLoadBalancer_611475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerListeners_611535 = ref object of OpenApiRestCall_610658
proc url_PostCreateLoadBalancerListeners_611537(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLoadBalancerListeners_611536(path: JsonNode;
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
  var valid_611538 = query.getOrDefault("Action")
  valid_611538 = validateParameter(valid_611538, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_611538 != nil:
    section.add "Action", valid_611538
  var valid_611539 = query.getOrDefault("Version")
  valid_611539 = validateParameter(valid_611539, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611539 != nil:
    section.add "Version", valid_611539
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
  var valid_611540 = header.getOrDefault("X-Amz-Signature")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Signature", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Content-Sha256", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Date")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Date", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Credential")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Credential", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Security-Token")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Security-Token", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Algorithm")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Algorithm", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-SignedHeaders", valid_611546
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_611547 = formData.getOrDefault("LoadBalancerName")
  valid_611547 = validateParameter(valid_611547, JString, required = true,
                                 default = nil)
  if valid_611547 != nil:
    section.add "LoadBalancerName", valid_611547
  var valid_611548 = formData.getOrDefault("Listeners")
  valid_611548 = validateParameter(valid_611548, JArray, required = true, default = nil)
  if valid_611548 != nil:
    section.add "Listeners", valid_611548
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611549: Call_PostCreateLoadBalancerListeners_611535;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611549.validator(path, query, header, formData, body)
  let scheme = call_611549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611549.url(scheme.get, call_611549.host, call_611549.base,
                         call_611549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611549, url, valid)

proc call*(call_611550: Call_PostCreateLoadBalancerListeners_611535;
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
  var query_611551 = newJObject()
  var formData_611552 = newJObject()
  add(formData_611552, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_611552.add "Listeners", Listeners
  add(query_611551, "Action", newJString(Action))
  add(query_611551, "Version", newJString(Version))
  result = call_611550.call(nil, query_611551, nil, formData_611552, nil)

var postCreateLoadBalancerListeners* = Call_PostCreateLoadBalancerListeners_611535(
    name: "postCreateLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_PostCreateLoadBalancerListeners_611536, base: "/",
    url: url_PostCreateLoadBalancerListeners_611537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerListeners_611518 = ref object of OpenApiRestCall_610658
proc url_GetCreateLoadBalancerListeners_611520(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLoadBalancerListeners_611519(path: JsonNode;
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
  var valid_611521 = query.getOrDefault("Listeners")
  valid_611521 = validateParameter(valid_611521, JArray, required = true, default = nil)
  if valid_611521 != nil:
    section.add "Listeners", valid_611521
  var valid_611522 = query.getOrDefault("LoadBalancerName")
  valid_611522 = validateParameter(valid_611522, JString, required = true,
                                 default = nil)
  if valid_611522 != nil:
    section.add "LoadBalancerName", valid_611522
  var valid_611523 = query.getOrDefault("Action")
  valid_611523 = validateParameter(valid_611523, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_611523 != nil:
    section.add "Action", valid_611523
  var valid_611524 = query.getOrDefault("Version")
  valid_611524 = validateParameter(valid_611524, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611524 != nil:
    section.add "Version", valid_611524
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
  var valid_611525 = header.getOrDefault("X-Amz-Signature")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Signature", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Content-Sha256", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Date")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Date", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Credential")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Credential", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Security-Token")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Security-Token", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-Algorithm")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Algorithm", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-SignedHeaders", valid_611531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611532: Call_GetCreateLoadBalancerListeners_611518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611532.validator(path, query, header, formData, body)
  let scheme = call_611532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611532.url(scheme.get, call_611532.host, call_611532.base,
                         call_611532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611532, url, valid)

proc call*(call_611533: Call_GetCreateLoadBalancerListeners_611518;
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
  var query_611534 = newJObject()
  if Listeners != nil:
    query_611534.add "Listeners", Listeners
  add(query_611534, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611534, "Action", newJString(Action))
  add(query_611534, "Version", newJString(Version))
  result = call_611533.call(nil, query_611534, nil, nil, nil)

var getCreateLoadBalancerListeners* = Call_GetCreateLoadBalancerListeners_611518(
    name: "getCreateLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_GetCreateLoadBalancerListeners_611519, base: "/",
    url: url_GetCreateLoadBalancerListeners_611520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerPolicy_611572 = ref object of OpenApiRestCall_610658
proc url_PostCreateLoadBalancerPolicy_611574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateLoadBalancerPolicy_611573(path: JsonNode; query: JsonNode;
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
  var valid_611575 = query.getOrDefault("Action")
  valid_611575 = validateParameter(valid_611575, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_611575 != nil:
    section.add "Action", valid_611575
  var valid_611576 = query.getOrDefault("Version")
  valid_611576 = validateParameter(valid_611576, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611576 != nil:
    section.add "Version", valid_611576
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
  var valid_611577 = header.getOrDefault("X-Amz-Signature")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-Signature", valid_611577
  var valid_611578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Content-Sha256", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-Date")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Date", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-Credential")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Credential", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Security-Token")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Security-Token", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-Algorithm")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Algorithm", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-SignedHeaders", valid_611583
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
  var valid_611584 = formData.getOrDefault("PolicyAttributes")
  valid_611584 = validateParameter(valid_611584, JArray, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "PolicyAttributes", valid_611584
  assert formData != nil,
        "formData argument is necessary due to required `PolicyTypeName` field"
  var valid_611585 = formData.getOrDefault("PolicyTypeName")
  valid_611585 = validateParameter(valid_611585, JString, required = true,
                                 default = nil)
  if valid_611585 != nil:
    section.add "PolicyTypeName", valid_611585
  var valid_611586 = formData.getOrDefault("LoadBalancerName")
  valid_611586 = validateParameter(valid_611586, JString, required = true,
                                 default = nil)
  if valid_611586 != nil:
    section.add "LoadBalancerName", valid_611586
  var valid_611587 = formData.getOrDefault("PolicyName")
  valid_611587 = validateParameter(valid_611587, JString, required = true,
                                 default = nil)
  if valid_611587 != nil:
    section.add "PolicyName", valid_611587
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611588: Call_PostCreateLoadBalancerPolicy_611572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_611588.validator(path, query, header, formData, body)
  let scheme = call_611588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611588.url(scheme.get, call_611588.host, call_611588.base,
                         call_611588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611588, url, valid)

proc call*(call_611589: Call_PostCreateLoadBalancerPolicy_611572;
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
  var query_611590 = newJObject()
  var formData_611591 = newJObject()
  if PolicyAttributes != nil:
    formData_611591.add "PolicyAttributes", PolicyAttributes
  add(formData_611591, "PolicyTypeName", newJString(PolicyTypeName))
  add(formData_611591, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611590, "Action", newJString(Action))
  add(query_611590, "Version", newJString(Version))
  add(formData_611591, "PolicyName", newJString(PolicyName))
  result = call_611589.call(nil, query_611590, nil, formData_611591, nil)

var postCreateLoadBalancerPolicy* = Call_PostCreateLoadBalancerPolicy_611572(
    name: "postCreateLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_PostCreateLoadBalancerPolicy_611573, base: "/",
    url: url_PostCreateLoadBalancerPolicy_611574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerPolicy_611553 = ref object of OpenApiRestCall_610658
proc url_GetCreateLoadBalancerPolicy_611555(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateLoadBalancerPolicy_611554(path: JsonNode; query: JsonNode;
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
  var valid_611556 = query.getOrDefault("PolicyAttributes")
  valid_611556 = validateParameter(valid_611556, JArray, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "PolicyAttributes", valid_611556
  assert query != nil,
        "query argument is necessary due to required `PolicyName` field"
  var valid_611557 = query.getOrDefault("PolicyName")
  valid_611557 = validateParameter(valid_611557, JString, required = true,
                                 default = nil)
  if valid_611557 != nil:
    section.add "PolicyName", valid_611557
  var valid_611558 = query.getOrDefault("PolicyTypeName")
  valid_611558 = validateParameter(valid_611558, JString, required = true,
                                 default = nil)
  if valid_611558 != nil:
    section.add "PolicyTypeName", valid_611558
  var valid_611559 = query.getOrDefault("LoadBalancerName")
  valid_611559 = validateParameter(valid_611559, JString, required = true,
                                 default = nil)
  if valid_611559 != nil:
    section.add "LoadBalancerName", valid_611559
  var valid_611560 = query.getOrDefault("Action")
  valid_611560 = validateParameter(valid_611560, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_611560 != nil:
    section.add "Action", valid_611560
  var valid_611561 = query.getOrDefault("Version")
  valid_611561 = validateParameter(valid_611561, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611561 != nil:
    section.add "Version", valid_611561
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
  var valid_611562 = header.getOrDefault("X-Amz-Signature")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Signature", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Content-Sha256", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-Date")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Date", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-Credential")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Credential", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Security-Token")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Security-Token", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Algorithm")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Algorithm", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-SignedHeaders", valid_611568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611569: Call_GetCreateLoadBalancerPolicy_611553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_611569.validator(path, query, header, formData, body)
  let scheme = call_611569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611569.url(scheme.get, call_611569.host, call_611569.base,
                         call_611569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611569, url, valid)

proc call*(call_611570: Call_GetCreateLoadBalancerPolicy_611553;
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
  var query_611571 = newJObject()
  if PolicyAttributes != nil:
    query_611571.add "PolicyAttributes", PolicyAttributes
  add(query_611571, "PolicyName", newJString(PolicyName))
  add(query_611571, "PolicyTypeName", newJString(PolicyTypeName))
  add(query_611571, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611571, "Action", newJString(Action))
  add(query_611571, "Version", newJString(Version))
  result = call_611570.call(nil, query_611571, nil, nil, nil)

var getCreateLoadBalancerPolicy* = Call_GetCreateLoadBalancerPolicy_611553(
    name: "getCreateLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_GetCreateLoadBalancerPolicy_611554, base: "/",
    url: url_GetCreateLoadBalancerPolicy_611555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_611608 = ref object of OpenApiRestCall_610658
proc url_PostDeleteLoadBalancer_611610(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteLoadBalancer_611609(path: JsonNode; query: JsonNode;
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
  var valid_611611 = query.getOrDefault("Action")
  valid_611611 = validateParameter(valid_611611, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_611611 != nil:
    section.add "Action", valid_611611
  var valid_611612 = query.getOrDefault("Version")
  valid_611612 = validateParameter(valid_611612, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611612 != nil:
    section.add "Version", valid_611612
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
  var valid_611613 = header.getOrDefault("X-Amz-Signature")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Signature", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Content-Sha256", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Date")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Date", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Credential")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Credential", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Security-Token")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Security-Token", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Algorithm")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Algorithm", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-SignedHeaders", valid_611619
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_611620 = formData.getOrDefault("LoadBalancerName")
  valid_611620 = validateParameter(valid_611620, JString, required = true,
                                 default = nil)
  if valid_611620 != nil:
    section.add "LoadBalancerName", valid_611620
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611621: Call_PostDeleteLoadBalancer_611608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_611621.validator(path, query, header, formData, body)
  let scheme = call_611621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611621.url(scheme.get, call_611621.host, call_611621.base,
                         call_611621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611621, url, valid)

proc call*(call_611622: Call_PostDeleteLoadBalancer_611608;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611623 = newJObject()
  var formData_611624 = newJObject()
  add(formData_611624, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611623, "Action", newJString(Action))
  add(query_611623, "Version", newJString(Version))
  result = call_611622.call(nil, query_611623, nil, formData_611624, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_611608(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_611609, base: "/",
    url: url_PostDeleteLoadBalancer_611610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_611592 = ref object of OpenApiRestCall_610658
proc url_GetDeleteLoadBalancer_611594(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteLoadBalancer_611593(path: JsonNode; query: JsonNode;
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
  var valid_611595 = query.getOrDefault("LoadBalancerName")
  valid_611595 = validateParameter(valid_611595, JString, required = true,
                                 default = nil)
  if valid_611595 != nil:
    section.add "LoadBalancerName", valid_611595
  var valid_611596 = query.getOrDefault("Action")
  valid_611596 = validateParameter(valid_611596, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_611596 != nil:
    section.add "Action", valid_611596
  var valid_611597 = query.getOrDefault("Version")
  valid_611597 = validateParameter(valid_611597, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611597 != nil:
    section.add "Version", valid_611597
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
  var valid_611598 = header.getOrDefault("X-Amz-Signature")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "X-Amz-Signature", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Content-Sha256", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Date")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Date", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Credential")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Credential", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Security-Token")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Security-Token", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Algorithm")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Algorithm", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-SignedHeaders", valid_611604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611605: Call_GetDeleteLoadBalancer_611592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_611605.validator(path, query, header, formData, body)
  let scheme = call_611605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611605.url(scheme.get, call_611605.host, call_611605.base,
                         call_611605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611605, url, valid)

proc call*(call_611606: Call_GetDeleteLoadBalancer_611592;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611607 = newJObject()
  add(query_611607, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611607, "Action", newJString(Action))
  add(query_611607, "Version", newJString(Version))
  result = call_611606.call(nil, query_611607, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_611592(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_611593, base: "/",
    url: url_GetDeleteLoadBalancer_611594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerListeners_611642 = ref object of OpenApiRestCall_610658
proc url_PostDeleteLoadBalancerListeners_611644(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteLoadBalancerListeners_611643(path: JsonNode;
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
  var valid_611645 = query.getOrDefault("Action")
  valid_611645 = validateParameter(valid_611645, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_611645 != nil:
    section.add "Action", valid_611645
  var valid_611646 = query.getOrDefault("Version")
  valid_611646 = validateParameter(valid_611646, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611646 != nil:
    section.add "Version", valid_611646
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
  var valid_611647 = header.getOrDefault("X-Amz-Signature")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Signature", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Content-Sha256", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Date")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Date", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-Credential")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Credential", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Security-Token")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Security-Token", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Algorithm")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Algorithm", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-SignedHeaders", valid_611653
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerPorts` field"
  var valid_611654 = formData.getOrDefault("LoadBalancerPorts")
  valid_611654 = validateParameter(valid_611654, JArray, required = true, default = nil)
  if valid_611654 != nil:
    section.add "LoadBalancerPorts", valid_611654
  var valid_611655 = formData.getOrDefault("LoadBalancerName")
  valid_611655 = validateParameter(valid_611655, JString, required = true,
                                 default = nil)
  if valid_611655 != nil:
    section.add "LoadBalancerName", valid_611655
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611656: Call_PostDeleteLoadBalancerListeners_611642;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_611656.validator(path, query, header, formData, body)
  let scheme = call_611656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611656.url(scheme.get, call_611656.host, call_611656.base,
                         call_611656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611656, url, valid)

proc call*(call_611657: Call_PostDeleteLoadBalancerListeners_611642;
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
  var query_611658 = newJObject()
  var formData_611659 = newJObject()
  if LoadBalancerPorts != nil:
    formData_611659.add "LoadBalancerPorts", LoadBalancerPorts
  add(formData_611659, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611658, "Action", newJString(Action))
  add(query_611658, "Version", newJString(Version))
  result = call_611657.call(nil, query_611658, nil, formData_611659, nil)

var postDeleteLoadBalancerListeners* = Call_PostDeleteLoadBalancerListeners_611642(
    name: "postDeleteLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_PostDeleteLoadBalancerListeners_611643, base: "/",
    url: url_PostDeleteLoadBalancerListeners_611644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerListeners_611625 = ref object of OpenApiRestCall_610658
proc url_GetDeleteLoadBalancerListeners_611627(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteLoadBalancerListeners_611626(path: JsonNode;
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
  var valid_611628 = query.getOrDefault("LoadBalancerPorts")
  valid_611628 = validateParameter(valid_611628, JArray, required = true, default = nil)
  if valid_611628 != nil:
    section.add "LoadBalancerPorts", valid_611628
  var valid_611629 = query.getOrDefault("LoadBalancerName")
  valid_611629 = validateParameter(valid_611629, JString, required = true,
                                 default = nil)
  if valid_611629 != nil:
    section.add "LoadBalancerName", valid_611629
  var valid_611630 = query.getOrDefault("Action")
  valid_611630 = validateParameter(valid_611630, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_611630 != nil:
    section.add "Action", valid_611630
  var valid_611631 = query.getOrDefault("Version")
  valid_611631 = validateParameter(valid_611631, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611631 != nil:
    section.add "Version", valid_611631
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
  var valid_611632 = header.getOrDefault("X-Amz-Signature")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Signature", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Content-Sha256", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Date")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Date", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Credential")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Credential", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Security-Token")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Security-Token", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Algorithm")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Algorithm", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-SignedHeaders", valid_611638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611639: Call_GetDeleteLoadBalancerListeners_611625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_611639.validator(path, query, header, formData, body)
  let scheme = call_611639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611639.url(scheme.get, call_611639.host, call_611639.base,
                         call_611639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611639, url, valid)

proc call*(call_611640: Call_GetDeleteLoadBalancerListeners_611625;
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
  var query_611641 = newJObject()
  if LoadBalancerPorts != nil:
    query_611641.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_611641, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611641, "Action", newJString(Action))
  add(query_611641, "Version", newJString(Version))
  result = call_611640.call(nil, query_611641, nil, nil, nil)

var getDeleteLoadBalancerListeners* = Call_GetDeleteLoadBalancerListeners_611625(
    name: "getDeleteLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_GetDeleteLoadBalancerListeners_611626, base: "/",
    url: url_GetDeleteLoadBalancerListeners_611627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerPolicy_611677 = ref object of OpenApiRestCall_610658
proc url_PostDeleteLoadBalancerPolicy_611679(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteLoadBalancerPolicy_611678(path: JsonNode; query: JsonNode;
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
  var valid_611680 = query.getOrDefault("Action")
  valid_611680 = validateParameter(valid_611680, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_611680 != nil:
    section.add "Action", valid_611680
  var valid_611681 = query.getOrDefault("Version")
  valid_611681 = validateParameter(valid_611681, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611681 != nil:
    section.add "Version", valid_611681
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
  var valid_611682 = header.getOrDefault("X-Amz-Signature")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Signature", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Content-Sha256", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Date")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Date", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-Credential")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Credential", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Security-Token")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Security-Token", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-Algorithm")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-Algorithm", valid_611687
  var valid_611688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611688 = validateParameter(valid_611688, JString, required = false,
                                 default = nil)
  if valid_611688 != nil:
    section.add "X-Amz-SignedHeaders", valid_611688
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_611689 = formData.getOrDefault("LoadBalancerName")
  valid_611689 = validateParameter(valid_611689, JString, required = true,
                                 default = nil)
  if valid_611689 != nil:
    section.add "LoadBalancerName", valid_611689
  var valid_611690 = formData.getOrDefault("PolicyName")
  valid_611690 = validateParameter(valid_611690, JString, required = true,
                                 default = nil)
  if valid_611690 != nil:
    section.add "PolicyName", valid_611690
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611691: Call_PostDeleteLoadBalancerPolicy_611677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_611691.validator(path, query, header, formData, body)
  let scheme = call_611691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611691.url(scheme.get, call_611691.host, call_611691.base,
                         call_611691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611691, url, valid)

proc call*(call_611692: Call_PostDeleteLoadBalancerPolicy_611677;
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
  var query_611693 = newJObject()
  var formData_611694 = newJObject()
  add(formData_611694, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611693, "Action", newJString(Action))
  add(query_611693, "Version", newJString(Version))
  add(formData_611694, "PolicyName", newJString(PolicyName))
  result = call_611692.call(nil, query_611693, nil, formData_611694, nil)

var postDeleteLoadBalancerPolicy* = Call_PostDeleteLoadBalancerPolicy_611677(
    name: "postDeleteLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_PostDeleteLoadBalancerPolicy_611678, base: "/",
    url: url_PostDeleteLoadBalancerPolicy_611679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerPolicy_611660 = ref object of OpenApiRestCall_610658
proc url_GetDeleteLoadBalancerPolicy_611662(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteLoadBalancerPolicy_611661(path: JsonNode; query: JsonNode;
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
  var valid_611663 = query.getOrDefault("PolicyName")
  valid_611663 = validateParameter(valid_611663, JString, required = true,
                                 default = nil)
  if valid_611663 != nil:
    section.add "PolicyName", valid_611663
  var valid_611664 = query.getOrDefault("LoadBalancerName")
  valid_611664 = validateParameter(valid_611664, JString, required = true,
                                 default = nil)
  if valid_611664 != nil:
    section.add "LoadBalancerName", valid_611664
  var valid_611665 = query.getOrDefault("Action")
  valid_611665 = validateParameter(valid_611665, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_611665 != nil:
    section.add "Action", valid_611665
  var valid_611666 = query.getOrDefault("Version")
  valid_611666 = validateParameter(valid_611666, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611666 != nil:
    section.add "Version", valid_611666
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
  var valid_611667 = header.getOrDefault("X-Amz-Signature")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Signature", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Content-Sha256", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-Date")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Date", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Credential")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Credential", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Security-Token")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Security-Token", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-Algorithm")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-Algorithm", valid_611672
  var valid_611673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611673 = validateParameter(valid_611673, JString, required = false,
                                 default = nil)
  if valid_611673 != nil:
    section.add "X-Amz-SignedHeaders", valid_611673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611674: Call_GetDeleteLoadBalancerPolicy_611660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_611674.validator(path, query, header, formData, body)
  let scheme = call_611674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611674.url(scheme.get, call_611674.host, call_611674.base,
                         call_611674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611674, url, valid)

proc call*(call_611675: Call_GetDeleteLoadBalancerPolicy_611660;
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
  var query_611676 = newJObject()
  add(query_611676, "PolicyName", newJString(PolicyName))
  add(query_611676, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611676, "Action", newJString(Action))
  add(query_611676, "Version", newJString(Version))
  result = call_611675.call(nil, query_611676, nil, nil, nil)

var getDeleteLoadBalancerPolicy* = Call_GetDeleteLoadBalancerPolicy_611660(
    name: "getDeleteLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_GetDeleteLoadBalancerPolicy_611661, base: "/",
    url: url_GetDeleteLoadBalancerPolicy_611662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterInstancesFromLoadBalancer_611712 = ref object of OpenApiRestCall_610658
proc url_PostDeregisterInstancesFromLoadBalancer_611714(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeregisterInstancesFromLoadBalancer_611713(path: JsonNode;
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
  var valid_611715 = query.getOrDefault("Action")
  valid_611715 = validateParameter(valid_611715, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_611715 != nil:
    section.add "Action", valid_611715
  var valid_611716 = query.getOrDefault("Version")
  valid_611716 = validateParameter(valid_611716, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611716 != nil:
    section.add "Version", valid_611716
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
  var valid_611717 = header.getOrDefault("X-Amz-Signature")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-Signature", valid_611717
  var valid_611718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611718 = validateParameter(valid_611718, JString, required = false,
                                 default = nil)
  if valid_611718 != nil:
    section.add "X-Amz-Content-Sha256", valid_611718
  var valid_611719 = header.getOrDefault("X-Amz-Date")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-Date", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-Credential")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Credential", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-Security-Token")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Security-Token", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Algorithm")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Algorithm", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-SignedHeaders", valid_611723
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_611724 = formData.getOrDefault("Instances")
  valid_611724 = validateParameter(valid_611724, JArray, required = true, default = nil)
  if valid_611724 != nil:
    section.add "Instances", valid_611724
  var valid_611725 = formData.getOrDefault("LoadBalancerName")
  valid_611725 = validateParameter(valid_611725, JString, required = true,
                                 default = nil)
  if valid_611725 != nil:
    section.add "LoadBalancerName", valid_611725
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611726: Call_PostDeregisterInstancesFromLoadBalancer_611712;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611726.validator(path, query, header, formData, body)
  let scheme = call_611726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611726.url(scheme.get, call_611726.host, call_611726.base,
                         call_611726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611726, url, valid)

proc call*(call_611727: Call_PostDeregisterInstancesFromLoadBalancer_611712;
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
  var query_611728 = newJObject()
  var formData_611729 = newJObject()
  if Instances != nil:
    formData_611729.add "Instances", Instances
  add(formData_611729, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611728, "Action", newJString(Action))
  add(query_611728, "Version", newJString(Version))
  result = call_611727.call(nil, query_611728, nil, formData_611729, nil)

var postDeregisterInstancesFromLoadBalancer* = Call_PostDeregisterInstancesFromLoadBalancer_611712(
    name: "postDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_PostDeregisterInstancesFromLoadBalancer_611713, base: "/",
    url: url_PostDeregisterInstancesFromLoadBalancer_611714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterInstancesFromLoadBalancer_611695 = ref object of OpenApiRestCall_610658
proc url_GetDeregisterInstancesFromLoadBalancer_611697(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeregisterInstancesFromLoadBalancer_611696(path: JsonNode;
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
  var valid_611698 = query.getOrDefault("LoadBalancerName")
  valid_611698 = validateParameter(valid_611698, JString, required = true,
                                 default = nil)
  if valid_611698 != nil:
    section.add "LoadBalancerName", valid_611698
  var valid_611699 = query.getOrDefault("Action")
  valid_611699 = validateParameter(valid_611699, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_611699 != nil:
    section.add "Action", valid_611699
  var valid_611700 = query.getOrDefault("Instances")
  valid_611700 = validateParameter(valid_611700, JArray, required = true, default = nil)
  if valid_611700 != nil:
    section.add "Instances", valid_611700
  var valid_611701 = query.getOrDefault("Version")
  valid_611701 = validateParameter(valid_611701, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611701 != nil:
    section.add "Version", valid_611701
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
  var valid_611702 = header.getOrDefault("X-Amz-Signature")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-Signature", valid_611702
  var valid_611703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611703 = validateParameter(valid_611703, JString, required = false,
                                 default = nil)
  if valid_611703 != nil:
    section.add "X-Amz-Content-Sha256", valid_611703
  var valid_611704 = header.getOrDefault("X-Amz-Date")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "X-Amz-Date", valid_611704
  var valid_611705 = header.getOrDefault("X-Amz-Credential")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Credential", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-Security-Token")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Security-Token", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Algorithm")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Algorithm", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-SignedHeaders", valid_611708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611709: Call_GetDeregisterInstancesFromLoadBalancer_611695;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611709.validator(path, query, header, formData, body)
  let scheme = call_611709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611709.url(scheme.get, call_611709.host, call_611709.base,
                         call_611709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611709, url, valid)

proc call*(call_611710: Call_GetDeregisterInstancesFromLoadBalancer_611695;
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
  var query_611711 = newJObject()
  add(query_611711, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611711, "Action", newJString(Action))
  if Instances != nil:
    query_611711.add "Instances", Instances
  add(query_611711, "Version", newJString(Version))
  result = call_611710.call(nil, query_611711, nil, nil, nil)

var getDeregisterInstancesFromLoadBalancer* = Call_GetDeregisterInstancesFromLoadBalancer_611695(
    name: "getDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_GetDeregisterInstancesFromLoadBalancer_611696, base: "/",
    url: url_GetDeregisterInstancesFromLoadBalancer_611697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_611747 = ref object of OpenApiRestCall_610658
proc url_PostDescribeAccountLimits_611749(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAccountLimits_611748(path: JsonNode; query: JsonNode;
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
  var valid_611750 = query.getOrDefault("Action")
  valid_611750 = validateParameter(valid_611750, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_611750 != nil:
    section.add "Action", valid_611750
  var valid_611751 = query.getOrDefault("Version")
  valid_611751 = validateParameter(valid_611751, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611751 != nil:
    section.add "Version", valid_611751
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
  var valid_611752 = header.getOrDefault("X-Amz-Signature")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-Signature", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-Content-Sha256", valid_611753
  var valid_611754 = header.getOrDefault("X-Amz-Date")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-Date", valid_611754
  var valid_611755 = header.getOrDefault("X-Amz-Credential")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-Credential", valid_611755
  var valid_611756 = header.getOrDefault("X-Amz-Security-Token")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Security-Token", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Algorithm")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Algorithm", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-SignedHeaders", valid_611758
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_611759 = formData.getOrDefault("Marker")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "Marker", valid_611759
  var valid_611760 = formData.getOrDefault("PageSize")
  valid_611760 = validateParameter(valid_611760, JInt, required = false, default = nil)
  if valid_611760 != nil:
    section.add "PageSize", valid_611760
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611761: Call_PostDescribeAccountLimits_611747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611761.validator(path, query, header, formData, body)
  let scheme = call_611761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611761.url(scheme.get, call_611761.host, call_611761.base,
                         call_611761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611761, url, valid)

proc call*(call_611762: Call_PostDescribeAccountLimits_611747; Marker: string = "";
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
  var query_611763 = newJObject()
  var formData_611764 = newJObject()
  add(formData_611764, "Marker", newJString(Marker))
  add(query_611763, "Action", newJString(Action))
  add(formData_611764, "PageSize", newJInt(PageSize))
  add(query_611763, "Version", newJString(Version))
  result = call_611762.call(nil, query_611763, nil, formData_611764, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_611747(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_611748, base: "/",
    url: url_PostDescribeAccountLimits_611749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_611730 = ref object of OpenApiRestCall_610658
proc url_GetDescribeAccountLimits_611732(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAccountLimits_611731(path: JsonNode; query: JsonNode;
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
  var valid_611733 = query.getOrDefault("Marker")
  valid_611733 = validateParameter(valid_611733, JString, required = false,
                                 default = nil)
  if valid_611733 != nil:
    section.add "Marker", valid_611733
  var valid_611734 = query.getOrDefault("PageSize")
  valid_611734 = validateParameter(valid_611734, JInt, required = false, default = nil)
  if valid_611734 != nil:
    section.add "PageSize", valid_611734
  var valid_611735 = query.getOrDefault("Action")
  valid_611735 = validateParameter(valid_611735, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_611735 != nil:
    section.add "Action", valid_611735
  var valid_611736 = query.getOrDefault("Version")
  valid_611736 = validateParameter(valid_611736, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611736 != nil:
    section.add "Version", valid_611736
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
  var valid_611737 = header.getOrDefault("X-Amz-Signature")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-Signature", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-Content-Sha256", valid_611738
  var valid_611739 = header.getOrDefault("X-Amz-Date")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Date", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-Credential")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Credential", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Security-Token")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Security-Token", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Algorithm")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Algorithm", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-SignedHeaders", valid_611743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611744: Call_GetDescribeAccountLimits_611730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_611744.validator(path, query, header, formData, body)
  let scheme = call_611744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611744.url(scheme.get, call_611744.host, call_611744.base,
                         call_611744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611744, url, valid)

proc call*(call_611745: Call_GetDescribeAccountLimits_611730; Marker: string = "";
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
  var query_611746 = newJObject()
  add(query_611746, "Marker", newJString(Marker))
  add(query_611746, "PageSize", newJInt(PageSize))
  add(query_611746, "Action", newJString(Action))
  add(query_611746, "Version", newJString(Version))
  result = call_611745.call(nil, query_611746, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_611730(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_611731, base: "/",
    url: url_GetDescribeAccountLimits_611732, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstanceHealth_611782 = ref object of OpenApiRestCall_610658
proc url_PostDescribeInstanceHealth_611784(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeInstanceHealth_611783(path: JsonNode; query: JsonNode;
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
  var valid_611785 = query.getOrDefault("Action")
  valid_611785 = validateParameter(valid_611785, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_611785 != nil:
    section.add "Action", valid_611785
  var valid_611786 = query.getOrDefault("Version")
  valid_611786 = validateParameter(valid_611786, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611786 != nil:
    section.add "Version", valid_611786
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
  var valid_611787 = header.getOrDefault("X-Amz-Signature")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "X-Amz-Signature", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-Content-Sha256", valid_611788
  var valid_611789 = header.getOrDefault("X-Amz-Date")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-Date", valid_611789
  var valid_611790 = header.getOrDefault("X-Amz-Credential")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-Credential", valid_611790
  var valid_611791 = header.getOrDefault("X-Amz-Security-Token")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Security-Token", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-Algorithm")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-Algorithm", valid_611792
  var valid_611793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-SignedHeaders", valid_611793
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_611794 = formData.getOrDefault("Instances")
  valid_611794 = validateParameter(valid_611794, JArray, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "Instances", valid_611794
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_611795 = formData.getOrDefault("LoadBalancerName")
  valid_611795 = validateParameter(valid_611795, JString, required = true,
                                 default = nil)
  if valid_611795 != nil:
    section.add "LoadBalancerName", valid_611795
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611796: Call_PostDescribeInstanceHealth_611782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_611796.validator(path, query, header, formData, body)
  let scheme = call_611796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611796.url(scheme.get, call_611796.host, call_611796.base,
                         call_611796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611796, url, valid)

proc call*(call_611797: Call_PostDescribeInstanceHealth_611782;
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
  var query_611798 = newJObject()
  var formData_611799 = newJObject()
  if Instances != nil:
    formData_611799.add "Instances", Instances
  add(formData_611799, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611798, "Action", newJString(Action))
  add(query_611798, "Version", newJString(Version))
  result = call_611797.call(nil, query_611798, nil, formData_611799, nil)

var postDescribeInstanceHealth* = Call_PostDescribeInstanceHealth_611782(
    name: "postDescribeInstanceHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_PostDescribeInstanceHealth_611783, base: "/",
    url: url_PostDescribeInstanceHealth_611784,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstanceHealth_611765 = ref object of OpenApiRestCall_610658
proc url_GetDescribeInstanceHealth_611767(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeInstanceHealth_611766(path: JsonNode; query: JsonNode;
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
  var valid_611768 = query.getOrDefault("LoadBalancerName")
  valid_611768 = validateParameter(valid_611768, JString, required = true,
                                 default = nil)
  if valid_611768 != nil:
    section.add "LoadBalancerName", valid_611768
  var valid_611769 = query.getOrDefault("Action")
  valid_611769 = validateParameter(valid_611769, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_611769 != nil:
    section.add "Action", valid_611769
  var valid_611770 = query.getOrDefault("Instances")
  valid_611770 = validateParameter(valid_611770, JArray, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "Instances", valid_611770
  var valid_611771 = query.getOrDefault("Version")
  valid_611771 = validateParameter(valid_611771, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611771 != nil:
    section.add "Version", valid_611771
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
  var valid_611772 = header.getOrDefault("X-Amz-Signature")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Signature", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-Content-Sha256", valid_611773
  var valid_611774 = header.getOrDefault("X-Amz-Date")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-Date", valid_611774
  var valid_611775 = header.getOrDefault("X-Amz-Credential")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-Credential", valid_611775
  var valid_611776 = header.getOrDefault("X-Amz-Security-Token")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-Security-Token", valid_611776
  var valid_611777 = header.getOrDefault("X-Amz-Algorithm")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Algorithm", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-SignedHeaders", valid_611778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611779: Call_GetDescribeInstanceHealth_611765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_611779.validator(path, query, header, formData, body)
  let scheme = call_611779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611779.url(scheme.get, call_611779.host, call_611779.base,
                         call_611779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611779, url, valid)

proc call*(call_611780: Call_GetDescribeInstanceHealth_611765;
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
  var query_611781 = newJObject()
  add(query_611781, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611781, "Action", newJString(Action))
  if Instances != nil:
    query_611781.add "Instances", Instances
  add(query_611781, "Version", newJString(Version))
  result = call_611780.call(nil, query_611781, nil, nil, nil)

var getDescribeInstanceHealth* = Call_GetDescribeInstanceHealth_611765(
    name: "getDescribeInstanceHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_GetDescribeInstanceHealth_611766, base: "/",
    url: url_GetDescribeInstanceHealth_611767,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_611816 = ref object of OpenApiRestCall_610658
proc url_PostDescribeLoadBalancerAttributes_611818(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancerAttributes_611817(path: JsonNode;
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
  var valid_611819 = query.getOrDefault("Action")
  valid_611819 = validateParameter(valid_611819, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_611819 != nil:
    section.add "Action", valid_611819
  var valid_611820 = query.getOrDefault("Version")
  valid_611820 = validateParameter(valid_611820, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611820 != nil:
    section.add "Version", valid_611820
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
  var valid_611821 = header.getOrDefault("X-Amz-Signature")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "X-Amz-Signature", valid_611821
  var valid_611822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "X-Amz-Content-Sha256", valid_611822
  var valid_611823 = header.getOrDefault("X-Amz-Date")
  valid_611823 = validateParameter(valid_611823, JString, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "X-Amz-Date", valid_611823
  var valid_611824 = header.getOrDefault("X-Amz-Credential")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "X-Amz-Credential", valid_611824
  var valid_611825 = header.getOrDefault("X-Amz-Security-Token")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Security-Token", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-Algorithm")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Algorithm", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-SignedHeaders", valid_611827
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_611828 = formData.getOrDefault("LoadBalancerName")
  valid_611828 = validateParameter(valid_611828, JString, required = true,
                                 default = nil)
  if valid_611828 != nil:
    section.add "LoadBalancerName", valid_611828
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611829: Call_PostDescribeLoadBalancerAttributes_611816;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_611829.validator(path, query, header, formData, body)
  let scheme = call_611829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611829.url(scheme.get, call_611829.host, call_611829.base,
                         call_611829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611829, url, valid)

proc call*(call_611830: Call_PostDescribeLoadBalancerAttributes_611816;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611831 = newJObject()
  var formData_611832 = newJObject()
  add(formData_611832, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611831, "Action", newJString(Action))
  add(query_611831, "Version", newJString(Version))
  result = call_611830.call(nil, query_611831, nil, formData_611832, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_611816(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_611817, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_611818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_611800 = ref object of OpenApiRestCall_610658
proc url_GetDescribeLoadBalancerAttributes_611802(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancerAttributes_611801(path: JsonNode;
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
  var valid_611803 = query.getOrDefault("LoadBalancerName")
  valid_611803 = validateParameter(valid_611803, JString, required = true,
                                 default = nil)
  if valid_611803 != nil:
    section.add "LoadBalancerName", valid_611803
  var valid_611804 = query.getOrDefault("Action")
  valid_611804 = validateParameter(valid_611804, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_611804 != nil:
    section.add "Action", valid_611804
  var valid_611805 = query.getOrDefault("Version")
  valid_611805 = validateParameter(valid_611805, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611805 != nil:
    section.add "Version", valid_611805
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
  var valid_611806 = header.getOrDefault("X-Amz-Signature")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-Signature", valid_611806
  var valid_611807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-Content-Sha256", valid_611807
  var valid_611808 = header.getOrDefault("X-Amz-Date")
  valid_611808 = validateParameter(valid_611808, JString, required = false,
                                 default = nil)
  if valid_611808 != nil:
    section.add "X-Amz-Date", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Credential")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Credential", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-Security-Token")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Security-Token", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Algorithm")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Algorithm", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-SignedHeaders", valid_611812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611813: Call_GetDescribeLoadBalancerAttributes_611800;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_611813.validator(path, query, header, formData, body)
  let scheme = call_611813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611813.url(scheme.get, call_611813.host, call_611813.base,
                         call_611813.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611813, url, valid)

proc call*(call_611814: Call_GetDescribeLoadBalancerAttributes_611800;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611815 = newJObject()
  add(query_611815, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611815, "Action", newJString(Action))
  add(query_611815, "Version", newJString(Version))
  result = call_611814.call(nil, query_611815, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_611800(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_611801, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_611802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicies_611850 = ref object of OpenApiRestCall_610658
proc url_PostDescribeLoadBalancerPolicies_611852(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancerPolicies_611851(path: JsonNode;
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
  var valid_611853 = query.getOrDefault("Action")
  valid_611853 = validateParameter(valid_611853, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_611853 != nil:
    section.add "Action", valid_611853
  var valid_611854 = query.getOrDefault("Version")
  valid_611854 = validateParameter(valid_611854, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611854 != nil:
    section.add "Version", valid_611854
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
  var valid_611855 = header.getOrDefault("X-Amz-Signature")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-Signature", valid_611855
  var valid_611856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "X-Amz-Content-Sha256", valid_611856
  var valid_611857 = header.getOrDefault("X-Amz-Date")
  valid_611857 = validateParameter(valid_611857, JString, required = false,
                                 default = nil)
  if valid_611857 != nil:
    section.add "X-Amz-Date", valid_611857
  var valid_611858 = header.getOrDefault("X-Amz-Credential")
  valid_611858 = validateParameter(valid_611858, JString, required = false,
                                 default = nil)
  if valid_611858 != nil:
    section.add "X-Amz-Credential", valid_611858
  var valid_611859 = header.getOrDefault("X-Amz-Security-Token")
  valid_611859 = validateParameter(valid_611859, JString, required = false,
                                 default = nil)
  if valid_611859 != nil:
    section.add "X-Amz-Security-Token", valid_611859
  var valid_611860 = header.getOrDefault("X-Amz-Algorithm")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-Algorithm", valid_611860
  var valid_611861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611861 = validateParameter(valid_611861, JString, required = false,
                                 default = nil)
  if valid_611861 != nil:
    section.add "X-Amz-SignedHeaders", valid_611861
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   LoadBalancerName: JString
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_611862 = formData.getOrDefault("PolicyNames")
  valid_611862 = validateParameter(valid_611862, JArray, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "PolicyNames", valid_611862
  var valid_611863 = formData.getOrDefault("LoadBalancerName")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "LoadBalancerName", valid_611863
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611864: Call_PostDescribeLoadBalancerPolicies_611850;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_611864.validator(path, query, header, formData, body)
  let scheme = call_611864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611864.url(scheme.get, call_611864.host, call_611864.base,
                         call_611864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611864, url, valid)

proc call*(call_611865: Call_PostDescribeLoadBalancerPolicies_611850;
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
  var query_611866 = newJObject()
  var formData_611867 = newJObject()
  if PolicyNames != nil:
    formData_611867.add "PolicyNames", PolicyNames
  add(formData_611867, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611866, "Action", newJString(Action))
  add(query_611866, "Version", newJString(Version))
  result = call_611865.call(nil, query_611866, nil, formData_611867, nil)

var postDescribeLoadBalancerPolicies* = Call_PostDescribeLoadBalancerPolicies_611850(
    name: "postDescribeLoadBalancerPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_PostDescribeLoadBalancerPolicies_611851, base: "/",
    url: url_PostDescribeLoadBalancerPolicies_611852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicies_611833 = ref object of OpenApiRestCall_610658
proc url_GetDescribeLoadBalancerPolicies_611835(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancerPolicies_611834(path: JsonNode;
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
  var valid_611836 = query.getOrDefault("LoadBalancerName")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "LoadBalancerName", valid_611836
  var valid_611837 = query.getOrDefault("Action")
  valid_611837 = validateParameter(valid_611837, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_611837 != nil:
    section.add "Action", valid_611837
  var valid_611838 = query.getOrDefault("Version")
  valid_611838 = validateParameter(valid_611838, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611838 != nil:
    section.add "Version", valid_611838
  var valid_611839 = query.getOrDefault("PolicyNames")
  valid_611839 = validateParameter(valid_611839, JArray, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "PolicyNames", valid_611839
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
  var valid_611840 = header.getOrDefault("X-Amz-Signature")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "X-Amz-Signature", valid_611840
  var valid_611841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611841 = validateParameter(valid_611841, JString, required = false,
                                 default = nil)
  if valid_611841 != nil:
    section.add "X-Amz-Content-Sha256", valid_611841
  var valid_611842 = header.getOrDefault("X-Amz-Date")
  valid_611842 = validateParameter(valid_611842, JString, required = false,
                                 default = nil)
  if valid_611842 != nil:
    section.add "X-Amz-Date", valid_611842
  var valid_611843 = header.getOrDefault("X-Amz-Credential")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-Credential", valid_611843
  var valid_611844 = header.getOrDefault("X-Amz-Security-Token")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Security-Token", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-Algorithm")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-Algorithm", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-SignedHeaders", valid_611846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611847: Call_GetDescribeLoadBalancerPolicies_611833;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_611847.validator(path, query, header, formData, body)
  let scheme = call_611847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611847.url(scheme.get, call_611847.host, call_611847.base,
                         call_611847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611847, url, valid)

proc call*(call_611848: Call_GetDescribeLoadBalancerPolicies_611833;
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
  var query_611849 = newJObject()
  add(query_611849, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611849, "Action", newJString(Action))
  add(query_611849, "Version", newJString(Version))
  if PolicyNames != nil:
    query_611849.add "PolicyNames", PolicyNames
  result = call_611848.call(nil, query_611849, nil, nil, nil)

var getDescribeLoadBalancerPolicies* = Call_GetDescribeLoadBalancerPolicies_611833(
    name: "getDescribeLoadBalancerPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_GetDescribeLoadBalancerPolicies_611834, base: "/",
    url: url_GetDescribeLoadBalancerPolicies_611835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicyTypes_611884 = ref object of OpenApiRestCall_610658
proc url_PostDescribeLoadBalancerPolicyTypes_611886(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancerPolicyTypes_611885(path: JsonNode;
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
  var valid_611887 = query.getOrDefault("Action")
  valid_611887 = validateParameter(valid_611887, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_611887 != nil:
    section.add "Action", valid_611887
  var valid_611888 = query.getOrDefault("Version")
  valid_611888 = validateParameter(valid_611888, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611888 != nil:
    section.add "Version", valid_611888
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
  var valid_611889 = header.getOrDefault("X-Amz-Signature")
  valid_611889 = validateParameter(valid_611889, JString, required = false,
                                 default = nil)
  if valid_611889 != nil:
    section.add "X-Amz-Signature", valid_611889
  var valid_611890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611890 = validateParameter(valid_611890, JString, required = false,
                                 default = nil)
  if valid_611890 != nil:
    section.add "X-Amz-Content-Sha256", valid_611890
  var valid_611891 = header.getOrDefault("X-Amz-Date")
  valid_611891 = validateParameter(valid_611891, JString, required = false,
                                 default = nil)
  if valid_611891 != nil:
    section.add "X-Amz-Date", valid_611891
  var valid_611892 = header.getOrDefault("X-Amz-Credential")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Credential", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-Security-Token")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Security-Token", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Algorithm")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Algorithm", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-SignedHeaders", valid_611895
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  section = newJObject()
  var valid_611896 = formData.getOrDefault("PolicyTypeNames")
  valid_611896 = validateParameter(valid_611896, JArray, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "PolicyTypeNames", valid_611896
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611897: Call_PostDescribeLoadBalancerPolicyTypes_611884;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_611897.validator(path, query, header, formData, body)
  let scheme = call_611897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611897.url(scheme.get, call_611897.host, call_611897.base,
                         call_611897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611897, url, valid)

proc call*(call_611898: Call_PostDescribeLoadBalancerPolicyTypes_611884;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611899 = newJObject()
  var formData_611900 = newJObject()
  if PolicyTypeNames != nil:
    formData_611900.add "PolicyTypeNames", PolicyTypeNames
  add(query_611899, "Action", newJString(Action))
  add(query_611899, "Version", newJString(Version))
  result = call_611898.call(nil, query_611899, nil, formData_611900, nil)

var postDescribeLoadBalancerPolicyTypes* = Call_PostDescribeLoadBalancerPolicyTypes_611884(
    name: "postDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_PostDescribeLoadBalancerPolicyTypes_611885, base: "/",
    url: url_PostDescribeLoadBalancerPolicyTypes_611886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicyTypes_611868 = ref object of OpenApiRestCall_610658
proc url_GetDescribeLoadBalancerPolicyTypes_611870(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancerPolicyTypes_611869(path: JsonNode;
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
  var valid_611871 = query.getOrDefault("PolicyTypeNames")
  valid_611871 = validateParameter(valid_611871, JArray, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "PolicyTypeNames", valid_611871
  var valid_611872 = query.getOrDefault("Action")
  valid_611872 = validateParameter(valid_611872, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_611872 != nil:
    section.add "Action", valid_611872
  var valid_611873 = query.getOrDefault("Version")
  valid_611873 = validateParameter(valid_611873, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611873 != nil:
    section.add "Version", valid_611873
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
  var valid_611874 = header.getOrDefault("X-Amz-Signature")
  valid_611874 = validateParameter(valid_611874, JString, required = false,
                                 default = nil)
  if valid_611874 != nil:
    section.add "X-Amz-Signature", valid_611874
  var valid_611875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611875 = validateParameter(valid_611875, JString, required = false,
                                 default = nil)
  if valid_611875 != nil:
    section.add "X-Amz-Content-Sha256", valid_611875
  var valid_611876 = header.getOrDefault("X-Amz-Date")
  valid_611876 = validateParameter(valid_611876, JString, required = false,
                                 default = nil)
  if valid_611876 != nil:
    section.add "X-Amz-Date", valid_611876
  var valid_611877 = header.getOrDefault("X-Amz-Credential")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Credential", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-Security-Token")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Security-Token", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Algorithm")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Algorithm", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-SignedHeaders", valid_611880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611881: Call_GetDescribeLoadBalancerPolicyTypes_611868;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_611881.validator(path, query, header, formData, body)
  let scheme = call_611881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611881.url(scheme.get, call_611881.host, call_611881.base,
                         call_611881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611881, url, valid)

proc call*(call_611882: Call_GetDescribeLoadBalancerPolicyTypes_611868;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611883 = newJObject()
  if PolicyTypeNames != nil:
    query_611883.add "PolicyTypeNames", PolicyTypeNames
  add(query_611883, "Action", newJString(Action))
  add(query_611883, "Version", newJString(Version))
  result = call_611882.call(nil, query_611883, nil, nil, nil)

var getDescribeLoadBalancerPolicyTypes* = Call_GetDescribeLoadBalancerPolicyTypes_611868(
    name: "getDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_GetDescribeLoadBalancerPolicyTypes_611869, base: "/",
    url: url_GetDescribeLoadBalancerPolicyTypes_611870,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_611919 = ref object of OpenApiRestCall_610658
proc url_PostDescribeLoadBalancers_611921(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeLoadBalancers_611920(path: JsonNode; query: JsonNode;
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
  var valid_611922 = query.getOrDefault("Action")
  valid_611922 = validateParameter(valid_611922, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_611922 != nil:
    section.add "Action", valid_611922
  var valid_611923 = query.getOrDefault("Version")
  valid_611923 = validateParameter(valid_611923, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611923 != nil:
    section.add "Version", valid_611923
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
  var valid_611924 = header.getOrDefault("X-Amz-Signature")
  valid_611924 = validateParameter(valid_611924, JString, required = false,
                                 default = nil)
  if valid_611924 != nil:
    section.add "X-Amz-Signature", valid_611924
  var valid_611925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Content-Sha256", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Date")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Date", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-Credential")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-Credential", valid_611927
  var valid_611928 = header.getOrDefault("X-Amz-Security-Token")
  valid_611928 = validateParameter(valid_611928, JString, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "X-Amz-Security-Token", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-Algorithm")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-Algorithm", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-SignedHeaders", valid_611930
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  section = newJObject()
  var valid_611931 = formData.getOrDefault("LoadBalancerNames")
  valid_611931 = validateParameter(valid_611931, JArray, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "LoadBalancerNames", valid_611931
  var valid_611932 = formData.getOrDefault("Marker")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "Marker", valid_611932
  var valid_611933 = formData.getOrDefault("PageSize")
  valid_611933 = validateParameter(valid_611933, JInt, required = false, default = nil)
  if valid_611933 != nil:
    section.add "PageSize", valid_611933
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611934: Call_PostDescribeLoadBalancers_611919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_611934.validator(path, query, header, formData, body)
  let scheme = call_611934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611934.url(scheme.get, call_611934.host, call_611934.base,
                         call_611934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611934, url, valid)

proc call*(call_611935: Call_PostDescribeLoadBalancers_611919;
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
  var query_611936 = newJObject()
  var formData_611937 = newJObject()
  if LoadBalancerNames != nil:
    formData_611937.add "LoadBalancerNames", LoadBalancerNames
  add(formData_611937, "Marker", newJString(Marker))
  add(query_611936, "Action", newJString(Action))
  add(formData_611937, "PageSize", newJInt(PageSize))
  add(query_611936, "Version", newJString(Version))
  result = call_611935.call(nil, query_611936, nil, formData_611937, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_611919(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_611920, base: "/",
    url: url_PostDescribeLoadBalancers_611921,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_611901 = ref object of OpenApiRestCall_610658
proc url_GetDescribeLoadBalancers_611903(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeLoadBalancers_611902(path: JsonNode; query: JsonNode;
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
  var valid_611904 = query.getOrDefault("Marker")
  valid_611904 = validateParameter(valid_611904, JString, required = false,
                                 default = nil)
  if valid_611904 != nil:
    section.add "Marker", valid_611904
  var valid_611905 = query.getOrDefault("PageSize")
  valid_611905 = validateParameter(valid_611905, JInt, required = false, default = nil)
  if valid_611905 != nil:
    section.add "PageSize", valid_611905
  var valid_611906 = query.getOrDefault("Action")
  valid_611906 = validateParameter(valid_611906, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_611906 != nil:
    section.add "Action", valid_611906
  var valid_611907 = query.getOrDefault("Version")
  valid_611907 = validateParameter(valid_611907, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611907 != nil:
    section.add "Version", valid_611907
  var valid_611908 = query.getOrDefault("LoadBalancerNames")
  valid_611908 = validateParameter(valid_611908, JArray, required = false,
                                 default = nil)
  if valid_611908 != nil:
    section.add "LoadBalancerNames", valid_611908
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
  var valid_611909 = header.getOrDefault("X-Amz-Signature")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "X-Amz-Signature", valid_611909
  var valid_611910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Content-Sha256", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Date")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Date", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-Credential")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Credential", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Security-Token")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Security-Token", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-Algorithm")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Algorithm", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-SignedHeaders", valid_611915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611916: Call_GetDescribeLoadBalancers_611901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_611916.validator(path, query, header, formData, body)
  let scheme = call_611916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611916.url(scheme.get, call_611916.host, call_611916.base,
                         call_611916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611916, url, valid)

proc call*(call_611917: Call_GetDescribeLoadBalancers_611901; Marker: string = "";
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
  var query_611918 = newJObject()
  add(query_611918, "Marker", newJString(Marker))
  add(query_611918, "PageSize", newJInt(PageSize))
  add(query_611918, "Action", newJString(Action))
  add(query_611918, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_611918.add "LoadBalancerNames", LoadBalancerNames
  result = call_611917.call(nil, query_611918, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_611901(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_611902, base: "/",
    url: url_GetDescribeLoadBalancers_611903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_611954 = ref object of OpenApiRestCall_610658
proc url_PostDescribeTags_611956(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeTags_611955(path: JsonNode; query: JsonNode;
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
  var valid_611957 = query.getOrDefault("Action")
  valid_611957 = validateParameter(valid_611957, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_611957 != nil:
    section.add "Action", valid_611957
  var valid_611958 = query.getOrDefault("Version")
  valid_611958 = validateParameter(valid_611958, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611958 != nil:
    section.add "Version", valid_611958
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
  var valid_611959 = header.getOrDefault("X-Amz-Signature")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Signature", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Content-Sha256", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Date")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Date", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-Credential")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-Credential", valid_611962
  var valid_611963 = header.getOrDefault("X-Amz-Security-Token")
  valid_611963 = validateParameter(valid_611963, JString, required = false,
                                 default = nil)
  if valid_611963 != nil:
    section.add "X-Amz-Security-Token", valid_611963
  var valid_611964 = header.getOrDefault("X-Amz-Algorithm")
  valid_611964 = validateParameter(valid_611964, JString, required = false,
                                 default = nil)
  if valid_611964 != nil:
    section.add "X-Amz-Algorithm", valid_611964
  var valid_611965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "X-Amz-SignedHeaders", valid_611965
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_611966 = formData.getOrDefault("LoadBalancerNames")
  valid_611966 = validateParameter(valid_611966, JArray, required = true, default = nil)
  if valid_611966 != nil:
    section.add "LoadBalancerNames", valid_611966
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611967: Call_PostDescribeTags_611954; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_611967.validator(path, query, header, formData, body)
  let scheme = call_611967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611967.url(scheme.get, call_611967.host, call_611967.base,
                         call_611967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611967, url, valid)

proc call*(call_611968: Call_PostDescribeTags_611954; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611969 = newJObject()
  var formData_611970 = newJObject()
  if LoadBalancerNames != nil:
    formData_611970.add "LoadBalancerNames", LoadBalancerNames
  add(query_611969, "Action", newJString(Action))
  add(query_611969, "Version", newJString(Version))
  result = call_611968.call(nil, query_611969, nil, formData_611970, nil)

var postDescribeTags* = Call_PostDescribeTags_611954(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_611955,
    base: "/", url: url_PostDescribeTags_611956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_611938 = ref object of OpenApiRestCall_610658
proc url_GetDescribeTags_611940(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeTags_611939(path: JsonNode; query: JsonNode;
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
  var valid_611941 = query.getOrDefault("Action")
  valid_611941 = validateParameter(valid_611941, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_611941 != nil:
    section.add "Action", valid_611941
  var valid_611942 = query.getOrDefault("Version")
  valid_611942 = validateParameter(valid_611942, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611942 != nil:
    section.add "Version", valid_611942
  var valid_611943 = query.getOrDefault("LoadBalancerNames")
  valid_611943 = validateParameter(valid_611943, JArray, required = true, default = nil)
  if valid_611943 != nil:
    section.add "LoadBalancerNames", valid_611943
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
  var valid_611944 = header.getOrDefault("X-Amz-Signature")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Signature", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Content-Sha256", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Date")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Date", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-Credential")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-Credential", valid_611947
  var valid_611948 = header.getOrDefault("X-Amz-Security-Token")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-Security-Token", valid_611948
  var valid_611949 = header.getOrDefault("X-Amz-Algorithm")
  valid_611949 = validateParameter(valid_611949, JString, required = false,
                                 default = nil)
  if valid_611949 != nil:
    section.add "X-Amz-Algorithm", valid_611949
  var valid_611950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "X-Amz-SignedHeaders", valid_611950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611951: Call_GetDescribeTags_611938; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_611951.validator(path, query, header, formData, body)
  let scheme = call_611951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611951.url(scheme.get, call_611951.host, call_611951.base,
                         call_611951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611951, url, valid)

proc call*(call_611952: Call_GetDescribeTags_611938; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  var query_611953 = newJObject()
  add(query_611953, "Action", newJString(Action))
  add(query_611953, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_611953.add "LoadBalancerNames", LoadBalancerNames
  result = call_611952.call(nil, query_611953, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_611938(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_611939,
    base: "/", url: url_GetDescribeTags_611940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDetachLoadBalancerFromSubnets_611988 = ref object of OpenApiRestCall_610658
proc url_PostDetachLoadBalancerFromSubnets_611990(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDetachLoadBalancerFromSubnets_611989(path: JsonNode;
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
  var valid_611991 = query.getOrDefault("Action")
  valid_611991 = validateParameter(valid_611991, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_611991 != nil:
    section.add "Action", valid_611991
  var valid_611992 = query.getOrDefault("Version")
  valid_611992 = validateParameter(valid_611992, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611992 != nil:
    section.add "Version", valid_611992
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
  var valid_611993 = header.getOrDefault("X-Amz-Signature")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Signature", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-Content-Sha256", valid_611994
  var valid_611995 = header.getOrDefault("X-Amz-Date")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-Date", valid_611995
  var valid_611996 = header.getOrDefault("X-Amz-Credential")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "X-Amz-Credential", valid_611996
  var valid_611997 = header.getOrDefault("X-Amz-Security-Token")
  valid_611997 = validateParameter(valid_611997, JString, required = false,
                                 default = nil)
  if valid_611997 != nil:
    section.add "X-Amz-Security-Token", valid_611997
  var valid_611998 = header.getOrDefault("X-Amz-Algorithm")
  valid_611998 = validateParameter(valid_611998, JString, required = false,
                                 default = nil)
  if valid_611998 != nil:
    section.add "X-Amz-Algorithm", valid_611998
  var valid_611999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611999 = validateParameter(valid_611999, JString, required = false,
                                 default = nil)
  if valid_611999 != nil:
    section.add "X-Amz-SignedHeaders", valid_611999
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_612000 = formData.getOrDefault("Subnets")
  valid_612000 = validateParameter(valid_612000, JArray, required = true, default = nil)
  if valid_612000 != nil:
    section.add "Subnets", valid_612000
  var valid_612001 = formData.getOrDefault("LoadBalancerName")
  valid_612001 = validateParameter(valid_612001, JString, required = true,
                                 default = nil)
  if valid_612001 != nil:
    section.add "LoadBalancerName", valid_612001
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612002: Call_PostDetachLoadBalancerFromSubnets_611988;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_612002.validator(path, query, header, formData, body)
  let scheme = call_612002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612002.url(scheme.get, call_612002.host, call_612002.base,
                         call_612002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612002, url, valid)

proc call*(call_612003: Call_PostDetachLoadBalancerFromSubnets_611988;
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
  var query_612004 = newJObject()
  var formData_612005 = newJObject()
  if Subnets != nil:
    formData_612005.add "Subnets", Subnets
  add(formData_612005, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612004, "Action", newJString(Action))
  add(query_612004, "Version", newJString(Version))
  result = call_612003.call(nil, query_612004, nil, formData_612005, nil)

var postDetachLoadBalancerFromSubnets* = Call_PostDetachLoadBalancerFromSubnets_611988(
    name: "postDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_PostDetachLoadBalancerFromSubnets_611989, base: "/",
    url: url_PostDetachLoadBalancerFromSubnets_611990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetachLoadBalancerFromSubnets_611971 = ref object of OpenApiRestCall_610658
proc url_GetDetachLoadBalancerFromSubnets_611973(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDetachLoadBalancerFromSubnets_611972(path: JsonNode;
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
  var valid_611974 = query.getOrDefault("LoadBalancerName")
  valid_611974 = validateParameter(valid_611974, JString, required = true,
                                 default = nil)
  if valid_611974 != nil:
    section.add "LoadBalancerName", valid_611974
  var valid_611975 = query.getOrDefault("Action")
  valid_611975 = validateParameter(valid_611975, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_611975 != nil:
    section.add "Action", valid_611975
  var valid_611976 = query.getOrDefault("Subnets")
  valid_611976 = validateParameter(valid_611976, JArray, required = true, default = nil)
  if valid_611976 != nil:
    section.add "Subnets", valid_611976
  var valid_611977 = query.getOrDefault("Version")
  valid_611977 = validateParameter(valid_611977, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_611977 != nil:
    section.add "Version", valid_611977
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
  var valid_611978 = header.getOrDefault("X-Amz-Signature")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-Signature", valid_611978
  var valid_611979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "X-Amz-Content-Sha256", valid_611979
  var valid_611980 = header.getOrDefault("X-Amz-Date")
  valid_611980 = validateParameter(valid_611980, JString, required = false,
                                 default = nil)
  if valid_611980 != nil:
    section.add "X-Amz-Date", valid_611980
  var valid_611981 = header.getOrDefault("X-Amz-Credential")
  valid_611981 = validateParameter(valid_611981, JString, required = false,
                                 default = nil)
  if valid_611981 != nil:
    section.add "X-Amz-Credential", valid_611981
  var valid_611982 = header.getOrDefault("X-Amz-Security-Token")
  valid_611982 = validateParameter(valid_611982, JString, required = false,
                                 default = nil)
  if valid_611982 != nil:
    section.add "X-Amz-Security-Token", valid_611982
  var valid_611983 = header.getOrDefault("X-Amz-Algorithm")
  valid_611983 = validateParameter(valid_611983, JString, required = false,
                                 default = nil)
  if valid_611983 != nil:
    section.add "X-Amz-Algorithm", valid_611983
  var valid_611984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611984 = validateParameter(valid_611984, JString, required = false,
                                 default = nil)
  if valid_611984 != nil:
    section.add "X-Amz-SignedHeaders", valid_611984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611985: Call_GetDetachLoadBalancerFromSubnets_611971;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_611985.validator(path, query, header, formData, body)
  let scheme = call_611985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611985.url(scheme.get, call_611985.host, call_611985.base,
                         call_611985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611985, url, valid)

proc call*(call_611986: Call_GetDetachLoadBalancerFromSubnets_611971;
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
  var query_611987 = newJObject()
  add(query_611987, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_611987, "Action", newJString(Action))
  if Subnets != nil:
    query_611987.add "Subnets", Subnets
  add(query_611987, "Version", newJString(Version))
  result = call_611986.call(nil, query_611987, nil, nil, nil)

var getDetachLoadBalancerFromSubnets* = Call_GetDetachLoadBalancerFromSubnets_611971(
    name: "getDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_GetDetachLoadBalancerFromSubnets_611972, base: "/",
    url: url_GetDetachLoadBalancerFromSubnets_611973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAvailabilityZonesForLoadBalancer_612023 = ref object of OpenApiRestCall_610658
proc url_PostDisableAvailabilityZonesForLoadBalancer_612025(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDisableAvailabilityZonesForLoadBalancer_612024(path: JsonNode;
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
  var valid_612026 = query.getOrDefault("Action")
  valid_612026 = validateParameter(valid_612026, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_612026 != nil:
    section.add "Action", valid_612026
  var valid_612027 = query.getOrDefault("Version")
  valid_612027 = validateParameter(valid_612027, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612027 != nil:
    section.add "Version", valid_612027
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
  var valid_612028 = header.getOrDefault("X-Amz-Signature")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-Signature", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-Content-Sha256", valid_612029
  var valid_612030 = header.getOrDefault("X-Amz-Date")
  valid_612030 = validateParameter(valid_612030, JString, required = false,
                                 default = nil)
  if valid_612030 != nil:
    section.add "X-Amz-Date", valid_612030
  var valid_612031 = header.getOrDefault("X-Amz-Credential")
  valid_612031 = validateParameter(valid_612031, JString, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "X-Amz-Credential", valid_612031
  var valid_612032 = header.getOrDefault("X-Amz-Security-Token")
  valid_612032 = validateParameter(valid_612032, JString, required = false,
                                 default = nil)
  if valid_612032 != nil:
    section.add "X-Amz-Security-Token", valid_612032
  var valid_612033 = header.getOrDefault("X-Amz-Algorithm")
  valid_612033 = validateParameter(valid_612033, JString, required = false,
                                 default = nil)
  if valid_612033 != nil:
    section.add "X-Amz-Algorithm", valid_612033
  var valid_612034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612034 = validateParameter(valid_612034, JString, required = false,
                                 default = nil)
  if valid_612034 != nil:
    section.add "X-Amz-SignedHeaders", valid_612034
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_612035 = formData.getOrDefault("AvailabilityZones")
  valid_612035 = validateParameter(valid_612035, JArray, required = true, default = nil)
  if valid_612035 != nil:
    section.add "AvailabilityZones", valid_612035
  var valid_612036 = formData.getOrDefault("LoadBalancerName")
  valid_612036 = validateParameter(valid_612036, JString, required = true,
                                 default = nil)
  if valid_612036 != nil:
    section.add "LoadBalancerName", valid_612036
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612037: Call_PostDisableAvailabilityZonesForLoadBalancer_612023;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_612037.validator(path, query, header, formData, body)
  let scheme = call_612037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612037.url(scheme.get, call_612037.host, call_612037.base,
                         call_612037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612037, url, valid)

proc call*(call_612038: Call_PostDisableAvailabilityZonesForLoadBalancer_612023;
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
  var query_612039 = newJObject()
  var formData_612040 = newJObject()
  if AvailabilityZones != nil:
    formData_612040.add "AvailabilityZones", AvailabilityZones
  add(formData_612040, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612039, "Action", newJString(Action))
  add(query_612039, "Version", newJString(Version))
  result = call_612038.call(nil, query_612039, nil, formData_612040, nil)

var postDisableAvailabilityZonesForLoadBalancer* = Call_PostDisableAvailabilityZonesForLoadBalancer_612023(
    name: "postDisableAvailabilityZonesForLoadBalancer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_PostDisableAvailabilityZonesForLoadBalancer_612024,
    base: "/", url: url_PostDisableAvailabilityZonesForLoadBalancer_612025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAvailabilityZonesForLoadBalancer_612006 = ref object of OpenApiRestCall_610658
proc url_GetDisableAvailabilityZonesForLoadBalancer_612008(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDisableAvailabilityZonesForLoadBalancer_612007(path: JsonNode;
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
  var valid_612009 = query.getOrDefault("AvailabilityZones")
  valid_612009 = validateParameter(valid_612009, JArray, required = true, default = nil)
  if valid_612009 != nil:
    section.add "AvailabilityZones", valid_612009
  var valid_612010 = query.getOrDefault("LoadBalancerName")
  valid_612010 = validateParameter(valid_612010, JString, required = true,
                                 default = nil)
  if valid_612010 != nil:
    section.add "LoadBalancerName", valid_612010
  var valid_612011 = query.getOrDefault("Action")
  valid_612011 = validateParameter(valid_612011, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_612011 != nil:
    section.add "Action", valid_612011
  var valid_612012 = query.getOrDefault("Version")
  valid_612012 = validateParameter(valid_612012, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612012 != nil:
    section.add "Version", valid_612012
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
  var valid_612013 = header.getOrDefault("X-Amz-Signature")
  valid_612013 = validateParameter(valid_612013, JString, required = false,
                                 default = nil)
  if valid_612013 != nil:
    section.add "X-Amz-Signature", valid_612013
  var valid_612014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612014 = validateParameter(valid_612014, JString, required = false,
                                 default = nil)
  if valid_612014 != nil:
    section.add "X-Amz-Content-Sha256", valid_612014
  var valid_612015 = header.getOrDefault("X-Amz-Date")
  valid_612015 = validateParameter(valid_612015, JString, required = false,
                                 default = nil)
  if valid_612015 != nil:
    section.add "X-Amz-Date", valid_612015
  var valid_612016 = header.getOrDefault("X-Amz-Credential")
  valid_612016 = validateParameter(valid_612016, JString, required = false,
                                 default = nil)
  if valid_612016 != nil:
    section.add "X-Amz-Credential", valid_612016
  var valid_612017 = header.getOrDefault("X-Amz-Security-Token")
  valid_612017 = validateParameter(valid_612017, JString, required = false,
                                 default = nil)
  if valid_612017 != nil:
    section.add "X-Amz-Security-Token", valid_612017
  var valid_612018 = header.getOrDefault("X-Amz-Algorithm")
  valid_612018 = validateParameter(valid_612018, JString, required = false,
                                 default = nil)
  if valid_612018 != nil:
    section.add "X-Amz-Algorithm", valid_612018
  var valid_612019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612019 = validateParameter(valid_612019, JString, required = false,
                                 default = nil)
  if valid_612019 != nil:
    section.add "X-Amz-SignedHeaders", valid_612019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612020: Call_GetDisableAvailabilityZonesForLoadBalancer_612006;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_612020.validator(path, query, header, formData, body)
  let scheme = call_612020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612020.url(scheme.get, call_612020.host, call_612020.base,
                         call_612020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612020, url, valid)

proc call*(call_612021: Call_GetDisableAvailabilityZonesForLoadBalancer_612006;
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
  var query_612022 = newJObject()
  if AvailabilityZones != nil:
    query_612022.add "AvailabilityZones", AvailabilityZones
  add(query_612022, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612022, "Action", newJString(Action))
  add(query_612022, "Version", newJString(Version))
  result = call_612021.call(nil, query_612022, nil, nil, nil)

var getDisableAvailabilityZonesForLoadBalancer* = Call_GetDisableAvailabilityZonesForLoadBalancer_612006(
    name: "getDisableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_GetDisableAvailabilityZonesForLoadBalancer_612007,
    base: "/", url: url_GetDisableAvailabilityZonesForLoadBalancer_612008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAvailabilityZonesForLoadBalancer_612058 = ref object of OpenApiRestCall_610658
proc url_PostEnableAvailabilityZonesForLoadBalancer_612060(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostEnableAvailabilityZonesForLoadBalancer_612059(path: JsonNode;
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
  var valid_612061 = query.getOrDefault("Action")
  valid_612061 = validateParameter(valid_612061, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_612061 != nil:
    section.add "Action", valid_612061
  var valid_612062 = query.getOrDefault("Version")
  valid_612062 = validateParameter(valid_612062, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612062 != nil:
    section.add "Version", valid_612062
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
  var valid_612063 = header.getOrDefault("X-Amz-Signature")
  valid_612063 = validateParameter(valid_612063, JString, required = false,
                                 default = nil)
  if valid_612063 != nil:
    section.add "X-Amz-Signature", valid_612063
  var valid_612064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612064 = validateParameter(valid_612064, JString, required = false,
                                 default = nil)
  if valid_612064 != nil:
    section.add "X-Amz-Content-Sha256", valid_612064
  var valid_612065 = header.getOrDefault("X-Amz-Date")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "X-Amz-Date", valid_612065
  var valid_612066 = header.getOrDefault("X-Amz-Credential")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "X-Amz-Credential", valid_612066
  var valid_612067 = header.getOrDefault("X-Amz-Security-Token")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-Security-Token", valid_612067
  var valid_612068 = header.getOrDefault("X-Amz-Algorithm")
  valid_612068 = validateParameter(valid_612068, JString, required = false,
                                 default = nil)
  if valid_612068 != nil:
    section.add "X-Amz-Algorithm", valid_612068
  var valid_612069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612069 = validateParameter(valid_612069, JString, required = false,
                                 default = nil)
  if valid_612069 != nil:
    section.add "X-Amz-SignedHeaders", valid_612069
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_612070 = formData.getOrDefault("AvailabilityZones")
  valid_612070 = validateParameter(valid_612070, JArray, required = true, default = nil)
  if valid_612070 != nil:
    section.add "AvailabilityZones", valid_612070
  var valid_612071 = formData.getOrDefault("LoadBalancerName")
  valid_612071 = validateParameter(valid_612071, JString, required = true,
                                 default = nil)
  if valid_612071 != nil:
    section.add "LoadBalancerName", valid_612071
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612072: Call_PostEnableAvailabilityZonesForLoadBalancer_612058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_612072.validator(path, query, header, formData, body)
  let scheme = call_612072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612072.url(scheme.get, call_612072.host, call_612072.base,
                         call_612072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612072, url, valid)

proc call*(call_612073: Call_PostEnableAvailabilityZonesForLoadBalancer_612058;
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
  var query_612074 = newJObject()
  var formData_612075 = newJObject()
  if AvailabilityZones != nil:
    formData_612075.add "AvailabilityZones", AvailabilityZones
  add(formData_612075, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612074, "Action", newJString(Action))
  add(query_612074, "Version", newJString(Version))
  result = call_612073.call(nil, query_612074, nil, formData_612075, nil)

var postEnableAvailabilityZonesForLoadBalancer* = Call_PostEnableAvailabilityZonesForLoadBalancer_612058(
    name: "postEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_PostEnableAvailabilityZonesForLoadBalancer_612059,
    base: "/", url: url_PostEnableAvailabilityZonesForLoadBalancer_612060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAvailabilityZonesForLoadBalancer_612041 = ref object of OpenApiRestCall_610658
proc url_GetEnableAvailabilityZonesForLoadBalancer_612043(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEnableAvailabilityZonesForLoadBalancer_612042(path: JsonNode;
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
  var valid_612044 = query.getOrDefault("AvailabilityZones")
  valid_612044 = validateParameter(valid_612044, JArray, required = true, default = nil)
  if valid_612044 != nil:
    section.add "AvailabilityZones", valid_612044
  var valid_612045 = query.getOrDefault("LoadBalancerName")
  valid_612045 = validateParameter(valid_612045, JString, required = true,
                                 default = nil)
  if valid_612045 != nil:
    section.add "LoadBalancerName", valid_612045
  var valid_612046 = query.getOrDefault("Action")
  valid_612046 = validateParameter(valid_612046, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_612046 != nil:
    section.add "Action", valid_612046
  var valid_612047 = query.getOrDefault("Version")
  valid_612047 = validateParameter(valid_612047, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612047 != nil:
    section.add "Version", valid_612047
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
  var valid_612048 = header.getOrDefault("X-Amz-Signature")
  valid_612048 = validateParameter(valid_612048, JString, required = false,
                                 default = nil)
  if valid_612048 != nil:
    section.add "X-Amz-Signature", valid_612048
  var valid_612049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612049 = validateParameter(valid_612049, JString, required = false,
                                 default = nil)
  if valid_612049 != nil:
    section.add "X-Amz-Content-Sha256", valid_612049
  var valid_612050 = header.getOrDefault("X-Amz-Date")
  valid_612050 = validateParameter(valid_612050, JString, required = false,
                                 default = nil)
  if valid_612050 != nil:
    section.add "X-Amz-Date", valid_612050
  var valid_612051 = header.getOrDefault("X-Amz-Credential")
  valid_612051 = validateParameter(valid_612051, JString, required = false,
                                 default = nil)
  if valid_612051 != nil:
    section.add "X-Amz-Credential", valid_612051
  var valid_612052 = header.getOrDefault("X-Amz-Security-Token")
  valid_612052 = validateParameter(valid_612052, JString, required = false,
                                 default = nil)
  if valid_612052 != nil:
    section.add "X-Amz-Security-Token", valid_612052
  var valid_612053 = header.getOrDefault("X-Amz-Algorithm")
  valid_612053 = validateParameter(valid_612053, JString, required = false,
                                 default = nil)
  if valid_612053 != nil:
    section.add "X-Amz-Algorithm", valid_612053
  var valid_612054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612054 = validateParameter(valid_612054, JString, required = false,
                                 default = nil)
  if valid_612054 != nil:
    section.add "X-Amz-SignedHeaders", valid_612054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612055: Call_GetEnableAvailabilityZonesForLoadBalancer_612041;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_612055.validator(path, query, header, formData, body)
  let scheme = call_612055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612055.url(scheme.get, call_612055.host, call_612055.base,
                         call_612055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612055, url, valid)

proc call*(call_612056: Call_GetEnableAvailabilityZonesForLoadBalancer_612041;
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
  var query_612057 = newJObject()
  if AvailabilityZones != nil:
    query_612057.add "AvailabilityZones", AvailabilityZones
  add(query_612057, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612057, "Action", newJString(Action))
  add(query_612057, "Version", newJString(Version))
  result = call_612056.call(nil, query_612057, nil, nil, nil)

var getEnableAvailabilityZonesForLoadBalancer* = Call_GetEnableAvailabilityZonesForLoadBalancer_612041(
    name: "getEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_GetEnableAvailabilityZonesForLoadBalancer_612042,
    base: "/", url: url_GetEnableAvailabilityZonesForLoadBalancer_612043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_612097 = ref object of OpenApiRestCall_610658
proc url_PostModifyLoadBalancerAttributes_612099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyLoadBalancerAttributes_612098(path: JsonNode;
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
  var valid_612100 = query.getOrDefault("Action")
  valid_612100 = validateParameter(valid_612100, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_612100 != nil:
    section.add "Action", valid_612100
  var valid_612101 = query.getOrDefault("Version")
  valid_612101 = validateParameter(valid_612101, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612101 != nil:
    section.add "Version", valid_612101
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
  var valid_612102 = header.getOrDefault("X-Amz-Signature")
  valid_612102 = validateParameter(valid_612102, JString, required = false,
                                 default = nil)
  if valid_612102 != nil:
    section.add "X-Amz-Signature", valid_612102
  var valid_612103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-Content-Sha256", valid_612103
  var valid_612104 = header.getOrDefault("X-Amz-Date")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-Date", valid_612104
  var valid_612105 = header.getOrDefault("X-Amz-Credential")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "X-Amz-Credential", valid_612105
  var valid_612106 = header.getOrDefault("X-Amz-Security-Token")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-Security-Token", valid_612106
  var valid_612107 = header.getOrDefault("X-Amz-Algorithm")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "X-Amz-Algorithm", valid_612107
  var valid_612108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "X-Amz-SignedHeaders", valid_612108
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
  var valid_612109 = formData.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_612109
  var valid_612110 = formData.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_612110 = validateParameter(valid_612110, JArray, required = false,
                                 default = nil)
  if valid_612110 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_612110
  var valid_612111 = formData.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_612111 = validateParameter(valid_612111, JString, required = false,
                                 default = nil)
  if valid_612111 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_612111
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_612112 = formData.getOrDefault("LoadBalancerName")
  valid_612112 = validateParameter(valid_612112, JString, required = true,
                                 default = nil)
  if valid_612112 != nil:
    section.add "LoadBalancerName", valid_612112
  var valid_612113 = formData.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_612113
  var valid_612114 = formData.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_612114
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612115: Call_PostModifyLoadBalancerAttributes_612097;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_612115.validator(path, query, header, formData, body)
  let scheme = call_612115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612115.url(scheme.get, call_612115.host, call_612115.base,
                         call_612115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612115, url, valid)

proc call*(call_612116: Call_PostModifyLoadBalancerAttributes_612097;
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
  var query_612117 = newJObject()
  var formData_612118 = newJObject()
  add(formData_612118, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    formData_612118.add "LoadBalancerAttributes.AdditionalAttributes",
                       LoadBalancerAttributesAdditionalAttributes
  add(formData_612118, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(formData_612118, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612117, "Action", newJString(Action))
  add(formData_612118, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_612117, "Version", newJString(Version))
  add(formData_612118, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  result = call_612116.call(nil, query_612117, nil, formData_612118, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_612097(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_612098, base: "/",
    url: url_PostModifyLoadBalancerAttributes_612099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_612076 = ref object of OpenApiRestCall_610658
proc url_GetModifyLoadBalancerAttributes_612078(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyLoadBalancerAttributes_612077(path: JsonNode;
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
  var valid_612079 = query.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_612079
  var valid_612080 = query.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_612080
  var valid_612081 = query.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_612081 = validateParameter(valid_612081, JString, required = false,
                                 default = nil)
  if valid_612081 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_612081
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_612082 = query.getOrDefault("LoadBalancerName")
  valid_612082 = validateParameter(valid_612082, JString, required = true,
                                 default = nil)
  if valid_612082 != nil:
    section.add "LoadBalancerName", valid_612082
  var valid_612083 = query.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_612083 = validateParameter(valid_612083, JString, required = false,
                                 default = nil)
  if valid_612083 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_612083
  var valid_612084 = query.getOrDefault("Action")
  valid_612084 = validateParameter(valid_612084, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_612084 != nil:
    section.add "Action", valid_612084
  var valid_612085 = query.getOrDefault("Version")
  valid_612085 = validateParameter(valid_612085, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612085 != nil:
    section.add "Version", valid_612085
  var valid_612086 = query.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_612086 = validateParameter(valid_612086, JArray, required = false,
                                 default = nil)
  if valid_612086 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_612086
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
  var valid_612087 = header.getOrDefault("X-Amz-Signature")
  valid_612087 = validateParameter(valid_612087, JString, required = false,
                                 default = nil)
  if valid_612087 != nil:
    section.add "X-Amz-Signature", valid_612087
  var valid_612088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612088 = validateParameter(valid_612088, JString, required = false,
                                 default = nil)
  if valid_612088 != nil:
    section.add "X-Amz-Content-Sha256", valid_612088
  var valid_612089 = header.getOrDefault("X-Amz-Date")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-Date", valid_612089
  var valid_612090 = header.getOrDefault("X-Amz-Credential")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Credential", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Security-Token")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Security-Token", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-Algorithm")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-Algorithm", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-SignedHeaders", valid_612093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612094: Call_GetModifyLoadBalancerAttributes_612076;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_612094.validator(path, query, header, formData, body)
  let scheme = call_612094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612094.url(scheme.get, call_612094.host, call_612094.base,
                         call_612094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612094, url, valid)

proc call*(call_612095: Call_GetModifyLoadBalancerAttributes_612076;
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
  var query_612096 = newJObject()
  add(query_612096, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_612096, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_612096, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_612096, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612096, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  add(query_612096, "Action", newJString(Action))
  add(query_612096, "Version", newJString(Version))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    query_612096.add "LoadBalancerAttributes.AdditionalAttributes",
                    LoadBalancerAttributesAdditionalAttributes
  result = call_612095.call(nil, query_612096, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_612076(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_612077, base: "/",
    url: url_GetModifyLoadBalancerAttributes_612078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterInstancesWithLoadBalancer_612136 = ref object of OpenApiRestCall_610658
proc url_PostRegisterInstancesWithLoadBalancer_612138(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRegisterInstancesWithLoadBalancer_612137(path: JsonNode;
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
  var valid_612139 = query.getOrDefault("Action")
  valid_612139 = validateParameter(valid_612139, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_612139 != nil:
    section.add "Action", valid_612139
  var valid_612140 = query.getOrDefault("Version")
  valid_612140 = validateParameter(valid_612140, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612140 != nil:
    section.add "Version", valid_612140
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
  var valid_612141 = header.getOrDefault("X-Amz-Signature")
  valid_612141 = validateParameter(valid_612141, JString, required = false,
                                 default = nil)
  if valid_612141 != nil:
    section.add "X-Amz-Signature", valid_612141
  var valid_612142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612142 = validateParameter(valid_612142, JString, required = false,
                                 default = nil)
  if valid_612142 != nil:
    section.add "X-Amz-Content-Sha256", valid_612142
  var valid_612143 = header.getOrDefault("X-Amz-Date")
  valid_612143 = validateParameter(valid_612143, JString, required = false,
                                 default = nil)
  if valid_612143 != nil:
    section.add "X-Amz-Date", valid_612143
  var valid_612144 = header.getOrDefault("X-Amz-Credential")
  valid_612144 = validateParameter(valid_612144, JString, required = false,
                                 default = nil)
  if valid_612144 != nil:
    section.add "X-Amz-Credential", valid_612144
  var valid_612145 = header.getOrDefault("X-Amz-Security-Token")
  valid_612145 = validateParameter(valid_612145, JString, required = false,
                                 default = nil)
  if valid_612145 != nil:
    section.add "X-Amz-Security-Token", valid_612145
  var valid_612146 = header.getOrDefault("X-Amz-Algorithm")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "X-Amz-Algorithm", valid_612146
  var valid_612147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "X-Amz-SignedHeaders", valid_612147
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_612148 = formData.getOrDefault("Instances")
  valid_612148 = validateParameter(valid_612148, JArray, required = true, default = nil)
  if valid_612148 != nil:
    section.add "Instances", valid_612148
  var valid_612149 = formData.getOrDefault("LoadBalancerName")
  valid_612149 = validateParameter(valid_612149, JString, required = true,
                                 default = nil)
  if valid_612149 != nil:
    section.add "LoadBalancerName", valid_612149
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612150: Call_PostRegisterInstancesWithLoadBalancer_612136;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_612150.validator(path, query, header, formData, body)
  let scheme = call_612150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612150.url(scheme.get, call_612150.host, call_612150.base,
                         call_612150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612150, url, valid)

proc call*(call_612151: Call_PostRegisterInstancesWithLoadBalancer_612136;
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
  var query_612152 = newJObject()
  var formData_612153 = newJObject()
  if Instances != nil:
    formData_612153.add "Instances", Instances
  add(formData_612153, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612152, "Action", newJString(Action))
  add(query_612152, "Version", newJString(Version))
  result = call_612151.call(nil, query_612152, nil, formData_612153, nil)

var postRegisterInstancesWithLoadBalancer* = Call_PostRegisterInstancesWithLoadBalancer_612136(
    name: "postRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_PostRegisterInstancesWithLoadBalancer_612137, base: "/",
    url: url_PostRegisterInstancesWithLoadBalancer_612138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterInstancesWithLoadBalancer_612119 = ref object of OpenApiRestCall_610658
proc url_GetRegisterInstancesWithLoadBalancer_612121(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRegisterInstancesWithLoadBalancer_612120(path: JsonNode;
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
  var valid_612122 = query.getOrDefault("LoadBalancerName")
  valid_612122 = validateParameter(valid_612122, JString, required = true,
                                 default = nil)
  if valid_612122 != nil:
    section.add "LoadBalancerName", valid_612122
  var valid_612123 = query.getOrDefault("Action")
  valid_612123 = validateParameter(valid_612123, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_612123 != nil:
    section.add "Action", valid_612123
  var valid_612124 = query.getOrDefault("Instances")
  valid_612124 = validateParameter(valid_612124, JArray, required = true, default = nil)
  if valid_612124 != nil:
    section.add "Instances", valid_612124
  var valid_612125 = query.getOrDefault("Version")
  valid_612125 = validateParameter(valid_612125, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612125 != nil:
    section.add "Version", valid_612125
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
  var valid_612126 = header.getOrDefault("X-Amz-Signature")
  valid_612126 = validateParameter(valid_612126, JString, required = false,
                                 default = nil)
  if valid_612126 != nil:
    section.add "X-Amz-Signature", valid_612126
  var valid_612127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612127 = validateParameter(valid_612127, JString, required = false,
                                 default = nil)
  if valid_612127 != nil:
    section.add "X-Amz-Content-Sha256", valid_612127
  var valid_612128 = header.getOrDefault("X-Amz-Date")
  valid_612128 = validateParameter(valid_612128, JString, required = false,
                                 default = nil)
  if valid_612128 != nil:
    section.add "X-Amz-Date", valid_612128
  var valid_612129 = header.getOrDefault("X-Amz-Credential")
  valid_612129 = validateParameter(valid_612129, JString, required = false,
                                 default = nil)
  if valid_612129 != nil:
    section.add "X-Amz-Credential", valid_612129
  var valid_612130 = header.getOrDefault("X-Amz-Security-Token")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "X-Amz-Security-Token", valid_612130
  var valid_612131 = header.getOrDefault("X-Amz-Algorithm")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "X-Amz-Algorithm", valid_612131
  var valid_612132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-SignedHeaders", valid_612132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612133: Call_GetRegisterInstancesWithLoadBalancer_612119;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_612133.validator(path, query, header, formData, body)
  let scheme = call_612133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612133.url(scheme.get, call_612133.host, call_612133.base,
                         call_612133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612133, url, valid)

proc call*(call_612134: Call_GetRegisterInstancesWithLoadBalancer_612119;
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
  var query_612135 = newJObject()
  add(query_612135, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612135, "Action", newJString(Action))
  if Instances != nil:
    query_612135.add "Instances", Instances
  add(query_612135, "Version", newJString(Version))
  result = call_612134.call(nil, query_612135, nil, nil, nil)

var getRegisterInstancesWithLoadBalancer* = Call_GetRegisterInstancesWithLoadBalancer_612119(
    name: "getRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_GetRegisterInstancesWithLoadBalancer_612120, base: "/",
    url: url_GetRegisterInstancesWithLoadBalancer_612121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_612171 = ref object of OpenApiRestCall_610658
proc url_PostRemoveTags_612173(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTags_612172(path: JsonNode; query: JsonNode;
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
  var valid_612174 = query.getOrDefault("Action")
  valid_612174 = validateParameter(valid_612174, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_612174 != nil:
    section.add "Action", valid_612174
  var valid_612175 = query.getOrDefault("Version")
  valid_612175 = validateParameter(valid_612175, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612175 != nil:
    section.add "Version", valid_612175
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
  var valid_612176 = header.getOrDefault("X-Amz-Signature")
  valid_612176 = validateParameter(valid_612176, JString, required = false,
                                 default = nil)
  if valid_612176 != nil:
    section.add "X-Amz-Signature", valid_612176
  var valid_612177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612177 = validateParameter(valid_612177, JString, required = false,
                                 default = nil)
  if valid_612177 != nil:
    section.add "X-Amz-Content-Sha256", valid_612177
  var valid_612178 = header.getOrDefault("X-Amz-Date")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Date", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Credential")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Credential", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Security-Token")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Security-Token", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Algorithm")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Algorithm", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-SignedHeaders", valid_612182
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_612183 = formData.getOrDefault("LoadBalancerNames")
  valid_612183 = validateParameter(valid_612183, JArray, required = true, default = nil)
  if valid_612183 != nil:
    section.add "LoadBalancerNames", valid_612183
  var valid_612184 = formData.getOrDefault("Tags")
  valid_612184 = validateParameter(valid_612184, JArray, required = true, default = nil)
  if valid_612184 != nil:
    section.add "Tags", valid_612184
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612185: Call_PostRemoveTags_612171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_612185.validator(path, query, header, formData, body)
  let scheme = call_612185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612185.url(scheme.get, call_612185.host, call_612185.base,
                         call_612185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612185, url, valid)

proc call*(call_612186: Call_PostRemoveTags_612171; LoadBalancerNames: JsonNode;
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
  var query_612187 = newJObject()
  var formData_612188 = newJObject()
  if LoadBalancerNames != nil:
    formData_612188.add "LoadBalancerNames", LoadBalancerNames
  add(query_612187, "Action", newJString(Action))
  if Tags != nil:
    formData_612188.add "Tags", Tags
  add(query_612187, "Version", newJString(Version))
  result = call_612186.call(nil, query_612187, nil, formData_612188, nil)

var postRemoveTags* = Call_PostRemoveTags_612171(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_612172,
    base: "/", url: url_PostRemoveTags_612173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_612154 = ref object of OpenApiRestCall_610658
proc url_GetRemoveTags_612156(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTags_612155(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612157 = query.getOrDefault("Tags")
  valid_612157 = validateParameter(valid_612157, JArray, required = true, default = nil)
  if valid_612157 != nil:
    section.add "Tags", valid_612157
  var valid_612158 = query.getOrDefault("Action")
  valid_612158 = validateParameter(valid_612158, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_612158 != nil:
    section.add "Action", valid_612158
  var valid_612159 = query.getOrDefault("Version")
  valid_612159 = validateParameter(valid_612159, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612159 != nil:
    section.add "Version", valid_612159
  var valid_612160 = query.getOrDefault("LoadBalancerNames")
  valid_612160 = validateParameter(valid_612160, JArray, required = true, default = nil)
  if valid_612160 != nil:
    section.add "LoadBalancerNames", valid_612160
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
  var valid_612161 = header.getOrDefault("X-Amz-Signature")
  valid_612161 = validateParameter(valid_612161, JString, required = false,
                                 default = nil)
  if valid_612161 != nil:
    section.add "X-Amz-Signature", valid_612161
  var valid_612162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612162 = validateParameter(valid_612162, JString, required = false,
                                 default = nil)
  if valid_612162 != nil:
    section.add "X-Amz-Content-Sha256", valid_612162
  var valid_612163 = header.getOrDefault("X-Amz-Date")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "X-Amz-Date", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Credential")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Credential", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Security-Token")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Security-Token", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-Algorithm")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-Algorithm", valid_612166
  var valid_612167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-SignedHeaders", valid_612167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612168: Call_GetRemoveTags_612154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_612168.validator(path, query, header, formData, body)
  let scheme = call_612168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612168.url(scheme.get, call_612168.host, call_612168.base,
                         call_612168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612168, url, valid)

proc call*(call_612169: Call_GetRemoveTags_612154; Tags: JsonNode;
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
  var query_612170 = newJObject()
  if Tags != nil:
    query_612170.add "Tags", Tags
  add(query_612170, "Action", newJString(Action))
  add(query_612170, "Version", newJString(Version))
  if LoadBalancerNames != nil:
    query_612170.add "LoadBalancerNames", LoadBalancerNames
  result = call_612169.call(nil, query_612170, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_612154(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_612155,
    base: "/", url: url_GetRemoveTags_612156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerListenerSSLCertificate_612207 = ref object of OpenApiRestCall_610658
proc url_PostSetLoadBalancerListenerSSLCertificate_612209(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetLoadBalancerListenerSSLCertificate_612208(path: JsonNode;
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
  var valid_612210 = query.getOrDefault("Action")
  valid_612210 = validateParameter(valid_612210, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_612210 != nil:
    section.add "Action", valid_612210
  var valid_612211 = query.getOrDefault("Version")
  valid_612211 = validateParameter(valid_612211, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612211 != nil:
    section.add "Version", valid_612211
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
  var valid_612212 = header.getOrDefault("X-Amz-Signature")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-Signature", valid_612212
  var valid_612213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612213 = validateParameter(valid_612213, JString, required = false,
                                 default = nil)
  if valid_612213 != nil:
    section.add "X-Amz-Content-Sha256", valid_612213
  var valid_612214 = header.getOrDefault("X-Amz-Date")
  valid_612214 = validateParameter(valid_612214, JString, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "X-Amz-Date", valid_612214
  var valid_612215 = header.getOrDefault("X-Amz-Credential")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-Credential", valid_612215
  var valid_612216 = header.getOrDefault("X-Amz-Security-Token")
  valid_612216 = validateParameter(valid_612216, JString, required = false,
                                 default = nil)
  if valid_612216 != nil:
    section.add "X-Amz-Security-Token", valid_612216
  var valid_612217 = header.getOrDefault("X-Amz-Algorithm")
  valid_612217 = validateParameter(valid_612217, JString, required = false,
                                 default = nil)
  if valid_612217 != nil:
    section.add "X-Amz-Algorithm", valid_612217
  var valid_612218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612218 = validateParameter(valid_612218, JString, required = false,
                                 default = nil)
  if valid_612218 != nil:
    section.add "X-Amz-SignedHeaders", valid_612218
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
  var valid_612219 = formData.getOrDefault("LoadBalancerName")
  valid_612219 = validateParameter(valid_612219, JString, required = true,
                                 default = nil)
  if valid_612219 != nil:
    section.add "LoadBalancerName", valid_612219
  var valid_612220 = formData.getOrDefault("SSLCertificateId")
  valid_612220 = validateParameter(valid_612220, JString, required = true,
                                 default = nil)
  if valid_612220 != nil:
    section.add "SSLCertificateId", valid_612220
  var valid_612221 = formData.getOrDefault("LoadBalancerPort")
  valid_612221 = validateParameter(valid_612221, JInt, required = true, default = nil)
  if valid_612221 != nil:
    section.add "LoadBalancerPort", valid_612221
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612222: Call_PostSetLoadBalancerListenerSSLCertificate_612207;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_612222.validator(path, query, header, formData, body)
  let scheme = call_612222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612222.url(scheme.get, call_612222.host, call_612222.base,
                         call_612222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612222, url, valid)

proc call*(call_612223: Call_PostSetLoadBalancerListenerSSLCertificate_612207;
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
  var query_612224 = newJObject()
  var formData_612225 = newJObject()
  add(formData_612225, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612224, "Action", newJString(Action))
  add(formData_612225, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_612224, "Version", newJString(Version))
  add(formData_612225, "LoadBalancerPort", newJInt(LoadBalancerPort))
  result = call_612223.call(nil, query_612224, nil, formData_612225, nil)

var postSetLoadBalancerListenerSSLCertificate* = Call_PostSetLoadBalancerListenerSSLCertificate_612207(
    name: "postSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_PostSetLoadBalancerListenerSSLCertificate_612208,
    base: "/", url: url_PostSetLoadBalancerListenerSSLCertificate_612209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerListenerSSLCertificate_612189 = ref object of OpenApiRestCall_610658
proc url_GetSetLoadBalancerListenerSSLCertificate_612191(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetLoadBalancerListenerSSLCertificate_612190(path: JsonNode;
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
  var valid_612192 = query.getOrDefault("LoadBalancerPort")
  valid_612192 = validateParameter(valid_612192, JInt, required = true, default = nil)
  if valid_612192 != nil:
    section.add "LoadBalancerPort", valid_612192
  var valid_612193 = query.getOrDefault("LoadBalancerName")
  valid_612193 = validateParameter(valid_612193, JString, required = true,
                                 default = nil)
  if valid_612193 != nil:
    section.add "LoadBalancerName", valid_612193
  var valid_612194 = query.getOrDefault("Action")
  valid_612194 = validateParameter(valid_612194, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_612194 != nil:
    section.add "Action", valid_612194
  var valid_612195 = query.getOrDefault("Version")
  valid_612195 = validateParameter(valid_612195, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612195 != nil:
    section.add "Version", valid_612195
  var valid_612196 = query.getOrDefault("SSLCertificateId")
  valid_612196 = validateParameter(valid_612196, JString, required = true,
                                 default = nil)
  if valid_612196 != nil:
    section.add "SSLCertificateId", valid_612196
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
  var valid_612197 = header.getOrDefault("X-Amz-Signature")
  valid_612197 = validateParameter(valid_612197, JString, required = false,
                                 default = nil)
  if valid_612197 != nil:
    section.add "X-Amz-Signature", valid_612197
  var valid_612198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612198 = validateParameter(valid_612198, JString, required = false,
                                 default = nil)
  if valid_612198 != nil:
    section.add "X-Amz-Content-Sha256", valid_612198
  var valid_612199 = header.getOrDefault("X-Amz-Date")
  valid_612199 = validateParameter(valid_612199, JString, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "X-Amz-Date", valid_612199
  var valid_612200 = header.getOrDefault("X-Amz-Credential")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "X-Amz-Credential", valid_612200
  var valid_612201 = header.getOrDefault("X-Amz-Security-Token")
  valid_612201 = validateParameter(valid_612201, JString, required = false,
                                 default = nil)
  if valid_612201 != nil:
    section.add "X-Amz-Security-Token", valid_612201
  var valid_612202 = header.getOrDefault("X-Amz-Algorithm")
  valid_612202 = validateParameter(valid_612202, JString, required = false,
                                 default = nil)
  if valid_612202 != nil:
    section.add "X-Amz-Algorithm", valid_612202
  var valid_612203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612203 = validateParameter(valid_612203, JString, required = false,
                                 default = nil)
  if valid_612203 != nil:
    section.add "X-Amz-SignedHeaders", valid_612203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612204: Call_GetSetLoadBalancerListenerSSLCertificate_612189;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_612204.validator(path, query, header, formData, body)
  let scheme = call_612204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612204.url(scheme.get, call_612204.host, call_612204.base,
                         call_612204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612204, url, valid)

proc call*(call_612205: Call_GetSetLoadBalancerListenerSSLCertificate_612189;
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
  var query_612206 = newJObject()
  add(query_612206, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_612206, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612206, "Action", newJString(Action))
  add(query_612206, "Version", newJString(Version))
  add(query_612206, "SSLCertificateId", newJString(SSLCertificateId))
  result = call_612205.call(nil, query_612206, nil, nil, nil)

var getSetLoadBalancerListenerSSLCertificate* = Call_GetSetLoadBalancerListenerSSLCertificate_612189(
    name: "getSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_GetSetLoadBalancerListenerSSLCertificate_612190,
    base: "/", url: url_GetSetLoadBalancerListenerSSLCertificate_612191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesForBackendServer_612244 = ref object of OpenApiRestCall_610658
proc url_PostSetLoadBalancerPoliciesForBackendServer_612246(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetLoadBalancerPoliciesForBackendServer_612245(path: JsonNode;
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
  var valid_612247 = query.getOrDefault("Action")
  valid_612247 = validateParameter(valid_612247, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_612247 != nil:
    section.add "Action", valid_612247
  var valid_612248 = query.getOrDefault("Version")
  valid_612248 = validateParameter(valid_612248, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612248 != nil:
    section.add "Version", valid_612248
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
  var valid_612249 = header.getOrDefault("X-Amz-Signature")
  valid_612249 = validateParameter(valid_612249, JString, required = false,
                                 default = nil)
  if valid_612249 != nil:
    section.add "X-Amz-Signature", valid_612249
  var valid_612250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612250 = validateParameter(valid_612250, JString, required = false,
                                 default = nil)
  if valid_612250 != nil:
    section.add "X-Amz-Content-Sha256", valid_612250
  var valid_612251 = header.getOrDefault("X-Amz-Date")
  valid_612251 = validateParameter(valid_612251, JString, required = false,
                                 default = nil)
  if valid_612251 != nil:
    section.add "X-Amz-Date", valid_612251
  var valid_612252 = header.getOrDefault("X-Amz-Credential")
  valid_612252 = validateParameter(valid_612252, JString, required = false,
                                 default = nil)
  if valid_612252 != nil:
    section.add "X-Amz-Credential", valid_612252
  var valid_612253 = header.getOrDefault("X-Amz-Security-Token")
  valid_612253 = validateParameter(valid_612253, JString, required = false,
                                 default = nil)
  if valid_612253 != nil:
    section.add "X-Amz-Security-Token", valid_612253
  var valid_612254 = header.getOrDefault("X-Amz-Algorithm")
  valid_612254 = validateParameter(valid_612254, JString, required = false,
                                 default = nil)
  if valid_612254 != nil:
    section.add "X-Amz-Algorithm", valid_612254
  var valid_612255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612255 = validateParameter(valid_612255, JString, required = false,
                                 default = nil)
  if valid_612255 != nil:
    section.add "X-Amz-SignedHeaders", valid_612255
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
  var valid_612256 = formData.getOrDefault("PolicyNames")
  valid_612256 = validateParameter(valid_612256, JArray, required = true, default = nil)
  if valid_612256 != nil:
    section.add "PolicyNames", valid_612256
  var valid_612257 = formData.getOrDefault("LoadBalancerName")
  valid_612257 = validateParameter(valid_612257, JString, required = true,
                                 default = nil)
  if valid_612257 != nil:
    section.add "LoadBalancerName", valid_612257
  var valid_612258 = formData.getOrDefault("InstancePort")
  valid_612258 = validateParameter(valid_612258, JInt, required = true, default = nil)
  if valid_612258 != nil:
    section.add "InstancePort", valid_612258
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612259: Call_PostSetLoadBalancerPoliciesForBackendServer_612244;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_612259.validator(path, query, header, formData, body)
  let scheme = call_612259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612259.url(scheme.get, call_612259.host, call_612259.base,
                         call_612259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612259, url, valid)

proc call*(call_612260: Call_PostSetLoadBalancerPoliciesForBackendServer_612244;
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
  var query_612261 = newJObject()
  var formData_612262 = newJObject()
  if PolicyNames != nil:
    formData_612262.add "PolicyNames", PolicyNames
  add(formData_612262, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612261, "Action", newJString(Action))
  add(formData_612262, "InstancePort", newJInt(InstancePort))
  add(query_612261, "Version", newJString(Version))
  result = call_612260.call(nil, query_612261, nil, formData_612262, nil)

var postSetLoadBalancerPoliciesForBackendServer* = Call_PostSetLoadBalancerPoliciesForBackendServer_612244(
    name: "postSetLoadBalancerPoliciesForBackendServer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_PostSetLoadBalancerPoliciesForBackendServer_612245,
    base: "/", url: url_PostSetLoadBalancerPoliciesForBackendServer_612246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesForBackendServer_612226 = ref object of OpenApiRestCall_610658
proc url_GetSetLoadBalancerPoliciesForBackendServer_612228(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetLoadBalancerPoliciesForBackendServer_612227(path: JsonNode;
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
  var valid_612229 = query.getOrDefault("InstancePort")
  valid_612229 = validateParameter(valid_612229, JInt, required = true, default = nil)
  if valid_612229 != nil:
    section.add "InstancePort", valid_612229
  var valid_612230 = query.getOrDefault("LoadBalancerName")
  valid_612230 = validateParameter(valid_612230, JString, required = true,
                                 default = nil)
  if valid_612230 != nil:
    section.add "LoadBalancerName", valid_612230
  var valid_612231 = query.getOrDefault("Action")
  valid_612231 = validateParameter(valid_612231, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_612231 != nil:
    section.add "Action", valid_612231
  var valid_612232 = query.getOrDefault("Version")
  valid_612232 = validateParameter(valid_612232, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612232 != nil:
    section.add "Version", valid_612232
  var valid_612233 = query.getOrDefault("PolicyNames")
  valid_612233 = validateParameter(valid_612233, JArray, required = true, default = nil)
  if valid_612233 != nil:
    section.add "PolicyNames", valid_612233
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
  var valid_612234 = header.getOrDefault("X-Amz-Signature")
  valid_612234 = validateParameter(valid_612234, JString, required = false,
                                 default = nil)
  if valid_612234 != nil:
    section.add "X-Amz-Signature", valid_612234
  var valid_612235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612235 = validateParameter(valid_612235, JString, required = false,
                                 default = nil)
  if valid_612235 != nil:
    section.add "X-Amz-Content-Sha256", valid_612235
  var valid_612236 = header.getOrDefault("X-Amz-Date")
  valid_612236 = validateParameter(valid_612236, JString, required = false,
                                 default = nil)
  if valid_612236 != nil:
    section.add "X-Amz-Date", valid_612236
  var valid_612237 = header.getOrDefault("X-Amz-Credential")
  valid_612237 = validateParameter(valid_612237, JString, required = false,
                                 default = nil)
  if valid_612237 != nil:
    section.add "X-Amz-Credential", valid_612237
  var valid_612238 = header.getOrDefault("X-Amz-Security-Token")
  valid_612238 = validateParameter(valid_612238, JString, required = false,
                                 default = nil)
  if valid_612238 != nil:
    section.add "X-Amz-Security-Token", valid_612238
  var valid_612239 = header.getOrDefault("X-Amz-Algorithm")
  valid_612239 = validateParameter(valid_612239, JString, required = false,
                                 default = nil)
  if valid_612239 != nil:
    section.add "X-Amz-Algorithm", valid_612239
  var valid_612240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612240 = validateParameter(valid_612240, JString, required = false,
                                 default = nil)
  if valid_612240 != nil:
    section.add "X-Amz-SignedHeaders", valid_612240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612241: Call_GetSetLoadBalancerPoliciesForBackendServer_612226;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_612241.validator(path, query, header, formData, body)
  let scheme = call_612241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612241.url(scheme.get, call_612241.host, call_612241.base,
                         call_612241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612241, url, valid)

proc call*(call_612242: Call_GetSetLoadBalancerPoliciesForBackendServer_612226;
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
  var query_612243 = newJObject()
  add(query_612243, "InstancePort", newJInt(InstancePort))
  add(query_612243, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612243, "Action", newJString(Action))
  add(query_612243, "Version", newJString(Version))
  if PolicyNames != nil:
    query_612243.add "PolicyNames", PolicyNames
  result = call_612242.call(nil, query_612243, nil, nil, nil)

var getSetLoadBalancerPoliciesForBackendServer* = Call_GetSetLoadBalancerPoliciesForBackendServer_612226(
    name: "getSetLoadBalancerPoliciesForBackendServer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_GetSetLoadBalancerPoliciesForBackendServer_612227,
    base: "/", url: url_GetSetLoadBalancerPoliciesForBackendServer_612228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesOfListener_612281 = ref object of OpenApiRestCall_610658
proc url_PostSetLoadBalancerPoliciesOfListener_612283(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetLoadBalancerPoliciesOfListener_612282(path: JsonNode;
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
  var valid_612284 = query.getOrDefault("Action")
  valid_612284 = validateParameter(valid_612284, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_612284 != nil:
    section.add "Action", valid_612284
  var valid_612285 = query.getOrDefault("Version")
  valid_612285 = validateParameter(valid_612285, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612285 != nil:
    section.add "Version", valid_612285
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
  var valid_612286 = header.getOrDefault("X-Amz-Signature")
  valid_612286 = validateParameter(valid_612286, JString, required = false,
                                 default = nil)
  if valid_612286 != nil:
    section.add "X-Amz-Signature", valid_612286
  var valid_612287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612287 = validateParameter(valid_612287, JString, required = false,
                                 default = nil)
  if valid_612287 != nil:
    section.add "X-Amz-Content-Sha256", valid_612287
  var valid_612288 = header.getOrDefault("X-Amz-Date")
  valid_612288 = validateParameter(valid_612288, JString, required = false,
                                 default = nil)
  if valid_612288 != nil:
    section.add "X-Amz-Date", valid_612288
  var valid_612289 = header.getOrDefault("X-Amz-Credential")
  valid_612289 = validateParameter(valid_612289, JString, required = false,
                                 default = nil)
  if valid_612289 != nil:
    section.add "X-Amz-Credential", valid_612289
  var valid_612290 = header.getOrDefault("X-Amz-Security-Token")
  valid_612290 = validateParameter(valid_612290, JString, required = false,
                                 default = nil)
  if valid_612290 != nil:
    section.add "X-Amz-Security-Token", valid_612290
  var valid_612291 = header.getOrDefault("X-Amz-Algorithm")
  valid_612291 = validateParameter(valid_612291, JString, required = false,
                                 default = nil)
  if valid_612291 != nil:
    section.add "X-Amz-Algorithm", valid_612291
  var valid_612292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612292 = validateParameter(valid_612292, JString, required = false,
                                 default = nil)
  if valid_612292 != nil:
    section.add "X-Amz-SignedHeaders", valid_612292
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
  var valid_612293 = formData.getOrDefault("PolicyNames")
  valid_612293 = validateParameter(valid_612293, JArray, required = true, default = nil)
  if valid_612293 != nil:
    section.add "PolicyNames", valid_612293
  var valid_612294 = formData.getOrDefault("LoadBalancerName")
  valid_612294 = validateParameter(valid_612294, JString, required = true,
                                 default = nil)
  if valid_612294 != nil:
    section.add "LoadBalancerName", valid_612294
  var valid_612295 = formData.getOrDefault("LoadBalancerPort")
  valid_612295 = validateParameter(valid_612295, JInt, required = true, default = nil)
  if valid_612295 != nil:
    section.add "LoadBalancerPort", valid_612295
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612296: Call_PostSetLoadBalancerPoliciesOfListener_612281;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_612296.validator(path, query, header, formData, body)
  let scheme = call_612296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612296.url(scheme.get, call_612296.host, call_612296.base,
                         call_612296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612296, url, valid)

proc call*(call_612297: Call_PostSetLoadBalancerPoliciesOfListener_612281;
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
  var query_612298 = newJObject()
  var formData_612299 = newJObject()
  if PolicyNames != nil:
    formData_612299.add "PolicyNames", PolicyNames
  add(formData_612299, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612298, "Action", newJString(Action))
  add(query_612298, "Version", newJString(Version))
  add(formData_612299, "LoadBalancerPort", newJInt(LoadBalancerPort))
  result = call_612297.call(nil, query_612298, nil, formData_612299, nil)

var postSetLoadBalancerPoliciesOfListener* = Call_PostSetLoadBalancerPoliciesOfListener_612281(
    name: "postSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_PostSetLoadBalancerPoliciesOfListener_612282, base: "/",
    url: url_PostSetLoadBalancerPoliciesOfListener_612283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesOfListener_612263 = ref object of OpenApiRestCall_610658
proc url_GetSetLoadBalancerPoliciesOfListener_612265(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetLoadBalancerPoliciesOfListener_612264(path: JsonNode;
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
  var valid_612266 = query.getOrDefault("LoadBalancerPort")
  valid_612266 = validateParameter(valid_612266, JInt, required = true, default = nil)
  if valid_612266 != nil:
    section.add "LoadBalancerPort", valid_612266
  var valid_612267 = query.getOrDefault("LoadBalancerName")
  valid_612267 = validateParameter(valid_612267, JString, required = true,
                                 default = nil)
  if valid_612267 != nil:
    section.add "LoadBalancerName", valid_612267
  var valid_612268 = query.getOrDefault("Action")
  valid_612268 = validateParameter(valid_612268, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_612268 != nil:
    section.add "Action", valid_612268
  var valid_612269 = query.getOrDefault("Version")
  valid_612269 = validateParameter(valid_612269, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_612269 != nil:
    section.add "Version", valid_612269
  var valid_612270 = query.getOrDefault("PolicyNames")
  valid_612270 = validateParameter(valid_612270, JArray, required = true, default = nil)
  if valid_612270 != nil:
    section.add "PolicyNames", valid_612270
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
  var valid_612271 = header.getOrDefault("X-Amz-Signature")
  valid_612271 = validateParameter(valid_612271, JString, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "X-Amz-Signature", valid_612271
  var valid_612272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612272 = validateParameter(valid_612272, JString, required = false,
                                 default = nil)
  if valid_612272 != nil:
    section.add "X-Amz-Content-Sha256", valid_612272
  var valid_612273 = header.getOrDefault("X-Amz-Date")
  valid_612273 = validateParameter(valid_612273, JString, required = false,
                                 default = nil)
  if valid_612273 != nil:
    section.add "X-Amz-Date", valid_612273
  var valid_612274 = header.getOrDefault("X-Amz-Credential")
  valid_612274 = validateParameter(valid_612274, JString, required = false,
                                 default = nil)
  if valid_612274 != nil:
    section.add "X-Amz-Credential", valid_612274
  var valid_612275 = header.getOrDefault("X-Amz-Security-Token")
  valid_612275 = validateParameter(valid_612275, JString, required = false,
                                 default = nil)
  if valid_612275 != nil:
    section.add "X-Amz-Security-Token", valid_612275
  var valid_612276 = header.getOrDefault("X-Amz-Algorithm")
  valid_612276 = validateParameter(valid_612276, JString, required = false,
                                 default = nil)
  if valid_612276 != nil:
    section.add "X-Amz-Algorithm", valid_612276
  var valid_612277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612277 = validateParameter(valid_612277, JString, required = false,
                                 default = nil)
  if valid_612277 != nil:
    section.add "X-Amz-SignedHeaders", valid_612277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612278: Call_GetSetLoadBalancerPoliciesOfListener_612263;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_612278.validator(path, query, header, formData, body)
  let scheme = call_612278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612278.url(scheme.get, call_612278.host, call_612278.base,
                         call_612278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612278, url, valid)

proc call*(call_612279: Call_GetSetLoadBalancerPoliciesOfListener_612263;
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
  var query_612280 = newJObject()
  add(query_612280, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_612280, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_612280, "Action", newJString(Action))
  add(query_612280, "Version", newJString(Version))
  if PolicyNames != nil:
    query_612280.add "PolicyNames", PolicyNames
  result = call_612279.call(nil, query_612280, nil, nil, nil)

var getSetLoadBalancerPoliciesOfListener* = Call_GetSetLoadBalancerPoliciesOfListener_612263(
    name: "getSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_GetSetLoadBalancerPoliciesOfListener_612264, base: "/",
    url: url_GetSetLoadBalancerPoliciesOfListener_612265,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
