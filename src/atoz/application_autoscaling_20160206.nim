
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Application Auto Scaling
## version: 2016-02-06
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>With Application Auto Scaling, you can configure automatic scaling for the following resources:</p> <ul> <li> <p>Amazon ECS services</p> </li> <li> <p>Amazon EC2 Spot Fleet requests</p> </li> <li> <p>Amazon EMR clusters</p> </li> <li> <p>Amazon AppStream 2.0 fleets</p> </li> <li> <p>Amazon DynamoDB tables and global secondary indexes throughput capacity</p> </li> <li> <p>Amazon Aurora Replicas</p> </li> <li> <p>Amazon SageMaker endpoint variants</p> </li> <li> <p>Custom resources provided by your own applications or services</p> </li> <li> <p>Amazon Comprehend document classification endpoints</p> </li> <li> <p>AWS Lambda function provisioned concurrency</p> </li> </ul> <p> <b>API Summary</b> </p> <p>The Application Auto Scaling service API includes three key sets of actions: </p> <ul> <li> <p>Register and manage scalable targets - Register AWS or custom resources as scalable targets (a resource that Application Auto Scaling can scale), set minimum and maximum capacity limits, and retrieve information on existing scalable targets.</p> </li> <li> <p>Configure and manage automatic scaling - Define scaling policies to dynamically scale your resources in response to CloudWatch alarms, schedule one-time or recurring scaling actions, and retrieve your recent scaling activity history.</p> </li> <li> <p>Suspend and resume scaling - Temporarily suspend and later resume automatic scaling by calling the <a>RegisterScalableTarget</a> action for any Application Auto Scaling scalable target. You can suspend and resume, individually or in combination, scale-out activities triggered by a scaling policy, scale-in activities triggered by a scaling policy, and scheduled scaling. </p> </li> </ul> <p>To learn more about Application Auto Scaling, including information about granting IAM users required permissions for Application Auto Scaling actions, see the <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html">Application Auto Scaling User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/application-autoscaling/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "application-autoscaling.ap-northeast-1.amazonaws.com", "ap-southeast-1": "application-autoscaling.ap-southeast-1.amazonaws.com", "us-west-2": "application-autoscaling.us-west-2.amazonaws.com", "eu-west-2": "application-autoscaling.eu-west-2.amazonaws.com", "ap-northeast-3": "application-autoscaling.ap-northeast-3.amazonaws.com", "eu-central-1": "application-autoscaling.eu-central-1.amazonaws.com", "us-east-2": "application-autoscaling.us-east-2.amazonaws.com", "us-east-1": "application-autoscaling.us-east-1.amazonaws.com", "cn-northwest-1": "application-autoscaling.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "application-autoscaling.ap-south-1.amazonaws.com", "eu-north-1": "application-autoscaling.eu-north-1.amazonaws.com", "ap-northeast-2": "application-autoscaling.ap-northeast-2.amazonaws.com", "us-west-1": "application-autoscaling.us-west-1.amazonaws.com", "us-gov-east-1": "application-autoscaling.us-gov-east-1.amazonaws.com", "eu-west-3": "application-autoscaling.eu-west-3.amazonaws.com", "cn-north-1": "application-autoscaling.cn-north-1.amazonaws.com.cn", "sa-east-1": "application-autoscaling.sa-east-1.amazonaws.com", "eu-west-1": "application-autoscaling.eu-west-1.amazonaws.com", "us-gov-west-1": "application-autoscaling.us-gov-west-1.amazonaws.com", "ap-southeast-2": "application-autoscaling.ap-southeast-2.amazonaws.com", "ca-central-1": "application-autoscaling.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "application-autoscaling.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "application-autoscaling.ap-southeast-1.amazonaws.com",
      "us-west-2": "application-autoscaling.us-west-2.amazonaws.com",
      "eu-west-2": "application-autoscaling.eu-west-2.amazonaws.com",
      "ap-northeast-3": "application-autoscaling.ap-northeast-3.amazonaws.com",
      "eu-central-1": "application-autoscaling.eu-central-1.amazonaws.com",
      "us-east-2": "application-autoscaling.us-east-2.amazonaws.com",
      "us-east-1": "application-autoscaling.us-east-1.amazonaws.com", "cn-northwest-1": "application-autoscaling.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "application-autoscaling.ap-south-1.amazonaws.com",
      "eu-north-1": "application-autoscaling.eu-north-1.amazonaws.com",
      "ap-northeast-2": "application-autoscaling.ap-northeast-2.amazonaws.com",
      "us-west-1": "application-autoscaling.us-west-1.amazonaws.com",
      "us-gov-east-1": "application-autoscaling.us-gov-east-1.amazonaws.com",
      "eu-west-3": "application-autoscaling.eu-west-3.amazonaws.com",
      "cn-north-1": "application-autoscaling.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "application-autoscaling.sa-east-1.amazonaws.com",
      "eu-west-1": "application-autoscaling.eu-west-1.amazonaws.com",
      "us-gov-west-1": "application-autoscaling.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "application-autoscaling.ap-southeast-2.amazonaws.com",
      "ca-central-1": "application-autoscaling.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "application-autoscaling"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DeleteScalingPolicy_612996 = ref object of OpenApiRestCall_612658
