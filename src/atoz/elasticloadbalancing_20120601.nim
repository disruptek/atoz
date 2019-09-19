
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  Call_PostAddTags_773205 = ref object of OpenApiRestCall_772597
proc url_PostAddTags_773207(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddTags_773206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773208 = query.getOrDefault("Action")
  valid_773208 = validateParameter(valid_773208, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_773208 != nil:
    section.add "Action", valid_773208
  var valid_773209 = query.getOrDefault("Version")
  valid_773209 = validateParameter(valid_773209, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773209 != nil:
    section.add "Version", valid_773209
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
  var valid_773210 = header.getOrDefault("X-Amz-Date")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Date", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Security-Token")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Security-Token", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Content-Sha256", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Algorithm")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Algorithm", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Signature")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Signature", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-SignedHeaders", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Credential")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Credential", valid_773216
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_773217 = formData.getOrDefault("Tags")
  valid_773217 = validateParameter(valid_773217, JArray, required = true, default = nil)
  if valid_773217 != nil:
    section.add "Tags", valid_773217
  var valid_773218 = formData.getOrDefault("LoadBalancerNames")
  valid_773218 = validateParameter(valid_773218, JArray, required = true, default = nil)
  if valid_773218 != nil:
    section.add "LoadBalancerNames", valid_773218
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773219: Call_PostAddTags_773205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773219.validator(path, query, header, formData, body)
  let scheme = call_773219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773219.url(scheme.get, call_773219.host, call_773219.base,
                         call_773219.route, valid.getOrDefault("path"))
  result = hook(call_773219, url, valid)

proc call*(call_773220: Call_PostAddTags_773205; Tags: JsonNode;
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
  var query_773221 = newJObject()
  var formData_773222 = newJObject()
  if Tags != nil:
    formData_773222.add "Tags", Tags
  add(query_773221, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_773222.add "LoadBalancerNames", LoadBalancerNames
  add(query_773221, "Version", newJString(Version))
  result = call_773220.call(nil, query_773221, nil, formData_773222, nil)

var postAddTags* = Call_PostAddTags_773205(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_773206,
                                        base: "/", url: url_PostAddTags_773207,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_772933 = ref object of OpenApiRestCall_772597
proc url_GetAddTags_772935(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddTags_772934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773047 = query.getOrDefault("Tags")
  valid_773047 = validateParameter(valid_773047, JArray, required = true, default = nil)
  if valid_773047 != nil:
    section.add "Tags", valid_773047
  var valid_773061 = query.getOrDefault("Action")
  valid_773061 = validateParameter(valid_773061, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_773061 != nil:
    section.add "Action", valid_773061
  var valid_773062 = query.getOrDefault("LoadBalancerNames")
  valid_773062 = validateParameter(valid_773062, JArray, required = true, default = nil)
  if valid_773062 != nil:
    section.add "LoadBalancerNames", valid_773062
  var valid_773063 = query.getOrDefault("Version")
  valid_773063 = validateParameter(valid_773063, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773063 != nil:
    section.add "Version", valid_773063
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
  var valid_773064 = header.getOrDefault("X-Amz-Date")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Date", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Security-Token")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Security-Token", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Content-Sha256", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Algorithm")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Algorithm", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-Signature")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-Signature", valid_773068
  var valid_773069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773069 = validateParameter(valid_773069, JString, required = false,
                                 default = nil)
  if valid_773069 != nil:
    section.add "X-Amz-SignedHeaders", valid_773069
  var valid_773070 = header.getOrDefault("X-Amz-Credential")
  valid_773070 = validateParameter(valid_773070, JString, required = false,
                                 default = nil)
  if valid_773070 != nil:
    section.add "X-Amz-Credential", valid_773070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773093: Call_GetAddTags_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773093.validator(path, query, header, formData, body)
  let scheme = call_773093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773093.url(scheme.get, call_773093.host, call_773093.base,
                         call_773093.route, valid.getOrDefault("path"))
  result = hook(call_773093, url, valid)

proc call*(call_773164: Call_GetAddTags_772933; Tags: JsonNode;
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
  var query_773165 = newJObject()
  if Tags != nil:
    query_773165.add "Tags", Tags
  add(query_773165, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_773165.add "LoadBalancerNames", LoadBalancerNames
  add(query_773165, "Version", newJString(Version))
  result = call_773164.call(nil, query_773165, nil, nil, nil)

var getAddTags* = Call_GetAddTags_772933(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_772934,
                                      base: "/", url: url_GetAddTags_772935,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplySecurityGroupsToLoadBalancer_773240 = ref object of OpenApiRestCall_772597
proc url_PostApplySecurityGroupsToLoadBalancer_773242(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostApplySecurityGroupsToLoadBalancer_773241(path: JsonNode;
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
  var valid_773243 = query.getOrDefault("Action")
  valid_773243 = validateParameter(valid_773243, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_773243 != nil:
    section.add "Action", valid_773243
  var valid_773244 = query.getOrDefault("Version")
  valid_773244 = validateParameter(valid_773244, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773244 != nil:
    section.add "Version", valid_773244
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
  var valid_773245 = header.getOrDefault("X-Amz-Date")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Date", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-Security-Token")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Security-Token", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Content-Sha256", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-Algorithm")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Algorithm", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Signature")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Signature", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-SignedHeaders", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Credential")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Credential", valid_773251
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_773252 = formData.getOrDefault("SecurityGroups")
  valid_773252 = validateParameter(valid_773252, JArray, required = true, default = nil)
  if valid_773252 != nil:
    section.add "SecurityGroups", valid_773252
  var valid_773253 = formData.getOrDefault("LoadBalancerName")
  valid_773253 = validateParameter(valid_773253, JString, required = true,
                                 default = nil)
  if valid_773253 != nil:
    section.add "LoadBalancerName", valid_773253
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773254: Call_PostApplySecurityGroupsToLoadBalancer_773240;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773254.validator(path, query, header, formData, body)
  let scheme = call_773254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773254.url(scheme.get, call_773254.host, call_773254.base,
                         call_773254.route, valid.getOrDefault("path"))
  result = hook(call_773254, url, valid)

proc call*(call_773255: Call_PostApplySecurityGroupsToLoadBalancer_773240;
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
  var query_773256 = newJObject()
  var formData_773257 = newJObject()
  add(query_773256, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_773257.add "SecurityGroups", SecurityGroups
  add(formData_773257, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773256, "Version", newJString(Version))
  result = call_773255.call(nil, query_773256, nil, formData_773257, nil)

var postApplySecurityGroupsToLoadBalancer* = Call_PostApplySecurityGroupsToLoadBalancer_773240(
    name: "postApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_PostApplySecurityGroupsToLoadBalancer_773241, base: "/",
    url: url_PostApplySecurityGroupsToLoadBalancer_773242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplySecurityGroupsToLoadBalancer_773223 = ref object of OpenApiRestCall_772597
proc url_GetApplySecurityGroupsToLoadBalancer_773225(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApplySecurityGroupsToLoadBalancer_773224(path: JsonNode;
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
  var valid_773226 = query.getOrDefault("LoadBalancerName")
  valid_773226 = validateParameter(valid_773226, JString, required = true,
                                 default = nil)
  if valid_773226 != nil:
    section.add "LoadBalancerName", valid_773226
  var valid_773227 = query.getOrDefault("Action")
  valid_773227 = validateParameter(valid_773227, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_773227 != nil:
    section.add "Action", valid_773227
  var valid_773228 = query.getOrDefault("Version")
  valid_773228 = validateParameter(valid_773228, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773228 != nil:
    section.add "Version", valid_773228
  var valid_773229 = query.getOrDefault("SecurityGroups")
  valid_773229 = validateParameter(valid_773229, JArray, required = true, default = nil)
  if valid_773229 != nil:
    section.add "SecurityGroups", valid_773229
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
  var valid_773230 = header.getOrDefault("X-Amz-Date")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Date", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Security-Token")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Security-Token", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-Content-Sha256", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Algorithm")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Algorithm", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Signature")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Signature", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-SignedHeaders", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Credential")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Credential", valid_773236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773237: Call_GetApplySecurityGroupsToLoadBalancer_773223;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773237.validator(path, query, header, formData, body)
  let scheme = call_773237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773237.url(scheme.get, call_773237.host, call_773237.base,
                         call_773237.route, valid.getOrDefault("path"))
  result = hook(call_773237, url, valid)

proc call*(call_773238: Call_GetApplySecurityGroupsToLoadBalancer_773223;
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
  var query_773239 = newJObject()
  add(query_773239, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773239, "Action", newJString(Action))
  add(query_773239, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_773239.add "SecurityGroups", SecurityGroups
  result = call_773238.call(nil, query_773239, nil, nil, nil)

var getApplySecurityGroupsToLoadBalancer* = Call_GetApplySecurityGroupsToLoadBalancer_773223(
    name: "getApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_GetApplySecurityGroupsToLoadBalancer_773224, base: "/",
    url: url_GetApplySecurityGroupsToLoadBalancer_773225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAttachLoadBalancerToSubnets_773275 = ref object of OpenApiRestCall_772597
proc url_PostAttachLoadBalancerToSubnets_773277(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAttachLoadBalancerToSubnets_773276(path: JsonNode;
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
  var valid_773278 = query.getOrDefault("Action")
  valid_773278 = validateParameter(valid_773278, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_773278 != nil:
    section.add "Action", valid_773278
  var valid_773279 = query.getOrDefault("Version")
  valid_773279 = validateParameter(valid_773279, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773279 != nil:
    section.add "Version", valid_773279
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
  var valid_773280 = header.getOrDefault("X-Amz-Date")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Date", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Security-Token")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Security-Token", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Content-Sha256", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Algorithm")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Algorithm", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Signature")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Signature", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-SignedHeaders", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Credential")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Credential", valid_773286
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_773287 = formData.getOrDefault("Subnets")
  valid_773287 = validateParameter(valid_773287, JArray, required = true, default = nil)
  if valid_773287 != nil:
    section.add "Subnets", valid_773287
  var valid_773288 = formData.getOrDefault("LoadBalancerName")
  valid_773288 = validateParameter(valid_773288, JString, required = true,
                                 default = nil)
  if valid_773288 != nil:
    section.add "LoadBalancerName", valid_773288
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773289: Call_PostAttachLoadBalancerToSubnets_773275;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773289.validator(path, query, header, formData, body)
  let scheme = call_773289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773289.url(scheme.get, call_773289.host, call_773289.base,
                         call_773289.route, valid.getOrDefault("path"))
  result = hook(call_773289, url, valid)

proc call*(call_773290: Call_PostAttachLoadBalancerToSubnets_773275;
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
  var query_773291 = newJObject()
  var formData_773292 = newJObject()
  add(query_773291, "Action", newJString(Action))
  if Subnets != nil:
    formData_773292.add "Subnets", Subnets
  add(formData_773292, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773291, "Version", newJString(Version))
  result = call_773290.call(nil, query_773291, nil, formData_773292, nil)

var postAttachLoadBalancerToSubnets* = Call_PostAttachLoadBalancerToSubnets_773275(
    name: "postAttachLoadBalancerToSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_PostAttachLoadBalancerToSubnets_773276, base: "/",
    url: url_PostAttachLoadBalancerToSubnets_773277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttachLoadBalancerToSubnets_773258 = ref object of OpenApiRestCall_772597
proc url_GetAttachLoadBalancerToSubnets_773260(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAttachLoadBalancerToSubnets_773259(path: JsonNode;
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
  var valid_773261 = query.getOrDefault("LoadBalancerName")
  valid_773261 = validateParameter(valid_773261, JString, required = true,
                                 default = nil)
  if valid_773261 != nil:
    section.add "LoadBalancerName", valid_773261
  var valid_773262 = query.getOrDefault("Action")
  valid_773262 = validateParameter(valid_773262, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_773262 != nil:
    section.add "Action", valid_773262
  var valid_773263 = query.getOrDefault("Subnets")
  valid_773263 = validateParameter(valid_773263, JArray, required = true, default = nil)
  if valid_773263 != nil:
    section.add "Subnets", valid_773263
  var valid_773264 = query.getOrDefault("Version")
  valid_773264 = validateParameter(valid_773264, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773264 != nil:
    section.add "Version", valid_773264
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
  var valid_773265 = header.getOrDefault("X-Amz-Date")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Date", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Security-Token")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Security-Token", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Content-Sha256", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Algorithm")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Algorithm", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Signature")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Signature", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-SignedHeaders", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Credential")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Credential", valid_773271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773272: Call_GetAttachLoadBalancerToSubnets_773258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773272.validator(path, query, header, formData, body)
  let scheme = call_773272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773272.url(scheme.get, call_773272.host, call_773272.base,
                         call_773272.route, valid.getOrDefault("path"))
  result = hook(call_773272, url, valid)

proc call*(call_773273: Call_GetAttachLoadBalancerToSubnets_773258;
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
  var query_773274 = newJObject()
  add(query_773274, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773274, "Action", newJString(Action))
  if Subnets != nil:
    query_773274.add "Subnets", Subnets
  add(query_773274, "Version", newJString(Version))
  result = call_773273.call(nil, query_773274, nil, nil, nil)

var getAttachLoadBalancerToSubnets* = Call_GetAttachLoadBalancerToSubnets_773258(
    name: "getAttachLoadBalancerToSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_GetAttachLoadBalancerToSubnets_773259, base: "/",
    url: url_GetAttachLoadBalancerToSubnets_773260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfigureHealthCheck_773314 = ref object of OpenApiRestCall_772597
proc url_PostConfigureHealthCheck_773316(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostConfigureHealthCheck_773315(path: JsonNode; query: JsonNode;
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
  var valid_773317 = query.getOrDefault("Action")
  valid_773317 = validateParameter(valid_773317, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_773317 != nil:
    section.add "Action", valid_773317
  var valid_773318 = query.getOrDefault("Version")
  valid_773318 = validateParameter(valid_773318, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773318 != nil:
    section.add "Version", valid_773318
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
  var valid_773319 = header.getOrDefault("X-Amz-Date")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-Date", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-Security-Token")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Security-Token", valid_773320
  var valid_773321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "X-Amz-Content-Sha256", valid_773321
  var valid_773322 = header.getOrDefault("X-Amz-Algorithm")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-Algorithm", valid_773322
  var valid_773323 = header.getOrDefault("X-Amz-Signature")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-Signature", valid_773323
  var valid_773324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-SignedHeaders", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-Credential")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Credential", valid_773325
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
  var valid_773326 = formData.getOrDefault("HealthCheck.HealthyThreshold")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_773326
  var valid_773327 = formData.getOrDefault("HealthCheck.Interval")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "HealthCheck.Interval", valid_773327
  var valid_773328 = formData.getOrDefault("HealthCheck.Timeout")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "HealthCheck.Timeout", valid_773328
  var valid_773329 = formData.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_773329
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_773330 = formData.getOrDefault("LoadBalancerName")
  valid_773330 = validateParameter(valid_773330, JString, required = true,
                                 default = nil)
  if valid_773330 != nil:
    section.add "LoadBalancerName", valid_773330
  var valid_773331 = formData.getOrDefault("HealthCheck.Target")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "HealthCheck.Target", valid_773331
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773332: Call_PostConfigureHealthCheck_773314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773332.validator(path, query, header, formData, body)
  let scheme = call_773332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773332.url(scheme.get, call_773332.host, call_773332.base,
                         call_773332.route, valid.getOrDefault("path"))
  result = hook(call_773332, url, valid)

proc call*(call_773333: Call_PostConfigureHealthCheck_773314;
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
  var query_773334 = newJObject()
  var formData_773335 = newJObject()
  add(formData_773335, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(formData_773335, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(formData_773335, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_773334, "Action", newJString(Action))
  add(formData_773335, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(formData_773335, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_773335, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_773334, "Version", newJString(Version))
  result = call_773333.call(nil, query_773334, nil, formData_773335, nil)

var postConfigureHealthCheck* = Call_PostConfigureHealthCheck_773314(
    name: "postConfigureHealthCheck", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_PostConfigureHealthCheck_773315, base: "/",
    url: url_PostConfigureHealthCheck_773316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigureHealthCheck_773293 = ref object of OpenApiRestCall_772597
proc url_GetConfigureHealthCheck_773295(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConfigureHealthCheck_773294(path: JsonNode; query: JsonNode;
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
  var valid_773296 = query.getOrDefault("HealthCheck.HealthyThreshold")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_773296
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_773297 = query.getOrDefault("LoadBalancerName")
  valid_773297 = validateParameter(valid_773297, JString, required = true,
                                 default = nil)
  if valid_773297 != nil:
    section.add "LoadBalancerName", valid_773297
  var valid_773298 = query.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_773298
  var valid_773299 = query.getOrDefault("HealthCheck.Timeout")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "HealthCheck.Timeout", valid_773299
  var valid_773300 = query.getOrDefault("HealthCheck.Target")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "HealthCheck.Target", valid_773300
  var valid_773301 = query.getOrDefault("Action")
  valid_773301 = validateParameter(valid_773301, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_773301 != nil:
    section.add "Action", valid_773301
  var valid_773302 = query.getOrDefault("HealthCheck.Interval")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "HealthCheck.Interval", valid_773302
  var valid_773303 = query.getOrDefault("Version")
  valid_773303 = validateParameter(valid_773303, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773303 != nil:
    section.add "Version", valid_773303
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
  var valid_773304 = header.getOrDefault("X-Amz-Date")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-Date", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-Security-Token")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Security-Token", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Content-Sha256", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Algorithm")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Algorithm", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Signature")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Signature", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-SignedHeaders", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Credential")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Credential", valid_773310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773311: Call_GetConfigureHealthCheck_773293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773311.validator(path, query, header, formData, body)
  let scheme = call_773311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773311.url(scheme.get, call_773311.host, call_773311.base,
                         call_773311.route, valid.getOrDefault("path"))
  result = hook(call_773311, url, valid)

proc call*(call_773312: Call_GetConfigureHealthCheck_773293;
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
  var query_773313 = newJObject()
  add(query_773313, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(query_773313, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773313, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(query_773313, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_773313, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_773313, "Action", newJString(Action))
  add(query_773313, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(query_773313, "Version", newJString(Version))
  result = call_773312.call(nil, query_773313, nil, nil, nil)

var getConfigureHealthCheck* = Call_GetConfigureHealthCheck_773293(
    name: "getConfigureHealthCheck", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_GetConfigureHealthCheck_773294, base: "/",
    url: url_GetConfigureHealthCheck_773295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateAppCookieStickinessPolicy_773354 = ref object of OpenApiRestCall_772597
proc url_PostCreateAppCookieStickinessPolicy_773356(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateAppCookieStickinessPolicy_773355(path: JsonNode;
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
  var valid_773357 = query.getOrDefault("Action")
  valid_773357 = validateParameter(valid_773357, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_773357 != nil:
    section.add "Action", valid_773357
  var valid_773358 = query.getOrDefault("Version")
  valid_773358 = validateParameter(valid_773358, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773358 != nil:
    section.add "Version", valid_773358
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
  var valid_773359 = header.getOrDefault("X-Amz-Date")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Date", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Security-Token")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Security-Token", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Content-Sha256", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Algorithm")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Algorithm", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-Signature")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-Signature", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-SignedHeaders", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-Credential")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Credential", valid_773365
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
  var valid_773366 = formData.getOrDefault("PolicyName")
  valid_773366 = validateParameter(valid_773366, JString, required = true,
                                 default = nil)
  if valid_773366 != nil:
    section.add "PolicyName", valid_773366
  var valid_773367 = formData.getOrDefault("CookieName")
  valid_773367 = validateParameter(valid_773367, JString, required = true,
                                 default = nil)
  if valid_773367 != nil:
    section.add "CookieName", valid_773367
  var valid_773368 = formData.getOrDefault("LoadBalancerName")
  valid_773368 = validateParameter(valid_773368, JString, required = true,
                                 default = nil)
  if valid_773368 != nil:
    section.add "LoadBalancerName", valid_773368
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773369: Call_PostCreateAppCookieStickinessPolicy_773354;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773369.validator(path, query, header, formData, body)
  let scheme = call_773369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773369.url(scheme.get, call_773369.host, call_773369.base,
                         call_773369.route, valid.getOrDefault("path"))
  result = hook(call_773369, url, valid)

proc call*(call_773370: Call_PostCreateAppCookieStickinessPolicy_773354;
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
  var query_773371 = newJObject()
  var formData_773372 = newJObject()
  add(formData_773372, "PolicyName", newJString(PolicyName))
  add(formData_773372, "CookieName", newJString(CookieName))
  add(query_773371, "Action", newJString(Action))
  add(formData_773372, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773371, "Version", newJString(Version))
  result = call_773370.call(nil, query_773371, nil, formData_773372, nil)

var postCreateAppCookieStickinessPolicy* = Call_PostCreateAppCookieStickinessPolicy_773354(
    name: "postCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_PostCreateAppCookieStickinessPolicy_773355, base: "/",
    url: url_PostCreateAppCookieStickinessPolicy_773356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateAppCookieStickinessPolicy_773336 = ref object of OpenApiRestCall_772597
proc url_GetCreateAppCookieStickinessPolicy_773338(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateAppCookieStickinessPolicy_773337(path: JsonNode;
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
  var valid_773339 = query.getOrDefault("LoadBalancerName")
  valid_773339 = validateParameter(valid_773339, JString, required = true,
                                 default = nil)
  if valid_773339 != nil:
    section.add "LoadBalancerName", valid_773339
  var valid_773340 = query.getOrDefault("Action")
  valid_773340 = validateParameter(valid_773340, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_773340 != nil:
    section.add "Action", valid_773340
  var valid_773341 = query.getOrDefault("CookieName")
  valid_773341 = validateParameter(valid_773341, JString, required = true,
                                 default = nil)
  if valid_773341 != nil:
    section.add "CookieName", valid_773341
  var valid_773342 = query.getOrDefault("Version")
  valid_773342 = validateParameter(valid_773342, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773342 != nil:
    section.add "Version", valid_773342
  var valid_773343 = query.getOrDefault("PolicyName")
  valid_773343 = validateParameter(valid_773343, JString, required = true,
                                 default = nil)
  if valid_773343 != nil:
    section.add "PolicyName", valid_773343
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
  var valid_773344 = header.getOrDefault("X-Amz-Date")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Date", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Security-Token")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Security-Token", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Content-Sha256", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Algorithm")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Algorithm", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Signature")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Signature", valid_773348
  var valid_773349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-SignedHeaders", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Credential")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Credential", valid_773350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773351: Call_GetCreateAppCookieStickinessPolicy_773336;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773351.validator(path, query, header, formData, body)
  let scheme = call_773351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773351.url(scheme.get, call_773351.host, call_773351.base,
                         call_773351.route, valid.getOrDefault("path"))
  result = hook(call_773351, url, valid)

proc call*(call_773352: Call_GetCreateAppCookieStickinessPolicy_773336;
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
  var query_773353 = newJObject()
  add(query_773353, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773353, "Action", newJString(Action))
  add(query_773353, "CookieName", newJString(CookieName))
  add(query_773353, "Version", newJString(Version))
  add(query_773353, "PolicyName", newJString(PolicyName))
  result = call_773352.call(nil, query_773353, nil, nil, nil)

var getCreateAppCookieStickinessPolicy* = Call_GetCreateAppCookieStickinessPolicy_773336(
    name: "getCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_GetCreateAppCookieStickinessPolicy_773337, base: "/",
    url: url_GetCreateAppCookieStickinessPolicy_773338,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLBCookieStickinessPolicy_773391 = ref object of OpenApiRestCall_772597
proc url_PostCreateLBCookieStickinessPolicy_773393(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateLBCookieStickinessPolicy_773392(path: JsonNode;
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
  var valid_773394 = query.getOrDefault("Action")
  valid_773394 = validateParameter(valid_773394, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_773394 != nil:
    section.add "Action", valid_773394
  var valid_773395 = query.getOrDefault("Version")
  valid_773395 = validateParameter(valid_773395, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773395 != nil:
    section.add "Version", valid_773395
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
  var valid_773396 = header.getOrDefault("X-Amz-Date")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-Date", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Security-Token")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Security-Token", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Content-Sha256", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Algorithm")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Algorithm", valid_773399
  var valid_773400 = header.getOrDefault("X-Amz-Signature")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Signature", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-SignedHeaders", valid_773401
  var valid_773402 = header.getOrDefault("X-Amz-Credential")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Credential", valid_773402
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
  var valid_773403 = formData.getOrDefault("PolicyName")
  valid_773403 = validateParameter(valid_773403, JString, required = true,
                                 default = nil)
  if valid_773403 != nil:
    section.add "PolicyName", valid_773403
  var valid_773404 = formData.getOrDefault("LoadBalancerName")
  valid_773404 = validateParameter(valid_773404, JString, required = true,
                                 default = nil)
  if valid_773404 != nil:
    section.add "LoadBalancerName", valid_773404
  var valid_773405 = formData.getOrDefault("CookieExpirationPeriod")
  valid_773405 = validateParameter(valid_773405, JInt, required = false, default = nil)
  if valid_773405 != nil:
    section.add "CookieExpirationPeriod", valid_773405
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773406: Call_PostCreateLBCookieStickinessPolicy_773391;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773406.validator(path, query, header, formData, body)
  let scheme = call_773406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773406.url(scheme.get, call_773406.host, call_773406.base,
                         call_773406.route, valid.getOrDefault("path"))
  result = hook(call_773406, url, valid)

proc call*(call_773407: Call_PostCreateLBCookieStickinessPolicy_773391;
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
  var query_773408 = newJObject()
  var formData_773409 = newJObject()
  add(formData_773409, "PolicyName", newJString(PolicyName))
  add(query_773408, "Action", newJString(Action))
  add(formData_773409, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773408, "Version", newJString(Version))
  add(formData_773409, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  result = call_773407.call(nil, query_773408, nil, formData_773409, nil)

var postCreateLBCookieStickinessPolicy* = Call_PostCreateLBCookieStickinessPolicy_773391(
    name: "postCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_PostCreateLBCookieStickinessPolicy_773392, base: "/",
    url: url_PostCreateLBCookieStickinessPolicy_773393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLBCookieStickinessPolicy_773373 = ref object of OpenApiRestCall_772597
proc url_GetCreateLBCookieStickinessPolicy_773375(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateLBCookieStickinessPolicy_773374(path: JsonNode;
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
  var valid_773376 = query.getOrDefault("CookieExpirationPeriod")
  valid_773376 = validateParameter(valid_773376, JInt, required = false, default = nil)
  if valid_773376 != nil:
    section.add "CookieExpirationPeriod", valid_773376
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_773377 = query.getOrDefault("LoadBalancerName")
  valid_773377 = validateParameter(valid_773377, JString, required = true,
                                 default = nil)
  if valid_773377 != nil:
    section.add "LoadBalancerName", valid_773377
  var valid_773378 = query.getOrDefault("Action")
  valid_773378 = validateParameter(valid_773378, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_773378 != nil:
    section.add "Action", valid_773378
  var valid_773379 = query.getOrDefault("Version")
  valid_773379 = validateParameter(valid_773379, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773379 != nil:
    section.add "Version", valid_773379
  var valid_773380 = query.getOrDefault("PolicyName")
  valid_773380 = validateParameter(valid_773380, JString, required = true,
                                 default = nil)
  if valid_773380 != nil:
    section.add "PolicyName", valid_773380
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
  var valid_773381 = header.getOrDefault("X-Amz-Date")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "X-Amz-Date", valid_773381
  var valid_773382 = header.getOrDefault("X-Amz-Security-Token")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-Security-Token", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Content-Sha256", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-Algorithm")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-Algorithm", valid_773384
  var valid_773385 = header.getOrDefault("X-Amz-Signature")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Signature", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-SignedHeaders", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Credential")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Credential", valid_773387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773388: Call_GetCreateLBCookieStickinessPolicy_773373;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773388.validator(path, query, header, formData, body)
  let scheme = call_773388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773388.url(scheme.get, call_773388.host, call_773388.base,
                         call_773388.route, valid.getOrDefault("path"))
  result = hook(call_773388, url, valid)

proc call*(call_773389: Call_GetCreateLBCookieStickinessPolicy_773373;
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
  var query_773390 = newJObject()
  add(query_773390, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(query_773390, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773390, "Action", newJString(Action))
  add(query_773390, "Version", newJString(Version))
  add(query_773390, "PolicyName", newJString(PolicyName))
  result = call_773389.call(nil, query_773390, nil, nil, nil)

var getCreateLBCookieStickinessPolicy* = Call_GetCreateLBCookieStickinessPolicy_773373(
    name: "getCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_GetCreateLBCookieStickinessPolicy_773374, base: "/",
    url: url_GetCreateLBCookieStickinessPolicy_773375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_773432 = ref object of OpenApiRestCall_772597
proc url_PostCreateLoadBalancer_773434(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateLoadBalancer_773433(path: JsonNode; query: JsonNode;
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
  var valid_773435 = query.getOrDefault("Action")
  valid_773435 = validateParameter(valid_773435, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_773435 != nil:
    section.add "Action", valid_773435
  var valid_773436 = query.getOrDefault("Version")
  valid_773436 = validateParameter(valid_773436, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773436 != nil:
    section.add "Version", valid_773436
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
  var valid_773437 = header.getOrDefault("X-Amz-Date")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Date", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Security-Token")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Security-Token", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Content-Sha256", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Algorithm")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Algorithm", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Signature")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Signature", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-SignedHeaders", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Credential")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Credential", valid_773443
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
  var valid_773444 = formData.getOrDefault("Tags")
  valid_773444 = validateParameter(valid_773444, JArray, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "Tags", valid_773444
  var valid_773445 = formData.getOrDefault("AvailabilityZones")
  valid_773445 = validateParameter(valid_773445, JArray, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "AvailabilityZones", valid_773445
  var valid_773446 = formData.getOrDefault("Subnets")
  valid_773446 = validateParameter(valid_773446, JArray, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "Subnets", valid_773446
  var valid_773447 = formData.getOrDefault("SecurityGroups")
  valid_773447 = validateParameter(valid_773447, JArray, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "SecurityGroups", valid_773447
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_773448 = formData.getOrDefault("LoadBalancerName")
  valid_773448 = validateParameter(valid_773448, JString, required = true,
                                 default = nil)
  if valid_773448 != nil:
    section.add "LoadBalancerName", valid_773448
  var valid_773449 = formData.getOrDefault("Scheme")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "Scheme", valid_773449
  var valid_773450 = formData.getOrDefault("Listeners")
  valid_773450 = validateParameter(valid_773450, JArray, required = true, default = nil)
  if valid_773450 != nil:
    section.add "Listeners", valid_773450
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773451: Call_PostCreateLoadBalancer_773432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773451.validator(path, query, header, formData, body)
  let scheme = call_773451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773451.url(scheme.get, call_773451.host, call_773451.base,
                         call_773451.route, valid.getOrDefault("path"))
  result = hook(call_773451, url, valid)

proc call*(call_773452: Call_PostCreateLoadBalancer_773432;
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
  var query_773453 = newJObject()
  var formData_773454 = newJObject()
  if Tags != nil:
    formData_773454.add "Tags", Tags
  add(query_773453, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_773454.add "AvailabilityZones", AvailabilityZones
  if Subnets != nil:
    formData_773454.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_773454.add "SecurityGroups", SecurityGroups
  add(formData_773454, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_773454, "Scheme", newJString(Scheme))
  if Listeners != nil:
    formData_773454.add "Listeners", Listeners
  add(query_773453, "Version", newJString(Version))
  result = call_773452.call(nil, query_773453, nil, formData_773454, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_773432(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_773433, base: "/",
    url: url_PostCreateLoadBalancer_773434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_773410 = ref object of OpenApiRestCall_772597
proc url_GetCreateLoadBalancer_773412(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateLoadBalancer_773411(path: JsonNode; query: JsonNode;
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
  var valid_773413 = query.getOrDefault("LoadBalancerName")
  valid_773413 = validateParameter(valid_773413, JString, required = true,
                                 default = nil)
  if valid_773413 != nil:
    section.add "LoadBalancerName", valid_773413
  var valid_773414 = query.getOrDefault("AvailabilityZones")
  valid_773414 = validateParameter(valid_773414, JArray, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "AvailabilityZones", valid_773414
  var valid_773415 = query.getOrDefault("Scheme")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "Scheme", valid_773415
  var valid_773416 = query.getOrDefault("Tags")
  valid_773416 = validateParameter(valid_773416, JArray, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "Tags", valid_773416
  var valid_773417 = query.getOrDefault("Action")
  valid_773417 = validateParameter(valid_773417, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_773417 != nil:
    section.add "Action", valid_773417
  var valid_773418 = query.getOrDefault("Subnets")
  valid_773418 = validateParameter(valid_773418, JArray, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "Subnets", valid_773418
  var valid_773419 = query.getOrDefault("Version")
  valid_773419 = validateParameter(valid_773419, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773419 != nil:
    section.add "Version", valid_773419
  var valid_773420 = query.getOrDefault("Listeners")
  valid_773420 = validateParameter(valid_773420, JArray, required = true, default = nil)
  if valid_773420 != nil:
    section.add "Listeners", valid_773420
  var valid_773421 = query.getOrDefault("SecurityGroups")
  valid_773421 = validateParameter(valid_773421, JArray, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "SecurityGroups", valid_773421
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
  var valid_773422 = header.getOrDefault("X-Amz-Date")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Date", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Security-Token")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Security-Token", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Content-Sha256", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Algorithm")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Algorithm", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Signature")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Signature", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-SignedHeaders", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Credential")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Credential", valid_773428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773429: Call_GetCreateLoadBalancer_773410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773429.validator(path, query, header, formData, body)
  let scheme = call_773429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773429.url(scheme.get, call_773429.host, call_773429.base,
                         call_773429.route, valid.getOrDefault("path"))
  result = hook(call_773429, url, valid)

proc call*(call_773430: Call_GetCreateLoadBalancer_773410;
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
  var query_773431 = newJObject()
  add(query_773431, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_773431.add "AvailabilityZones", AvailabilityZones
  add(query_773431, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_773431.add "Tags", Tags
  add(query_773431, "Action", newJString(Action))
  if Subnets != nil:
    query_773431.add "Subnets", Subnets
  add(query_773431, "Version", newJString(Version))
  if Listeners != nil:
    query_773431.add "Listeners", Listeners
  if SecurityGroups != nil:
    query_773431.add "SecurityGroups", SecurityGroups
  result = call_773430.call(nil, query_773431, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_773410(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_773411, base: "/",
    url: url_GetCreateLoadBalancer_773412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerListeners_773472 = ref object of OpenApiRestCall_772597
proc url_PostCreateLoadBalancerListeners_773474(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateLoadBalancerListeners_773473(path: JsonNode;
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
  var valid_773475 = query.getOrDefault("Action")
  valid_773475 = validateParameter(valid_773475, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_773475 != nil:
    section.add "Action", valid_773475
  var valid_773476 = query.getOrDefault("Version")
  valid_773476 = validateParameter(valid_773476, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773476 != nil:
    section.add "Version", valid_773476
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
  var valid_773477 = header.getOrDefault("X-Amz-Date")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "X-Amz-Date", valid_773477
  var valid_773478 = header.getOrDefault("X-Amz-Security-Token")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Security-Token", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Content-Sha256", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Algorithm")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Algorithm", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-Signature")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-Signature", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-SignedHeaders", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Credential")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Credential", valid_773483
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_773484 = formData.getOrDefault("LoadBalancerName")
  valid_773484 = validateParameter(valid_773484, JString, required = true,
                                 default = nil)
  if valid_773484 != nil:
    section.add "LoadBalancerName", valid_773484
  var valid_773485 = formData.getOrDefault("Listeners")
  valid_773485 = validateParameter(valid_773485, JArray, required = true, default = nil)
  if valid_773485 != nil:
    section.add "Listeners", valid_773485
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773486: Call_PostCreateLoadBalancerListeners_773472;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773486.validator(path, query, header, formData, body)
  let scheme = call_773486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773486.url(scheme.get, call_773486.host, call_773486.base,
                         call_773486.route, valid.getOrDefault("path"))
  result = hook(call_773486, url, valid)

proc call*(call_773487: Call_PostCreateLoadBalancerListeners_773472;
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
  var query_773488 = newJObject()
  var formData_773489 = newJObject()
  add(query_773488, "Action", newJString(Action))
  add(formData_773489, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_773489.add "Listeners", Listeners
  add(query_773488, "Version", newJString(Version))
  result = call_773487.call(nil, query_773488, nil, formData_773489, nil)

var postCreateLoadBalancerListeners* = Call_PostCreateLoadBalancerListeners_773472(
    name: "postCreateLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_PostCreateLoadBalancerListeners_773473, base: "/",
    url: url_PostCreateLoadBalancerListeners_773474,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerListeners_773455 = ref object of OpenApiRestCall_772597
proc url_GetCreateLoadBalancerListeners_773457(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateLoadBalancerListeners_773456(path: JsonNode;
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
  var valid_773458 = query.getOrDefault("LoadBalancerName")
  valid_773458 = validateParameter(valid_773458, JString, required = true,
                                 default = nil)
  if valid_773458 != nil:
    section.add "LoadBalancerName", valid_773458
  var valid_773459 = query.getOrDefault("Action")
  valid_773459 = validateParameter(valid_773459, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_773459 != nil:
    section.add "Action", valid_773459
  var valid_773460 = query.getOrDefault("Version")
  valid_773460 = validateParameter(valid_773460, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773460 != nil:
    section.add "Version", valid_773460
  var valid_773461 = query.getOrDefault("Listeners")
  valid_773461 = validateParameter(valid_773461, JArray, required = true, default = nil)
  if valid_773461 != nil:
    section.add "Listeners", valid_773461
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
  var valid_773462 = header.getOrDefault("X-Amz-Date")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "X-Amz-Date", valid_773462
  var valid_773463 = header.getOrDefault("X-Amz-Security-Token")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Security-Token", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Content-Sha256", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Algorithm")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Algorithm", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Signature")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Signature", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-SignedHeaders", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Credential")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Credential", valid_773468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773469: Call_GetCreateLoadBalancerListeners_773455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773469.validator(path, query, header, formData, body)
  let scheme = call_773469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773469.url(scheme.get, call_773469.host, call_773469.base,
                         call_773469.route, valid.getOrDefault("path"))
  result = hook(call_773469, url, valid)

proc call*(call_773470: Call_GetCreateLoadBalancerListeners_773455;
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
  var query_773471 = newJObject()
  add(query_773471, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773471, "Action", newJString(Action))
  add(query_773471, "Version", newJString(Version))
  if Listeners != nil:
    query_773471.add "Listeners", Listeners
  result = call_773470.call(nil, query_773471, nil, nil, nil)

var getCreateLoadBalancerListeners* = Call_GetCreateLoadBalancerListeners_773455(
    name: "getCreateLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_GetCreateLoadBalancerListeners_773456, base: "/",
    url: url_GetCreateLoadBalancerListeners_773457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerPolicy_773509 = ref object of OpenApiRestCall_772597
proc url_PostCreateLoadBalancerPolicy_773511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateLoadBalancerPolicy_773510(path: JsonNode; query: JsonNode;
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
  var valid_773512 = query.getOrDefault("Action")
  valid_773512 = validateParameter(valid_773512, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_773512 != nil:
    section.add "Action", valid_773512
  var valid_773513 = query.getOrDefault("Version")
  valid_773513 = validateParameter(valid_773513, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773513 != nil:
    section.add "Version", valid_773513
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
  var valid_773514 = header.getOrDefault("X-Amz-Date")
  valid_773514 = validateParameter(valid_773514, JString, required = false,
                                 default = nil)
  if valid_773514 != nil:
    section.add "X-Amz-Date", valid_773514
  var valid_773515 = header.getOrDefault("X-Amz-Security-Token")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Security-Token", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Content-Sha256", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-Algorithm")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Algorithm", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Signature")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Signature", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-SignedHeaders", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Credential")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Credential", valid_773520
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
  var valid_773521 = formData.getOrDefault("PolicyName")
  valid_773521 = validateParameter(valid_773521, JString, required = true,
                                 default = nil)
  if valid_773521 != nil:
    section.add "PolicyName", valid_773521
  var valid_773522 = formData.getOrDefault("PolicyTypeName")
  valid_773522 = validateParameter(valid_773522, JString, required = true,
                                 default = nil)
  if valid_773522 != nil:
    section.add "PolicyTypeName", valid_773522
  var valid_773523 = formData.getOrDefault("PolicyAttributes")
  valid_773523 = validateParameter(valid_773523, JArray, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "PolicyAttributes", valid_773523
  var valid_773524 = formData.getOrDefault("LoadBalancerName")
  valid_773524 = validateParameter(valid_773524, JString, required = true,
                                 default = nil)
  if valid_773524 != nil:
    section.add "LoadBalancerName", valid_773524
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773525: Call_PostCreateLoadBalancerPolicy_773509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_773525.validator(path, query, header, formData, body)
  let scheme = call_773525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773525.url(scheme.get, call_773525.host, call_773525.base,
                         call_773525.route, valid.getOrDefault("path"))
  result = hook(call_773525, url, valid)

proc call*(call_773526: Call_PostCreateLoadBalancerPolicy_773509;
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
  var query_773527 = newJObject()
  var formData_773528 = newJObject()
  add(formData_773528, "PolicyName", newJString(PolicyName))
  add(formData_773528, "PolicyTypeName", newJString(PolicyTypeName))
  if PolicyAttributes != nil:
    formData_773528.add "PolicyAttributes", PolicyAttributes
  add(query_773527, "Action", newJString(Action))
  add(formData_773528, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773527, "Version", newJString(Version))
  result = call_773526.call(nil, query_773527, nil, formData_773528, nil)

var postCreateLoadBalancerPolicy* = Call_PostCreateLoadBalancerPolicy_773509(
    name: "postCreateLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_PostCreateLoadBalancerPolicy_773510, base: "/",
    url: url_PostCreateLoadBalancerPolicy_773511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerPolicy_773490 = ref object of OpenApiRestCall_772597
proc url_GetCreateLoadBalancerPolicy_773492(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateLoadBalancerPolicy_773491(path: JsonNode; query: JsonNode;
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
  var valid_773493 = query.getOrDefault("LoadBalancerName")
  valid_773493 = validateParameter(valid_773493, JString, required = true,
                                 default = nil)
  if valid_773493 != nil:
    section.add "LoadBalancerName", valid_773493
  var valid_773494 = query.getOrDefault("PolicyAttributes")
  valid_773494 = validateParameter(valid_773494, JArray, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "PolicyAttributes", valid_773494
  var valid_773495 = query.getOrDefault("Action")
  valid_773495 = validateParameter(valid_773495, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_773495 != nil:
    section.add "Action", valid_773495
  var valid_773496 = query.getOrDefault("PolicyTypeName")
  valid_773496 = validateParameter(valid_773496, JString, required = true,
                                 default = nil)
  if valid_773496 != nil:
    section.add "PolicyTypeName", valid_773496
  var valid_773497 = query.getOrDefault("Version")
  valid_773497 = validateParameter(valid_773497, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773497 != nil:
    section.add "Version", valid_773497
  var valid_773498 = query.getOrDefault("PolicyName")
  valid_773498 = validateParameter(valid_773498, JString, required = true,
                                 default = nil)
  if valid_773498 != nil:
    section.add "PolicyName", valid_773498
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
  var valid_773499 = header.getOrDefault("X-Amz-Date")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "X-Amz-Date", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Security-Token")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Security-Token", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Content-Sha256", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Algorithm")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Algorithm", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Signature")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Signature", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-SignedHeaders", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-Credential")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Credential", valid_773505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773506: Call_GetCreateLoadBalancerPolicy_773490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_773506.validator(path, query, header, formData, body)
  let scheme = call_773506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773506.url(scheme.get, call_773506.host, call_773506.base,
                         call_773506.route, valid.getOrDefault("path"))
  result = hook(call_773506, url, valid)

proc call*(call_773507: Call_GetCreateLoadBalancerPolicy_773490;
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
  var query_773508 = newJObject()
  add(query_773508, "LoadBalancerName", newJString(LoadBalancerName))
  if PolicyAttributes != nil:
    query_773508.add "PolicyAttributes", PolicyAttributes
  add(query_773508, "Action", newJString(Action))
  add(query_773508, "PolicyTypeName", newJString(PolicyTypeName))
  add(query_773508, "Version", newJString(Version))
  add(query_773508, "PolicyName", newJString(PolicyName))
  result = call_773507.call(nil, query_773508, nil, nil, nil)

var getCreateLoadBalancerPolicy* = Call_GetCreateLoadBalancerPolicy_773490(
    name: "getCreateLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_GetCreateLoadBalancerPolicy_773491, base: "/",
    url: url_GetCreateLoadBalancerPolicy_773492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_773545 = ref object of OpenApiRestCall_772597
proc url_PostDeleteLoadBalancer_773547(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteLoadBalancer_773546(path: JsonNode; query: JsonNode;
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
  var valid_773548 = query.getOrDefault("Action")
  valid_773548 = validateParameter(valid_773548, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_773548 != nil:
    section.add "Action", valid_773548
  var valid_773549 = query.getOrDefault("Version")
  valid_773549 = validateParameter(valid_773549, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773549 != nil:
    section.add "Version", valid_773549
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
  var valid_773550 = header.getOrDefault("X-Amz-Date")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Date", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Security-Token")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Security-Token", valid_773551
  var valid_773552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Content-Sha256", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Algorithm")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Algorithm", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Signature")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Signature", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-SignedHeaders", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-Credential")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-Credential", valid_773556
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_773557 = formData.getOrDefault("LoadBalancerName")
  valid_773557 = validateParameter(valid_773557, JString, required = true,
                                 default = nil)
  if valid_773557 != nil:
    section.add "LoadBalancerName", valid_773557
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773558: Call_PostDeleteLoadBalancer_773545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_773558.validator(path, query, header, formData, body)
  let scheme = call_773558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773558.url(scheme.get, call_773558.host, call_773558.base,
                         call_773558.route, valid.getOrDefault("path"))
  result = hook(call_773558, url, valid)

proc call*(call_773559: Call_PostDeleteLoadBalancer_773545;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_773560 = newJObject()
  var formData_773561 = newJObject()
  add(query_773560, "Action", newJString(Action))
  add(formData_773561, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773560, "Version", newJString(Version))
  result = call_773559.call(nil, query_773560, nil, formData_773561, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_773545(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_773546, base: "/",
    url: url_PostDeleteLoadBalancer_773547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_773529 = ref object of OpenApiRestCall_772597
proc url_GetDeleteLoadBalancer_773531(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteLoadBalancer_773530(path: JsonNode; query: JsonNode;
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
  var valid_773532 = query.getOrDefault("LoadBalancerName")
  valid_773532 = validateParameter(valid_773532, JString, required = true,
                                 default = nil)
  if valid_773532 != nil:
    section.add "LoadBalancerName", valid_773532
  var valid_773533 = query.getOrDefault("Action")
  valid_773533 = validateParameter(valid_773533, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_773533 != nil:
    section.add "Action", valid_773533
  var valid_773534 = query.getOrDefault("Version")
  valid_773534 = validateParameter(valid_773534, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773534 != nil:
    section.add "Version", valid_773534
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
  var valid_773535 = header.getOrDefault("X-Amz-Date")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Date", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Security-Token")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Security-Token", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Content-Sha256", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Algorithm")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Algorithm", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Signature")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Signature", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-SignedHeaders", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-Credential")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-Credential", valid_773541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773542: Call_GetDeleteLoadBalancer_773529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_773542.validator(path, query, header, formData, body)
  let scheme = call_773542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773542.url(scheme.get, call_773542.host, call_773542.base,
                         call_773542.route, valid.getOrDefault("path"))
  result = hook(call_773542, url, valid)

proc call*(call_773543: Call_GetDeleteLoadBalancer_773529;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773544 = newJObject()
  add(query_773544, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773544, "Action", newJString(Action))
  add(query_773544, "Version", newJString(Version))
  result = call_773543.call(nil, query_773544, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_773529(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_773530, base: "/",
    url: url_GetDeleteLoadBalancer_773531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerListeners_773579 = ref object of OpenApiRestCall_772597
proc url_PostDeleteLoadBalancerListeners_773581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteLoadBalancerListeners_773580(path: JsonNode;
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
  var valid_773582 = query.getOrDefault("Action")
  valid_773582 = validateParameter(valid_773582, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_773582 != nil:
    section.add "Action", valid_773582
  var valid_773583 = query.getOrDefault("Version")
  valid_773583 = validateParameter(valid_773583, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773583 != nil:
    section.add "Version", valid_773583
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
  var valid_773584 = header.getOrDefault("X-Amz-Date")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Date", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-Security-Token")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Security-Token", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-Content-Sha256", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Algorithm")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Algorithm", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Signature")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Signature", valid_773588
  var valid_773589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "X-Amz-SignedHeaders", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-Credential")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-Credential", valid_773590
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_773591 = formData.getOrDefault("LoadBalancerName")
  valid_773591 = validateParameter(valid_773591, JString, required = true,
                                 default = nil)
  if valid_773591 != nil:
    section.add "LoadBalancerName", valid_773591
  var valid_773592 = formData.getOrDefault("LoadBalancerPorts")
  valid_773592 = validateParameter(valid_773592, JArray, required = true, default = nil)
  if valid_773592 != nil:
    section.add "LoadBalancerPorts", valid_773592
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773593: Call_PostDeleteLoadBalancerListeners_773579;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_773593.validator(path, query, header, formData, body)
  let scheme = call_773593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773593.url(scheme.get, call_773593.host, call_773593.base,
                         call_773593.route, valid.getOrDefault("path"))
  result = hook(call_773593, url, valid)

proc call*(call_773594: Call_PostDeleteLoadBalancerListeners_773579;
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
  var query_773595 = newJObject()
  var formData_773596 = newJObject()
  add(query_773595, "Action", newJString(Action))
  add(formData_773596, "LoadBalancerName", newJString(LoadBalancerName))
  if LoadBalancerPorts != nil:
    formData_773596.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_773595, "Version", newJString(Version))
  result = call_773594.call(nil, query_773595, nil, formData_773596, nil)

var postDeleteLoadBalancerListeners* = Call_PostDeleteLoadBalancerListeners_773579(
    name: "postDeleteLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_PostDeleteLoadBalancerListeners_773580, base: "/",
    url: url_PostDeleteLoadBalancerListeners_773581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerListeners_773562 = ref object of OpenApiRestCall_772597
proc url_GetDeleteLoadBalancerListeners_773564(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteLoadBalancerListeners_773563(path: JsonNode;
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
  var valid_773565 = query.getOrDefault("LoadBalancerName")
  valid_773565 = validateParameter(valid_773565, JString, required = true,
                                 default = nil)
  if valid_773565 != nil:
    section.add "LoadBalancerName", valid_773565
  var valid_773566 = query.getOrDefault("Action")
  valid_773566 = validateParameter(valid_773566, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_773566 != nil:
    section.add "Action", valid_773566
  var valid_773567 = query.getOrDefault("LoadBalancerPorts")
  valid_773567 = validateParameter(valid_773567, JArray, required = true, default = nil)
  if valid_773567 != nil:
    section.add "LoadBalancerPorts", valid_773567
  var valid_773568 = query.getOrDefault("Version")
  valid_773568 = validateParameter(valid_773568, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773568 != nil:
    section.add "Version", valid_773568
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
  var valid_773569 = header.getOrDefault("X-Amz-Date")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Date", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Security-Token")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Security-Token", valid_773570
  var valid_773571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "X-Amz-Content-Sha256", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Algorithm")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Algorithm", valid_773572
  var valid_773573 = header.getOrDefault("X-Amz-Signature")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "X-Amz-Signature", valid_773573
  var valid_773574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "X-Amz-SignedHeaders", valid_773574
  var valid_773575 = header.getOrDefault("X-Amz-Credential")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-Credential", valid_773575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773576: Call_GetDeleteLoadBalancerListeners_773562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_773576.validator(path, query, header, formData, body)
  let scheme = call_773576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773576.url(scheme.get, call_773576.host, call_773576.base,
                         call_773576.route, valid.getOrDefault("path"))
  result = hook(call_773576, url, valid)

proc call*(call_773577: Call_GetDeleteLoadBalancerListeners_773562;
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
  var query_773578 = newJObject()
  add(query_773578, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773578, "Action", newJString(Action))
  if LoadBalancerPorts != nil:
    query_773578.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_773578, "Version", newJString(Version))
  result = call_773577.call(nil, query_773578, nil, nil, nil)

var getDeleteLoadBalancerListeners* = Call_GetDeleteLoadBalancerListeners_773562(
    name: "getDeleteLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_GetDeleteLoadBalancerListeners_773563, base: "/",
    url: url_GetDeleteLoadBalancerListeners_773564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerPolicy_773614 = ref object of OpenApiRestCall_772597
proc url_PostDeleteLoadBalancerPolicy_773616(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteLoadBalancerPolicy_773615(path: JsonNode; query: JsonNode;
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
  var valid_773617 = query.getOrDefault("Action")
  valid_773617 = validateParameter(valid_773617, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_773617 != nil:
    section.add "Action", valid_773617
  var valid_773618 = query.getOrDefault("Version")
  valid_773618 = validateParameter(valid_773618, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773618 != nil:
    section.add "Version", valid_773618
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
  var valid_773619 = header.getOrDefault("X-Amz-Date")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-Date", valid_773619
  var valid_773620 = header.getOrDefault("X-Amz-Security-Token")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-Security-Token", valid_773620
  var valid_773621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-Content-Sha256", valid_773621
  var valid_773622 = header.getOrDefault("X-Amz-Algorithm")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Algorithm", valid_773622
  var valid_773623 = header.getOrDefault("X-Amz-Signature")
  valid_773623 = validateParameter(valid_773623, JString, required = false,
                                 default = nil)
  if valid_773623 != nil:
    section.add "X-Amz-Signature", valid_773623
  var valid_773624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-SignedHeaders", valid_773624
  var valid_773625 = header.getOrDefault("X-Amz-Credential")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Credential", valid_773625
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PolicyName` field"
  var valid_773626 = formData.getOrDefault("PolicyName")
  valid_773626 = validateParameter(valid_773626, JString, required = true,
                                 default = nil)
  if valid_773626 != nil:
    section.add "PolicyName", valid_773626
  var valid_773627 = formData.getOrDefault("LoadBalancerName")
  valid_773627 = validateParameter(valid_773627, JString, required = true,
                                 default = nil)
  if valid_773627 != nil:
    section.add "LoadBalancerName", valid_773627
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773628: Call_PostDeleteLoadBalancerPolicy_773614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_773628.validator(path, query, header, formData, body)
  let scheme = call_773628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773628.url(scheme.get, call_773628.host, call_773628.base,
                         call_773628.route, valid.getOrDefault("path"))
  result = hook(call_773628, url, valid)

proc call*(call_773629: Call_PostDeleteLoadBalancerPolicy_773614;
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
  var query_773630 = newJObject()
  var formData_773631 = newJObject()
  add(formData_773631, "PolicyName", newJString(PolicyName))
  add(query_773630, "Action", newJString(Action))
  add(formData_773631, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773630, "Version", newJString(Version))
  result = call_773629.call(nil, query_773630, nil, formData_773631, nil)

var postDeleteLoadBalancerPolicy* = Call_PostDeleteLoadBalancerPolicy_773614(
    name: "postDeleteLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_PostDeleteLoadBalancerPolicy_773615, base: "/",
    url: url_PostDeleteLoadBalancerPolicy_773616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerPolicy_773597 = ref object of OpenApiRestCall_772597
proc url_GetDeleteLoadBalancerPolicy_773599(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteLoadBalancerPolicy_773598(path: JsonNode; query: JsonNode;
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
  var valid_773600 = query.getOrDefault("LoadBalancerName")
  valid_773600 = validateParameter(valid_773600, JString, required = true,
                                 default = nil)
  if valid_773600 != nil:
    section.add "LoadBalancerName", valid_773600
  var valid_773601 = query.getOrDefault("Action")
  valid_773601 = validateParameter(valid_773601, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_773601 != nil:
    section.add "Action", valid_773601
  var valid_773602 = query.getOrDefault("Version")
  valid_773602 = validateParameter(valid_773602, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773602 != nil:
    section.add "Version", valid_773602
  var valid_773603 = query.getOrDefault("PolicyName")
  valid_773603 = validateParameter(valid_773603, JString, required = true,
                                 default = nil)
  if valid_773603 != nil:
    section.add "PolicyName", valid_773603
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
  var valid_773604 = header.getOrDefault("X-Amz-Date")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-Date", valid_773604
  var valid_773605 = header.getOrDefault("X-Amz-Security-Token")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "X-Amz-Security-Token", valid_773605
  var valid_773606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "X-Amz-Content-Sha256", valid_773606
  var valid_773607 = header.getOrDefault("X-Amz-Algorithm")
  valid_773607 = validateParameter(valid_773607, JString, required = false,
                                 default = nil)
  if valid_773607 != nil:
    section.add "X-Amz-Algorithm", valid_773607
  var valid_773608 = header.getOrDefault("X-Amz-Signature")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "X-Amz-Signature", valid_773608
  var valid_773609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773609 = validateParameter(valid_773609, JString, required = false,
                                 default = nil)
  if valid_773609 != nil:
    section.add "X-Amz-SignedHeaders", valid_773609
  var valid_773610 = header.getOrDefault("X-Amz-Credential")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Credential", valid_773610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773611: Call_GetDeleteLoadBalancerPolicy_773597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_773611.validator(path, query, header, formData, body)
  let scheme = call_773611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773611.url(scheme.get, call_773611.host, call_773611.base,
                         call_773611.route, valid.getOrDefault("path"))
  result = hook(call_773611, url, valid)

proc call*(call_773612: Call_GetDeleteLoadBalancerPolicy_773597;
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
  var query_773613 = newJObject()
  add(query_773613, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773613, "Action", newJString(Action))
  add(query_773613, "Version", newJString(Version))
  add(query_773613, "PolicyName", newJString(PolicyName))
  result = call_773612.call(nil, query_773613, nil, nil, nil)

var getDeleteLoadBalancerPolicy* = Call_GetDeleteLoadBalancerPolicy_773597(
    name: "getDeleteLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_GetDeleteLoadBalancerPolicy_773598, base: "/",
    url: url_GetDeleteLoadBalancerPolicy_773599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterInstancesFromLoadBalancer_773649 = ref object of OpenApiRestCall_772597
proc url_PostDeregisterInstancesFromLoadBalancer_773651(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeregisterInstancesFromLoadBalancer_773650(path: JsonNode;
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
  var valid_773652 = query.getOrDefault("Action")
  valid_773652 = validateParameter(valid_773652, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_773652 != nil:
    section.add "Action", valid_773652
  var valid_773653 = query.getOrDefault("Version")
  valid_773653 = validateParameter(valid_773653, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773653 != nil:
    section.add "Version", valid_773653
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
  var valid_773654 = header.getOrDefault("X-Amz-Date")
  valid_773654 = validateParameter(valid_773654, JString, required = false,
                                 default = nil)
  if valid_773654 != nil:
    section.add "X-Amz-Date", valid_773654
  var valid_773655 = header.getOrDefault("X-Amz-Security-Token")
  valid_773655 = validateParameter(valid_773655, JString, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "X-Amz-Security-Token", valid_773655
  var valid_773656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773656 = validateParameter(valid_773656, JString, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "X-Amz-Content-Sha256", valid_773656
  var valid_773657 = header.getOrDefault("X-Amz-Algorithm")
  valid_773657 = validateParameter(valid_773657, JString, required = false,
                                 default = nil)
  if valid_773657 != nil:
    section.add "X-Amz-Algorithm", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-Signature")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Signature", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-SignedHeaders", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Credential")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Credential", valid_773660
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_773661 = formData.getOrDefault("Instances")
  valid_773661 = validateParameter(valid_773661, JArray, required = true, default = nil)
  if valid_773661 != nil:
    section.add "Instances", valid_773661
  var valid_773662 = formData.getOrDefault("LoadBalancerName")
  valid_773662 = validateParameter(valid_773662, JString, required = true,
                                 default = nil)
  if valid_773662 != nil:
    section.add "LoadBalancerName", valid_773662
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773663: Call_PostDeregisterInstancesFromLoadBalancer_773649;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773663.validator(path, query, header, formData, body)
  let scheme = call_773663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773663.url(scheme.get, call_773663.host, call_773663.base,
                         call_773663.route, valid.getOrDefault("path"))
  result = hook(call_773663, url, valid)

proc call*(call_773664: Call_PostDeregisterInstancesFromLoadBalancer_773649;
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
  var query_773665 = newJObject()
  var formData_773666 = newJObject()
  if Instances != nil:
    formData_773666.add "Instances", Instances
  add(query_773665, "Action", newJString(Action))
  add(formData_773666, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773665, "Version", newJString(Version))
  result = call_773664.call(nil, query_773665, nil, formData_773666, nil)

var postDeregisterInstancesFromLoadBalancer* = Call_PostDeregisterInstancesFromLoadBalancer_773649(
    name: "postDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_PostDeregisterInstancesFromLoadBalancer_773650, base: "/",
    url: url_PostDeregisterInstancesFromLoadBalancer_773651,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterInstancesFromLoadBalancer_773632 = ref object of OpenApiRestCall_772597
proc url_GetDeregisterInstancesFromLoadBalancer_773634(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeregisterInstancesFromLoadBalancer_773633(path: JsonNode;
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
  var valid_773635 = query.getOrDefault("LoadBalancerName")
  valid_773635 = validateParameter(valid_773635, JString, required = true,
                                 default = nil)
  if valid_773635 != nil:
    section.add "LoadBalancerName", valid_773635
  var valid_773636 = query.getOrDefault("Action")
  valid_773636 = validateParameter(valid_773636, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_773636 != nil:
    section.add "Action", valid_773636
  var valid_773637 = query.getOrDefault("Instances")
  valid_773637 = validateParameter(valid_773637, JArray, required = true, default = nil)
  if valid_773637 != nil:
    section.add "Instances", valid_773637
  var valid_773638 = query.getOrDefault("Version")
  valid_773638 = validateParameter(valid_773638, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773638 != nil:
    section.add "Version", valid_773638
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
  var valid_773639 = header.getOrDefault("X-Amz-Date")
  valid_773639 = validateParameter(valid_773639, JString, required = false,
                                 default = nil)
  if valid_773639 != nil:
    section.add "X-Amz-Date", valid_773639
  var valid_773640 = header.getOrDefault("X-Amz-Security-Token")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "X-Amz-Security-Token", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Content-Sha256", valid_773641
  var valid_773642 = header.getOrDefault("X-Amz-Algorithm")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "X-Amz-Algorithm", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-Signature")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Signature", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-SignedHeaders", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Credential")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Credential", valid_773645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773646: Call_GetDeregisterInstancesFromLoadBalancer_773632;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773646.validator(path, query, header, formData, body)
  let scheme = call_773646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773646.url(scheme.get, call_773646.host, call_773646.base,
                         call_773646.route, valid.getOrDefault("path"))
  result = hook(call_773646, url, valid)

proc call*(call_773647: Call_GetDeregisterInstancesFromLoadBalancer_773632;
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
  var query_773648 = newJObject()
  add(query_773648, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773648, "Action", newJString(Action))
  if Instances != nil:
    query_773648.add "Instances", Instances
  add(query_773648, "Version", newJString(Version))
  result = call_773647.call(nil, query_773648, nil, nil, nil)

var getDeregisterInstancesFromLoadBalancer* = Call_GetDeregisterInstancesFromLoadBalancer_773632(
    name: "getDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_GetDeregisterInstancesFromLoadBalancer_773633, base: "/",
    url: url_GetDeregisterInstancesFromLoadBalancer_773634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_773684 = ref object of OpenApiRestCall_772597
proc url_PostDescribeAccountLimits_773686(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAccountLimits_773685(path: JsonNode; query: JsonNode;
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
  var valid_773687 = query.getOrDefault("Action")
  valid_773687 = validateParameter(valid_773687, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_773687 != nil:
    section.add "Action", valid_773687
  var valid_773688 = query.getOrDefault("Version")
  valid_773688 = validateParameter(valid_773688, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773688 != nil:
    section.add "Version", valid_773688
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
  var valid_773689 = header.getOrDefault("X-Amz-Date")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Date", valid_773689
  var valid_773690 = header.getOrDefault("X-Amz-Security-Token")
  valid_773690 = validateParameter(valid_773690, JString, required = false,
                                 default = nil)
  if valid_773690 != nil:
    section.add "X-Amz-Security-Token", valid_773690
  var valid_773691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-Content-Sha256", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Algorithm")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Algorithm", valid_773692
  var valid_773693 = header.getOrDefault("X-Amz-Signature")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-Signature", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-SignedHeaders", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Credential")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Credential", valid_773695
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_773696 = formData.getOrDefault("Marker")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "Marker", valid_773696
  var valid_773697 = formData.getOrDefault("PageSize")
  valid_773697 = validateParameter(valid_773697, JInt, required = false, default = nil)
  if valid_773697 != nil:
    section.add "PageSize", valid_773697
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773698: Call_PostDescribeAccountLimits_773684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773698.validator(path, query, header, formData, body)
  let scheme = call_773698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773698.url(scheme.get, call_773698.host, call_773698.base,
                         call_773698.route, valid.getOrDefault("path"))
  result = hook(call_773698, url, valid)

proc call*(call_773699: Call_PostDescribeAccountLimits_773684; Marker: string = "";
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
  var query_773700 = newJObject()
  var formData_773701 = newJObject()
  add(formData_773701, "Marker", newJString(Marker))
  add(query_773700, "Action", newJString(Action))
  add(formData_773701, "PageSize", newJInt(PageSize))
  add(query_773700, "Version", newJString(Version))
  result = call_773699.call(nil, query_773700, nil, formData_773701, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_773684(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_773685, base: "/",
    url: url_PostDescribeAccountLimits_773686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_773667 = ref object of OpenApiRestCall_772597
proc url_GetDescribeAccountLimits_773669(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAccountLimits_773668(path: JsonNode; query: JsonNode;
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
  var valid_773670 = query.getOrDefault("PageSize")
  valid_773670 = validateParameter(valid_773670, JInt, required = false, default = nil)
  if valid_773670 != nil:
    section.add "PageSize", valid_773670
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773671 = query.getOrDefault("Action")
  valid_773671 = validateParameter(valid_773671, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_773671 != nil:
    section.add "Action", valid_773671
  var valid_773672 = query.getOrDefault("Marker")
  valid_773672 = validateParameter(valid_773672, JString, required = false,
                                 default = nil)
  if valid_773672 != nil:
    section.add "Marker", valid_773672
  var valid_773673 = query.getOrDefault("Version")
  valid_773673 = validateParameter(valid_773673, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773673 != nil:
    section.add "Version", valid_773673
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
  var valid_773674 = header.getOrDefault("X-Amz-Date")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Date", valid_773674
  var valid_773675 = header.getOrDefault("X-Amz-Security-Token")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "X-Amz-Security-Token", valid_773675
  var valid_773676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-Content-Sha256", valid_773676
  var valid_773677 = header.getOrDefault("X-Amz-Algorithm")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Algorithm", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Signature")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Signature", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-SignedHeaders", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Credential")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Credential", valid_773680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773681: Call_GetDescribeAccountLimits_773667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773681.validator(path, query, header, formData, body)
  let scheme = call_773681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773681.url(scheme.get, call_773681.host, call_773681.base,
                         call_773681.route, valid.getOrDefault("path"))
  result = hook(call_773681, url, valid)

proc call*(call_773682: Call_GetDescribeAccountLimits_773667; PageSize: int = 0;
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
  var query_773683 = newJObject()
  add(query_773683, "PageSize", newJInt(PageSize))
  add(query_773683, "Action", newJString(Action))
  add(query_773683, "Marker", newJString(Marker))
  add(query_773683, "Version", newJString(Version))
  result = call_773682.call(nil, query_773683, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_773667(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_773668, base: "/",
    url: url_GetDescribeAccountLimits_773669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstanceHealth_773719 = ref object of OpenApiRestCall_772597
proc url_PostDescribeInstanceHealth_773721(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeInstanceHealth_773720(path: JsonNode; query: JsonNode;
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
  var valid_773722 = query.getOrDefault("Action")
  valid_773722 = validateParameter(valid_773722, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_773722 != nil:
    section.add "Action", valid_773722
  var valid_773723 = query.getOrDefault("Version")
  valid_773723 = validateParameter(valid_773723, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773723 != nil:
    section.add "Version", valid_773723
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
  var valid_773724 = header.getOrDefault("X-Amz-Date")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "X-Amz-Date", valid_773724
  var valid_773725 = header.getOrDefault("X-Amz-Security-Token")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-Security-Token", valid_773725
  var valid_773726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773726 = validateParameter(valid_773726, JString, required = false,
                                 default = nil)
  if valid_773726 != nil:
    section.add "X-Amz-Content-Sha256", valid_773726
  var valid_773727 = header.getOrDefault("X-Amz-Algorithm")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-Algorithm", valid_773727
  var valid_773728 = header.getOrDefault("X-Amz-Signature")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-Signature", valid_773728
  var valid_773729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "X-Amz-SignedHeaders", valid_773729
  var valid_773730 = header.getOrDefault("X-Amz-Credential")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Credential", valid_773730
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_773731 = formData.getOrDefault("Instances")
  valid_773731 = validateParameter(valid_773731, JArray, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "Instances", valid_773731
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_773732 = formData.getOrDefault("LoadBalancerName")
  valid_773732 = validateParameter(valid_773732, JString, required = true,
                                 default = nil)
  if valid_773732 != nil:
    section.add "LoadBalancerName", valid_773732
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773733: Call_PostDescribeInstanceHealth_773719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_773733.validator(path, query, header, formData, body)
  let scheme = call_773733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773733.url(scheme.get, call_773733.host, call_773733.base,
                         call_773733.route, valid.getOrDefault("path"))
  result = hook(call_773733, url, valid)

proc call*(call_773734: Call_PostDescribeInstanceHealth_773719;
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
  var query_773735 = newJObject()
  var formData_773736 = newJObject()
  if Instances != nil:
    formData_773736.add "Instances", Instances
  add(query_773735, "Action", newJString(Action))
  add(formData_773736, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773735, "Version", newJString(Version))
  result = call_773734.call(nil, query_773735, nil, formData_773736, nil)

var postDescribeInstanceHealth* = Call_PostDescribeInstanceHealth_773719(
    name: "postDescribeInstanceHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_PostDescribeInstanceHealth_773720, base: "/",
    url: url_PostDescribeInstanceHealth_773721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstanceHealth_773702 = ref object of OpenApiRestCall_772597
proc url_GetDescribeInstanceHealth_773704(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeInstanceHealth_773703(path: JsonNode; query: JsonNode;
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
  var valid_773705 = query.getOrDefault("LoadBalancerName")
  valid_773705 = validateParameter(valid_773705, JString, required = true,
                                 default = nil)
  if valid_773705 != nil:
    section.add "LoadBalancerName", valid_773705
  var valid_773706 = query.getOrDefault("Action")
  valid_773706 = validateParameter(valid_773706, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_773706 != nil:
    section.add "Action", valid_773706
  var valid_773707 = query.getOrDefault("Instances")
  valid_773707 = validateParameter(valid_773707, JArray, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "Instances", valid_773707
  var valid_773708 = query.getOrDefault("Version")
  valid_773708 = validateParameter(valid_773708, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773708 != nil:
    section.add "Version", valid_773708
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
  var valid_773709 = header.getOrDefault("X-Amz-Date")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-Date", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Security-Token")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Security-Token", valid_773710
  var valid_773711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-Content-Sha256", valid_773711
  var valid_773712 = header.getOrDefault("X-Amz-Algorithm")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-Algorithm", valid_773712
  var valid_773713 = header.getOrDefault("X-Amz-Signature")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-Signature", valid_773713
  var valid_773714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773714 = validateParameter(valid_773714, JString, required = false,
                                 default = nil)
  if valid_773714 != nil:
    section.add "X-Amz-SignedHeaders", valid_773714
  var valid_773715 = header.getOrDefault("X-Amz-Credential")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Credential", valid_773715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773716: Call_GetDescribeInstanceHealth_773702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_773716.validator(path, query, header, formData, body)
  let scheme = call_773716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773716.url(scheme.get, call_773716.host, call_773716.base,
                         call_773716.route, valid.getOrDefault("path"))
  result = hook(call_773716, url, valid)

proc call*(call_773717: Call_GetDescribeInstanceHealth_773702;
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
  var query_773718 = newJObject()
  add(query_773718, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773718, "Action", newJString(Action))
  if Instances != nil:
    query_773718.add "Instances", Instances
  add(query_773718, "Version", newJString(Version))
  result = call_773717.call(nil, query_773718, nil, nil, nil)

var getDescribeInstanceHealth* = Call_GetDescribeInstanceHealth_773702(
    name: "getDescribeInstanceHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_GetDescribeInstanceHealth_773703, base: "/",
    url: url_GetDescribeInstanceHealth_773704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_773753 = ref object of OpenApiRestCall_772597
proc url_PostDescribeLoadBalancerAttributes_773755(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancerAttributes_773754(path: JsonNode;
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
  var valid_773756 = query.getOrDefault("Action")
  valid_773756 = validateParameter(valid_773756, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_773756 != nil:
    section.add "Action", valid_773756
  var valid_773757 = query.getOrDefault("Version")
  valid_773757 = validateParameter(valid_773757, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773757 != nil:
    section.add "Version", valid_773757
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
  var valid_773758 = header.getOrDefault("X-Amz-Date")
  valid_773758 = validateParameter(valid_773758, JString, required = false,
                                 default = nil)
  if valid_773758 != nil:
    section.add "X-Amz-Date", valid_773758
  var valid_773759 = header.getOrDefault("X-Amz-Security-Token")
  valid_773759 = validateParameter(valid_773759, JString, required = false,
                                 default = nil)
  if valid_773759 != nil:
    section.add "X-Amz-Security-Token", valid_773759
  var valid_773760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-Content-Sha256", valid_773760
  var valid_773761 = header.getOrDefault("X-Amz-Algorithm")
  valid_773761 = validateParameter(valid_773761, JString, required = false,
                                 default = nil)
  if valid_773761 != nil:
    section.add "X-Amz-Algorithm", valid_773761
  var valid_773762 = header.getOrDefault("X-Amz-Signature")
  valid_773762 = validateParameter(valid_773762, JString, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "X-Amz-Signature", valid_773762
  var valid_773763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "X-Amz-SignedHeaders", valid_773763
  var valid_773764 = header.getOrDefault("X-Amz-Credential")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Credential", valid_773764
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_773765 = formData.getOrDefault("LoadBalancerName")
  valid_773765 = validateParameter(valid_773765, JString, required = true,
                                 default = nil)
  if valid_773765 != nil:
    section.add "LoadBalancerName", valid_773765
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773766: Call_PostDescribeLoadBalancerAttributes_773753;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_773766.validator(path, query, header, formData, body)
  let scheme = call_773766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773766.url(scheme.get, call_773766.host, call_773766.base,
                         call_773766.route, valid.getOrDefault("path"))
  result = hook(call_773766, url, valid)

proc call*(call_773767: Call_PostDescribeLoadBalancerAttributes_773753;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_773768 = newJObject()
  var formData_773769 = newJObject()
  add(query_773768, "Action", newJString(Action))
  add(formData_773769, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773768, "Version", newJString(Version))
  result = call_773767.call(nil, query_773768, nil, formData_773769, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_773753(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_773754, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_773755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_773737 = ref object of OpenApiRestCall_772597
proc url_GetDescribeLoadBalancerAttributes_773739(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancerAttributes_773738(path: JsonNode;
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
  var valid_773740 = query.getOrDefault("LoadBalancerName")
  valid_773740 = validateParameter(valid_773740, JString, required = true,
                                 default = nil)
  if valid_773740 != nil:
    section.add "LoadBalancerName", valid_773740
  var valid_773741 = query.getOrDefault("Action")
  valid_773741 = validateParameter(valid_773741, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_773741 != nil:
    section.add "Action", valid_773741
  var valid_773742 = query.getOrDefault("Version")
  valid_773742 = validateParameter(valid_773742, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773742 != nil:
    section.add "Version", valid_773742
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
  var valid_773743 = header.getOrDefault("X-Amz-Date")
  valid_773743 = validateParameter(valid_773743, JString, required = false,
                                 default = nil)
  if valid_773743 != nil:
    section.add "X-Amz-Date", valid_773743
  var valid_773744 = header.getOrDefault("X-Amz-Security-Token")
  valid_773744 = validateParameter(valid_773744, JString, required = false,
                                 default = nil)
  if valid_773744 != nil:
    section.add "X-Amz-Security-Token", valid_773744
  var valid_773745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773745 = validateParameter(valid_773745, JString, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "X-Amz-Content-Sha256", valid_773745
  var valid_773746 = header.getOrDefault("X-Amz-Algorithm")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "X-Amz-Algorithm", valid_773746
  var valid_773747 = header.getOrDefault("X-Amz-Signature")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "X-Amz-Signature", valid_773747
  var valid_773748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-SignedHeaders", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Credential")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Credential", valid_773749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773750: Call_GetDescribeLoadBalancerAttributes_773737;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_773750.validator(path, query, header, formData, body)
  let scheme = call_773750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773750.url(scheme.get, call_773750.host, call_773750.base,
                         call_773750.route, valid.getOrDefault("path"))
  result = hook(call_773750, url, valid)

proc call*(call_773751: Call_GetDescribeLoadBalancerAttributes_773737;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773752 = newJObject()
  add(query_773752, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773752, "Action", newJString(Action))
  add(query_773752, "Version", newJString(Version))
  result = call_773751.call(nil, query_773752, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_773737(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_773738, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_773739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicies_773787 = ref object of OpenApiRestCall_772597
proc url_PostDescribeLoadBalancerPolicies_773789(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancerPolicies_773788(path: JsonNode;
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
  var valid_773790 = query.getOrDefault("Action")
  valid_773790 = validateParameter(valid_773790, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_773790 != nil:
    section.add "Action", valid_773790
  var valid_773791 = query.getOrDefault("Version")
  valid_773791 = validateParameter(valid_773791, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773791 != nil:
    section.add "Version", valid_773791
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
  var valid_773792 = header.getOrDefault("X-Amz-Date")
  valid_773792 = validateParameter(valid_773792, JString, required = false,
                                 default = nil)
  if valid_773792 != nil:
    section.add "X-Amz-Date", valid_773792
  var valid_773793 = header.getOrDefault("X-Amz-Security-Token")
  valid_773793 = validateParameter(valid_773793, JString, required = false,
                                 default = nil)
  if valid_773793 != nil:
    section.add "X-Amz-Security-Token", valid_773793
  var valid_773794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773794 = validateParameter(valid_773794, JString, required = false,
                                 default = nil)
  if valid_773794 != nil:
    section.add "X-Amz-Content-Sha256", valid_773794
  var valid_773795 = header.getOrDefault("X-Amz-Algorithm")
  valid_773795 = validateParameter(valid_773795, JString, required = false,
                                 default = nil)
  if valid_773795 != nil:
    section.add "X-Amz-Algorithm", valid_773795
  var valid_773796 = header.getOrDefault("X-Amz-Signature")
  valid_773796 = validateParameter(valid_773796, JString, required = false,
                                 default = nil)
  if valid_773796 != nil:
    section.add "X-Amz-Signature", valid_773796
  var valid_773797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-SignedHeaders", valid_773797
  var valid_773798 = header.getOrDefault("X-Amz-Credential")
  valid_773798 = validateParameter(valid_773798, JString, required = false,
                                 default = nil)
  if valid_773798 != nil:
    section.add "X-Amz-Credential", valid_773798
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   LoadBalancerName: JString
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_773799 = formData.getOrDefault("PolicyNames")
  valid_773799 = validateParameter(valid_773799, JArray, required = false,
                                 default = nil)
  if valid_773799 != nil:
    section.add "PolicyNames", valid_773799
  var valid_773800 = formData.getOrDefault("LoadBalancerName")
  valid_773800 = validateParameter(valid_773800, JString, required = false,
                                 default = nil)
  if valid_773800 != nil:
    section.add "LoadBalancerName", valid_773800
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773801: Call_PostDescribeLoadBalancerPolicies_773787;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_773801.validator(path, query, header, formData, body)
  let scheme = call_773801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773801.url(scheme.get, call_773801.host, call_773801.base,
                         call_773801.route, valid.getOrDefault("path"))
  result = hook(call_773801, url, valid)

proc call*(call_773802: Call_PostDescribeLoadBalancerPolicies_773787;
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
  var query_773803 = newJObject()
  var formData_773804 = newJObject()
  if PolicyNames != nil:
    formData_773804.add "PolicyNames", PolicyNames
  add(query_773803, "Action", newJString(Action))
  add(formData_773804, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773803, "Version", newJString(Version))
  result = call_773802.call(nil, query_773803, nil, formData_773804, nil)

var postDescribeLoadBalancerPolicies* = Call_PostDescribeLoadBalancerPolicies_773787(
    name: "postDescribeLoadBalancerPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_PostDescribeLoadBalancerPolicies_773788, base: "/",
    url: url_PostDescribeLoadBalancerPolicies_773789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicies_773770 = ref object of OpenApiRestCall_772597
proc url_GetDescribeLoadBalancerPolicies_773772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancerPolicies_773771(path: JsonNode;
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
  var valid_773773 = query.getOrDefault("LoadBalancerName")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "LoadBalancerName", valid_773773
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773774 = query.getOrDefault("Action")
  valid_773774 = validateParameter(valid_773774, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_773774 != nil:
    section.add "Action", valid_773774
  var valid_773775 = query.getOrDefault("PolicyNames")
  valid_773775 = validateParameter(valid_773775, JArray, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "PolicyNames", valid_773775
  var valid_773776 = query.getOrDefault("Version")
  valid_773776 = validateParameter(valid_773776, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773776 != nil:
    section.add "Version", valid_773776
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
  var valid_773777 = header.getOrDefault("X-Amz-Date")
  valid_773777 = validateParameter(valid_773777, JString, required = false,
                                 default = nil)
  if valid_773777 != nil:
    section.add "X-Amz-Date", valid_773777
  var valid_773778 = header.getOrDefault("X-Amz-Security-Token")
  valid_773778 = validateParameter(valid_773778, JString, required = false,
                                 default = nil)
  if valid_773778 != nil:
    section.add "X-Amz-Security-Token", valid_773778
  var valid_773779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773779 = validateParameter(valid_773779, JString, required = false,
                                 default = nil)
  if valid_773779 != nil:
    section.add "X-Amz-Content-Sha256", valid_773779
  var valid_773780 = header.getOrDefault("X-Amz-Algorithm")
  valid_773780 = validateParameter(valid_773780, JString, required = false,
                                 default = nil)
  if valid_773780 != nil:
    section.add "X-Amz-Algorithm", valid_773780
  var valid_773781 = header.getOrDefault("X-Amz-Signature")
  valid_773781 = validateParameter(valid_773781, JString, required = false,
                                 default = nil)
  if valid_773781 != nil:
    section.add "X-Amz-Signature", valid_773781
  var valid_773782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-SignedHeaders", valid_773782
  var valid_773783 = header.getOrDefault("X-Amz-Credential")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "X-Amz-Credential", valid_773783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773784: Call_GetDescribeLoadBalancerPolicies_773770;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_773784.validator(path, query, header, formData, body)
  let scheme = call_773784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773784.url(scheme.get, call_773784.host, call_773784.base,
                         call_773784.route, valid.getOrDefault("path"))
  result = hook(call_773784, url, valid)

proc call*(call_773785: Call_GetDescribeLoadBalancerPolicies_773770;
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
  var query_773786 = newJObject()
  add(query_773786, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773786, "Action", newJString(Action))
  if PolicyNames != nil:
    query_773786.add "PolicyNames", PolicyNames
  add(query_773786, "Version", newJString(Version))
  result = call_773785.call(nil, query_773786, nil, nil, nil)

var getDescribeLoadBalancerPolicies* = Call_GetDescribeLoadBalancerPolicies_773770(
    name: "getDescribeLoadBalancerPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_GetDescribeLoadBalancerPolicies_773771, base: "/",
    url: url_GetDescribeLoadBalancerPolicies_773772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicyTypes_773821 = ref object of OpenApiRestCall_772597
proc url_PostDescribeLoadBalancerPolicyTypes_773823(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancerPolicyTypes_773822(path: JsonNode;
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
  var valid_773824 = query.getOrDefault("Action")
  valid_773824 = validateParameter(valid_773824, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_773824 != nil:
    section.add "Action", valid_773824
  var valid_773825 = query.getOrDefault("Version")
  valid_773825 = validateParameter(valid_773825, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773825 != nil:
    section.add "Version", valid_773825
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
  var valid_773826 = header.getOrDefault("X-Amz-Date")
  valid_773826 = validateParameter(valid_773826, JString, required = false,
                                 default = nil)
  if valid_773826 != nil:
    section.add "X-Amz-Date", valid_773826
  var valid_773827 = header.getOrDefault("X-Amz-Security-Token")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-Security-Token", valid_773827
  var valid_773828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773828 = validateParameter(valid_773828, JString, required = false,
                                 default = nil)
  if valid_773828 != nil:
    section.add "X-Amz-Content-Sha256", valid_773828
  var valid_773829 = header.getOrDefault("X-Amz-Algorithm")
  valid_773829 = validateParameter(valid_773829, JString, required = false,
                                 default = nil)
  if valid_773829 != nil:
    section.add "X-Amz-Algorithm", valid_773829
  var valid_773830 = header.getOrDefault("X-Amz-Signature")
  valid_773830 = validateParameter(valid_773830, JString, required = false,
                                 default = nil)
  if valid_773830 != nil:
    section.add "X-Amz-Signature", valid_773830
  var valid_773831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773831 = validateParameter(valid_773831, JString, required = false,
                                 default = nil)
  if valid_773831 != nil:
    section.add "X-Amz-SignedHeaders", valid_773831
  var valid_773832 = header.getOrDefault("X-Amz-Credential")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "X-Amz-Credential", valid_773832
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  section = newJObject()
  var valid_773833 = formData.getOrDefault("PolicyTypeNames")
  valid_773833 = validateParameter(valid_773833, JArray, required = false,
                                 default = nil)
  if valid_773833 != nil:
    section.add "PolicyTypeNames", valid_773833
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773834: Call_PostDescribeLoadBalancerPolicyTypes_773821;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_773834.validator(path, query, header, formData, body)
  let scheme = call_773834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773834.url(scheme.get, call_773834.host, call_773834.base,
                         call_773834.route, valid.getOrDefault("path"))
  result = hook(call_773834, url, valid)

proc call*(call_773835: Call_PostDescribeLoadBalancerPolicyTypes_773821;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773836 = newJObject()
  var formData_773837 = newJObject()
  if PolicyTypeNames != nil:
    formData_773837.add "PolicyTypeNames", PolicyTypeNames
  add(query_773836, "Action", newJString(Action))
  add(query_773836, "Version", newJString(Version))
  result = call_773835.call(nil, query_773836, nil, formData_773837, nil)

var postDescribeLoadBalancerPolicyTypes* = Call_PostDescribeLoadBalancerPolicyTypes_773821(
    name: "postDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_PostDescribeLoadBalancerPolicyTypes_773822, base: "/",
    url: url_PostDescribeLoadBalancerPolicyTypes_773823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicyTypes_773805 = ref object of OpenApiRestCall_772597
proc url_GetDescribeLoadBalancerPolicyTypes_773807(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancerPolicyTypes_773806(path: JsonNode;
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
  var valid_773808 = query.getOrDefault("Action")
  valid_773808 = validateParameter(valid_773808, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_773808 != nil:
    section.add "Action", valid_773808
  var valid_773809 = query.getOrDefault("PolicyTypeNames")
  valid_773809 = validateParameter(valid_773809, JArray, required = false,
                                 default = nil)
  if valid_773809 != nil:
    section.add "PolicyTypeNames", valid_773809
  var valid_773810 = query.getOrDefault("Version")
  valid_773810 = validateParameter(valid_773810, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773810 != nil:
    section.add "Version", valid_773810
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
  var valid_773811 = header.getOrDefault("X-Amz-Date")
  valid_773811 = validateParameter(valid_773811, JString, required = false,
                                 default = nil)
  if valid_773811 != nil:
    section.add "X-Amz-Date", valid_773811
  var valid_773812 = header.getOrDefault("X-Amz-Security-Token")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-Security-Token", valid_773812
  var valid_773813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773813 = validateParameter(valid_773813, JString, required = false,
                                 default = nil)
  if valid_773813 != nil:
    section.add "X-Amz-Content-Sha256", valid_773813
  var valid_773814 = header.getOrDefault("X-Amz-Algorithm")
  valid_773814 = validateParameter(valid_773814, JString, required = false,
                                 default = nil)
  if valid_773814 != nil:
    section.add "X-Amz-Algorithm", valid_773814
  var valid_773815 = header.getOrDefault("X-Amz-Signature")
  valid_773815 = validateParameter(valid_773815, JString, required = false,
                                 default = nil)
  if valid_773815 != nil:
    section.add "X-Amz-Signature", valid_773815
  var valid_773816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773816 = validateParameter(valid_773816, JString, required = false,
                                 default = nil)
  if valid_773816 != nil:
    section.add "X-Amz-SignedHeaders", valid_773816
  var valid_773817 = header.getOrDefault("X-Amz-Credential")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-Credential", valid_773817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773818: Call_GetDescribeLoadBalancerPolicyTypes_773805;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_773818.validator(path, query, header, formData, body)
  let scheme = call_773818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773818.url(scheme.get, call_773818.host, call_773818.base,
                         call_773818.route, valid.getOrDefault("path"))
  result = hook(call_773818, url, valid)

proc call*(call_773819: Call_GetDescribeLoadBalancerPolicyTypes_773805;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          PolicyTypeNames: JsonNode = nil; Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   Action: string (required)
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Version: string (required)
  var query_773820 = newJObject()
  add(query_773820, "Action", newJString(Action))
  if PolicyTypeNames != nil:
    query_773820.add "PolicyTypeNames", PolicyTypeNames
  add(query_773820, "Version", newJString(Version))
  result = call_773819.call(nil, query_773820, nil, nil, nil)

var getDescribeLoadBalancerPolicyTypes* = Call_GetDescribeLoadBalancerPolicyTypes_773805(
    name: "getDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_GetDescribeLoadBalancerPolicyTypes_773806, base: "/",
    url: url_GetDescribeLoadBalancerPolicyTypes_773807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_773856 = ref object of OpenApiRestCall_772597
proc url_PostDescribeLoadBalancers_773858(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeLoadBalancers_773857(path: JsonNode; query: JsonNode;
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
  var valid_773859 = query.getOrDefault("Action")
  valid_773859 = validateParameter(valid_773859, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_773859 != nil:
    section.add "Action", valid_773859
  var valid_773860 = query.getOrDefault("Version")
  valid_773860 = validateParameter(valid_773860, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773860 != nil:
    section.add "Version", valid_773860
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
  var valid_773861 = header.getOrDefault("X-Amz-Date")
  valid_773861 = validateParameter(valid_773861, JString, required = false,
                                 default = nil)
  if valid_773861 != nil:
    section.add "X-Amz-Date", valid_773861
  var valid_773862 = header.getOrDefault("X-Amz-Security-Token")
  valid_773862 = validateParameter(valid_773862, JString, required = false,
                                 default = nil)
  if valid_773862 != nil:
    section.add "X-Amz-Security-Token", valid_773862
  var valid_773863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773863 = validateParameter(valid_773863, JString, required = false,
                                 default = nil)
  if valid_773863 != nil:
    section.add "X-Amz-Content-Sha256", valid_773863
  var valid_773864 = header.getOrDefault("X-Amz-Algorithm")
  valid_773864 = validateParameter(valid_773864, JString, required = false,
                                 default = nil)
  if valid_773864 != nil:
    section.add "X-Amz-Algorithm", valid_773864
  var valid_773865 = header.getOrDefault("X-Amz-Signature")
  valid_773865 = validateParameter(valid_773865, JString, required = false,
                                 default = nil)
  if valid_773865 != nil:
    section.add "X-Amz-Signature", valid_773865
  var valid_773866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773866 = validateParameter(valid_773866, JString, required = false,
                                 default = nil)
  if valid_773866 != nil:
    section.add "X-Amz-SignedHeaders", valid_773866
  var valid_773867 = header.getOrDefault("X-Amz-Credential")
  valid_773867 = validateParameter(valid_773867, JString, required = false,
                                 default = nil)
  if valid_773867 != nil:
    section.add "X-Amz-Credential", valid_773867
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  section = newJObject()
  var valid_773868 = formData.getOrDefault("Marker")
  valid_773868 = validateParameter(valid_773868, JString, required = false,
                                 default = nil)
  if valid_773868 != nil:
    section.add "Marker", valid_773868
  var valid_773869 = formData.getOrDefault("LoadBalancerNames")
  valid_773869 = validateParameter(valid_773869, JArray, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "LoadBalancerNames", valid_773869
  var valid_773870 = formData.getOrDefault("PageSize")
  valid_773870 = validateParameter(valid_773870, JInt, required = false, default = nil)
  if valid_773870 != nil:
    section.add "PageSize", valid_773870
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773871: Call_PostDescribeLoadBalancers_773856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_773871.validator(path, query, header, formData, body)
  let scheme = call_773871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773871.url(scheme.get, call_773871.host, call_773871.base,
                         call_773871.route, valid.getOrDefault("path"))
  result = hook(call_773871, url, valid)

proc call*(call_773872: Call_PostDescribeLoadBalancers_773856; Marker: string = "";
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
  var query_773873 = newJObject()
  var formData_773874 = newJObject()
  add(formData_773874, "Marker", newJString(Marker))
  add(query_773873, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_773874.add "LoadBalancerNames", LoadBalancerNames
  add(formData_773874, "PageSize", newJInt(PageSize))
  add(query_773873, "Version", newJString(Version))
  result = call_773872.call(nil, query_773873, nil, formData_773874, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_773856(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_773857, base: "/",
    url: url_PostDescribeLoadBalancers_773858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_773838 = ref object of OpenApiRestCall_772597
proc url_GetDescribeLoadBalancers_773840(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeLoadBalancers_773839(path: JsonNode; query: JsonNode;
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
  var valid_773841 = query.getOrDefault("PageSize")
  valid_773841 = validateParameter(valid_773841, JInt, required = false, default = nil)
  if valid_773841 != nil:
    section.add "PageSize", valid_773841
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773842 = query.getOrDefault("Action")
  valid_773842 = validateParameter(valid_773842, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_773842 != nil:
    section.add "Action", valid_773842
  var valid_773843 = query.getOrDefault("Marker")
  valid_773843 = validateParameter(valid_773843, JString, required = false,
                                 default = nil)
  if valid_773843 != nil:
    section.add "Marker", valid_773843
  var valid_773844 = query.getOrDefault("LoadBalancerNames")
  valid_773844 = validateParameter(valid_773844, JArray, required = false,
                                 default = nil)
  if valid_773844 != nil:
    section.add "LoadBalancerNames", valid_773844
  var valid_773845 = query.getOrDefault("Version")
  valid_773845 = validateParameter(valid_773845, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773845 != nil:
    section.add "Version", valid_773845
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
  var valid_773846 = header.getOrDefault("X-Amz-Date")
  valid_773846 = validateParameter(valid_773846, JString, required = false,
                                 default = nil)
  if valid_773846 != nil:
    section.add "X-Amz-Date", valid_773846
  var valid_773847 = header.getOrDefault("X-Amz-Security-Token")
  valid_773847 = validateParameter(valid_773847, JString, required = false,
                                 default = nil)
  if valid_773847 != nil:
    section.add "X-Amz-Security-Token", valid_773847
  var valid_773848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773848 = validateParameter(valid_773848, JString, required = false,
                                 default = nil)
  if valid_773848 != nil:
    section.add "X-Amz-Content-Sha256", valid_773848
  var valid_773849 = header.getOrDefault("X-Amz-Algorithm")
  valid_773849 = validateParameter(valid_773849, JString, required = false,
                                 default = nil)
  if valid_773849 != nil:
    section.add "X-Amz-Algorithm", valid_773849
  var valid_773850 = header.getOrDefault("X-Amz-Signature")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "X-Amz-Signature", valid_773850
  var valid_773851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "X-Amz-SignedHeaders", valid_773851
  var valid_773852 = header.getOrDefault("X-Amz-Credential")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-Credential", valid_773852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773853: Call_GetDescribeLoadBalancers_773838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_773853.validator(path, query, header, formData, body)
  let scheme = call_773853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773853.url(scheme.get, call_773853.host, call_773853.base,
                         call_773853.route, valid.getOrDefault("path"))
  result = hook(call_773853, url, valid)

proc call*(call_773854: Call_GetDescribeLoadBalancers_773838; PageSize: int = 0;
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
  var query_773855 = newJObject()
  add(query_773855, "PageSize", newJInt(PageSize))
  add(query_773855, "Action", newJString(Action))
  add(query_773855, "Marker", newJString(Marker))
  if LoadBalancerNames != nil:
    query_773855.add "LoadBalancerNames", LoadBalancerNames
  add(query_773855, "Version", newJString(Version))
  result = call_773854.call(nil, query_773855, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_773838(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_773839, base: "/",
    url: url_GetDescribeLoadBalancers_773840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_773891 = ref object of OpenApiRestCall_772597
proc url_PostDescribeTags_773893(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeTags_773892(path: JsonNode; query: JsonNode;
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
  var valid_773894 = query.getOrDefault("Action")
  valid_773894 = validateParameter(valid_773894, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_773894 != nil:
    section.add "Action", valid_773894
  var valid_773895 = query.getOrDefault("Version")
  valid_773895 = validateParameter(valid_773895, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773895 != nil:
    section.add "Version", valid_773895
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
  var valid_773896 = header.getOrDefault("X-Amz-Date")
  valid_773896 = validateParameter(valid_773896, JString, required = false,
                                 default = nil)
  if valid_773896 != nil:
    section.add "X-Amz-Date", valid_773896
  var valid_773897 = header.getOrDefault("X-Amz-Security-Token")
  valid_773897 = validateParameter(valid_773897, JString, required = false,
                                 default = nil)
  if valid_773897 != nil:
    section.add "X-Amz-Security-Token", valid_773897
  var valid_773898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773898 = validateParameter(valid_773898, JString, required = false,
                                 default = nil)
  if valid_773898 != nil:
    section.add "X-Amz-Content-Sha256", valid_773898
  var valid_773899 = header.getOrDefault("X-Amz-Algorithm")
  valid_773899 = validateParameter(valid_773899, JString, required = false,
                                 default = nil)
  if valid_773899 != nil:
    section.add "X-Amz-Algorithm", valid_773899
  var valid_773900 = header.getOrDefault("X-Amz-Signature")
  valid_773900 = validateParameter(valid_773900, JString, required = false,
                                 default = nil)
  if valid_773900 != nil:
    section.add "X-Amz-Signature", valid_773900
  var valid_773901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773901 = validateParameter(valid_773901, JString, required = false,
                                 default = nil)
  if valid_773901 != nil:
    section.add "X-Amz-SignedHeaders", valid_773901
  var valid_773902 = header.getOrDefault("X-Amz-Credential")
  valid_773902 = validateParameter(valid_773902, JString, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "X-Amz-Credential", valid_773902
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_773903 = formData.getOrDefault("LoadBalancerNames")
  valid_773903 = validateParameter(valid_773903, JArray, required = true, default = nil)
  if valid_773903 != nil:
    section.add "LoadBalancerNames", valid_773903
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773904: Call_PostDescribeTags_773891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_773904.validator(path, query, header, formData, body)
  let scheme = call_773904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773904.url(scheme.get, call_773904.host, call_773904.base,
                         call_773904.route, valid.getOrDefault("path"))
  result = hook(call_773904, url, valid)

proc call*(call_773905: Call_PostDescribeTags_773891; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_773906 = newJObject()
  var formData_773907 = newJObject()
  add(query_773906, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_773907.add "LoadBalancerNames", LoadBalancerNames
  add(query_773906, "Version", newJString(Version))
  result = call_773905.call(nil, query_773906, nil, formData_773907, nil)

var postDescribeTags* = Call_PostDescribeTags_773891(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_773892,
    base: "/", url: url_PostDescribeTags_773893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_773875 = ref object of OpenApiRestCall_772597
proc url_GetDescribeTags_773877(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeTags_773876(path: JsonNode; query: JsonNode;
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
  var valid_773878 = query.getOrDefault("Action")
  valid_773878 = validateParameter(valid_773878, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_773878 != nil:
    section.add "Action", valid_773878
  var valid_773879 = query.getOrDefault("LoadBalancerNames")
  valid_773879 = validateParameter(valid_773879, JArray, required = true, default = nil)
  if valid_773879 != nil:
    section.add "LoadBalancerNames", valid_773879
  var valid_773880 = query.getOrDefault("Version")
  valid_773880 = validateParameter(valid_773880, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773880 != nil:
    section.add "Version", valid_773880
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
  var valid_773881 = header.getOrDefault("X-Amz-Date")
  valid_773881 = validateParameter(valid_773881, JString, required = false,
                                 default = nil)
  if valid_773881 != nil:
    section.add "X-Amz-Date", valid_773881
  var valid_773882 = header.getOrDefault("X-Amz-Security-Token")
  valid_773882 = validateParameter(valid_773882, JString, required = false,
                                 default = nil)
  if valid_773882 != nil:
    section.add "X-Amz-Security-Token", valid_773882
  var valid_773883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773883 = validateParameter(valid_773883, JString, required = false,
                                 default = nil)
  if valid_773883 != nil:
    section.add "X-Amz-Content-Sha256", valid_773883
  var valid_773884 = header.getOrDefault("X-Amz-Algorithm")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "X-Amz-Algorithm", valid_773884
  var valid_773885 = header.getOrDefault("X-Amz-Signature")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "X-Amz-Signature", valid_773885
  var valid_773886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773886 = validateParameter(valid_773886, JString, required = false,
                                 default = nil)
  if valid_773886 != nil:
    section.add "X-Amz-SignedHeaders", valid_773886
  var valid_773887 = header.getOrDefault("X-Amz-Credential")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-Credential", valid_773887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773888: Call_GetDescribeTags_773875; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_773888.validator(path, query, header, formData, body)
  let scheme = call_773888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773888.url(scheme.get, call_773888.host, call_773888.base,
                         call_773888.route, valid.getOrDefault("path"))
  result = hook(call_773888, url, valid)

proc call*(call_773889: Call_GetDescribeTags_773875; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_773890 = newJObject()
  add(query_773890, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_773890.add "LoadBalancerNames", LoadBalancerNames
  add(query_773890, "Version", newJString(Version))
  result = call_773889.call(nil, query_773890, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_773875(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_773876,
    base: "/", url: url_GetDescribeTags_773877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDetachLoadBalancerFromSubnets_773925 = ref object of OpenApiRestCall_772597
proc url_PostDetachLoadBalancerFromSubnets_773927(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDetachLoadBalancerFromSubnets_773926(path: JsonNode;
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
  var valid_773928 = query.getOrDefault("Action")
  valid_773928 = validateParameter(valid_773928, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_773928 != nil:
    section.add "Action", valid_773928
  var valid_773929 = query.getOrDefault("Version")
  valid_773929 = validateParameter(valid_773929, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773929 != nil:
    section.add "Version", valid_773929
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
  var valid_773930 = header.getOrDefault("X-Amz-Date")
  valid_773930 = validateParameter(valid_773930, JString, required = false,
                                 default = nil)
  if valid_773930 != nil:
    section.add "X-Amz-Date", valid_773930
  var valid_773931 = header.getOrDefault("X-Amz-Security-Token")
  valid_773931 = validateParameter(valid_773931, JString, required = false,
                                 default = nil)
  if valid_773931 != nil:
    section.add "X-Amz-Security-Token", valid_773931
  var valid_773932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773932 = validateParameter(valid_773932, JString, required = false,
                                 default = nil)
  if valid_773932 != nil:
    section.add "X-Amz-Content-Sha256", valid_773932
  var valid_773933 = header.getOrDefault("X-Amz-Algorithm")
  valid_773933 = validateParameter(valid_773933, JString, required = false,
                                 default = nil)
  if valid_773933 != nil:
    section.add "X-Amz-Algorithm", valid_773933
  var valid_773934 = header.getOrDefault("X-Amz-Signature")
  valid_773934 = validateParameter(valid_773934, JString, required = false,
                                 default = nil)
  if valid_773934 != nil:
    section.add "X-Amz-Signature", valid_773934
  var valid_773935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773935 = validateParameter(valid_773935, JString, required = false,
                                 default = nil)
  if valid_773935 != nil:
    section.add "X-Amz-SignedHeaders", valid_773935
  var valid_773936 = header.getOrDefault("X-Amz-Credential")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "X-Amz-Credential", valid_773936
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_773937 = formData.getOrDefault("Subnets")
  valid_773937 = validateParameter(valid_773937, JArray, required = true, default = nil)
  if valid_773937 != nil:
    section.add "Subnets", valid_773937
  var valid_773938 = formData.getOrDefault("LoadBalancerName")
  valid_773938 = validateParameter(valid_773938, JString, required = true,
                                 default = nil)
  if valid_773938 != nil:
    section.add "LoadBalancerName", valid_773938
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773939: Call_PostDetachLoadBalancerFromSubnets_773925;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_773939.validator(path, query, header, formData, body)
  let scheme = call_773939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773939.url(scheme.get, call_773939.host, call_773939.base,
                         call_773939.route, valid.getOrDefault("path"))
  result = hook(call_773939, url, valid)

proc call*(call_773940: Call_PostDetachLoadBalancerFromSubnets_773925;
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
  var query_773941 = newJObject()
  var formData_773942 = newJObject()
  add(query_773941, "Action", newJString(Action))
  if Subnets != nil:
    formData_773942.add "Subnets", Subnets
  add(formData_773942, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773941, "Version", newJString(Version))
  result = call_773940.call(nil, query_773941, nil, formData_773942, nil)

var postDetachLoadBalancerFromSubnets* = Call_PostDetachLoadBalancerFromSubnets_773925(
    name: "postDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_PostDetachLoadBalancerFromSubnets_773926, base: "/",
    url: url_PostDetachLoadBalancerFromSubnets_773927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetachLoadBalancerFromSubnets_773908 = ref object of OpenApiRestCall_772597
proc url_GetDetachLoadBalancerFromSubnets_773910(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDetachLoadBalancerFromSubnets_773909(path: JsonNode;
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
  var valid_773911 = query.getOrDefault("LoadBalancerName")
  valid_773911 = validateParameter(valid_773911, JString, required = true,
                                 default = nil)
  if valid_773911 != nil:
    section.add "LoadBalancerName", valid_773911
  var valid_773912 = query.getOrDefault("Action")
  valid_773912 = validateParameter(valid_773912, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_773912 != nil:
    section.add "Action", valid_773912
  var valid_773913 = query.getOrDefault("Subnets")
  valid_773913 = validateParameter(valid_773913, JArray, required = true, default = nil)
  if valid_773913 != nil:
    section.add "Subnets", valid_773913
  var valid_773914 = query.getOrDefault("Version")
  valid_773914 = validateParameter(valid_773914, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773914 != nil:
    section.add "Version", valid_773914
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
  var valid_773915 = header.getOrDefault("X-Amz-Date")
  valid_773915 = validateParameter(valid_773915, JString, required = false,
                                 default = nil)
  if valid_773915 != nil:
    section.add "X-Amz-Date", valid_773915
  var valid_773916 = header.getOrDefault("X-Amz-Security-Token")
  valid_773916 = validateParameter(valid_773916, JString, required = false,
                                 default = nil)
  if valid_773916 != nil:
    section.add "X-Amz-Security-Token", valid_773916
  var valid_773917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773917 = validateParameter(valid_773917, JString, required = false,
                                 default = nil)
  if valid_773917 != nil:
    section.add "X-Amz-Content-Sha256", valid_773917
  var valid_773918 = header.getOrDefault("X-Amz-Algorithm")
  valid_773918 = validateParameter(valid_773918, JString, required = false,
                                 default = nil)
  if valid_773918 != nil:
    section.add "X-Amz-Algorithm", valid_773918
  var valid_773919 = header.getOrDefault("X-Amz-Signature")
  valid_773919 = validateParameter(valid_773919, JString, required = false,
                                 default = nil)
  if valid_773919 != nil:
    section.add "X-Amz-Signature", valid_773919
  var valid_773920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773920 = validateParameter(valid_773920, JString, required = false,
                                 default = nil)
  if valid_773920 != nil:
    section.add "X-Amz-SignedHeaders", valid_773920
  var valid_773921 = header.getOrDefault("X-Amz-Credential")
  valid_773921 = validateParameter(valid_773921, JString, required = false,
                                 default = nil)
  if valid_773921 != nil:
    section.add "X-Amz-Credential", valid_773921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773922: Call_GetDetachLoadBalancerFromSubnets_773908;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_773922.validator(path, query, header, formData, body)
  let scheme = call_773922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773922.url(scheme.get, call_773922.host, call_773922.base,
                         call_773922.route, valid.getOrDefault("path"))
  result = hook(call_773922, url, valid)

proc call*(call_773923: Call_GetDetachLoadBalancerFromSubnets_773908;
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
  var query_773924 = newJObject()
  add(query_773924, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773924, "Action", newJString(Action))
  if Subnets != nil:
    query_773924.add "Subnets", Subnets
  add(query_773924, "Version", newJString(Version))
  result = call_773923.call(nil, query_773924, nil, nil, nil)

var getDetachLoadBalancerFromSubnets* = Call_GetDetachLoadBalancerFromSubnets_773908(
    name: "getDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_GetDetachLoadBalancerFromSubnets_773909, base: "/",
    url: url_GetDetachLoadBalancerFromSubnets_773910,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAvailabilityZonesForLoadBalancer_773960 = ref object of OpenApiRestCall_772597
proc url_PostDisableAvailabilityZonesForLoadBalancer_773962(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDisableAvailabilityZonesForLoadBalancer_773961(path: JsonNode;
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
  var valid_773963 = query.getOrDefault("Action")
  valid_773963 = validateParameter(valid_773963, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_773963 != nil:
    section.add "Action", valid_773963
  var valid_773964 = query.getOrDefault("Version")
  valid_773964 = validateParameter(valid_773964, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773964 != nil:
    section.add "Version", valid_773964
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
  var valid_773965 = header.getOrDefault("X-Amz-Date")
  valid_773965 = validateParameter(valid_773965, JString, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "X-Amz-Date", valid_773965
  var valid_773966 = header.getOrDefault("X-Amz-Security-Token")
  valid_773966 = validateParameter(valid_773966, JString, required = false,
                                 default = nil)
  if valid_773966 != nil:
    section.add "X-Amz-Security-Token", valid_773966
  var valid_773967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773967 = validateParameter(valid_773967, JString, required = false,
                                 default = nil)
  if valid_773967 != nil:
    section.add "X-Amz-Content-Sha256", valid_773967
  var valid_773968 = header.getOrDefault("X-Amz-Algorithm")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "X-Amz-Algorithm", valid_773968
  var valid_773969 = header.getOrDefault("X-Amz-Signature")
  valid_773969 = validateParameter(valid_773969, JString, required = false,
                                 default = nil)
  if valid_773969 != nil:
    section.add "X-Amz-Signature", valid_773969
  var valid_773970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773970 = validateParameter(valid_773970, JString, required = false,
                                 default = nil)
  if valid_773970 != nil:
    section.add "X-Amz-SignedHeaders", valid_773970
  var valid_773971 = header.getOrDefault("X-Amz-Credential")
  valid_773971 = validateParameter(valid_773971, JString, required = false,
                                 default = nil)
  if valid_773971 != nil:
    section.add "X-Amz-Credential", valid_773971
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_773972 = formData.getOrDefault("AvailabilityZones")
  valid_773972 = validateParameter(valid_773972, JArray, required = true, default = nil)
  if valid_773972 != nil:
    section.add "AvailabilityZones", valid_773972
  var valid_773973 = formData.getOrDefault("LoadBalancerName")
  valid_773973 = validateParameter(valid_773973, JString, required = true,
                                 default = nil)
  if valid_773973 != nil:
    section.add "LoadBalancerName", valid_773973
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773974: Call_PostDisableAvailabilityZonesForLoadBalancer_773960;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773974.validator(path, query, header, formData, body)
  let scheme = call_773974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773974.url(scheme.get, call_773974.host, call_773974.base,
                         call_773974.route, valid.getOrDefault("path"))
  result = hook(call_773974, url, valid)

proc call*(call_773975: Call_PostDisableAvailabilityZonesForLoadBalancer_773960;
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
  var query_773976 = newJObject()
  var formData_773977 = newJObject()
  add(query_773976, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_773977.add "AvailabilityZones", AvailabilityZones
  add(formData_773977, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_773976, "Version", newJString(Version))
  result = call_773975.call(nil, query_773976, nil, formData_773977, nil)

var postDisableAvailabilityZonesForLoadBalancer* = Call_PostDisableAvailabilityZonesForLoadBalancer_773960(
    name: "postDisableAvailabilityZonesForLoadBalancer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_PostDisableAvailabilityZonesForLoadBalancer_773961,
    base: "/", url: url_PostDisableAvailabilityZonesForLoadBalancer_773962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAvailabilityZonesForLoadBalancer_773943 = ref object of OpenApiRestCall_772597
proc url_GetDisableAvailabilityZonesForLoadBalancer_773945(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDisableAvailabilityZonesForLoadBalancer_773944(path: JsonNode;
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
  var valid_773946 = query.getOrDefault("LoadBalancerName")
  valid_773946 = validateParameter(valid_773946, JString, required = true,
                                 default = nil)
  if valid_773946 != nil:
    section.add "LoadBalancerName", valid_773946
  var valid_773947 = query.getOrDefault("AvailabilityZones")
  valid_773947 = validateParameter(valid_773947, JArray, required = true, default = nil)
  if valid_773947 != nil:
    section.add "AvailabilityZones", valid_773947
  var valid_773948 = query.getOrDefault("Action")
  valid_773948 = validateParameter(valid_773948, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_773948 != nil:
    section.add "Action", valid_773948
  var valid_773949 = query.getOrDefault("Version")
  valid_773949 = validateParameter(valid_773949, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773949 != nil:
    section.add "Version", valid_773949
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
  var valid_773950 = header.getOrDefault("X-Amz-Date")
  valid_773950 = validateParameter(valid_773950, JString, required = false,
                                 default = nil)
  if valid_773950 != nil:
    section.add "X-Amz-Date", valid_773950
  var valid_773951 = header.getOrDefault("X-Amz-Security-Token")
  valid_773951 = validateParameter(valid_773951, JString, required = false,
                                 default = nil)
  if valid_773951 != nil:
    section.add "X-Amz-Security-Token", valid_773951
  var valid_773952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773952 = validateParameter(valid_773952, JString, required = false,
                                 default = nil)
  if valid_773952 != nil:
    section.add "X-Amz-Content-Sha256", valid_773952
  var valid_773953 = header.getOrDefault("X-Amz-Algorithm")
  valid_773953 = validateParameter(valid_773953, JString, required = false,
                                 default = nil)
  if valid_773953 != nil:
    section.add "X-Amz-Algorithm", valid_773953
  var valid_773954 = header.getOrDefault("X-Amz-Signature")
  valid_773954 = validateParameter(valid_773954, JString, required = false,
                                 default = nil)
  if valid_773954 != nil:
    section.add "X-Amz-Signature", valid_773954
  var valid_773955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773955 = validateParameter(valid_773955, JString, required = false,
                                 default = nil)
  if valid_773955 != nil:
    section.add "X-Amz-SignedHeaders", valid_773955
  var valid_773956 = header.getOrDefault("X-Amz-Credential")
  valid_773956 = validateParameter(valid_773956, JString, required = false,
                                 default = nil)
  if valid_773956 != nil:
    section.add "X-Amz-Credential", valid_773956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773957: Call_GetDisableAvailabilityZonesForLoadBalancer_773943;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773957.validator(path, query, header, formData, body)
  let scheme = call_773957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773957.url(scheme.get, call_773957.host, call_773957.base,
                         call_773957.route, valid.getOrDefault("path"))
  result = hook(call_773957, url, valid)

proc call*(call_773958: Call_GetDisableAvailabilityZonesForLoadBalancer_773943;
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
  var query_773959 = newJObject()
  add(query_773959, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_773959.add "AvailabilityZones", AvailabilityZones
  add(query_773959, "Action", newJString(Action))
  add(query_773959, "Version", newJString(Version))
  result = call_773958.call(nil, query_773959, nil, nil, nil)

var getDisableAvailabilityZonesForLoadBalancer* = Call_GetDisableAvailabilityZonesForLoadBalancer_773943(
    name: "getDisableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_GetDisableAvailabilityZonesForLoadBalancer_773944,
    base: "/", url: url_GetDisableAvailabilityZonesForLoadBalancer_773945,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAvailabilityZonesForLoadBalancer_773995 = ref object of OpenApiRestCall_772597
proc url_PostEnableAvailabilityZonesForLoadBalancer_773997(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostEnableAvailabilityZonesForLoadBalancer_773996(path: JsonNode;
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
  var valid_773998 = query.getOrDefault("Action")
  valid_773998 = validateParameter(valid_773998, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_773998 != nil:
    section.add "Action", valid_773998
  var valid_773999 = query.getOrDefault("Version")
  valid_773999 = validateParameter(valid_773999, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773999 != nil:
    section.add "Version", valid_773999
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
  var valid_774000 = header.getOrDefault("X-Amz-Date")
  valid_774000 = validateParameter(valid_774000, JString, required = false,
                                 default = nil)
  if valid_774000 != nil:
    section.add "X-Amz-Date", valid_774000
  var valid_774001 = header.getOrDefault("X-Amz-Security-Token")
  valid_774001 = validateParameter(valid_774001, JString, required = false,
                                 default = nil)
  if valid_774001 != nil:
    section.add "X-Amz-Security-Token", valid_774001
  var valid_774002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774002 = validateParameter(valid_774002, JString, required = false,
                                 default = nil)
  if valid_774002 != nil:
    section.add "X-Amz-Content-Sha256", valid_774002
  var valid_774003 = header.getOrDefault("X-Amz-Algorithm")
  valid_774003 = validateParameter(valid_774003, JString, required = false,
                                 default = nil)
  if valid_774003 != nil:
    section.add "X-Amz-Algorithm", valid_774003
  var valid_774004 = header.getOrDefault("X-Amz-Signature")
  valid_774004 = validateParameter(valid_774004, JString, required = false,
                                 default = nil)
  if valid_774004 != nil:
    section.add "X-Amz-Signature", valid_774004
  var valid_774005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774005 = validateParameter(valid_774005, JString, required = false,
                                 default = nil)
  if valid_774005 != nil:
    section.add "X-Amz-SignedHeaders", valid_774005
  var valid_774006 = header.getOrDefault("X-Amz-Credential")
  valid_774006 = validateParameter(valid_774006, JString, required = false,
                                 default = nil)
  if valid_774006 != nil:
    section.add "X-Amz-Credential", valid_774006
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_774007 = formData.getOrDefault("AvailabilityZones")
  valid_774007 = validateParameter(valid_774007, JArray, required = true, default = nil)
  if valid_774007 != nil:
    section.add "AvailabilityZones", valid_774007
  var valid_774008 = formData.getOrDefault("LoadBalancerName")
  valid_774008 = validateParameter(valid_774008, JString, required = true,
                                 default = nil)
  if valid_774008 != nil:
    section.add "LoadBalancerName", valid_774008
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774009: Call_PostEnableAvailabilityZonesForLoadBalancer_773995;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_774009.validator(path, query, header, formData, body)
  let scheme = call_774009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774009.url(scheme.get, call_774009.host, call_774009.base,
                         call_774009.route, valid.getOrDefault("path"))
  result = hook(call_774009, url, valid)

proc call*(call_774010: Call_PostEnableAvailabilityZonesForLoadBalancer_773995;
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
  var query_774011 = newJObject()
  var formData_774012 = newJObject()
  add(query_774011, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_774012.add "AvailabilityZones", AvailabilityZones
  add(formData_774012, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_774011, "Version", newJString(Version))
  result = call_774010.call(nil, query_774011, nil, formData_774012, nil)

var postEnableAvailabilityZonesForLoadBalancer* = Call_PostEnableAvailabilityZonesForLoadBalancer_773995(
    name: "postEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_PostEnableAvailabilityZonesForLoadBalancer_773996,
    base: "/", url: url_PostEnableAvailabilityZonesForLoadBalancer_773997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAvailabilityZonesForLoadBalancer_773978 = ref object of OpenApiRestCall_772597
proc url_GetEnableAvailabilityZonesForLoadBalancer_773980(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetEnableAvailabilityZonesForLoadBalancer_773979(path: JsonNode;
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
  var valid_773981 = query.getOrDefault("LoadBalancerName")
  valid_773981 = validateParameter(valid_773981, JString, required = true,
                                 default = nil)
  if valid_773981 != nil:
    section.add "LoadBalancerName", valid_773981
  var valid_773982 = query.getOrDefault("AvailabilityZones")
  valid_773982 = validateParameter(valid_773982, JArray, required = true, default = nil)
  if valid_773982 != nil:
    section.add "AvailabilityZones", valid_773982
  var valid_773983 = query.getOrDefault("Action")
  valid_773983 = validateParameter(valid_773983, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_773983 != nil:
    section.add "Action", valid_773983
  var valid_773984 = query.getOrDefault("Version")
  valid_773984 = validateParameter(valid_773984, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_773984 != nil:
    section.add "Version", valid_773984
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
  var valid_773985 = header.getOrDefault("X-Amz-Date")
  valid_773985 = validateParameter(valid_773985, JString, required = false,
                                 default = nil)
  if valid_773985 != nil:
    section.add "X-Amz-Date", valid_773985
  var valid_773986 = header.getOrDefault("X-Amz-Security-Token")
  valid_773986 = validateParameter(valid_773986, JString, required = false,
                                 default = nil)
  if valid_773986 != nil:
    section.add "X-Amz-Security-Token", valid_773986
  var valid_773987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773987 = validateParameter(valid_773987, JString, required = false,
                                 default = nil)
  if valid_773987 != nil:
    section.add "X-Amz-Content-Sha256", valid_773987
  var valid_773988 = header.getOrDefault("X-Amz-Algorithm")
  valid_773988 = validateParameter(valid_773988, JString, required = false,
                                 default = nil)
  if valid_773988 != nil:
    section.add "X-Amz-Algorithm", valid_773988
  var valid_773989 = header.getOrDefault("X-Amz-Signature")
  valid_773989 = validateParameter(valid_773989, JString, required = false,
                                 default = nil)
  if valid_773989 != nil:
    section.add "X-Amz-Signature", valid_773989
  var valid_773990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773990 = validateParameter(valid_773990, JString, required = false,
                                 default = nil)
  if valid_773990 != nil:
    section.add "X-Amz-SignedHeaders", valid_773990
  var valid_773991 = header.getOrDefault("X-Amz-Credential")
  valid_773991 = validateParameter(valid_773991, JString, required = false,
                                 default = nil)
  if valid_773991 != nil:
    section.add "X-Amz-Credential", valid_773991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773992: Call_GetEnableAvailabilityZonesForLoadBalancer_773978;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_773992.validator(path, query, header, formData, body)
  let scheme = call_773992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773992.url(scheme.get, call_773992.host, call_773992.base,
                         call_773992.route, valid.getOrDefault("path"))
  result = hook(call_773992, url, valid)

proc call*(call_773993: Call_GetEnableAvailabilityZonesForLoadBalancer_773978;
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
  var query_773994 = newJObject()
  add(query_773994, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_773994.add "AvailabilityZones", AvailabilityZones
  add(query_773994, "Action", newJString(Action))
  add(query_773994, "Version", newJString(Version))
  result = call_773993.call(nil, query_773994, nil, nil, nil)

var getEnableAvailabilityZonesForLoadBalancer* = Call_GetEnableAvailabilityZonesForLoadBalancer_773978(
    name: "getEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_GetEnableAvailabilityZonesForLoadBalancer_773979,
    base: "/", url: url_GetEnableAvailabilityZonesForLoadBalancer_773980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_774034 = ref object of OpenApiRestCall_772597
proc url_PostModifyLoadBalancerAttributes_774036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyLoadBalancerAttributes_774035(path: JsonNode;
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
  var valid_774037 = query.getOrDefault("Action")
  valid_774037 = validateParameter(valid_774037, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_774037 != nil:
    section.add "Action", valid_774037
  var valid_774038 = query.getOrDefault("Version")
  valid_774038 = validateParameter(valid_774038, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_774038 != nil:
    section.add "Version", valid_774038
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
  var valid_774039 = header.getOrDefault("X-Amz-Date")
  valid_774039 = validateParameter(valid_774039, JString, required = false,
                                 default = nil)
  if valid_774039 != nil:
    section.add "X-Amz-Date", valid_774039
  var valid_774040 = header.getOrDefault("X-Amz-Security-Token")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Security-Token", valid_774040
  var valid_774041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774041 = validateParameter(valid_774041, JString, required = false,
                                 default = nil)
  if valid_774041 != nil:
    section.add "X-Amz-Content-Sha256", valid_774041
  var valid_774042 = header.getOrDefault("X-Amz-Algorithm")
  valid_774042 = validateParameter(valid_774042, JString, required = false,
                                 default = nil)
  if valid_774042 != nil:
    section.add "X-Amz-Algorithm", valid_774042
  var valid_774043 = header.getOrDefault("X-Amz-Signature")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "X-Amz-Signature", valid_774043
  var valid_774044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "X-Amz-SignedHeaders", valid_774044
  var valid_774045 = header.getOrDefault("X-Amz-Credential")
  valid_774045 = validateParameter(valid_774045, JString, required = false,
                                 default = nil)
  if valid_774045 != nil:
    section.add "X-Amz-Credential", valid_774045
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
  var valid_774046 = formData.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_774046 = validateParameter(valid_774046, JArray, required = false,
                                 default = nil)
  if valid_774046 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_774046
  var valid_774047 = formData.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_774047 = validateParameter(valid_774047, JString, required = false,
                                 default = nil)
  if valid_774047 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_774047
  var valid_774048 = formData.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_774048 = validateParameter(valid_774048, JString, required = false,
                                 default = nil)
  if valid_774048 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_774048
  var valid_774049 = formData.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_774049 = validateParameter(valid_774049, JString, required = false,
                                 default = nil)
  if valid_774049 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_774049
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_774050 = formData.getOrDefault("LoadBalancerName")
  valid_774050 = validateParameter(valid_774050, JString, required = true,
                                 default = nil)
  if valid_774050 != nil:
    section.add "LoadBalancerName", valid_774050
  var valid_774051 = formData.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_774051 = validateParameter(valid_774051, JString, required = false,
                                 default = nil)
  if valid_774051 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_774051
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774052: Call_PostModifyLoadBalancerAttributes_774034;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_774052.validator(path, query, header, formData, body)
  let scheme = call_774052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774052.url(scheme.get, call_774052.host, call_774052.base,
                         call_774052.route, valid.getOrDefault("path"))
  result = hook(call_774052, url, valid)

proc call*(call_774053: Call_PostModifyLoadBalancerAttributes_774034;
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
  var query_774054 = newJObject()
  var formData_774055 = newJObject()
  if LoadBalancerAttributesAdditionalAttributes != nil:
    formData_774055.add "LoadBalancerAttributes.AdditionalAttributes",
                       LoadBalancerAttributesAdditionalAttributes
  add(formData_774055, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  add(formData_774055, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_774054, "Action", newJString(Action))
  add(formData_774055, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(formData_774055, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_774055, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_774054, "Version", newJString(Version))
  result = call_774053.call(nil, query_774054, nil, formData_774055, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_774034(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_774035, base: "/",
    url: url_PostModifyLoadBalancerAttributes_774036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_774013 = ref object of OpenApiRestCall_772597
proc url_GetModifyLoadBalancerAttributes_774015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyLoadBalancerAttributes_774014(path: JsonNode;
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
  var valid_774016 = query.getOrDefault("LoadBalancerName")
  valid_774016 = validateParameter(valid_774016, JString, required = true,
                                 default = nil)
  if valid_774016 != nil:
    section.add "LoadBalancerName", valid_774016
  var valid_774017 = query.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_774017 = validateParameter(valid_774017, JString, required = false,
                                 default = nil)
  if valid_774017 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_774017
  var valid_774018 = query.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_774018 = validateParameter(valid_774018, JString, required = false,
                                 default = nil)
  if valid_774018 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_774018
  var valid_774019 = query.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_774019 = validateParameter(valid_774019, JArray, required = false,
                                 default = nil)
  if valid_774019 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_774019
  var valid_774020 = query.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_774020 = validateParameter(valid_774020, JString, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_774020
  var valid_774021 = query.getOrDefault("Action")
  valid_774021 = validateParameter(valid_774021, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_774021 != nil:
    section.add "Action", valid_774021
  var valid_774022 = query.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_774022
  var valid_774023 = query.getOrDefault("Version")
  valid_774023 = validateParameter(valid_774023, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_774023 != nil:
    section.add "Version", valid_774023
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
  var valid_774024 = header.getOrDefault("X-Amz-Date")
  valid_774024 = validateParameter(valid_774024, JString, required = false,
                                 default = nil)
  if valid_774024 != nil:
    section.add "X-Amz-Date", valid_774024
  var valid_774025 = header.getOrDefault("X-Amz-Security-Token")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "X-Amz-Security-Token", valid_774025
  var valid_774026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "X-Amz-Content-Sha256", valid_774026
  var valid_774027 = header.getOrDefault("X-Amz-Algorithm")
  valid_774027 = validateParameter(valid_774027, JString, required = false,
                                 default = nil)
  if valid_774027 != nil:
    section.add "X-Amz-Algorithm", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-Signature")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-Signature", valid_774028
  var valid_774029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774029 = validateParameter(valid_774029, JString, required = false,
                                 default = nil)
  if valid_774029 != nil:
    section.add "X-Amz-SignedHeaders", valid_774029
  var valid_774030 = header.getOrDefault("X-Amz-Credential")
  valid_774030 = validateParameter(valid_774030, JString, required = false,
                                 default = nil)
  if valid_774030 != nil:
    section.add "X-Amz-Credential", valid_774030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774031: Call_GetModifyLoadBalancerAttributes_774013;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_774031.validator(path, query, header, formData, body)
  let scheme = call_774031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774031.url(scheme.get, call_774031.host, call_774031.base,
                         call_774031.route, valid.getOrDefault("path"))
  result = hook(call_774031, url, valid)

proc call*(call_774032: Call_GetModifyLoadBalancerAttributes_774013;
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
  var query_774033 = newJObject()
  add(query_774033, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_774033, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_774033, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    query_774033.add "LoadBalancerAttributes.AdditionalAttributes",
                    LoadBalancerAttributesAdditionalAttributes
  add(query_774033, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_774033, "Action", newJString(Action))
  add(query_774033, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_774033, "Version", newJString(Version))
  result = call_774032.call(nil, query_774033, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_774013(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_774014, base: "/",
    url: url_GetModifyLoadBalancerAttributes_774015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterInstancesWithLoadBalancer_774073 = ref object of OpenApiRestCall_772597
proc url_PostRegisterInstancesWithLoadBalancer_774075(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRegisterInstancesWithLoadBalancer_774074(path: JsonNode;
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
  var valid_774076 = query.getOrDefault("Action")
  valid_774076 = validateParameter(valid_774076, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_774076 != nil:
    section.add "Action", valid_774076
  var valid_774077 = query.getOrDefault("Version")
  valid_774077 = validateParameter(valid_774077, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_774077 != nil:
    section.add "Version", valid_774077
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
  var valid_774078 = header.getOrDefault("X-Amz-Date")
  valid_774078 = validateParameter(valid_774078, JString, required = false,
                                 default = nil)
  if valid_774078 != nil:
    section.add "X-Amz-Date", valid_774078
  var valid_774079 = header.getOrDefault("X-Amz-Security-Token")
  valid_774079 = validateParameter(valid_774079, JString, required = false,
                                 default = nil)
  if valid_774079 != nil:
    section.add "X-Amz-Security-Token", valid_774079
  var valid_774080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774080 = validateParameter(valid_774080, JString, required = false,
                                 default = nil)
  if valid_774080 != nil:
    section.add "X-Amz-Content-Sha256", valid_774080
  var valid_774081 = header.getOrDefault("X-Amz-Algorithm")
  valid_774081 = validateParameter(valid_774081, JString, required = false,
                                 default = nil)
  if valid_774081 != nil:
    section.add "X-Amz-Algorithm", valid_774081
  var valid_774082 = header.getOrDefault("X-Amz-Signature")
  valid_774082 = validateParameter(valid_774082, JString, required = false,
                                 default = nil)
  if valid_774082 != nil:
    section.add "X-Amz-Signature", valid_774082
  var valid_774083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774083 = validateParameter(valid_774083, JString, required = false,
                                 default = nil)
  if valid_774083 != nil:
    section.add "X-Amz-SignedHeaders", valid_774083
  var valid_774084 = header.getOrDefault("X-Amz-Credential")
  valid_774084 = validateParameter(valid_774084, JString, required = false,
                                 default = nil)
  if valid_774084 != nil:
    section.add "X-Amz-Credential", valid_774084
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_774085 = formData.getOrDefault("Instances")
  valid_774085 = validateParameter(valid_774085, JArray, required = true, default = nil)
  if valid_774085 != nil:
    section.add "Instances", valid_774085
  var valid_774086 = formData.getOrDefault("LoadBalancerName")
  valid_774086 = validateParameter(valid_774086, JString, required = true,
                                 default = nil)
  if valid_774086 != nil:
    section.add "LoadBalancerName", valid_774086
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774087: Call_PostRegisterInstancesWithLoadBalancer_774073;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_774087.validator(path, query, header, formData, body)
  let scheme = call_774087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774087.url(scheme.get, call_774087.host, call_774087.base,
                         call_774087.route, valid.getOrDefault("path"))
  result = hook(call_774087, url, valid)

proc call*(call_774088: Call_PostRegisterInstancesWithLoadBalancer_774073;
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
  var query_774089 = newJObject()
  var formData_774090 = newJObject()
  if Instances != nil:
    formData_774090.add "Instances", Instances
  add(query_774089, "Action", newJString(Action))
  add(formData_774090, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_774089, "Version", newJString(Version))
  result = call_774088.call(nil, query_774089, nil, formData_774090, nil)

var postRegisterInstancesWithLoadBalancer* = Call_PostRegisterInstancesWithLoadBalancer_774073(
    name: "postRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_PostRegisterInstancesWithLoadBalancer_774074, base: "/",
    url: url_PostRegisterInstancesWithLoadBalancer_774075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterInstancesWithLoadBalancer_774056 = ref object of OpenApiRestCall_772597
proc url_GetRegisterInstancesWithLoadBalancer_774058(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRegisterInstancesWithLoadBalancer_774057(path: JsonNode;
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
  var valid_774059 = query.getOrDefault("LoadBalancerName")
  valid_774059 = validateParameter(valid_774059, JString, required = true,
                                 default = nil)
  if valid_774059 != nil:
    section.add "LoadBalancerName", valid_774059
  var valid_774060 = query.getOrDefault("Action")
  valid_774060 = validateParameter(valid_774060, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_774060 != nil:
    section.add "Action", valid_774060
  var valid_774061 = query.getOrDefault("Instances")
  valid_774061 = validateParameter(valid_774061, JArray, required = true, default = nil)
  if valid_774061 != nil:
    section.add "Instances", valid_774061
  var valid_774062 = query.getOrDefault("Version")
  valid_774062 = validateParameter(valid_774062, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_774062 != nil:
    section.add "Version", valid_774062
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
  var valid_774063 = header.getOrDefault("X-Amz-Date")
  valid_774063 = validateParameter(valid_774063, JString, required = false,
                                 default = nil)
  if valid_774063 != nil:
    section.add "X-Amz-Date", valid_774063
  var valid_774064 = header.getOrDefault("X-Amz-Security-Token")
  valid_774064 = validateParameter(valid_774064, JString, required = false,
                                 default = nil)
  if valid_774064 != nil:
    section.add "X-Amz-Security-Token", valid_774064
  var valid_774065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774065 = validateParameter(valid_774065, JString, required = false,
                                 default = nil)
  if valid_774065 != nil:
    section.add "X-Amz-Content-Sha256", valid_774065
  var valid_774066 = header.getOrDefault("X-Amz-Algorithm")
  valid_774066 = validateParameter(valid_774066, JString, required = false,
                                 default = nil)
  if valid_774066 != nil:
    section.add "X-Amz-Algorithm", valid_774066
  var valid_774067 = header.getOrDefault("X-Amz-Signature")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "X-Amz-Signature", valid_774067
  var valid_774068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774068 = validateParameter(valid_774068, JString, required = false,
                                 default = nil)
  if valid_774068 != nil:
    section.add "X-Amz-SignedHeaders", valid_774068
  var valid_774069 = header.getOrDefault("X-Amz-Credential")
  valid_774069 = validateParameter(valid_774069, JString, required = false,
                                 default = nil)
  if valid_774069 != nil:
    section.add "X-Amz-Credential", valid_774069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774070: Call_GetRegisterInstancesWithLoadBalancer_774056;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_774070.validator(path, query, header, formData, body)
  let scheme = call_774070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774070.url(scheme.get, call_774070.host, call_774070.base,
                         call_774070.route, valid.getOrDefault("path"))
  result = hook(call_774070, url, valid)

proc call*(call_774071: Call_GetRegisterInstancesWithLoadBalancer_774056;
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
  var query_774072 = newJObject()
  add(query_774072, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_774072, "Action", newJString(Action))
  if Instances != nil:
    query_774072.add "Instances", Instances
  add(query_774072, "Version", newJString(Version))
  result = call_774071.call(nil, query_774072, nil, nil, nil)

var getRegisterInstancesWithLoadBalancer* = Call_GetRegisterInstancesWithLoadBalancer_774056(
    name: "getRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_GetRegisterInstancesWithLoadBalancer_774057, base: "/",
    url: url_GetRegisterInstancesWithLoadBalancer_774058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_774108 = ref object of OpenApiRestCall_772597
proc url_PostRemoveTags_774110(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTags_774109(path: JsonNode; query: JsonNode;
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
  var valid_774111 = query.getOrDefault("Action")
  valid_774111 = validateParameter(valid_774111, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_774111 != nil:
    section.add "Action", valid_774111
  var valid_774112 = query.getOrDefault("Version")
  valid_774112 = validateParameter(valid_774112, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_774112 != nil:
    section.add "Version", valid_774112
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
  var valid_774113 = header.getOrDefault("X-Amz-Date")
  valid_774113 = validateParameter(valid_774113, JString, required = false,
                                 default = nil)
  if valid_774113 != nil:
    section.add "X-Amz-Date", valid_774113
  var valid_774114 = header.getOrDefault("X-Amz-Security-Token")
  valid_774114 = validateParameter(valid_774114, JString, required = false,
                                 default = nil)
  if valid_774114 != nil:
    section.add "X-Amz-Security-Token", valid_774114
  var valid_774115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Content-Sha256", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-Algorithm")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Algorithm", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-Signature")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-Signature", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-SignedHeaders", valid_774118
  var valid_774119 = header.getOrDefault("X-Amz-Credential")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-Credential", valid_774119
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_774120 = formData.getOrDefault("Tags")
  valid_774120 = validateParameter(valid_774120, JArray, required = true, default = nil)
  if valid_774120 != nil:
    section.add "Tags", valid_774120
  var valid_774121 = formData.getOrDefault("LoadBalancerNames")
  valid_774121 = validateParameter(valid_774121, JArray, required = true, default = nil)
  if valid_774121 != nil:
    section.add "LoadBalancerNames", valid_774121
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774122: Call_PostRemoveTags_774108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_774122.validator(path, query, header, formData, body)
  let scheme = call_774122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774122.url(scheme.get, call_774122.host, call_774122.base,
                         call_774122.route, valid.getOrDefault("path"))
  result = hook(call_774122, url, valid)

proc call*(call_774123: Call_PostRemoveTags_774108; Tags: JsonNode;
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
  var query_774124 = newJObject()
  var formData_774125 = newJObject()
  if Tags != nil:
    formData_774125.add "Tags", Tags
  add(query_774124, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_774125.add "LoadBalancerNames", LoadBalancerNames
  add(query_774124, "Version", newJString(Version))
  result = call_774123.call(nil, query_774124, nil, formData_774125, nil)

var postRemoveTags* = Call_PostRemoveTags_774108(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_774109,
    base: "/", url: url_PostRemoveTags_774110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_774091 = ref object of OpenApiRestCall_772597
proc url_GetRemoveTags_774093(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTags_774092(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774094 = query.getOrDefault("Tags")
  valid_774094 = validateParameter(valid_774094, JArray, required = true, default = nil)
  if valid_774094 != nil:
    section.add "Tags", valid_774094
  var valid_774095 = query.getOrDefault("Action")
  valid_774095 = validateParameter(valid_774095, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_774095 != nil:
    section.add "Action", valid_774095
  var valid_774096 = query.getOrDefault("LoadBalancerNames")
  valid_774096 = validateParameter(valid_774096, JArray, required = true, default = nil)
  if valid_774096 != nil:
    section.add "LoadBalancerNames", valid_774096
  var valid_774097 = query.getOrDefault("Version")
  valid_774097 = validateParameter(valid_774097, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_774097 != nil:
    section.add "Version", valid_774097
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
  var valid_774098 = header.getOrDefault("X-Amz-Date")
  valid_774098 = validateParameter(valid_774098, JString, required = false,
                                 default = nil)
  if valid_774098 != nil:
    section.add "X-Amz-Date", valid_774098
  var valid_774099 = header.getOrDefault("X-Amz-Security-Token")
  valid_774099 = validateParameter(valid_774099, JString, required = false,
                                 default = nil)
  if valid_774099 != nil:
    section.add "X-Amz-Security-Token", valid_774099
  var valid_774100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "X-Amz-Content-Sha256", valid_774100
  var valid_774101 = header.getOrDefault("X-Amz-Algorithm")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "X-Amz-Algorithm", valid_774101
  var valid_774102 = header.getOrDefault("X-Amz-Signature")
  valid_774102 = validateParameter(valid_774102, JString, required = false,
                                 default = nil)
  if valid_774102 != nil:
    section.add "X-Amz-Signature", valid_774102
  var valid_774103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "X-Amz-SignedHeaders", valid_774103
  var valid_774104 = header.getOrDefault("X-Amz-Credential")
  valid_774104 = validateParameter(valid_774104, JString, required = false,
                                 default = nil)
  if valid_774104 != nil:
    section.add "X-Amz-Credential", valid_774104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774105: Call_GetRemoveTags_774091; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_774105.validator(path, query, header, formData, body)
  let scheme = call_774105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774105.url(scheme.get, call_774105.host, call_774105.base,
                         call_774105.route, valid.getOrDefault("path"))
  result = hook(call_774105, url, valid)

proc call*(call_774106: Call_GetRemoveTags_774091; Tags: JsonNode;
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
  var query_774107 = newJObject()
  if Tags != nil:
    query_774107.add "Tags", Tags
  add(query_774107, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_774107.add "LoadBalancerNames", LoadBalancerNames
  add(query_774107, "Version", newJString(Version))
  result = call_774106.call(nil, query_774107, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_774091(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_774092,
    base: "/", url: url_GetRemoveTags_774093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerListenerSSLCertificate_774144 = ref object of OpenApiRestCall_772597
proc url_PostSetLoadBalancerListenerSSLCertificate_774146(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetLoadBalancerListenerSSLCertificate_774145(path: JsonNode;
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
  var valid_774147 = query.getOrDefault("Action")
  valid_774147 = validateParameter(valid_774147, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_774147 != nil:
    section.add "Action", valid_774147
  var valid_774148 = query.getOrDefault("Version")
  valid_774148 = validateParameter(valid_774148, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_774148 != nil:
    section.add "Version", valid_774148
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
  var valid_774149 = header.getOrDefault("X-Amz-Date")
  valid_774149 = validateParameter(valid_774149, JString, required = false,
                                 default = nil)
  if valid_774149 != nil:
    section.add "X-Amz-Date", valid_774149
  var valid_774150 = header.getOrDefault("X-Amz-Security-Token")
  valid_774150 = validateParameter(valid_774150, JString, required = false,
                                 default = nil)
  if valid_774150 != nil:
    section.add "X-Amz-Security-Token", valid_774150
  var valid_774151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = nil)
  if valid_774151 != nil:
    section.add "X-Amz-Content-Sha256", valid_774151
  var valid_774152 = header.getOrDefault("X-Amz-Algorithm")
  valid_774152 = validateParameter(valid_774152, JString, required = false,
                                 default = nil)
  if valid_774152 != nil:
    section.add "X-Amz-Algorithm", valid_774152
  var valid_774153 = header.getOrDefault("X-Amz-Signature")
  valid_774153 = validateParameter(valid_774153, JString, required = false,
                                 default = nil)
  if valid_774153 != nil:
    section.add "X-Amz-Signature", valid_774153
  var valid_774154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774154 = validateParameter(valid_774154, JString, required = false,
                                 default = nil)
  if valid_774154 != nil:
    section.add "X-Amz-SignedHeaders", valid_774154
  var valid_774155 = header.getOrDefault("X-Amz-Credential")
  valid_774155 = validateParameter(valid_774155, JString, required = false,
                                 default = nil)
  if valid_774155 != nil:
    section.add "X-Amz-Credential", valid_774155
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
  var valid_774156 = formData.getOrDefault("LoadBalancerPort")
  valid_774156 = validateParameter(valid_774156, JInt, required = true, default = nil)
  if valid_774156 != nil:
    section.add "LoadBalancerPort", valid_774156
  var valid_774157 = formData.getOrDefault("SSLCertificateId")
  valid_774157 = validateParameter(valid_774157, JString, required = true,
                                 default = nil)
  if valid_774157 != nil:
    section.add "SSLCertificateId", valid_774157
  var valid_774158 = formData.getOrDefault("LoadBalancerName")
  valid_774158 = validateParameter(valid_774158, JString, required = true,
                                 default = nil)
  if valid_774158 != nil:
    section.add "LoadBalancerName", valid_774158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774159: Call_PostSetLoadBalancerListenerSSLCertificate_774144;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_774159.validator(path, query, header, formData, body)
  let scheme = call_774159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774159.url(scheme.get, call_774159.host, call_774159.base,
                         call_774159.route, valid.getOrDefault("path"))
  result = hook(call_774159, url, valid)

proc call*(call_774160: Call_PostSetLoadBalancerListenerSSLCertificate_774144;
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
  var query_774161 = newJObject()
  var formData_774162 = newJObject()
  add(formData_774162, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(formData_774162, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_774161, "Action", newJString(Action))
  add(formData_774162, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_774161, "Version", newJString(Version))
  result = call_774160.call(nil, query_774161, nil, formData_774162, nil)

var postSetLoadBalancerListenerSSLCertificate* = Call_PostSetLoadBalancerListenerSSLCertificate_774144(
    name: "postSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_PostSetLoadBalancerListenerSSLCertificate_774145,
    base: "/", url: url_PostSetLoadBalancerListenerSSLCertificate_774146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerListenerSSLCertificate_774126 = ref object of OpenApiRestCall_772597
proc url_GetSetLoadBalancerListenerSSLCertificate_774128(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetLoadBalancerListenerSSLCertificate_774127(path: JsonNode;
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
  var valid_774129 = query.getOrDefault("LoadBalancerName")
  valid_774129 = validateParameter(valid_774129, JString, required = true,
                                 default = nil)
  if valid_774129 != nil:
    section.add "LoadBalancerName", valid_774129
  var valid_774130 = query.getOrDefault("SSLCertificateId")
  valid_774130 = validateParameter(valid_774130, JString, required = true,
                                 default = nil)
  if valid_774130 != nil:
    section.add "SSLCertificateId", valid_774130
  var valid_774131 = query.getOrDefault("LoadBalancerPort")
  valid_774131 = validateParameter(valid_774131, JInt, required = true, default = nil)
  if valid_774131 != nil:
    section.add "LoadBalancerPort", valid_774131
  var valid_774132 = query.getOrDefault("Action")
  valid_774132 = validateParameter(valid_774132, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_774132 != nil:
    section.add "Action", valid_774132
  var valid_774133 = query.getOrDefault("Version")
  valid_774133 = validateParameter(valid_774133, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_774133 != nil:
    section.add "Version", valid_774133
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
  var valid_774134 = header.getOrDefault("X-Amz-Date")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "X-Amz-Date", valid_774134
  var valid_774135 = header.getOrDefault("X-Amz-Security-Token")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "X-Amz-Security-Token", valid_774135
  var valid_774136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "X-Amz-Content-Sha256", valid_774136
  var valid_774137 = header.getOrDefault("X-Amz-Algorithm")
  valid_774137 = validateParameter(valid_774137, JString, required = false,
                                 default = nil)
  if valid_774137 != nil:
    section.add "X-Amz-Algorithm", valid_774137
  var valid_774138 = header.getOrDefault("X-Amz-Signature")
  valid_774138 = validateParameter(valid_774138, JString, required = false,
                                 default = nil)
  if valid_774138 != nil:
    section.add "X-Amz-Signature", valid_774138
  var valid_774139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774139 = validateParameter(valid_774139, JString, required = false,
                                 default = nil)
  if valid_774139 != nil:
    section.add "X-Amz-SignedHeaders", valid_774139
  var valid_774140 = header.getOrDefault("X-Amz-Credential")
  valid_774140 = validateParameter(valid_774140, JString, required = false,
                                 default = nil)
  if valid_774140 != nil:
    section.add "X-Amz-Credential", valid_774140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774141: Call_GetSetLoadBalancerListenerSSLCertificate_774126;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_774141.validator(path, query, header, formData, body)
  let scheme = call_774141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774141.url(scheme.get, call_774141.host, call_774141.base,
                         call_774141.route, valid.getOrDefault("path"))
  result = hook(call_774141, url, valid)

proc call*(call_774142: Call_GetSetLoadBalancerListenerSSLCertificate_774126;
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
  var query_774143 = newJObject()
  add(query_774143, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_774143, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_774143, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_774143, "Action", newJString(Action))
  add(query_774143, "Version", newJString(Version))
  result = call_774142.call(nil, query_774143, nil, nil, nil)

var getSetLoadBalancerListenerSSLCertificate* = Call_GetSetLoadBalancerListenerSSLCertificate_774126(
    name: "getSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_GetSetLoadBalancerListenerSSLCertificate_774127,
    base: "/", url: url_GetSetLoadBalancerListenerSSLCertificate_774128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesForBackendServer_774181 = ref object of OpenApiRestCall_772597
proc url_PostSetLoadBalancerPoliciesForBackendServer_774183(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetLoadBalancerPoliciesForBackendServer_774182(path: JsonNode;
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
  var valid_774184 = query.getOrDefault("Action")
  valid_774184 = validateParameter(valid_774184, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_774184 != nil:
    section.add "Action", valid_774184
  var valid_774185 = query.getOrDefault("Version")
  valid_774185 = validateParameter(valid_774185, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_774185 != nil:
    section.add "Version", valid_774185
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
  var valid_774186 = header.getOrDefault("X-Amz-Date")
  valid_774186 = validateParameter(valid_774186, JString, required = false,
                                 default = nil)
  if valid_774186 != nil:
    section.add "X-Amz-Date", valid_774186
  var valid_774187 = header.getOrDefault("X-Amz-Security-Token")
  valid_774187 = validateParameter(valid_774187, JString, required = false,
                                 default = nil)
  if valid_774187 != nil:
    section.add "X-Amz-Security-Token", valid_774187
  var valid_774188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774188 = validateParameter(valid_774188, JString, required = false,
                                 default = nil)
  if valid_774188 != nil:
    section.add "X-Amz-Content-Sha256", valid_774188
  var valid_774189 = header.getOrDefault("X-Amz-Algorithm")
  valid_774189 = validateParameter(valid_774189, JString, required = false,
                                 default = nil)
  if valid_774189 != nil:
    section.add "X-Amz-Algorithm", valid_774189
  var valid_774190 = header.getOrDefault("X-Amz-Signature")
  valid_774190 = validateParameter(valid_774190, JString, required = false,
                                 default = nil)
  if valid_774190 != nil:
    section.add "X-Amz-Signature", valid_774190
  var valid_774191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774191 = validateParameter(valid_774191, JString, required = false,
                                 default = nil)
  if valid_774191 != nil:
    section.add "X-Amz-SignedHeaders", valid_774191
  var valid_774192 = header.getOrDefault("X-Amz-Credential")
  valid_774192 = validateParameter(valid_774192, JString, required = false,
                                 default = nil)
  if valid_774192 != nil:
    section.add "X-Amz-Credential", valid_774192
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
  var valid_774193 = formData.getOrDefault("PolicyNames")
  valid_774193 = validateParameter(valid_774193, JArray, required = true, default = nil)
  if valid_774193 != nil:
    section.add "PolicyNames", valid_774193
  var valid_774194 = formData.getOrDefault("InstancePort")
  valid_774194 = validateParameter(valid_774194, JInt, required = true, default = nil)
  if valid_774194 != nil:
    section.add "InstancePort", valid_774194
  var valid_774195 = formData.getOrDefault("LoadBalancerName")
  valid_774195 = validateParameter(valid_774195, JString, required = true,
                                 default = nil)
  if valid_774195 != nil:
    section.add "LoadBalancerName", valid_774195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774196: Call_PostSetLoadBalancerPoliciesForBackendServer_774181;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_774196.validator(path, query, header, formData, body)
  let scheme = call_774196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774196.url(scheme.get, call_774196.host, call_774196.base,
                         call_774196.route, valid.getOrDefault("path"))
  result = hook(call_774196, url, valid)

proc call*(call_774197: Call_PostSetLoadBalancerPoliciesForBackendServer_774181;
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
  var query_774198 = newJObject()
  var formData_774199 = newJObject()
  if PolicyNames != nil:
    formData_774199.add "PolicyNames", PolicyNames
  add(formData_774199, "InstancePort", newJInt(InstancePort))
  add(query_774198, "Action", newJString(Action))
  add(formData_774199, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_774198, "Version", newJString(Version))
  result = call_774197.call(nil, query_774198, nil, formData_774199, nil)

var postSetLoadBalancerPoliciesForBackendServer* = Call_PostSetLoadBalancerPoliciesForBackendServer_774181(
    name: "postSetLoadBalancerPoliciesForBackendServer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_PostSetLoadBalancerPoliciesForBackendServer_774182,
    base: "/", url: url_PostSetLoadBalancerPoliciesForBackendServer_774183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesForBackendServer_774163 = ref object of OpenApiRestCall_772597
proc url_GetSetLoadBalancerPoliciesForBackendServer_774165(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetLoadBalancerPoliciesForBackendServer_774164(path: JsonNode;
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
  var valid_774166 = query.getOrDefault("LoadBalancerName")
  valid_774166 = validateParameter(valid_774166, JString, required = true,
                                 default = nil)
  if valid_774166 != nil:
    section.add "LoadBalancerName", valid_774166
  var valid_774167 = query.getOrDefault("Action")
  valid_774167 = validateParameter(valid_774167, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_774167 != nil:
    section.add "Action", valid_774167
  var valid_774168 = query.getOrDefault("PolicyNames")
  valid_774168 = validateParameter(valid_774168, JArray, required = true, default = nil)
  if valid_774168 != nil:
    section.add "PolicyNames", valid_774168
  var valid_774169 = query.getOrDefault("Version")
  valid_774169 = validateParameter(valid_774169, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_774169 != nil:
    section.add "Version", valid_774169
  var valid_774170 = query.getOrDefault("InstancePort")
  valid_774170 = validateParameter(valid_774170, JInt, required = true, default = nil)
  if valid_774170 != nil:
    section.add "InstancePort", valid_774170
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
  var valid_774171 = header.getOrDefault("X-Amz-Date")
  valid_774171 = validateParameter(valid_774171, JString, required = false,
                                 default = nil)
  if valid_774171 != nil:
    section.add "X-Amz-Date", valid_774171
  var valid_774172 = header.getOrDefault("X-Amz-Security-Token")
  valid_774172 = validateParameter(valid_774172, JString, required = false,
                                 default = nil)
  if valid_774172 != nil:
    section.add "X-Amz-Security-Token", valid_774172
  var valid_774173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774173 = validateParameter(valid_774173, JString, required = false,
                                 default = nil)
  if valid_774173 != nil:
    section.add "X-Amz-Content-Sha256", valid_774173
  var valid_774174 = header.getOrDefault("X-Amz-Algorithm")
  valid_774174 = validateParameter(valid_774174, JString, required = false,
                                 default = nil)
  if valid_774174 != nil:
    section.add "X-Amz-Algorithm", valid_774174
  var valid_774175 = header.getOrDefault("X-Amz-Signature")
  valid_774175 = validateParameter(valid_774175, JString, required = false,
                                 default = nil)
  if valid_774175 != nil:
    section.add "X-Amz-Signature", valid_774175
  var valid_774176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774176 = validateParameter(valid_774176, JString, required = false,
                                 default = nil)
  if valid_774176 != nil:
    section.add "X-Amz-SignedHeaders", valid_774176
  var valid_774177 = header.getOrDefault("X-Amz-Credential")
  valid_774177 = validateParameter(valid_774177, JString, required = false,
                                 default = nil)
  if valid_774177 != nil:
    section.add "X-Amz-Credential", valid_774177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774178: Call_GetSetLoadBalancerPoliciesForBackendServer_774163;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_774178.validator(path, query, header, formData, body)
  let scheme = call_774178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774178.url(scheme.get, call_774178.host, call_774178.base,
                         call_774178.route, valid.getOrDefault("path"))
  result = hook(call_774178, url, valid)

proc call*(call_774179: Call_GetSetLoadBalancerPoliciesForBackendServer_774163;
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
  var query_774180 = newJObject()
  add(query_774180, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_774180, "Action", newJString(Action))
  if PolicyNames != nil:
    query_774180.add "PolicyNames", PolicyNames
  add(query_774180, "Version", newJString(Version))
  add(query_774180, "InstancePort", newJInt(InstancePort))
  result = call_774179.call(nil, query_774180, nil, nil, nil)

var getSetLoadBalancerPoliciesForBackendServer* = Call_GetSetLoadBalancerPoliciesForBackendServer_774163(
    name: "getSetLoadBalancerPoliciesForBackendServer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_GetSetLoadBalancerPoliciesForBackendServer_774164,
    base: "/", url: url_GetSetLoadBalancerPoliciesForBackendServer_774165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesOfListener_774218 = ref object of OpenApiRestCall_772597
proc url_PostSetLoadBalancerPoliciesOfListener_774220(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetLoadBalancerPoliciesOfListener_774219(path: JsonNode;
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
  var valid_774221 = query.getOrDefault("Action")
  valid_774221 = validateParameter(valid_774221, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_774221 != nil:
    section.add "Action", valid_774221
  var valid_774222 = query.getOrDefault("Version")
  valid_774222 = validateParameter(valid_774222, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_774222 != nil:
    section.add "Version", valid_774222
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
  var valid_774223 = header.getOrDefault("X-Amz-Date")
  valid_774223 = validateParameter(valid_774223, JString, required = false,
                                 default = nil)
  if valid_774223 != nil:
    section.add "X-Amz-Date", valid_774223
  var valid_774224 = header.getOrDefault("X-Amz-Security-Token")
  valid_774224 = validateParameter(valid_774224, JString, required = false,
                                 default = nil)
  if valid_774224 != nil:
    section.add "X-Amz-Security-Token", valid_774224
  var valid_774225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774225 = validateParameter(valid_774225, JString, required = false,
                                 default = nil)
  if valid_774225 != nil:
    section.add "X-Amz-Content-Sha256", valid_774225
  var valid_774226 = header.getOrDefault("X-Amz-Algorithm")
  valid_774226 = validateParameter(valid_774226, JString, required = false,
                                 default = nil)
  if valid_774226 != nil:
    section.add "X-Amz-Algorithm", valid_774226
  var valid_774227 = header.getOrDefault("X-Amz-Signature")
  valid_774227 = validateParameter(valid_774227, JString, required = false,
                                 default = nil)
  if valid_774227 != nil:
    section.add "X-Amz-Signature", valid_774227
  var valid_774228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774228 = validateParameter(valid_774228, JString, required = false,
                                 default = nil)
  if valid_774228 != nil:
    section.add "X-Amz-SignedHeaders", valid_774228
  var valid_774229 = header.getOrDefault("X-Amz-Credential")
  valid_774229 = validateParameter(valid_774229, JString, required = false,
                                 default = nil)
  if valid_774229 != nil:
    section.add "X-Amz-Credential", valid_774229
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
  var valid_774230 = formData.getOrDefault("LoadBalancerPort")
  valid_774230 = validateParameter(valid_774230, JInt, required = true, default = nil)
  if valid_774230 != nil:
    section.add "LoadBalancerPort", valid_774230
  var valid_774231 = formData.getOrDefault("PolicyNames")
  valid_774231 = validateParameter(valid_774231, JArray, required = true, default = nil)
  if valid_774231 != nil:
    section.add "PolicyNames", valid_774231
  var valid_774232 = formData.getOrDefault("LoadBalancerName")
  valid_774232 = validateParameter(valid_774232, JString, required = true,
                                 default = nil)
  if valid_774232 != nil:
    section.add "LoadBalancerName", valid_774232
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774233: Call_PostSetLoadBalancerPoliciesOfListener_774218;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_774233.validator(path, query, header, formData, body)
  let scheme = call_774233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774233.url(scheme.get, call_774233.host, call_774233.base,
                         call_774233.route, valid.getOrDefault("path"))
  result = hook(call_774233, url, valid)

proc call*(call_774234: Call_PostSetLoadBalancerPoliciesOfListener_774218;
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
  var query_774235 = newJObject()
  var formData_774236 = newJObject()
  add(formData_774236, "LoadBalancerPort", newJInt(LoadBalancerPort))
  if PolicyNames != nil:
    formData_774236.add "PolicyNames", PolicyNames
  add(query_774235, "Action", newJString(Action))
  add(formData_774236, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_774235, "Version", newJString(Version))
  result = call_774234.call(nil, query_774235, nil, formData_774236, nil)

var postSetLoadBalancerPoliciesOfListener* = Call_PostSetLoadBalancerPoliciesOfListener_774218(
    name: "postSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_PostSetLoadBalancerPoliciesOfListener_774219, base: "/",
    url: url_PostSetLoadBalancerPoliciesOfListener_774220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesOfListener_774200 = ref object of OpenApiRestCall_772597
proc url_GetSetLoadBalancerPoliciesOfListener_774202(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetLoadBalancerPoliciesOfListener_774201(path: JsonNode;
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
  var valid_774203 = query.getOrDefault("LoadBalancerName")
  valid_774203 = validateParameter(valid_774203, JString, required = true,
                                 default = nil)
  if valid_774203 != nil:
    section.add "LoadBalancerName", valid_774203
  var valid_774204 = query.getOrDefault("LoadBalancerPort")
  valid_774204 = validateParameter(valid_774204, JInt, required = true, default = nil)
  if valid_774204 != nil:
    section.add "LoadBalancerPort", valid_774204
  var valid_774205 = query.getOrDefault("Action")
  valid_774205 = validateParameter(valid_774205, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_774205 != nil:
    section.add "Action", valid_774205
  var valid_774206 = query.getOrDefault("PolicyNames")
  valid_774206 = validateParameter(valid_774206, JArray, required = true, default = nil)
  if valid_774206 != nil:
    section.add "PolicyNames", valid_774206
  var valid_774207 = query.getOrDefault("Version")
  valid_774207 = validateParameter(valid_774207, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_774207 != nil:
    section.add "Version", valid_774207
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
  var valid_774208 = header.getOrDefault("X-Amz-Date")
  valid_774208 = validateParameter(valid_774208, JString, required = false,
                                 default = nil)
  if valid_774208 != nil:
    section.add "X-Amz-Date", valid_774208
  var valid_774209 = header.getOrDefault("X-Amz-Security-Token")
  valid_774209 = validateParameter(valid_774209, JString, required = false,
                                 default = nil)
  if valid_774209 != nil:
    section.add "X-Amz-Security-Token", valid_774209
  var valid_774210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774210 = validateParameter(valid_774210, JString, required = false,
                                 default = nil)
  if valid_774210 != nil:
    section.add "X-Amz-Content-Sha256", valid_774210
  var valid_774211 = header.getOrDefault("X-Amz-Algorithm")
  valid_774211 = validateParameter(valid_774211, JString, required = false,
                                 default = nil)
  if valid_774211 != nil:
    section.add "X-Amz-Algorithm", valid_774211
  var valid_774212 = header.getOrDefault("X-Amz-Signature")
  valid_774212 = validateParameter(valid_774212, JString, required = false,
                                 default = nil)
  if valid_774212 != nil:
    section.add "X-Amz-Signature", valid_774212
  var valid_774213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774213 = validateParameter(valid_774213, JString, required = false,
                                 default = nil)
  if valid_774213 != nil:
    section.add "X-Amz-SignedHeaders", valid_774213
  var valid_774214 = header.getOrDefault("X-Amz-Credential")
  valid_774214 = validateParameter(valid_774214, JString, required = false,
                                 default = nil)
  if valid_774214 != nil:
    section.add "X-Amz-Credential", valid_774214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774215: Call_GetSetLoadBalancerPoliciesOfListener_774200;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_774215.validator(path, query, header, formData, body)
  let scheme = call_774215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774215.url(scheme.get, call_774215.host, call_774215.base,
                         call_774215.route, valid.getOrDefault("path"))
  result = hook(call_774215, url, valid)

proc call*(call_774216: Call_GetSetLoadBalancerPoliciesOfListener_774200;
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
  var query_774217 = newJObject()
  add(query_774217, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_774217, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_774217, "Action", newJString(Action))
  if PolicyNames != nil:
    query_774217.add "PolicyNames", PolicyNames
  add(query_774217, "Version", newJString(Version))
  result = call_774216.call(nil, query_774217, nil, nil, nil)

var getSetLoadBalancerPoliciesOfListener* = Call_GetSetLoadBalancerPoliciesOfListener_774200(
    name: "getSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_GetSetLoadBalancerPoliciesOfListener_774201, base: "/",
    url: url_GetSetLoadBalancerPoliciesOfListener_774202,
    schemes: {Scheme.Https, Scheme.Http})
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
