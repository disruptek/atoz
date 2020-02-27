
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

## auto-generated via openapi macro
## title: AWS Step Functions
## version: 2016-11-23
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Step Functions</fullname> <p>AWS Step Functions is a service that lets you coordinate the components of distributed applications and microservices using visual workflows.</p> <p>You can use Step Functions to build applications from individual components, each of which performs a discrete function, or <i>task</i>, allowing you to scale and change applications quickly. Step Functions provides a console that helps visualize the components of your application as a series of steps. Step Functions automatically triggers and tracks each step, and retries steps when there are errors, so your application executes predictably and in the right order every time. Step Functions logs the state of each step, so you can quickly diagnose and debug any issues.</p> <p>Step Functions manages operations and underlying infrastructure to ensure your application is available at any scale. You can run tasks on AWS, your own servers, or any system that has access to AWS. You can access and use Step Functions using the console, the AWS SDKs, or an HTTP API. For more information about Step Functions, see the <i> <a href="https://docs.aws.amazon.com/step-functions/latest/dg/welcome.html">AWS Step Functions Developer Guide</a> </i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/states/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "states.ap-northeast-1.amazonaws.com", "ap-southeast-1": "states.ap-southeast-1.amazonaws.com",
                           "us-west-2": "states.us-west-2.amazonaws.com",
                           "eu-west-2": "states.eu-west-2.amazonaws.com", "ap-northeast-3": "states.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "states.eu-central-1.amazonaws.com",
                           "us-east-2": "states.us-east-2.amazonaws.com",
                           "us-east-1": "states.us-east-1.amazonaws.com", "cn-northwest-1": "states.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "states.ap-northeast-2.amazonaws.com",
                           "ap-south-1": "states.ap-south-1.amazonaws.com",
                           "eu-north-1": "states.eu-north-1.amazonaws.com",
                           "us-west-1": "states.us-west-1.amazonaws.com", "us-gov-east-1": "states.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "states.eu-west-3.amazonaws.com",
                           "cn-north-1": "states.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "states.sa-east-1.amazonaws.com",
                           "eu-west-1": "states.eu-west-1.amazonaws.com", "us-gov-west-1": "states.us-gov-west-1.amazonaws.com", "ap-southeast-2": "states.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "states.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "states.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "states.ap-southeast-1.amazonaws.com",
      "us-west-2": "states.us-west-2.amazonaws.com",
      "eu-west-2": "states.eu-west-2.amazonaws.com",
      "ap-northeast-3": "states.ap-northeast-3.amazonaws.com",
      "eu-central-1": "states.eu-central-1.amazonaws.com",
      "us-east-2": "states.us-east-2.amazonaws.com",
      "us-east-1": "states.us-east-1.amazonaws.com",
      "cn-northwest-1": "states.cn-northwest-1.amazonaws.com.cn",
      "ap-northeast-2": "states.ap-northeast-2.amazonaws.com",
      "ap-south-1": "states.ap-south-1.amazonaws.com",
      "eu-north-1": "states.eu-north-1.amazonaws.com",
      "us-west-1": "states.us-west-1.amazonaws.com",
      "us-gov-east-1": "states.us-gov-east-1.amazonaws.com",
      "eu-west-3": "states.eu-west-3.amazonaws.com",
      "cn-north-1": "states.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "states.sa-east-1.amazonaws.com",
      "eu-west-1": "states.eu-west-1.amazonaws.com",
      "us-gov-west-1": "states.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "states.ap-southeast-2.amazonaws.com",
      "ca-central-1": "states.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "states"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateActivity_617205 = ref object of OpenApiRestCall_616866
proc url_CreateActivity_617207(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateActivity_617206(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## <p>Creates an activity. An activity is a task that you write in any programming language and host on any machine that has access to AWS Step Functions. Activities must poll Step Functions using the <code>GetActivityTask</code> API action and respond using <code>SendTask*</code> API actions. This function lets Step Functions know the existence of your activity and returns an identifier for use in a state machine and when polling from the activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateActivity</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateActivity</code>'s idempotency check is based on the activity <code>name</code>. If a following request has different <code>tags</code> values, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>tags</code> will not be updated, even if they are different.</p> </note>
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
      "AWSStepFunctions.CreateActivity"))
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