proc url_DeleteScalingPolicy_612998(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteScalingPolicy_612997(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes the specified scaling policy for an Application Auto Scaling scalable target.</p> <p>Deleting a step scaling policy deletes the underlying alarm action, but does not delete the CloudWatch alarm associated with the scaling policy, even if it no longer has an associated action.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html#delete-step-scaling-policy">Delete a Step Scaling Policy</a> and <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-target-tracking.html#delete-target-tracking-policy">Delete a Target Tracking Scaling Policy</a> in the <i>Application Auto Scaling User Guide</i>.</p> <p>To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>.</p>
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
      "AnyScaleFrontendService.DeleteScalingPolicy"))
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

proc call*(call_613154: Call_DeleteScalingPolicy_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified scaling policy for an Application Auto Scaling scalable target.</p> <p>Deleting a step scaling policy deletes the underlying alarm action, but does not delete the CloudWatch alarm associated with the scaling policy, even if it no longer has an associated action.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html#delete-step-scaling-policy">Delete a Step Scaling Policy</a> and <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-target-tracking.html#delete-target-tracking-policy">Delete a Target Tracking Scaling Policy</a> in the <i>Application Auto Scaling User Guide</i>.</p> <p>To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>.</p>
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_DeleteScalingPolicy_612996; body: JsonNode): Recallable =
  ## deleteScalingPolicy
  ## <p>Deletes the specified scaling policy for an Application Auto Scaling scalable target.</p> <p>Deleting a step scaling policy deletes the underlying alarm action, but does not delete the CloudWatch alarm associated with the scaling policy, even if it no longer has an associated action.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html#delete-step-scaling-policy">Delete a Step Scaling Policy</a> and <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-target-tracking.html#delete-target-tracking-policy">Delete a Target Tracking Scaling Policy</a> in the <i>Application Auto Scaling User Guide</i>.</p> <p>To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>.</p>
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var deleteScalingPolicy* = Call_DeleteScalingPolicy_612996(
    name: "deleteScalingPolicy", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DeleteScalingPolicy",
    validator: validate_DeleteScalingPolicy_612997, base: "/",
    url: url_DeleteScalingPolicy_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteScheduledAction_613265 = ref object of OpenApiRestCall_612658
proc url_DeleteScheduledAction_613267(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteScheduledAction_613266(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified scheduled action for an Application Auto Scaling scalable target.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-scheduled-scaling.html#delete-scheduled-action">Delete a Scheduled Action</a> in the <i>Application Auto Scaling User Guide</i>.</p>
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
      "AnyScaleFrontendService.DeleteScheduledAction"))
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

proc call*(call_613277: Call_DeleteScheduledAction_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified scheduled action for an Application Auto Scaling scalable target.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-scheduled-scaling.html#delete-scheduled-action">Delete a Scheduled Action</a> in the <i>Application Auto Scaling User Guide</i>.</p>
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_DeleteScheduledAction_613265; body: JsonNode): Recallable =
  ## deleteScheduledAction
  ## <p>Deletes the specified scheduled action for an Application Auto Scaling scalable target.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-scheduled-scaling.html#delete-scheduled-action">Delete a Scheduled Action</a> in the <i>Application Auto Scaling User Guide</i>.</p>
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var deleteScheduledAction* = Call_DeleteScheduledAction_613265(
    name: "deleteScheduledAction", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DeleteScheduledAction",
    validator: validate_DeleteScheduledAction_613266, base: "/",
    url: url_DeleteScheduledAction_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterScalableTarget_613280 = ref object of OpenApiRestCall_612658
proc url_DeregisterScalableTarget_613282(protocol: Scheme; host: string;
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

proc validate_DeregisterScalableTarget_613281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deregisters an Application Auto Scaling scalable target.</p> <p>Deregistering a scalable target deletes the scaling policies that are associated with it.</p> <p>To create a scalable target or update an existing one, see <a>RegisterScalableTarget</a>. </p>
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
      "AnyScaleFrontendService.DeregisterScalableTarget"))
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

proc call*(call_613292: Call_DeregisterScalableTarget_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deregisters an Application Auto Scaling scalable target.</p> <p>Deregistering a scalable target deletes the scaling policies that are associated with it.</p> <p>To create a scalable target or update an existing one, see <a>RegisterScalableTarget</a>. </p>
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_DeregisterScalableTarget_613280; body: JsonNode): Recallable =
  ## deregisterScalableTarget
  ## <p>Deregisters an Application Auto Scaling scalable target.</p> <p>Deregistering a scalable target deletes the scaling policies that are associated with it.</p> <p>To create a scalable target or update an existing one, see <a>RegisterScalableTarget</a>. </p>
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var deregisterScalableTarget* = Call_DeregisterScalableTarget_613280(
    name: "deregisterScalableTarget", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DeregisterScalableTarget",
    validator: validate_DeregisterScalableTarget_613281, base: "/",
    url: url_DeregisterScalableTarget_613282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScalableTargets_613295 = ref object of OpenApiRestCall_612658
proc url_DescribeScalableTargets_613297(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeScalableTargets_613296(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the scalable targets in the specified namespace.</p> <p>You can filter the results using <code>ResourceIds</code> and <code>ScalableDimension</code>.</p> <p>To create a scalable target or update an existing one, see <a>RegisterScalableTarget</a>. If you are no longer using a scalable target, you can deregister it using <a>DeregisterScalableTarget</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613298 = query.getOrDefault("MaxResults")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "MaxResults", valid_613298
  var valid_613299 = query.getOrDefault("NextToken")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "NextToken", valid_613299
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
  var valid_613300 = header.getOrDefault("X-Amz-Target")
  valid_613300 = validateParameter(valid_613300, JString, required = true, default = newJString(
      "AnyScaleFrontendService.DescribeScalableTargets"))
  if valid_613300 != nil:
    section.add "X-Amz-Target", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Signature")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Signature", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Content-Sha256", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Date")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Date", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Credential")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Credential", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Security-Token")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Security-Token", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Algorithm")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Algorithm", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-SignedHeaders", valid_613307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613309: Call_DescribeScalableTargets_613295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the scalable targets in the specified namespace.</p> <p>You can filter the results using <code>ResourceIds</code> and <code>ScalableDimension</code>.</p> <p>To create a scalable target or update an existing one, see <a>RegisterScalableTarget</a>. If you are no longer using a scalable target, you can deregister it using <a>DeregisterScalableTarget</a>.</p>
  ## 
  let valid = call_613309.validator(path, query, header, formData, body)
  let scheme = call_613309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613309.url(scheme.get, call_613309.host, call_613309.base,
                         call_613309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613309, url, valid)

