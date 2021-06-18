
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
    if required:
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "autoscaling-plans.ap-northeast-1.amazonaws.com", "ap-southeast-1": "autoscaling-plans.ap-southeast-1.amazonaws.com", "us-west-2": "autoscaling-plans.us-west-2.amazonaws.com", "eu-west-2": "autoscaling-plans.eu-west-2.amazonaws.com", "ap-northeast-3": "autoscaling-plans.ap-northeast-3.amazonaws.com", "eu-central-1": "autoscaling-plans.eu-central-1.amazonaws.com", "us-east-2": "autoscaling-plans.us-east-2.amazonaws.com", "us-east-1": "autoscaling-plans.us-east-1.amazonaws.com", "cn-northwest-1": "autoscaling-plans.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "autoscaling-plans.ap-south-1.amazonaws.com", "eu-north-1": "autoscaling-plans.eu-north-1.amazonaws.com", "ap-northeast-2": "autoscaling-plans.ap-northeast-2.amazonaws.com", "us-west-1": "autoscaling-plans.us-west-1.amazonaws.com", "us-gov-east-1": "autoscaling-plans.us-gov-east-1.amazonaws.com", "eu-west-3": "autoscaling-plans.eu-west-3.amazonaws.com", "cn-north-1": "autoscaling-plans.cn-north-1.amazonaws.com.cn", "sa-east-1": "autoscaling-plans.sa-east-1.amazonaws.com", "eu-west-1": "autoscaling-plans.eu-west-1.amazonaws.com", "us-gov-west-1": "autoscaling-plans.us-gov-west-1.amazonaws.com", "ap-southeast-2": "autoscaling-plans.ap-southeast-2.amazonaws.com", "ca-central-1": "autoscaling-plans.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateScalingPlan_402656288 = ref object of OpenApiRestCall_402656038
proc url_CreateScalingPlan_402656290(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateScalingPlan_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656384 = header.getOrDefault("X-Amz-Target")
  valid_402656384 = validateParameter(valid_402656384, JString, required = true, default = newJString(
      "AnyScaleScalingPlannerFrontendService.CreateScalingPlan"))
  if valid_402656384 != nil:
    section.add "X-Amz-Target", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Security-Token", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Signature")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Signature", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Algorithm", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Date")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Date", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Credential")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Credential", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656406: Call_CreateScalingPlan_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a scaling plan.
                                                                                         ## 
  let valid = call_402656406.validator(path, query, header, formData, body, _)
  let scheme = call_402656406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656406.makeUrl(scheme.get, call_402656406.host, call_402656406.base,
                                   call_402656406.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656406, uri, valid, _)

proc call*(call_402656455: Call_CreateScalingPlan_402656288; body: JsonNode): Recallable =
  ## createScalingPlan
  ## Creates a scaling plan.
  ##   body: JObject (required)
  var body_402656456 = newJObject()
  if body != nil:
    body_402656456 = body
  result = call_402656455.call(nil, nil, nil, nil, body_402656456)