proc call*(call_617364: Call_CreateActivity_617205; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an activity. An activity is a task that you write in any programming language and host on any machine that has access to AWS Step Functions. Activities must poll Step Functions using the <code>GetActivityTask</code> API action and respond using <code>SendTask*</code> API actions. This function lets Step Functions know the existence of your activity and returns an identifier for use in a state machine and when polling from the activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateActivity</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateActivity</code>'s idempotency check is based on the activity <code>name</code>. If a following request has different <code>tags</code> values, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>tags</code> will not be updated, even if they are different.</p> </note>
  ## 
  let valid = call_617364.validator(path, query, header, formData, body, _)
  let scheme = call_617364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617364.url(scheme.get, call_617364.host, call_617364.base,
                         call_617364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617364, url, valid, _)

proc call*(call_617435: Call_CreateActivity_617205; body: JsonNode): Recallable =
  ## createActivity
  ## <p>Creates an activity. An activity is a task that you write in any programming language and host on any machine that has access to AWS Step Functions. Activities must poll Step Functions using the <code>GetActivityTask</code> API action and respond using <code>SendTask*</code> API actions. This function lets Step Functions know the existence of your activity and returns an identifier for use in a state machine and when polling from the activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateActivity</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateActivity</code>'s idempotency check is based on the activity <code>name</code>. If a following request has different <code>tags</code> values, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>tags</code> will not be updated, even if they are different.</p> </note>
  ##   body: JObject (required)
  var body_617436 = newJObject()
  if body != nil:
    body_617436 = body
  result = call_617435.call(nil, nil, nil, nil, body_617436)

var createActivity* = Call_CreateActivity_617205(name: "createActivity",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.CreateActivity",
    validator: validate_CreateActivity_617206, base: "/", url: url_CreateActivity_617207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStateMachine_617477 = ref object of OpenApiRestCall_616866
proc url_CreateStateMachine_617479(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStateMachine_617478(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## <p>Creates a state machine. A state machine consists of a collection of states that can do work (<code>Task</code> states), determine to which states to transition next (<code>Choice</code> states), stop an execution with an error (<code>Fail</code> states), and so on. State machines are specified using a JSON-based, structured language. For more information, see <a href="https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html">Amazon States Language</a> in the AWS Step Functions User Guide.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateStateMachine</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateStateMachine</code>'s idempotency check is based on the state machine <code>name</code>, <code>definition</code>, <code>type</code>, and <code>LoggingConfiguration</code>. If a following request has a different <code>roleArn</code> or <code>tags</code>, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>roleArn</code> and <code>tags</code> will not be updated, even if they are different.</p> </note>
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
      "AWSStepFunctions.CreateStateMachine"))
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

proc call*(call_617489: Call_CreateStateMachine_617477; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a state machine. A state machine consists of a collection of states that can do work (<code>Task</code> states), determine to which states to transition next (<code>Choice</code> states), stop an execution with an error (<code>Fail</code> states), and so on. State machines are specified using a JSON-based, structured language. For more information, see <a href="https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html">Amazon States Language</a> in the AWS Step Functions User Guide.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateStateMachine</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateStateMachine</code>'s idempotency check is based on the state machine <code>name</code>, <code>definition</code>, <code>type</code>, and <code>LoggingConfiguration</code>. If a following request has a different <code>roleArn</code> or <code>tags</code>, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>roleArn</code> and <code>tags</code> will not be updated, even if they are different.</p> </note>
  ## 
  let valid = call_617489.validator(path, query, header, formData, body, _)
  let scheme = call_617489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617489.url(scheme.get, call_617489.host, call_617489.base,
                         call_617489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617489, url, valid, _)

proc call*(call_617490: Call_CreateStateMachine_617477; body: JsonNode): Recallable =
  ## createStateMachine
  ## <p>Creates a state machine. A state machine consists of a collection of states that can do work (<code>Task</code> states), determine to which states to transition next (<code>Choice</code> states), stop an execution with an error (<code>Fail</code> states), and so on. State machines are specified using a JSON-based, structured language. For more information, see <a href="https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html">Amazon States Language</a> in the AWS Step Functions User Guide.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateStateMachine</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateStateMachine</code>'s idempotency check is based on the state machine <code>name</code>, <code>definition</code>, <code>type</code>, and <code>LoggingConfiguration</code>. If a following request has a different <code>roleArn</code> or <code>tags</code>, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>roleArn</code> and <code>tags</code> will not be updated, even if they are different.</p> </note>
  ##   body: JObject (required)
  var body_617491 = newJObject()
  if body != nil:
    body_617491 = body
  result = call_617490.call(nil, nil, nil, nil, body_617491)

var createStateMachine* = Call_CreateStateMachine_617477(
    name: "createStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.CreateStateMachine",
    validator: validate_CreateStateMachine_617478, base: "/",
    url: url_CreateStateMachine_617479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivity_617492 = ref object of OpenApiRestCall_616866
proc url_DeleteActivity_617494(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteActivity_617493(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## Deletes an activity.
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
      "AWSStepFunctions.DeleteActivity"))
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

proc call*(call_617504: Call_DeleteActivity_617492; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an activity.
  ## 
  let valid = call_617504.validator(path, query, header, formData, body, _)
  let scheme = call_617504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617504.url(scheme.get, call_617504.host, call_617504.base,
                         call_617504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617504, url, valid, _)

proc call*(call_617505: Call_DeleteActivity_617492; body: JsonNode): Recallable =
  ## deleteActivity
  ## Deletes an activity.
  ##   body: JObject (required)
  var body_617506 = newJObject()
  if body != nil:
    body_617506 = body
  result = call_617505.call(nil, nil, nil, nil, body_617506)

var deleteActivity* = Call_DeleteActivity_617492(name: "deleteActivity",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DeleteActivity",
    validator: validate_DeleteActivity_617493, base: "/", url: url_DeleteActivity_617494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStateMachine_617507 = ref object of OpenApiRestCall_616866
proc url_DeleteStateMachine_617509(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteStateMachine_617508(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## <p>Deletes a state machine. This is an asynchronous operation: It sets the state machine's status to <code>DELETING</code> and begins the deletion process. </p> <note> <p>For <code>EXPRESS</code>state machines, the deletion will happen eventually (usually less than a minute). Running executions may emit logs after <code>DeleteStateMachine</code> API is called.</p> </note>
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
      "AWSStepFunctions.DeleteStateMachine"))
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

proc call*(call_617519: Call_DeleteStateMachine_617507; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a state machine. This is an asynchronous operation: It sets the state machine's status to <code>DELETING</code> and begins the deletion process. </p> <note> <p>For <code>EXPRESS</code>state machines, the deletion will happen eventually (usually less than a minute). Running executions may emit logs after <code>DeleteStateMachine</code> API is called.</p> </note>
  ## 
  let valid = call_617519.validator(path, query, header, formData, body, _)
  let scheme = call_617519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617519.url(scheme.get, call_617519.host, call_617519.base,
                         call_617519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617519, url, valid, _)

proc call*(call_617520: Call_DeleteStateMachine_617507; body: JsonNode): Recallable =
  ## deleteStateMachine
  ## <p>Deletes a state machine. This is an asynchronous operation: It sets the state machine's status to <code>DELETING</code> and begins the deletion process. </p> <note> <p>For <code>EXPRESS</code>state machines, the deletion will happen eventually (usually less than a minute). Running executions may emit logs after <code>DeleteStateMachine</code> API is called.</p> </note>
  ##   body: JObject (required)
  var body_617521 = newJObject()
  if body != nil:
    body_617521 = body
  result = call_617520.call(nil, nil, nil, nil, body_617521)

var deleteStateMachine* = Call_DeleteStateMachine_617507(
    name: "deleteStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DeleteStateMachine",
    validator: validate_DeleteStateMachine_617508, base: "/",
    url: url_DeleteStateMachine_617509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivity_617522 = ref object of OpenApiRestCall_616866
proc url_DescribeActivity_617524(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeActivity_617523(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## <p>Describes an activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
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
      "AWSStepFunctions.DescribeActivity"))
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

proc call*(call_617534: Call_DescribeActivity_617522; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes an activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_617534.validator(path, query, header, formData, body, _)
  let scheme = call_617534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617534.url(scheme.get, call_617534.host, call_617534.base,
                         call_617534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617534, url, valid, _)

proc call*(call_617535: Call_DescribeActivity_617522; body: JsonNode): Recallable =
  ## describeActivity
  ## <p>Describes an activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_617536 = newJObject()
  if body != nil:
    body_617536 = body
  result = call_617535.call(nil, nil, nil, nil, body_617536)

var describeActivity* = Call_DescribeActivity_617522(name: "describeActivity",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeActivity",
    validator: validate_DescribeActivity_617523, base: "/",
    url: url_DescribeActivity_617524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExecution_617537 = ref object of OpenApiRestCall_616866
proc url_DescribeExecution_617539(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExecution_617538(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## <p>Describes an execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
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
      "AWSStepFunctions.DescribeExecution"))
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

proc call*(call_617549: Call_DescribeExecution_617537; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes an execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
  ## 
  let valid = call_617549.validator(path, query, header, formData, body, _)
  let scheme = call_617549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617549.url(scheme.get, call_617549.host, call_617549.base,
                         call_617549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617549, url, valid, _)

proc call*(call_617550: Call_DescribeExecution_617537; body: JsonNode): Recallable =
  ## describeExecution
  ## <p>Describes an execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
  ##   body: JObject (required)
  var body_617551 = newJObject()
  if body != nil:
    body_617551 = body
  result = call_617550.call(nil, nil, nil, nil, body_617551)

var describeExecution* = Call_DescribeExecution_617537(name: "describeExecution",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeExecution",
    validator: validate_DescribeExecution_617538, base: "/",
    url: url_DescribeExecution_617539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStateMachine_617552 = ref object of OpenApiRestCall_616866
proc url_DescribeStateMachine_617554(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStateMachine_617553(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Describes a state machine.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
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
      "AWSStepFunctions.DescribeStateMachine"))
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

proc call*(call_617564: Call_DescribeStateMachine_617552; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes a state machine.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_617564.validator(path, query, header, formData, body, _)
  let scheme = call_617564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617564.url(scheme.get, call_617564.host, call_617564.base,
                         call_617564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617564, url, valid, _)

proc call*(call_617565: Call_DescribeStateMachine_617552; body: JsonNode): Recallable =
  ## describeStateMachine
  ## <p>Describes a state machine.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_617566 = newJObject()
  if body != nil:
    body_617566 = body
  result = call_617565.call(nil, nil, nil, nil, body_617566)

var describeStateMachine* = Call_DescribeStateMachine_617552(
    name: "describeStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeStateMachine",
    validator: validate_DescribeStateMachine_617553, base: "/",
    url: url_DescribeStateMachine_617554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStateMachineForExecution_617567 = ref object of OpenApiRestCall_616866
proc url_DescribeStateMachineForExecution_617569(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStateMachineForExecution_617568(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## <p>Describes the state machine associated with a specific execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
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
      "AWSStepFunctions.DescribeStateMachineForExecution"))
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

proc call*(call_617579: Call_DescribeStateMachineForExecution_617567;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the state machine associated with a specific execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
  ## 
  let valid = call_617579.validator(path, query, header, formData, body, _)
  let scheme = call_617579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617579.url(scheme.get, call_617579.host, call_617579.base,
                         call_617579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617579, url, valid, _)

proc call*(call_617580: Call_DescribeStateMachineForExecution_617567;
          body: JsonNode): Recallable =
  ## describeStateMachineForExecution
  ## <p>Describes the state machine associated with a specific execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
  ##   body: JObject (required)
  var body_617581 = newJObject()
  if body != nil:
    body_617581 = body
  result = call_617580.call(nil, nil, nil, nil, body_617581)

var describeStateMachineForExecution* = Call_DescribeStateMachineForExecution_617567(
    name: "describeStateMachineForExecution", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeStateMachineForExecution",
    validator: validate_DescribeStateMachineForExecution_617568, base: "/",
    url: url_DescribeStateMachineForExecution_617569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetActivityTask_617582 = ref object of OpenApiRestCall_616866
proc url_GetActivityTask_617584(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetActivityTask_617583(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## <p>Used by workers to retrieve a task (with the specified activity ARN) which has been scheduled for execution by a running state machine. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available (i.e. an execution of a task of this type is needed.) The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns a <code>taskToken</code> with a null string.</p> <important> <p>Workers should set their client side socket timeout to at least 65 seconds (5 seconds higher than the maximum time the service may hold the poll request).</p> <p>Polling with <code>GetActivityTask</code> can cause latency in some implementations. See <a href="https://docs.aws.amazon.com/step-functions/latest/dg/bp-activity-pollers.html">Avoid Latency When Polling for Activity Tasks</a> in the Step Functions Developer Guide.</p> </important>
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
      "AWSStepFunctions.GetActivityTask"))
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

proc call*(call_617594: Call_GetActivityTask_617582; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Used by workers to retrieve a task (with the specified activity ARN) which has been scheduled for execution by a running state machine. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available (i.e. an execution of a task of this type is needed.) The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns a <code>taskToken</code> with a null string.</p> <important> <p>Workers should set their client side socket timeout to at least 65 seconds (5 seconds higher than the maximum time the service may hold the poll request).</p> <p>Polling with <code>GetActivityTask</code> can cause latency in some implementations. See <a href="https://docs.aws.amazon.com/step-functions/latest/dg/bp-activity-pollers.html">Avoid Latency When Polling for Activity Tasks</a> in the Step Functions Developer Guide.</p> </important>
  ## 
  let valid = call_617594.validator(path, query, header, formData, body, _)
  let scheme = call_617594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617594.url(scheme.get, call_617594.host, call_617594.base,
                         call_617594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617594, url, valid, _)

proc call*(call_617595: Call_GetActivityTask_617582; body: JsonNode): Recallable =
  ## getActivityTask
  ## <p>Used by workers to retrieve a task (with the specified activity ARN) which has been scheduled for execution by a running state machine. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available (i.e. an execution of a task of this type is needed.) The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns a <code>taskToken</code> with a null string.</p> <important> <p>Workers should set their client side socket timeout to at least 65 seconds (5 seconds higher than the maximum time the service may hold the poll request).</p> <p>Polling with <code>GetActivityTask</code> can cause latency in some implementations. See <a href="https://docs.aws.amazon.com/step-functions/latest/dg/bp-activity-pollers.html">Avoid Latency When Polling for Activity Tasks</a> in the Step Functions Developer Guide.</p> </important>
  ##   body: JObject (required)
  var body_617596 = newJObject()
  if body != nil:
    body_617596 = body
  result = call_617595.call(nil, nil, nil, nil, body_617596)

var getActivityTask* = Call_GetActivityTask_617582(name: "getActivityTask",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.GetActivityTask",
    validator: validate_GetActivityTask_617583, base: "/", url: url_GetActivityTask_617584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExecutionHistory_617597 = ref object of OpenApiRestCall_616866
proc url_GetExecutionHistory_617599(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetExecutionHistory_617598(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## <p>Returns the history of the specified execution as a list of events. By default, the results are returned in ascending order of the <code>timeStamp</code> of the events. Use the <code>reverseOrder</code> parameter to get the latest events first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617600 = query.getOrDefault("maxResults")
  valid_617600 = validateParameter(valid_617600, JString, required = false,
                                 default = nil)
  if valid_617600 != nil:
    section.add "maxResults", valid_617600
  var valid_617601 = query.getOrDefault("nextToken")
  valid_617601 = validateParameter(valid_617601, JString, required = false,
                                 default = nil)
  if valid_617601 != nil:
    section.add "nextToken", valid_617601
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
  var valid_617602 = header.getOrDefault("X-Amz-Date")
  valid_617602 = validateParameter(valid_617602, JString, required = false,
                                 default = nil)
  if valid_617602 != nil:
    section.add "X-Amz-Date", valid_617602
  var valid_617603 = header.getOrDefault("X-Amz-Security-Token")
  valid_617603 = validateParameter(valid_617603, JString, required = false,
                                 default = nil)
  if valid_617603 != nil:
    section.add "X-Amz-Security-Token", valid_617603
  var valid_617604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617604 = validateParameter(valid_617604, JString, required = false,
                                 default = nil)
  if valid_617604 != nil:
    section.add "X-Amz-Content-Sha256", valid_617604
  var valid_617605 = header.getOrDefault("X-Amz-Algorithm")
  valid_617605 = validateParameter(valid_617605, JString, required = false,
                                 default = nil)
  if valid_617605 != nil:
    section.add "X-Amz-Algorithm", valid_617605
  var valid_617606 = header.getOrDefault("X-Amz-Signature")
  valid_617606 = validateParameter(valid_617606, JString, required = false,
                                 default = nil)
  if valid_617606 != nil:
    section.add "X-Amz-Signature", valid_617606
  var valid_617607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617607 = validateParameter(valid_617607, JString, required = false,
                                 default = nil)
  if valid_617607 != nil:
    section.add "X-Amz-SignedHeaders", valid_617607
  var valid_617608 = header.getOrDefault("X-Amz-Target")
  valid_617608 = validateParameter(valid_617608, JString, required = true, default = newJString(
      "AWSStepFunctions.GetExecutionHistory"))
  if valid_617608 != nil:
    section.add "X-Amz-Target", valid_617608
  var valid_617609 = header.getOrDefault("X-Amz-Credential")
  valid_617609 = validateParameter(valid_617609, JString, required = false,
                                 default = nil)
  if valid_617609 != nil:
    section.add "X-Amz-Credential", valid_617609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617611: Call_GetExecutionHistory_617597; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the history of the specified execution as a list of events. By default, the results are returned in ascending order of the <code>timeStamp</code> of the events. Use the <code>reverseOrder</code> parameter to get the latest events first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
  ## 
  let valid = call_617611.validator(path, query, header, formData, body, _)
  let scheme = call_617611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617611.url(scheme.get, call_617611.host, call_617611.base,
                         call_617611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617611, url, valid, _)

proc call*(call_617612: Call_GetExecutionHistory_617597; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getExecutionHistory
  ## <p>Returns the history of the specified execution as a list of events. By default, the results are returned in ascending order of the <code>timeStamp</code> of the events. Use the <code>reverseOrder</code> parameter to get the latest events first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617613 = newJObject()
  var body_617614 = newJObject()
  add(query_617613, "maxResults", newJString(maxResults))
  add(query_617613, "nextToken", newJString(nextToken))
  if body != nil:
    body_617614 = body
  result = call_617612.call(nil, query_617613, nil, nil, body_617614)

var getExecutionHistory* = Call_GetExecutionHistory_617597(
    name: "getExecutionHistory", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.GetExecutionHistory",
    validator: validate_GetExecutionHistory_617598, base: "/",
    url: url_GetExecutionHistory_617599, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActivities_617616 = ref object of OpenApiRestCall_616866
proc url_ListActivities_617618(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListActivities_617617(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## <p>Lists the existing activities.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617619 = query.getOrDefault("maxResults")
  valid_617619 = validateParameter(valid_617619, JString, required = false,
                                 default = nil)
  if valid_617619 != nil:
    section.add "maxResults", valid_617619
  var valid_617620 = query.getOrDefault("nextToken")
  valid_617620 = validateParameter(valid_617620, JString, required = false,
                                 default = nil)
  if valid_617620 != nil:
    section.add "nextToken", valid_617620
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
  var valid_617621 = header.getOrDefault("X-Amz-Date")
  valid_617621 = validateParameter(valid_617621, JString, required = false,
                                 default = nil)
  if valid_617621 != nil:
    section.add "X-Amz-Date", valid_617621
  var valid_617622 = header.getOrDefault("X-Amz-Security-Token")
  valid_617622 = validateParameter(valid_617622, JString, required = false,
                                 default = nil)
  if valid_617622 != nil:
    section.add "X-Amz-Security-Token", valid_617622
  var valid_617623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617623 = validateParameter(valid_617623, JString, required = false,
                                 default = nil)
  if valid_617623 != nil:
    section.add "X-Amz-Content-Sha256", valid_617623
  var valid_617624 = header.getOrDefault("X-Amz-Algorithm")
  valid_617624 = validateParameter(valid_617624, JString, required = false,
                                 default = nil)
  if valid_617624 != nil:
    section.add "X-Amz-Algorithm", valid_617624
  var valid_617625 = header.getOrDefault("X-Amz-Signature")
  valid_617625 = validateParameter(valid_617625, JString, required = false,
                                 default = nil)
  if valid_617625 != nil:
    section.add "X-Amz-Signature", valid_617625
  var valid_617626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617626 = validateParameter(valid_617626, JString, required = false,
                                 default = nil)
  if valid_617626 != nil:
    section.add "X-Amz-SignedHeaders", valid_617626
  var valid_617627 = header.getOrDefault("X-Amz-Target")
  valid_617627 = validateParameter(valid_617627, JString, required = true, default = newJString(
      "AWSStepFunctions.ListActivities"))
  if valid_617627 != nil:
    section.add "X-Amz-Target", valid_617627
  var valid_617628 = header.getOrDefault("X-Amz-Credential")
  valid_617628 = validateParameter(valid_617628, JString, required = false,
                                 default = nil)
  if valid_617628 != nil:
    section.add "X-Amz-Credential", valid_617628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617630: Call_ListActivities_617616; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the existing activities.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_617630.validator(path, query, header, formData, body, _)
  let scheme = call_617630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617630.url(scheme.get, call_617630.host, call_617630.base,
                         call_617630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617630, url, valid, _)

proc call*(call_617631: Call_ListActivities_617616; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listActivities
  ## <p>Lists the existing activities.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617632 = newJObject()
  var body_617633 = newJObject()
  add(query_617632, "maxResults", newJString(maxResults))
  add(query_617632, "nextToken", newJString(nextToken))
  if body != nil:
    body_617633 = body
  result = call_617631.call(nil, query_617632, nil, nil, body_617633)

var listActivities* = Call_ListActivities_617616(name: "listActivities",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListActivities",
    validator: validate_ListActivities_617617, base: "/", url: url_ListActivities_617618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExecutions_617634 = ref object of OpenApiRestCall_616866
proc url_ListExecutions_617636(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListExecutions_617635(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## <p>Lists the executions of a state machine that meet the filtering criteria. Results are sorted by time, with the most recent execution first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617637 = query.getOrDefault("maxResults")
  valid_617637 = validateParameter(valid_617637, JString, required = false,
                                 default = nil)
  if valid_617637 != nil:
    section.add "maxResults", valid_617637
  var valid_617638 = query.getOrDefault("nextToken")
  valid_617638 = validateParameter(valid_617638, JString, required = false,
                                 default = nil)
  if valid_617638 != nil:
    section.add "nextToken", valid_617638
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
  var valid_617639 = header.getOrDefault("X-Amz-Date")
  valid_617639 = validateParameter(valid_617639, JString, required = false,
                                 default = nil)
  if valid_617639 != nil:
    section.add "X-Amz-Date", valid_617639
  var valid_617640 = header.getOrDefault("X-Amz-Security-Token")
  valid_617640 = validateParameter(valid_617640, JString, required = false,
                                 default = nil)
  if valid_617640 != nil:
    section.add "X-Amz-Security-Token", valid_617640
  var valid_617641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617641 = validateParameter(valid_617641, JString, required = false,
                                 default = nil)
  if valid_617641 != nil:
    section.add "X-Amz-Content-Sha256", valid_617641
  var valid_617642 = header.getOrDefault("X-Amz-Algorithm")
  valid_617642 = validateParameter(valid_617642, JString, required = false,
                                 default = nil)
  if valid_617642 != nil:
    section.add "X-Amz-Algorithm", valid_617642
  var valid_617643 = header.getOrDefault("X-Amz-Signature")
  valid_617643 = validateParameter(valid_617643, JString, required = false,
                                 default = nil)
  if valid_617643 != nil:
    section.add "X-Amz-Signature", valid_617643
  var valid_617644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617644 = validateParameter(valid_617644, JString, required = false,
                                 default = nil)
  if valid_617644 != nil:
    section.add "X-Amz-SignedHeaders", valid_617644
  var valid_617645 = header.getOrDefault("X-Amz-Target")
  valid_617645 = validateParameter(valid_617645, JString, required = true, default = newJString(
      "AWSStepFunctions.ListExecutions"))
  if valid_617645 != nil:
    section.add "X-Amz-Target", valid_617645
  var valid_617646 = header.getOrDefault("X-Amz-Credential")
  valid_617646 = validateParameter(valid_617646, JString, required = false,
                                 default = nil)
  if valid_617646 != nil:
    section.add "X-Amz-Credential", valid_617646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617648: Call_ListExecutions_617634; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the executions of a state machine that meet the filtering criteria. Results are sorted by time, with the most recent execution first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
  ## 
  let valid = call_617648.validator(path, query, header, formData, body, _)
  let scheme = call_617648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617648.url(scheme.get, call_617648.host, call_617648.base,
                         call_617648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617648, url, valid, _)

proc call*(call_617649: Call_ListExecutions_617634; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listExecutions
  ## <p>Lists the executions of a state machine that meet the filtering criteria. Results are sorted by time, with the most recent execution first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617650 = newJObject()
  var body_617651 = newJObject()
  add(query_617650, "maxResults", newJString(maxResults))
  add(query_617650, "nextToken", newJString(nextToken))
  if body != nil:
    body_617651 = body
  result = call_617649.call(nil, query_617650, nil, nil, body_617651)

var listExecutions* = Call_ListExecutions_617634(name: "listExecutions",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListExecutions",
    validator: validate_ListExecutions_617635, base: "/", url: url_ListExecutions_617636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStateMachines_617652 = ref object of OpenApiRestCall_616866
proc url_ListStateMachines_617654(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStateMachines_617653(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## <p>Lists the existing state machines.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_617655 = query.getOrDefault("maxResults")
  valid_617655 = validateParameter(valid_617655, JString, required = false,
                                 default = nil)
  if valid_617655 != nil:
    section.add "maxResults", valid_617655
  var valid_617656 = query.getOrDefault("nextToken")
  valid_617656 = validateParameter(valid_617656, JString, required = false,
                                 default = nil)
  if valid_617656 != nil:
    section.add "nextToken", valid_617656
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
  var valid_617657 = header.getOrDefault("X-Amz-Date")
  valid_617657 = validateParameter(valid_617657, JString, required = false,
                                 default = nil)
  if valid_617657 != nil:
    section.add "X-Amz-Date", valid_617657
  var valid_617658 = header.getOrDefault("X-Amz-Security-Token")
  valid_617658 = validateParameter(valid_617658, JString, required = false,
                                 default = nil)
  if valid_617658 != nil:
    section.add "X-Amz-Security-Token", valid_617658
  var valid_617659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617659 = validateParameter(valid_617659, JString, required = false,
                                 default = nil)
  if valid_617659 != nil:
    section.add "X-Amz-Content-Sha256", valid_617659
  var valid_617660 = header.getOrDefault("X-Amz-Algorithm")
  valid_617660 = validateParameter(valid_617660, JString, required = false,
                                 default = nil)
  if valid_617660 != nil:
    section.add "X-Amz-Algorithm", valid_617660
  var valid_617661 = header.getOrDefault("X-Amz-Signature")
  valid_617661 = validateParameter(valid_617661, JString, required = false,
                                 default = nil)
  if valid_617661 != nil:
    section.add "X-Amz-Signature", valid_617661
  var valid_617662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617662 = validateParameter(valid_617662, JString, required = false,
                                 default = nil)
  if valid_617662 != nil:
    section.add "X-Amz-SignedHeaders", valid_617662
  var valid_617663 = header.getOrDefault("X-Amz-Target")
  valid_617663 = validateParameter(valid_617663, JString, required = true, default = newJString(
      "AWSStepFunctions.ListStateMachines"))
  if valid_617663 != nil:
    section.add "X-Amz-Target", valid_617663
  var valid_617664 = header.getOrDefault("X-Amz-Credential")
  valid_617664 = validateParameter(valid_617664, JString, required = false,
                                 default = nil)
  if valid_617664 != nil:
    section.add "X-Amz-Credential", valid_617664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617666: Call_ListStateMachines_617652; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the existing state machines.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_617666.validator(path, query, header, formData, body, _)
  let scheme = call_617666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617666.url(scheme.get, call_617666.host, call_617666.base,
                         call_617666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617666, url, valid, _)

proc call*(call_617667: Call_ListStateMachines_617652; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listStateMachines
  ## <p>Lists the existing state machines.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_617668 = newJObject()
  var body_617669 = newJObject()
  add(query_617668, "maxResults", newJString(maxResults))
  add(query_617668, "nextToken", newJString(nextToken))
  if body != nil:
    body_617669 = body
  result = call_617667.call(nil, query_617668, nil, nil, body_617669)

var listStateMachines* = Call_ListStateMachines_617652(name: "listStateMachines",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListStateMachines",
    validator: validate_ListStateMachines_617653, base: "/",
    url: url_ListStateMachines_617654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_617670 = ref object of OpenApiRestCall_616866
proc url_ListTagsForResource_617672(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_617671(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## <p>List tags for a given resource.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
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
  var valid_617673 = header.getOrDefault("X-Amz-Date")
  valid_617673 = validateParameter(valid_617673, JString, required = false,
                                 default = nil)
  if valid_617673 != nil:
    section.add "X-Amz-Date", valid_617673
  var valid_617674 = header.getOrDefault("X-Amz-Security-Token")
  valid_617674 = validateParameter(valid_617674, JString, required = false,
                                 default = nil)
  if valid_617674 != nil:
    section.add "X-Amz-Security-Token", valid_617674
  var valid_617675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617675 = validateParameter(valid_617675, JString, required = false,
                                 default = nil)
  if valid_617675 != nil:
    section.add "X-Amz-Content-Sha256", valid_617675
  var valid_617676 = header.getOrDefault("X-Amz-Algorithm")
  valid_617676 = validateParameter(valid_617676, JString, required = false,
                                 default = nil)
  if valid_617676 != nil:
    section.add "X-Amz-Algorithm", valid_617676
  var valid_617677 = header.getOrDefault("X-Amz-Signature")
  valid_617677 = validateParameter(valid_617677, JString, required = false,
                                 default = nil)
  if valid_617677 != nil:
    section.add "X-Amz-Signature", valid_617677
  var valid_617678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617678 = validateParameter(valid_617678, JString, required = false,
                                 default = nil)
  if valid_617678 != nil:
    section.add "X-Amz-SignedHeaders", valid_617678
  var valid_617679 = header.getOrDefault("X-Amz-Target")
  valid_617679 = validateParameter(valid_617679, JString, required = true, default = newJString(
      "AWSStepFunctions.ListTagsForResource"))
  if valid_617679 != nil:
    section.add "X-Amz-Target", valid_617679
  var valid_617680 = header.getOrDefault("X-Amz-Credential")
  valid_617680 = validateParameter(valid_617680, JString, required = false,
                                 default = nil)
  if valid_617680 != nil:
    section.add "X-Amz-Credential", valid_617680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617682: Call_ListTagsForResource_617670; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>List tags for a given resource.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ## 
  let valid = call_617682.validator(path, query, header, formData, body, _)
  let scheme = call_617682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617682.url(scheme.get, call_617682.host, call_617682.base,
                         call_617682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617682, url, valid, _)

proc call*(call_617683: Call_ListTagsForResource_617670; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>List tags for a given resource.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ##   body: JObject (required)
  var body_617684 = newJObject()
  if body != nil:
    body_617684 = body
  result = call_617683.call(nil, nil, nil, nil, body_617684)

var listTagsForResource* = Call_ListTagsForResource_617670(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListTagsForResource",
    validator: validate_ListTagsForResource_617671, base: "/",
    url: url_ListTagsForResource_617672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTaskFailure_617685 = ref object of OpenApiRestCall_616866
proc url_SendTaskFailure_617687(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendTaskFailure_617686(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> failed.
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
  var valid_617688 = header.getOrDefault("X-Amz-Date")
  valid_617688 = validateParameter(valid_617688, JString, required = false,
                                 default = nil)
  if valid_617688 != nil:
    section.add "X-Amz-Date", valid_617688
  var valid_617689 = header.getOrDefault("X-Amz-Security-Token")
  valid_617689 = validateParameter(valid_617689, JString, required = false,
                                 default = nil)
  if valid_617689 != nil:
    section.add "X-Amz-Security-Token", valid_617689
  var valid_617690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617690 = validateParameter(valid_617690, JString, required = false,
                                 default = nil)
  if valid_617690 != nil:
    section.add "X-Amz-Content-Sha256", valid_617690
  var valid_617691 = header.getOrDefault("X-Amz-Algorithm")
  valid_617691 = validateParameter(valid_617691, JString, required = false,
                                 default = nil)
  if valid_617691 != nil:
    section.add "X-Amz-Algorithm", valid_617691
  var valid_617692 = header.getOrDefault("X-Amz-Signature")
  valid_617692 = validateParameter(valid_617692, JString, required = false,
                                 default = nil)
  if valid_617692 != nil:
    section.add "X-Amz-Signature", valid_617692
  var valid_617693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617693 = validateParameter(valid_617693, JString, required = false,
                                 default = nil)
  if valid_617693 != nil:
    section.add "X-Amz-SignedHeaders", valid_617693
  var valid_617694 = header.getOrDefault("X-Amz-Target")
  valid_617694 = validateParameter(valid_617694, JString, required = true, default = newJString(
      "AWSStepFunctions.SendTaskFailure"))
  if valid_617694 != nil:
    section.add "X-Amz-Target", valid_617694
  var valid_617695 = header.getOrDefault("X-Amz-Credential")
  valid_617695 = validateParameter(valid_617695, JString, required = false,
                                 default = nil)
  if valid_617695 != nil:
    section.add "X-Amz-Credential", valid_617695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617697: Call_SendTaskFailure_617685; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> failed.
  ## 
  let valid = call_617697.validator(path, query, header, formData, body, _)
  let scheme = call_617697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617697.url(scheme.get, call_617697.host, call_617697.base,
                         call_617697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617697, url, valid, _)

proc call*(call_617698: Call_SendTaskFailure_617685; body: JsonNode): Recallable =
  ## sendTaskFailure
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> failed.
  ##   body: JObject (required)
  var body_617699 = newJObject()
  if body != nil:
    body_617699 = body
  result = call_617698.call(nil, nil, nil, nil, body_617699)

var sendTaskFailure* = Call_SendTaskFailure_617685(name: "sendTaskFailure",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.SendTaskFailure",
    validator: validate_SendTaskFailure_617686, base: "/", url: url_SendTaskFailure_617687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTaskHeartbeat_617700 = ref object of OpenApiRestCall_616866
proc url_SendTaskHeartbeat_617702(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendTaskHeartbeat_617701(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## <p>Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report to Step Functions that the task represented by the specified <code>taskToken</code> is still making progress. This action resets the <code>Heartbeat</code> clock. The <code>Heartbeat</code> threshold is specified in the state machine's Amazon States Language definition (<code>HeartbeatSeconds</code>). This action does not in itself create an event in the execution history. However, if the task times out, the execution history contains an <code>ActivityTimedOut</code> entry for activities, or a <code>TaskTimedOut</code> entry for for tasks using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-sync">job run</a> or <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern.</p> <note> <p>The <code>Timeout</code> of a task, defined in the state machine's Amazon States Language definition, is its maximum allowed duration, regardless of the number of <a>SendTaskHeartbeat</a> requests received. Use <code>HeartbeatSeconds</code> to configure the timeout interval for heartbeats.</p> </note>
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
  var valid_617703 = header.getOrDefault("X-Amz-Date")
  valid_617703 = validateParameter(valid_617703, JString, required = false,
                                 default = nil)
  if valid_617703 != nil:
    section.add "X-Amz-Date", valid_617703
  var valid_617704 = header.getOrDefault("X-Amz-Security-Token")
  valid_617704 = validateParameter(valid_617704, JString, required = false,
                                 default = nil)
  if valid_617704 != nil:
    section.add "X-Amz-Security-Token", valid_617704
  var valid_617705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617705 = validateParameter(valid_617705, JString, required = false,
                                 default = nil)
  if valid_617705 != nil:
    section.add "X-Amz-Content-Sha256", valid_617705
  var valid_617706 = header.getOrDefault("X-Amz-Algorithm")
  valid_617706 = validateParameter(valid_617706, JString, required = false,
                                 default = nil)
  if valid_617706 != nil:
    section.add "X-Amz-Algorithm", valid_617706
  var valid_617707 = header.getOrDefault("X-Amz-Signature")
  valid_617707 = validateParameter(valid_617707, JString, required = false,
                                 default = nil)
  if valid_617707 != nil:
    section.add "X-Amz-Signature", valid_617707
  var valid_617708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617708 = validateParameter(valid_617708, JString, required = false,
                                 default = nil)
  if valid_617708 != nil:
    section.add "X-Amz-SignedHeaders", valid_617708
  var valid_617709 = header.getOrDefault("X-Amz-Target")
  valid_617709 = validateParameter(valid_617709, JString, required = true, default = newJString(
      "AWSStepFunctions.SendTaskHeartbeat"))
  if valid_617709 != nil:
    section.add "X-Amz-Target", valid_617709
  var valid_617710 = header.getOrDefault("X-Amz-Credential")
  valid_617710 = validateParameter(valid_617710, JString, required = false,
                                 default = nil)
  if valid_617710 != nil:
    section.add "X-Amz-Credential", valid_617710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617712: Call_SendTaskHeartbeat_617700; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report to Step Functions that the task represented by the specified <code>taskToken</code> is still making progress. This action resets the <code>Heartbeat</code> clock. The <code>Heartbeat</code> threshold is specified in the state machine's Amazon States Language definition (<code>HeartbeatSeconds</code>). This action does not in itself create an event in the execution history. However, if the task times out, the execution history contains an <code>ActivityTimedOut</code> entry for activities, or a <code>TaskTimedOut</code> entry for for tasks using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-sync">job run</a> or <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern.</p> <note> <p>The <code>Timeout</code> of a task, defined in the state machine's Amazon States Language definition, is its maximum allowed duration, regardless of the number of <a>SendTaskHeartbeat</a> requests received. Use <code>HeartbeatSeconds</code> to configure the timeout interval for heartbeats.</p> </note>
  ## 
  let valid = call_617712.validator(path, query, header, formData, body, _)
  let scheme = call_617712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617712.url(scheme.get, call_617712.host, call_617712.base,
                         call_617712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617712, url, valid, _)

proc call*(call_617713: Call_SendTaskHeartbeat_617700; body: JsonNode): Recallable =
  ## sendTaskHeartbeat
  ## <p>Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report to Step Functions that the task represented by the specified <code>taskToken</code> is still making progress. This action resets the <code>Heartbeat</code> clock. The <code>Heartbeat</code> threshold is specified in the state machine's Amazon States Language definition (<code>HeartbeatSeconds</code>). This action does not in itself create an event in the execution history. However, if the task times out, the execution history contains an <code>ActivityTimedOut</code> entry for activities, or a <code>TaskTimedOut</code> entry for for tasks using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-sync">job run</a> or <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern.</p> <note> <p>The <code>Timeout</code> of a task, defined in the state machine's Amazon States Language definition, is its maximum allowed duration, regardless of the number of <a>SendTaskHeartbeat</a> requests received. Use <code>HeartbeatSeconds</code> to configure the timeout interval for heartbeats.</p> </note>
  ##   body: JObject (required)
  var body_617714 = newJObject()
  if body != nil:
    body_617714 = body
  result = call_617713.call(nil, nil, nil, nil, body_617714)

var sendTaskHeartbeat* = Call_SendTaskHeartbeat_617700(name: "sendTaskHeartbeat",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.SendTaskHeartbeat",
    validator: validate_SendTaskHeartbeat_617701, base: "/",
    url: url_SendTaskHeartbeat_617702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTaskSuccess_617715 = ref object of OpenApiRestCall_616866
proc url_SendTaskSuccess_617717(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendTaskSuccess_617716(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> completed successfully.
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
  var valid_617718 = header.getOrDefault("X-Amz-Date")
  valid_617718 = validateParameter(valid_617718, JString, required = false,
                                 default = nil)
  if valid_617718 != nil:
    section.add "X-Amz-Date", valid_617718
  var valid_617719 = header.getOrDefault("X-Amz-Security-Token")
  valid_617719 = validateParameter(valid_617719, JString, required = false,
                                 default = nil)
  if valid_617719 != nil:
    section.add "X-Amz-Security-Token", valid_617719
  var valid_617720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617720 = validateParameter(valid_617720, JString, required = false,
                                 default = nil)
  if valid_617720 != nil:
    section.add "X-Amz-Content-Sha256", valid_617720
  var valid_617721 = header.getOrDefault("X-Amz-Algorithm")
  valid_617721 = validateParameter(valid_617721, JString, required = false,
                                 default = nil)
  if valid_617721 != nil:
    section.add "X-Amz-Algorithm", valid_617721
  var valid_617722 = header.getOrDefault("X-Amz-Signature")
  valid_617722 = validateParameter(valid_617722, JString, required = false,
                                 default = nil)
  if valid_617722 != nil:
    section.add "X-Amz-Signature", valid_617722
  var valid_617723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617723 = validateParameter(valid_617723, JString, required = false,
                                 default = nil)
  if valid_617723 != nil:
    section.add "X-Amz-SignedHeaders", valid_617723
  var valid_617724 = header.getOrDefault("X-Amz-Target")
  valid_617724 = validateParameter(valid_617724, JString, required = true, default = newJString(
      "AWSStepFunctions.SendTaskSuccess"))
  if valid_617724 != nil:
    section.add "X-Amz-Target", valid_617724
  var valid_617725 = header.getOrDefault("X-Amz-Credential")
  valid_617725 = validateParameter(valid_617725, JString, required = false,
                                 default = nil)
  if valid_617725 != nil:
    section.add "X-Amz-Credential", valid_617725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617727: Call_SendTaskSuccess_617715; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> completed successfully.
  ## 
  let valid = call_617727.validator(path, query, header, formData, body, _)
  let scheme = call_617727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617727.url(scheme.get, call_617727.host, call_617727.base,
                         call_617727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617727, url, valid, _)

proc call*(call_617728: Call_SendTaskSuccess_617715; body: JsonNode): Recallable =
  ## sendTaskSuccess
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> completed successfully.
  ##   body: JObject (required)
  var body_617729 = newJObject()
  if body != nil:
    body_617729 = body
  result = call_617728.call(nil, nil, nil, nil, body_617729)

var sendTaskSuccess* = Call_SendTaskSuccess_617715(name: "sendTaskSuccess",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.SendTaskSuccess",
    validator: validate_SendTaskSuccess_617716, base: "/", url: url_SendTaskSuccess_617717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExecution_617730 = ref object of OpenApiRestCall_616866
proc url_StartExecution_617732(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartExecution_617731(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## <p>Starts a state machine execution.</p> <note> <p> <code>StartExecution</code> is idempotent. If <code>StartExecution</code> is called with the same name and input as a running execution, the call will succeed and return the same response as the original request. If the execution is closed or if the input is different, it will return a 400 <code>ExecutionAlreadyExists</code> error. Names can be reused after 90 days. </p> </note>
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
  var valid_617733 = header.getOrDefault("X-Amz-Date")
  valid_617733 = validateParameter(valid_617733, JString, required = false,
                                 default = nil)
  if valid_617733 != nil:
    section.add "X-Amz-Date", valid_617733
  var valid_617734 = header.getOrDefault("X-Amz-Security-Token")
  valid_617734 = validateParameter(valid_617734, JString, required = false,
                                 default = nil)
  if valid_617734 != nil:
    section.add "X-Amz-Security-Token", valid_617734
  var valid_617735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617735 = validateParameter(valid_617735, JString, required = false,
                                 default = nil)
  if valid_617735 != nil:
    section.add "X-Amz-Content-Sha256", valid_617735
  var valid_617736 = header.getOrDefault("X-Amz-Algorithm")
  valid_617736 = validateParameter(valid_617736, JString, required = false,
                                 default = nil)
  if valid_617736 != nil:
    section.add "X-Amz-Algorithm", valid_617736
  var valid_617737 = header.getOrDefault("X-Amz-Signature")
  valid_617737 = validateParameter(valid_617737, JString, required = false,
                                 default = nil)
  if valid_617737 != nil:
    section.add "X-Amz-Signature", valid_617737
  var valid_617738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617738 = validateParameter(valid_617738, JString, required = false,
                                 default = nil)
  if valid_617738 != nil:
    section.add "X-Amz-SignedHeaders", valid_617738
  var valid_617739 = header.getOrDefault("X-Amz-Target")
  valid_617739 = validateParameter(valid_617739, JString, required = true, default = newJString(
      "AWSStepFunctions.StartExecution"))
  if valid_617739 != nil:
    section.add "X-Amz-Target", valid_617739
  var valid_617740 = header.getOrDefault("X-Amz-Credential")
  valid_617740 = validateParameter(valid_617740, JString, required = false,
                                 default = nil)
  if valid_617740 != nil:
    section.add "X-Amz-Credential", valid_617740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617742: Call_StartExecution_617730; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a state machine execution.</p> <note> <p> <code>StartExecution</code> is idempotent. If <code>StartExecution</code> is called with the same name and input as a running execution, the call will succeed and return the same response as the original request. If the execution is closed or if the input is different, it will return a 400 <code>ExecutionAlreadyExists</code> error. Names can be reused after 90 days. </p> </note>
  ## 
  let valid = call_617742.validator(path, query, header, formData, body, _)
  let scheme = call_617742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617742.url(scheme.get, call_617742.host, call_617742.base,
                         call_617742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617742, url, valid, _)

proc call*(call_617743: Call_StartExecution_617730; body: JsonNode): Recallable =
  ## startExecution
  ## <p>Starts a state machine execution.</p> <note> <p> <code>StartExecution</code> is idempotent. If <code>StartExecution</code> is called with the same name and input as a running execution, the call will succeed and return the same response as the original request. If the execution is closed or if the input is different, it will return a 400 <code>ExecutionAlreadyExists</code> error. Names can be reused after 90 days. </p> </note>
  ##   body: JObject (required)
  var body_617744 = newJObject()
  if body != nil:
    body_617744 = body
  result = call_617743.call(nil, nil, nil, nil, body_617744)

var startExecution* = Call_StartExecution_617730(name: "startExecution",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.StartExecution",
    validator: validate_StartExecution_617731, base: "/", url: url_StartExecution_617732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopExecution_617745 = ref object of OpenApiRestCall_616866
proc url_StopExecution_617747(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopExecution_617746(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Stops an execution.</p> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
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
  var valid_617748 = header.getOrDefault("X-Amz-Date")
  valid_617748 = validateParameter(valid_617748, JString, required = false,
                                 default = nil)
  if valid_617748 != nil:
    section.add "X-Amz-Date", valid_617748
  var valid_617749 = header.getOrDefault("X-Amz-Security-Token")
  valid_617749 = validateParameter(valid_617749, JString, required = false,
                                 default = nil)
  if valid_617749 != nil:
    section.add "X-Amz-Security-Token", valid_617749
  var valid_617750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617750 = validateParameter(valid_617750, JString, required = false,
                                 default = nil)
  if valid_617750 != nil:
    section.add "X-Amz-Content-Sha256", valid_617750
  var valid_617751 = header.getOrDefault("X-Amz-Algorithm")
  valid_617751 = validateParameter(valid_617751, JString, required = false,
                                 default = nil)
  if valid_617751 != nil:
    section.add "X-Amz-Algorithm", valid_617751
  var valid_617752 = header.getOrDefault("X-Amz-Signature")
  valid_617752 = validateParameter(valid_617752, JString, required = false,
                                 default = nil)
  if valid_617752 != nil:
    section.add "X-Amz-Signature", valid_617752
  var valid_617753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617753 = validateParameter(valid_617753, JString, required = false,
                                 default = nil)
  if valid_617753 != nil:
    section.add "X-Amz-SignedHeaders", valid_617753
  var valid_617754 = header.getOrDefault("X-Amz-Target")
  valid_617754 = validateParameter(valid_617754, JString, required = true, default = newJString(
      "AWSStepFunctions.StopExecution"))
  if valid_617754 != nil:
    section.add "X-Amz-Target", valid_617754
  var valid_617755 = header.getOrDefault("X-Amz-Credential")
  valid_617755 = validateParameter(valid_617755, JString, required = false,
                                 default = nil)
  if valid_617755 != nil:
    section.add "X-Amz-Credential", valid_617755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617757: Call_StopExecution_617745; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops an execution.</p> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
  ## 
  let valid = call_617757.validator(path, query, header, formData, body, _)
  let scheme = call_617757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617757.url(scheme.get, call_617757.host, call_617757.base,
                         call_617757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617757, url, valid, _)

proc call*(call_617758: Call_StopExecution_617745; body: JsonNode): Recallable =
  ## stopExecution
  ## <p>Stops an execution.</p> <p>This API action is not supported by <code>EXPRESS</code> state machines.</p>
  ##   body: JObject (required)
  var body_617759 = newJObject()
  if body != nil:
    body_617759 = body
  result = call_617758.call(nil, nil, nil, nil, body_617759)

var stopExecution* = Call_StopExecution_617745(name: "stopExecution",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.StopExecution",
    validator: validate_StopExecution_617746, base: "/", url: url_StopExecution_617747,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_617760 = ref object of OpenApiRestCall_616866
proc url_TagResource_617762(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_617761(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Add a tag to a Step Functions resource.</p> <p>An array of key-value pairs. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>, and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html">Controlling Access Using IAM Tags</a>.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
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
  var valid_617763 = header.getOrDefault("X-Amz-Date")
  valid_617763 = validateParameter(valid_617763, JString, required = false,
                                 default = nil)
  if valid_617763 != nil:
    section.add "X-Amz-Date", valid_617763
  var valid_617764 = header.getOrDefault("X-Amz-Security-Token")
  valid_617764 = validateParameter(valid_617764, JString, required = false,
                                 default = nil)
  if valid_617764 != nil:
    section.add "X-Amz-Security-Token", valid_617764
  var valid_617765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617765 = validateParameter(valid_617765, JString, required = false,
                                 default = nil)
  if valid_617765 != nil:
    section.add "X-Amz-Content-Sha256", valid_617765
  var valid_617766 = header.getOrDefault("X-Amz-Algorithm")
  valid_617766 = validateParameter(valid_617766, JString, required = false,
                                 default = nil)
  if valid_617766 != nil:
    section.add "X-Amz-Algorithm", valid_617766
  var valid_617767 = header.getOrDefault("X-Amz-Signature")
  valid_617767 = validateParameter(valid_617767, JString, required = false,
                                 default = nil)
  if valid_617767 != nil:
    section.add "X-Amz-Signature", valid_617767
  var valid_617768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617768 = validateParameter(valid_617768, JString, required = false,
                                 default = nil)
  if valid_617768 != nil:
    section.add "X-Amz-SignedHeaders", valid_617768
  var valid_617769 = header.getOrDefault("X-Amz-Target")
  valid_617769 = validateParameter(valid_617769, JString, required = true, default = newJString(
      "AWSStepFunctions.TagResource"))
  if valid_617769 != nil:
    section.add "X-Amz-Target", valid_617769
  var valid_617770 = header.getOrDefault("X-Amz-Credential")
  valid_617770 = validateParameter(valid_617770, JString, required = false,
                                 default = nil)
  if valid_617770 != nil:
    section.add "X-Amz-Credential", valid_617770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617772: Call_TagResource_617760; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Add a tag to a Step Functions resource.</p> <p>An array of key-value pairs. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>, and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html">Controlling Access Using IAM Tags</a>.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ## 
  let valid = call_617772.validator(path, query, header, formData, body, _)
  let scheme = call_617772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617772.url(scheme.get, call_617772.host, call_617772.base,
                         call_617772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617772, url, valid, _)

proc call*(call_617773: Call_TagResource_617760; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add a tag to a Step Functions resource.</p> <p>An array of key-value pairs. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>, and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html">Controlling Access Using IAM Tags</a>.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ##   body: JObject (required)
  var body_617774 = newJObject()
  if body != nil:
    body_617774 = body
  result = call_617773.call(nil, nil, nil, nil, body_617774)

var tagResource* = Call_TagResource_617760(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "states.amazonaws.com", route: "/#X-Amz-Target=AWSStepFunctions.TagResource",
                                        validator: validate_TagResource_617761,
                                        base: "/", url: url_TagResource_617762,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_617775 = ref object of OpenApiRestCall_616866
proc url_UntagResource_617777(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_617776(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Remove a tag from a Step Functions resource
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
  var valid_617778 = header.getOrDefault("X-Amz-Date")
  valid_617778 = validateParameter(valid_617778, JString, required = false,
                                 default = nil)
  if valid_617778 != nil:
    section.add "X-Amz-Date", valid_617778
  var valid_617779 = header.getOrDefault("X-Amz-Security-Token")
  valid_617779 = validateParameter(valid_617779, JString, required = false,
                                 default = nil)
  if valid_617779 != nil:
    section.add "X-Amz-Security-Token", valid_617779
  var valid_617780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617780 = validateParameter(valid_617780, JString, required = false,
                                 default = nil)
  if valid_617780 != nil:
    section.add "X-Amz-Content-Sha256", valid_617780
  var valid_617781 = header.getOrDefault("X-Amz-Algorithm")
  valid_617781 = validateParameter(valid_617781, JString, required = false,
                                 default = nil)
  if valid_617781 != nil:
    section.add "X-Amz-Algorithm", valid_617781
  var valid_617782 = header.getOrDefault("X-Amz-Signature")
  valid_617782 = validateParameter(valid_617782, JString, required = false,
                                 default = nil)
  if valid_617782 != nil:
    section.add "X-Amz-Signature", valid_617782
  var valid_617783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617783 = validateParameter(valid_617783, JString, required = false,
                                 default = nil)
  if valid_617783 != nil:
    section.add "X-Amz-SignedHeaders", valid_617783
  var valid_617784 = header.getOrDefault("X-Amz-Target")
  valid_617784 = validateParameter(valid_617784, JString, required = true, default = newJString(
      "AWSStepFunctions.UntagResource"))
  if valid_617784 != nil:
    section.add "X-Amz-Target", valid_617784
  var valid_617785 = header.getOrDefault("X-Amz-Credential")
  valid_617785 = validateParameter(valid_617785, JString, required = false,
                                 default = nil)
  if valid_617785 != nil:
    section.add "X-Amz-Credential", valid_617785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617787: Call_UntagResource_617775; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove a tag from a Step Functions resource
  ## 
  let valid = call_617787.validator(path, query, header, formData, body, _)
  let scheme = call_617787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617787.url(scheme.get, call_617787.host, call_617787.base,
                         call_617787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617787, url, valid, _)

proc call*(call_617788: Call_UntagResource_617775; body: JsonNode): Recallable =
  ## untagResource
  ## Remove a tag from a Step Functions resource
  ##   body: JObject (required)
  var body_617789 = newJObject()
  if body != nil:
    body_617789 = body
  result = call_617788.call(nil, nil, nil, nil, body_617789)

var untagResource* = Call_UntagResource_617775(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.UntagResource",
    validator: validate_UntagResource_617776, base: "/", url: url_UntagResource_617777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStateMachine_617790 = ref object of OpenApiRestCall_616866
proc url_UpdateStateMachine_617792(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateStateMachine_617791(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## <p>Updates an existing state machine by modifying its <code>definition</code>, <code>roleArn</code>, or <code>loggingConfiguration</code>. Running executions will continue to use the previous <code>definition</code> and <code>roleArn</code>. You must include at least one of <code>definition</code> or <code>roleArn</code> or you will receive a <code>MissingRequiredParameter</code> error.</p> <note> <p>All <code>StartExecution</code> calls within a few seconds will use the updated <code>definition</code> and <code>roleArn</code>. Executions started immediately after calling <code>UpdateStateMachine</code> may use the previous state machine <code>definition</code> and <code>roleArn</code>. </p> </note>
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
  var valid_617793 = header.getOrDefault("X-Amz-Date")
  valid_617793 = validateParameter(valid_617793, JString, required = false,
                                 default = nil)
  if valid_617793 != nil:
    section.add "X-Amz-Date", valid_617793
  var valid_617794 = header.getOrDefault("X-Amz-Security-Token")
  valid_617794 = validateParameter(valid_617794, JString, required = false,
                                 default = nil)
  if valid_617794 != nil:
    section.add "X-Amz-Security-Token", valid_617794
  var valid_617795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617795 = validateParameter(valid_617795, JString, required = false,
                                 default = nil)
  if valid_617795 != nil:
    section.add "X-Amz-Content-Sha256", valid_617795
  var valid_617796 = header.getOrDefault("X-Amz-Algorithm")
  valid_617796 = validateParameter(valid_617796, JString, required = false,
                                 default = nil)
  if valid_617796 != nil:
    section.add "X-Amz-Algorithm", valid_617796
  var valid_617797 = header.getOrDefault("X-Amz-Signature")
  valid_617797 = validateParameter(valid_617797, JString, required = false,
                                 default = nil)
  if valid_617797 != nil:
    section.add "X-Amz-Signature", valid_617797
  var valid_617798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617798 = validateParameter(valid_617798, JString, required = false,
                                 default = nil)
  if valid_617798 != nil:
    section.add "X-Amz-SignedHeaders", valid_617798
  var valid_617799 = header.getOrDefault("X-Amz-Target")
  valid_617799 = validateParameter(valid_617799, JString, required = true, default = newJString(
      "AWSStepFunctions.UpdateStateMachine"))
  if valid_617799 != nil:
    section.add "X-Amz-Target", valid_617799
  var valid_617800 = header.getOrDefault("X-Amz-Credential")
  valid_617800 = validateParameter(valid_617800, JString, required = false,
                                 default = nil)
  if valid_617800 != nil:
    section.add "X-Amz-Credential", valid_617800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617802: Call_UpdateStateMachine_617790; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an existing state machine by modifying its <code>definition</code>, <code>roleArn</code>, or <code>loggingConfiguration</code>. Running executions will continue to use the previous <code>definition</code> and <code>roleArn</code>. You must include at least one of <code>definition</code> or <code>roleArn</code> or you will receive a <code>MissingRequiredParameter</code> error.</p> <note> <p>All <code>StartExecution</code> calls within a few seconds will use the updated <code>definition</code> and <code>roleArn</code>. Executions started immediately after calling <code>UpdateStateMachine</code> may use the previous state machine <code>definition</code> and <code>roleArn</code>. </p> </note>
  ## 
  let valid = call_617802.validator(path, query, header, formData, body, _)
  let scheme = call_617802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617802.url(scheme.get, call_617802.host, call_617802.base,
                         call_617802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617802, url, valid, _)

proc call*(call_617803: Call_UpdateStateMachine_617790; body: JsonNode): Recallable =
  ## updateStateMachine
  ## <p>Updates an existing state machine by modifying its <code>definition</code>, <code>roleArn</code>, or <code>loggingConfiguration</code>. Running executions will continue to use the previous <code>definition</code> and <code>roleArn</code>. You must include at least one of <code>definition</code> or <code>roleArn</code> or you will receive a <code>MissingRequiredParameter</code> error.</p> <note> <p>All <code>StartExecution</code> calls within a few seconds will use the updated <code>definition</code> and <code>roleArn</code>. Executions started immediately after calling <code>UpdateStateMachine</code> may use the previous state machine <code>definition</code> and <code>roleArn</code>. </p> </note>
  ##   body: JObject (required)
  var body_617804 = newJObject()
  if body != nil:
    body_617804 = body
  result = call_617803.call(nil, nil, nil, nil, body_617804)

var updateStateMachine* = Call_UpdateStateMachine_617790(
    name: "updateStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.UpdateStateMachine",
    validator: validate_UpdateStateMachine_617791, base: "/",
    url: url_UpdateStateMachine_617792, schemes: {Scheme.Https, Scheme.Http})
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