proc call*(call_613310: Call_DescribeScalableTargets_613295; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeScalableTargets
  ## <p>Gets information about the scalable targets in the specified namespace.</p> <p>You can filter the results using <code>ResourceIds</code> and <code>ScalableDimension</code>.</p> <p>To create a scalable target or update an existing one, see <a>RegisterScalableTarget</a>. If you are no longer using a scalable target, you can deregister it using <a>DeregisterScalableTarget</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613311 = newJObject()
  var body_613312 = newJObject()
  add(query_613311, "MaxResults", newJString(MaxResults))
  add(query_613311, "NextToken", newJString(NextToken))
  if body != nil:
    body_613312 = body
  result = call_613310.call(nil, query_613311, nil, nil, body_613312)

var describeScalableTargets* = Call_DescribeScalableTargets_613295(
    name: "describeScalableTargets", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DescribeScalableTargets",
    validator: validate_DescribeScalableTargets_613296, base: "/",
    url: url_DescribeScalableTargets_613297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScalingActivities_613314 = ref object of OpenApiRestCall_612658
proc url_DescribeScalingActivities_613316(protocol: Scheme; host: string;
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

proc validate_DescribeScalingActivities_613315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Provides descriptive information about the scaling activities in the specified namespace from the previous six weeks.</p> <p>You can filter the results using <code>ResourceId</code> and <code>ScalableDimension</code>.</p> <p>Scaling activities are triggered by CloudWatch alarms that are associated with scaling policies. To view the scaling policies for a service namespace, see <a>DescribeScalingPolicies</a>. To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613317 = query.getOrDefault("MaxResults")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "MaxResults", valid_613317
  var valid_613318 = query.getOrDefault("NextToken")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "NextToken", valid_613318
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
  var valid_613319 = header.getOrDefault("X-Amz-Target")
  valid_613319 = validateParameter(valid_613319, JString, required = true, default = newJString(
      "AnyScaleFrontendService.DescribeScalingActivities"))
  if valid_613319 != nil:
    section.add "X-Amz-Target", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Signature")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Signature", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Content-Sha256", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Date")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Date", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Credential")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Credential", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Security-Token")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Security-Token", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Algorithm")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Algorithm", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-SignedHeaders", valid_613326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613328: Call_DescribeScalingActivities_613314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides descriptive information about the scaling activities in the specified namespace from the previous six weeks.</p> <p>You can filter the results using <code>ResourceId</code> and <code>ScalableDimension</code>.</p> <p>Scaling activities are triggered by CloudWatch alarms that are associated with scaling policies. To view the scaling policies for a service namespace, see <a>DescribeScalingPolicies</a>. To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>.</p>
  ## 
  let valid = call_613328.validator(path, query, header, formData, body)
  let scheme = call_613328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613328.url(scheme.get, call_613328.host, call_613328.base,
                         call_613328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613328, url, valid)

