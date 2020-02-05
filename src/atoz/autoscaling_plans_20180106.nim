
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Auto Scaling Plans
## version: 2018-01-06
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Auto Scaling</fullname> <p>Use AWS Auto Scaling to quickly discover all the scalable AWS resources for your application and configure dynamic scaling and predictive scaling for your resources using scaling plans. Use this service in conjunction with the Amazon EC2 Auto Scaling, Application Auto Scaling, Amazon CloudWatch, and AWS CloudFormation services. </p> <p>Currently, predictive scaling is only available for Amazon EC2 Auto Scaling groups.</p> <p>For more information about AWS Auto Scaling, including information about granting IAM users required permissions for AWS Auto Scaling actions, see the <a href="https://docs.aws.amazon.com/autoscaling/plans/userguide/what-is-aws-auto-scaling.html">AWS Auto Scaling User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/autoscaling-plans/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "autoscaling-plans.ap-northeast-1.amazonaws.com", "ap-southeast-1": "autoscaling-plans.ap-southeast-1.amazonaws.com", "us-west-2": "autoscaling-plans.us-west-2.amazonaws.com", "eu-west-2": "autoscaling-plans.eu-west-2.amazonaws.com", "ap-northeast-3": "autoscaling-plans.ap-northeast-3.amazonaws.com", "eu-central-1": "autoscaling-plans.eu-central-1.amazonaws.com", "us-east-2": "autoscaling-plans.us-east-2.amazonaws.com", "us-east-1": "autoscaling-plans.us-east-1.amazonaws.com", "cn-northwest-1": "autoscaling-plans.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "autoscaling-plans.ap-south-1.amazonaws.com", "eu-north-1": "autoscaling-plans.eu-north-1.amazonaws.com", "ap-northeast-2": "autoscaling-plans.ap-northeast-2.amazonaws.com", "us-west-1": "autoscaling-plans.us-west-1.amazonaws.com", "us-gov-east-1": "autoscaling-plans.us-gov-east-1.amazonaws.com", "eu-west-3": "autoscaling-plans.eu-west-3.amazonaws.com", "cn-north-1": "autoscaling-plans.cn-north-1.amazonaws.com.cn", "sa-east-1": "autoscaling-plans.sa-east-1.amazonaws.com", "eu-west-1": "autoscaling-plans.eu-west-1.amazonaws.com", "us-gov-west-1": "autoscaling-plans.us-gov-west-1.amazonaws.com", "ap-southeast-2": "autoscaling-plans.ap-southeast-2.amazonaws.com", "ca-central-1": "autoscaling-plans.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "autoscaling-plans.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "autoscaling-plans.ap-southeast-1.amazonaws.com",
      "us-west-2": "autoscaling-plans.us-west-2.amazonaws.com",
      "eu-west-2": "autoscaling-plans.eu-west-2.amazonaws.com",
      "ap-northeast-3": "autoscaling-plans.ap-northeast-3.amazonaws.com",
      "eu-central-1": "autoscaling-plans.eu-central-1.amazonaws.com",
      "us-east-2": "autoscaling-plans.us-east-2.amazonaws.com",
      "us-east-1": "autoscaling-plans.us-east-1.amazonaws.com",
      "cn-northwest-1": "autoscaling-plans.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "autoscaling-plans.ap-south-1.amazonaws.com",
      "eu-north-1": "autoscaling-plans.eu-north-1.amazonaws.com",
      "ap-northeast-2": "autoscaling-plans.ap-northeast-2.amazonaws.com",
      "us-west-1": "autoscaling-plans.us-west-1.amazonaws.com",
      "us-gov-east-1": "autoscaling-plans.us-gov-east-1.amazonaws.com",
      "eu-west-3": "autoscaling-plans.eu-west-3.amazonaws.com",
      "cn-north-1": "autoscaling-plans.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "autoscaling-plans.sa-east-1.amazonaws.com",
      "eu-west-1": "autoscaling-plans.eu-west-1.amazonaws.com",
      "us-gov-west-1": "autoscaling-plans.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "autoscaling-plans.ap-southeast-2.amazonaws.com",
      "ca-central-1": "autoscaling-plans.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "autoscaling-plans"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateScalingPlan_612996 = ref object of OpenApiRestCall_612658
