
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
  Call_PostAddTags_603075 = ref object of OpenApiRestCall_602466
proc url_PostAddTags_603077(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTags_603076(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603078 = query.getOrDefault("Action")
  valid_603078 = validateParameter(valid_603078, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_603078 != nil:
    section.add "Action", valid_603078
  var valid_603079 = query.getOrDefault("Version")
  valid_603079 = validateParameter(valid_603079, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603079 != nil:
    section.add "Version", valid_603079
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603080 = header.getOrDefault("X-Amz-Date")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Date", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Security-Token")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Security-Token", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Content-Sha256", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Algorithm")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Algorithm", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Signature")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Signature", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-SignedHeaders", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Credential")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Credential", valid_603086
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify one load balancer only.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_603087 = formData.getOrDefault("Tags")
  valid_603087 = validateParameter(valid_603087, JArray, required = true, default = nil)
  if valid_603087 != nil:
    section.add "Tags", valid_603087
  var valid_603088 = formData.getOrDefault("LoadBalancerNames")
  valid_603088 = validateParameter(valid_603088, JArray, required = true, default = nil)
  if valid_603088 != nil:
    section.add "LoadBalancerNames", valid_603088
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603089: Call_PostAddTags_603075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603089.validator(path, query, header, formData, body)
  let scheme = call_603089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603089.url(scheme.get, call_603089.host, call_603089.base,
                         call_603089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603089, url, valid)

proc call*(call_603090: Call_PostAddTags_603075; Tags: JsonNode;
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
  var query_603091 = newJObject()
  var formData_603092 = newJObject()
  if Tags != nil:
    formData_603092.add "Tags", Tags
  add(query_603091, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_603092.add "LoadBalancerNames", LoadBalancerNames
  add(query_603091, "Version", newJString(Version))
  result = call_603090.call(nil, query_603091, nil, formData_603092, nil)

var postAddTags* = Call_PostAddTags_603075(name: "postAddTags",
                                        meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
                                        route: "/#Action=AddTags",
                                        validator: validate_PostAddTags_603076,
                                        base: "/", url: url_PostAddTags_603077,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTags_602803 = ref object of OpenApiRestCall_602466
proc url_GetAddTags_602805(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTags_602804(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602917 = query.getOrDefault("Tags")
  valid_602917 = validateParameter(valid_602917, JArray, required = true, default = nil)
  if valid_602917 != nil:
    section.add "Tags", valid_602917
  var valid_602931 = query.getOrDefault("Action")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = newJString("AddTags"))
  if valid_602931 != nil:
    section.add "Action", valid_602931
  var valid_602932 = query.getOrDefault("LoadBalancerNames")
  valid_602932 = validateParameter(valid_602932, JArray, required = true, default = nil)
  if valid_602932 != nil:
    section.add "LoadBalancerNames", valid_602932
  var valid_602933 = query.getOrDefault("Version")
  valid_602933 = validateParameter(valid_602933, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_602933 != nil:
    section.add "Version", valid_602933
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602934 = header.getOrDefault("X-Amz-Date")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Date", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Security-Token")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Security-Token", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Content-Sha256", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Algorithm")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Algorithm", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Signature")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Signature", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-SignedHeaders", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Credential")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Credential", valid_602940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602963: Call_GetAddTags_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified load balancer. Each load balancer can have a maximum of 10 tags.</p> <p>Each tag consists of a key and an optional value. If a tag with the same key is already associated with the load balancer, <code>AddTags</code> updates its value.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/add-remove-tags.html">Tag Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_602963.validator(path, query, header, formData, body)
  let scheme = call_602963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602963.url(scheme.get, call_602963.host, call_602963.base,
                         call_602963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602963, url, valid)

proc call*(call_603034: Call_GetAddTags_602803; Tags: JsonNode;
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
  var query_603035 = newJObject()
  if Tags != nil:
    query_603035.add "Tags", Tags
  add(query_603035, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_603035.add "LoadBalancerNames", LoadBalancerNames
  add(query_603035, "Version", newJString(Version))
  result = call_603034.call(nil, query_603035, nil, nil, nil)

var getAddTags* = Call_GetAddTags_602803(name: "getAddTags",
                                      meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
                                      route: "/#Action=AddTags",
                                      validator: validate_GetAddTags_602804,
                                      base: "/", url: url_GetAddTags_602805,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplySecurityGroupsToLoadBalancer_603110 = ref object of OpenApiRestCall_602466
proc url_PostApplySecurityGroupsToLoadBalancer_603112(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostApplySecurityGroupsToLoadBalancer_603111(path: JsonNode;
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
  var valid_603113 = query.getOrDefault("Action")
  valid_603113 = validateParameter(valid_603113, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_603113 != nil:
    section.add "Action", valid_603113
  var valid_603114 = query.getOrDefault("Version")
  valid_603114 = validateParameter(valid_603114, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603114 != nil:
    section.add "Version", valid_603114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603115 = header.getOrDefault("X-Amz-Date")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Date", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Security-Token")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Security-Token", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Content-Sha256", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Algorithm")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Algorithm", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Signature")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Signature", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-SignedHeaders", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Credential")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Credential", valid_603121
  result.add "header", section
  ## parameters in `formData` object:
  ##   SecurityGroups: JArray (required)
  ##                 : The IDs of the security groups to associate with the load balancer. Note that you cannot specify the name of the security group.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SecurityGroups` field"
  var valid_603122 = formData.getOrDefault("SecurityGroups")
  valid_603122 = validateParameter(valid_603122, JArray, required = true, default = nil)
  if valid_603122 != nil:
    section.add "SecurityGroups", valid_603122
  var valid_603123 = formData.getOrDefault("LoadBalancerName")
  valid_603123 = validateParameter(valid_603123, JString, required = true,
                                 default = nil)
  if valid_603123 != nil:
    section.add "LoadBalancerName", valid_603123
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603124: Call_PostApplySecurityGroupsToLoadBalancer_603110;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603124.validator(path, query, header, formData, body)
  let scheme = call_603124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603124.url(scheme.get, call_603124.host, call_603124.base,
                         call_603124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603124, url, valid)

proc call*(call_603125: Call_PostApplySecurityGroupsToLoadBalancer_603110;
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
  var query_603126 = newJObject()
  var formData_603127 = newJObject()
  add(query_603126, "Action", newJString(Action))
  if SecurityGroups != nil:
    formData_603127.add "SecurityGroups", SecurityGroups
  add(formData_603127, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603126, "Version", newJString(Version))
  result = call_603125.call(nil, query_603126, nil, formData_603127, nil)

var postApplySecurityGroupsToLoadBalancer* = Call_PostApplySecurityGroupsToLoadBalancer_603110(
    name: "postApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_PostApplySecurityGroupsToLoadBalancer_603111, base: "/",
    url: url_PostApplySecurityGroupsToLoadBalancer_603112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplySecurityGroupsToLoadBalancer_603093 = ref object of OpenApiRestCall_602466
proc url_GetApplySecurityGroupsToLoadBalancer_603095(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApplySecurityGroupsToLoadBalancer_603094(path: JsonNode;
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
  var valid_603096 = query.getOrDefault("LoadBalancerName")
  valid_603096 = validateParameter(valid_603096, JString, required = true,
                                 default = nil)
  if valid_603096 != nil:
    section.add "LoadBalancerName", valid_603096
  var valid_603097 = query.getOrDefault("Action")
  valid_603097 = validateParameter(valid_603097, JString, required = true, default = newJString(
      "ApplySecurityGroupsToLoadBalancer"))
  if valid_603097 != nil:
    section.add "Action", valid_603097
  var valid_603098 = query.getOrDefault("Version")
  valid_603098 = validateParameter(valid_603098, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603098 != nil:
    section.add "Version", valid_603098
  var valid_603099 = query.getOrDefault("SecurityGroups")
  valid_603099 = validateParameter(valid_603099, JArray, required = true, default = nil)
  if valid_603099 != nil:
    section.add "SecurityGroups", valid_603099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603100 = header.getOrDefault("X-Amz-Date")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Date", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Security-Token")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Security-Token", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Content-Sha256", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Algorithm")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Algorithm", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Signature")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Signature", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-SignedHeaders", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Credential")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Credential", valid_603106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603107: Call_GetApplySecurityGroupsToLoadBalancer_603093;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Associates one or more security groups with your load balancer in a virtual private cloud (VPC). The specified security groups override the previously associated security groups.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-groups.html#elb-vpc-security-groups">Security Groups for Load Balancers in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603107.validator(path, query, header, formData, body)
  let scheme = call_603107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603107.url(scheme.get, call_603107.host, call_603107.base,
                         call_603107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603107, url, valid)

proc call*(call_603108: Call_GetApplySecurityGroupsToLoadBalancer_603093;
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
  var query_603109 = newJObject()
  add(query_603109, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603109, "Action", newJString(Action))
  add(query_603109, "Version", newJString(Version))
  if SecurityGroups != nil:
    query_603109.add "SecurityGroups", SecurityGroups
  result = call_603108.call(nil, query_603109, nil, nil, nil)

var getApplySecurityGroupsToLoadBalancer* = Call_GetApplySecurityGroupsToLoadBalancer_603093(
    name: "getApplySecurityGroupsToLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ApplySecurityGroupsToLoadBalancer",
    validator: validate_GetApplySecurityGroupsToLoadBalancer_603094, base: "/",
    url: url_GetApplySecurityGroupsToLoadBalancer_603095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAttachLoadBalancerToSubnets_603145 = ref object of OpenApiRestCall_602466
proc url_PostAttachLoadBalancerToSubnets_603147(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAttachLoadBalancerToSubnets_603146(path: JsonNode;
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
  var valid_603148 = query.getOrDefault("Action")
  valid_603148 = validateParameter(valid_603148, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_603148 != nil:
    section.add "Action", valid_603148
  var valid_603149 = query.getOrDefault("Version")
  valid_603149 = validateParameter(valid_603149, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603149 != nil:
    section.add "Version", valid_603149
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Content-Sha256", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Algorithm")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Algorithm", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Signature")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Signature", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-SignedHeaders", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Credential")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Credential", valid_603156
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets to add. You can add only one subnet per Availability Zone.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_603157 = formData.getOrDefault("Subnets")
  valid_603157 = validateParameter(valid_603157, JArray, required = true, default = nil)
  if valid_603157 != nil:
    section.add "Subnets", valid_603157
  var valid_603158 = formData.getOrDefault("LoadBalancerName")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "LoadBalancerName", valid_603158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_PostAttachLoadBalancerToSubnets_603145;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_PostAttachLoadBalancerToSubnets_603145;
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
  var query_603161 = newJObject()
  var formData_603162 = newJObject()
  add(query_603161, "Action", newJString(Action))
  if Subnets != nil:
    formData_603162.add "Subnets", Subnets
  add(formData_603162, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603161, "Version", newJString(Version))
  result = call_603160.call(nil, query_603161, nil, formData_603162, nil)

var postAttachLoadBalancerToSubnets* = Call_PostAttachLoadBalancerToSubnets_603145(
    name: "postAttachLoadBalancerToSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_PostAttachLoadBalancerToSubnets_603146, base: "/",
    url: url_PostAttachLoadBalancerToSubnets_603147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttachLoadBalancerToSubnets_603128 = ref object of OpenApiRestCall_602466
proc url_GetAttachLoadBalancerToSubnets_603130(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAttachLoadBalancerToSubnets_603129(path: JsonNode;
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
  var valid_603131 = query.getOrDefault("LoadBalancerName")
  valid_603131 = validateParameter(valid_603131, JString, required = true,
                                 default = nil)
  if valid_603131 != nil:
    section.add "LoadBalancerName", valid_603131
  var valid_603132 = query.getOrDefault("Action")
  valid_603132 = validateParameter(valid_603132, JString, required = true, default = newJString(
      "AttachLoadBalancerToSubnets"))
  if valid_603132 != nil:
    section.add "Action", valid_603132
  var valid_603133 = query.getOrDefault("Subnets")
  valid_603133 = validateParameter(valid_603133, JArray, required = true, default = nil)
  if valid_603133 != nil:
    section.add "Subnets", valid_603133
  var valid_603134 = query.getOrDefault("Version")
  valid_603134 = validateParameter(valid_603134, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603134 != nil:
    section.add "Version", valid_603134
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Content-Sha256", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Algorithm")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Algorithm", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Signature")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Signature", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-SignedHeaders", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Credential")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Credential", valid_603141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603142: Call_GetAttachLoadBalancerToSubnets_603128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more subnets to the set of configured subnets for the specified load balancer.</p> <p>The load balancer evenly distributes requests across all registered subnets. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-manage-subnets.html">Add or Remove Subnets for Your Load Balancer in a VPC</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603142.validator(path, query, header, formData, body)
  let scheme = call_603142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603142.url(scheme.get, call_603142.host, call_603142.base,
                         call_603142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603142, url, valid)

proc call*(call_603143: Call_GetAttachLoadBalancerToSubnets_603128;
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
  var query_603144 = newJObject()
  add(query_603144, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603144, "Action", newJString(Action))
  if Subnets != nil:
    query_603144.add "Subnets", Subnets
  add(query_603144, "Version", newJString(Version))
  result = call_603143.call(nil, query_603144, nil, nil, nil)

var getAttachLoadBalancerToSubnets* = Call_GetAttachLoadBalancerToSubnets_603128(
    name: "getAttachLoadBalancerToSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=AttachLoadBalancerToSubnets",
    validator: validate_GetAttachLoadBalancerToSubnets_603129, base: "/",
    url: url_GetAttachLoadBalancerToSubnets_603130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfigureHealthCheck_603184 = ref object of OpenApiRestCall_602466
proc url_PostConfigureHealthCheck_603186(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostConfigureHealthCheck_603185(path: JsonNode; query: JsonNode;
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
  var valid_603187 = query.getOrDefault("Action")
  valid_603187 = validateParameter(valid_603187, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_603187 != nil:
    section.add "Action", valid_603187
  var valid_603188 = query.getOrDefault("Version")
  valid_603188 = validateParameter(valid_603188, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603188 != nil:
    section.add "Version", valid_603188
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603189 = header.getOrDefault("X-Amz-Date")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Date", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Security-Token")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Security-Token", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Content-Sha256", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Algorithm")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Algorithm", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Signature")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Signature", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-SignedHeaders", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Credential")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Credential", valid_603195
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
  var valid_603196 = formData.getOrDefault("HealthCheck.HealthyThreshold")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_603196
  var valid_603197 = formData.getOrDefault("HealthCheck.Interval")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "HealthCheck.Interval", valid_603197
  var valid_603198 = formData.getOrDefault("HealthCheck.Timeout")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "HealthCheck.Timeout", valid_603198
  var valid_603199 = formData.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_603199
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_603200 = formData.getOrDefault("LoadBalancerName")
  valid_603200 = validateParameter(valid_603200, JString, required = true,
                                 default = nil)
  if valid_603200 != nil:
    section.add "LoadBalancerName", valid_603200
  var valid_603201 = formData.getOrDefault("HealthCheck.Target")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "HealthCheck.Target", valid_603201
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603202: Call_PostConfigureHealthCheck_603184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603202.validator(path, query, header, formData, body)
  let scheme = call_603202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603202.url(scheme.get, call_603202.host, call_603202.base,
                         call_603202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603202, url, valid)

proc call*(call_603203: Call_PostConfigureHealthCheck_603184;
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
  var query_603204 = newJObject()
  var formData_603205 = newJObject()
  add(formData_603205, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(formData_603205, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(formData_603205, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_603204, "Action", newJString(Action))
  add(formData_603205, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(formData_603205, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_603205, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_603204, "Version", newJString(Version))
  result = call_603203.call(nil, query_603204, nil, formData_603205, nil)

var postConfigureHealthCheck* = Call_PostConfigureHealthCheck_603184(
    name: "postConfigureHealthCheck", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_PostConfigureHealthCheck_603185, base: "/",
    url: url_PostConfigureHealthCheck_603186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigureHealthCheck_603163 = ref object of OpenApiRestCall_602466
proc url_GetConfigureHealthCheck_603165(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConfigureHealthCheck_603164(path: JsonNode; query: JsonNode;
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
  var valid_603166 = query.getOrDefault("HealthCheck.HealthyThreshold")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "HealthCheck.HealthyThreshold", valid_603166
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_603167 = query.getOrDefault("LoadBalancerName")
  valid_603167 = validateParameter(valid_603167, JString, required = true,
                                 default = nil)
  if valid_603167 != nil:
    section.add "LoadBalancerName", valid_603167
  var valid_603168 = query.getOrDefault("HealthCheck.UnhealthyThreshold")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "HealthCheck.UnhealthyThreshold", valid_603168
  var valid_603169 = query.getOrDefault("HealthCheck.Timeout")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "HealthCheck.Timeout", valid_603169
  var valid_603170 = query.getOrDefault("HealthCheck.Target")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "HealthCheck.Target", valid_603170
  var valid_603171 = query.getOrDefault("Action")
  valid_603171 = validateParameter(valid_603171, JString, required = true,
                                 default = newJString("ConfigureHealthCheck"))
  if valid_603171 != nil:
    section.add "Action", valid_603171
  var valid_603172 = query.getOrDefault("HealthCheck.Interval")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "HealthCheck.Interval", valid_603172
  var valid_603173 = query.getOrDefault("Version")
  valid_603173 = validateParameter(valid_603173, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603173 != nil:
    section.add "Version", valid_603173
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603174 = header.getOrDefault("X-Amz-Date")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Date", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Security-Token")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Security-Token", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Content-Sha256", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Algorithm")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Algorithm", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Signature")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Signature", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-SignedHeaders", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Credential")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Credential", valid_603180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603181: Call_GetConfigureHealthCheck_603163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Specifies the health check settings to use when evaluating the health state of your EC2 instances.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-healthchecks.html">Configure Health Checks for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603181.validator(path, query, header, formData, body)
  let scheme = call_603181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603181.url(scheme.get, call_603181.host, call_603181.base,
                         call_603181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603181, url, valid)

proc call*(call_603182: Call_GetConfigureHealthCheck_603163;
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
  var query_603183 = newJObject()
  add(query_603183, "HealthCheck.HealthyThreshold",
      newJString(HealthCheckHealthyThreshold))
  add(query_603183, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603183, "HealthCheck.UnhealthyThreshold",
      newJString(HealthCheckUnhealthyThreshold))
  add(query_603183, "HealthCheck.Timeout", newJString(HealthCheckTimeout))
  add(query_603183, "HealthCheck.Target", newJString(HealthCheckTarget))
  add(query_603183, "Action", newJString(Action))
  add(query_603183, "HealthCheck.Interval", newJString(HealthCheckInterval))
  add(query_603183, "Version", newJString(Version))
  result = call_603182.call(nil, query_603183, nil, nil, nil)

var getConfigureHealthCheck* = Call_GetConfigureHealthCheck_603163(
    name: "getConfigureHealthCheck", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ConfigureHealthCheck",
    validator: validate_GetConfigureHealthCheck_603164, base: "/",
    url: url_GetConfigureHealthCheck_603165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateAppCookieStickinessPolicy_603224 = ref object of OpenApiRestCall_602466
proc url_PostCreateAppCookieStickinessPolicy_603226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateAppCookieStickinessPolicy_603225(path: JsonNode;
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
  var valid_603227 = query.getOrDefault("Action")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_603227 != nil:
    section.add "Action", valid_603227
  var valid_603228 = query.getOrDefault("Version")
  valid_603228 = validateParameter(valid_603228, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603228 != nil:
    section.add "Version", valid_603228
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603229 = header.getOrDefault("X-Amz-Date")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Date", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Security-Token")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Security-Token", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Content-Sha256", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Algorithm")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Algorithm", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Signature")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Signature", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-SignedHeaders", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Credential")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Credential", valid_603235
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
  var valid_603236 = formData.getOrDefault("PolicyName")
  valid_603236 = validateParameter(valid_603236, JString, required = true,
                                 default = nil)
  if valid_603236 != nil:
    section.add "PolicyName", valid_603236
  var valid_603237 = formData.getOrDefault("CookieName")
  valid_603237 = validateParameter(valid_603237, JString, required = true,
                                 default = nil)
  if valid_603237 != nil:
    section.add "CookieName", valid_603237
  var valid_603238 = formData.getOrDefault("LoadBalancerName")
  valid_603238 = validateParameter(valid_603238, JString, required = true,
                                 default = nil)
  if valid_603238 != nil:
    section.add "LoadBalancerName", valid_603238
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603239: Call_PostCreateAppCookieStickinessPolicy_603224;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603239.validator(path, query, header, formData, body)
  let scheme = call_603239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603239.url(scheme.get, call_603239.host, call_603239.base,
                         call_603239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603239, url, valid)

proc call*(call_603240: Call_PostCreateAppCookieStickinessPolicy_603224;
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
  var query_603241 = newJObject()
  var formData_603242 = newJObject()
  add(formData_603242, "PolicyName", newJString(PolicyName))
  add(formData_603242, "CookieName", newJString(CookieName))
  add(query_603241, "Action", newJString(Action))
  add(formData_603242, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603241, "Version", newJString(Version))
  result = call_603240.call(nil, query_603241, nil, formData_603242, nil)

var postCreateAppCookieStickinessPolicy* = Call_PostCreateAppCookieStickinessPolicy_603224(
    name: "postCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_PostCreateAppCookieStickinessPolicy_603225, base: "/",
    url: url_PostCreateAppCookieStickinessPolicy_603226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateAppCookieStickinessPolicy_603206 = ref object of OpenApiRestCall_602466
proc url_GetCreateAppCookieStickinessPolicy_603208(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateAppCookieStickinessPolicy_603207(path: JsonNode;
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
  var valid_603209 = query.getOrDefault("LoadBalancerName")
  valid_603209 = validateParameter(valid_603209, JString, required = true,
                                 default = nil)
  if valid_603209 != nil:
    section.add "LoadBalancerName", valid_603209
  var valid_603210 = query.getOrDefault("Action")
  valid_603210 = validateParameter(valid_603210, JString, required = true, default = newJString(
      "CreateAppCookieStickinessPolicy"))
  if valid_603210 != nil:
    section.add "Action", valid_603210
  var valid_603211 = query.getOrDefault("CookieName")
  valid_603211 = validateParameter(valid_603211, JString, required = true,
                                 default = nil)
  if valid_603211 != nil:
    section.add "CookieName", valid_603211
  var valid_603212 = query.getOrDefault("Version")
  valid_603212 = validateParameter(valid_603212, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603212 != nil:
    section.add "Version", valid_603212
  var valid_603213 = query.getOrDefault("PolicyName")
  valid_603213 = validateParameter(valid_603213, JString, required = true,
                                 default = nil)
  if valid_603213 != nil:
    section.add "PolicyName", valid_603213
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603214 = header.getOrDefault("X-Amz-Date")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Date", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Security-Token")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Security-Token", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Content-Sha256", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Algorithm")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Algorithm", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Signature")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Signature", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-SignedHeaders", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Credential")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Credential", valid_603220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603221: Call_GetCreateAppCookieStickinessPolicy_603206;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes that follow that of an application-generated cookie. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>This policy is similar to the policy created by <a>CreateLBCookieStickinessPolicy</a>, except that the lifetime of the special Elastic Load Balancing cookie, <code>AWSELB</code>, follows the lifetime of the application-generated cookie specified in the policy configuration. The load balancer only inserts a new stickiness cookie when the application response includes a new application cookie.</p> <p>If the application cookie is explicitly removed or expires, the session stops being sticky until a new application cookie is issued.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603221.validator(path, query, header, formData, body)
  let scheme = call_603221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603221.url(scheme.get, call_603221.host, call_603221.base,
                         call_603221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603221, url, valid)

proc call*(call_603222: Call_GetCreateAppCookieStickinessPolicy_603206;
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
  var query_603223 = newJObject()
  add(query_603223, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603223, "Action", newJString(Action))
  add(query_603223, "CookieName", newJString(CookieName))
  add(query_603223, "Version", newJString(Version))
  add(query_603223, "PolicyName", newJString(PolicyName))
  result = call_603222.call(nil, query_603223, nil, nil, nil)

var getCreateAppCookieStickinessPolicy* = Call_GetCreateAppCookieStickinessPolicy_603206(
    name: "getCreateAppCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateAppCookieStickinessPolicy",
    validator: validate_GetCreateAppCookieStickinessPolicy_603207, base: "/",
    url: url_GetCreateAppCookieStickinessPolicy_603208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLBCookieStickinessPolicy_603261 = ref object of OpenApiRestCall_602466
proc url_PostCreateLBCookieStickinessPolicy_603263(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLBCookieStickinessPolicy_603262(path: JsonNode;
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
  var valid_603264 = query.getOrDefault("Action")
  valid_603264 = validateParameter(valid_603264, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_603264 != nil:
    section.add "Action", valid_603264
  var valid_603265 = query.getOrDefault("Version")
  valid_603265 = validateParameter(valid_603265, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603265 != nil:
    section.add "Version", valid_603265
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603266 = header.getOrDefault("X-Amz-Date")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Date", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Security-Token")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Security-Token", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Content-Sha256", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Algorithm")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Algorithm", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Signature")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Signature", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-SignedHeaders", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Credential")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Credential", valid_603272
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
  var valid_603273 = formData.getOrDefault("PolicyName")
  valid_603273 = validateParameter(valid_603273, JString, required = true,
                                 default = nil)
  if valid_603273 != nil:
    section.add "PolicyName", valid_603273
  var valid_603274 = formData.getOrDefault("LoadBalancerName")
  valid_603274 = validateParameter(valid_603274, JString, required = true,
                                 default = nil)
  if valid_603274 != nil:
    section.add "LoadBalancerName", valid_603274
  var valid_603275 = formData.getOrDefault("CookieExpirationPeriod")
  valid_603275 = validateParameter(valid_603275, JInt, required = false, default = nil)
  if valid_603275 != nil:
    section.add "CookieExpirationPeriod", valid_603275
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603276: Call_PostCreateLBCookieStickinessPolicy_603261;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603276.validator(path, query, header, formData, body)
  let scheme = call_603276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603276.url(scheme.get, call_603276.host, call_603276.base,
                         call_603276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603276, url, valid)

proc call*(call_603277: Call_PostCreateLBCookieStickinessPolicy_603261;
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
  var query_603278 = newJObject()
  var formData_603279 = newJObject()
  add(formData_603279, "PolicyName", newJString(PolicyName))
  add(query_603278, "Action", newJString(Action))
  add(formData_603279, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603278, "Version", newJString(Version))
  add(formData_603279, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  result = call_603277.call(nil, query_603278, nil, formData_603279, nil)

var postCreateLBCookieStickinessPolicy* = Call_PostCreateLBCookieStickinessPolicy_603261(
    name: "postCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_PostCreateLBCookieStickinessPolicy_603262, base: "/",
    url: url_PostCreateLBCookieStickinessPolicy_603263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLBCookieStickinessPolicy_603243 = ref object of OpenApiRestCall_602466
proc url_GetCreateLBCookieStickinessPolicy_603245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLBCookieStickinessPolicy_603244(path: JsonNode;
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
  var valid_603246 = query.getOrDefault("CookieExpirationPeriod")
  valid_603246 = validateParameter(valid_603246, JInt, required = false, default = nil)
  if valid_603246 != nil:
    section.add "CookieExpirationPeriod", valid_603246
  assert query != nil,
        "query argument is necessary due to required `LoadBalancerName` field"
  var valid_603247 = query.getOrDefault("LoadBalancerName")
  valid_603247 = validateParameter(valid_603247, JString, required = true,
                                 default = nil)
  if valid_603247 != nil:
    section.add "LoadBalancerName", valid_603247
  var valid_603248 = query.getOrDefault("Action")
  valid_603248 = validateParameter(valid_603248, JString, required = true, default = newJString(
      "CreateLBCookieStickinessPolicy"))
  if valid_603248 != nil:
    section.add "Action", valid_603248
  var valid_603249 = query.getOrDefault("Version")
  valid_603249 = validateParameter(valid_603249, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603249 != nil:
    section.add "Version", valid_603249
  var valid_603250 = query.getOrDefault("PolicyName")
  valid_603250 = validateParameter(valid_603250, JString, required = true,
                                 default = nil)
  if valid_603250 != nil:
    section.add "PolicyName", valid_603250
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603251 = header.getOrDefault("X-Amz-Date")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Date", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Security-Token")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Security-Token", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Content-Sha256", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Algorithm")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Algorithm", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Signature")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Signature", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-SignedHeaders", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Credential")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Credential", valid_603257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603258: Call_GetCreateLBCookieStickinessPolicy_603243;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Generates a stickiness policy with sticky session lifetimes controlled by the lifetime of the browser (user-agent) or a specified expiration period. This policy can be associated only with HTTP/HTTPS listeners.</p> <p>When a load balancer implements this policy, the load balancer uses a special cookie to track the instance for each request. When the load balancer receives a request, it first checks to see if this cookie is present in the request. If so, the load balancer sends the request to the application server specified in the cookie. If not, the load balancer sends the request to a server that is chosen based on the existing load-balancing algorithm.</p> <p>A cookie is inserted into the response for binding subsequent requests from the same user to that server. The validity of the cookie is based on the cookie expiration time, which is specified in the policy configuration.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603258.validator(path, query, header, formData, body)
  let scheme = call_603258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603258.url(scheme.get, call_603258.host, call_603258.base,
                         call_603258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603258, url, valid)

proc call*(call_603259: Call_GetCreateLBCookieStickinessPolicy_603243;
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
  var query_603260 = newJObject()
  add(query_603260, "CookieExpirationPeriod", newJInt(CookieExpirationPeriod))
  add(query_603260, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603260, "Action", newJString(Action))
  add(query_603260, "Version", newJString(Version))
  add(query_603260, "PolicyName", newJString(PolicyName))
  result = call_603259.call(nil, query_603260, nil, nil, nil)

var getCreateLBCookieStickinessPolicy* = Call_GetCreateLBCookieStickinessPolicy_603243(
    name: "getCreateLBCookieStickinessPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLBCookieStickinessPolicy",
    validator: validate_GetCreateLBCookieStickinessPolicy_603244, base: "/",
    url: url_GetCreateLBCookieStickinessPolicy_603245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancer_603302 = ref object of OpenApiRestCall_602466
proc url_PostCreateLoadBalancer_603304(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLoadBalancer_603303(path: JsonNode; query: JsonNode;
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
  var valid_603305 = query.getOrDefault("Action")
  valid_603305 = validateParameter(valid_603305, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_603305 != nil:
    section.add "Action", valid_603305
  var valid_603306 = query.getOrDefault("Version")
  valid_603306 = validateParameter(valid_603306, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603306 != nil:
    section.add "Version", valid_603306
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603307 = header.getOrDefault("X-Amz-Date")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Date", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Security-Token")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Security-Token", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Content-Sha256", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Algorithm")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Algorithm", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Signature")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Signature", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-SignedHeaders", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Credential")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Credential", valid_603313
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
  var valid_603314 = formData.getOrDefault("Tags")
  valid_603314 = validateParameter(valid_603314, JArray, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "Tags", valid_603314
  var valid_603315 = formData.getOrDefault("AvailabilityZones")
  valid_603315 = validateParameter(valid_603315, JArray, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "AvailabilityZones", valid_603315
  var valid_603316 = formData.getOrDefault("Subnets")
  valid_603316 = validateParameter(valid_603316, JArray, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "Subnets", valid_603316
  var valid_603317 = formData.getOrDefault("SecurityGroups")
  valid_603317 = validateParameter(valid_603317, JArray, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "SecurityGroups", valid_603317
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_603318 = formData.getOrDefault("LoadBalancerName")
  valid_603318 = validateParameter(valid_603318, JString, required = true,
                                 default = nil)
  if valid_603318 != nil:
    section.add "LoadBalancerName", valid_603318
  var valid_603319 = formData.getOrDefault("Scheme")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "Scheme", valid_603319
  var valid_603320 = formData.getOrDefault("Listeners")
  valid_603320 = validateParameter(valid_603320, JArray, required = true, default = nil)
  if valid_603320 != nil:
    section.add "Listeners", valid_603320
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603321: Call_PostCreateLoadBalancer_603302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603321.validator(path, query, header, formData, body)
  let scheme = call_603321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603321.url(scheme.get, call_603321.host, call_603321.base,
                         call_603321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603321, url, valid)

proc call*(call_603322: Call_PostCreateLoadBalancer_603302;
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
  var query_603323 = newJObject()
  var formData_603324 = newJObject()
  if Tags != nil:
    formData_603324.add "Tags", Tags
  add(query_603323, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_603324.add "AvailabilityZones", AvailabilityZones
  if Subnets != nil:
    formData_603324.add "Subnets", Subnets
  if SecurityGroups != nil:
    formData_603324.add "SecurityGroups", SecurityGroups
  add(formData_603324, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_603324, "Scheme", newJString(Scheme))
  if Listeners != nil:
    formData_603324.add "Listeners", Listeners
  add(query_603323, "Version", newJString(Version))
  result = call_603322.call(nil, query_603323, nil, formData_603324, nil)

var postCreateLoadBalancer* = Call_PostCreateLoadBalancer_603302(
    name: "postCreateLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_PostCreateLoadBalancer_603303, base: "/",
    url: url_PostCreateLoadBalancer_603304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancer_603280 = ref object of OpenApiRestCall_602466
proc url_GetCreateLoadBalancer_603282(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLoadBalancer_603281(path: JsonNode; query: JsonNode;
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
  var valid_603283 = query.getOrDefault("LoadBalancerName")
  valid_603283 = validateParameter(valid_603283, JString, required = true,
                                 default = nil)
  if valid_603283 != nil:
    section.add "LoadBalancerName", valid_603283
  var valid_603284 = query.getOrDefault("AvailabilityZones")
  valid_603284 = validateParameter(valid_603284, JArray, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "AvailabilityZones", valid_603284
  var valid_603285 = query.getOrDefault("Scheme")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "Scheme", valid_603285
  var valid_603286 = query.getOrDefault("Tags")
  valid_603286 = validateParameter(valid_603286, JArray, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "Tags", valid_603286
  var valid_603287 = query.getOrDefault("Action")
  valid_603287 = validateParameter(valid_603287, JString, required = true,
                                 default = newJString("CreateLoadBalancer"))
  if valid_603287 != nil:
    section.add "Action", valid_603287
  var valid_603288 = query.getOrDefault("Subnets")
  valid_603288 = validateParameter(valid_603288, JArray, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "Subnets", valid_603288
  var valid_603289 = query.getOrDefault("Version")
  valid_603289 = validateParameter(valid_603289, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603289 != nil:
    section.add "Version", valid_603289
  var valid_603290 = query.getOrDefault("Listeners")
  valid_603290 = validateParameter(valid_603290, JArray, required = true, default = nil)
  if valid_603290 != nil:
    section.add "Listeners", valid_603290
  var valid_603291 = query.getOrDefault("SecurityGroups")
  valid_603291 = validateParameter(valid_603291, JArray, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "SecurityGroups", valid_603291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603292 = header.getOrDefault("X-Amz-Date")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Date", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Security-Token")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Security-Token", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Content-Sha256", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Algorithm")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Algorithm", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Signature")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Signature", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-SignedHeaders", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Credential")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Credential", valid_603298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603299: Call_GetCreateLoadBalancer_603280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Classic Load Balancer.</p> <p>You can add listeners, security groups, subnets, and tags when you create your load balancer, or you can add them later using <a>CreateLoadBalancerListeners</a>, <a>ApplySecurityGroupsToLoadBalancer</a>, <a>AttachLoadBalancerToSubnets</a>, and <a>AddTags</a>.</p> <p>To describe your current load balancers, see <a>DescribeLoadBalancers</a>. When you are finished with a load balancer, you can delete it using <a>DeleteLoadBalancer</a>.</p> <p>You can create up to 20 load balancers per region per account. You can request an increase for the number of load balancers for your account. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603299.validator(path, query, header, formData, body)
  let scheme = call_603299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603299.url(scheme.get, call_603299.host, call_603299.base,
                         call_603299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603299, url, valid)

proc call*(call_603300: Call_GetCreateLoadBalancer_603280;
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
  var query_603301 = newJObject()
  add(query_603301, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_603301.add "AvailabilityZones", AvailabilityZones
  add(query_603301, "Scheme", newJString(Scheme))
  if Tags != nil:
    query_603301.add "Tags", Tags
  add(query_603301, "Action", newJString(Action))
  if Subnets != nil:
    query_603301.add "Subnets", Subnets
  add(query_603301, "Version", newJString(Version))
  if Listeners != nil:
    query_603301.add "Listeners", Listeners
  if SecurityGroups != nil:
    query_603301.add "SecurityGroups", SecurityGroups
  result = call_603300.call(nil, query_603301, nil, nil, nil)

var getCreateLoadBalancer* = Call_GetCreateLoadBalancer_603280(
    name: "getCreateLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancer",
    validator: validate_GetCreateLoadBalancer_603281, base: "/",
    url: url_GetCreateLoadBalancer_603282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerListeners_603342 = ref object of OpenApiRestCall_602466
proc url_PostCreateLoadBalancerListeners_603344(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLoadBalancerListeners_603343(path: JsonNode;
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
  var valid_603345 = query.getOrDefault("Action")
  valid_603345 = validateParameter(valid_603345, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_603345 != nil:
    section.add "Action", valid_603345
  var valid_603346 = query.getOrDefault("Version")
  valid_603346 = validateParameter(valid_603346, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603346 != nil:
    section.add "Version", valid_603346
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603347 = header.getOrDefault("X-Amz-Date")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Date", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Security-Token")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Security-Token", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Content-Sha256", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Algorithm")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Algorithm", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Signature")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Signature", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-SignedHeaders", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Credential")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Credential", valid_603353
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   Listeners: JArray (required)
  ##            : The listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_603354 = formData.getOrDefault("LoadBalancerName")
  valid_603354 = validateParameter(valid_603354, JString, required = true,
                                 default = nil)
  if valid_603354 != nil:
    section.add "LoadBalancerName", valid_603354
  var valid_603355 = formData.getOrDefault("Listeners")
  valid_603355 = validateParameter(valid_603355, JArray, required = true, default = nil)
  if valid_603355 != nil:
    section.add "Listeners", valid_603355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603356: Call_PostCreateLoadBalancerListeners_603342;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603356.validator(path, query, header, formData, body)
  let scheme = call_603356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603356.url(scheme.get, call_603356.host, call_603356.base,
                         call_603356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603356, url, valid)

proc call*(call_603357: Call_PostCreateLoadBalancerListeners_603342;
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
  var query_603358 = newJObject()
  var formData_603359 = newJObject()
  add(query_603358, "Action", newJString(Action))
  add(formData_603359, "LoadBalancerName", newJString(LoadBalancerName))
  if Listeners != nil:
    formData_603359.add "Listeners", Listeners
  add(query_603358, "Version", newJString(Version))
  result = call_603357.call(nil, query_603358, nil, formData_603359, nil)

var postCreateLoadBalancerListeners* = Call_PostCreateLoadBalancerListeners_603342(
    name: "postCreateLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_PostCreateLoadBalancerListeners_603343, base: "/",
    url: url_PostCreateLoadBalancerListeners_603344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerListeners_603325 = ref object of OpenApiRestCall_602466
proc url_GetCreateLoadBalancerListeners_603327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLoadBalancerListeners_603326(path: JsonNode;
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
  var valid_603328 = query.getOrDefault("LoadBalancerName")
  valid_603328 = validateParameter(valid_603328, JString, required = true,
                                 default = nil)
  if valid_603328 != nil:
    section.add "LoadBalancerName", valid_603328
  var valid_603329 = query.getOrDefault("Action")
  valid_603329 = validateParameter(valid_603329, JString, required = true, default = newJString(
      "CreateLoadBalancerListeners"))
  if valid_603329 != nil:
    section.add "Action", valid_603329
  var valid_603330 = query.getOrDefault("Version")
  valid_603330 = validateParameter(valid_603330, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603330 != nil:
    section.add "Version", valid_603330
  var valid_603331 = query.getOrDefault("Listeners")
  valid_603331 = validateParameter(valid_603331, JArray, required = true, default = nil)
  if valid_603331 != nil:
    section.add "Listeners", valid_603331
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603332 = header.getOrDefault("X-Amz-Date")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Date", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Security-Token")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Security-Token", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Content-Sha256", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Algorithm")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Algorithm", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Signature")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Signature", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-SignedHeaders", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Credential")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Credential", valid_603338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_GetCreateLoadBalancerListeners_603325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates one or more listeners for the specified load balancer. If a listener with the specified port does not already exist, it is created; otherwise, the properties of the new listener must match the properties of the existing listener.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-listener-config.html">Listeners for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_GetCreateLoadBalancerListeners_603325;
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
  var query_603341 = newJObject()
  add(query_603341, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603341, "Action", newJString(Action))
  add(query_603341, "Version", newJString(Version))
  if Listeners != nil:
    query_603341.add "Listeners", Listeners
  result = call_603340.call(nil, query_603341, nil, nil, nil)

var getCreateLoadBalancerListeners* = Call_GetCreateLoadBalancerListeners_603325(
    name: "getCreateLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerListeners",
    validator: validate_GetCreateLoadBalancerListeners_603326, base: "/",
    url: url_GetCreateLoadBalancerListeners_603327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateLoadBalancerPolicy_603379 = ref object of OpenApiRestCall_602466
proc url_PostCreateLoadBalancerPolicy_603381(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateLoadBalancerPolicy_603380(path: JsonNode; query: JsonNode;
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
  var valid_603382 = query.getOrDefault("Action")
  valid_603382 = validateParameter(valid_603382, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_603382 != nil:
    section.add "Action", valid_603382
  var valid_603383 = query.getOrDefault("Version")
  valid_603383 = validateParameter(valid_603383, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603383 != nil:
    section.add "Version", valid_603383
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603384 = header.getOrDefault("X-Amz-Date")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Date", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Security-Token")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Security-Token", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Content-Sha256", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-Algorithm")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Algorithm", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Signature")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Signature", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-SignedHeaders", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Credential")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Credential", valid_603390
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
  var valid_603391 = formData.getOrDefault("PolicyName")
  valid_603391 = validateParameter(valid_603391, JString, required = true,
                                 default = nil)
  if valid_603391 != nil:
    section.add "PolicyName", valid_603391
  var valid_603392 = formData.getOrDefault("PolicyTypeName")
  valid_603392 = validateParameter(valid_603392, JString, required = true,
                                 default = nil)
  if valid_603392 != nil:
    section.add "PolicyTypeName", valid_603392
  var valid_603393 = formData.getOrDefault("PolicyAttributes")
  valid_603393 = validateParameter(valid_603393, JArray, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "PolicyAttributes", valid_603393
  var valid_603394 = formData.getOrDefault("LoadBalancerName")
  valid_603394 = validateParameter(valid_603394, JString, required = true,
                                 default = nil)
  if valid_603394 != nil:
    section.add "LoadBalancerName", valid_603394
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603395: Call_PostCreateLoadBalancerPolicy_603379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_603395.validator(path, query, header, formData, body)
  let scheme = call_603395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603395.url(scheme.get, call_603395.host, call_603395.base,
                         call_603395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603395, url, valid)

proc call*(call_603396: Call_PostCreateLoadBalancerPolicy_603379;
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
  var query_603397 = newJObject()
  var formData_603398 = newJObject()
  add(formData_603398, "PolicyName", newJString(PolicyName))
  add(formData_603398, "PolicyTypeName", newJString(PolicyTypeName))
  if PolicyAttributes != nil:
    formData_603398.add "PolicyAttributes", PolicyAttributes
  add(query_603397, "Action", newJString(Action))
  add(formData_603398, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603397, "Version", newJString(Version))
  result = call_603396.call(nil, query_603397, nil, formData_603398, nil)

var postCreateLoadBalancerPolicy* = Call_PostCreateLoadBalancerPolicy_603379(
    name: "postCreateLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_PostCreateLoadBalancerPolicy_603380, base: "/",
    url: url_PostCreateLoadBalancerPolicy_603381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateLoadBalancerPolicy_603360 = ref object of OpenApiRestCall_602466
proc url_GetCreateLoadBalancerPolicy_603362(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateLoadBalancerPolicy_603361(path: JsonNode; query: JsonNode;
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
  var valid_603363 = query.getOrDefault("LoadBalancerName")
  valid_603363 = validateParameter(valid_603363, JString, required = true,
                                 default = nil)
  if valid_603363 != nil:
    section.add "LoadBalancerName", valid_603363
  var valid_603364 = query.getOrDefault("PolicyAttributes")
  valid_603364 = validateParameter(valid_603364, JArray, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "PolicyAttributes", valid_603364
  var valid_603365 = query.getOrDefault("Action")
  valid_603365 = validateParameter(valid_603365, JString, required = true, default = newJString(
      "CreateLoadBalancerPolicy"))
  if valid_603365 != nil:
    section.add "Action", valid_603365
  var valid_603366 = query.getOrDefault("PolicyTypeName")
  valid_603366 = validateParameter(valid_603366, JString, required = true,
                                 default = nil)
  if valid_603366 != nil:
    section.add "PolicyTypeName", valid_603366
  var valid_603367 = query.getOrDefault("Version")
  valid_603367 = validateParameter(valid_603367, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603367 != nil:
    section.add "Version", valid_603367
  var valid_603368 = query.getOrDefault("PolicyName")
  valid_603368 = validateParameter(valid_603368, JString, required = true,
                                 default = nil)
  if valid_603368 != nil:
    section.add "PolicyName", valid_603368
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603369 = header.getOrDefault("X-Amz-Date")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Date", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Security-Token")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Security-Token", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Content-Sha256", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Algorithm")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Algorithm", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Signature")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Signature", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-SignedHeaders", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Credential")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Credential", valid_603375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603376: Call_GetCreateLoadBalancerPolicy_603360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a policy with the specified attributes for the specified load balancer.</p> <p>Policies are settings that are saved for your load balancer and that can be applied to the listener or the application server, depending on the policy type.</p>
  ## 
  let valid = call_603376.validator(path, query, header, formData, body)
  let scheme = call_603376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603376.url(scheme.get, call_603376.host, call_603376.base,
                         call_603376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603376, url, valid)

proc call*(call_603377: Call_GetCreateLoadBalancerPolicy_603360;
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
  var query_603378 = newJObject()
  add(query_603378, "LoadBalancerName", newJString(LoadBalancerName))
  if PolicyAttributes != nil:
    query_603378.add "PolicyAttributes", PolicyAttributes
  add(query_603378, "Action", newJString(Action))
  add(query_603378, "PolicyTypeName", newJString(PolicyTypeName))
  add(query_603378, "Version", newJString(Version))
  add(query_603378, "PolicyName", newJString(PolicyName))
  result = call_603377.call(nil, query_603378, nil, nil, nil)

var getCreateLoadBalancerPolicy* = Call_GetCreateLoadBalancerPolicy_603360(
    name: "getCreateLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=CreateLoadBalancerPolicy",
    validator: validate_GetCreateLoadBalancerPolicy_603361, base: "/",
    url: url_GetCreateLoadBalancerPolicy_603362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancer_603415 = ref object of OpenApiRestCall_602466
proc url_PostDeleteLoadBalancer_603417(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteLoadBalancer_603416(path: JsonNode; query: JsonNode;
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
  var valid_603418 = query.getOrDefault("Action")
  valid_603418 = validateParameter(valid_603418, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_603418 != nil:
    section.add "Action", valid_603418
  var valid_603419 = query.getOrDefault("Version")
  valid_603419 = validateParameter(valid_603419, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603419 != nil:
    section.add "Version", valid_603419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603420 = header.getOrDefault("X-Amz-Date")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Date", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Security-Token")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Security-Token", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Content-Sha256", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Algorithm")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Algorithm", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Signature")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Signature", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-SignedHeaders", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Credential")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Credential", valid_603426
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_603427 = formData.getOrDefault("LoadBalancerName")
  valid_603427 = validateParameter(valid_603427, JString, required = true,
                                 default = nil)
  if valid_603427 != nil:
    section.add "LoadBalancerName", valid_603427
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603428: Call_PostDeleteLoadBalancer_603415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_603428.validator(path, query, header, formData, body)
  let scheme = call_603428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603428.url(scheme.get, call_603428.host, call_603428.base,
                         call_603428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603428, url, valid)

proc call*(call_603429: Call_PostDeleteLoadBalancer_603415;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## postDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_603430 = newJObject()
  var formData_603431 = newJObject()
  add(query_603430, "Action", newJString(Action))
  add(formData_603431, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603430, "Version", newJString(Version))
  result = call_603429.call(nil, query_603430, nil, formData_603431, nil)

var postDeleteLoadBalancer* = Call_PostDeleteLoadBalancer_603415(
    name: "postDeleteLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_PostDeleteLoadBalancer_603416, base: "/",
    url: url_PostDeleteLoadBalancer_603417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancer_603399 = ref object of OpenApiRestCall_602466
proc url_GetDeleteLoadBalancer_603401(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteLoadBalancer_603400(path: JsonNode; query: JsonNode;
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
  var valid_603402 = query.getOrDefault("LoadBalancerName")
  valid_603402 = validateParameter(valid_603402, JString, required = true,
                                 default = nil)
  if valid_603402 != nil:
    section.add "LoadBalancerName", valid_603402
  var valid_603403 = query.getOrDefault("Action")
  valid_603403 = validateParameter(valid_603403, JString, required = true,
                                 default = newJString("DeleteLoadBalancer"))
  if valid_603403 != nil:
    section.add "Action", valid_603403
  var valid_603404 = query.getOrDefault("Version")
  valid_603404 = validateParameter(valid_603404, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603404 != nil:
    section.add "Version", valid_603404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603405 = header.getOrDefault("X-Amz-Date")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Date", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Security-Token")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Security-Token", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Content-Sha256", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Algorithm")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Algorithm", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Signature")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Signature", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-SignedHeaders", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Credential")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Credential", valid_603411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603412: Call_GetDeleteLoadBalancer_603399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ## 
  let valid = call_603412.validator(path, query, header, formData, body)
  let scheme = call_603412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603412.url(scheme.get, call_603412.host, call_603412.base,
                         call_603412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603412, url, valid)

proc call*(call_603413: Call_GetDeleteLoadBalancer_603399;
          LoadBalancerName: string; Action: string = "DeleteLoadBalancer";
          Version: string = "2012-06-01"): Recallable =
  ## getDeleteLoadBalancer
  ## <p>Deletes the specified load balancer.</p> <p>If you are attempting to recreate a load balancer, you must reconfigure all settings. The DNS name associated with a deleted load balancer are no longer usable. The name and associated DNS record of the deleted load balancer no longer exist and traffic sent to any of its IP addresses is no longer delivered to your instances.</p> <p>If the load balancer does not exist or has already been deleted, the call to <code>DeleteLoadBalancer</code> still succeeds.</p>
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603414 = newJObject()
  add(query_603414, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603414, "Action", newJString(Action))
  add(query_603414, "Version", newJString(Version))
  result = call_603413.call(nil, query_603414, nil, nil, nil)

var getDeleteLoadBalancer* = Call_GetDeleteLoadBalancer_603399(
    name: "getDeleteLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancer",
    validator: validate_GetDeleteLoadBalancer_603400, base: "/",
    url: url_GetDeleteLoadBalancer_603401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerListeners_603449 = ref object of OpenApiRestCall_602466
proc url_PostDeleteLoadBalancerListeners_603451(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteLoadBalancerListeners_603450(path: JsonNode;
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
  var valid_603452 = query.getOrDefault("Action")
  valid_603452 = validateParameter(valid_603452, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_603452 != nil:
    section.add "Action", valid_603452
  var valid_603453 = query.getOrDefault("Version")
  valid_603453 = validateParameter(valid_603453, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603453 != nil:
    section.add "Version", valid_603453
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603454 = header.getOrDefault("X-Amz-Date")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Date", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Security-Token")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Security-Token", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Content-Sha256", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Algorithm")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Algorithm", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Signature")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Signature", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-SignedHeaders", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Credential")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Credential", valid_603460
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  ##   LoadBalancerPorts: JArray (required)
  ##                    : The client port numbers of the listeners.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_603461 = formData.getOrDefault("LoadBalancerName")
  valid_603461 = validateParameter(valid_603461, JString, required = true,
                                 default = nil)
  if valid_603461 != nil:
    section.add "LoadBalancerName", valid_603461
  var valid_603462 = formData.getOrDefault("LoadBalancerPorts")
  valid_603462 = validateParameter(valid_603462, JArray, required = true, default = nil)
  if valid_603462 != nil:
    section.add "LoadBalancerPorts", valid_603462
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603463: Call_PostDeleteLoadBalancerListeners_603449;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_603463.validator(path, query, header, formData, body)
  let scheme = call_603463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603463.url(scheme.get, call_603463.host, call_603463.base,
                         call_603463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603463, url, valid)

proc call*(call_603464: Call_PostDeleteLoadBalancerListeners_603449;
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
  var query_603465 = newJObject()
  var formData_603466 = newJObject()
  add(query_603465, "Action", newJString(Action))
  add(formData_603466, "LoadBalancerName", newJString(LoadBalancerName))
  if LoadBalancerPorts != nil:
    formData_603466.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_603465, "Version", newJString(Version))
  result = call_603464.call(nil, query_603465, nil, formData_603466, nil)

var postDeleteLoadBalancerListeners* = Call_PostDeleteLoadBalancerListeners_603449(
    name: "postDeleteLoadBalancerListeners", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_PostDeleteLoadBalancerListeners_603450, base: "/",
    url: url_PostDeleteLoadBalancerListeners_603451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerListeners_603432 = ref object of OpenApiRestCall_602466
proc url_GetDeleteLoadBalancerListeners_603434(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteLoadBalancerListeners_603433(path: JsonNode;
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
  var valid_603435 = query.getOrDefault("LoadBalancerName")
  valid_603435 = validateParameter(valid_603435, JString, required = true,
                                 default = nil)
  if valid_603435 != nil:
    section.add "LoadBalancerName", valid_603435
  var valid_603436 = query.getOrDefault("Action")
  valid_603436 = validateParameter(valid_603436, JString, required = true, default = newJString(
      "DeleteLoadBalancerListeners"))
  if valid_603436 != nil:
    section.add "Action", valid_603436
  var valid_603437 = query.getOrDefault("LoadBalancerPorts")
  valid_603437 = validateParameter(valid_603437, JArray, required = true, default = nil)
  if valid_603437 != nil:
    section.add "LoadBalancerPorts", valid_603437
  var valid_603438 = query.getOrDefault("Version")
  valid_603438 = validateParameter(valid_603438, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603438 != nil:
    section.add "Version", valid_603438
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603439 = header.getOrDefault("X-Amz-Date")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Date", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Security-Token")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Security-Token", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Content-Sha256", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Algorithm")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Algorithm", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Signature")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Signature", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-SignedHeaders", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Credential")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Credential", valid_603445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603446: Call_GetDeleteLoadBalancerListeners_603432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified listeners from the specified load balancer.
  ## 
  let valid = call_603446.validator(path, query, header, formData, body)
  let scheme = call_603446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603446.url(scheme.get, call_603446.host, call_603446.base,
                         call_603446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603446, url, valid)

proc call*(call_603447: Call_GetDeleteLoadBalancerListeners_603432;
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
  var query_603448 = newJObject()
  add(query_603448, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603448, "Action", newJString(Action))
  if LoadBalancerPorts != nil:
    query_603448.add "LoadBalancerPorts", LoadBalancerPorts
  add(query_603448, "Version", newJString(Version))
  result = call_603447.call(nil, query_603448, nil, nil, nil)

var getDeleteLoadBalancerListeners* = Call_GetDeleteLoadBalancerListeners_603432(
    name: "getDeleteLoadBalancerListeners", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerListeners",
    validator: validate_GetDeleteLoadBalancerListeners_603433, base: "/",
    url: url_GetDeleteLoadBalancerListeners_603434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteLoadBalancerPolicy_603484 = ref object of OpenApiRestCall_602466
proc url_PostDeleteLoadBalancerPolicy_603486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteLoadBalancerPolicy_603485(path: JsonNode; query: JsonNode;
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
  var valid_603487 = query.getOrDefault("Action")
  valid_603487 = validateParameter(valid_603487, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_603487 != nil:
    section.add "Action", valid_603487
  var valid_603488 = query.getOrDefault("Version")
  valid_603488 = validateParameter(valid_603488, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603488 != nil:
    section.add "Version", valid_603488
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603489 = header.getOrDefault("X-Amz-Date")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Date", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Security-Token")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Security-Token", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Content-Sha256", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Algorithm")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Algorithm", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Signature")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Signature", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-SignedHeaders", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Credential")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Credential", valid_603495
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyName: JString (required)
  ##             : The name of the policy.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PolicyName` field"
  var valid_603496 = formData.getOrDefault("PolicyName")
  valid_603496 = validateParameter(valid_603496, JString, required = true,
                                 default = nil)
  if valid_603496 != nil:
    section.add "PolicyName", valid_603496
  var valid_603497 = formData.getOrDefault("LoadBalancerName")
  valid_603497 = validateParameter(valid_603497, JString, required = true,
                                 default = nil)
  if valid_603497 != nil:
    section.add "LoadBalancerName", valid_603497
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603498: Call_PostDeleteLoadBalancerPolicy_603484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_603498.validator(path, query, header, formData, body)
  let scheme = call_603498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603498.url(scheme.get, call_603498.host, call_603498.base,
                         call_603498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603498, url, valid)

proc call*(call_603499: Call_PostDeleteLoadBalancerPolicy_603484;
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
  var query_603500 = newJObject()
  var formData_603501 = newJObject()
  add(formData_603501, "PolicyName", newJString(PolicyName))
  add(query_603500, "Action", newJString(Action))
  add(formData_603501, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603500, "Version", newJString(Version))
  result = call_603499.call(nil, query_603500, nil, formData_603501, nil)

var postDeleteLoadBalancerPolicy* = Call_PostDeleteLoadBalancerPolicy_603484(
    name: "postDeleteLoadBalancerPolicy", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_PostDeleteLoadBalancerPolicy_603485, base: "/",
    url: url_PostDeleteLoadBalancerPolicy_603486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteLoadBalancerPolicy_603467 = ref object of OpenApiRestCall_602466
proc url_GetDeleteLoadBalancerPolicy_603469(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteLoadBalancerPolicy_603468(path: JsonNode; query: JsonNode;
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
  var valid_603470 = query.getOrDefault("LoadBalancerName")
  valid_603470 = validateParameter(valid_603470, JString, required = true,
                                 default = nil)
  if valid_603470 != nil:
    section.add "LoadBalancerName", valid_603470
  var valid_603471 = query.getOrDefault("Action")
  valid_603471 = validateParameter(valid_603471, JString, required = true, default = newJString(
      "DeleteLoadBalancerPolicy"))
  if valid_603471 != nil:
    section.add "Action", valid_603471
  var valid_603472 = query.getOrDefault("Version")
  valid_603472 = validateParameter(valid_603472, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603472 != nil:
    section.add "Version", valid_603472
  var valid_603473 = query.getOrDefault("PolicyName")
  valid_603473 = validateParameter(valid_603473, JString, required = true,
                                 default = nil)
  if valid_603473 != nil:
    section.add "PolicyName", valid_603473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603474 = header.getOrDefault("X-Amz-Date")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Date", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Security-Token")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Security-Token", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Content-Sha256", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Algorithm")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Algorithm", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Signature")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Signature", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-SignedHeaders", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Credential")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Credential", valid_603480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603481: Call_GetDeleteLoadBalancerPolicy_603467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified policy from the specified load balancer. This policy must not be enabled for any listeners.
  ## 
  let valid = call_603481.validator(path, query, header, formData, body)
  let scheme = call_603481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603481.url(scheme.get, call_603481.host, call_603481.base,
                         call_603481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603481, url, valid)

proc call*(call_603482: Call_GetDeleteLoadBalancerPolicy_603467;
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
  var query_603483 = newJObject()
  add(query_603483, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603483, "Action", newJString(Action))
  add(query_603483, "Version", newJString(Version))
  add(query_603483, "PolicyName", newJString(PolicyName))
  result = call_603482.call(nil, query_603483, nil, nil, nil)

var getDeleteLoadBalancerPolicy* = Call_GetDeleteLoadBalancerPolicy_603467(
    name: "getDeleteLoadBalancerPolicy", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeleteLoadBalancerPolicy",
    validator: validate_GetDeleteLoadBalancerPolicy_603468, base: "/",
    url: url_GetDeleteLoadBalancerPolicy_603469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeregisterInstancesFromLoadBalancer_603519 = ref object of OpenApiRestCall_602466
proc url_PostDeregisterInstancesFromLoadBalancer_603521(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeregisterInstancesFromLoadBalancer_603520(path: JsonNode;
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
  var valid_603522 = query.getOrDefault("Action")
  valid_603522 = validateParameter(valid_603522, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_603522 != nil:
    section.add "Action", valid_603522
  var valid_603523 = query.getOrDefault("Version")
  valid_603523 = validateParameter(valid_603523, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603523 != nil:
    section.add "Version", valid_603523
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603524 = header.getOrDefault("X-Amz-Date")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Date", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Security-Token")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Security-Token", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Content-Sha256", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Algorithm")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Algorithm", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Signature")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Signature", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-SignedHeaders", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Credential")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Credential", valid_603530
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_603531 = formData.getOrDefault("Instances")
  valid_603531 = validateParameter(valid_603531, JArray, required = true, default = nil)
  if valid_603531 != nil:
    section.add "Instances", valid_603531
  var valid_603532 = formData.getOrDefault("LoadBalancerName")
  valid_603532 = validateParameter(valid_603532, JString, required = true,
                                 default = nil)
  if valid_603532 != nil:
    section.add "LoadBalancerName", valid_603532
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603533: Call_PostDeregisterInstancesFromLoadBalancer_603519;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603533.validator(path, query, header, formData, body)
  let scheme = call_603533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603533.url(scheme.get, call_603533.host, call_603533.base,
                         call_603533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603533, url, valid)

proc call*(call_603534: Call_PostDeregisterInstancesFromLoadBalancer_603519;
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
  var query_603535 = newJObject()
  var formData_603536 = newJObject()
  if Instances != nil:
    formData_603536.add "Instances", Instances
  add(query_603535, "Action", newJString(Action))
  add(formData_603536, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603535, "Version", newJString(Version))
  result = call_603534.call(nil, query_603535, nil, formData_603536, nil)

var postDeregisterInstancesFromLoadBalancer* = Call_PostDeregisterInstancesFromLoadBalancer_603519(
    name: "postDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_PostDeregisterInstancesFromLoadBalancer_603520, base: "/",
    url: url_PostDeregisterInstancesFromLoadBalancer_603521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeregisterInstancesFromLoadBalancer_603502 = ref object of OpenApiRestCall_602466
proc url_GetDeregisterInstancesFromLoadBalancer_603504(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeregisterInstancesFromLoadBalancer_603503(path: JsonNode;
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
  var valid_603505 = query.getOrDefault("LoadBalancerName")
  valid_603505 = validateParameter(valid_603505, JString, required = true,
                                 default = nil)
  if valid_603505 != nil:
    section.add "LoadBalancerName", valid_603505
  var valid_603506 = query.getOrDefault("Action")
  valid_603506 = validateParameter(valid_603506, JString, required = true, default = newJString(
      "DeregisterInstancesFromLoadBalancer"))
  if valid_603506 != nil:
    section.add "Action", valid_603506
  var valid_603507 = query.getOrDefault("Instances")
  valid_603507 = validateParameter(valid_603507, JArray, required = true, default = nil)
  if valid_603507 != nil:
    section.add "Instances", valid_603507
  var valid_603508 = query.getOrDefault("Version")
  valid_603508 = validateParameter(valid_603508, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603508 != nil:
    section.add "Version", valid_603508
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603509 = header.getOrDefault("X-Amz-Date")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Date", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Security-Token")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Security-Token", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Content-Sha256", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Algorithm")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Algorithm", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Signature")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Signature", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-SignedHeaders", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Credential")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Credential", valid_603515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603516: Call_GetDeregisterInstancesFromLoadBalancer_603502;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deregisters the specified instances from the specified load balancer. After the instance is deregistered, it no longer receives traffic from the load balancer.</p> <p>You can use <a>DescribeLoadBalancers</a> to verify that the instance is deregistered from the load balancer.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603516.validator(path, query, header, formData, body)
  let scheme = call_603516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603516.url(scheme.get, call_603516.host, call_603516.base,
                         call_603516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603516, url, valid)

proc call*(call_603517: Call_GetDeregisterInstancesFromLoadBalancer_603502;
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
  var query_603518 = newJObject()
  add(query_603518, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603518, "Action", newJString(Action))
  if Instances != nil:
    query_603518.add "Instances", Instances
  add(query_603518, "Version", newJString(Version))
  result = call_603517.call(nil, query_603518, nil, nil, nil)

var getDeregisterInstancesFromLoadBalancer* = Call_GetDeregisterInstancesFromLoadBalancer_603502(
    name: "getDeregisterInstancesFromLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DeregisterInstancesFromLoadBalancer",
    validator: validate_GetDeregisterInstancesFromLoadBalancer_603503, base: "/",
    url: url_GetDeregisterInstancesFromLoadBalancer_603504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountLimits_603554 = ref object of OpenApiRestCall_602466
proc url_PostDescribeAccountLimits_603556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAccountLimits_603555(path: JsonNode; query: JsonNode;
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
  var valid_603557 = query.getOrDefault("Action")
  valid_603557 = validateParameter(valid_603557, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_603557 != nil:
    section.add "Action", valid_603557
  var valid_603558 = query.getOrDefault("Version")
  valid_603558 = validateParameter(valid_603558, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603558 != nil:
    section.add "Version", valid_603558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603559 = header.getOrDefault("X-Amz-Date")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Date", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Security-Token")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Security-Token", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Content-Sha256", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Algorithm")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Algorithm", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Signature")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Signature", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-SignedHeaders", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-Credential")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Credential", valid_603565
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call.
  section = newJObject()
  var valid_603566 = formData.getOrDefault("Marker")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "Marker", valid_603566
  var valid_603567 = formData.getOrDefault("PageSize")
  valid_603567 = validateParameter(valid_603567, JInt, required = false, default = nil)
  if valid_603567 != nil:
    section.add "PageSize", valid_603567
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603568: Call_PostDescribeAccountLimits_603554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603568.validator(path, query, header, formData, body)
  let scheme = call_603568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603568.url(scheme.get, call_603568.host, call_603568.base,
                         call_603568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603568, url, valid)

proc call*(call_603569: Call_PostDescribeAccountLimits_603554; Marker: string = "";
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
  var query_603570 = newJObject()
  var formData_603571 = newJObject()
  add(formData_603571, "Marker", newJString(Marker))
  add(query_603570, "Action", newJString(Action))
  add(formData_603571, "PageSize", newJInt(PageSize))
  add(query_603570, "Version", newJString(Version))
  result = call_603569.call(nil, query_603570, nil, formData_603571, nil)

var postDescribeAccountLimits* = Call_PostDescribeAccountLimits_603554(
    name: "postDescribeAccountLimits", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_PostDescribeAccountLimits_603555, base: "/",
    url: url_PostDescribeAccountLimits_603556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountLimits_603537 = ref object of OpenApiRestCall_602466
proc url_GetDescribeAccountLimits_603539(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAccountLimits_603538(path: JsonNode; query: JsonNode;
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
  var valid_603540 = query.getOrDefault("PageSize")
  valid_603540 = validateParameter(valid_603540, JInt, required = false, default = nil)
  if valid_603540 != nil:
    section.add "PageSize", valid_603540
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603541 = query.getOrDefault("Action")
  valid_603541 = validateParameter(valid_603541, JString, required = true,
                                 default = newJString("DescribeAccountLimits"))
  if valid_603541 != nil:
    section.add "Action", valid_603541
  var valid_603542 = query.getOrDefault("Marker")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "Marker", valid_603542
  var valid_603543 = query.getOrDefault("Version")
  valid_603543 = validateParameter(valid_603543, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603543 != nil:
    section.add "Version", valid_603543
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603544 = header.getOrDefault("X-Amz-Date")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Date", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Security-Token")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Security-Token", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Content-Sha256", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Algorithm")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Algorithm", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Signature")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Signature", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-SignedHeaders", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Credential")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Credential", valid_603550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603551: Call_GetDescribeAccountLimits_603537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the current Elastic Load Balancing resource limits for your AWS account.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-limits.html">Limits for Your Classic Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603551.validator(path, query, header, formData, body)
  let scheme = call_603551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603551.url(scheme.get, call_603551.host, call_603551.base,
                         call_603551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603551, url, valid)

proc call*(call_603552: Call_GetDescribeAccountLimits_603537; PageSize: int = 0;
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
  var query_603553 = newJObject()
  add(query_603553, "PageSize", newJInt(PageSize))
  add(query_603553, "Action", newJString(Action))
  add(query_603553, "Marker", newJString(Marker))
  add(query_603553, "Version", newJString(Version))
  result = call_603552.call(nil, query_603553, nil, nil, nil)

var getDescribeAccountLimits* = Call_GetDescribeAccountLimits_603537(
    name: "getDescribeAccountLimits", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeAccountLimits",
    validator: validate_GetDescribeAccountLimits_603538, base: "/",
    url: url_GetDescribeAccountLimits_603539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstanceHealth_603589 = ref object of OpenApiRestCall_602466
proc url_PostDescribeInstanceHealth_603591(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeInstanceHealth_603590(path: JsonNode; query: JsonNode;
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
  var valid_603592 = query.getOrDefault("Action")
  valid_603592 = validateParameter(valid_603592, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_603592 != nil:
    section.add "Action", valid_603592
  var valid_603593 = query.getOrDefault("Version")
  valid_603593 = validateParameter(valid_603593, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603593 != nil:
    section.add "Version", valid_603593
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603594 = header.getOrDefault("X-Amz-Date")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Date", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Security-Token")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Security-Token", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Content-Sha256", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Algorithm")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Algorithm", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-Signature")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Signature", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-SignedHeaders", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Credential")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Credential", valid_603600
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_603601 = formData.getOrDefault("Instances")
  valid_603601 = validateParameter(valid_603601, JArray, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "Instances", valid_603601
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_603602 = formData.getOrDefault("LoadBalancerName")
  valid_603602 = validateParameter(valid_603602, JString, required = true,
                                 default = nil)
  if valid_603602 != nil:
    section.add "LoadBalancerName", valid_603602
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603603: Call_PostDescribeInstanceHealth_603589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_603603.validator(path, query, header, formData, body)
  let scheme = call_603603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603603.url(scheme.get, call_603603.host, call_603603.base,
                         call_603603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603603, url, valid)

proc call*(call_603604: Call_PostDescribeInstanceHealth_603589;
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
  var query_603605 = newJObject()
  var formData_603606 = newJObject()
  if Instances != nil:
    formData_603606.add "Instances", Instances
  add(query_603605, "Action", newJString(Action))
  add(formData_603606, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603605, "Version", newJString(Version))
  result = call_603604.call(nil, query_603605, nil, formData_603606, nil)

var postDescribeInstanceHealth* = Call_PostDescribeInstanceHealth_603589(
    name: "postDescribeInstanceHealth", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_PostDescribeInstanceHealth_603590, base: "/",
    url: url_PostDescribeInstanceHealth_603591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstanceHealth_603572 = ref object of OpenApiRestCall_602466
proc url_GetDescribeInstanceHealth_603574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeInstanceHealth_603573(path: JsonNode; query: JsonNode;
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
  var valid_603575 = query.getOrDefault("LoadBalancerName")
  valid_603575 = validateParameter(valid_603575, JString, required = true,
                                 default = nil)
  if valid_603575 != nil:
    section.add "LoadBalancerName", valid_603575
  var valid_603576 = query.getOrDefault("Action")
  valid_603576 = validateParameter(valid_603576, JString, required = true,
                                 default = newJString("DescribeInstanceHealth"))
  if valid_603576 != nil:
    section.add "Action", valid_603576
  var valid_603577 = query.getOrDefault("Instances")
  valid_603577 = validateParameter(valid_603577, JArray, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "Instances", valid_603577
  var valid_603578 = query.getOrDefault("Version")
  valid_603578 = validateParameter(valid_603578, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603578 != nil:
    section.add "Version", valid_603578
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603579 = header.getOrDefault("X-Amz-Date")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Date", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Security-Token")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Security-Token", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Content-Sha256", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Algorithm")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Algorithm", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Signature")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Signature", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-SignedHeaders", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Credential")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Credential", valid_603585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603586: Call_GetDescribeInstanceHealth_603572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the state of the specified instances with respect to the specified load balancer. If no instances are specified, the call describes the state of all instances that are currently registered with the load balancer. If instances are specified, their state is returned even if they are no longer registered with the load balancer. The state of terminated instances is not returned.
  ## 
  let valid = call_603586.validator(path, query, header, formData, body)
  let scheme = call_603586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603586.url(scheme.get, call_603586.host, call_603586.base,
                         call_603586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603586, url, valid)

proc call*(call_603587: Call_GetDescribeInstanceHealth_603572;
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
  var query_603588 = newJObject()
  add(query_603588, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603588, "Action", newJString(Action))
  if Instances != nil:
    query_603588.add "Instances", Instances
  add(query_603588, "Version", newJString(Version))
  result = call_603587.call(nil, query_603588, nil, nil, nil)

var getDescribeInstanceHealth* = Call_GetDescribeInstanceHealth_603572(
    name: "getDescribeInstanceHealth", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeInstanceHealth",
    validator: validate_GetDescribeInstanceHealth_603573, base: "/",
    url: url_GetDescribeInstanceHealth_603574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerAttributes_603623 = ref object of OpenApiRestCall_602466
proc url_PostDescribeLoadBalancerAttributes_603625(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancerAttributes_603624(path: JsonNode;
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
  var valid_603626 = query.getOrDefault("Action")
  valid_603626 = validateParameter(valid_603626, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_603626 != nil:
    section.add "Action", valid_603626
  var valid_603627 = query.getOrDefault("Version")
  valid_603627 = validateParameter(valid_603627, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603627 != nil:
    section.add "Version", valid_603627
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603628 = header.getOrDefault("X-Amz-Date")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Date", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Security-Token")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Security-Token", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Content-Sha256", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Algorithm")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Algorithm", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Signature")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Signature", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-SignedHeaders", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Credential")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Credential", valid_603634
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_603635 = formData.getOrDefault("LoadBalancerName")
  valid_603635 = validateParameter(valid_603635, JString, required = true,
                                 default = nil)
  if valid_603635 != nil:
    section.add "LoadBalancerName", valid_603635
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603636: Call_PostDescribeLoadBalancerAttributes_603623;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_603636.validator(path, query, header, formData, body)
  let scheme = call_603636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603636.url(scheme.get, call_603636.host, call_603636.base,
                         call_603636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603636, url, valid)

proc call*(call_603637: Call_PostDescribeLoadBalancerAttributes_603623;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   Action: string (required)
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Version: string (required)
  var query_603638 = newJObject()
  var formData_603639 = newJObject()
  add(query_603638, "Action", newJString(Action))
  add(formData_603639, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603638, "Version", newJString(Version))
  result = call_603637.call(nil, query_603638, nil, formData_603639, nil)

var postDescribeLoadBalancerAttributes* = Call_PostDescribeLoadBalancerAttributes_603623(
    name: "postDescribeLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_PostDescribeLoadBalancerAttributes_603624, base: "/",
    url: url_PostDescribeLoadBalancerAttributes_603625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerAttributes_603607 = ref object of OpenApiRestCall_602466
proc url_GetDescribeLoadBalancerAttributes_603609(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancerAttributes_603608(path: JsonNode;
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
  var valid_603610 = query.getOrDefault("LoadBalancerName")
  valid_603610 = validateParameter(valid_603610, JString, required = true,
                                 default = nil)
  if valid_603610 != nil:
    section.add "LoadBalancerName", valid_603610
  var valid_603611 = query.getOrDefault("Action")
  valid_603611 = validateParameter(valid_603611, JString, required = true, default = newJString(
      "DescribeLoadBalancerAttributes"))
  if valid_603611 != nil:
    section.add "Action", valid_603611
  var valid_603612 = query.getOrDefault("Version")
  valid_603612 = validateParameter(valid_603612, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603612 != nil:
    section.add "Version", valid_603612
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603613 = header.getOrDefault("X-Amz-Date")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Date", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Security-Token")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Security-Token", valid_603614
  var valid_603615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Content-Sha256", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Algorithm")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Algorithm", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Signature")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Signature", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-SignedHeaders", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Credential")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Credential", valid_603619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603620: Call_GetDescribeLoadBalancerAttributes_603607;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the attributes for the specified load balancer.
  ## 
  let valid = call_603620.validator(path, query, header, formData, body)
  let scheme = call_603620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603620.url(scheme.get, call_603620.host, call_603620.base,
                         call_603620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603620, url, valid)

proc call*(call_603621: Call_GetDescribeLoadBalancerAttributes_603607;
          LoadBalancerName: string;
          Action: string = "DescribeLoadBalancerAttributes";
          Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerAttributes
  ## Describes the attributes for the specified load balancer.
  ##   LoadBalancerName: string (required)
  ##                   : The name of the load balancer.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603622 = newJObject()
  add(query_603622, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603622, "Action", newJString(Action))
  add(query_603622, "Version", newJString(Version))
  result = call_603621.call(nil, query_603622, nil, nil, nil)

var getDescribeLoadBalancerAttributes* = Call_GetDescribeLoadBalancerAttributes_603607(
    name: "getDescribeLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerAttributes",
    validator: validate_GetDescribeLoadBalancerAttributes_603608, base: "/",
    url: url_GetDescribeLoadBalancerAttributes_603609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicies_603657 = ref object of OpenApiRestCall_602466
proc url_PostDescribeLoadBalancerPolicies_603659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancerPolicies_603658(path: JsonNode;
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
  var valid_603660 = query.getOrDefault("Action")
  valid_603660 = validateParameter(valid_603660, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_603660 != nil:
    section.add "Action", valid_603660
  var valid_603661 = query.getOrDefault("Version")
  valid_603661 = validateParameter(valid_603661, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603661 != nil:
    section.add "Version", valid_603661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603662 = header.getOrDefault("X-Amz-Date")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Date", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Security-Token")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Security-Token", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Content-Sha256", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Algorithm")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Algorithm", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-Signature")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-Signature", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-SignedHeaders", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-Credential")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Credential", valid_603668
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyNames: JArray
  ##              : The names of the policies.
  ##   LoadBalancerName: JString
  ##                   : The name of the load balancer.
  section = newJObject()
  var valid_603669 = formData.getOrDefault("PolicyNames")
  valid_603669 = validateParameter(valid_603669, JArray, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "PolicyNames", valid_603669
  var valid_603670 = formData.getOrDefault("LoadBalancerName")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "LoadBalancerName", valid_603670
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603671: Call_PostDescribeLoadBalancerPolicies_603657;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_603671.validator(path, query, header, formData, body)
  let scheme = call_603671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603671.url(scheme.get, call_603671.host, call_603671.base,
                         call_603671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603671, url, valid)

proc call*(call_603672: Call_PostDescribeLoadBalancerPolicies_603657;
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
  var query_603673 = newJObject()
  var formData_603674 = newJObject()
  if PolicyNames != nil:
    formData_603674.add "PolicyNames", PolicyNames
  add(query_603673, "Action", newJString(Action))
  add(formData_603674, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603673, "Version", newJString(Version))
  result = call_603672.call(nil, query_603673, nil, formData_603674, nil)

var postDescribeLoadBalancerPolicies* = Call_PostDescribeLoadBalancerPolicies_603657(
    name: "postDescribeLoadBalancerPolicies", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_PostDescribeLoadBalancerPolicies_603658, base: "/",
    url: url_PostDescribeLoadBalancerPolicies_603659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicies_603640 = ref object of OpenApiRestCall_602466
proc url_GetDescribeLoadBalancerPolicies_603642(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancerPolicies_603641(path: JsonNode;
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
  var valid_603643 = query.getOrDefault("LoadBalancerName")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "LoadBalancerName", valid_603643
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603644 = query.getOrDefault("Action")
  valid_603644 = validateParameter(valid_603644, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicies"))
  if valid_603644 != nil:
    section.add "Action", valid_603644
  var valid_603645 = query.getOrDefault("PolicyNames")
  valid_603645 = validateParameter(valid_603645, JArray, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "PolicyNames", valid_603645
  var valid_603646 = query.getOrDefault("Version")
  valid_603646 = validateParameter(valid_603646, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603646 != nil:
    section.add "Version", valid_603646
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603647 = header.getOrDefault("X-Amz-Date")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Date", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Security-Token")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Security-Token", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Content-Sha256", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Algorithm")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Algorithm", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-Signature")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Signature", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-SignedHeaders", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Credential")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Credential", valid_603653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603654: Call_GetDescribeLoadBalancerPolicies_603640;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified policies.</p> <p>If you specify a load balancer name, the action returns the descriptions of all policies created for the load balancer. If you specify a policy name associated with your load balancer, the action returns the description of that policy. If you don't specify a load balancer name, the action returns descriptions of the specified sample policies, or descriptions of all sample policies. The names of the sample policies have the <code>ELBSample-</code> prefix.</p>
  ## 
  let valid = call_603654.validator(path, query, header, formData, body)
  let scheme = call_603654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603654.url(scheme.get, call_603654.host, call_603654.base,
                         call_603654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603654, url, valid)

proc call*(call_603655: Call_GetDescribeLoadBalancerPolicies_603640;
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
  var query_603656 = newJObject()
  add(query_603656, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603656, "Action", newJString(Action))
  if PolicyNames != nil:
    query_603656.add "PolicyNames", PolicyNames
  add(query_603656, "Version", newJString(Version))
  result = call_603655.call(nil, query_603656, nil, nil, nil)

var getDescribeLoadBalancerPolicies* = Call_GetDescribeLoadBalancerPolicies_603640(
    name: "getDescribeLoadBalancerPolicies", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicies",
    validator: validate_GetDescribeLoadBalancerPolicies_603641, base: "/",
    url: url_GetDescribeLoadBalancerPolicies_603642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancerPolicyTypes_603691 = ref object of OpenApiRestCall_602466
proc url_PostDescribeLoadBalancerPolicyTypes_603693(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancerPolicyTypes_603692(path: JsonNode;
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
  var valid_603694 = query.getOrDefault("Action")
  valid_603694 = validateParameter(valid_603694, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_603694 != nil:
    section.add "Action", valid_603694
  var valid_603695 = query.getOrDefault("Version")
  valid_603695 = validateParameter(valid_603695, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603695 != nil:
    section.add "Version", valid_603695
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603696 = header.getOrDefault("X-Amz-Date")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Date", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Security-Token")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Security-Token", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Content-Sha256", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Algorithm")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Algorithm", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Signature")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Signature", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-SignedHeaders", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Credential")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Credential", valid_603702
  result.add "header", section
  ## parameters in `formData` object:
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  section = newJObject()
  var valid_603703 = formData.getOrDefault("PolicyTypeNames")
  valid_603703 = validateParameter(valid_603703, JArray, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "PolicyTypeNames", valid_603703
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603704: Call_PostDescribeLoadBalancerPolicyTypes_603691;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_603704.validator(path, query, header, formData, body)
  let scheme = call_603704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603704.url(scheme.get, call_603704.host, call_603704.base,
                         call_603704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603704, url, valid)

proc call*(call_603705: Call_PostDescribeLoadBalancerPolicyTypes_603691;
          PolicyTypeNames: JsonNode = nil;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          Version: string = "2012-06-01"): Recallable =
  ## postDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603706 = newJObject()
  var formData_603707 = newJObject()
  if PolicyTypeNames != nil:
    formData_603707.add "PolicyTypeNames", PolicyTypeNames
  add(query_603706, "Action", newJString(Action))
  add(query_603706, "Version", newJString(Version))
  result = call_603705.call(nil, query_603706, nil, formData_603707, nil)

var postDescribeLoadBalancerPolicyTypes* = Call_PostDescribeLoadBalancerPolicyTypes_603691(
    name: "postDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_PostDescribeLoadBalancerPolicyTypes_603692, base: "/",
    url: url_PostDescribeLoadBalancerPolicyTypes_603693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancerPolicyTypes_603675 = ref object of OpenApiRestCall_602466
proc url_GetDescribeLoadBalancerPolicyTypes_603677(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancerPolicyTypes_603676(path: JsonNode;
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
  var valid_603678 = query.getOrDefault("Action")
  valid_603678 = validateParameter(valid_603678, JString, required = true, default = newJString(
      "DescribeLoadBalancerPolicyTypes"))
  if valid_603678 != nil:
    section.add "Action", valid_603678
  var valid_603679 = query.getOrDefault("PolicyTypeNames")
  valid_603679 = validateParameter(valid_603679, JArray, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "PolicyTypeNames", valid_603679
  var valid_603680 = query.getOrDefault("Version")
  valid_603680 = validateParameter(valid_603680, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603680 != nil:
    section.add "Version", valid_603680
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603681 = header.getOrDefault("X-Amz-Date")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-Date", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Security-Token")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Security-Token", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Content-Sha256", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Algorithm")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Algorithm", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Signature")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Signature", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-SignedHeaders", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Credential")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Credential", valid_603687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603688: Call_GetDescribeLoadBalancerPolicyTypes_603675;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ## 
  let valid = call_603688.validator(path, query, header, formData, body)
  let scheme = call_603688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603688.url(scheme.get, call_603688.host, call_603688.base,
                         call_603688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603688, url, valid)

proc call*(call_603689: Call_GetDescribeLoadBalancerPolicyTypes_603675;
          Action: string = "DescribeLoadBalancerPolicyTypes";
          PolicyTypeNames: JsonNode = nil; Version: string = "2012-06-01"): Recallable =
  ## getDescribeLoadBalancerPolicyTypes
  ## <p>Describes the specified load balancer policy types or all load balancer policy types.</p> <p>The description of each type indicates how it can be used. For example, some policies can be used only with layer 7 listeners, some policies can be used only with layer 4 listeners, and some policies can be used only with your EC2 instances.</p> <p>You can use <a>CreateLoadBalancerPolicy</a> to create a policy configuration for any of these policy types. Then, depending on the policy type, use either <a>SetLoadBalancerPoliciesOfListener</a> or <a>SetLoadBalancerPoliciesForBackendServer</a> to set the policy.</p>
  ##   Action: string (required)
  ##   PolicyTypeNames: JArray
  ##                  : The names of the policy types. If no names are specified, describes all policy types defined by Elastic Load Balancing.
  ##   Version: string (required)
  var query_603690 = newJObject()
  add(query_603690, "Action", newJString(Action))
  if PolicyTypeNames != nil:
    query_603690.add "PolicyTypeNames", PolicyTypeNames
  add(query_603690, "Version", newJString(Version))
  result = call_603689.call(nil, query_603690, nil, nil, nil)

var getDescribeLoadBalancerPolicyTypes* = Call_GetDescribeLoadBalancerPolicyTypes_603675(
    name: "getDescribeLoadBalancerPolicyTypes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancerPolicyTypes",
    validator: validate_GetDescribeLoadBalancerPolicyTypes_603676, base: "/",
    url: url_GetDescribeLoadBalancerPolicyTypes_603677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeLoadBalancers_603726 = ref object of OpenApiRestCall_602466
proc url_PostDescribeLoadBalancers_603728(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeLoadBalancers_603727(path: JsonNode; query: JsonNode;
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
  var valid_603729 = query.getOrDefault("Action")
  valid_603729 = validateParameter(valid_603729, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_603729 != nil:
    section.add "Action", valid_603729
  var valid_603730 = query.getOrDefault("Version")
  valid_603730 = validateParameter(valid_603730, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603730 != nil:
    section.add "Version", valid_603730
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603731 = header.getOrDefault("X-Amz-Date")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Date", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Security-Token")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Security-Token", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Content-Sha256", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Algorithm")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Algorithm", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Signature")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Signature", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-SignedHeaders", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-Credential")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Credential", valid_603737
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : The marker for the next set of results. (You received this marker from a previous call.)
  ##   LoadBalancerNames: JArray
  ##                    : The names of the load balancers.
  ##   PageSize: JInt
  ##           : The maximum number of results to return with this call (a number from 1 to 400). The default is 400.
  section = newJObject()
  var valid_603738 = formData.getOrDefault("Marker")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "Marker", valid_603738
  var valid_603739 = formData.getOrDefault("LoadBalancerNames")
  valid_603739 = validateParameter(valid_603739, JArray, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "LoadBalancerNames", valid_603739
  var valid_603740 = formData.getOrDefault("PageSize")
  valid_603740 = validateParameter(valid_603740, JInt, required = false, default = nil)
  if valid_603740 != nil:
    section.add "PageSize", valid_603740
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603741: Call_PostDescribeLoadBalancers_603726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_603741.validator(path, query, header, formData, body)
  let scheme = call_603741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603741.url(scheme.get, call_603741.host, call_603741.base,
                         call_603741.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603741, url, valid)

proc call*(call_603742: Call_PostDescribeLoadBalancers_603726; Marker: string = "";
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
  var query_603743 = newJObject()
  var formData_603744 = newJObject()
  add(formData_603744, "Marker", newJString(Marker))
  add(query_603743, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_603744.add "LoadBalancerNames", LoadBalancerNames
  add(formData_603744, "PageSize", newJInt(PageSize))
  add(query_603743, "Version", newJString(Version))
  result = call_603742.call(nil, query_603743, nil, formData_603744, nil)

var postDescribeLoadBalancers* = Call_PostDescribeLoadBalancers_603726(
    name: "postDescribeLoadBalancers", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_PostDescribeLoadBalancers_603727, base: "/",
    url: url_PostDescribeLoadBalancers_603728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeLoadBalancers_603708 = ref object of OpenApiRestCall_602466
proc url_GetDescribeLoadBalancers_603710(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeLoadBalancers_603709(path: JsonNode; query: JsonNode;
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
  var valid_603711 = query.getOrDefault("PageSize")
  valid_603711 = validateParameter(valid_603711, JInt, required = false, default = nil)
  if valid_603711 != nil:
    section.add "PageSize", valid_603711
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603712 = query.getOrDefault("Action")
  valid_603712 = validateParameter(valid_603712, JString, required = true,
                                 default = newJString("DescribeLoadBalancers"))
  if valid_603712 != nil:
    section.add "Action", valid_603712
  var valid_603713 = query.getOrDefault("Marker")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "Marker", valid_603713
  var valid_603714 = query.getOrDefault("LoadBalancerNames")
  valid_603714 = validateParameter(valid_603714, JArray, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "LoadBalancerNames", valid_603714
  var valid_603715 = query.getOrDefault("Version")
  valid_603715 = validateParameter(valid_603715, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603715 != nil:
    section.add "Version", valid_603715
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603716 = header.getOrDefault("X-Amz-Date")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Date", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Security-Token")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Security-Token", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Content-Sha256", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Algorithm")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Algorithm", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Signature")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Signature", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-SignedHeaders", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Credential")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Credential", valid_603722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603723: Call_GetDescribeLoadBalancers_603708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified the load balancers. If no load balancers are specified, the call describes all of your load balancers.
  ## 
  let valid = call_603723.validator(path, query, header, formData, body)
  let scheme = call_603723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603723.url(scheme.get, call_603723.host, call_603723.base,
                         call_603723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603723, url, valid)

proc call*(call_603724: Call_GetDescribeLoadBalancers_603708; PageSize: int = 0;
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
  var query_603725 = newJObject()
  add(query_603725, "PageSize", newJInt(PageSize))
  add(query_603725, "Action", newJString(Action))
  add(query_603725, "Marker", newJString(Marker))
  if LoadBalancerNames != nil:
    query_603725.add "LoadBalancerNames", LoadBalancerNames
  add(query_603725, "Version", newJString(Version))
  result = call_603724.call(nil, query_603725, nil, nil, nil)

var getDescribeLoadBalancers* = Call_GetDescribeLoadBalancers_603708(
    name: "getDescribeLoadBalancers", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeLoadBalancers",
    validator: validate_GetDescribeLoadBalancers_603709, base: "/",
    url: url_GetDescribeLoadBalancers_603710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeTags_603761 = ref object of OpenApiRestCall_602466
proc url_PostDescribeTags_603763(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeTags_603762(path: JsonNode; query: JsonNode;
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
  var valid_603764 = query.getOrDefault("Action")
  valid_603764 = validateParameter(valid_603764, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_603764 != nil:
    section.add "Action", valid_603764
  var valid_603765 = query.getOrDefault("Version")
  valid_603765 = validateParameter(valid_603765, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603765 != nil:
    section.add "Version", valid_603765
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603766 = header.getOrDefault("X-Amz-Date")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Date", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Security-Token")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Security-Token", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Content-Sha256", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Algorithm")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Algorithm", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Signature")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Signature", valid_603770
  var valid_603771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "X-Amz-SignedHeaders", valid_603771
  var valid_603772 = header.getOrDefault("X-Amz-Credential")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-Credential", valid_603772
  result.add "header", section
  ## parameters in `formData` object:
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerNames` field"
  var valid_603773 = formData.getOrDefault("LoadBalancerNames")
  valid_603773 = validateParameter(valid_603773, JArray, required = true, default = nil)
  if valid_603773 != nil:
    section.add "LoadBalancerNames", valid_603773
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603774: Call_PostDescribeTags_603761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_603774.validator(path, query, header, formData, body)
  let scheme = call_603774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603774.url(scheme.get, call_603774.host, call_603774.base,
                         call_603774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603774, url, valid)

proc call*(call_603775: Call_PostDescribeTags_603761; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## postDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_603776 = newJObject()
  var formData_603777 = newJObject()
  add(query_603776, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_603777.add "LoadBalancerNames", LoadBalancerNames
  add(query_603776, "Version", newJString(Version))
  result = call_603775.call(nil, query_603776, nil, formData_603777, nil)

var postDescribeTags* = Call_PostDescribeTags_603761(name: "postDescribeTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_PostDescribeTags_603762,
    base: "/", url: url_PostDescribeTags_603763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeTags_603745 = ref object of OpenApiRestCall_602466
proc url_GetDescribeTags_603747(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeTags_603746(path: JsonNode; query: JsonNode;
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
  var valid_603748 = query.getOrDefault("Action")
  valid_603748 = validateParameter(valid_603748, JString, required = true,
                                 default = newJString("DescribeTags"))
  if valid_603748 != nil:
    section.add "Action", valid_603748
  var valid_603749 = query.getOrDefault("LoadBalancerNames")
  valid_603749 = validateParameter(valid_603749, JArray, required = true, default = nil)
  if valid_603749 != nil:
    section.add "LoadBalancerNames", valid_603749
  var valid_603750 = query.getOrDefault("Version")
  valid_603750 = validateParameter(valid_603750, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603750 != nil:
    section.add "Version", valid_603750
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603751 = header.getOrDefault("X-Amz-Date")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Date", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Security-Token")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Security-Token", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Content-Sha256", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-Algorithm")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Algorithm", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Signature")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Signature", valid_603755
  var valid_603756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "X-Amz-SignedHeaders", valid_603756
  var valid_603757 = header.getOrDefault("X-Amz-Credential")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Credential", valid_603757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603758: Call_GetDescribeTags_603745; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the tags associated with the specified load balancers.
  ## 
  let valid = call_603758.validator(path, query, header, formData, body)
  let scheme = call_603758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603758.url(scheme.get, call_603758.host, call_603758.base,
                         call_603758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603758, url, valid)

proc call*(call_603759: Call_GetDescribeTags_603745; LoadBalancerNames: JsonNode;
          Action: string = "DescribeTags"; Version: string = "2012-06-01"): Recallable =
  ## getDescribeTags
  ## Describes the tags associated with the specified load balancers.
  ##   Action: string (required)
  ##   LoadBalancerNames: JArray (required)
  ##                    : The names of the load balancers.
  ##   Version: string (required)
  var query_603760 = newJObject()
  add(query_603760, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_603760.add "LoadBalancerNames", LoadBalancerNames
  add(query_603760, "Version", newJString(Version))
  result = call_603759.call(nil, query_603760, nil, nil, nil)

var getDescribeTags* = Call_GetDescribeTags_603745(name: "getDescribeTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DescribeTags", validator: validate_GetDescribeTags_603746,
    base: "/", url: url_GetDescribeTags_603747, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDetachLoadBalancerFromSubnets_603795 = ref object of OpenApiRestCall_602466
proc url_PostDetachLoadBalancerFromSubnets_603797(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDetachLoadBalancerFromSubnets_603796(path: JsonNode;
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
  var valid_603798 = query.getOrDefault("Action")
  valid_603798 = validateParameter(valid_603798, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_603798 != nil:
    section.add "Action", valid_603798
  var valid_603799 = query.getOrDefault("Version")
  valid_603799 = validateParameter(valid_603799, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603799 != nil:
    section.add "Version", valid_603799
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603800 = header.getOrDefault("X-Amz-Date")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Date", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Security-Token")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Security-Token", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Content-Sha256", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Algorithm")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Algorithm", valid_603803
  var valid_603804 = header.getOrDefault("X-Amz-Signature")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Signature", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-SignedHeaders", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Credential")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Credential", valid_603806
  result.add "header", section
  ## parameters in `formData` object:
  ##   Subnets: JArray (required)
  ##          : The IDs of the subnets.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Subnets` field"
  var valid_603807 = formData.getOrDefault("Subnets")
  valid_603807 = validateParameter(valid_603807, JArray, required = true, default = nil)
  if valid_603807 != nil:
    section.add "Subnets", valid_603807
  var valid_603808 = formData.getOrDefault("LoadBalancerName")
  valid_603808 = validateParameter(valid_603808, JString, required = true,
                                 default = nil)
  if valid_603808 != nil:
    section.add "LoadBalancerName", valid_603808
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603809: Call_PostDetachLoadBalancerFromSubnets_603795;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_603809.validator(path, query, header, formData, body)
  let scheme = call_603809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603809.url(scheme.get, call_603809.host, call_603809.base,
                         call_603809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603809, url, valid)

proc call*(call_603810: Call_PostDetachLoadBalancerFromSubnets_603795;
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
  var query_603811 = newJObject()
  var formData_603812 = newJObject()
  add(query_603811, "Action", newJString(Action))
  if Subnets != nil:
    formData_603812.add "Subnets", Subnets
  add(formData_603812, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603811, "Version", newJString(Version))
  result = call_603810.call(nil, query_603811, nil, formData_603812, nil)

var postDetachLoadBalancerFromSubnets* = Call_PostDetachLoadBalancerFromSubnets_603795(
    name: "postDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_PostDetachLoadBalancerFromSubnets_603796, base: "/",
    url: url_PostDetachLoadBalancerFromSubnets_603797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetachLoadBalancerFromSubnets_603778 = ref object of OpenApiRestCall_602466
proc url_GetDetachLoadBalancerFromSubnets_603780(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDetachLoadBalancerFromSubnets_603779(path: JsonNode;
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
  var valid_603781 = query.getOrDefault("LoadBalancerName")
  valid_603781 = validateParameter(valid_603781, JString, required = true,
                                 default = nil)
  if valid_603781 != nil:
    section.add "LoadBalancerName", valid_603781
  var valid_603782 = query.getOrDefault("Action")
  valid_603782 = validateParameter(valid_603782, JString, required = true, default = newJString(
      "DetachLoadBalancerFromSubnets"))
  if valid_603782 != nil:
    section.add "Action", valid_603782
  var valid_603783 = query.getOrDefault("Subnets")
  valid_603783 = validateParameter(valid_603783, JArray, required = true, default = nil)
  if valid_603783 != nil:
    section.add "Subnets", valid_603783
  var valid_603784 = query.getOrDefault("Version")
  valid_603784 = validateParameter(valid_603784, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603784 != nil:
    section.add "Version", valid_603784
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603785 = header.getOrDefault("X-Amz-Date")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Date", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-Security-Token")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Security-Token", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Content-Sha256", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-Algorithm")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Algorithm", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Signature")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Signature", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-SignedHeaders", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Credential")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Credential", valid_603791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603792: Call_GetDetachLoadBalancerFromSubnets_603778;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified subnets from the set of configured subnets for the load balancer.</p> <p>After a subnet is removed, all EC2 instances registered with the load balancer in the removed subnet go into the <code>OutOfService</code> state. Then, the load balancer balances the traffic among the remaining routable subnets.</p>
  ## 
  let valid = call_603792.validator(path, query, header, formData, body)
  let scheme = call_603792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603792.url(scheme.get, call_603792.host, call_603792.base,
                         call_603792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603792, url, valid)

proc call*(call_603793: Call_GetDetachLoadBalancerFromSubnets_603778;
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
  var query_603794 = newJObject()
  add(query_603794, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603794, "Action", newJString(Action))
  if Subnets != nil:
    query_603794.add "Subnets", Subnets
  add(query_603794, "Version", newJString(Version))
  result = call_603793.call(nil, query_603794, nil, nil, nil)

var getDetachLoadBalancerFromSubnets* = Call_GetDetachLoadBalancerFromSubnets_603778(
    name: "getDetachLoadBalancerFromSubnets", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DetachLoadBalancerFromSubnets",
    validator: validate_GetDetachLoadBalancerFromSubnets_603779, base: "/",
    url: url_GetDetachLoadBalancerFromSubnets_603780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDisableAvailabilityZonesForLoadBalancer_603830 = ref object of OpenApiRestCall_602466
proc url_PostDisableAvailabilityZonesForLoadBalancer_603832(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDisableAvailabilityZonesForLoadBalancer_603831(path: JsonNode;
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
  var valid_603833 = query.getOrDefault("Action")
  valid_603833 = validateParameter(valid_603833, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_603833 != nil:
    section.add "Action", valid_603833
  var valid_603834 = query.getOrDefault("Version")
  valid_603834 = validateParameter(valid_603834, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603834 != nil:
    section.add "Version", valid_603834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603835 = header.getOrDefault("X-Amz-Date")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Date", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Security-Token")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Security-Token", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Content-Sha256", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Algorithm")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Algorithm", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Signature")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Signature", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-SignedHeaders", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Credential")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Credential", valid_603841
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_603842 = formData.getOrDefault("AvailabilityZones")
  valid_603842 = validateParameter(valid_603842, JArray, required = true, default = nil)
  if valid_603842 != nil:
    section.add "AvailabilityZones", valid_603842
  var valid_603843 = formData.getOrDefault("LoadBalancerName")
  valid_603843 = validateParameter(valid_603843, JString, required = true,
                                 default = nil)
  if valid_603843 != nil:
    section.add "LoadBalancerName", valid_603843
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603844: Call_PostDisableAvailabilityZonesForLoadBalancer_603830;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603844.validator(path, query, header, formData, body)
  let scheme = call_603844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603844.url(scheme.get, call_603844.host, call_603844.base,
                         call_603844.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603844, url, valid)

proc call*(call_603845: Call_PostDisableAvailabilityZonesForLoadBalancer_603830;
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
  var query_603846 = newJObject()
  var formData_603847 = newJObject()
  add(query_603846, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_603847.add "AvailabilityZones", AvailabilityZones
  add(formData_603847, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603846, "Version", newJString(Version))
  result = call_603845.call(nil, query_603846, nil, formData_603847, nil)

var postDisableAvailabilityZonesForLoadBalancer* = Call_PostDisableAvailabilityZonesForLoadBalancer_603830(
    name: "postDisableAvailabilityZonesForLoadBalancer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_PostDisableAvailabilityZonesForLoadBalancer_603831,
    base: "/", url: url_PostDisableAvailabilityZonesForLoadBalancer_603832,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDisableAvailabilityZonesForLoadBalancer_603813 = ref object of OpenApiRestCall_602466
proc url_GetDisableAvailabilityZonesForLoadBalancer_603815(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDisableAvailabilityZonesForLoadBalancer_603814(path: JsonNode;
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
  var valid_603816 = query.getOrDefault("LoadBalancerName")
  valid_603816 = validateParameter(valid_603816, JString, required = true,
                                 default = nil)
  if valid_603816 != nil:
    section.add "LoadBalancerName", valid_603816
  var valid_603817 = query.getOrDefault("AvailabilityZones")
  valid_603817 = validateParameter(valid_603817, JArray, required = true, default = nil)
  if valid_603817 != nil:
    section.add "AvailabilityZones", valid_603817
  var valid_603818 = query.getOrDefault("Action")
  valid_603818 = validateParameter(valid_603818, JString, required = true, default = newJString(
      "DisableAvailabilityZonesForLoadBalancer"))
  if valid_603818 != nil:
    section.add "Action", valid_603818
  var valid_603819 = query.getOrDefault("Version")
  valid_603819 = validateParameter(valid_603819, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603819 != nil:
    section.add "Version", valid_603819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603820 = header.getOrDefault("X-Amz-Date")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-Date", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Security-Token")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Security-Token", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Content-Sha256", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-Algorithm")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Algorithm", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Signature")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Signature", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-SignedHeaders", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Credential")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Credential", valid_603826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603827: Call_GetDisableAvailabilityZonesForLoadBalancer_603813;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes the specified Availability Zones from the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>DetachLoadBalancerFromSubnets</a>.</p> <p>There must be at least one Availability Zone registered with a load balancer at all times. After an Availability Zone is removed, all instances registered with the load balancer that are in the removed Availability Zone go into the <code>OutOfService</code> state. Then, the load balancer attempts to equally balance the traffic among its remaining Availability Zones.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603827.validator(path, query, header, formData, body)
  let scheme = call_603827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603827.url(scheme.get, call_603827.host, call_603827.base,
                         call_603827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603827, url, valid)

proc call*(call_603828: Call_GetDisableAvailabilityZonesForLoadBalancer_603813;
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
  var query_603829 = newJObject()
  add(query_603829, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_603829.add "AvailabilityZones", AvailabilityZones
  add(query_603829, "Action", newJString(Action))
  add(query_603829, "Version", newJString(Version))
  result = call_603828.call(nil, query_603829, nil, nil, nil)

var getDisableAvailabilityZonesForLoadBalancer* = Call_GetDisableAvailabilityZonesForLoadBalancer_603813(
    name: "getDisableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=DisableAvailabilityZonesForLoadBalancer",
    validator: validate_GetDisableAvailabilityZonesForLoadBalancer_603814,
    base: "/", url: url_GetDisableAvailabilityZonesForLoadBalancer_603815,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostEnableAvailabilityZonesForLoadBalancer_603865 = ref object of OpenApiRestCall_602466
proc url_PostEnableAvailabilityZonesForLoadBalancer_603867(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostEnableAvailabilityZonesForLoadBalancer_603866(path: JsonNode;
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
  var valid_603868 = query.getOrDefault("Action")
  valid_603868 = validateParameter(valid_603868, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_603868 != nil:
    section.add "Action", valid_603868
  var valid_603869 = query.getOrDefault("Version")
  valid_603869 = validateParameter(valid_603869, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603869 != nil:
    section.add "Version", valid_603869
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603870 = header.getOrDefault("X-Amz-Date")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Date", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Security-Token")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Security-Token", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Content-Sha256", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Algorithm")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Algorithm", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Signature")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Signature", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-SignedHeaders", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-Credential")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-Credential", valid_603876
  result.add "header", section
  ## parameters in `formData` object:
  ##   AvailabilityZones: JArray (required)
  ##                    : The Availability Zones. These must be in the same region as the load balancer.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `AvailabilityZones` field"
  var valid_603877 = formData.getOrDefault("AvailabilityZones")
  valid_603877 = validateParameter(valid_603877, JArray, required = true, default = nil)
  if valid_603877 != nil:
    section.add "AvailabilityZones", valid_603877
  var valid_603878 = formData.getOrDefault("LoadBalancerName")
  valid_603878 = validateParameter(valid_603878, JString, required = true,
                                 default = nil)
  if valid_603878 != nil:
    section.add "LoadBalancerName", valid_603878
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603879: Call_PostEnableAvailabilityZonesForLoadBalancer_603865;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603879.validator(path, query, header, formData, body)
  let scheme = call_603879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603879.url(scheme.get, call_603879.host, call_603879.base,
                         call_603879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603879, url, valid)

proc call*(call_603880: Call_PostEnableAvailabilityZonesForLoadBalancer_603865;
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
  var query_603881 = newJObject()
  var formData_603882 = newJObject()
  add(query_603881, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_603882.add "AvailabilityZones", AvailabilityZones
  add(formData_603882, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603881, "Version", newJString(Version))
  result = call_603880.call(nil, query_603881, nil, formData_603882, nil)

var postEnableAvailabilityZonesForLoadBalancer* = Call_PostEnableAvailabilityZonesForLoadBalancer_603865(
    name: "postEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_PostEnableAvailabilityZonesForLoadBalancer_603866,
    base: "/", url: url_PostEnableAvailabilityZonesForLoadBalancer_603867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnableAvailabilityZonesForLoadBalancer_603848 = ref object of OpenApiRestCall_602466
proc url_GetEnableAvailabilityZonesForLoadBalancer_603850(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetEnableAvailabilityZonesForLoadBalancer_603849(path: JsonNode;
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
  var valid_603851 = query.getOrDefault("LoadBalancerName")
  valid_603851 = validateParameter(valid_603851, JString, required = true,
                                 default = nil)
  if valid_603851 != nil:
    section.add "LoadBalancerName", valid_603851
  var valid_603852 = query.getOrDefault("AvailabilityZones")
  valid_603852 = validateParameter(valid_603852, JArray, required = true, default = nil)
  if valid_603852 != nil:
    section.add "AvailabilityZones", valid_603852
  var valid_603853 = query.getOrDefault("Action")
  valid_603853 = validateParameter(valid_603853, JString, required = true, default = newJString(
      "EnableAvailabilityZonesForLoadBalancer"))
  if valid_603853 != nil:
    section.add "Action", valid_603853
  var valid_603854 = query.getOrDefault("Version")
  valid_603854 = validateParameter(valid_603854, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603854 != nil:
    section.add "Version", valid_603854
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603855 = header.getOrDefault("X-Amz-Date")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Date", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Security-Token")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Security-Token", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Content-Sha256", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Algorithm")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Algorithm", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Signature")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Signature", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-SignedHeaders", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-Credential")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-Credential", valid_603861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603862: Call_GetEnableAvailabilityZonesForLoadBalancer_603848;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified Availability Zones to the set of Availability Zones for the specified load balancer in EC2-Classic or a default VPC.</p> <p>For load balancers in a non-default VPC, use <a>AttachLoadBalancerToSubnets</a>.</p> <p>The load balancer evenly distributes requests across all its registered Availability Zones that contain instances. For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-az.html">Add or Remove Availability Zones</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603862.validator(path, query, header, formData, body)
  let scheme = call_603862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603862.url(scheme.get, call_603862.host, call_603862.base,
                         call_603862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603862, url, valid)

proc call*(call_603863: Call_GetEnableAvailabilityZonesForLoadBalancer_603848;
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
  var query_603864 = newJObject()
  add(query_603864, "LoadBalancerName", newJString(LoadBalancerName))
  if AvailabilityZones != nil:
    query_603864.add "AvailabilityZones", AvailabilityZones
  add(query_603864, "Action", newJString(Action))
  add(query_603864, "Version", newJString(Version))
  result = call_603863.call(nil, query_603864, nil, nil, nil)

var getEnableAvailabilityZonesForLoadBalancer* = Call_GetEnableAvailabilityZonesForLoadBalancer_603848(
    name: "getEnableAvailabilityZonesForLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=EnableAvailabilityZonesForLoadBalancer",
    validator: validate_GetEnableAvailabilityZonesForLoadBalancer_603849,
    base: "/", url: url_GetEnableAvailabilityZonesForLoadBalancer_603850,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyLoadBalancerAttributes_603904 = ref object of OpenApiRestCall_602466
proc url_PostModifyLoadBalancerAttributes_603906(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyLoadBalancerAttributes_603905(path: JsonNode;
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
  var valid_603907 = query.getOrDefault("Action")
  valid_603907 = validateParameter(valid_603907, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_603907 != nil:
    section.add "Action", valid_603907
  var valid_603908 = query.getOrDefault("Version")
  valid_603908 = validateParameter(valid_603908, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603908 != nil:
    section.add "Version", valid_603908
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603909 = header.getOrDefault("X-Amz-Date")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-Date", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Security-Token")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Security-Token", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Content-Sha256", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Algorithm")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Algorithm", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Signature")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Signature", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-SignedHeaders", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-Credential")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Credential", valid_603915
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
  var valid_603916 = formData.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_603916 = validateParameter(valid_603916, JArray, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_603916
  var valid_603917 = formData.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_603917
  var valid_603918 = formData.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_603918
  var valid_603919 = formData.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_603919
  assert formData != nil, "formData argument is necessary due to required `LoadBalancerName` field"
  var valid_603920 = formData.getOrDefault("LoadBalancerName")
  valid_603920 = validateParameter(valid_603920, JString, required = true,
                                 default = nil)
  if valid_603920 != nil:
    section.add "LoadBalancerName", valid_603920
  var valid_603921 = formData.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_603921
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603922: Call_PostModifyLoadBalancerAttributes_603904;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_603922.validator(path, query, header, formData, body)
  let scheme = call_603922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603922.url(scheme.get, call_603922.host, call_603922.base,
                         call_603922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603922, url, valid)

proc call*(call_603923: Call_PostModifyLoadBalancerAttributes_603904;
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
  var query_603924 = newJObject()
  var formData_603925 = newJObject()
  if LoadBalancerAttributesAdditionalAttributes != nil:
    formData_603925.add "LoadBalancerAttributes.AdditionalAttributes",
                       LoadBalancerAttributesAdditionalAttributes
  add(formData_603925, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  add(formData_603925, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_603924, "Action", newJString(Action))
  add(formData_603925, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(formData_603925, "LoadBalancerName", newJString(LoadBalancerName))
  add(formData_603925, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_603924, "Version", newJString(Version))
  result = call_603923.call(nil, query_603924, nil, formData_603925, nil)

var postModifyLoadBalancerAttributes* = Call_PostModifyLoadBalancerAttributes_603904(
    name: "postModifyLoadBalancerAttributes", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_PostModifyLoadBalancerAttributes_603905, base: "/",
    url: url_PostModifyLoadBalancerAttributes_603906,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyLoadBalancerAttributes_603883 = ref object of OpenApiRestCall_602466
proc url_GetModifyLoadBalancerAttributes_603885(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyLoadBalancerAttributes_603884(path: JsonNode;
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
  var valid_603886 = query.getOrDefault("LoadBalancerName")
  valid_603886 = validateParameter(valid_603886, JString, required = true,
                                 default = nil)
  if valid_603886 != nil:
    section.add "LoadBalancerName", valid_603886
  var valid_603887 = query.getOrDefault("LoadBalancerAttributes.AccessLog")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "LoadBalancerAttributes.AccessLog", valid_603887
  var valid_603888 = query.getOrDefault("LoadBalancerAttributes.CrossZoneLoadBalancing")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "LoadBalancerAttributes.CrossZoneLoadBalancing", valid_603888
  var valid_603889 = query.getOrDefault("LoadBalancerAttributes.AdditionalAttributes")
  valid_603889 = validateParameter(valid_603889, JArray, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "LoadBalancerAttributes.AdditionalAttributes", valid_603889
  var valid_603890 = query.getOrDefault("LoadBalancerAttributes.ConnectionSettings")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "LoadBalancerAttributes.ConnectionSettings", valid_603890
  var valid_603891 = query.getOrDefault("Action")
  valid_603891 = validateParameter(valid_603891, JString, required = true, default = newJString(
      "ModifyLoadBalancerAttributes"))
  if valid_603891 != nil:
    section.add "Action", valid_603891
  var valid_603892 = query.getOrDefault("LoadBalancerAttributes.ConnectionDraining")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "LoadBalancerAttributes.ConnectionDraining", valid_603892
  var valid_603893 = query.getOrDefault("Version")
  valid_603893 = validateParameter(valid_603893, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603893 != nil:
    section.add "Version", valid_603893
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603894 = header.getOrDefault("X-Amz-Date")
  valid_603894 = validateParameter(valid_603894, JString, required = false,
                                 default = nil)
  if valid_603894 != nil:
    section.add "X-Amz-Date", valid_603894
  var valid_603895 = header.getOrDefault("X-Amz-Security-Token")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-Security-Token", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Content-Sha256", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-Algorithm")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Algorithm", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Signature")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Signature", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-SignedHeaders", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-Credential")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Credential", valid_603900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603901: Call_GetModifyLoadBalancerAttributes_603883;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Modifies the attributes of the specified load balancer.</p> <p>You can modify the load balancer attributes, such as <code>AccessLogs</code>, <code>ConnectionDraining</code>, and <code>CrossZoneLoadBalancing</code> by either enabling or disabling them. Or, you can modify the load balancer attribute <code>ConnectionSettings</code> by specifying an idle connection timeout value for your load balancer.</p> <p>For more information, see the following in the <i>Classic Load Balancers Guide</i>:</p> <ul> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-disable-crosszone-lb.html">Cross-Zone Load Balancing</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-conn-drain.html">Connection Draining</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html">Access Logs</a> </p> </li> <li> <p> <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html">Idle Connection Timeout</a> </p> </li> </ul>
  ## 
  let valid = call_603901.validator(path, query, header, formData, body)
  let scheme = call_603901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603901.url(scheme.get, call_603901.host, call_603901.base,
                         call_603901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603901, url, valid)

proc call*(call_603902: Call_GetModifyLoadBalancerAttributes_603883;
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
  var query_603903 = newJObject()
  add(query_603903, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603903, "LoadBalancerAttributes.AccessLog",
      newJString(LoadBalancerAttributesAccessLog))
  add(query_603903, "LoadBalancerAttributes.CrossZoneLoadBalancing",
      newJString(LoadBalancerAttributesCrossZoneLoadBalancing))
  if LoadBalancerAttributesAdditionalAttributes != nil:
    query_603903.add "LoadBalancerAttributes.AdditionalAttributes",
                    LoadBalancerAttributesAdditionalAttributes
  add(query_603903, "LoadBalancerAttributes.ConnectionSettings",
      newJString(LoadBalancerAttributesConnectionSettings))
  add(query_603903, "Action", newJString(Action))
  add(query_603903, "LoadBalancerAttributes.ConnectionDraining",
      newJString(LoadBalancerAttributesConnectionDraining))
  add(query_603903, "Version", newJString(Version))
  result = call_603902.call(nil, query_603903, nil, nil, nil)

var getModifyLoadBalancerAttributes* = Call_GetModifyLoadBalancerAttributes_603883(
    name: "getModifyLoadBalancerAttributes", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=ModifyLoadBalancerAttributes",
    validator: validate_GetModifyLoadBalancerAttributes_603884, base: "/",
    url: url_GetModifyLoadBalancerAttributes_603885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRegisterInstancesWithLoadBalancer_603943 = ref object of OpenApiRestCall_602466
proc url_PostRegisterInstancesWithLoadBalancer_603945(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRegisterInstancesWithLoadBalancer_603944(path: JsonNode;
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
  var valid_603946 = query.getOrDefault("Action")
  valid_603946 = validateParameter(valid_603946, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_603946 != nil:
    section.add "Action", valid_603946
  var valid_603947 = query.getOrDefault("Version")
  valid_603947 = validateParameter(valid_603947, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603947 != nil:
    section.add "Version", valid_603947
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603948 = header.getOrDefault("X-Amz-Date")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "X-Amz-Date", valid_603948
  var valid_603949 = header.getOrDefault("X-Amz-Security-Token")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-Security-Token", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Content-Sha256", valid_603950
  var valid_603951 = header.getOrDefault("X-Amz-Algorithm")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "X-Amz-Algorithm", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Signature")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Signature", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-SignedHeaders", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Credential")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Credential", valid_603954
  result.add "header", section
  ## parameters in `formData` object:
  ##   Instances: JArray (required)
  ##            : The IDs of the instances.
  ##   LoadBalancerName: JString (required)
  ##                   : The name of the load balancer.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Instances` field"
  var valid_603955 = formData.getOrDefault("Instances")
  valid_603955 = validateParameter(valid_603955, JArray, required = true, default = nil)
  if valid_603955 != nil:
    section.add "Instances", valid_603955
  var valid_603956 = formData.getOrDefault("LoadBalancerName")
  valid_603956 = validateParameter(valid_603956, JString, required = true,
                                 default = nil)
  if valid_603956 != nil:
    section.add "LoadBalancerName", valid_603956
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603957: Call_PostRegisterInstancesWithLoadBalancer_603943;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603957.validator(path, query, header, formData, body)
  let scheme = call_603957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603957.url(scheme.get, call_603957.host, call_603957.base,
                         call_603957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603957, url, valid)

proc call*(call_603958: Call_PostRegisterInstancesWithLoadBalancer_603943;
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
  var query_603959 = newJObject()
  var formData_603960 = newJObject()
  if Instances != nil:
    formData_603960.add "Instances", Instances
  add(query_603959, "Action", newJString(Action))
  add(formData_603960, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603959, "Version", newJString(Version))
  result = call_603958.call(nil, query_603959, nil, formData_603960, nil)

var postRegisterInstancesWithLoadBalancer* = Call_PostRegisterInstancesWithLoadBalancer_603943(
    name: "postRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_PostRegisterInstancesWithLoadBalancer_603944, base: "/",
    url: url_PostRegisterInstancesWithLoadBalancer_603945,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegisterInstancesWithLoadBalancer_603926 = ref object of OpenApiRestCall_602466
proc url_GetRegisterInstancesWithLoadBalancer_603928(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRegisterInstancesWithLoadBalancer_603927(path: JsonNode;
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
  var valid_603929 = query.getOrDefault("LoadBalancerName")
  valid_603929 = validateParameter(valid_603929, JString, required = true,
                                 default = nil)
  if valid_603929 != nil:
    section.add "LoadBalancerName", valid_603929
  var valid_603930 = query.getOrDefault("Action")
  valid_603930 = validateParameter(valid_603930, JString, required = true, default = newJString(
      "RegisterInstancesWithLoadBalancer"))
  if valid_603930 != nil:
    section.add "Action", valid_603930
  var valid_603931 = query.getOrDefault("Instances")
  valid_603931 = validateParameter(valid_603931, JArray, required = true, default = nil)
  if valid_603931 != nil:
    section.add "Instances", valid_603931
  var valid_603932 = query.getOrDefault("Version")
  valid_603932 = validateParameter(valid_603932, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603932 != nil:
    section.add "Version", valid_603932
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603933 = header.getOrDefault("X-Amz-Date")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "X-Amz-Date", valid_603933
  var valid_603934 = header.getOrDefault("X-Amz-Security-Token")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-Security-Token", valid_603934
  var valid_603935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-Content-Sha256", valid_603935
  var valid_603936 = header.getOrDefault("X-Amz-Algorithm")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-Algorithm", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Signature")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Signature", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-SignedHeaders", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Credential")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Credential", valid_603939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603940: Call_GetRegisterInstancesWithLoadBalancer_603926;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds the specified instances to the specified load balancer.</p> <p>The instance must be a running instance in the same network as the load balancer (EC2-Classic or the same VPC). If you have EC2-Classic instances and a load balancer in a VPC with ClassicLink enabled, you can link the EC2-Classic instances to that VPC and then register the linked EC2-Classic instances with the load balancer in the VPC.</p> <p>Note that <code>RegisterInstanceWithLoadBalancer</code> completes when the request has been registered. Instance registration takes a little time to complete. To check the state of the registered instances, use <a>DescribeLoadBalancers</a> or <a>DescribeInstanceHealth</a>.</p> <p>After the instance is registered, it starts receiving traffic and requests from the load balancer. Any instance that is not in one of the Availability Zones registered for the load balancer is moved to the <code>OutOfService</code> state. If an Availability Zone is added to the load balancer later, any instances registered with the load balancer move to the <code>InService</code> state.</p> <p>To deregister instances from a load balancer, use <a>DeregisterInstancesFromLoadBalancer</a>.</p> <p>For more information, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-deregister-register-instances.html">Register or De-Register EC2 Instances</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_603940.validator(path, query, header, formData, body)
  let scheme = call_603940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603940.url(scheme.get, call_603940.host, call_603940.base,
                         call_603940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603940, url, valid)

proc call*(call_603941: Call_GetRegisterInstancesWithLoadBalancer_603926;
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
  var query_603942 = newJObject()
  add(query_603942, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_603942, "Action", newJString(Action))
  if Instances != nil:
    query_603942.add "Instances", Instances
  add(query_603942, "Version", newJString(Version))
  result = call_603941.call(nil, query_603942, nil, nil, nil)

var getRegisterInstancesWithLoadBalancer* = Call_GetRegisterInstancesWithLoadBalancer_603926(
    name: "getRegisterInstancesWithLoadBalancer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RegisterInstancesWithLoadBalancer",
    validator: validate_GetRegisterInstancesWithLoadBalancer_603927, base: "/",
    url: url_GetRegisterInstancesWithLoadBalancer_603928,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTags_603978 = ref object of OpenApiRestCall_602466
proc url_PostRemoveTags_603980(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTags_603979(path: JsonNode; query: JsonNode;
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
  var valid_603981 = query.getOrDefault("Action")
  valid_603981 = validateParameter(valid_603981, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_603981 != nil:
    section.add "Action", valid_603981
  var valid_603982 = query.getOrDefault("Version")
  valid_603982 = validateParameter(valid_603982, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603982 != nil:
    section.add "Version", valid_603982
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603983 = header.getOrDefault("X-Amz-Date")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Date", valid_603983
  var valid_603984 = header.getOrDefault("X-Amz-Security-Token")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Security-Token", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Content-Sha256", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Algorithm")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Algorithm", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Signature")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Signature", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-SignedHeaders", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-Credential")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Credential", valid_603989
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The list of tag keys to remove.
  ##   LoadBalancerNames: JArray (required)
  ##                    : The name of the load balancer. You can specify a maximum of one load balancer name.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_603990 = formData.getOrDefault("Tags")
  valid_603990 = validateParameter(valid_603990, JArray, required = true, default = nil)
  if valid_603990 != nil:
    section.add "Tags", valid_603990
  var valid_603991 = formData.getOrDefault("LoadBalancerNames")
  valid_603991 = validateParameter(valid_603991, JArray, required = true, default = nil)
  if valid_603991 != nil:
    section.add "LoadBalancerNames", valid_603991
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603992: Call_PostRemoveTags_603978; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_603992.validator(path, query, header, formData, body)
  let scheme = call_603992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603992.url(scheme.get, call_603992.host, call_603992.base,
                         call_603992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603992, url, valid)

proc call*(call_603993: Call_PostRemoveTags_603978; Tags: JsonNode;
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
  var query_603994 = newJObject()
  var formData_603995 = newJObject()
  if Tags != nil:
    formData_603995.add "Tags", Tags
  add(query_603994, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    formData_603995.add "LoadBalancerNames", LoadBalancerNames
  add(query_603994, "Version", newJString(Version))
  result = call_603993.call(nil, query_603994, nil, formData_603995, nil)

var postRemoveTags* = Call_PostRemoveTags_603978(name: "postRemoveTags",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_PostRemoveTags_603979,
    base: "/", url: url_PostRemoveTags_603980, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTags_603961 = ref object of OpenApiRestCall_602466
proc url_GetRemoveTags_603963(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTags_603962(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603964 = query.getOrDefault("Tags")
  valid_603964 = validateParameter(valid_603964, JArray, required = true, default = nil)
  if valid_603964 != nil:
    section.add "Tags", valid_603964
  var valid_603965 = query.getOrDefault("Action")
  valid_603965 = validateParameter(valid_603965, JString, required = true,
                                 default = newJString("RemoveTags"))
  if valid_603965 != nil:
    section.add "Action", valid_603965
  var valid_603966 = query.getOrDefault("LoadBalancerNames")
  valid_603966 = validateParameter(valid_603966, JArray, required = true, default = nil)
  if valid_603966 != nil:
    section.add "LoadBalancerNames", valid_603966
  var valid_603967 = query.getOrDefault("Version")
  valid_603967 = validateParameter(valid_603967, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_603967 != nil:
    section.add "Version", valid_603967
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603968 = header.getOrDefault("X-Amz-Date")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "X-Amz-Date", valid_603968
  var valid_603969 = header.getOrDefault("X-Amz-Security-Token")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Security-Token", valid_603969
  var valid_603970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-Content-Sha256", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Algorithm")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Algorithm", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-Signature")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-Signature", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-SignedHeaders", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-Credential")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-Credential", valid_603974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603975: Call_GetRemoveTags_603961; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified load balancer.
  ## 
  let valid = call_603975.validator(path, query, header, formData, body)
  let scheme = call_603975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603975.url(scheme.get, call_603975.host, call_603975.base,
                         call_603975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603975, url, valid)

proc call*(call_603976: Call_GetRemoveTags_603961; Tags: JsonNode;
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
  var query_603977 = newJObject()
  if Tags != nil:
    query_603977.add "Tags", Tags
  add(query_603977, "Action", newJString(Action))
  if LoadBalancerNames != nil:
    query_603977.add "LoadBalancerNames", LoadBalancerNames
  add(query_603977, "Version", newJString(Version))
  result = call_603976.call(nil, query_603977, nil, nil, nil)

var getRemoveTags* = Call_GetRemoveTags_603961(name: "getRemoveTags",
    meth: HttpMethod.HttpGet, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=RemoveTags", validator: validate_GetRemoveTags_603962,
    base: "/", url: url_GetRemoveTags_603963, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerListenerSSLCertificate_604014 = ref object of OpenApiRestCall_602466
proc url_PostSetLoadBalancerListenerSSLCertificate_604016(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetLoadBalancerListenerSSLCertificate_604015(path: JsonNode;
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
  var valid_604017 = query.getOrDefault("Action")
  valid_604017 = validateParameter(valid_604017, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_604017 != nil:
    section.add "Action", valid_604017
  var valid_604018 = query.getOrDefault("Version")
  valid_604018 = validateParameter(valid_604018, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_604018 != nil:
    section.add "Version", valid_604018
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604019 = header.getOrDefault("X-Amz-Date")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-Date", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-Security-Token")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Security-Token", valid_604020
  var valid_604021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-Content-Sha256", valid_604021
  var valid_604022 = header.getOrDefault("X-Amz-Algorithm")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-Algorithm", valid_604022
  var valid_604023 = header.getOrDefault("X-Amz-Signature")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "X-Amz-Signature", valid_604023
  var valid_604024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-SignedHeaders", valid_604024
  var valid_604025 = header.getOrDefault("X-Amz-Credential")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Credential", valid_604025
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
  var valid_604026 = formData.getOrDefault("LoadBalancerPort")
  valid_604026 = validateParameter(valid_604026, JInt, required = true, default = nil)
  if valid_604026 != nil:
    section.add "LoadBalancerPort", valid_604026
  var valid_604027 = formData.getOrDefault("SSLCertificateId")
  valid_604027 = validateParameter(valid_604027, JString, required = true,
                                 default = nil)
  if valid_604027 != nil:
    section.add "SSLCertificateId", valid_604027
  var valid_604028 = formData.getOrDefault("LoadBalancerName")
  valid_604028 = validateParameter(valid_604028, JString, required = true,
                                 default = nil)
  if valid_604028 != nil:
    section.add "LoadBalancerName", valid_604028
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604029: Call_PostSetLoadBalancerListenerSSLCertificate_604014;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_604029.validator(path, query, header, formData, body)
  let scheme = call_604029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604029.url(scheme.get, call_604029.host, call_604029.base,
                         call_604029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604029, url, valid)

proc call*(call_604030: Call_PostSetLoadBalancerListenerSSLCertificate_604014;
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
  var query_604031 = newJObject()
  var formData_604032 = newJObject()
  add(formData_604032, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(formData_604032, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_604031, "Action", newJString(Action))
  add(formData_604032, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_604031, "Version", newJString(Version))
  result = call_604030.call(nil, query_604031, nil, formData_604032, nil)

var postSetLoadBalancerListenerSSLCertificate* = Call_PostSetLoadBalancerListenerSSLCertificate_604014(
    name: "postSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_PostSetLoadBalancerListenerSSLCertificate_604015,
    base: "/", url: url_PostSetLoadBalancerListenerSSLCertificate_604016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerListenerSSLCertificate_603996 = ref object of OpenApiRestCall_602466
proc url_GetSetLoadBalancerListenerSSLCertificate_603998(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetLoadBalancerListenerSSLCertificate_603997(path: JsonNode;
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
  var valid_603999 = query.getOrDefault("LoadBalancerName")
  valid_603999 = validateParameter(valid_603999, JString, required = true,
                                 default = nil)
  if valid_603999 != nil:
    section.add "LoadBalancerName", valid_603999
  var valid_604000 = query.getOrDefault("SSLCertificateId")
  valid_604000 = validateParameter(valid_604000, JString, required = true,
                                 default = nil)
  if valid_604000 != nil:
    section.add "SSLCertificateId", valid_604000
  var valid_604001 = query.getOrDefault("LoadBalancerPort")
  valid_604001 = validateParameter(valid_604001, JInt, required = true, default = nil)
  if valid_604001 != nil:
    section.add "LoadBalancerPort", valid_604001
  var valid_604002 = query.getOrDefault("Action")
  valid_604002 = validateParameter(valid_604002, JString, required = true, default = newJString(
      "SetLoadBalancerListenerSSLCertificate"))
  if valid_604002 != nil:
    section.add "Action", valid_604002
  var valid_604003 = query.getOrDefault("Version")
  valid_604003 = validateParameter(valid_604003, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_604003 != nil:
    section.add "Version", valid_604003
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604004 = header.getOrDefault("X-Amz-Date")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Date", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-Security-Token")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Security-Token", valid_604005
  var valid_604006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-Content-Sha256", valid_604006
  var valid_604007 = header.getOrDefault("X-Amz-Algorithm")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "X-Amz-Algorithm", valid_604007
  var valid_604008 = header.getOrDefault("X-Amz-Signature")
  valid_604008 = validateParameter(valid_604008, JString, required = false,
                                 default = nil)
  if valid_604008 != nil:
    section.add "X-Amz-Signature", valid_604008
  var valid_604009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604009 = validateParameter(valid_604009, JString, required = false,
                                 default = nil)
  if valid_604009 != nil:
    section.add "X-Amz-SignedHeaders", valid_604009
  var valid_604010 = header.getOrDefault("X-Amz-Credential")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = nil)
  if valid_604010 != nil:
    section.add "X-Amz-Credential", valid_604010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604011: Call_GetSetLoadBalancerListenerSSLCertificate_603996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Sets the certificate that terminates the specified listener's SSL connections. The specified certificate replaces any prior certificate that was used on the same load balancer and port.</p> <p>For more information about updating your SSL certificate, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-update-ssl-cert.html">Replace the SSL Certificate for Your Load Balancer</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_604011.validator(path, query, header, formData, body)
  let scheme = call_604011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604011.url(scheme.get, call_604011.host, call_604011.base,
                         call_604011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604011, url, valid)

proc call*(call_604012: Call_GetSetLoadBalancerListenerSSLCertificate_603996;
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
  var query_604013 = newJObject()
  add(query_604013, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_604013, "SSLCertificateId", newJString(SSLCertificateId))
  add(query_604013, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_604013, "Action", newJString(Action))
  add(query_604013, "Version", newJString(Version))
  result = call_604012.call(nil, query_604013, nil, nil, nil)

var getSetLoadBalancerListenerSSLCertificate* = Call_GetSetLoadBalancerListenerSSLCertificate_603996(
    name: "getSetLoadBalancerListenerSSLCertificate", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerListenerSSLCertificate",
    validator: validate_GetSetLoadBalancerListenerSSLCertificate_603997,
    base: "/", url: url_GetSetLoadBalancerListenerSSLCertificate_603998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesForBackendServer_604051 = ref object of OpenApiRestCall_602466
proc url_PostSetLoadBalancerPoliciesForBackendServer_604053(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetLoadBalancerPoliciesForBackendServer_604052(path: JsonNode;
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
  var valid_604054 = query.getOrDefault("Action")
  valid_604054 = validateParameter(valid_604054, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_604054 != nil:
    section.add "Action", valid_604054
  var valid_604055 = query.getOrDefault("Version")
  valid_604055 = validateParameter(valid_604055, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_604055 != nil:
    section.add "Version", valid_604055
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604056 = header.getOrDefault("X-Amz-Date")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "X-Amz-Date", valid_604056
  var valid_604057 = header.getOrDefault("X-Amz-Security-Token")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-Security-Token", valid_604057
  var valid_604058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "X-Amz-Content-Sha256", valid_604058
  var valid_604059 = header.getOrDefault("X-Amz-Algorithm")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "X-Amz-Algorithm", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-Signature")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-Signature", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-SignedHeaders", valid_604061
  var valid_604062 = header.getOrDefault("X-Amz-Credential")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "X-Amz-Credential", valid_604062
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
  var valid_604063 = formData.getOrDefault("PolicyNames")
  valid_604063 = validateParameter(valid_604063, JArray, required = true, default = nil)
  if valid_604063 != nil:
    section.add "PolicyNames", valid_604063
  var valid_604064 = formData.getOrDefault("InstancePort")
  valid_604064 = validateParameter(valid_604064, JInt, required = true, default = nil)
  if valid_604064 != nil:
    section.add "InstancePort", valid_604064
  var valid_604065 = formData.getOrDefault("LoadBalancerName")
  valid_604065 = validateParameter(valid_604065, JString, required = true,
                                 default = nil)
  if valid_604065 != nil:
    section.add "LoadBalancerName", valid_604065
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604066: Call_PostSetLoadBalancerPoliciesForBackendServer_604051;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_604066.validator(path, query, header, formData, body)
  let scheme = call_604066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604066.url(scheme.get, call_604066.host, call_604066.base,
                         call_604066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604066, url, valid)

proc call*(call_604067: Call_PostSetLoadBalancerPoliciesForBackendServer_604051;
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
  var query_604068 = newJObject()
  var formData_604069 = newJObject()
  if PolicyNames != nil:
    formData_604069.add "PolicyNames", PolicyNames
  add(formData_604069, "InstancePort", newJInt(InstancePort))
  add(query_604068, "Action", newJString(Action))
  add(formData_604069, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_604068, "Version", newJString(Version))
  result = call_604067.call(nil, query_604068, nil, formData_604069, nil)

var postSetLoadBalancerPoliciesForBackendServer* = Call_PostSetLoadBalancerPoliciesForBackendServer_604051(
    name: "postSetLoadBalancerPoliciesForBackendServer",
    meth: HttpMethod.HttpPost, host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_PostSetLoadBalancerPoliciesForBackendServer_604052,
    base: "/", url: url_PostSetLoadBalancerPoliciesForBackendServer_604053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesForBackendServer_604033 = ref object of OpenApiRestCall_602466
proc url_GetSetLoadBalancerPoliciesForBackendServer_604035(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetLoadBalancerPoliciesForBackendServer_604034(path: JsonNode;
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
  var valid_604036 = query.getOrDefault("LoadBalancerName")
  valid_604036 = validateParameter(valid_604036, JString, required = true,
                                 default = nil)
  if valid_604036 != nil:
    section.add "LoadBalancerName", valid_604036
  var valid_604037 = query.getOrDefault("Action")
  valid_604037 = validateParameter(valid_604037, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesForBackendServer"))
  if valid_604037 != nil:
    section.add "Action", valid_604037
  var valid_604038 = query.getOrDefault("PolicyNames")
  valid_604038 = validateParameter(valid_604038, JArray, required = true, default = nil)
  if valid_604038 != nil:
    section.add "PolicyNames", valid_604038
  var valid_604039 = query.getOrDefault("Version")
  valid_604039 = validateParameter(valid_604039, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_604039 != nil:
    section.add "Version", valid_604039
  var valid_604040 = query.getOrDefault("InstancePort")
  valid_604040 = validateParameter(valid_604040, JInt, required = true, default = nil)
  if valid_604040 != nil:
    section.add "InstancePort", valid_604040
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604041 = header.getOrDefault("X-Amz-Date")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-Date", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Security-Token")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Security-Token", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Content-Sha256", valid_604043
  var valid_604044 = header.getOrDefault("X-Amz-Algorithm")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-Algorithm", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-Signature")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-Signature", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-SignedHeaders", valid_604046
  var valid_604047 = header.getOrDefault("X-Amz-Credential")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "X-Amz-Credential", valid_604047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604048: Call_GetSetLoadBalancerPoliciesForBackendServer_604033;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the set of policies associated with the specified port on which the EC2 instance is listening with a new set of policies. At this time, only the back-end server authentication policy type can be applied to the instance ports; this policy type is composed of multiple public key policies.</p> <p>Each time you use <code>SetLoadBalancerPoliciesForBackendServer</code> to enable the policies, use the <code>PolicyNames</code> parameter to list the policies that you want to enable.</p> <p>You can use <a>DescribeLoadBalancers</a> or <a>DescribeLoadBalancerPolicies</a> to verify that the policy is associated with the EC2 instance.</p> <p>For more information about enabling back-end instance authentication, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-create-https-ssl-load-balancer.html#configure_backendauth_clt">Configure Back-end Instance Authentication</a> in the <i>Classic Load Balancers Guide</i>. For more information about Proxy Protocol, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html">Configure Proxy Protocol Support</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_604048.validator(path, query, header, formData, body)
  let scheme = call_604048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604048.url(scheme.get, call_604048.host, call_604048.base,
                         call_604048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604048, url, valid)

proc call*(call_604049: Call_GetSetLoadBalancerPoliciesForBackendServer_604033;
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
  var query_604050 = newJObject()
  add(query_604050, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_604050, "Action", newJString(Action))
  if PolicyNames != nil:
    query_604050.add "PolicyNames", PolicyNames
  add(query_604050, "Version", newJString(Version))
  add(query_604050, "InstancePort", newJInt(InstancePort))
  result = call_604049.call(nil, query_604050, nil, nil, nil)

var getSetLoadBalancerPoliciesForBackendServer* = Call_GetSetLoadBalancerPoliciesForBackendServer_604033(
    name: "getSetLoadBalancerPoliciesForBackendServer", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesForBackendServer",
    validator: validate_GetSetLoadBalancerPoliciesForBackendServer_604034,
    base: "/", url: url_GetSetLoadBalancerPoliciesForBackendServer_604035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetLoadBalancerPoliciesOfListener_604088 = ref object of OpenApiRestCall_602466
proc url_PostSetLoadBalancerPoliciesOfListener_604090(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetLoadBalancerPoliciesOfListener_604089(path: JsonNode;
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
  var valid_604091 = query.getOrDefault("Action")
  valid_604091 = validateParameter(valid_604091, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_604091 != nil:
    section.add "Action", valid_604091
  var valid_604092 = query.getOrDefault("Version")
  valid_604092 = validateParameter(valid_604092, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_604092 != nil:
    section.add "Version", valid_604092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604093 = header.getOrDefault("X-Amz-Date")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-Date", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-Security-Token")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Security-Token", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Content-Sha256", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-Algorithm")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Algorithm", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-Signature")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-Signature", valid_604097
  var valid_604098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-SignedHeaders", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-Credential")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Credential", valid_604099
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
  var valid_604100 = formData.getOrDefault("LoadBalancerPort")
  valid_604100 = validateParameter(valid_604100, JInt, required = true, default = nil)
  if valid_604100 != nil:
    section.add "LoadBalancerPort", valid_604100
  var valid_604101 = formData.getOrDefault("PolicyNames")
  valid_604101 = validateParameter(valid_604101, JArray, required = true, default = nil)
  if valid_604101 != nil:
    section.add "PolicyNames", valid_604101
  var valid_604102 = formData.getOrDefault("LoadBalancerName")
  valid_604102 = validateParameter(valid_604102, JString, required = true,
                                 default = nil)
  if valid_604102 != nil:
    section.add "LoadBalancerName", valid_604102
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604103: Call_PostSetLoadBalancerPoliciesOfListener_604088;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_604103.validator(path, query, header, formData, body)
  let scheme = call_604103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604103.url(scheme.get, call_604103.host, call_604103.base,
                         call_604103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604103, url, valid)

proc call*(call_604104: Call_PostSetLoadBalancerPoliciesOfListener_604088;
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
  var query_604105 = newJObject()
  var formData_604106 = newJObject()
  add(formData_604106, "LoadBalancerPort", newJInt(LoadBalancerPort))
  if PolicyNames != nil:
    formData_604106.add "PolicyNames", PolicyNames
  add(query_604105, "Action", newJString(Action))
  add(formData_604106, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_604105, "Version", newJString(Version))
  result = call_604104.call(nil, query_604105, nil, formData_604106, nil)

var postSetLoadBalancerPoliciesOfListener* = Call_PostSetLoadBalancerPoliciesOfListener_604088(
    name: "postSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpPost,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_PostSetLoadBalancerPoliciesOfListener_604089, base: "/",
    url: url_PostSetLoadBalancerPoliciesOfListener_604090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetLoadBalancerPoliciesOfListener_604070 = ref object of OpenApiRestCall_602466
proc url_GetSetLoadBalancerPoliciesOfListener_604072(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetLoadBalancerPoliciesOfListener_604071(path: JsonNode;
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
  var valid_604073 = query.getOrDefault("LoadBalancerName")
  valid_604073 = validateParameter(valid_604073, JString, required = true,
                                 default = nil)
  if valid_604073 != nil:
    section.add "LoadBalancerName", valid_604073
  var valid_604074 = query.getOrDefault("LoadBalancerPort")
  valid_604074 = validateParameter(valid_604074, JInt, required = true, default = nil)
  if valid_604074 != nil:
    section.add "LoadBalancerPort", valid_604074
  var valid_604075 = query.getOrDefault("Action")
  valid_604075 = validateParameter(valid_604075, JString, required = true, default = newJString(
      "SetLoadBalancerPoliciesOfListener"))
  if valid_604075 != nil:
    section.add "Action", valid_604075
  var valid_604076 = query.getOrDefault("PolicyNames")
  valid_604076 = validateParameter(valid_604076, JArray, required = true, default = nil)
  if valid_604076 != nil:
    section.add "PolicyNames", valid_604076
  var valid_604077 = query.getOrDefault("Version")
  valid_604077 = validateParameter(valid_604077, JString, required = true,
                                 default = newJString("2012-06-01"))
  if valid_604077 != nil:
    section.add "Version", valid_604077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604078 = header.getOrDefault("X-Amz-Date")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Date", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Security-Token")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Security-Token", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-Content-Sha256", valid_604080
  var valid_604081 = header.getOrDefault("X-Amz-Algorithm")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-Algorithm", valid_604081
  var valid_604082 = header.getOrDefault("X-Amz-Signature")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "X-Amz-Signature", valid_604082
  var valid_604083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604083 = validateParameter(valid_604083, JString, required = false,
                                 default = nil)
  if valid_604083 != nil:
    section.add "X-Amz-SignedHeaders", valid_604083
  var valid_604084 = header.getOrDefault("X-Amz-Credential")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-Credential", valid_604084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604085: Call_GetSetLoadBalancerPoliciesOfListener_604070;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Replaces the current set of policies for the specified load balancer port with the specified set of policies.</p> <p>To enable back-end server authentication, use <a>SetLoadBalancerPoliciesForBackendServer</a>.</p> <p>For more information about setting policies, see <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-config-update.html">Update the SSL Negotiation Configuration</a>, <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-duration">Duration-Based Session Stickiness</a>, and <a href="http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html#enable-sticky-sessions-application">Application-Controlled Session Stickiness</a> in the <i>Classic Load Balancers Guide</i>.</p>
  ## 
  let valid = call_604085.validator(path, query, header, formData, body)
  let scheme = call_604085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604085.url(scheme.get, call_604085.host, call_604085.base,
                         call_604085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604085, url, valid)

proc call*(call_604086: Call_GetSetLoadBalancerPoliciesOfListener_604070;
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
  var query_604087 = newJObject()
  add(query_604087, "LoadBalancerName", newJString(LoadBalancerName))
  add(query_604087, "LoadBalancerPort", newJInt(LoadBalancerPort))
  add(query_604087, "Action", newJString(Action))
  if PolicyNames != nil:
    query_604087.add "PolicyNames", PolicyNames
  add(query_604087, "Version", newJString(Version))
  result = call_604086.call(nil, query_604087, nil, nil, nil)

var getSetLoadBalancerPoliciesOfListener* = Call_GetSetLoadBalancerPoliciesOfListener_604070(
    name: "getSetLoadBalancerPoliciesOfListener", meth: HttpMethod.HttpGet,
    host: "elasticloadbalancing.amazonaws.com",
    route: "/#Action=SetLoadBalancerPoliciesOfListener",
    validator: validate_GetSetLoadBalancerPoliciesOfListener_604071, base: "/",
    url: url_GetSetLoadBalancerPoliciesOfListener_604072,
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