proc call*(call_613329: Call_DescribeScalingActivities_613314; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeScalingActivities
  ## <p>Provides descriptive information about the scaling activities in the specified namespace from the previous six weeks.</p> <p>You can filter the results using <code>ResourceId</code> and <code>ScalableDimension</code>.</p> <p>Scaling activities are triggered by CloudWatch alarms that are associated with scaling policies. To view the scaling policies for a service namespace, see <a>DescribeScalingPolicies</a>. To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613330 = newJObject()
  var body_613331 = newJObject()
  add(query_613330, "MaxResults", newJString(MaxResults))
  add(query_613330, "NextToken", newJString(NextToken))
  if body != nil:
    body_613331 = body
  result = call_613329.call(nil, query_613330, nil, nil, body_613331)

var describeScalingActivities* = Call_DescribeScalingActivities_613314(
    name: "describeScalingActivities", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DescribeScalingActivities",
    validator: validate_DescribeScalingActivities_613315, base: "/",
    url: url_DescribeScalingActivities_613316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScalingPolicies_613332 = ref object of OpenApiRestCall_612658
proc url_DescribeScalingPolicies_613334(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeScalingPolicies_613333(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the Application Auto Scaling scaling policies for the specified service namespace.</p> <p>You can filter the results using <code>ResourceId</code>, <code>ScalableDimension</code>, and <code>PolicyNames</code>.</p> <p>To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>. If you are no longer using a scaling policy, you can delete it using <a>DeleteScalingPolicy</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613335 = query.getOrDefault("MaxResults")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "MaxResults", valid_613335
  var valid_613336 = query.getOrDefault("NextToken")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "NextToken", valid_613336
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
  var valid_613337 = header.getOrDefault("X-Amz-Target")
  valid_613337 = validateParameter(valid_613337, JString, required = true, default = newJString(
      "AnyScaleFrontendService.DescribeScalingPolicies"))
  if valid_613337 != nil:
    section.add "X-Amz-Target", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Signature")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Signature", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Content-Sha256", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Date")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Date", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Credential")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Credential", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Security-Token")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Security-Token", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Algorithm")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Algorithm", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-SignedHeaders", valid_613344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613346: Call_DescribeScalingPolicies_613332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the Application Auto Scaling scaling policies for the specified service namespace.</p> <p>You can filter the results using <code>ResourceId</code>, <code>ScalableDimension</code>, and <code>PolicyNames</code>.</p> <p>To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>. If you are no longer using a scaling policy, you can delete it using <a>DeleteScalingPolicy</a>.</p>
  ## 
  let valid = call_613346.validator(path, query, header, formData, body)
  let scheme = call_613346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613346.url(scheme.get, call_613346.host, call_613346.base,
                         call_613346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613346, url, valid)