var createScalingPlan* = Call_CreateScalingPlan_402656288(
    name: "createScalingPlan", meth: HttpMethod.HttpPost,
    host: "autoscaling-plans.amazonaws.com", route: "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.CreateScalingPlan",
    validator: validate_CreateScalingPlan_402656289, base: "/",
    makeUrl: url_CreateScalingPlan_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteScalingPlan_402656483 = ref object of OpenApiRestCall_402656038
proc url_DeleteScalingPlan_402656485(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteScalingPlan_402656484(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656486 = header.getOrDefault("X-Amz-Target")
  valid_402656486 = validateParameter(valid_402656486, JString, required = true, default = newJString(
      "AnyScaleScalingPlannerFrontendService.DeleteScalingPlan"))
  if valid_402656486 != nil:
    section.add "X-Amz-Target", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Security-Token", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Signature")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Signature", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Algorithm", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-Date")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Date", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Credential")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Credential", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656495: Call_DeleteScalingPlan_402656483;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified scaling plan.</p> <p>Deleting a scaling plan deletes the underlying <a>ScalingInstruction</a> for all of the scalable resources that are covered by the plan.</p> <p>If the plan has launched resources or has scaling activities in progress, you must delete those resources separately.</p>
                                                                                         ## 
  let valid = call_402656495.validator(path, query, header, formData, body, _)
  let scheme = call_402656495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656495.makeUrl(scheme.get, call_402656495.host, call_402656495.base,
                                   call_402656495.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656495, uri, valid, _)

proc call*(call_402656496: Call_DeleteScalingPlan_402656483; body: JsonNode): Recallable =
  ## deleteScalingPlan
  ## <p>Deletes the specified scaling plan.</p> <p>Deleting a scaling plan deletes the underlying <a>ScalingInstruction</a> for all of the scalable resources that are covered by the plan.</p> <p>If the plan has launched resources or has scaling activities in progress, you must delete those resources separately.</p>
  ##   
                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656497 = newJObject()
  if body != nil:
    body_402656497 = body
  result = call_402656496.call(nil, nil, nil, nil, body_402656497)

var deleteScalingPlan* = Call_DeleteScalingPlan_402656483(
    name: "deleteScalingPlan", meth: HttpMethod.HttpPost,
    host: "autoscaling-plans.amazonaws.com", route: "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.DeleteScalingPlan",
    validator: validate_DeleteScalingPlan_402656484, base: "/",
    makeUrl: url_DeleteScalingPlan_402656485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScalingPlanResources_402656498 = ref object of OpenApiRestCall_402656038
proc url_DescribeScalingPlanResources_402656500(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeScalingPlanResources_402656499(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656501 = header.getOrDefault("X-Amz-Target")
  valid_402656501 = validateParameter(valid_402656501, JString, required = true, default = newJString(
      "AnyScaleScalingPlannerFrontendService.DescribeScalingPlanResources"))
  if valid_402656501 != nil:
    section.add "X-Amz-Target", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Security-Token", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Signature")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Signature", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Algorithm", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Date")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Date", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Credential")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Credential", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656510: Call_DescribeScalingPlanResources_402656498;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the scalable resources in the specified scaling plan.
                                                                                         ## 
  let valid = call_402656510.validator(path, query, header, formData, body, _)
  let scheme = call_402656510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656510.makeUrl(scheme.get, call_402656510.host, call_402656510.base,
                                   call_402656510.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656510, uri, valid, _)

proc call*(call_402656511: Call_DescribeScalingPlanResources_402656498;
           body: JsonNode): Recallable =
  ## describeScalingPlanResources
  ## Describes the scalable resources in the specified scaling plan.
  ##   body: JObject (required)
  var body_402656512 = newJObject()
  if body != nil:
    body_402656512 = body
  result = call_402656511.call(nil, nil, nil, nil, body_402656512)

var describeScalingPlanResources* = Call_DescribeScalingPlanResources_402656498(
    name: "describeScalingPlanResources", meth: HttpMethod.HttpPost,
    host: "autoscaling-plans.amazonaws.com", route: "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.DescribeScalingPlanResources",
    validator: validate_DescribeScalingPlanResources_402656499, base: "/",
    makeUrl: url_DescribeScalingPlanResources_402656500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScalingPlans_402656513 = ref object of OpenApiRestCall_402656038
proc url_DescribeScalingPlans_402656515(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeScalingPlans_402656514(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656516 = header.getOrDefault("X-Amz-Target")
  valid_402656516 = validateParameter(valid_402656516, JString, required = true, default = newJString(
      "AnyScaleScalingPlannerFrontendService.DescribeScalingPlans"))
  if valid_402656516 != nil:
    section.add "X-Amz-Target", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Security-Token", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Signature")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Signature", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Algorithm", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Date")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Date", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Credential")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Credential", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656525: Call_DescribeScalingPlans_402656513;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes one or more of your scaling plans.
                                                                                         ## 
  let valid = call_402656525.validator(path, query, header, formData, body, _)
  let scheme = call_402656525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656525.makeUrl(scheme.get, call_402656525.host, call_402656525.base,
                                   call_402656525.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656525, uri, valid, _)

proc call*(call_402656526: Call_DescribeScalingPlans_402656513; body: JsonNode): Recallable =
  ## describeScalingPlans
  ## Describes one or more of your scaling plans.
  ##   body: JObject (required)
  var body_402656527 = newJObject()
  if body != nil:
    body_402656527 = body
  result = call_402656526.call(nil, nil, nil, nil, body_402656527)

var describeScalingPlans* = Call_DescribeScalingPlans_402656513(
    name: "describeScalingPlans", meth: HttpMethod.HttpPost,
    host: "autoscaling-plans.amazonaws.com", route: "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.DescribeScalingPlans",
    validator: validate_DescribeScalingPlans_402656514, base: "/",
    makeUrl: url_DescribeScalingPlans_402656515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetScalingPlanResourceForecastData_402656528 = ref object of OpenApiRestCall_402656038
proc url_GetScalingPlanResourceForecastData_402656530(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetScalingPlanResourceForecastData_402656529(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656531 = header.getOrDefault("X-Amz-Target")
  valid_402656531 = validateParameter(valid_402656531, JString, required = true, default = newJString("AnyScaleScalingPlannerFrontendService.GetScalingPlanResourceForecastData"))
  if valid_402656531 != nil:
    section.add "X-Amz-Target", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Security-Token", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Signature")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Signature", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Algorithm", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Date")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Date", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Credential")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Credential", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656540: Call_GetScalingPlanResourceForecastData_402656528;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the forecast data for a scalable resource.</p> <p>Capacity forecasts are represented as predicted values, or data points, that are calculated using historical data points from a specified CloudWatch load metric. Data points are available for up to 56 days. </p>
                                                                                         ## 
  let valid = call_402656540.validator(path, query, header, formData, body, _)
  let scheme = call_402656540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656540.makeUrl(scheme.get, call_402656540.host, call_402656540.base,
                                   call_402656540.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656540, uri, valid, _)

proc call*(call_402656541: Call_GetScalingPlanResourceForecastData_402656528;
           body: JsonNode): Recallable =
  ## getScalingPlanResourceForecastData
  ## <p>Retrieves the forecast data for a scalable resource.</p> <p>Capacity forecasts are represented as predicted values, or data points, that are calculated using historical data points from a specified CloudWatch load metric. Data points are available for up to 56 days. </p>
  ##   
                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656542 = newJObject()
  if body != nil:
    body_402656542 = body
  result = call_402656541.call(nil, nil, nil, nil, body_402656542)

var getScalingPlanResourceForecastData* = Call_GetScalingPlanResourceForecastData_402656528(
    name: "getScalingPlanResourceForecastData", meth: HttpMethod.HttpPost,
    host: "autoscaling-plans.amazonaws.com", route: "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.GetScalingPlanResourceForecastData",
    validator: validate_GetScalingPlanResourceForecastData_402656529, base: "/",
    makeUrl: url_GetScalingPlanResourceForecastData_402656530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateScalingPlan_402656543 = ref object of OpenApiRestCall_402656038
proc url_UpdateScalingPlan_402656545(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateScalingPlan_402656544(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656546 = header.getOrDefault("X-Amz-Target")
  valid_402656546 = validateParameter(valid_402656546, JString, required = true, default = newJString(
      "AnyScaleScalingPlannerFrontendService.UpdateScalingPlan"))
  if valid_402656546 != nil:
    section.add "X-Amz-Target", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Security-Token", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Signature")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Signature", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Algorithm", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Date")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Date", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Credential")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Credential", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656555: Call_UpdateScalingPlan_402656543;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified scaling plan.</p> <p>You cannot update a scaling plan if it is in the process of being created, updated, or deleted.</p>
                                                                                         ## 
  let valid = call_402656555.validator(path, query, header, formData, body, _)
  let scheme = call_402656555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656555.makeUrl(scheme.get, call_402656555.host, call_402656555.base,
                                   call_402656555.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656555, uri, valid, _)

proc call*(call_402656556: Call_UpdateScalingPlan_402656543; body: JsonNode): Recallable =
  ## updateScalingPlan
  ## <p>Updates the specified scaling plan.</p> <p>You cannot update a scaling plan if it is in the process of being created, updated, or deleted.</p>
  ##   
                                                                                                                                                      ## body: JObject (required)
  var body_402656557 = newJObject()
  if body != nil:
    body_402656557 = body
  result = call_402656556.call(nil, nil, nil, nil, body_402656557)

var updateScalingPlan* = Call_UpdateScalingPlan_402656543(
    name: "updateScalingPlan", meth: HttpMethod.HttpPost,
    host: "autoscaling-plans.amazonaws.com", route: "/#X-Amz-Target=AnyScaleScalingPlannerFrontendService.UpdateScalingPlan",
    validator: validate_UpdateScalingPlan_402656544, base: "/",
    makeUrl: url_UpdateScalingPlan_402656545,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}