proc url_CreateScalingPlan_612998(protocol: Scheme; host: string; base: string;
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

proc validate_CreateScalingPlan_612997(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a scaling plan.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "AnyScaleScalingPlannerFrontendService.CreateScalingPlan"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_CreateScalingPlan_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a scaling plan.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_CreateScalingPlan_612996; body: JsonNode): Recallable =
  ## createScalingPlan
  ## Creates a scaling plan.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var createScalingPlan* = Call_CreateScalingPlan_612996(name: "createScalingPlan",
    meth: HttpMethod.HttpPost, host: "autoscaling-plans.amazonaws.com", route: "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.CreateScalingPlan",
    validator: validate_CreateScalingPlan_612997, base: "/",
    url: url_CreateScalingPlan_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteScalingPlan_613265 = ref object of OpenApiRestCall_612658
proc url_DeleteScalingPlan_613267(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteScalingPlan_613266(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes the specified scaling plan.</p> <p>Deleting a scaling plan deletes the underlying <a>ScalingInstruction</a> for all of the scalable resources that are covered by the plan.</p> <p>If the plan has launched resources or has scaling activities in progress, you must delete those resources separately.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "AnyScaleScalingPlannerFrontendService.DeleteScalingPlan"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_DeleteScalingPlan_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified scaling plan.</p> <p>Deleting a scaling plan deletes the underlying <a>ScalingInstruction</a> for all of the scalable resources that are covered by the plan.</p> <p>If the plan has launched resources or has scaling activities in progress, you must delete those resources separately.</p>
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_DeleteScalingPlan_613265; body: JsonNode): Recallable =
  ## deleteScalingPlan
  ## <p>Deletes the specified scaling plan.</p> <p>Deleting a scaling plan deletes the underlying <a>ScalingInstruction</a> for all of the scalable resources that are covered by the plan.</p> <p>If the plan has launched resources or has scaling activities in progress, you must delete those resources separately.</p>
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var deleteScalingPlan* = Call_DeleteScalingPlan_613265(name: "deleteScalingPlan",
    meth: HttpMethod.HttpPost, host: "autoscaling-plans.amazonaws.com", route: "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.DeleteScalingPlan",
    validator: validate_DeleteScalingPlan_613266, base: "/",
    url: url_DeleteScalingPlan_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScalingPlanResources_613280 = ref object of OpenApiRestCall_612658
proc url_DescribeScalingPlanResources_613282(protocol: Scheme; host: string;
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

proc validate_DescribeScalingPlanResources_613281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the scalable resources in the specified scaling plan.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "AnyScaleScalingPlannerFrontendService.DescribeScalingPlanResources"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_DescribeScalingPlanResources_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the scalable resources in the specified scaling plan.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_DescribeScalingPlanResources_613280; body: JsonNode): Recallable =
  ## describeScalingPlanResources
  ## Describes the scalable resources in the specified scaling plan.
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var describeScalingPlanResources* = Call_DescribeScalingPlanResources_613280(
    name: "describeScalingPlanResources", meth: HttpMethod.HttpPost,
    host: "autoscaling-plans.amazonaws.com", route: "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.DescribeScalingPlanResources",
    validator: validate_DescribeScalingPlanResources_613281, base: "/",
    url: url_DescribeScalingPlanResources_613282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScalingPlans_613295 = ref object of OpenApiRestCall_612658
proc url_DescribeScalingPlans_613297(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeScalingPlans_613296(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes one or more of your scaling plans.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "AnyScaleScalingPlannerFrontendService.DescribeScalingPlans"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_DescribeScalingPlans_613295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your scaling plans.
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_DescribeScalingPlans_613295; body: JsonNode): Recallable =
  ## describeScalingPlans
  ## Describes one or more of your scaling plans.
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var describeScalingPlans* = Call_DescribeScalingPlans_613295(
    name: "describeScalingPlans", meth: HttpMethod.HttpPost,
    host: "autoscaling-plans.amazonaws.com", route: "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.DescribeScalingPlans",
    validator: validate_DescribeScalingPlans_613296, base: "/",
    url: url_DescribeScalingPlans_613297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetScalingPlanResourceForecastData_613310 = ref object of OpenApiRestCall_612658
proc url_GetScalingPlanResourceForecastData_613312(protocol: Scheme; host: string;
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

proc validate_GetScalingPlanResourceForecastData_613311(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the forecast data for a scalable resource.</p> <p>Capacity forecasts are represented as predicted values, or data points, that are calculated using historical data points from a specified CloudWatch load metric. Data points are available for up to 56 days. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString("AnyScaleScalingPlannerFrontendService.GetScalingPlanResourceForecastData"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_GetScalingPlanResourceForecastData_613310;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieves the forecast data for a scalable resource.</p> <p>Capacity forecasts are represented as predicted values, or data points, that are calculated using historical data points from a specified CloudWatch load metric. Data points are available for up to 56 days. </p>
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_GetScalingPlanResourceForecastData_613310;
          body: JsonNode): Recallable =
  ## getScalingPlanResourceForecastData
  ## <p>Retrieves the forecast data for a scalable resource.</p> <p>Capacity forecasts are represented as predicted values, or data points, that are calculated using historical data points from a specified CloudWatch load metric. Data points are available for up to 56 days. </p>
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var getScalingPlanResourceForecastData* = Call_GetScalingPlanResourceForecastData_613310(
    name: "getScalingPlanResourceForecastData", meth: HttpMethod.HttpPost,
    host: "autoscaling-plans.amazonaws.com", route: "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.GetScalingPlanResourceForecastData",
    validator: validate_GetScalingPlanResourceForecastData_613311, base: "/",
    url: url_GetScalingPlanResourceForecastData_613312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateScalingPlan_613325 = ref object of OpenApiRestCall_612658
proc url_UpdateScalingPlan_613327(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateScalingPlan_613326(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates the specified scaling plan.</p> <p>You cannot update a scaling plan if it is in the process of being created, updated, or deleted.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "AnyScaleScalingPlannerFrontendService.UpdateScalingPlan"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_UpdateScalingPlan_613325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified scaling plan.</p> <p>You cannot update a scaling plan if it is in the process of being created, updated, or deleted.</p>
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_UpdateScalingPlan_613325; body: JsonNode): Recallable =
  ## updateScalingPlan
  ## <p>Updates the specified scaling plan.</p> <p>You cannot update a scaling plan if it is in the process of being created, updated, or deleted.</p>
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var updateScalingPlan* = Call_UpdateScalingPlan_613325(name: "updateScalingPlan",
    meth: HttpMethod.HttpPost, host: "autoscaling-plans.amazonaws.com", route: "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.UpdateScalingPlan",
    validator: validate_UpdateScalingPlan_613326, base: "/",
    url: url_UpdateScalingPlan_613327, schemes: {Scheme.Https, Scheme.Http})
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