proc call*(call_613347: Call_DescribeScalingPolicies_613332; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeScalingPolicies
  ## <p>Describes the Application Auto Scaling scaling policies for the specified service namespace.</p> <p>You can filter the results using <code>ResourceId</code>, <code>ScalableDimension</code>, and <code>PolicyNames</code>.</p> <p>To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>. If you are no longer using a scaling policy, you can delete it using <a>DeleteScalingPolicy</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613348 = newJObject()
  var body_613349 = newJObject()
  add(query_613348, "MaxResults", newJString(MaxResults))
  add(query_613348, "NextToken", newJString(NextToken))
  if body != nil:
    body_613349 = body
  result = call_613347.call(nil, query_613348, nil, nil, body_613349)

var describeScalingPolicies* = Call_DescribeScalingPolicies_613332(
    name: "describeScalingPolicies", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DescribeScalingPolicies",
    validator: validate_DescribeScalingPolicies_613333, base: "/",
    url: url_DescribeScalingPolicies_613334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScheduledActions_613350 = ref object of OpenApiRestCall_612658
proc url_DescribeScheduledActions_613352(protocol: Scheme; host: string;
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

proc validate_DescribeScheduledActions_613351(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the Application Auto Scaling scheduled actions for the specified service namespace.</p> <p>You can filter the results using the <code>ResourceId</code>, <code>ScalableDimension</code>, and <code>ScheduledActionNames</code> parameters.</p> <p>To create a scheduled action or update an existing one, see <a>PutScheduledAction</a>. If you are no longer using a scheduled action, you can delete it using <a>DeleteScheduledAction</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613353 = query.getOrDefault("MaxResults")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "MaxResults", valid_613353
  var valid_613354 = query.getOrDefault("NextToken")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "NextToken", valid_613354
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
  var valid_613355 = header.getOrDefault("X-Amz-Target")
  valid_613355 = validateParameter(valid_613355, JString, required = true, default = newJString(
      "AnyScaleFrontendService.DescribeScheduledActions"))
  if valid_613355 != nil:
    section.add "X-Amz-Target", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Signature")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Signature", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Content-Sha256", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Date")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Date", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Credential")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Credential", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Security-Token")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Security-Token", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Algorithm")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Algorithm", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-SignedHeaders", valid_613362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613364: Call_DescribeScheduledActions_613350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the Application Auto Scaling scheduled actions for the specified service namespace.</p> <p>You can filter the results using the <code>ResourceId</code>, <code>ScalableDimension</code>, and <code>ScheduledActionNames</code> parameters.</p> <p>To create a scheduled action or update an existing one, see <a>PutScheduledAction</a>. If you are no longer using a scheduled action, you can delete it using <a>DeleteScheduledAction</a>.</p>
  ## 
  let valid = call_613364.validator(path, query, header, formData, body)
  let scheme = call_613364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613364.url(scheme.get, call_613364.host, call_613364.base,
                         call_613364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613364, url, valid)

