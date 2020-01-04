
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_DeleteScalingPolicy_601727 = ref object of OpenApiRestCall_601389
proc url_DeleteScalingPolicy_601729(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteScalingPolicy_601728(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "AnyScaleFrontendService.DeleteScalingPolicy"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_DeleteScalingPolicy_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified scaling policy for an Application Auto Scaling scalable target.</p> <p>Deleting a step scaling policy deletes the underlying alarm action, but does not delete the CloudWatch alarm associated with the scaling policy, even if it no longer has an associated action.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html#delete-step-scaling-policy">Delete a Step Scaling Policy</a> and <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-target-tracking.html#delete-target-tracking-policy">Delete a Target Tracking Scaling Policy</a> in the <i>Application Auto Scaling User Guide</i>.</p> <p>To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>.</p>
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_DeleteScalingPolicy_601727; body: JsonNode): Recallable =
  ## deleteScalingPolicy
  ## <p>Deletes the specified scaling policy for an Application Auto Scaling scalable target.</p> <p>Deleting a step scaling policy deletes the underlying alarm action, but does not delete the CloudWatch alarm associated with the scaling policy, even if it no longer has an associated action.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html#delete-step-scaling-policy">Delete a Step Scaling Policy</a> and <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-target-tracking.html#delete-target-tracking-policy">Delete a Target Tracking Scaling Policy</a> in the <i>Application Auto Scaling User Guide</i>.</p> <p>To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>.</p>
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var deleteScalingPolicy* = Call_DeleteScalingPolicy_601727(
    name: "deleteScalingPolicy", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DeleteScalingPolicy",
    validator: validate_DeleteScalingPolicy_601728, base: "/",
    url: url_DeleteScalingPolicy_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteScheduledAction_601996 = ref object of OpenApiRestCall_601389
proc url_DeleteScheduledAction_601998(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteScheduledAction_601997(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "AnyScaleFrontendService.DeleteScheduledAction"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_DeleteScheduledAction_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified scheduled action for an Application Auto Scaling scalable target.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-scheduled-scaling.html#delete-scheduled-action">Delete a Scheduled Action</a> in the <i>Application Auto Scaling User Guide</i>.</p>
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_DeleteScheduledAction_601996; body: JsonNode): Recallable =
  ## deleteScheduledAction
  ## <p>Deletes the specified scheduled action for an Application Auto Scaling scalable target.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-scheduled-scaling.html#delete-scheduled-action">Delete a Scheduled Action</a> in the <i>Application Auto Scaling User Guide</i>.</p>
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var deleteScheduledAction* = Call_DeleteScheduledAction_601996(
    name: "deleteScheduledAction", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DeleteScheduledAction",
    validator: validate_DeleteScheduledAction_601997, base: "/",
    url: url_DeleteScheduledAction_601998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterScalableTarget_602011 = ref object of OpenApiRestCall_601389
proc url_DeregisterScalableTarget_602013(protocol: Scheme; host: string;
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

proc validate_DeregisterScalableTarget_602012(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "AnyScaleFrontendService.DeregisterScalableTarget"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_DeregisterScalableTarget_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deregisters an Application Auto Scaling scalable target.</p> <p>Deregistering a scalable target deletes the scaling policies that are associated with it.</p> <p>To create a scalable target or update an existing one, see <a>RegisterScalableTarget</a>. </p>
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_DeregisterScalableTarget_602011; body: JsonNode): Recallable =
  ## deregisterScalableTarget
  ## <p>Deregisters an Application Auto Scaling scalable target.</p> <p>Deregistering a scalable target deletes the scaling policies that are associated with it.</p> <p>To create a scalable target or update an existing one, see <a>RegisterScalableTarget</a>. </p>
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var deregisterScalableTarget* = Call_DeregisterScalableTarget_602011(
    name: "deregisterScalableTarget", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DeregisterScalableTarget",
    validator: validate_DeregisterScalableTarget_602012, base: "/",
    url: url_DeregisterScalableTarget_602013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScalableTargets_602026 = ref object of OpenApiRestCall_601389
proc url_DescribeScalableTargets_602028(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeScalableTargets_602027(path: JsonNode; query: JsonNode;
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
  var valid_602029 = query.getOrDefault("MaxResults")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "MaxResults", valid_602029
  var valid_602030 = query.getOrDefault("NextToken")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "NextToken", valid_602030
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602031 = header.getOrDefault("X-Amz-Target")
  valid_602031 = validateParameter(valid_602031, JString, required = true, default = newJString(
      "AnyScaleFrontendService.DescribeScalableTargets"))
  if valid_602031 != nil:
    section.add "X-Amz-Target", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Signature")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Signature", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Content-Sha256", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Date")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Date", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Credential")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Credential", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Security-Token")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Security-Token", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Algorithm")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Algorithm", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-SignedHeaders", valid_602038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602040: Call_DescribeScalableTargets_602026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the scalable targets in the specified namespace.</p> <p>You can filter the results using <code>ResourceIds</code> and <code>ScalableDimension</code>.</p> <p>To create a scalable target or update an existing one, see <a>RegisterScalableTarget</a>. If you are no longer using a scalable target, you can deregister it using <a>DeregisterScalableTarget</a>.</p>
  ## 
  let valid = call_602040.validator(path, query, header, formData, body)
  let scheme = call_602040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602040.url(scheme.get, call_602040.host, call_602040.base,
                         call_602040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602040, url, valid)

proc call*(call_602041: Call_DescribeScalableTargets_602026; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeScalableTargets
  ## <p>Gets information about the scalable targets in the specified namespace.</p> <p>You can filter the results using <code>ResourceIds</code> and <code>ScalableDimension</code>.</p> <p>To create a scalable target or update an existing one, see <a>RegisterScalableTarget</a>. If you are no longer using a scalable target, you can deregister it using <a>DeregisterScalableTarget</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602042 = newJObject()
  var body_602043 = newJObject()
  add(query_602042, "MaxResults", newJString(MaxResults))
  add(query_602042, "NextToken", newJString(NextToken))
  if body != nil:
    body_602043 = body
  result = call_602041.call(nil, query_602042, nil, nil, body_602043)

var describeScalableTargets* = Call_DescribeScalableTargets_602026(
    name: "describeScalableTargets", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DescribeScalableTargets",
    validator: validate_DescribeScalableTargets_602027, base: "/",
    url: url_DescribeScalableTargets_602028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScalingActivities_602045 = ref object of OpenApiRestCall_601389
proc url_DescribeScalingActivities_602047(protocol: Scheme; host: string;
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

proc validate_DescribeScalingActivities_602046(path: JsonNode; query: JsonNode;
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
  var valid_602048 = query.getOrDefault("MaxResults")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "MaxResults", valid_602048
  var valid_602049 = query.getOrDefault("NextToken")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "NextToken", valid_602049
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602050 = header.getOrDefault("X-Amz-Target")
  valid_602050 = validateParameter(valid_602050, JString, required = true, default = newJString(
      "AnyScaleFrontendService.DescribeScalingActivities"))
  if valid_602050 != nil:
    section.add "X-Amz-Target", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Signature")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Signature", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Content-Sha256", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Date")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Date", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Credential")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Credential", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Security-Token")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Security-Token", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Algorithm")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Algorithm", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-SignedHeaders", valid_602057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602059: Call_DescribeScalingActivities_602045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides descriptive information about the scaling activities in the specified namespace from the previous six weeks.</p> <p>You can filter the results using <code>ResourceId</code> and <code>ScalableDimension</code>.</p> <p>Scaling activities are triggered by CloudWatch alarms that are associated with scaling policies. To view the scaling policies for a service namespace, see <a>DescribeScalingPolicies</a>. To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>.</p>
  ## 
  let valid = call_602059.validator(path, query, header, formData, body)
  let scheme = call_602059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602059.url(scheme.get, call_602059.host, call_602059.base,
                         call_602059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602059, url, valid)

proc call*(call_602060: Call_DescribeScalingActivities_602045; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeScalingActivities
  ## <p>Provides descriptive information about the scaling activities in the specified namespace from the previous six weeks.</p> <p>You can filter the results using <code>ResourceId</code> and <code>ScalableDimension</code>.</p> <p>Scaling activities are triggered by CloudWatch alarms that are associated with scaling policies. To view the scaling policies for a service namespace, see <a>DescribeScalingPolicies</a>. To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602061 = newJObject()
  var body_602062 = newJObject()
  add(query_602061, "MaxResults", newJString(MaxResults))
  add(query_602061, "NextToken", newJString(NextToken))
  if body != nil:
    body_602062 = body
  result = call_602060.call(nil, query_602061, nil, nil, body_602062)

var describeScalingActivities* = Call_DescribeScalingActivities_602045(
    name: "describeScalingActivities", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DescribeScalingActivities",
    validator: validate_DescribeScalingActivities_602046, base: "/",
    url: url_DescribeScalingActivities_602047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScalingPolicies_602063 = ref object of OpenApiRestCall_601389
proc url_DescribeScalingPolicies_602065(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeScalingPolicies_602064(path: JsonNode; query: JsonNode;
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
  var valid_602066 = query.getOrDefault("MaxResults")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "MaxResults", valid_602066
  var valid_602067 = query.getOrDefault("NextToken")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "NextToken", valid_602067
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602068 = header.getOrDefault("X-Amz-Target")
  valid_602068 = validateParameter(valid_602068, JString, required = true, default = newJString(
      "AnyScaleFrontendService.DescribeScalingPolicies"))
  if valid_602068 != nil:
    section.add "X-Amz-Target", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Signature")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Signature", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Content-Sha256", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Date")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Date", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Credential")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Credential", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Security-Token")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Security-Token", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Algorithm")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Algorithm", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-SignedHeaders", valid_602075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602077: Call_DescribeScalingPolicies_602063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the Application Auto Scaling scaling policies for the specified service namespace.</p> <p>You can filter the results using <code>ResourceId</code>, <code>ScalableDimension</code>, and <code>PolicyNames</code>.</p> <p>To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>. If you are no longer using a scaling policy, you can delete it using <a>DeleteScalingPolicy</a>.</p>
  ## 
  let valid = call_602077.validator(path, query, header, formData, body)
  let scheme = call_602077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602077.url(scheme.get, call_602077.host, call_602077.base,
                         call_602077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602077, url, valid)

proc call*(call_602078: Call_DescribeScalingPolicies_602063; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeScalingPolicies
  ## <p>Describes the Application Auto Scaling scaling policies for the specified service namespace.</p> <p>You can filter the results using <code>ResourceId</code>, <code>ScalableDimension</code>, and <code>PolicyNames</code>.</p> <p>To create a scaling policy or update an existing one, see <a>PutScalingPolicy</a>. If you are no longer using a scaling policy, you can delete it using <a>DeleteScalingPolicy</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602079 = newJObject()
  var body_602080 = newJObject()
  add(query_602079, "MaxResults", newJString(MaxResults))
  add(query_602079, "NextToken", newJString(NextToken))
  if body != nil:
    body_602080 = body
  result = call_602078.call(nil, query_602079, nil, nil, body_602080)

var describeScalingPolicies* = Call_DescribeScalingPolicies_602063(
    name: "describeScalingPolicies", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DescribeScalingPolicies",
    validator: validate_DescribeScalingPolicies_602064, base: "/",
    url: url_DescribeScalingPolicies_602065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScheduledActions_602081 = ref object of OpenApiRestCall_601389
proc url_DescribeScheduledActions_602083(protocol: Scheme; host: string;
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

proc validate_DescribeScheduledActions_602082(path: JsonNode; query: JsonNode;
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
  var valid_602084 = query.getOrDefault("MaxResults")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "MaxResults", valid_602084
  var valid_602085 = query.getOrDefault("NextToken")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "NextToken", valid_602085
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602086 = header.getOrDefault("X-Amz-Target")
  valid_602086 = validateParameter(valid_602086, JString, required = true, default = newJString(
      "AnyScaleFrontendService.DescribeScheduledActions"))
  if valid_602086 != nil:
    section.add "X-Amz-Target", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Signature")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Signature", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Content-Sha256", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Date")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Date", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Credential")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Credential", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Security-Token")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Security-Token", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Algorithm")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Algorithm", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-SignedHeaders", valid_602093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602095: Call_DescribeScheduledActions_602081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the Application Auto Scaling scheduled actions for the specified service namespace.</p> <p>You can filter the results using the <code>ResourceId</code>, <code>ScalableDimension</code>, and <code>ScheduledActionNames</code> parameters.</p> <p>To create a scheduled action or update an existing one, see <a>PutScheduledAction</a>. If you are no longer using a scheduled action, you can delete it using <a>DeleteScheduledAction</a>.</p>
  ## 
  let valid = call_602095.validator(path, query, header, formData, body)
  let scheme = call_602095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602095.url(scheme.get, call_602095.host, call_602095.base,
                         call_602095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602095, url, valid)

proc call*(call_602096: Call_DescribeScheduledActions_602081; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeScheduledActions
  ## <p>Describes the Application Auto Scaling scheduled actions for the specified service namespace.</p> <p>You can filter the results using the <code>ResourceId</code>, <code>ScalableDimension</code>, and <code>ScheduledActionNames</code> parameters.</p> <p>To create a scheduled action or update an existing one, see <a>PutScheduledAction</a>. If you are no longer using a scheduled action, you can delete it using <a>DeleteScheduledAction</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602097 = newJObject()
  var body_602098 = newJObject()
  add(query_602097, "MaxResults", newJString(MaxResults))
  add(query_602097, "NextToken", newJString(NextToken))
  if body != nil:
    body_602098 = body
  result = call_602096.call(nil, query_602097, nil, nil, body_602098)

var describeScheduledActions* = Call_DescribeScheduledActions_602081(
    name: "describeScheduledActions", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.DescribeScheduledActions",
    validator: validate_DescribeScheduledActions_602082, base: "/",
    url: url_DescribeScheduledActions_602083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutScalingPolicy_602099 = ref object of OpenApiRestCall_601389
proc url_PutScalingPolicy_602101(protocol: Scheme; host: string; base: string;
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

proc validate_PutScalingPolicy_602100(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602102 = header.getOrDefault("X-Amz-Target")
  valid_602102 = validateParameter(valid_602102, JString, required = true, default = newJString(
      "AnyScaleFrontendService.PutScalingPolicy"))
  if valid_602102 != nil:
    section.add "X-Amz-Target", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Signature")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Signature", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Content-Sha256", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Date")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Date", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Credential")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Credential", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Security-Token")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Security-Token", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Algorithm")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Algorithm", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-SignedHeaders", valid_602109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602111: Call_PutScalingPolicy_602099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a policy for an Application Auto Scaling scalable target.</p> <p>Each scalable target is identified by a service namespace, resource ID, and scalable dimension. A scaling policy applies to the scalable target identified by those three attributes. You cannot create a scaling policy until you have registered the resource as a scalable target using <a>RegisterScalableTarget</a>.</p> <p>To update a policy, specify its policy name and the parameters that you want to change. Any parameters that you don't specify are not changed by this update request.</p> <p>You can view the scaling policies for a service namespace using <a>DescribeScalingPolicies</a>. If you are no longer using a scaling policy, you can delete it using <a>DeleteScalingPolicy</a>.</p> <p>Multiple scaling policies can be in force at the same time for the same scalable target. You can have one or more target tracking scaling policies, one or more step scaling policies, or both. However, there is a chance that multiple policies could conflict, instructing the scalable target to scale out or in at the same time. Application Auto Scaling gives precedence to the policy that provides the largest capacity for both scale out and scale in. For example, if one policy increases capacity by 3, another policy increases capacity by 200 percent, and the current capacity is 10, Application Auto Scaling uses the policy with the highest calculated capacity (200% of 10 = 20) and scales out to 30. </p> <p>Learn more about how to work with scaling policies in the <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html">Application Auto Scaling User Guide</a>.</p>
  ## 
  let valid = call_602111.validator(path, query, header, formData, body)
  let scheme = call_602111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602111.url(scheme.get, call_602111.host, call_602111.base,
                         call_602111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602111, url, valid)

proc call*(call_602112: Call_PutScalingPolicy_602099; body: JsonNode): Recallable =
  ## putScalingPolicy
  ## <p>Creates or updates a policy for an Application Auto Scaling scalable target.</p> <p>Each scalable target is identified by a service namespace, resource ID, and scalable dimension. A scaling policy applies to the scalable target identified by those three attributes. You cannot create a scaling policy until you have registered the resource as a scalable target using <a>RegisterScalableTarget</a>.</p> <p>To update a policy, specify its policy name and the parameters that you want to change. Any parameters that you don't specify are not changed by this update request.</p> <p>You can view the scaling policies for a service namespace using <a>DescribeScalingPolicies</a>. If you are no longer using a scaling policy, you can delete it using <a>DeleteScalingPolicy</a>.</p> <p>Multiple scaling policies can be in force at the same time for the same scalable target. You can have one or more target tracking scaling policies, one or more step scaling policies, or both. However, there is a chance that multiple policies could conflict, instructing the scalable target to scale out or in at the same time. Application Auto Scaling gives precedence to the policy that provides the largest capacity for both scale out and scale in. For example, if one policy increases capacity by 3, another policy increases capacity by 200 percent, and the current capacity is 10, Application Auto Scaling uses the policy with the highest calculated capacity (200% of 10 = 20) and scales out to 30. </p> <p>Learn more about how to work with scaling policies in the <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html">Application Auto Scaling User Guide</a>.</p>
  ##   body: JObject (required)
  var body_602113 = newJObject()
  if body != nil:
    body_602113 = body
  result = call_602112.call(nil, nil, nil, nil, body_602113)

var putScalingPolicy* = Call_PutScalingPolicy_602099(name: "putScalingPolicy",
    meth: HttpMethod.HttpPost, host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.PutScalingPolicy",
    validator: validate_PutScalingPolicy_602100, base: "/",
    url: url_PutScalingPolicy_602101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutScheduledAction_602114 = ref object of OpenApiRestCall_601389
proc url_PutScheduledAction_602116(protocol: Scheme; host: string; base: string;
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

proc validate_PutScheduledAction_602115(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602117 = header.getOrDefault("X-Amz-Target")
  valid_602117 = validateParameter(valid_602117, JString, required = true, default = newJString(
      "AnyScaleFrontendService.PutScheduledAction"))
  if valid_602117 != nil:
    section.add "X-Amz-Target", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Signature")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Signature", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Content-Sha256", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Date")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Date", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Credential")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Credential", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Security-Token")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Security-Token", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Algorithm")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Algorithm", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-SignedHeaders", valid_602124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602126: Call_PutScheduledAction_602114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a scheduled action for an Application Auto Scaling scalable target.</p> <p>Each scalable target is identified by a service namespace, resource ID, and scalable dimension. A scheduled action applies to the scalable target identified by those three attributes. You cannot create a scheduled action until you have registered the resource as a scalable target using <a>RegisterScalableTarget</a>. </p> <p>To update an action, specify its name and the parameters that you want to change. If you don't specify start and end times, the old values are deleted. Any other parameters that you don't specify are not changed by this update request.</p> <p>You can view the scheduled actions using <a>DescribeScheduledActions</a>. If you are no longer using a scheduled action, you can delete it using <a>DeleteScheduledAction</a>.</p> <p>Learn more about how to work with scheduled actions in the <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html">Application Auto Scaling User Guide</a>.</p>
  ## 
  let valid = call_602126.validator(path, query, header, formData, body)
  let scheme = call_602126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602126.url(scheme.get, call_602126.host, call_602126.base,
                         call_602126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602126, url, valid)

proc call*(call_602127: Call_PutScheduledAction_602114; body: JsonNode): Recallable =
  ## putScheduledAction
  ## <p>Creates or updates a scheduled action for an Application Auto Scaling scalable target.</p> <p>Each scalable target is identified by a service namespace, resource ID, and scalable dimension. A scheduled action applies to the scalable target identified by those three attributes. You cannot create a scheduled action until you have registered the resource as a scalable target using <a>RegisterScalableTarget</a>. </p> <p>To update an action, specify its name and the parameters that you want to change. If you don't specify start and end times, the old values are deleted. Any other parameters that you don't specify are not changed by this update request.</p> <p>You can view the scheduled actions using <a>DescribeScheduledActions</a>. If you are no longer using a scheduled action, you can delete it using <a>DeleteScheduledAction</a>.</p> <p>Learn more about how to work with scheduled actions in the <a href="https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html">Application Auto Scaling User Guide</a>.</p>
  ##   body: JObject (required)
  var body_602128 = newJObject()
  if body != nil:
    body_602128 = body
  result = call_602127.call(nil, nil, nil, nil, body_602128)

var putScheduledAction* = Call_PutScheduledAction_602114(
    name: "putScheduledAction", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.PutScheduledAction",
    validator: validate_PutScheduledAction_602115, base: "/",
    url: url_PutScheduledAction_602116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterScalableTarget_602129 = ref object of OpenApiRestCall_601389
proc url_RegisterScalableTarget_602131(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterScalableTarget_602130(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602132 = header.getOrDefault("X-Amz-Target")
  valid_602132 = validateParameter(valid_602132, JString, required = true, default = newJString(
      "AnyScaleFrontendService.RegisterScalableTarget"))
  if valid_602132 != nil:
    section.add "X-Amz-Target", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Signature")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Signature", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Content-Sha256", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Date")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Date", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Credential")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Credential", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Security-Token")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Security-Token", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Algorithm")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Algorithm", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-SignedHeaders", valid_602139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602141: Call_RegisterScalableTarget_602129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers or updates a scalable target. A scalable target is a resource that Application Auto Scaling can scale out and scale in. Scalable targets are uniquely identified by the combination of resource ID, scalable dimension, and namespace. </p> <p>When you register a new scalable target, you must specify values for minimum and maximum capacity. Application Auto Scaling will not scale capacity to values that are outside of this range. </p> <p>To update a scalable target, specify the parameter that you want to change as well as the following parameters that identify the scalable target: resource ID, scalable dimension, and namespace. Any parameters that you don't specify are not changed by this update request. </p> <p>After you register a scalable target, you do not need to register it again to use other Application Auto Scaling operations. To see which resources have been registered, use <a>DescribeScalableTargets</a>. You can also view the scaling policies for a service namespace by using <a>DescribeScalableTargets</a>. </p> <p>If you no longer need a scalable target, you can deregister it by using <a>DeregisterScalableTarget</a>.</p>
  ## 
  let valid = call_602141.validator(path, query, header, formData, body)
  let scheme = call_602141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602141.url(scheme.get, call_602141.host, call_602141.base,
                         call_602141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602141, url, valid)

proc call*(call_602142: Call_RegisterScalableTarget_602129; body: JsonNode): Recallable =
  ## registerScalableTarget
  ## <p>Registers or updates a scalable target. A scalable target is a resource that Application Auto Scaling can scale out and scale in. Scalable targets are uniquely identified by the combination of resource ID, scalable dimension, and namespace. </p> <p>When you register a new scalable target, you must specify values for minimum and maximum capacity. Application Auto Scaling will not scale capacity to values that are outside of this range. </p> <p>To update a scalable target, specify the parameter that you want to change as well as the following parameters that identify the scalable target: resource ID, scalable dimension, and namespace. Any parameters that you don't specify are not changed by this update request. </p> <p>After you register a scalable target, you do not need to register it again to use other Application Auto Scaling operations. To see which resources have been registered, use <a>DescribeScalableTargets</a>. You can also view the scaling policies for a service namespace by using <a>DescribeScalableTargets</a>. </p> <p>If you no longer need a scalable target, you can deregister it by using <a>DeregisterScalableTarget</a>.</p>
  ##   body: JObject (required)
  var body_602143 = newJObject()
  if body != nil:
    body_602143 = body
  result = call_602142.call(nil, nil, nil, nil, body_602143)

var registerScalableTarget* = Call_RegisterScalableTarget_602129(
    name: "registerScalableTarget", meth: HttpMethod.HttpPost,
    host: "application-autoscaling.amazonaws.com",
    route: "/#X-Amz-Target=AnyScaleFrontendService.RegisterScalableTarget",
    validator: validate_RegisterScalableTarget_602130, base: "/",
    url: url_RegisterScalableTarget_602131, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
