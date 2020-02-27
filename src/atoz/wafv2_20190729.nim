
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

## auto-generated via openapi macro
## title: AWS WAFV2
## version: 2019-07-29
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <note> <p>This is the latest version of the <b>AWS WAF</b> API, released in November, 2019. The names of the entities that you use to access this API, like endpoints and namespaces, all have the versioning information added, like "V2" or "v2", to distinguish from the prior version. We recommend migrating your resources to this version, because it has a number of significant improvements.</p> <p>If you used AWS WAF prior to this release, you can't use this AWS WAFV2 API to access any AWS WAF resources that you created before. You can access your old rules, web ACLs, and other AWS WAF resources only through the AWS WAF Classic APIs. The AWS WAF Classic APIs have retained the prior names, endpoints, and namespaces. </p> <p>For information, including how to migrate your AWS WAF resources to this version, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>AWS WAF is a web application firewall that lets you monitor the HTTP and HTTPS requests that are forwarded to Amazon CloudFront, an Amazon API Gateway API, or an Application Load Balancer. AWS WAF also lets you control access to your content. Based on conditions that you specify, such as the IP addresses that requests originate from or the values of query strings, API Gateway, CloudFront, or the Application Load Balancer responds to requests either with the requested content or with an HTTP 403 status code (Forbidden). You also can configure CloudFront to return a custom error page when a request is blocked.</p> <p>This API guide is for developers who need detailed information about AWS WAF API actions, data types, and errors. For detailed information about AWS WAF features and an overview of how to use AWS WAF, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p> <p>You can make API calls using the endpoints listed in <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#waf_region">AWS Service Endpoints for AWS WAF</a>. </p> <ul> <li> <p>For regional applications, you can use any of the endpoints in the list. A regional application can be an Application Load Balancer (ALB) or an API Gateway stage. </p> </li> <li> <p>For AWS CloudFront applications, you must use the API endpoint listed for US East (N. Virginia): us-east-1.</p> </li> </ul> <p>Alternatively, you can use one of the AWS SDKs to access an API that's tailored to the programming language or platform that you're using. For more information, see <a href="http://aws.amazon.com/tools/#SDKs">AWS SDKs</a>.</p> <p>We currently provide two versions of the AWS WAF API: this API and the prior versions, the classic AWS WAF APIs. This new API provides the same functionality as the older versions, with the following major improvements:</p> <ul> <li> <p>You use one API for both global and regional applications. Where you need to distinguish the scope, you specify a <code>Scope</code> parameter and set it to <code>CLOUDFRONT</code> or <code>REGIONAL</code>. </p> </li> <li> <p>You can define a Web ACL or rule group with a single API call, and update it with a single call. You define all rule specifications in JSON format, and pass them to your rule group or Web ACL API calls.</p> </li> <li> <p>The limits AWS WAF places on the use of rules more closely reflects the cost of running each type of rule. Rule groups include capacity settings, so you know the maximum cost of a rule group when you use it.</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/wafv2/
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
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616866 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616866](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616866): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "wafv2.ap-northeast-1.amazonaws.com", "ap-southeast-1": "wafv2.ap-southeast-1.amazonaws.com",
                           "us-west-2": "wafv2.us-west-2.amazonaws.com",
                           "eu-west-2": "wafv2.eu-west-2.amazonaws.com", "ap-northeast-3": "wafv2.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "wafv2.eu-central-1.amazonaws.com",
                           "us-east-2": "wafv2.us-east-2.amazonaws.com",
                           "us-east-1": "wafv2.us-east-1.amazonaws.com", "cn-northwest-1": "wafv2.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "wafv2.ap-northeast-2.amazonaws.com",
                           "ap-south-1": "wafv2.ap-south-1.amazonaws.com",
                           "eu-north-1": "wafv2.eu-north-1.amazonaws.com",
                           "us-west-1": "wafv2.us-west-1.amazonaws.com", "us-gov-east-1": "wafv2.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "wafv2.eu-west-3.amazonaws.com",
                           "cn-north-1": "wafv2.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "wafv2.sa-east-1.amazonaws.com",
                           "eu-west-1": "wafv2.eu-west-1.amazonaws.com", "us-gov-west-1": "wafv2.us-gov-west-1.amazonaws.com", "ap-southeast-2": "wafv2.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "wafv2.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "wafv2.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "wafv2.ap-southeast-1.amazonaws.com",
      "us-west-2": "wafv2.us-west-2.amazonaws.com",
      "eu-west-2": "wafv2.eu-west-2.amazonaws.com",
      "ap-northeast-3": "wafv2.ap-northeast-3.amazonaws.com",
      "eu-central-1": "wafv2.eu-central-1.amazonaws.com",
      "us-east-2": "wafv2.us-east-2.amazonaws.com",
      "us-east-1": "wafv2.us-east-1.amazonaws.com",
      "cn-northwest-1": "wafv2.cn-northwest-1.amazonaws.com.cn",
      "ap-northeast-2": "wafv2.ap-northeast-2.amazonaws.com",
      "ap-south-1": "wafv2.ap-south-1.amazonaws.com",
      "eu-north-1": "wafv2.eu-north-1.amazonaws.com",
      "us-west-1": "wafv2.us-west-1.amazonaws.com",
      "us-gov-east-1": "wafv2.us-gov-east-1.amazonaws.com",
      "eu-west-3": "wafv2.eu-west-3.amazonaws.com",
      "cn-north-1": "wafv2.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "wafv2.sa-east-1.amazonaws.com",
      "eu-west-1": "wafv2.eu-west-1.amazonaws.com",
      "us-gov-west-1": "wafv2.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "wafv2.ap-southeast-2.amazonaws.com",
      "ca-central-1": "wafv2.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "wafv2"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AssociateWebACL_617205 = ref object of OpenApiRestCall_616866