proc call*(call_613365: Call_DescribeScheduledActions_613350; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeScheduledActions
  ## <p>Describes the Application Auto Scaling scheduled actions for the specified service namespace.</p> <p>You can filter the results using the <code>ResourceId</code>, <code>ScalableDimension</code>, and <code>ScheduledActionNames</code> parameters.</p> <p>To create a scheduled action or update an existing one, see <a>PutScheduledAction</a>. If you are no longer using a scheduled action, you can delete it using <a>DeleteScheduledAction</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613366 = newJObject()
  var body_613367 = newJObject()
  add(query_613366, "MaxResults", newJString(MaxResults))
  add(query_613366, "NextToken", newJString(NextToken))
  if body != nil:
    body_613367 = body
  result = call_613365.call(nil, query_613366, nil, nil, body_613367)

var describeScheduledActions* = Call_DescribeScheduledActions_613350(
    name: "describeScheduledActions", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DescribeScheduledActions",
    validator: validate_DescribeScheduledActions_613351, base: "/",
    url: url_DescribeScheduledActions_613352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutScalingPolicy_613368 = ref object of OpenApiRestCall_612658
proc url_PutScalingPolicy_613370(protocol: Scheme; host: string; base: string;
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

proc validate_PutScalingPolicy_613369(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates or updates a policy for an Application Auto Scaling scalable target.</p> <p>Each scalable target is identified by a service namespace, resource ID, and scalable dimension. A scaling policy applies to the scalable target identified by those three attributes. You cannot create a scaling policy until you have registered the resource as a scalable target using <a>RegisterScalableTarget</a>.</p> <p>To update a policy, specify its policy name and the parameters that you want to change. Any parameters that you don't specify are not changed by this update request.</p> <p>You can view the scaling policies for a service namespace using <a>DescribeScalingPolicies</a>. If you are no longer using a scaling policy, you can delete it using <a>DeleteScalingPolicy</a>.</p> <p>Multiple scaling policies can be in force at the same time for the same scalable target. You can have one or more target tracking scaling policies, one or more step scaling policies, or both. However, there is a chance that multiple policies could conflict, instructing the scalable target to scale out or in at the same time. Application Auto Scaling gives precedence to the policy that provides the largest capacity for both scale out and scale in. For example, if one policy increases capacity by 3, another policy increases capacity by 200 percent, and the current capacity is 10, Application Auto Scaling uses the policy with the highest calculated capacity (200% of 10 = 20) and scales out to 30. </p> <p>Learn more about how to work with scaling policies in the <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html">Application Auto Scaling User Guide</a>.</p>
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
  var valid_613371 = header.getOrDefault("X-Amz-Target")
  valid_613371 = validateParameter(valid_613371, JString, required = true, default = newJString(
      "AnyScaleFrontendService.PutScalingPolicy"))
  if valid_613371 != nil:
    section.add "X-Amz-Target", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Signature")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Signature", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Content-Sha256", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Date")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Date", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Credential")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Credential", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Security-Token")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Security-Token", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Algorithm")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Algorithm", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-SignedHeaders", valid_613378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613380: Call_PutScalingPolicy_613368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a policy for an Application Auto Scaling scalable target.</p> <p>Each scalable target is identified by a service namespace, resource ID, and scalable dimension. A scaling policy applies to the scalable target identified by those three attributes. You cannot create a scaling policy until you have registered the resource as a scalable target using <a>RegisterScalableTarget</a>.</p> <p>To update a policy, specify its policy name and the parameters that you want to change. Any parameters that you don't specify are not changed by this update request.</p> <p>You can view the scaling policies for a service namespace using <a>DescribeScalingPolicies</a>. If you are no longer using a scaling policy, you can delete it using <a>DeleteScalingPolicy</a>.</p> <p>Multiple scaling policies can be in force at the same time for the same scalable target. You can have one or more target tracking scaling policies, one or more step scaling policies, or both. However, there is a chance that multiple policies could conflict, instructing the scalable target to scale out or in at the same time. Application Auto Scaling gives precedence to the policy that provides the largest capacity for both scale out and scale in. For example, if one policy increases capacity by 3, another policy increases capacity by 200 percent, and the current capacity is 10, Application Auto Scaling uses the policy with the highest calculated capacity (200% of 10 = 20) and scales out to 30. </p> <p>Learn more about how to work with scaling policies in the <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html">Application Auto Scaling User Guide</a>.</p>
  ## 
  let valid = call_613380.validator(path, query, header, formData, body)
  let scheme = call_613380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613380.url(scheme.get, call_613380.host, call_613380.base,
                         call_613380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613380, url, valid)

proc call*(call_613381: Call_PutScalingPolicy_613368; body: JsonNode): Recallable =
  ## putScalingPolicy
  ## <p>Creates or updates a policy for an Application Auto Scaling scalable target.</p> <p>Each scalable target is identified by a service namespace, resource ID, and scalable dimension. A scaling policy applies to the scalable target identified by those three attributes. You cannot create a scaling policy until you have registered the resource as a scalable target using <a>RegisterScalableTarget</a>.</p> <p>To update a policy, specify its policy name and the parameters that you want to change. Any parameters that you don't specify are not changed by this update request.</p> <p>You can view the scaling policies for a service namespace using <a>DescribeScalingPolicies</a>. If you are no longer using a scaling policy, you can delete it using <a>DeleteScalingPolicy</a>.</p> <p>Multiple scaling policies can be in force at the same time for the same scalable target. You can have one or more target tracking scaling policies, one or more step scaling policies, or both. However, there is a chance that multiple policies could conflict, instructing the scalable target to scale out or in at the same time. Application Auto Scaling gives precedence to the policy that provides the largest capacity for both scale out and scale in. For example, if one policy increases capacity by 3, another policy increases capacity by 200 percent, and the current capacity is 10, Application Auto Scaling uses the policy with the highest calculated capacity (200% of 10 = 20) and scales out to 30. </p> <p>Learn more about how to work with scaling policies in the <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html">Application Auto Scaling User Guide</a>.</p>
  ##   body: JObject (required)
  var body_613382 = newJObject()
  if body != nil:
    body_613382 = body
  result = call_613381.call(nil, nil, nil, nil, body_613382)

var putScalingPolicy* = Call_PutScalingPolicy_613368(name: "putScalingPolicy",
    meth: HttpMethod.HttpPost, host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.PutScalingPolicy",
    validator: validate_PutScalingPolicy_613369, base: "/",
    url: url_PutScalingPolicy_613370, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutScheduledAction_613383 = ref object of OpenApiRestCall_612658
proc url_PutScheduledAction_613385(protocol: Scheme; host: string; base: string;
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

proc validate_PutScheduledAction_613384(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates or updates a scheduled action for an Application Auto Scaling scalable target.</p> <p>Each scalable target is identified by a service namespace, resource ID, and scalable dimension. A scheduled action applies to the scalable target identified by those three attributes. You cannot create a scheduled action until you have registered the resource as a scalable target using <a>RegisterScalableTarget</a>. </p> <p>To update an action, specify its name and the parameters that you want to change. If you don't specify start and end times, the old values are deleted. Any other parameters that you don't specify are not changed by this update request.</p> <p>You can view the scheduled actions using <a>DescribeScheduledActions</a>. If you are no longer using a scheduled action, you can delete it using <a>DeleteScheduledAction</a>.</p> <p>Learn more about how to work with scheduled actions in the <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html">Application Auto Scaling User Guide</a>.</p>
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
  var valid_613386 = header.getOrDefault("X-Amz-Target")
  valid_613386 = validateParameter(valid_613386, JString, required = true, default = newJString(
      "AnyScaleFrontendService.PutScheduledAction"))
  if valid_613386 != nil:
    section.add "X-Amz-Target", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Signature")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Signature", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Content-Sha256", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Date")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Date", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Credential")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Credential", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Security-Token")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Security-Token", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Algorithm")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Algorithm", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-SignedHeaders", valid_613393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613395: Call_PutScheduledAction_613383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a scheduled action for an Application Auto Scaling scalable target.</p> <p>Each scalable target is identified by a service namespace, resource ID, and scalable dimension. A scheduled action applies to the scalable target identified by those three attributes. You cannot create a scheduled action until you have registered the resource as a scalable target using <a>RegisterScalableTarget</a>. </p> <p>To update an action, specify its name and the parameters that you want to change. If you don't specify start and end times, the old values are deleted. Any other parameters that you don't specify are not changed by this update request.</p> <p>You can view the scheduled actions using <a>DescribeScheduledActions</a>. If you are no longer using a scheduled action, you can delete it using <a>DeleteScheduledAction</a>.</p> <p>Learn more about how to work with scheduled actions in the <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html">Application Auto Scaling User Guide</a>.</p>
  ## 
  let valid = call_613395.validator(path, query, header, formData, body)
  let scheme = call_613395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613395.url(scheme.get, call_613395.host, call_613395.base,
                         call_613395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613395, url, valid)

proc call*(call_613396: Call_PutScheduledAction_613383; body: JsonNode): Recallable =
  ## putScheduledAction
  ## <p>Creates or updates a scheduled action for an Application Auto Scaling scalable target.</p> <p>Each scalable target is identified by a service namespace, resource ID, and scalable dimension. A scheduled action applies to the scalable target identified by those three attributes. You cannot create a scheduled action until you have registered the resource as a scalable target using <a>RegisterScalableTarget</a>. </p> <p>To update an action, specify its name and the parameters that you want to change. If you don't specify start and end times, the old values are deleted. Any other parameters that you don't specify are not changed by this update request.</p> <p>You can view the scheduled actions using <a>DescribeScheduledActions</a>. If you are no longer using a scheduled action, you can delete it using <a>DeleteScheduledAction</a>.</p> <p>Learn more about how to work with scheduled actions in the <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html">Application Auto Scaling User Guide</a>.</p>
  ##   body: JObject (required)
  var body_613397 = newJObject()
  if body != nil:
    body_613397 = body
  result = call_613396.call(nil, nil, nil, nil, body_613397)