proc url_AssociateWebACL_617207(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateWebACL_617206(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Associates a Web ACL with a regional application resource, to protect the resource. A regional application can be an Application Load Balancer (ALB) or an API Gateway stage. </p> <p>For AWS CloudFront, you can associate the Web ACL by providing the <code>ARN</code> of the <a>WebACL</a> to the CloudFront API call <code>UpdateDistribution</code>. For information, see <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617319 = header.getOrDefault("X-Amz-Date")
  valid_617319 = validateParameter(valid_617319, JString, required = false,
                                 default = nil)
  if valid_617319 != nil:
    section.add "X-Amz-Date", valid_617319
  var valid_617320 = header.getOrDefault("X-Amz-Security-Token")
  valid_617320 = validateParameter(valid_617320, JString, required = false,
                                 default = nil)
  if valid_617320 != nil:
    section.add "X-Amz-Security-Token", valid_617320
  var valid_617321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617321 = validateParameter(valid_617321, JString, required = false,
                                 default = nil)
  if valid_617321 != nil:
    section.add "X-Amz-Content-Sha256", valid_617321
  var valid_617322 = header.getOrDefault("X-Amz-Algorithm")
  valid_617322 = validateParameter(valid_617322, JString, required = false,
                                 default = nil)
  if valid_617322 != nil:
    section.add "X-Amz-Algorithm", valid_617322
  var valid_617323 = header.getOrDefault("X-Amz-Signature")
  valid_617323 = validateParameter(valid_617323, JString, required = false,
                                 default = nil)
  if valid_617323 != nil:
    section.add "X-Amz-Signature", valid_617323
  var valid_617324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617324 = validateParameter(valid_617324, JString, required = false,
                                 default = nil)
  if valid_617324 != nil:
    section.add "X-Amz-SignedHeaders", valid_617324
  var valid_617338 = header.getOrDefault("X-Amz-Target")
  valid_617338 = validateParameter(valid_617338, JString, required = true, default = newJString(
      "AWSWAF_20190729.AssociateWebACL"))
  if valid_617338 != nil:
    section.add "X-Amz-Target", valid_617338
  var valid_617339 = header.getOrDefault("X-Amz-Credential")
  valid_617339 = validateParameter(valid_617339, JString, required = false,
                                 default = nil)
  if valid_617339 != nil:
    section.add "X-Amz-Credential", valid_617339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617364: Call_AssociateWebACL_617205; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Associates a Web ACL with a regional application resource, to protect the resource. A regional application can be an Application Load Balancer (ALB) or an API Gateway stage. </p> <p>For AWS CloudFront, you can associate the Web ACL by providing the <code>ARN</code> of the <a>WebACL</a> to the CloudFront API call <code>UpdateDistribution</code>. For information, see <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>.</p>
  ## 
  let valid = call_617364.validator(path, query, header, formData, body, _)
  let scheme = call_617364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617364.url(scheme.get, call_617364.host, call_617364.base,
                         call_617364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617364, url, valid, _)

proc call*(call_617435: Call_AssociateWebACL_617205; body: JsonNode): Recallable =
  ## associateWebACL
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Associates a Web ACL with a regional application resource, to protect the resource. A regional application can be an Application Load Balancer (ALB) or an API Gateway stage. </p> <p>For AWS CloudFront, you can associate the Web ACL by providing the <code>ARN</code> of the <a>WebACL</a> to the CloudFront API call <code>UpdateDistribution</code>. For information, see <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>.</p>
  ##   body: JObject (required)
  var body_617436 = newJObject()
  if body != nil:
    body_617436 = body
  result = call_617435.call(nil, nil, nil, nil, body_617436)

var associateWebACL* = Call_AssociateWebACL_617205(name: "associateWebACL",
    meth: HttpMethod.HttpPost, host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.AssociateWebACL",
    validator: validate_AssociateWebACL_617206, base: "/", url: url_AssociateWebACL_617207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CheckCapacity_617477 = ref object of OpenApiRestCall_616866
proc url_CheckCapacity_617479(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CheckCapacity_617478(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Returns the web ACL capacity unit (WCU) requirements for a specified scope and set of rules. You can use this to check the capacity requirements for the rules you want to use in a <a>RuleGroup</a> or <a>WebACL</a>. </p> <p>AWS WAF uses WCUs to calculate and control the operating resources that are used to run your rules, rule groups, and web ACLs. AWS WAF calculates capacity differently for each rule type, to reflect the relative cost of each rule. Simple rules that cost little to run use fewer WCUs than more complex rules that use more processing power. Rule group capacity is fixed at creation, which helps users plan their web ACL WCU usage when they use a rule group. The WCU limit for web ACLs is 1,500. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617480 = header.getOrDefault("X-Amz-Date")
  valid_617480 = validateParameter(valid_617480, JString, required = false,
                                 default = nil)
  if valid_617480 != nil:
    section.add "X-Amz-Date", valid_617480
  var valid_617481 = header.getOrDefault("X-Amz-Security-Token")
  valid_617481 = validateParameter(valid_617481, JString, required = false,
                                 default = nil)
  if valid_617481 != nil:
    section.add "X-Amz-Security-Token", valid_617481
  var valid_617482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617482 = validateParameter(valid_617482, JString, required = false,
                                 default = nil)
  if valid_617482 != nil:
    section.add "X-Amz-Content-Sha256", valid_617482
  var valid_617483 = header.getOrDefault("X-Amz-Algorithm")
  valid_617483 = validateParameter(valid_617483, JString, required = false,
                                 default = nil)
  if valid_617483 != nil:
    section.add "X-Amz-Algorithm", valid_617483
  var valid_617484 = header.getOrDefault("X-Amz-Signature")
  valid_617484 = validateParameter(valid_617484, JString, required = false,
                                 default = nil)
  if valid_617484 != nil:
    section.add "X-Amz-Signature", valid_617484
  var valid_617485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617485 = validateParameter(valid_617485, JString, required = false,
                                 default = nil)
  if valid_617485 != nil:
    section.add "X-Amz-SignedHeaders", valid_617485
  var valid_617486 = header.getOrDefault("X-Amz-Target")
  valid_617486 = validateParameter(valid_617486, JString, required = true, default = newJString(
      "AWSWAF_20190729.CheckCapacity"))
  if valid_617486 != nil:
    section.add "X-Amz-Target", valid_617486
  var valid_617487 = header.getOrDefault("X-Amz-Credential")
  valid_617487 = validateParameter(valid_617487, JString, required = false,
                                 default = nil)
  if valid_617487 != nil:
    section.add "X-Amz-Credential", valid_617487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617489: Call_CheckCapacity_617477; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Returns the web ACL capacity unit (WCU) requirements for a specified scope and set of rules. You can use this to check the capacity requirements for the rules you want to use in a <a>RuleGroup</a> or <a>WebACL</a>. </p> <p>AWS WAF uses WCUs to calculate and control the operating resources that are used to run your rules, rule groups, and web ACLs. AWS WAF calculates capacity differently for each rule type, to reflect the relative cost of each rule. Simple rules that cost little to run use fewer WCUs than more complex rules that use more processing power. Rule group capacity is fixed at creation, which helps users plan their web ACL WCU usage when they use a rule group. The WCU limit for web ACLs is 1,500. </p>
  ## 
  let valid = call_617489.validator(path, query, header, formData, body, _)
  let scheme = call_617489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617489.url(scheme.get, call_617489.host, call_617489.base,
                         call_617489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617489, url, valid, _)

proc call*(call_617490: Call_CheckCapacity_617477; body: JsonNode): Recallable =
  ## checkCapacity
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Returns the web ACL capacity unit (WCU) requirements for a specified scope and set of rules. You can use this to check the capacity requirements for the rules you want to use in a <a>RuleGroup</a> or <a>WebACL</a>. </p> <p>AWS WAF uses WCUs to calculate and control the operating resources that are used to run your rules, rule groups, and web ACLs. AWS WAF calculates capacity differently for each rule type, to reflect the relative cost of each rule. Simple rules that cost little to run use fewer WCUs than more complex rules that use more processing power. Rule group capacity is fixed at creation, which helps users plan their web ACL WCU usage when they use a rule group. The WCU limit for web ACLs is 1,500. </p>
  ##   body: JObject (required)
  var body_617491 = newJObject()
  if body != nil:
    body_617491 = body
  result = call_617490.call(nil, nil, nil, nil, body_617491)

var checkCapacity* = Call_CheckCapacity_617477(name: "checkCapacity",
    meth: HttpMethod.HttpPost, host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.CheckCapacity",
    validator: validate_CheckCapacity_617478, base: "/", url: url_CheckCapacity_617479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIPSet_617492 = ref object of OpenApiRestCall_616866
proc url_CreateIPSet_617494(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateIPSet_617493(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Creates an <a>IPSet</a>, which you use to identify web requests that originate from specific IP addresses or ranges of IP addresses. For example, if you're receiving a lot of requests from a ranges of IP addresses, you can configure AWS WAF to block them using an IPSet that lists those IP addresses. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617495 = header.getOrDefault("X-Amz-Date")
  valid_617495 = validateParameter(valid_617495, JString, required = false,
                                 default = nil)
  if valid_617495 != nil:
    section.add "X-Amz-Date", valid_617495
  var valid_617496 = header.getOrDefault("X-Amz-Security-Token")
  valid_617496 = validateParameter(valid_617496, JString, required = false,
                                 default = nil)
  if valid_617496 != nil:
    section.add "X-Amz-Security-Token", valid_617496
  var valid_617497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617497 = validateParameter(valid_617497, JString, required = false,
                                 default = nil)
  if valid_617497 != nil:
    section.add "X-Amz-Content-Sha256", valid_617497
  var valid_617498 = header.getOrDefault("X-Amz-Algorithm")
  valid_617498 = validateParameter(valid_617498, JString, required = false,
                                 default = nil)
  if valid_617498 != nil:
    section.add "X-Amz-Algorithm", valid_617498
  var valid_617499 = header.getOrDefault("X-Amz-Signature")
  valid_617499 = validateParameter(valid_617499, JString, required = false,
                                 default = nil)
  if valid_617499 != nil:
    section.add "X-Amz-Signature", valid_617499
  var valid_617500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617500 = validateParameter(valid_617500, JString, required = false,
                                 default = nil)
  if valid_617500 != nil:
    section.add "X-Amz-SignedHeaders", valid_617500
  var valid_617501 = header.getOrDefault("X-Amz-Target")
  valid_617501 = validateParameter(valid_617501, JString, required = true, default = newJString(
      "AWSWAF_20190729.CreateIPSet"))
  if valid_617501 != nil:
    section.add "X-Amz-Target", valid_617501
  var valid_617502 = header.getOrDefault("X-Amz-Credential")
  valid_617502 = validateParameter(valid_617502, JString, required = false,
                                 default = nil)
  if valid_617502 != nil:
    section.add "X-Amz-Credential", valid_617502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617504: Call_CreateIPSet_617492; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Creates an <a>IPSet</a>, which you use to identify web requests that originate from specific IP addresses or ranges of IP addresses. For example, if you're receiving a lot of requests from a ranges of IP addresses, you can configure AWS WAF to block them using an IPSet that lists those IP addresses. </p>
  ## 
  let valid = call_617504.validator(path, query, header, formData, body, _)
  let scheme = call_617504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617504.url(scheme.get, call_617504.host, call_617504.base,
                         call_617504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617504, url, valid, _)

proc call*(call_617505: Call_CreateIPSet_617492; body: JsonNode): Recallable =
  ## createIPSet
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Creates an <a>IPSet</a>, which you use to identify web requests that originate from specific IP addresses or ranges of IP addresses. For example, if you're receiving a lot of requests from a ranges of IP addresses, you can configure AWS WAF to block them using an IPSet that lists those IP addresses. </p>
  ##   body: JObject (required)
  var body_617506 = newJObject()
  if body != nil:
    body_617506 = body
  result = call_617505.call(nil, nil, nil, nil, body_617506)

var createIPSet* = Call_CreateIPSet_617492(name: "createIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "wafv2.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_20190729.CreateIPSet",
                                        validator: validate_CreateIPSet_617493,
                                        base: "/", url: url_CreateIPSet_617494,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRegexPatternSet_617507 = ref object of OpenApiRestCall_616866
proc url_CreateRegexPatternSet_617509(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRegexPatternSet_617508(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Creates a <a>RegexPatternSet</a>, which you reference in a <a>RegexPatternSetReferenceStatement</a>, to have AWS WAF inspect a web request component for the specified patterns.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617510 = header.getOrDefault("X-Amz-Date")
  valid_617510 = validateParameter(valid_617510, JString, required = false,
                                 default = nil)
  if valid_617510 != nil:
    section.add "X-Amz-Date", valid_617510
  var valid_617511 = header.getOrDefault("X-Amz-Security-Token")
  valid_617511 = validateParameter(valid_617511, JString, required = false,
                                 default = nil)
  if valid_617511 != nil:
    section.add "X-Amz-Security-Token", valid_617511
  var valid_617512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617512 = validateParameter(valid_617512, JString, required = false,
                                 default = nil)
  if valid_617512 != nil:
    section.add "X-Amz-Content-Sha256", valid_617512
  var valid_617513 = header.getOrDefault("X-Amz-Algorithm")
  valid_617513 = validateParameter(valid_617513, JString, required = false,
                                 default = nil)
  if valid_617513 != nil:
    section.add "X-Amz-Algorithm", valid_617513
  var valid_617514 = header.getOrDefault("X-Amz-Signature")
  valid_617514 = validateParameter(valid_617514, JString, required = false,
                                 default = nil)
  if valid_617514 != nil:
    section.add "X-Amz-Signature", valid_617514
  var valid_617515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617515 = validateParameter(valid_617515, JString, required = false,
                                 default = nil)
  if valid_617515 != nil:
    section.add "X-Amz-SignedHeaders", valid_617515
  var valid_617516 = header.getOrDefault("X-Amz-Target")
  valid_617516 = validateParameter(valid_617516, JString, required = true, default = newJString(
      "AWSWAF_20190729.CreateRegexPatternSet"))
  if valid_617516 != nil:
    section.add "X-Amz-Target", valid_617516
  var valid_617517 = header.getOrDefault("X-Amz-Credential")
  valid_617517 = validateParameter(valid_617517, JString, required = false,
                                 default = nil)
  if valid_617517 != nil:
    section.add "X-Amz-Credential", valid_617517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617519: Call_CreateRegexPatternSet_617507; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Creates a <a>RegexPatternSet</a>, which you reference in a <a>RegexPatternSetReferenceStatement</a>, to have AWS WAF inspect a web request component for the specified patterns.</p>
  ## 
  let valid = call_617519.validator(path, query, header, formData, body, _)
  let scheme = call_617519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617519.url(scheme.get, call_617519.host, call_617519.base,
                         call_617519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617519, url, valid, _)

proc call*(call_617520: Call_CreateRegexPatternSet_617507; body: JsonNode): Recallable =
  ## createRegexPatternSet
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Creates a <a>RegexPatternSet</a>, which you reference in a <a>RegexPatternSetReferenceStatement</a>, to have AWS WAF inspect a web request component for the specified patterns.</p>
  ##   body: JObject (required)
  var body_617521 = newJObject()
  if body != nil:
    body_617521 = body
  result = call_617520.call(nil, nil, nil, nil, body_617521)

var createRegexPatternSet* = Call_CreateRegexPatternSet_617507(
    name: "createRegexPatternSet", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.CreateRegexPatternSet",
    validator: validate_CreateRegexPatternSet_617508, base: "/",
    url: url_CreateRegexPatternSet_617509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRuleGroup_617522 = ref object of OpenApiRestCall_616866
proc url_CreateRuleGroup_617524(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRuleGroup_617523(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Creates a <a>RuleGroup</a> per the specifications provided. </p> <p> A rule group defines a collection of rules to inspect and control web requests that you can use in a <a>WebACL</a>. When you create a rule group, you define an immutable capacity limit. If you update a rule group, you must stay within the capacity. This allows others to reuse the rule group with confidence in its capacity requirements. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617525 = header.getOrDefault("X-Amz-Date")
  valid_617525 = validateParameter(valid_617525, JString, required = false,
                                 default = nil)
  if valid_617525 != nil:
    section.add "X-Amz-Date", valid_617525
  var valid_617526 = header.getOrDefault("X-Amz-Security-Token")
  valid_617526 = validateParameter(valid_617526, JString, required = false,
                                 default = nil)
  if valid_617526 != nil:
    section.add "X-Amz-Security-Token", valid_617526
  var valid_617527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617527 = validateParameter(valid_617527, JString, required = false,
                                 default = nil)
  if valid_617527 != nil:
    section.add "X-Amz-Content-Sha256", valid_617527
  var valid_617528 = header.getOrDefault("X-Amz-Algorithm")
  valid_617528 = validateParameter(valid_617528, JString, required = false,
                                 default = nil)
  if valid_617528 != nil:
    section.add "X-Amz-Algorithm", valid_617528
  var valid_617529 = header.getOrDefault("X-Amz-Signature")
  valid_617529 = validateParameter(valid_617529, JString, required = false,
                                 default = nil)
  if valid_617529 != nil:
    section.add "X-Amz-Signature", valid_617529
  var valid_617530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617530 = validateParameter(valid_617530, JString, required = false,
                                 default = nil)
  if valid_617530 != nil:
    section.add "X-Amz-SignedHeaders", valid_617530
  var valid_617531 = header.getOrDefault("X-Amz-Target")
  valid_617531 = validateParameter(valid_617531, JString, required = true, default = newJString(
      "AWSWAF_20190729.CreateRuleGroup"))
  if valid_617531 != nil:
    section.add "X-Amz-Target", valid_617531
  var valid_617532 = header.getOrDefault("X-Amz-Credential")
  valid_617532 = validateParameter(valid_617532, JString, required = false,
                                 default = nil)
  if valid_617532 != nil:
    section.add "X-Amz-Credential", valid_617532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617534: Call_CreateRuleGroup_617522; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Creates a <a>RuleGroup</a> per the specifications provided. </p> <p> A rule group defines a collection of rules to inspect and control web requests that you can use in a <a>WebACL</a>. When you create a rule group, you define an immutable capacity limit. If you update a rule group, you must stay within the capacity. This allows others to reuse the rule group with confidence in its capacity requirements. </p>
  ## 
  let valid = call_617534.validator(path, query, header, formData, body, _)
  let scheme = call_617534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617534.url(scheme.get, call_617534.host, call_617534.base,
                         call_617534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617534, url, valid, _)

proc call*(call_617535: Call_CreateRuleGroup_617522; body: JsonNode): Recallable =
  ## createRuleGroup
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Creates a <a>RuleGroup</a> per the specifications provided. </p> <p> A rule group defines a collection of rules to inspect and control web requests that you can use in a <a>WebACL</a>. When you create a rule group, you define an immutable capacity limit. If you update a rule group, you must stay within the capacity. This allows others to reuse the rule group with confidence in its capacity requirements. </p>
  ##   body: JObject (required)
  var body_617536 = newJObject()
  if body != nil:
    body_617536 = body
  result = call_617535.call(nil, nil, nil, nil, body_617536)

var createRuleGroup* = Call_CreateRuleGroup_617522(name: "createRuleGroup",
    meth: HttpMethod.HttpPost, host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.CreateRuleGroup",
    validator: validate_CreateRuleGroup_617523, base: "/", url: url_CreateRuleGroup_617524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebACL_617537 = ref object of OpenApiRestCall_616866
proc url_CreateWebACL_617539(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWebACL_617538(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Creates a <a>WebACL</a> per the specifications provided.</p> <p> A Web ACL defines a collection of rules to use to inspect and control web requests. Each rule has an action defined (allow, block, or count) for requests that match the statement of the rule. In the Web ACL, you assign a default action to take (allow, block) for any request that does not match any of the rules. The rules in a Web ACL can be a combination of the types <a>Rule</a>, <a>RuleGroup</a>, and managed rule group. You can associate a Web ACL with one or more AWS resources to protect. The resources can be Amazon CloudFront, an Amazon API Gateway API, or an Application Load Balancer. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617540 = header.getOrDefault("X-Amz-Date")
  valid_617540 = validateParameter(valid_617540, JString, required = false,
                                 default = nil)
  if valid_617540 != nil:
    section.add "X-Amz-Date", valid_617540
  var valid_617541 = header.getOrDefault("X-Amz-Security-Token")
  valid_617541 = validateParameter(valid_617541, JString, required = false,
                                 default = nil)
  if valid_617541 != nil:
    section.add "X-Amz-Security-Token", valid_617541
  var valid_617542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617542 = validateParameter(valid_617542, JString, required = false,
                                 default = nil)
  if valid_617542 != nil:
    section.add "X-Amz-Content-Sha256", valid_617542
  var valid_617543 = header.getOrDefault("X-Amz-Algorithm")
  valid_617543 = validateParameter(valid_617543, JString, required = false,
                                 default = nil)
  if valid_617543 != nil:
    section.add "X-Amz-Algorithm", valid_617543
  var valid_617544 = header.getOrDefault("X-Amz-Signature")
  valid_617544 = validateParameter(valid_617544, JString, required = false,
                                 default = nil)
  if valid_617544 != nil:
    section.add "X-Amz-Signature", valid_617544
  var valid_617545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617545 = validateParameter(valid_617545, JString, required = false,
                                 default = nil)
  if valid_617545 != nil:
    section.add "X-Amz-SignedHeaders", valid_617545
  var valid_617546 = header.getOrDefault("X-Amz-Target")
  valid_617546 = validateParameter(valid_617546, JString, required = true, default = newJString(
      "AWSWAF_20190729.CreateWebACL"))
  if valid_617546 != nil:
    section.add "X-Amz-Target", valid_617546
  var valid_617547 = header.getOrDefault("X-Amz-Credential")
  valid_617547 = validateParameter(valid_617547, JString, required = false,
                                 default = nil)
  if valid_617547 != nil:
    section.add "X-Amz-Credential", valid_617547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617549: Call_CreateWebACL_617537; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Creates a <a>WebACL</a> per the specifications provided.</p> <p> A Web ACL defines a collection of rules to use to inspect and control web requests. Each rule has an action defined (allow, block, or count) for requests that match the statement of the rule. In the Web ACL, you assign a default action to take (allow, block) for any request that does not match any of the rules. The rules in a Web ACL can be a combination of the types <a>Rule</a>, <a>RuleGroup</a>, and managed rule group. You can associate a Web ACL with one or more AWS resources to protect. The resources can be Amazon CloudFront, an Amazon API Gateway API, or an Application Load Balancer. </p>
  ## 
  let valid = call_617549.validator(path, query, header, formData, body, _)
  let scheme = call_617549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617549.url(scheme.get, call_617549.host, call_617549.base,
                         call_617549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617549, url, valid, _)

proc call*(call_617550: Call_CreateWebACL_617537; body: JsonNode): Recallable =
  ## createWebACL
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Creates a <a>WebACL</a> per the specifications provided.</p> <p> A Web ACL defines a collection of rules to use to inspect and control web requests. Each rule has an action defined (allow, block, or count) for requests that match the statement of the rule. In the Web ACL, you assign a default action to take (allow, block) for any request that does not match any of the rules. The rules in a Web ACL can be a combination of the types <a>Rule</a>, <a>RuleGroup</a>, and managed rule group. You can associate a Web ACL with one or more AWS resources to protect. The resources can be Amazon CloudFront, an Amazon API Gateway API, or an Application Load Balancer. </p>
  ##   body: JObject (required)
  var body_617551 = newJObject()
  if body != nil:
    body_617551 = body
  result = call_617550.call(nil, nil, nil, nil, body_617551)

var createWebACL* = Call_CreateWebACL_617537(name: "createWebACL",
    meth: HttpMethod.HttpPost, host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.CreateWebACL",
    validator: validate_CreateWebACL_617538, base: "/", url: url_CreateWebACL_617539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIPSet_617552 = ref object of OpenApiRestCall_616866
proc url_DeleteIPSet_617554(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteIPSet_617553(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the specified <a>IPSet</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617555 = header.getOrDefault("X-Amz-Date")
  valid_617555 = validateParameter(valid_617555, JString, required = false,
                                 default = nil)
  if valid_617555 != nil:
    section.add "X-Amz-Date", valid_617555
  var valid_617556 = header.getOrDefault("X-Amz-Security-Token")
  valid_617556 = validateParameter(valid_617556, JString, required = false,
                                 default = nil)
  if valid_617556 != nil:
    section.add "X-Amz-Security-Token", valid_617556
  var valid_617557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617557 = validateParameter(valid_617557, JString, required = false,
                                 default = nil)
  if valid_617557 != nil:
    section.add "X-Amz-Content-Sha256", valid_617557
  var valid_617558 = header.getOrDefault("X-Amz-Algorithm")
  valid_617558 = validateParameter(valid_617558, JString, required = false,
                                 default = nil)
  if valid_617558 != nil:
    section.add "X-Amz-Algorithm", valid_617558
  var valid_617559 = header.getOrDefault("X-Amz-Signature")
  valid_617559 = validateParameter(valid_617559, JString, required = false,
                                 default = nil)
  if valid_617559 != nil:
    section.add "X-Amz-Signature", valid_617559
  var valid_617560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617560 = validateParameter(valid_617560, JString, required = false,
                                 default = nil)
  if valid_617560 != nil:
    section.add "X-Amz-SignedHeaders", valid_617560
  var valid_617561 = header.getOrDefault("X-Amz-Target")
  valid_617561 = validateParameter(valid_617561, JString, required = true, default = newJString(
      "AWSWAF_20190729.DeleteIPSet"))
  if valid_617561 != nil:
    section.add "X-Amz-Target", valid_617561
  var valid_617562 = header.getOrDefault("X-Amz-Credential")
  valid_617562 = validateParameter(valid_617562, JString, required = false,
                                 default = nil)
  if valid_617562 != nil:
    section.add "X-Amz-Credential", valid_617562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617564: Call_DeleteIPSet_617552; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the specified <a>IPSet</a>. </p>
  ## 
  let valid = call_617564.validator(path, query, header, formData, body, _)
  let scheme = call_617564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617564.url(scheme.get, call_617564.host, call_617564.base,
                         call_617564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617564, url, valid, _)

proc call*(call_617565: Call_DeleteIPSet_617552; body: JsonNode): Recallable =
  ## deleteIPSet
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the specified <a>IPSet</a>. </p>
  ##   body: JObject (required)
  var body_617566 = newJObject()
  if body != nil:
    body_617566 = body
  result = call_617565.call(nil, nil, nil, nil, body_617566)

var deleteIPSet* = Call_DeleteIPSet_617552(name: "deleteIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "wafv2.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_20190729.DeleteIPSet",
                                        validator: validate_DeleteIPSet_617553,
                                        base: "/", url: url_DeleteIPSet_617554,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggingConfiguration_617567 = ref object of OpenApiRestCall_616866
proc url_DeleteLoggingConfiguration_617569(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLoggingConfiguration_617568(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the <a>LoggingConfiguration</a> from the specified web ACL.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617570 = header.getOrDefault("X-Amz-Date")
  valid_617570 = validateParameter(valid_617570, JString, required = false,
                                 default = nil)
  if valid_617570 != nil:
    section.add "X-Amz-Date", valid_617570
  var valid_617571 = header.getOrDefault("X-Amz-Security-Token")
  valid_617571 = validateParameter(valid_617571, JString, required = false,
                                 default = nil)
  if valid_617571 != nil:
    section.add "X-Amz-Security-Token", valid_617571
  var valid_617572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617572 = validateParameter(valid_617572, JString, required = false,
                                 default = nil)
  if valid_617572 != nil:
    section.add "X-Amz-Content-Sha256", valid_617572
  var valid_617573 = header.getOrDefault("X-Amz-Algorithm")
  valid_617573 = validateParameter(valid_617573, JString, required = false,
                                 default = nil)
  if valid_617573 != nil:
    section.add "X-Amz-Algorithm", valid_617573
  var valid_617574 = header.getOrDefault("X-Amz-Signature")
  valid_617574 = validateParameter(valid_617574, JString, required = false,
                                 default = nil)
  if valid_617574 != nil:
    section.add "X-Amz-Signature", valid_617574
  var valid_617575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617575 = validateParameter(valid_617575, JString, required = false,
                                 default = nil)
  if valid_617575 != nil:
    section.add "X-Amz-SignedHeaders", valid_617575
  var valid_617576 = header.getOrDefault("X-Amz-Target")
  valid_617576 = validateParameter(valid_617576, JString, required = true, default = newJString(
      "AWSWAF_20190729.DeleteLoggingConfiguration"))
  if valid_617576 != nil:
    section.add "X-Amz-Target", valid_617576
  var valid_617577 = header.getOrDefault("X-Amz-Credential")
  valid_617577 = validateParameter(valid_617577, JString, required = false,
                                 default = nil)
  if valid_617577 != nil:
    section.add "X-Amz-Credential", valid_617577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617579: Call_DeleteLoggingConfiguration_617567;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the <a>LoggingConfiguration</a> from the specified web ACL.</p>
  ## 
  let valid = call_617579.validator(path, query, header, formData, body, _)
  let scheme = call_617579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617579.url(scheme.get, call_617579.host, call_617579.base,
                         call_617579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617579, url, valid, _)

proc call*(call_617580: Call_DeleteLoggingConfiguration_617567; body: JsonNode): Recallable =
  ## deleteLoggingConfiguration
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the <a>LoggingConfiguration</a> from the specified web ACL.</p>
  ##   body: JObject (required)
  var body_617581 = newJObject()
  if body != nil:
    body_617581 = body
  result = call_617580.call(nil, nil, nil, nil, body_617581)

var deleteLoggingConfiguration* = Call_DeleteLoggingConfiguration_617567(
    name: "deleteLoggingConfiguration", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.DeleteLoggingConfiguration",
    validator: validate_DeleteLoggingConfiguration_617568, base: "/",
    url: url_DeleteLoggingConfiguration_617569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRegexPatternSet_617582 = ref object of OpenApiRestCall_616866
proc url_DeleteRegexPatternSet_617584(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRegexPatternSet_617583(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the specified <a>RegexPatternSet</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617585 = header.getOrDefault("X-Amz-Date")
  valid_617585 = validateParameter(valid_617585, JString, required = false,
                                 default = nil)
  if valid_617585 != nil:
    section.add "X-Amz-Date", valid_617585
  var valid_617586 = header.getOrDefault("X-Amz-Security-Token")
  valid_617586 = validateParameter(valid_617586, JString, required = false,
                                 default = nil)
  if valid_617586 != nil:
    section.add "X-Amz-Security-Token", valid_617586
  var valid_617587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617587 = validateParameter(valid_617587, JString, required = false,
                                 default = nil)
  if valid_617587 != nil:
    section.add "X-Amz-Content-Sha256", valid_617587
  var valid_617588 = header.getOrDefault("X-Amz-Algorithm")
  valid_617588 = validateParameter(valid_617588, JString, required = false,
                                 default = nil)
  if valid_617588 != nil:
    section.add "X-Amz-Algorithm", valid_617588
  var valid_617589 = header.getOrDefault("X-Amz-Signature")
  valid_617589 = validateParameter(valid_617589, JString, required = false,
                                 default = nil)
  if valid_617589 != nil:
    section.add "X-Amz-Signature", valid_617589
  var valid_617590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617590 = validateParameter(valid_617590, JString, required = false,
                                 default = nil)
  if valid_617590 != nil:
    section.add "X-Amz-SignedHeaders", valid_617590
  var valid_617591 = header.getOrDefault("X-Amz-Target")
  valid_617591 = validateParameter(valid_617591, JString, required = true, default = newJString(
      "AWSWAF_20190729.DeleteRegexPatternSet"))
  if valid_617591 != nil:
    section.add "X-Amz-Target", valid_617591
  var valid_617592 = header.getOrDefault("X-Amz-Credential")
  valid_617592 = validateParameter(valid_617592, JString, required = false,
                                 default = nil)
  if valid_617592 != nil:
    section.add "X-Amz-Credential", valid_617592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617594: Call_DeleteRegexPatternSet_617582; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the specified <a>RegexPatternSet</a>.</p>
  ## 
  let valid = call_617594.validator(path, query, header, formData, body, _)
  let scheme = call_617594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617594.url(scheme.get, call_617594.host, call_617594.base,
                         call_617594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617594, url, valid, _)

proc call*(call_617595: Call_DeleteRegexPatternSet_617582; body: JsonNode): Recallable =
  ## deleteRegexPatternSet
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the specified <a>RegexPatternSet</a>.</p>
  ##   body: JObject (required)
  var body_617596 = newJObject()
  if body != nil:
    body_617596 = body
  result = call_617595.call(nil, nil, nil, nil, body_617596)

var deleteRegexPatternSet* = Call_DeleteRegexPatternSet_617582(
    name: "deleteRegexPatternSet", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.DeleteRegexPatternSet",
    validator: validate_DeleteRegexPatternSet_617583, base: "/",
    url: url_DeleteRegexPatternSet_617584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRuleGroup_617597 = ref object of OpenApiRestCall_616866
proc url_DeleteRuleGroup_617599(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRuleGroup_617598(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the specified <a>RuleGroup</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617600 = header.getOrDefault("X-Amz-Date")
  valid_617600 = validateParameter(valid_617600, JString, required = false,
                                 default = nil)
  if valid_617600 != nil:
    section.add "X-Amz-Date", valid_617600
  var valid_617601 = header.getOrDefault("X-Amz-Security-Token")
  valid_617601 = validateParameter(valid_617601, JString, required = false,
                                 default = nil)
  if valid_617601 != nil:
    section.add "X-Amz-Security-Token", valid_617601
  var valid_617602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617602 = validateParameter(valid_617602, JString, required = false,
                                 default = nil)
  if valid_617602 != nil:
    section.add "X-Amz-Content-Sha256", valid_617602
  var valid_617603 = header.getOrDefault("X-Amz-Algorithm")
  valid_617603 = validateParameter(valid_617603, JString, required = false,
                                 default = nil)
  if valid_617603 != nil:
    section.add "X-Amz-Algorithm", valid_617603
  var valid_617604 = header.getOrDefault("X-Amz-Signature")
  valid_617604 = validateParameter(valid_617604, JString, required = false,
                                 default = nil)
  if valid_617604 != nil:
    section.add "X-Amz-Signature", valid_617604
  var valid_617605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617605 = validateParameter(valid_617605, JString, required = false,
                                 default = nil)
  if valid_617605 != nil:
    section.add "X-Amz-SignedHeaders", valid_617605
  var valid_617606 = header.getOrDefault("X-Amz-Target")
  valid_617606 = validateParameter(valid_617606, JString, required = true, default = newJString(
      "AWSWAF_20190729.DeleteRuleGroup"))
  if valid_617606 != nil:
    section.add "X-Amz-Target", valid_617606
  var valid_617607 = header.getOrDefault("X-Amz-Credential")
  valid_617607 = validateParameter(valid_617607, JString, required = false,
                                 default = nil)
  if valid_617607 != nil:
    section.add "X-Amz-Credential", valid_617607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617609: Call_DeleteRuleGroup_617597; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the specified <a>RuleGroup</a>.</p>
  ## 
  let valid = call_617609.validator(path, query, header, formData, body, _)
  let scheme = call_617609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617609.url(scheme.get, call_617609.host, call_617609.base,
                         call_617609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617609, url, valid, _)

proc call*(call_617610: Call_DeleteRuleGroup_617597; body: JsonNode): Recallable =
  ## deleteRuleGroup
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the specified <a>RuleGroup</a>.</p>
  ##   body: JObject (required)
  var body_617611 = newJObject()
  if body != nil:
    body_617611 = body
  result = call_617610.call(nil, nil, nil, nil, body_617611)

var deleteRuleGroup* = Call_DeleteRuleGroup_617597(name: "deleteRuleGroup",
    meth: HttpMethod.HttpPost, host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.DeleteRuleGroup",
    validator: validate_DeleteRuleGroup_617598, base: "/", url: url_DeleteRuleGroup_617599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebACL_617612 = ref object of OpenApiRestCall_616866
proc url_DeleteWebACL_617614(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWebACL_617613(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the specified <a>WebACL</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617615 = header.getOrDefault("X-Amz-Date")
  valid_617615 = validateParameter(valid_617615, JString, required = false,
                                 default = nil)
  if valid_617615 != nil:
    section.add "X-Amz-Date", valid_617615
  var valid_617616 = header.getOrDefault("X-Amz-Security-Token")
  valid_617616 = validateParameter(valid_617616, JString, required = false,
                                 default = nil)
  if valid_617616 != nil:
    section.add "X-Amz-Security-Token", valid_617616
  var valid_617617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617617 = validateParameter(valid_617617, JString, required = false,
                                 default = nil)
  if valid_617617 != nil:
    section.add "X-Amz-Content-Sha256", valid_617617
  var valid_617618 = header.getOrDefault("X-Amz-Algorithm")
  valid_617618 = validateParameter(valid_617618, JString, required = false,
                                 default = nil)
  if valid_617618 != nil:
    section.add "X-Amz-Algorithm", valid_617618
  var valid_617619 = header.getOrDefault("X-Amz-Signature")
  valid_617619 = validateParameter(valid_617619, JString, required = false,
                                 default = nil)
  if valid_617619 != nil:
    section.add "X-Amz-Signature", valid_617619
  var valid_617620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617620 = validateParameter(valid_617620, JString, required = false,
                                 default = nil)
  if valid_617620 != nil:
    section.add "X-Amz-SignedHeaders", valid_617620
  var valid_617621 = header.getOrDefault("X-Amz-Target")
  valid_617621 = validateParameter(valid_617621, JString, required = true, default = newJString(
      "AWSWAF_20190729.DeleteWebACL"))
  if valid_617621 != nil:
    section.add "X-Amz-Target", valid_617621
  var valid_617622 = header.getOrDefault("X-Amz-Credential")
  valid_617622 = validateParameter(valid_617622, JString, required = false,
                                 default = nil)
  if valid_617622 != nil:
    section.add "X-Amz-Credential", valid_617622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617624: Call_DeleteWebACL_617612; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the specified <a>WebACL</a>.</p>
  ## 
  let valid = call_617624.validator(path, query, header, formData, body, _)
  let scheme = call_617624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617624.url(scheme.get, call_617624.host, call_617624.base,
                         call_617624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617624, url, valid, _)

proc call*(call_617625: Call_DeleteWebACL_617612; body: JsonNode): Recallable =
  ## deleteWebACL
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Deletes the specified <a>WebACL</a>.</p>
  ##   body: JObject (required)
  var body_617626 = newJObject()
  if body != nil:
    body_617626 = body
  result = call_617625.call(nil, nil, nil, nil, body_617626)

var deleteWebACL* = Call_DeleteWebACL_617612(name: "deleteWebACL",
    meth: HttpMethod.HttpPost, host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.DeleteWebACL",
    validator: validate_DeleteWebACL_617613, base: "/", url: url_DeleteWebACL_617614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeManagedRuleGroup_617627 = ref object of OpenApiRestCall_616866
proc url_DescribeManagedRuleGroup_617629(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeManagedRuleGroup_617628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Provides high-level information for a managed rule group, including descriptions of the rules. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617630 = header.getOrDefault("X-Amz-Date")
  valid_617630 = validateParameter(valid_617630, JString, required = false,
                                 default = nil)
  if valid_617630 != nil:
    section.add "X-Amz-Date", valid_617630
  var valid_617631 = header.getOrDefault("X-Amz-Security-Token")
  valid_617631 = validateParameter(valid_617631, JString, required = false,
                                 default = nil)
  if valid_617631 != nil:
    section.add "X-Amz-Security-Token", valid_617631
  var valid_617632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617632 = validateParameter(valid_617632, JString, required = false,
                                 default = nil)
  if valid_617632 != nil:
    section.add "X-Amz-Content-Sha256", valid_617632
  var valid_617633 = header.getOrDefault("X-Amz-Algorithm")
  valid_617633 = validateParameter(valid_617633, JString, required = false,
                                 default = nil)
  if valid_617633 != nil:
    section.add "X-Amz-Algorithm", valid_617633
  var valid_617634 = header.getOrDefault("X-Amz-Signature")
  valid_617634 = validateParameter(valid_617634, JString, required = false,
                                 default = nil)
  if valid_617634 != nil:
    section.add "X-Amz-Signature", valid_617634
  var valid_617635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617635 = validateParameter(valid_617635, JString, required = false,
                                 default = nil)
  if valid_617635 != nil:
    section.add "X-Amz-SignedHeaders", valid_617635
  var valid_617636 = header.getOrDefault("X-Amz-Target")
  valid_617636 = validateParameter(valid_617636, JString, required = true, default = newJString(
      "AWSWAF_20190729.DescribeManagedRuleGroup"))
  if valid_617636 != nil:
    section.add "X-Amz-Target", valid_617636
  var valid_617637 = header.getOrDefault("X-Amz-Credential")
  valid_617637 = validateParameter(valid_617637, JString, required = false,
                                 default = nil)
  if valid_617637 != nil:
    section.add "X-Amz-Credential", valid_617637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617639: Call_DescribeManagedRuleGroup_617627; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Provides high-level information for a managed rule group, including descriptions of the rules. </p>
  ## 
  let valid = call_617639.validator(path, query, header, formData, body, _)
  let scheme = call_617639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617639.url(scheme.get, call_617639.host, call_617639.base,
                         call_617639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617639, url, valid, _)

proc call*(call_617640: Call_DescribeManagedRuleGroup_617627; body: JsonNode): Recallable =
  ## describeManagedRuleGroup
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Provides high-level information for a managed rule group, including descriptions of the rules. </p>
  ##   body: JObject (required)
  var body_617641 = newJObject()
  if body != nil:
    body_617641 = body
  result = call_617640.call(nil, nil, nil, nil, body_617641)

var describeManagedRuleGroup* = Call_DescribeManagedRuleGroup_617627(
    name: "describeManagedRuleGroup", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.DescribeManagedRuleGroup",
    validator: validate_DescribeManagedRuleGroup_617628, base: "/",
    url: url_DescribeManagedRuleGroup_617629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebACL_617642 = ref object of OpenApiRestCall_616866
proc url_DisassociateWebACL_617644(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateWebACL_617643(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Disassociates a Web ACL from a regional application resource. A regional application can be an Application Load Balancer (ALB) or an API Gateway stage. </p> <p>For AWS CloudFront, you can disassociate the Web ACL by providing an empty web ACL ARN in the CloudFront API call <code>UpdateDistribution</code>. For information, see <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617645 = header.getOrDefault("X-Amz-Date")
  valid_617645 = validateParameter(valid_617645, JString, required = false,
                                 default = nil)
  if valid_617645 != nil:
    section.add "X-Amz-Date", valid_617645
  var valid_617646 = header.getOrDefault("X-Amz-Security-Token")
  valid_617646 = validateParameter(valid_617646, JString, required = false,
                                 default = nil)
  if valid_617646 != nil:
    section.add "X-Amz-Security-Token", valid_617646
  var valid_617647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617647 = validateParameter(valid_617647, JString, required = false,
                                 default = nil)
  if valid_617647 != nil:
    section.add "X-Amz-Content-Sha256", valid_617647
  var valid_617648 = header.getOrDefault("X-Amz-Algorithm")
  valid_617648 = validateParameter(valid_617648, JString, required = false,
                                 default = nil)
  if valid_617648 != nil:
    section.add "X-Amz-Algorithm", valid_617648
  var valid_617649 = header.getOrDefault("X-Amz-Signature")
  valid_617649 = validateParameter(valid_617649, JString, required = false,
                                 default = nil)
  if valid_617649 != nil:
    section.add "X-Amz-Signature", valid_617649
  var valid_617650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617650 = validateParameter(valid_617650, JString, required = false,
                                 default = nil)
  if valid_617650 != nil:
    section.add "X-Amz-SignedHeaders", valid_617650
  var valid_617651 = header.getOrDefault("X-Amz-Target")
  valid_617651 = validateParameter(valid_617651, JString, required = true, default = newJString(
      "AWSWAF_20190729.DisassociateWebACL"))
  if valid_617651 != nil:
    section.add "X-Amz-Target", valid_617651
  var valid_617652 = header.getOrDefault("X-Amz-Credential")
  valid_617652 = validateParameter(valid_617652, JString, required = false,
                                 default = nil)
  if valid_617652 != nil:
    section.add "X-Amz-Credential", valid_617652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617654: Call_DisassociateWebACL_617642; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Disassociates a Web ACL from a regional application resource. A regional application can be an Application Load Balancer (ALB) or an API Gateway stage. </p> <p>For AWS CloudFront, you can disassociate the Web ACL by providing an empty web ACL ARN in the CloudFront API call <code>UpdateDistribution</code>. For information, see <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>.</p>
  ## 
  let valid = call_617654.validator(path, query, header, formData, body, _)
  let scheme = call_617654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617654.url(scheme.get, call_617654.host, call_617654.base,
                         call_617654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617654, url, valid, _)

proc call*(call_617655: Call_DisassociateWebACL_617642; body: JsonNode): Recallable =
  ## disassociateWebACL
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Disassociates a Web ACL from a regional application resource. A regional application can be an Application Load Balancer (ALB) or an API Gateway stage. </p> <p>For AWS CloudFront, you can disassociate the Web ACL by providing an empty web ACL ARN in the CloudFront API call <code>UpdateDistribution</code>. For information, see <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>.</p>
  ##   body: JObject (required)
  var body_617656 = newJObject()
  if body != nil:
    body_617656 = body
  result = call_617655.call(nil, nil, nil, nil, body_617656)

var disassociateWebACL* = Call_DisassociateWebACL_617642(
    name: "disassociateWebACL", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.DisassociateWebACL",
    validator: validate_DisassociateWebACL_617643, base: "/",
    url: url_DisassociateWebACL_617644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIPSet_617657 = ref object of OpenApiRestCall_616866
proc url_GetIPSet_617659(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIPSet_617658(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the specified <a>IPSet</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617660 = header.getOrDefault("X-Amz-Date")
  valid_617660 = validateParameter(valid_617660, JString, required = false,
                                 default = nil)
  if valid_617660 != nil:
    section.add "X-Amz-Date", valid_617660
  var valid_617661 = header.getOrDefault("X-Amz-Security-Token")
  valid_617661 = validateParameter(valid_617661, JString, required = false,
                                 default = nil)
  if valid_617661 != nil:
    section.add "X-Amz-Security-Token", valid_617661
  var valid_617662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617662 = validateParameter(valid_617662, JString, required = false,
                                 default = nil)
  if valid_617662 != nil:
    section.add "X-Amz-Content-Sha256", valid_617662
  var valid_617663 = header.getOrDefault("X-Amz-Algorithm")
  valid_617663 = validateParameter(valid_617663, JString, required = false,
                                 default = nil)
  if valid_617663 != nil:
    section.add "X-Amz-Algorithm", valid_617663
  var valid_617664 = header.getOrDefault("X-Amz-Signature")
  valid_617664 = validateParameter(valid_617664, JString, required = false,
                                 default = nil)
  if valid_617664 != nil:
    section.add "X-Amz-Signature", valid_617664
  var valid_617665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617665 = validateParameter(valid_617665, JString, required = false,
                                 default = nil)
  if valid_617665 != nil:
    section.add "X-Amz-SignedHeaders", valid_617665
  var valid_617666 = header.getOrDefault("X-Amz-Target")
  valid_617666 = validateParameter(valid_617666, JString, required = true, default = newJString(
      "AWSWAF_20190729.GetIPSet"))
  if valid_617666 != nil:
    section.add "X-Amz-Target", valid_617666
  var valid_617667 = header.getOrDefault("X-Amz-Credential")
  valid_617667 = validateParameter(valid_617667, JString, required = false,
                                 default = nil)
  if valid_617667 != nil:
    section.add "X-Amz-Credential", valid_617667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617669: Call_GetIPSet_617657; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the specified <a>IPSet</a>.</p>
  ## 
  let valid = call_617669.validator(path, query, header, formData, body, _)
  let scheme = call_617669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617669.url(scheme.get, call_617669.host, call_617669.base,
                         call_617669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617669, url, valid, _)

proc call*(call_617670: Call_GetIPSet_617657; body: JsonNode): Recallable =
  ## getIPSet
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the specified <a>IPSet</a>.</p>
  ##   body: JObject (required)
  var body_617671 = newJObject()
  if body != nil:
    body_617671 = body
  result = call_617670.call(nil, nil, nil, nil, body_617671)

var getIPSet* = Call_GetIPSet_617657(name: "getIPSet", meth: HttpMethod.HttpPost,
                                  host: "wafv2.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_20190729.GetIPSet",
                                  validator: validate_GetIPSet_617658, base: "/",
                                  url: url_GetIPSet_617659,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggingConfiguration_617672 = ref object of OpenApiRestCall_616866
proc url_GetLoggingConfiguration_617674(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLoggingConfiguration_617673(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Returns the <a>LoggingConfiguration</a> for the specified web ACL.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617675 = header.getOrDefault("X-Amz-Date")
  valid_617675 = validateParameter(valid_617675, JString, required = false,
                                 default = nil)
  if valid_617675 != nil:
    section.add "X-Amz-Date", valid_617675
  var valid_617676 = header.getOrDefault("X-Amz-Security-Token")
  valid_617676 = validateParameter(valid_617676, JString, required = false,
                                 default = nil)
  if valid_617676 != nil:
    section.add "X-Amz-Security-Token", valid_617676
  var valid_617677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617677 = validateParameter(valid_617677, JString, required = false,
                                 default = nil)
  if valid_617677 != nil:
    section.add "X-Amz-Content-Sha256", valid_617677
  var valid_617678 = header.getOrDefault("X-Amz-Algorithm")
  valid_617678 = validateParameter(valid_617678, JString, required = false,
                                 default = nil)
  if valid_617678 != nil:
    section.add "X-Amz-Algorithm", valid_617678
  var valid_617679 = header.getOrDefault("X-Amz-Signature")
  valid_617679 = validateParameter(valid_617679, JString, required = false,
                                 default = nil)
  if valid_617679 != nil:
    section.add "X-Amz-Signature", valid_617679
  var valid_617680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617680 = validateParameter(valid_617680, JString, required = false,
                                 default = nil)
  if valid_617680 != nil:
    section.add "X-Amz-SignedHeaders", valid_617680
  var valid_617681 = header.getOrDefault("X-Amz-Target")
  valid_617681 = validateParameter(valid_617681, JString, required = true, default = newJString(
      "AWSWAF_20190729.GetLoggingConfiguration"))
  if valid_617681 != nil:
    section.add "X-Amz-Target", valid_617681
  var valid_617682 = header.getOrDefault("X-Amz-Credential")
  valid_617682 = validateParameter(valid_617682, JString, required = false,
                                 default = nil)
  if valid_617682 != nil:
    section.add "X-Amz-Credential", valid_617682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617684: Call_GetLoggingConfiguration_617672; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Returns the <a>LoggingConfiguration</a> for the specified web ACL.</p>
  ## 
  let valid = call_617684.validator(path, query, header, formData, body, _)
  let scheme = call_617684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617684.url(scheme.get, call_617684.host, call_617684.base,
                         call_617684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617684, url, valid, _)

proc call*(call_617685: Call_GetLoggingConfiguration_617672; body: JsonNode): Recallable =
  ## getLoggingConfiguration
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Returns the <a>LoggingConfiguration</a> for the specified web ACL.</p>
  ##   body: JObject (required)
  var body_617686 = newJObject()
  if body != nil:
    body_617686 = body
  result = call_617685.call(nil, nil, nil, nil, body_617686)

var getLoggingConfiguration* = Call_GetLoggingConfiguration_617672(
    name: "getLoggingConfiguration", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.GetLoggingConfiguration",
    validator: validate_GetLoggingConfiguration_617673, base: "/",
    url: url_GetLoggingConfiguration_617674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRateBasedStatementManagedKeys_617687 = ref object of OpenApiRestCall_616866
proc url_GetRateBasedStatementManagedKeys_617689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRateBasedStatementManagedKeys_617688(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the keys that are currently blocked by a rate-based rule. The maximum number of managed keys that can be blocked for a single rate-based rule is 10,000. If more than 10,000 addresses exceed the rate limit, those with the highest rates are blocked.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617690 = header.getOrDefault("X-Amz-Date")
  valid_617690 = validateParameter(valid_617690, JString, required = false,
                                 default = nil)
  if valid_617690 != nil:
    section.add "X-Amz-Date", valid_617690
  var valid_617691 = header.getOrDefault("X-Amz-Security-Token")
  valid_617691 = validateParameter(valid_617691, JString, required = false,
                                 default = nil)
  if valid_617691 != nil:
    section.add "X-Amz-Security-Token", valid_617691
  var valid_617692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617692 = validateParameter(valid_617692, JString, required = false,
                                 default = nil)
  if valid_617692 != nil:
    section.add "X-Amz-Content-Sha256", valid_617692
  var valid_617693 = header.getOrDefault("X-Amz-Algorithm")
  valid_617693 = validateParameter(valid_617693, JString, required = false,
                                 default = nil)
  if valid_617693 != nil:
    section.add "X-Amz-Algorithm", valid_617693
  var valid_617694 = header.getOrDefault("X-Amz-Signature")
  valid_617694 = validateParameter(valid_617694, JString, required = false,
                                 default = nil)
  if valid_617694 != nil:
    section.add "X-Amz-Signature", valid_617694
  var valid_617695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617695 = validateParameter(valid_617695, JString, required = false,
                                 default = nil)
  if valid_617695 != nil:
    section.add "X-Amz-SignedHeaders", valid_617695
  var valid_617696 = header.getOrDefault("X-Amz-Target")
  valid_617696 = validateParameter(valid_617696, JString, required = true, default = newJString(
      "AWSWAF_20190729.GetRateBasedStatementManagedKeys"))
  if valid_617696 != nil:
    section.add "X-Amz-Target", valid_617696
  var valid_617697 = header.getOrDefault("X-Amz-Credential")
  valid_617697 = validateParameter(valid_617697, JString, required = false,
                                 default = nil)
  if valid_617697 != nil:
    section.add "X-Amz-Credential", valid_617697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617699: Call_GetRateBasedStatementManagedKeys_617687;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the keys that are currently blocked by a rate-based rule. The maximum number of managed keys that can be blocked for a single rate-based rule is 10,000. If more than 10,000 addresses exceed the rate limit, those with the highest rates are blocked.</p>
  ## 
  let valid = call_617699.validator(path, query, header, formData, body, _)
  let scheme = call_617699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617699.url(scheme.get, call_617699.host, call_617699.base,
                         call_617699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617699, url, valid, _)

proc call*(call_617700: Call_GetRateBasedStatementManagedKeys_617687;
          body: JsonNode): Recallable =
  ## getRateBasedStatementManagedKeys
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the keys that are currently blocked by a rate-based rule. The maximum number of managed keys that can be blocked for a single rate-based rule is 10,000. If more than 10,000 addresses exceed the rate limit, those with the highest rates are blocked.</p>
  ##   body: JObject (required)
  var body_617701 = newJObject()
  if body != nil:
    body_617701 = body
  result = call_617700.call(nil, nil, nil, nil, body_617701)

var getRateBasedStatementManagedKeys* = Call_GetRateBasedStatementManagedKeys_617687(
    name: "getRateBasedStatementManagedKeys", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.GetRateBasedStatementManagedKeys",
    validator: validate_GetRateBasedStatementManagedKeys_617688, base: "/",
    url: url_GetRateBasedStatementManagedKeys_617689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegexPatternSet_617702 = ref object of OpenApiRestCall_616866
proc url_GetRegexPatternSet_617704(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRegexPatternSet_617703(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the specified <a>RegexPatternSet</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617705 = header.getOrDefault("X-Amz-Date")
  valid_617705 = validateParameter(valid_617705, JString, required = false,
                                 default = nil)
  if valid_617705 != nil:
    section.add "X-Amz-Date", valid_617705
  var valid_617706 = header.getOrDefault("X-Amz-Security-Token")
  valid_617706 = validateParameter(valid_617706, JString, required = false,
                                 default = nil)
  if valid_617706 != nil:
    section.add "X-Amz-Security-Token", valid_617706
  var valid_617707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617707 = validateParameter(valid_617707, JString, required = false,
                                 default = nil)
  if valid_617707 != nil:
    section.add "X-Amz-Content-Sha256", valid_617707
  var valid_617708 = header.getOrDefault("X-Amz-Algorithm")
  valid_617708 = validateParameter(valid_617708, JString, required = false,
                                 default = nil)
  if valid_617708 != nil:
    section.add "X-Amz-Algorithm", valid_617708
  var valid_617709 = header.getOrDefault("X-Amz-Signature")
  valid_617709 = validateParameter(valid_617709, JString, required = false,
                                 default = nil)
  if valid_617709 != nil:
    section.add "X-Amz-Signature", valid_617709
  var valid_617710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617710 = validateParameter(valid_617710, JString, required = false,
                                 default = nil)
  if valid_617710 != nil:
    section.add "X-Amz-SignedHeaders", valid_617710
  var valid_617711 = header.getOrDefault("X-Amz-Target")
  valid_617711 = validateParameter(valid_617711, JString, required = true, default = newJString(
      "AWSWAF_20190729.GetRegexPatternSet"))
  if valid_617711 != nil:
    section.add "X-Amz-Target", valid_617711
  var valid_617712 = header.getOrDefault("X-Amz-Credential")
  valid_617712 = validateParameter(valid_617712, JString, required = false,
                                 default = nil)
  if valid_617712 != nil:
    section.add "X-Amz-Credential", valid_617712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617714: Call_GetRegexPatternSet_617702; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the specified <a>RegexPatternSet</a>.</p>
  ## 
  let valid = call_617714.validator(path, query, header, formData, body, _)
  let scheme = call_617714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617714.url(scheme.get, call_617714.host, call_617714.base,
                         call_617714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617714, url, valid, _)

proc call*(call_617715: Call_GetRegexPatternSet_617702; body: JsonNode): Recallable =
  ## getRegexPatternSet
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the specified <a>RegexPatternSet</a>.</p>
  ##   body: JObject (required)
  var body_617716 = newJObject()
  if body != nil:
    body_617716 = body
  result = call_617715.call(nil, nil, nil, nil, body_617716)

var getRegexPatternSet* = Call_GetRegexPatternSet_617702(
    name: "getRegexPatternSet", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.GetRegexPatternSet",
    validator: validate_GetRegexPatternSet_617703, base: "/",
    url: url_GetRegexPatternSet_617704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRuleGroup_617717 = ref object of OpenApiRestCall_616866
proc url_GetRuleGroup_617719(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRuleGroup_617718(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the specified <a>RuleGroup</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617720 = header.getOrDefault("X-Amz-Date")
  valid_617720 = validateParameter(valid_617720, JString, required = false,
                                 default = nil)
  if valid_617720 != nil:
    section.add "X-Amz-Date", valid_617720
  var valid_617721 = header.getOrDefault("X-Amz-Security-Token")
  valid_617721 = validateParameter(valid_617721, JString, required = false,
                                 default = nil)
  if valid_617721 != nil:
    section.add "X-Amz-Security-Token", valid_617721
  var valid_617722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617722 = validateParameter(valid_617722, JString, required = false,
                                 default = nil)
  if valid_617722 != nil:
    section.add "X-Amz-Content-Sha256", valid_617722
  var valid_617723 = header.getOrDefault("X-Amz-Algorithm")
  valid_617723 = validateParameter(valid_617723, JString, required = false,
                                 default = nil)
  if valid_617723 != nil:
    section.add "X-Amz-Algorithm", valid_617723
  var valid_617724 = header.getOrDefault("X-Amz-Signature")
  valid_617724 = validateParameter(valid_617724, JString, required = false,
                                 default = nil)
  if valid_617724 != nil:
    section.add "X-Amz-Signature", valid_617724
  var valid_617725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617725 = validateParameter(valid_617725, JString, required = false,
                                 default = nil)
  if valid_617725 != nil:
    section.add "X-Amz-SignedHeaders", valid_617725
  var valid_617726 = header.getOrDefault("X-Amz-Target")
  valid_617726 = validateParameter(valid_617726, JString, required = true, default = newJString(
      "AWSWAF_20190729.GetRuleGroup"))
  if valid_617726 != nil:
    section.add "X-Amz-Target", valid_617726
  var valid_617727 = header.getOrDefault("X-Amz-Credential")
  valid_617727 = validateParameter(valid_617727, JString, required = false,
                                 default = nil)
  if valid_617727 != nil:
    section.add "X-Amz-Credential", valid_617727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617729: Call_GetRuleGroup_617717; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the specified <a>RuleGroup</a>.</p>
  ## 
  let valid = call_617729.validator(path, query, header, formData, body, _)
  let scheme = call_617729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617729.url(scheme.get, call_617729.host, call_617729.base,
                         call_617729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617729, url, valid, _)

proc call*(call_617730: Call_GetRuleGroup_617717; body: JsonNode): Recallable =
  ## getRuleGroup
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the specified <a>RuleGroup</a>.</p>
  ##   body: JObject (required)
  var body_617731 = newJObject()
  if body != nil:
    body_617731 = body
  result = call_617730.call(nil, nil, nil, nil, body_617731)

var getRuleGroup* = Call_GetRuleGroup_617717(name: "getRuleGroup",
    meth: HttpMethod.HttpPost, host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.GetRuleGroup",
    validator: validate_GetRuleGroup_617718, base: "/", url: url_GetRuleGroup_617719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSampledRequests_617732 = ref object of OpenApiRestCall_616866
proc url_GetSampledRequests_617734(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSampledRequests_617733(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Gets detailed information about a specified number of requests--a sample--that AWS WAF randomly selects from among the first 5,000 requests that your AWS resource received during a time range that you choose. You can specify a sample size of up to 500 requests, and you can specify any time range in the previous three hours.</p> <p> <code>GetSampledRequests</code> returns a time range, which is usually the time range that you specified. However, if your resource (such as a CloudFront distribution) received 5,000 requests before the specified time range elapsed, <code>GetSampledRequests</code> returns an updated time range. This new time range indicates the actual period during which AWS WAF selected the requests in the sample.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617735 = header.getOrDefault("X-Amz-Date")
  valid_617735 = validateParameter(valid_617735, JString, required = false,
                                 default = nil)
  if valid_617735 != nil:
    section.add "X-Amz-Date", valid_617735
  var valid_617736 = header.getOrDefault("X-Amz-Security-Token")
  valid_617736 = validateParameter(valid_617736, JString, required = false,
                                 default = nil)
  if valid_617736 != nil:
    section.add "X-Amz-Security-Token", valid_617736
  var valid_617737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617737 = validateParameter(valid_617737, JString, required = false,
                                 default = nil)
  if valid_617737 != nil:
    section.add "X-Amz-Content-Sha256", valid_617737
  var valid_617738 = header.getOrDefault("X-Amz-Algorithm")
  valid_617738 = validateParameter(valid_617738, JString, required = false,
                                 default = nil)
  if valid_617738 != nil:
    section.add "X-Amz-Algorithm", valid_617738
  var valid_617739 = header.getOrDefault("X-Amz-Signature")
  valid_617739 = validateParameter(valid_617739, JString, required = false,
                                 default = nil)
  if valid_617739 != nil:
    section.add "X-Amz-Signature", valid_617739
  var valid_617740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617740 = validateParameter(valid_617740, JString, required = false,
                                 default = nil)
  if valid_617740 != nil:
    section.add "X-Amz-SignedHeaders", valid_617740
  var valid_617741 = header.getOrDefault("X-Amz-Target")
  valid_617741 = validateParameter(valid_617741, JString, required = true, default = newJString(
      "AWSWAF_20190729.GetSampledRequests"))
  if valid_617741 != nil:
    section.add "X-Amz-Target", valid_617741
  var valid_617742 = header.getOrDefault("X-Amz-Credential")
  valid_617742 = validateParameter(valid_617742, JString, required = false,
                                 default = nil)
  if valid_617742 != nil:
    section.add "X-Amz-Credential", valid_617742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617744: Call_GetSampledRequests_617732; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Gets detailed information about a specified number of requests--a sample--that AWS WAF randomly selects from among the first 5,000 requests that your AWS resource received during a time range that you choose. You can specify a sample size of up to 500 requests, and you can specify any time range in the previous three hours.</p> <p> <code>GetSampledRequests</code> returns a time range, which is usually the time range that you specified. However, if your resource (such as a CloudFront distribution) received 5,000 requests before the specified time range elapsed, <code>GetSampledRequests</code> returns an updated time range. This new time range indicates the actual period during which AWS WAF selected the requests in the sample.</p>
  ## 
  let valid = call_617744.validator(path, query, header, formData, body, _)
  let scheme = call_617744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617744.url(scheme.get, call_617744.host, call_617744.base,
                         call_617744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617744, url, valid, _)

proc call*(call_617745: Call_GetSampledRequests_617732; body: JsonNode): Recallable =
  ## getSampledRequests
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Gets detailed information about a specified number of requests--a sample--that AWS WAF randomly selects from among the first 5,000 requests that your AWS resource received during a time range that you choose. You can specify a sample size of up to 500 requests, and you can specify any time range in the previous three hours.</p> <p> <code>GetSampledRequests</code> returns a time range, which is usually the time range that you specified. However, if your resource (such as a CloudFront distribution) received 5,000 requests before the specified time range elapsed, <code>GetSampledRequests</code> returns an updated time range. This new time range indicates the actual period during which AWS WAF selected the requests in the sample.</p>
  ##   body: JObject (required)
  var body_617746 = newJObject()
  if body != nil:
    body_617746 = body
  result = call_617745.call(nil, nil, nil, nil, body_617746)

var getSampledRequests* = Call_GetSampledRequests_617732(
    name: "getSampledRequests", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.GetSampledRequests",
    validator: validate_GetSampledRequests_617733, base: "/",
    url: url_GetSampledRequests_617734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebACL_617747 = ref object of OpenApiRestCall_616866
proc url_GetWebACL_617749(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWebACL_617748(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the specified <a>WebACL</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617750 = header.getOrDefault("X-Amz-Date")
  valid_617750 = validateParameter(valid_617750, JString, required = false,
                                 default = nil)
  if valid_617750 != nil:
    section.add "X-Amz-Date", valid_617750
  var valid_617751 = header.getOrDefault("X-Amz-Security-Token")
  valid_617751 = validateParameter(valid_617751, JString, required = false,
                                 default = nil)
  if valid_617751 != nil:
    section.add "X-Amz-Security-Token", valid_617751
  var valid_617752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617752 = validateParameter(valid_617752, JString, required = false,
                                 default = nil)
  if valid_617752 != nil:
    section.add "X-Amz-Content-Sha256", valid_617752
  var valid_617753 = header.getOrDefault("X-Amz-Algorithm")
  valid_617753 = validateParameter(valid_617753, JString, required = false,
                                 default = nil)
  if valid_617753 != nil:
    section.add "X-Amz-Algorithm", valid_617753
  var valid_617754 = header.getOrDefault("X-Amz-Signature")
  valid_617754 = validateParameter(valid_617754, JString, required = false,
                                 default = nil)
  if valid_617754 != nil:
    section.add "X-Amz-Signature", valid_617754
  var valid_617755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617755 = validateParameter(valid_617755, JString, required = false,
                                 default = nil)
  if valid_617755 != nil:
    section.add "X-Amz-SignedHeaders", valid_617755
  var valid_617756 = header.getOrDefault("X-Amz-Target")
  valid_617756 = validateParameter(valid_617756, JString, required = true, default = newJString(
      "AWSWAF_20190729.GetWebACL"))
  if valid_617756 != nil:
    section.add "X-Amz-Target", valid_617756
  var valid_617757 = header.getOrDefault("X-Amz-Credential")
  valid_617757 = validateParameter(valid_617757, JString, required = false,
                                 default = nil)
  if valid_617757 != nil:
    section.add "X-Amz-Credential", valid_617757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617759: Call_GetWebACL_617747; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the specified <a>WebACL</a>.</p>
  ## 
  let valid = call_617759.validator(path, query, header, formData, body, _)
  let scheme = call_617759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617759.url(scheme.get, call_617759.host, call_617759.base,
                         call_617759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617759, url, valid, _)

proc call*(call_617760: Call_GetWebACL_617747; body: JsonNode): Recallable =
  ## getWebACL
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the specified <a>WebACL</a>.</p>
  ##   body: JObject (required)
  var body_617761 = newJObject()
  if body != nil:
    body_617761 = body
  result = call_617760.call(nil, nil, nil, nil, body_617761)

var getWebACL* = Call_GetWebACL_617747(name: "getWebACL", meth: HttpMethod.HttpPost,
                                    host: "wafv2.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_20190729.GetWebACL",
                                    validator: validate_GetWebACL_617748,
                                    base: "/", url: url_GetWebACL_617749,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebACLForResource_617762 = ref object of OpenApiRestCall_616866
proc url_GetWebACLForResource_617764(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWebACLForResource_617763(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the <a>WebACL</a> for the specified resource. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617765 = header.getOrDefault("X-Amz-Date")
  valid_617765 = validateParameter(valid_617765, JString, required = false,
                                 default = nil)
  if valid_617765 != nil:
    section.add "X-Amz-Date", valid_617765
  var valid_617766 = header.getOrDefault("X-Amz-Security-Token")
  valid_617766 = validateParameter(valid_617766, JString, required = false,
                                 default = nil)
  if valid_617766 != nil:
    section.add "X-Amz-Security-Token", valid_617766
  var valid_617767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617767 = validateParameter(valid_617767, JString, required = false,
                                 default = nil)
  if valid_617767 != nil:
    section.add "X-Amz-Content-Sha256", valid_617767
  var valid_617768 = header.getOrDefault("X-Amz-Algorithm")
  valid_617768 = validateParameter(valid_617768, JString, required = false,
                                 default = nil)
  if valid_617768 != nil:
    section.add "X-Amz-Algorithm", valid_617768
  var valid_617769 = header.getOrDefault("X-Amz-Signature")
  valid_617769 = validateParameter(valid_617769, JString, required = false,
                                 default = nil)
  if valid_617769 != nil:
    section.add "X-Amz-Signature", valid_617769
  var valid_617770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617770 = validateParameter(valid_617770, JString, required = false,
                                 default = nil)
  if valid_617770 != nil:
    section.add "X-Amz-SignedHeaders", valid_617770
  var valid_617771 = header.getOrDefault("X-Amz-Target")
  valid_617771 = validateParameter(valid_617771, JString, required = true, default = newJString(
      "AWSWAF_20190729.GetWebACLForResource"))
  if valid_617771 != nil:
    section.add "X-Amz-Target", valid_617771
  var valid_617772 = header.getOrDefault("X-Amz-Credential")
  valid_617772 = validateParameter(valid_617772, JString, required = false,
                                 default = nil)
  if valid_617772 != nil:
    section.add "X-Amz-Credential", valid_617772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617774: Call_GetWebACLForResource_617762; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the <a>WebACL</a> for the specified resource. </p>
  ## 
  let valid = call_617774.validator(path, query, header, formData, body, _)
  let scheme = call_617774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617774.url(scheme.get, call_617774.host, call_617774.base,
                         call_617774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617774, url, valid, _)

proc call*(call_617775: Call_GetWebACLForResource_617762; body: JsonNode): Recallable =
  ## getWebACLForResource
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the <a>WebACL</a> for the specified resource. </p>
  ##   body: JObject (required)
  var body_617776 = newJObject()
  if body != nil:
    body_617776 = body
  result = call_617775.call(nil, nil, nil, nil, body_617776)

var getWebACLForResource* = Call_GetWebACLForResource_617762(
    name: "getWebACLForResource", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.GetWebACLForResource",
    validator: validate_GetWebACLForResource_617763, base: "/",
    url: url_GetWebACLForResource_617764, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAvailableManagedRuleGroups_617777 = ref object of OpenApiRestCall_616866
proc url_ListAvailableManagedRuleGroups_617779(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAvailableManagedRuleGroups_617778(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of managed rule groups that are available for you to use. This list includes all AWS Managed Rules rule groups and the AWS Marketplace managed rule groups that you're subscribed to.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617780 = header.getOrDefault("X-Amz-Date")
  valid_617780 = validateParameter(valid_617780, JString, required = false,
                                 default = nil)
  if valid_617780 != nil:
    section.add "X-Amz-Date", valid_617780
  var valid_617781 = header.getOrDefault("X-Amz-Security-Token")
  valid_617781 = validateParameter(valid_617781, JString, required = false,
                                 default = nil)
  if valid_617781 != nil:
    section.add "X-Amz-Security-Token", valid_617781
  var valid_617782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617782 = validateParameter(valid_617782, JString, required = false,
                                 default = nil)
  if valid_617782 != nil:
    section.add "X-Amz-Content-Sha256", valid_617782
  var valid_617783 = header.getOrDefault("X-Amz-Algorithm")
  valid_617783 = validateParameter(valid_617783, JString, required = false,
                                 default = nil)
  if valid_617783 != nil:
    section.add "X-Amz-Algorithm", valid_617783
  var valid_617784 = header.getOrDefault("X-Amz-Signature")
  valid_617784 = validateParameter(valid_617784, JString, required = false,
                                 default = nil)
  if valid_617784 != nil:
    section.add "X-Amz-Signature", valid_617784
  var valid_617785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617785 = validateParameter(valid_617785, JString, required = false,
                                 default = nil)
  if valid_617785 != nil:
    section.add "X-Amz-SignedHeaders", valid_617785
  var valid_617786 = header.getOrDefault("X-Amz-Target")
  valid_617786 = validateParameter(valid_617786, JString, required = true, default = newJString(
      "AWSWAF_20190729.ListAvailableManagedRuleGroups"))
  if valid_617786 != nil:
    section.add "X-Amz-Target", valid_617786
  var valid_617787 = header.getOrDefault("X-Amz-Credential")
  valid_617787 = validateParameter(valid_617787, JString, required = false,
                                 default = nil)
  if valid_617787 != nil:
    section.add "X-Amz-Credential", valid_617787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617789: Call_ListAvailableManagedRuleGroups_617777;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of managed rule groups that are available for you to use. This list includes all AWS Managed Rules rule groups and the AWS Marketplace managed rule groups that you're subscribed to.</p>
  ## 
  let valid = call_617789.validator(path, query, header, formData, body, _)
  let scheme = call_617789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617789.url(scheme.get, call_617789.host, call_617789.base,
                         call_617789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617789, url, valid, _)

proc call*(call_617790: Call_ListAvailableManagedRuleGroups_617777; body: JsonNode): Recallable =
  ## listAvailableManagedRuleGroups
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of managed rule groups that are available for you to use. This list includes all AWS Managed Rules rule groups and the AWS Marketplace managed rule groups that you're subscribed to.</p>
  ##   body: JObject (required)
  var body_617791 = newJObject()
  if body != nil:
    body_617791 = body
  result = call_617790.call(nil, nil, nil, nil, body_617791)

var listAvailableManagedRuleGroups* = Call_ListAvailableManagedRuleGroups_617777(
    name: "listAvailableManagedRuleGroups", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.ListAvailableManagedRuleGroups",
    validator: validate_ListAvailableManagedRuleGroups_617778, base: "/",
    url: url_ListAvailableManagedRuleGroups_617779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIPSets_617792 = ref object of OpenApiRestCall_616866
proc url_ListIPSets_617794(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIPSets_617793(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of <a>IPSetSummary</a> objects for the IP sets that you manage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617795 = header.getOrDefault("X-Amz-Date")
  valid_617795 = validateParameter(valid_617795, JString, required = false,
                                 default = nil)
  if valid_617795 != nil:
    section.add "X-Amz-Date", valid_617795
  var valid_617796 = header.getOrDefault("X-Amz-Security-Token")
  valid_617796 = validateParameter(valid_617796, JString, required = false,
                                 default = nil)
  if valid_617796 != nil:
    section.add "X-Amz-Security-Token", valid_617796
  var valid_617797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617797 = validateParameter(valid_617797, JString, required = false,
                                 default = nil)
  if valid_617797 != nil:
    section.add "X-Amz-Content-Sha256", valid_617797
  var valid_617798 = header.getOrDefault("X-Amz-Algorithm")
  valid_617798 = validateParameter(valid_617798, JString, required = false,
                                 default = nil)
  if valid_617798 != nil:
    section.add "X-Amz-Algorithm", valid_617798
  var valid_617799 = header.getOrDefault("X-Amz-Signature")
  valid_617799 = validateParameter(valid_617799, JString, required = false,
                                 default = nil)
  if valid_617799 != nil:
    section.add "X-Amz-Signature", valid_617799
  var valid_617800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617800 = validateParameter(valid_617800, JString, required = false,
                                 default = nil)
  if valid_617800 != nil:
    section.add "X-Amz-SignedHeaders", valid_617800
  var valid_617801 = header.getOrDefault("X-Amz-Target")
  valid_617801 = validateParameter(valid_617801, JString, required = true, default = newJString(
      "AWSWAF_20190729.ListIPSets"))
  if valid_617801 != nil:
    section.add "X-Amz-Target", valid_617801
  var valid_617802 = header.getOrDefault("X-Amz-Credential")
  valid_617802 = validateParameter(valid_617802, JString, required = false,
                                 default = nil)
  if valid_617802 != nil:
    section.add "X-Amz-Credential", valid_617802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617804: Call_ListIPSets_617792; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of <a>IPSetSummary</a> objects for the IP sets that you manage.</p>
  ## 
  let valid = call_617804.validator(path, query, header, formData, body, _)
  let scheme = call_617804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617804.url(scheme.get, call_617804.host, call_617804.base,
                         call_617804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617804, url, valid, _)

proc call*(call_617805: Call_ListIPSets_617792; body: JsonNode): Recallable =
  ## listIPSets
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of <a>IPSetSummary</a> objects for the IP sets that you manage.</p>
  ##   body: JObject (required)
  var body_617806 = newJObject()
  if body != nil:
    body_617806 = body
  result = call_617805.call(nil, nil, nil, nil, body_617806)

var listIPSets* = Call_ListIPSets_617792(name: "listIPSets",
                                      meth: HttpMethod.HttpPost,
                                      host: "wafv2.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_20190729.ListIPSets",
                                      validator: validate_ListIPSets_617793,
                                      base: "/", url: url_ListIPSets_617794,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggingConfigurations_617807 = ref object of OpenApiRestCall_616866
proc url_ListLoggingConfigurations_617809(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLoggingConfigurations_617808(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of your <a>LoggingConfiguration</a> objects.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617810 = header.getOrDefault("X-Amz-Date")
  valid_617810 = validateParameter(valid_617810, JString, required = false,
                                 default = nil)
  if valid_617810 != nil:
    section.add "X-Amz-Date", valid_617810
  var valid_617811 = header.getOrDefault("X-Amz-Security-Token")
  valid_617811 = validateParameter(valid_617811, JString, required = false,
                                 default = nil)
  if valid_617811 != nil:
    section.add "X-Amz-Security-Token", valid_617811
  var valid_617812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617812 = validateParameter(valid_617812, JString, required = false,
                                 default = nil)
  if valid_617812 != nil:
    section.add "X-Amz-Content-Sha256", valid_617812
  var valid_617813 = header.getOrDefault("X-Amz-Algorithm")
  valid_617813 = validateParameter(valid_617813, JString, required = false,
                                 default = nil)
  if valid_617813 != nil:
    section.add "X-Amz-Algorithm", valid_617813
  var valid_617814 = header.getOrDefault("X-Amz-Signature")
  valid_617814 = validateParameter(valid_617814, JString, required = false,
                                 default = nil)
  if valid_617814 != nil:
    section.add "X-Amz-Signature", valid_617814
  var valid_617815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617815 = validateParameter(valid_617815, JString, required = false,
                                 default = nil)
  if valid_617815 != nil:
    section.add "X-Amz-SignedHeaders", valid_617815
  var valid_617816 = header.getOrDefault("X-Amz-Target")
  valid_617816 = validateParameter(valid_617816, JString, required = true, default = newJString(
      "AWSWAF_20190729.ListLoggingConfigurations"))
  if valid_617816 != nil:
    section.add "X-Amz-Target", valid_617816
  var valid_617817 = header.getOrDefault("X-Amz-Credential")
  valid_617817 = validateParameter(valid_617817, JString, required = false,
                                 default = nil)
  if valid_617817 != nil:
    section.add "X-Amz-Credential", valid_617817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617819: Call_ListLoggingConfigurations_617807;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of your <a>LoggingConfiguration</a> objects.</p>
  ## 
  let valid = call_617819.validator(path, query, header, formData, body, _)
  let scheme = call_617819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617819.url(scheme.get, call_617819.host, call_617819.base,
                         call_617819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617819, url, valid, _)

proc call*(call_617820: Call_ListLoggingConfigurations_617807; body: JsonNode): Recallable =
  ## listLoggingConfigurations
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of your <a>LoggingConfiguration</a> objects.</p>
  ##   body: JObject (required)
  var body_617821 = newJObject()
  if body != nil:
    body_617821 = body
  result = call_617820.call(nil, nil, nil, nil, body_617821)

var listLoggingConfigurations* = Call_ListLoggingConfigurations_617807(
    name: "listLoggingConfigurations", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.ListLoggingConfigurations",
    validator: validate_ListLoggingConfigurations_617808, base: "/",
    url: url_ListLoggingConfigurations_617809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRegexPatternSets_617822 = ref object of OpenApiRestCall_616866
proc url_ListRegexPatternSets_617824(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRegexPatternSets_617823(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of <a>RegexPatternSetSummary</a> objects for the regex pattern sets that you manage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617825 = header.getOrDefault("X-Amz-Date")
  valid_617825 = validateParameter(valid_617825, JString, required = false,
                                 default = nil)
  if valid_617825 != nil:
    section.add "X-Amz-Date", valid_617825
  var valid_617826 = header.getOrDefault("X-Amz-Security-Token")
  valid_617826 = validateParameter(valid_617826, JString, required = false,
                                 default = nil)
  if valid_617826 != nil:
    section.add "X-Amz-Security-Token", valid_617826
  var valid_617827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617827 = validateParameter(valid_617827, JString, required = false,
                                 default = nil)
  if valid_617827 != nil:
    section.add "X-Amz-Content-Sha256", valid_617827
  var valid_617828 = header.getOrDefault("X-Amz-Algorithm")
  valid_617828 = validateParameter(valid_617828, JString, required = false,
                                 default = nil)
  if valid_617828 != nil:
    section.add "X-Amz-Algorithm", valid_617828
  var valid_617829 = header.getOrDefault("X-Amz-Signature")
  valid_617829 = validateParameter(valid_617829, JString, required = false,
                                 default = nil)
  if valid_617829 != nil:
    section.add "X-Amz-Signature", valid_617829
  var valid_617830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617830 = validateParameter(valid_617830, JString, required = false,
                                 default = nil)
  if valid_617830 != nil:
    section.add "X-Amz-SignedHeaders", valid_617830
  var valid_617831 = header.getOrDefault("X-Amz-Target")
  valid_617831 = validateParameter(valid_617831, JString, required = true, default = newJString(
      "AWSWAF_20190729.ListRegexPatternSets"))
  if valid_617831 != nil:
    section.add "X-Amz-Target", valid_617831
  var valid_617832 = header.getOrDefault("X-Amz-Credential")
  valid_617832 = validateParameter(valid_617832, JString, required = false,
                                 default = nil)
  if valid_617832 != nil:
    section.add "X-Amz-Credential", valid_617832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617834: Call_ListRegexPatternSets_617822; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of <a>RegexPatternSetSummary</a> objects for the regex pattern sets that you manage.</p>
  ## 
  let valid = call_617834.validator(path, query, header, formData, body, _)
  let scheme = call_617834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617834.url(scheme.get, call_617834.host, call_617834.base,
                         call_617834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617834, url, valid, _)

proc call*(call_617835: Call_ListRegexPatternSets_617822; body: JsonNode): Recallable =
  ## listRegexPatternSets
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of <a>RegexPatternSetSummary</a> objects for the regex pattern sets that you manage.</p>
  ##   body: JObject (required)
  var body_617836 = newJObject()
  if body != nil:
    body_617836 = body
  result = call_617835.call(nil, nil, nil, nil, body_617836)

var listRegexPatternSets* = Call_ListRegexPatternSets_617822(
    name: "listRegexPatternSets", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.ListRegexPatternSets",
    validator: validate_ListRegexPatternSets_617823, base: "/",
    url: url_ListRegexPatternSets_617824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourcesForWebACL_617837 = ref object of OpenApiRestCall_616866
proc url_ListResourcesForWebACL_617839(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourcesForWebACL_617838(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of the Amazon Resource Names (ARNs) for the regional resources that are associated with the specified web ACL. If you want the list of AWS CloudFront resources, use the AWS CloudFront call <code>ListDistributionsByWebACLId</code>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617840 = header.getOrDefault("X-Amz-Date")
  valid_617840 = validateParameter(valid_617840, JString, required = false,
                                 default = nil)
  if valid_617840 != nil:
    section.add "X-Amz-Date", valid_617840
  var valid_617841 = header.getOrDefault("X-Amz-Security-Token")
  valid_617841 = validateParameter(valid_617841, JString, required = false,
                                 default = nil)
  if valid_617841 != nil:
    section.add "X-Amz-Security-Token", valid_617841
  var valid_617842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617842 = validateParameter(valid_617842, JString, required = false,
                                 default = nil)
  if valid_617842 != nil:
    section.add "X-Amz-Content-Sha256", valid_617842
  var valid_617843 = header.getOrDefault("X-Amz-Algorithm")
  valid_617843 = validateParameter(valid_617843, JString, required = false,
                                 default = nil)
  if valid_617843 != nil:
    section.add "X-Amz-Algorithm", valid_617843
  var valid_617844 = header.getOrDefault("X-Amz-Signature")
  valid_617844 = validateParameter(valid_617844, JString, required = false,
                                 default = nil)
  if valid_617844 != nil:
    section.add "X-Amz-Signature", valid_617844
  var valid_617845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617845 = validateParameter(valid_617845, JString, required = false,
                                 default = nil)
  if valid_617845 != nil:
    section.add "X-Amz-SignedHeaders", valid_617845
  var valid_617846 = header.getOrDefault("X-Amz-Target")
  valid_617846 = validateParameter(valid_617846, JString, required = true, default = newJString(
      "AWSWAF_20190729.ListResourcesForWebACL"))
  if valid_617846 != nil:
    section.add "X-Amz-Target", valid_617846
  var valid_617847 = header.getOrDefault("X-Amz-Credential")
  valid_617847 = validateParameter(valid_617847, JString, required = false,
                                 default = nil)
  if valid_617847 != nil:
    section.add "X-Amz-Credential", valid_617847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617849: Call_ListResourcesForWebACL_617837; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of the Amazon Resource Names (ARNs) for the regional resources that are associated with the specified web ACL. If you want the list of AWS CloudFront resources, use the AWS CloudFront call <code>ListDistributionsByWebACLId</code>. </p>
  ## 
  let valid = call_617849.validator(path, query, header, formData, body, _)
  let scheme = call_617849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617849.url(scheme.get, call_617849.host, call_617849.base,
                         call_617849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617849, url, valid, _)

proc call*(call_617850: Call_ListResourcesForWebACL_617837; body: JsonNode): Recallable =
  ## listResourcesForWebACL
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of the Amazon Resource Names (ARNs) for the regional resources that are associated with the specified web ACL. If you want the list of AWS CloudFront resources, use the AWS CloudFront call <code>ListDistributionsByWebACLId</code>. </p>
  ##   body: JObject (required)
  var body_617851 = newJObject()
  if body != nil:
    body_617851 = body
  result = call_617850.call(nil, nil, nil, nil, body_617851)

var listResourcesForWebACL* = Call_ListResourcesForWebACL_617837(
    name: "listResourcesForWebACL", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.ListResourcesForWebACL",
    validator: validate_ListResourcesForWebACL_617838, base: "/",
    url: url_ListResourcesForWebACL_617839, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuleGroups_617852 = ref object of OpenApiRestCall_616866
proc url_ListRuleGroups_617854(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRuleGroups_617853(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of <a>RuleGroupSummary</a> objects for the rule groups that you manage. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617855 = header.getOrDefault("X-Amz-Date")
  valid_617855 = validateParameter(valid_617855, JString, required = false,
                                 default = nil)
  if valid_617855 != nil:
    section.add "X-Amz-Date", valid_617855
  var valid_617856 = header.getOrDefault("X-Amz-Security-Token")
  valid_617856 = validateParameter(valid_617856, JString, required = false,
                                 default = nil)
  if valid_617856 != nil:
    section.add "X-Amz-Security-Token", valid_617856
  var valid_617857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617857 = validateParameter(valid_617857, JString, required = false,
                                 default = nil)
  if valid_617857 != nil:
    section.add "X-Amz-Content-Sha256", valid_617857
  var valid_617858 = header.getOrDefault("X-Amz-Algorithm")
  valid_617858 = validateParameter(valid_617858, JString, required = false,
                                 default = nil)
  if valid_617858 != nil:
    section.add "X-Amz-Algorithm", valid_617858
  var valid_617859 = header.getOrDefault("X-Amz-Signature")
  valid_617859 = validateParameter(valid_617859, JString, required = false,
                                 default = nil)
  if valid_617859 != nil:
    section.add "X-Amz-Signature", valid_617859
  var valid_617860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617860 = validateParameter(valid_617860, JString, required = false,
                                 default = nil)
  if valid_617860 != nil:
    section.add "X-Amz-SignedHeaders", valid_617860
  var valid_617861 = header.getOrDefault("X-Amz-Target")
  valid_617861 = validateParameter(valid_617861, JString, required = true, default = newJString(
      "AWSWAF_20190729.ListRuleGroups"))
  if valid_617861 != nil:
    section.add "X-Amz-Target", valid_617861
  var valid_617862 = header.getOrDefault("X-Amz-Credential")
  valid_617862 = validateParameter(valid_617862, JString, required = false,
                                 default = nil)
  if valid_617862 != nil:
    section.add "X-Amz-Credential", valid_617862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617864: Call_ListRuleGroups_617852; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of <a>RuleGroupSummary</a> objects for the rule groups that you manage. </p>
  ## 
  let valid = call_617864.validator(path, query, header, formData, body, _)
  let scheme = call_617864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617864.url(scheme.get, call_617864.host, call_617864.base,
                         call_617864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617864, url, valid, _)

proc call*(call_617865: Call_ListRuleGroups_617852; body: JsonNode): Recallable =
  ## listRuleGroups
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of <a>RuleGroupSummary</a> objects for the rule groups that you manage. </p>
  ##   body: JObject (required)
  var body_617866 = newJObject()
  if body != nil:
    body_617866 = body
  result = call_617865.call(nil, nil, nil, nil, body_617866)

var listRuleGroups* = Call_ListRuleGroups_617852(name: "listRuleGroups",
    meth: HttpMethod.HttpPost, host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.ListRuleGroups",
    validator: validate_ListRuleGroups_617853, base: "/", url: url_ListRuleGroups_617854,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_617867 = ref object of OpenApiRestCall_616866
proc url_ListTagsForResource_617869(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_617868(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the <a>TagInfoForResource</a> for the specified resource. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617870 = header.getOrDefault("X-Amz-Date")
  valid_617870 = validateParameter(valid_617870, JString, required = false,
                                 default = nil)
  if valid_617870 != nil:
    section.add "X-Amz-Date", valid_617870
  var valid_617871 = header.getOrDefault("X-Amz-Security-Token")
  valid_617871 = validateParameter(valid_617871, JString, required = false,
                                 default = nil)
  if valid_617871 != nil:
    section.add "X-Amz-Security-Token", valid_617871
  var valid_617872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617872 = validateParameter(valid_617872, JString, required = false,
                                 default = nil)
  if valid_617872 != nil:
    section.add "X-Amz-Content-Sha256", valid_617872
  var valid_617873 = header.getOrDefault("X-Amz-Algorithm")
  valid_617873 = validateParameter(valid_617873, JString, required = false,
                                 default = nil)
  if valid_617873 != nil:
    section.add "X-Amz-Algorithm", valid_617873
  var valid_617874 = header.getOrDefault("X-Amz-Signature")
  valid_617874 = validateParameter(valid_617874, JString, required = false,
                                 default = nil)
  if valid_617874 != nil:
    section.add "X-Amz-Signature", valid_617874
  var valid_617875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617875 = validateParameter(valid_617875, JString, required = false,
                                 default = nil)
  if valid_617875 != nil:
    section.add "X-Amz-SignedHeaders", valid_617875
  var valid_617876 = header.getOrDefault("X-Amz-Target")
  valid_617876 = validateParameter(valid_617876, JString, required = true, default = newJString(
      "AWSWAF_20190729.ListTagsForResource"))
  if valid_617876 != nil:
    section.add "X-Amz-Target", valid_617876
  var valid_617877 = header.getOrDefault("X-Amz-Credential")
  valid_617877 = validateParameter(valid_617877, JString, required = false,
                                 default = nil)
  if valid_617877 != nil:
    section.add "X-Amz-Credential", valid_617877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617879: Call_ListTagsForResource_617867; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the <a>TagInfoForResource</a> for the specified resource. </p>
  ## 
  let valid = call_617879.validator(path, query, header, formData, body, _)
  let scheme = call_617879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617879.url(scheme.get, call_617879.host, call_617879.base,
                         call_617879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617879, url, valid, _)

proc call*(call_617880: Call_ListTagsForResource_617867; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves the <a>TagInfoForResource</a> for the specified resource. </p>
  ##   body: JObject (required)
  var body_617881 = newJObject()
  if body != nil:
    body_617881 = body
  result = call_617880.call(nil, nil, nil, nil, body_617881)

var listTagsForResource* = Call_ListTagsForResource_617867(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.ListTagsForResource",
    validator: validate_ListTagsForResource_617868, base: "/",
    url: url_ListTagsForResource_617869, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebACLs_617882 = ref object of OpenApiRestCall_616866
proc url_ListWebACLs_617884(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWebACLs_617883(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of <a>WebACLSummary</a> objects for the web ACLs that you manage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617885 = header.getOrDefault("X-Amz-Date")
  valid_617885 = validateParameter(valid_617885, JString, required = false,
                                 default = nil)
  if valid_617885 != nil:
    section.add "X-Amz-Date", valid_617885
  var valid_617886 = header.getOrDefault("X-Amz-Security-Token")
  valid_617886 = validateParameter(valid_617886, JString, required = false,
                                 default = nil)
  if valid_617886 != nil:
    section.add "X-Amz-Security-Token", valid_617886
  var valid_617887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617887 = validateParameter(valid_617887, JString, required = false,
                                 default = nil)
  if valid_617887 != nil:
    section.add "X-Amz-Content-Sha256", valid_617887
  var valid_617888 = header.getOrDefault("X-Amz-Algorithm")
  valid_617888 = validateParameter(valid_617888, JString, required = false,
                                 default = nil)
  if valid_617888 != nil:
    section.add "X-Amz-Algorithm", valid_617888
  var valid_617889 = header.getOrDefault("X-Amz-Signature")
  valid_617889 = validateParameter(valid_617889, JString, required = false,
                                 default = nil)
  if valid_617889 != nil:
    section.add "X-Amz-Signature", valid_617889
  var valid_617890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617890 = validateParameter(valid_617890, JString, required = false,
                                 default = nil)
  if valid_617890 != nil:
    section.add "X-Amz-SignedHeaders", valid_617890
  var valid_617891 = header.getOrDefault("X-Amz-Target")
  valid_617891 = validateParameter(valid_617891, JString, required = true, default = newJString(
      "AWSWAF_20190729.ListWebACLs"))
  if valid_617891 != nil:
    section.add "X-Amz-Target", valid_617891
  var valid_617892 = header.getOrDefault("X-Amz-Credential")
  valid_617892 = validateParameter(valid_617892, JString, required = false,
                                 default = nil)
  if valid_617892 != nil:
    section.add "X-Amz-Credential", valid_617892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617894: Call_ListWebACLs_617882; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of <a>WebACLSummary</a> objects for the web ACLs that you manage.</p>
  ## 
  let valid = call_617894.validator(path, query, header, formData, body, _)
  let scheme = call_617894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617894.url(scheme.get, call_617894.host, call_617894.base,
                         call_617894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617894, url, valid, _)

proc call*(call_617895: Call_ListWebACLs_617882; body: JsonNode): Recallable =
  ## listWebACLs
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Retrieves an array of <a>WebACLSummary</a> objects for the web ACLs that you manage.</p>
  ##   body: JObject (required)
  var body_617896 = newJObject()
  if body != nil:
    body_617896 = body
  result = call_617895.call(nil, nil, nil, nil, body_617896)

var listWebACLs* = Call_ListWebACLs_617882(name: "listWebACLs",
                                        meth: HttpMethod.HttpPost,
                                        host: "wafv2.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_20190729.ListWebACLs",
                                        validator: validate_ListWebACLs_617883,
                                        base: "/", url: url_ListWebACLs_617884,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingConfiguration_617897 = ref object of OpenApiRestCall_616866
proc url_PutLoggingConfiguration_617899(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutLoggingConfiguration_617898(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Enables the specified <a>LoggingConfiguration</a>, to start logging from a web ACL, according to the configuration provided.</p> <p>You can access information about all traffic that AWS WAF inspects using the following steps:</p> <ol> <li> <p>Create an Amazon Kinesis Data Firehose. </p> <p>Create the data firehose with a PUT source and in the region that you are operating. If you are capturing logs for Amazon CloudFront, always create the firehose in US East (N. Virginia). </p> <note> <p>Do not create the data firehose using a <code>Kinesis stream</code> as your source.</p> </note> </li> <li> <p>Associate that firehose to your web ACL using a <code>PutLoggingConfiguration</code> request.</p> </li> </ol> <p>When you successfully enable logging using a <code>PutLoggingConfiguration</code> request, AWS WAF will create a service linked role with the necessary permissions to write logs to the Amazon Kinesis Data Firehose. For more information, see <a href="https://docs.aws.amazon.com/waf/latest/developerguide/logging.html">Logging Web ACL Traffic Information</a> in the <i>AWS WAF Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617900 = header.getOrDefault("X-Amz-Date")
  valid_617900 = validateParameter(valid_617900, JString, required = false,
                                 default = nil)
  if valid_617900 != nil:
    section.add "X-Amz-Date", valid_617900
  var valid_617901 = header.getOrDefault("X-Amz-Security-Token")
  valid_617901 = validateParameter(valid_617901, JString, required = false,
                                 default = nil)
  if valid_617901 != nil:
    section.add "X-Amz-Security-Token", valid_617901
  var valid_617902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617902 = validateParameter(valid_617902, JString, required = false,
                                 default = nil)
  if valid_617902 != nil:
    section.add "X-Amz-Content-Sha256", valid_617902
  var valid_617903 = header.getOrDefault("X-Amz-Algorithm")
  valid_617903 = validateParameter(valid_617903, JString, required = false,
                                 default = nil)
  if valid_617903 != nil:
    section.add "X-Amz-Algorithm", valid_617903
  var valid_617904 = header.getOrDefault("X-Amz-Signature")
  valid_617904 = validateParameter(valid_617904, JString, required = false,
                                 default = nil)
  if valid_617904 != nil:
    section.add "X-Amz-Signature", valid_617904
  var valid_617905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617905 = validateParameter(valid_617905, JString, required = false,
                                 default = nil)
  if valid_617905 != nil:
    section.add "X-Amz-SignedHeaders", valid_617905
  var valid_617906 = header.getOrDefault("X-Amz-Target")
  valid_617906 = validateParameter(valid_617906, JString, required = true, default = newJString(
      "AWSWAF_20190729.PutLoggingConfiguration"))
  if valid_617906 != nil:
    section.add "X-Amz-Target", valid_617906
  var valid_617907 = header.getOrDefault("X-Amz-Credential")
  valid_617907 = validateParameter(valid_617907, JString, required = false,
                                 default = nil)
  if valid_617907 != nil:
    section.add "X-Amz-Credential", valid_617907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617909: Call_PutLoggingConfiguration_617897; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Enables the specified <a>LoggingConfiguration</a>, to start logging from a web ACL, according to the configuration provided.</p> <p>You can access information about all traffic that AWS WAF inspects using the following steps:</p> <ol> <li> <p>Create an Amazon Kinesis Data Firehose. </p> <p>Create the data firehose with a PUT source and in the region that you are operating. If you are capturing logs for Amazon CloudFront, always create the firehose in US East (N. Virginia). </p> <note> <p>Do not create the data firehose using a <code>Kinesis stream</code> as your source.</p> </note> </li> <li> <p>Associate that firehose to your web ACL using a <code>PutLoggingConfiguration</code> request.</p> </li> </ol> <p>When you successfully enable logging using a <code>PutLoggingConfiguration</code> request, AWS WAF will create a service linked role with the necessary permissions to write logs to the Amazon Kinesis Data Firehose. For more information, see <a href="https://docs.aws.amazon.com/waf/latest/developerguide/logging.html">Logging Web ACL Traffic Information</a> in the <i>AWS WAF Developer Guide</i>.</p>
  ## 
  let valid = call_617909.validator(path, query, header, formData, body, _)
  let scheme = call_617909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617909.url(scheme.get, call_617909.host, call_617909.base,
                         call_617909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617909, url, valid, _)

proc call*(call_617910: Call_PutLoggingConfiguration_617897; body: JsonNode): Recallable =
  ## putLoggingConfiguration
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Enables the specified <a>LoggingConfiguration</a>, to start logging from a web ACL, according to the configuration provided.</p> <p>You can access information about all traffic that AWS WAF inspects using the following steps:</p> <ol> <li> <p>Create an Amazon Kinesis Data Firehose. </p> <p>Create the data firehose with a PUT source and in the region that you are operating. If you are capturing logs for Amazon CloudFront, always create the firehose in US East (N. Virginia). </p> <note> <p>Do not create the data firehose using a <code>Kinesis stream</code> as your source.</p> </note> </li> <li> <p>Associate that firehose to your web ACL using a <code>PutLoggingConfiguration</code> request.</p> </li> </ol> <p>When you successfully enable logging using a <code>PutLoggingConfiguration</code> request, AWS WAF will create a service linked role with the necessary permissions to write logs to the Amazon Kinesis Data Firehose. For more information, see <a href="https://docs.aws.amazon.com/waf/latest/developerguide/logging.html">Logging Web ACL Traffic Information</a> in the <i>AWS WAF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_617911 = newJObject()
  if body != nil:
    body_617911 = body
  result = call_617910.call(nil, nil, nil, nil, body_617911)

var putLoggingConfiguration* = Call_PutLoggingConfiguration_617897(
    name: "putLoggingConfiguration", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.PutLoggingConfiguration",
    validator: validate_PutLoggingConfiguration_617898, base: "/",
    url: url_PutLoggingConfiguration_617899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_617912 = ref object of OpenApiRestCall_616866
proc url_TagResource_617914(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_617913(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Associates tags with the specified AWS resource. Tags are key:value pairs that you can associate with AWS resources. For example, the tag key might be "customer" and the tag value might be "companyA." You can specify one or more tags to add to each container. You can add up to 50 tags to each AWS resource.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617915 = header.getOrDefault("X-Amz-Date")
  valid_617915 = validateParameter(valid_617915, JString, required = false,
                                 default = nil)
  if valid_617915 != nil:
    section.add "X-Amz-Date", valid_617915
  var valid_617916 = header.getOrDefault("X-Amz-Security-Token")
  valid_617916 = validateParameter(valid_617916, JString, required = false,
                                 default = nil)
  if valid_617916 != nil:
    section.add "X-Amz-Security-Token", valid_617916
  var valid_617917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617917 = validateParameter(valid_617917, JString, required = false,
                                 default = nil)
  if valid_617917 != nil:
    section.add "X-Amz-Content-Sha256", valid_617917
  var valid_617918 = header.getOrDefault("X-Amz-Algorithm")
  valid_617918 = validateParameter(valid_617918, JString, required = false,
                                 default = nil)
  if valid_617918 != nil:
    section.add "X-Amz-Algorithm", valid_617918
  var valid_617919 = header.getOrDefault("X-Amz-Signature")
  valid_617919 = validateParameter(valid_617919, JString, required = false,
                                 default = nil)
  if valid_617919 != nil:
    section.add "X-Amz-Signature", valid_617919
  var valid_617920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617920 = validateParameter(valid_617920, JString, required = false,
                                 default = nil)
  if valid_617920 != nil:
    section.add "X-Amz-SignedHeaders", valid_617920
  var valid_617921 = header.getOrDefault("X-Amz-Target")
  valid_617921 = validateParameter(valid_617921, JString, required = true, default = newJString(
      "AWSWAF_20190729.TagResource"))
  if valid_617921 != nil:
    section.add "X-Amz-Target", valid_617921
  var valid_617922 = header.getOrDefault("X-Amz-Credential")
  valid_617922 = validateParameter(valid_617922, JString, required = false,
                                 default = nil)
  if valid_617922 != nil:
    section.add "X-Amz-Credential", valid_617922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617924: Call_TagResource_617912; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Associates tags with the specified AWS resource. Tags are key:value pairs that you can associate with AWS resources. For example, the tag key might be "customer" and the tag value might be "companyA." You can specify one or more tags to add to each container. You can add up to 50 tags to each AWS resource.</p>
  ## 
  let valid = call_617924.validator(path, query, header, formData, body, _)
  let scheme = call_617924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617924.url(scheme.get, call_617924.host, call_617924.base,
                         call_617924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617924, url, valid, _)

proc call*(call_617925: Call_TagResource_617912; body: JsonNode): Recallable =
  ## tagResource
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Associates tags with the specified AWS resource. Tags are key:value pairs that you can associate with AWS resources. For example, the tag key might be "customer" and the tag value might be "companyA." You can specify one or more tags to add to each container. You can add up to 50 tags to each AWS resource.</p>
  ##   body: JObject (required)
  var body_617926 = newJObject()
  if body != nil:
    body_617926 = body
  result = call_617925.call(nil, nil, nil, nil, body_617926)

var tagResource* = Call_TagResource_617912(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "wafv2.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_20190729.TagResource",
                                        validator: validate_TagResource_617913,
                                        base: "/", url: url_TagResource_617914,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_617927 = ref object of OpenApiRestCall_616866
proc url_UntagResource_617929(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_617928(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Disassociates tags from an AWS resource. Tags are key:value pairs that you can associate with AWS resources. For example, the tag key might be "customer" and the tag value might be "companyA." You can specify one or more tags to add to each container. You can add up to 50 tags to each AWS resource.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617930 = header.getOrDefault("X-Amz-Date")
  valid_617930 = validateParameter(valid_617930, JString, required = false,
                                 default = nil)
  if valid_617930 != nil:
    section.add "X-Amz-Date", valid_617930
  var valid_617931 = header.getOrDefault("X-Amz-Security-Token")
  valid_617931 = validateParameter(valid_617931, JString, required = false,
                                 default = nil)
  if valid_617931 != nil:
    section.add "X-Amz-Security-Token", valid_617931
  var valid_617932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617932 = validateParameter(valid_617932, JString, required = false,
                                 default = nil)
  if valid_617932 != nil:
    section.add "X-Amz-Content-Sha256", valid_617932
  var valid_617933 = header.getOrDefault("X-Amz-Algorithm")
  valid_617933 = validateParameter(valid_617933, JString, required = false,
                                 default = nil)
  if valid_617933 != nil:
    section.add "X-Amz-Algorithm", valid_617933
  var valid_617934 = header.getOrDefault("X-Amz-Signature")
  valid_617934 = validateParameter(valid_617934, JString, required = false,
                                 default = nil)
  if valid_617934 != nil:
    section.add "X-Amz-Signature", valid_617934
  var valid_617935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617935 = validateParameter(valid_617935, JString, required = false,
                                 default = nil)
  if valid_617935 != nil:
    section.add "X-Amz-SignedHeaders", valid_617935
  var valid_617936 = header.getOrDefault("X-Amz-Target")
  valid_617936 = validateParameter(valid_617936, JString, required = true, default = newJString(
      "AWSWAF_20190729.UntagResource"))
  if valid_617936 != nil:
    section.add "X-Amz-Target", valid_617936
  var valid_617937 = header.getOrDefault("X-Amz-Credential")
  valid_617937 = validateParameter(valid_617937, JString, required = false,
                                 default = nil)
  if valid_617937 != nil:
    section.add "X-Amz-Credential", valid_617937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617939: Call_UntagResource_617927; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Disassociates tags from an AWS resource. Tags are key:value pairs that you can associate with AWS resources. For example, the tag key might be "customer" and the tag value might be "companyA." You can specify one or more tags to add to each container. You can add up to 50 tags to each AWS resource.</p>
  ## 
  let valid = call_617939.validator(path, query, header, formData, body, _)
  let scheme = call_617939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617939.url(scheme.get, call_617939.host, call_617939.base,
                         call_617939.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617939, url, valid, _)

proc call*(call_617940: Call_UntagResource_617927; body: JsonNode): Recallable =
  ## untagResource
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Disassociates tags from an AWS resource. Tags are key:value pairs that you can associate with AWS resources. For example, the tag key might be "customer" and the tag value might be "companyA." You can specify one or more tags to add to each container. You can add up to 50 tags to each AWS resource.</p>
  ##   body: JObject (required)
  var body_617941 = newJObject()
  if body != nil:
    body_617941 = body
  result = call_617940.call(nil, nil, nil, nil, body_617941)

var untagResource* = Call_UntagResource_617927(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.UntagResource",
    validator: validate_UntagResource_617928, base: "/", url: url_UntagResource_617929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIPSet_617942 = ref object of OpenApiRestCall_616866
proc url_UpdateIPSet_617944(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateIPSet_617943(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Updates the specified <a>IPSet</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617945 = header.getOrDefault("X-Amz-Date")
  valid_617945 = validateParameter(valid_617945, JString, required = false,
                                 default = nil)
  if valid_617945 != nil:
    section.add "X-Amz-Date", valid_617945
  var valid_617946 = header.getOrDefault("X-Amz-Security-Token")
  valid_617946 = validateParameter(valid_617946, JString, required = false,
                                 default = nil)
  if valid_617946 != nil:
    section.add "X-Amz-Security-Token", valid_617946
  var valid_617947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617947 = validateParameter(valid_617947, JString, required = false,
                                 default = nil)
  if valid_617947 != nil:
    section.add "X-Amz-Content-Sha256", valid_617947
  var valid_617948 = header.getOrDefault("X-Amz-Algorithm")
  valid_617948 = validateParameter(valid_617948, JString, required = false,
                                 default = nil)
  if valid_617948 != nil:
    section.add "X-Amz-Algorithm", valid_617948
  var valid_617949 = header.getOrDefault("X-Amz-Signature")
  valid_617949 = validateParameter(valid_617949, JString, required = false,
                                 default = nil)
  if valid_617949 != nil:
    section.add "X-Amz-Signature", valid_617949
  var valid_617950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617950 = validateParameter(valid_617950, JString, required = false,
                                 default = nil)
  if valid_617950 != nil:
    section.add "X-Amz-SignedHeaders", valid_617950
  var valid_617951 = header.getOrDefault("X-Amz-Target")
  valid_617951 = validateParameter(valid_617951, JString, required = true, default = newJString(
      "AWSWAF_20190729.UpdateIPSet"))
  if valid_617951 != nil:
    section.add "X-Amz-Target", valid_617951
  var valid_617952 = header.getOrDefault("X-Amz-Credential")
  valid_617952 = validateParameter(valid_617952, JString, required = false,
                                 default = nil)
  if valid_617952 != nil:
    section.add "X-Amz-Credential", valid_617952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617954: Call_UpdateIPSet_617942; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Updates the specified <a>IPSet</a>.</p>
  ## 
  let valid = call_617954.validator(path, query, header, formData, body, _)
  let scheme = call_617954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617954.url(scheme.get, call_617954.host, call_617954.base,
                         call_617954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617954, url, valid, _)

proc call*(call_617955: Call_UpdateIPSet_617942; body: JsonNode): Recallable =
  ## updateIPSet
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Updates the specified <a>IPSet</a>.</p>
  ##   body: JObject (required)
  var body_617956 = newJObject()
  if body != nil:
    body_617956 = body
  result = call_617955.call(nil, nil, nil, nil, body_617956)

var updateIPSet* = Call_UpdateIPSet_617942(name: "updateIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "wafv2.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_20190729.UpdateIPSet",
                                        validator: validate_UpdateIPSet_617943,
                                        base: "/", url: url_UpdateIPSet_617944,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRegexPatternSet_617957 = ref object of OpenApiRestCall_616866
proc url_UpdateRegexPatternSet_617959(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRegexPatternSet_617958(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Updates the specified <a>RegexPatternSet</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617960 = header.getOrDefault("X-Amz-Date")
  valid_617960 = validateParameter(valid_617960, JString, required = false,
                                 default = nil)
  if valid_617960 != nil:
    section.add "X-Amz-Date", valid_617960
  var valid_617961 = header.getOrDefault("X-Amz-Security-Token")
  valid_617961 = validateParameter(valid_617961, JString, required = false,
                                 default = nil)
  if valid_617961 != nil:
    section.add "X-Amz-Security-Token", valid_617961
  var valid_617962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617962 = validateParameter(valid_617962, JString, required = false,
                                 default = nil)
  if valid_617962 != nil:
    section.add "X-Amz-Content-Sha256", valid_617962
  var valid_617963 = header.getOrDefault("X-Amz-Algorithm")
  valid_617963 = validateParameter(valid_617963, JString, required = false,
                                 default = nil)
  if valid_617963 != nil:
    section.add "X-Amz-Algorithm", valid_617963
  var valid_617964 = header.getOrDefault("X-Amz-Signature")
  valid_617964 = validateParameter(valid_617964, JString, required = false,
                                 default = nil)
  if valid_617964 != nil:
    section.add "X-Amz-Signature", valid_617964
  var valid_617965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617965 = validateParameter(valid_617965, JString, required = false,
                                 default = nil)
  if valid_617965 != nil:
    section.add "X-Amz-SignedHeaders", valid_617965
  var valid_617966 = header.getOrDefault("X-Amz-Target")
  valid_617966 = validateParameter(valid_617966, JString, required = true, default = newJString(
      "AWSWAF_20190729.UpdateRegexPatternSet"))
  if valid_617966 != nil:
    section.add "X-Amz-Target", valid_617966
  var valid_617967 = header.getOrDefault("X-Amz-Credential")
  valid_617967 = validateParameter(valid_617967, JString, required = false,
                                 default = nil)
  if valid_617967 != nil:
    section.add "X-Amz-Credential", valid_617967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617969: Call_UpdateRegexPatternSet_617957; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Updates the specified <a>RegexPatternSet</a>.</p>
  ## 
  let valid = call_617969.validator(path, query, header, formData, body, _)
  let scheme = call_617969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617969.url(scheme.get, call_617969.host, call_617969.base,
                         call_617969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617969, url, valid, _)

proc call*(call_617970: Call_UpdateRegexPatternSet_617957; body: JsonNode): Recallable =
  ## updateRegexPatternSet
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Updates the specified <a>RegexPatternSet</a>.</p>
  ##   body: JObject (required)
  var body_617971 = newJObject()
  if body != nil:
    body_617971 = body
  result = call_617970.call(nil, nil, nil, nil, body_617971)

var updateRegexPatternSet* = Call_UpdateRegexPatternSet_617957(
    name: "updateRegexPatternSet", meth: HttpMethod.HttpPost,
    host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.UpdateRegexPatternSet",
    validator: validate_UpdateRegexPatternSet_617958, base: "/",
    url: url_UpdateRegexPatternSet_617959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleGroup_617972 = ref object of OpenApiRestCall_616866
proc url_UpdateRuleGroup_617974(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRuleGroup_617973(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Updates the specified <a>RuleGroup</a>.</p> <p> A rule group defines a collection of rules to inspect and control web requests that you can use in a <a>WebACL</a>. When you create a rule group, you define an immutable capacity limit. If you update a rule group, you must stay within the capacity. This allows others to reuse the rule group with confidence in its capacity requirements. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617975 = header.getOrDefault("X-Amz-Date")
  valid_617975 = validateParameter(valid_617975, JString, required = false,
                                 default = nil)
  if valid_617975 != nil:
    section.add "X-Amz-Date", valid_617975
  var valid_617976 = header.getOrDefault("X-Amz-Security-Token")
  valid_617976 = validateParameter(valid_617976, JString, required = false,
                                 default = nil)
  if valid_617976 != nil:
    section.add "X-Amz-Security-Token", valid_617976
  var valid_617977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617977 = validateParameter(valid_617977, JString, required = false,
                                 default = nil)
  if valid_617977 != nil:
    section.add "X-Amz-Content-Sha256", valid_617977
  var valid_617978 = header.getOrDefault("X-Amz-Algorithm")
  valid_617978 = validateParameter(valid_617978, JString, required = false,
                                 default = nil)
  if valid_617978 != nil:
    section.add "X-Amz-Algorithm", valid_617978
  var valid_617979 = header.getOrDefault("X-Amz-Signature")
  valid_617979 = validateParameter(valid_617979, JString, required = false,
                                 default = nil)
  if valid_617979 != nil:
    section.add "X-Amz-Signature", valid_617979
  var valid_617980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617980 = validateParameter(valid_617980, JString, required = false,
                                 default = nil)
  if valid_617980 != nil:
    section.add "X-Amz-SignedHeaders", valid_617980
  var valid_617981 = header.getOrDefault("X-Amz-Target")
  valid_617981 = validateParameter(valid_617981, JString, required = true, default = newJString(
      "AWSWAF_20190729.UpdateRuleGroup"))
  if valid_617981 != nil:
    section.add "X-Amz-Target", valid_617981
  var valid_617982 = header.getOrDefault("X-Amz-Credential")
  valid_617982 = validateParameter(valid_617982, JString, required = false,
                                 default = nil)
  if valid_617982 != nil:
    section.add "X-Amz-Credential", valid_617982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617984: Call_UpdateRuleGroup_617972; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Updates the specified <a>RuleGroup</a>.</p> <p> A rule group defines a collection of rules to inspect and control web requests that you can use in a <a>WebACL</a>. When you create a rule group, you define an immutable capacity limit. If you update a rule group, you must stay within the capacity. This allows others to reuse the rule group with confidence in its capacity requirements. </p>
  ## 
  let valid = call_617984.validator(path, query, header, formData, body, _)
  let scheme = call_617984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617984.url(scheme.get, call_617984.host, call_617984.base,
                         call_617984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617984, url, valid, _)

proc call*(call_617985: Call_UpdateRuleGroup_617972; body: JsonNode): Recallable =
  ## updateRuleGroup
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Updates the specified <a>RuleGroup</a>.</p> <p> A rule group defines a collection of rules to inspect and control web requests that you can use in a <a>WebACL</a>. When you create a rule group, you define an immutable capacity limit. If you update a rule group, you must stay within the capacity. This allows others to reuse the rule group with confidence in its capacity requirements. </p>
  ##   body: JObject (required)
  var body_617986 = newJObject()
  if body != nil:
    body_617986 = body
  result = call_617985.call(nil, nil, nil, nil, body_617986)

var updateRuleGroup* = Call_UpdateRuleGroup_617972(name: "updateRuleGroup",
    meth: HttpMethod.HttpPost, host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.UpdateRuleGroup",
    validator: validate_UpdateRuleGroup_617973, base: "/", url: url_UpdateRuleGroup_617974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebACL_617987 = ref object of OpenApiRestCall_616866
proc url_UpdateWebACL_617989(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWebACL_617988(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Updates the specified <a>WebACL</a>.</p> <p> A Web ACL defines a collection of rules to use to inspect and control web requests. Each rule has an action defined (allow, block, or count) for requests that match the statement of the rule. In the Web ACL, you assign a default action to take (allow, block) for any request that does not match any of the rules. The rules in a Web ACL can be a combination of the types <a>Rule</a>, <a>RuleGroup</a>, and managed rule group. You can associate a Web ACL with one or more AWS resources to protect. The resources can be Amazon CloudFront, an Amazon API Gateway API, or an Application Load Balancer. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617990 = header.getOrDefault("X-Amz-Date")
  valid_617990 = validateParameter(valid_617990, JString, required = false,
                                 default = nil)
  if valid_617990 != nil:
    section.add "X-Amz-Date", valid_617990
  var valid_617991 = header.getOrDefault("X-Amz-Security-Token")
  valid_617991 = validateParameter(valid_617991, JString, required = false,
                                 default = nil)
  if valid_617991 != nil:
    section.add "X-Amz-Security-Token", valid_617991
  var valid_617992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617992 = validateParameter(valid_617992, JString, required = false,
                                 default = nil)
  if valid_617992 != nil:
    section.add "X-Amz-Content-Sha256", valid_617992
  var valid_617993 = header.getOrDefault("X-Amz-Algorithm")
  valid_617993 = validateParameter(valid_617993, JString, required = false,
                                 default = nil)
  if valid_617993 != nil:
    section.add "X-Amz-Algorithm", valid_617993
  var valid_617994 = header.getOrDefault("X-Amz-Signature")
  valid_617994 = validateParameter(valid_617994, JString, required = false,
                                 default = nil)
  if valid_617994 != nil:
    section.add "X-Amz-Signature", valid_617994
  var valid_617995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617995 = validateParameter(valid_617995, JString, required = false,
                                 default = nil)
  if valid_617995 != nil:
    section.add "X-Amz-SignedHeaders", valid_617995
  var valid_617996 = header.getOrDefault("X-Amz-Target")
  valid_617996 = validateParameter(valid_617996, JString, required = true, default = newJString(
      "AWSWAF_20190729.UpdateWebACL"))
  if valid_617996 != nil:
    section.add "X-Amz-Target", valid_617996
  var valid_617997 = header.getOrDefault("X-Amz-Credential")
  valid_617997 = validateParameter(valid_617997, JString, required = false,
                                 default = nil)
  if valid_617997 != nil:
    section.add "X-Amz-Credential", valid_617997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617999: Call_UpdateWebACL_617987; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Updates the specified <a>WebACL</a>.</p> <p> A Web ACL defines a collection of rules to use to inspect and control web requests. Each rule has an action defined (allow, block, or count) for requests that match the statement of the rule. In the Web ACL, you assign a default action to take (allow, block) for any request that does not match any of the rules. The rules in a Web ACL can be a combination of the types <a>Rule</a>, <a>RuleGroup</a>, and managed rule group. You can associate a Web ACL with one or more AWS resources to protect. The resources can be Amazon CloudFront, an Amazon API Gateway API, or an Application Load Balancer. </p>
  ## 
  let valid = call_617999.validator(path, query, header, formData, body, _)
  let scheme = call_617999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617999.url(scheme.get, call_617999.host, call_617999.base,
                         call_617999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617999, url, valid, _)

proc call*(call_618000: Call_UpdateWebACL_617987; body: JsonNode): Recallable =
  ## updateWebACL
  ## <note> <p>This is the latest version of <b>AWS WAF</b>, named AWS WAFV2, released in November, 2019. For information, including how to migrate your AWS WAF resources from the prior release, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html">AWS WAF Developer Guide</a>. </p> </note> <p>Updates the specified <a>WebACL</a>.</p> <p> A Web ACL defines a collection of rules to use to inspect and control web requests. Each rule has an action defined (allow, block, or count) for requests that match the statement of the rule. In the Web ACL, you assign a default action to take (allow, block) for any request that does not match any of the rules. The rules in a Web ACL can be a combination of the types <a>Rule</a>, <a>RuleGroup</a>, and managed rule group. You can associate a Web ACL with one or more AWS resources to protect. The resources can be Amazon CloudFront, an Amazon API Gateway API, or an Application Load Balancer. </p>
  ##   body: JObject (required)
  var body_618001 = newJObject()
  if body != nil:
    body_618001 = body
  result = call_618000.call(nil, nil, nil, nil, body_618001)

var updateWebACL* = Call_UpdateWebACL_617987(name: "updateWebACL",
    meth: HttpMethod.HttpPost, host: "wafv2.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_20190729.UpdateWebACL",
    validator: validate_UpdateWebACL_617988, base: "/", url: url_UpdateWebACL_617989,
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
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