var putScheduledAction* = Call_PutScheduledAction_613383(
    name: "putScheduledAction", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.PutScheduledAction",
    validator: validate_PutScheduledAction_613384, base: "/",
    url: url_PutScheduledAction_613385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterScalableTarget_613398 = ref object of OpenApiRestCall_612658
proc url_RegisterScalableTarget_613400(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterScalableTarget_613399(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Registers or updates a scalable target. A scalable target is a resource that Application Auto Scaling can scale out and scale in. Scalable targets are uniquely identified by the combination of resource ID, scalable dimension, and namespace. </p> <p>When you register a new scalable target, you must specify values for minimum and maximum capacity. Application Auto Scaling will not scale capacity to values that are outside of this range. </p> <p>To update a scalable target, specify the parameter that you want to change as well as the following parameters that identify the scalable target: resource ID, scalable dimension, and namespace. Any parameters that you don't specify are not changed by this update request. </p> <p>After you register a scalable target, you do not need to register it again to use other Application Auto Scaling operations. To see which resources have been registered, use <a>DescribeScalableTargets</a>. You can also view the scaling policies for a service namespace by using <a>DescribeScalableTargets</a>. </p> <p>If you no longer need a scalable target, you can deregister it by using <a>DeregisterScalableTarget</a>.</p>
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
  var valid_613401 = header.getOrDefault("X-Amz-Target")
  valid_613401 = validateParameter(valid_613401, JString, required = true, default = newJString(
      "AnyScaleFrontendService.RegisterScalableTarget"))
  if valid_613401 != nil:
    section.add "X-Amz-Target", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Signature")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Signature", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Content-Sha256", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Date")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Date", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Credential")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Credential", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Security-Token")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Security-Token", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Algorithm")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Algorithm", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-SignedHeaders", valid_613408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613410: Call_RegisterScalableTarget_613398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers or updates a scalable target. A scalable target is a resource that Application Auto Scaling can scale out and scale in. Scalable targets are uniquely identified by the combination of resource ID, scalable dimension, and namespace. </p> <p>When you register a new scalable target, you must specify values for minimum and maximum capacity. Application Auto Scaling will not scale capacity to values that are outside of this range. </p> <p>To update a scalable target, specify the parameter that you want to change as well as the following parameters that identify the scalable target: resource ID, scalable dimension, and namespace. Any parameters that you don't specify are not changed by this update request. </p> <p>After you register a scalable target, you do not need to register it again to use other Application Auto Scaling operations. To see which resources have been registered, use <a>DescribeScalableTargets</a>. You can also view the scaling policies for a service namespace by using <a>DescribeScalableTargets</a>. </p> <p>If you no longer need a scalable target, you can deregister it by using <a>DeregisterScalableTarget</a>.</p>
  ## 
  let valid = call_613410.validator(path, query, header, formData, body)
  let scheme = call_613410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613410.url(scheme.get, call_613410.host, call_613410.base,
                         call_613410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613410, url, valid)

proc call*(call_613411: Call_RegisterScalableTarget_613398; body: JsonNode): Recallable =
  ## registerScalableTarget
  ## <p>Registers or updates a scalable target. A scalable target is a resource that Application Auto Scaling can scale out and scale in. Scalable targets are uniquely identified by the combination of resource ID, scalable dimension, and namespace. </p> <p>When you register a new scalable target, you must specify values for minimum and maximum capacity. Application Auto Scaling will not scale capacity to values that are outside of this range. </p> <p>To update a scalable target, specify the parameter that you want to change as well as the following parameters that identify the scalable target: resource ID, scalable dimension, and namespace. Any parameters that you don't specify are not changed by this update request. </p> <p>After you register a scalable target, you do not need to register it again to use other Application Auto Scaling operations. To see which resources have been registered, use <a>DescribeScalableTargets</a>. You can also view the scaling policies for a service namespace by using <a>DescribeScalableTargets</a>. </p> <p>If you no longer need a scalable target, you can deregister it by using <a>DeregisterScalableTarget</a>.</p>
  ##   body: JObject (required)
  var body_613412 = newJObject()
  if body != nil:
    body_613412 = body
  result = call_613411.call(nil, nil, nil, nil, body_613412)

var registerScalableTarget* = Call_RegisterScalableTarget_613398(
    name: "registerScalableTarget", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.RegisterScalableTarget",
    validator: validate_RegisterScalableTarget_613399, base: "/",
    url: url_RegisterScalableTarget_613400, schemes: {Scheme.Https, Scheme.Http})
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
