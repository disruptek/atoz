
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "states.ap-northeast-1.amazonaws.com", "ap-southeast-1": "states.ap-southeast-1.amazonaws.com",
                           "us-west-2": "states.us-west-2.amazonaws.com",
                           "eu-west-2": "states.eu-west-2.amazonaws.com", "ap-northeast-3": "states.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "states.eu-central-1.amazonaws.com",
                           "us-east-2": "states.us-east-2.amazonaws.com",
                           "us-east-1": "states.us-east-1.amazonaws.com", "cn-northwest-1": "states.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "states.ap-south-1.amazonaws.com",
                           "eu-north-1": "states.eu-north-1.amazonaws.com", "ap-northeast-2": "states.ap-northeast-2.amazonaws.com",
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
      "ap-south-1": "states.ap-south-1.amazonaws.com",
      "eu-north-1": "states.eu-north-1.amazonaws.com",
      "ap-northeast-2": "states.ap-northeast-2.amazonaws.com",
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateActivity_601727 = ref object of OpenApiRestCall_601389
proc url_CreateActivity_601729(protocol: Scheme; host: string; base: string;
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

proc validate_CreateActivity_601728(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates an activity. An activity is a task that you write in any programming language and host on any machine that has access to AWS Step Functions. Activities must poll Step Functions using the <code>GetActivityTask</code> API action and respond using <code>SendTask*</code> API actions. This function lets Step Functions know the existence of your activity and returns an identifier for use in a state machine and when polling from the activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateActivity</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateActivity</code>'s idempotency check is based on the activity <code>name</code>. If a following request has different <code>tags</code> values, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>tags</code> will not be updated, even if they are different.</p> </note>
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
      "AWSStepFunctions.CreateActivity"))
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

proc call*(call_601885: Call_CreateActivity_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an activity. An activity is a task that you write in any programming language and host on any machine that has access to AWS Step Functions. Activities must poll Step Functions using the <code>GetActivityTask</code> API action and respond using <code>SendTask*</code> API actions. This function lets Step Functions know the existence of your activity and returns an identifier for use in a state machine and when polling from the activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateActivity</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateActivity</code>'s idempotency check is based on the activity <code>name</code>. If a following request has different <code>tags</code> values, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>tags</code> will not be updated, even if they are different.</p> </note>
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_CreateActivity_601727; body: JsonNode): Recallable =
  ## createActivity
  ## <p>Creates an activity. An activity is a task that you write in any programming language and host on any machine that has access to AWS Step Functions. Activities must poll Step Functions using the <code>GetActivityTask</code> API action and respond using <code>SendTask*</code> API actions. This function lets Step Functions know the existence of your activity and returns an identifier for use in a state machine and when polling from the activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateActivity</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateActivity</code>'s idempotency check is based on the activity <code>name</code>. If a following request has different <code>tags</code> values, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>tags</code> will not be updated, even if they are different.</p> </note>
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var createActivity* = Call_CreateActivity_601727(name: "createActivity",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.CreateActivity",
    validator: validate_CreateActivity_601728, base: "/", url: url_CreateActivity_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStateMachine_601996 = ref object of OpenApiRestCall_601389
proc url_CreateStateMachine_601998(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStateMachine_601997(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates a state machine. A state machine consists of a collection of states that can do work (<code>Task</code> states), determine to which states to transition next (<code>Choice</code> states), stop an execution with an error (<code>Fail</code> states), and so on. State machines are specified using a JSON-based, structured language.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateStateMachine</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateStateMachine</code>'s idempotency check is based on the state machine <code>name</code> and <code>definition</code>. If a following request has a different <code>roleArn</code> or <code>tags</code>, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>roleArn</code> and <code>tags</code> will not be updated, even if they are different.</p> </note>
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
      "AWSStepFunctions.CreateStateMachine"))
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

proc call*(call_602008: Call_CreateStateMachine_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a state machine. A state machine consists of a collection of states that can do work (<code>Task</code> states), determine to which states to transition next (<code>Choice</code> states), stop an execution with an error (<code>Fail</code> states), and so on. State machines are specified using a JSON-based, structured language.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateStateMachine</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateStateMachine</code>'s idempotency check is based on the state machine <code>name</code> and <code>definition</code>. If a following request has a different <code>roleArn</code> or <code>tags</code>, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>roleArn</code> and <code>tags</code> will not be updated, even if they are different.</p> </note>
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_CreateStateMachine_601996; body: JsonNode): Recallable =
  ## createStateMachine
  ## <p>Creates a state machine. A state machine consists of a collection of states that can do work (<code>Task</code> states), determine to which states to transition next (<code>Choice</code> states), stop an execution with an error (<code>Fail</code> states), and so on. State machines are specified using a JSON-based, structured language.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateStateMachine</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateStateMachine</code>'s idempotency check is based on the state machine <code>name</code> and <code>definition</code>. If a following request has a different <code>roleArn</code> or <code>tags</code>, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>roleArn</code> and <code>tags</code> will not be updated, even if they are different.</p> </note>
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var createStateMachine* = Call_CreateStateMachine_601996(
    name: "createStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.CreateStateMachine",
    validator: validate_CreateStateMachine_601997, base: "/",
    url: url_CreateStateMachine_601998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivity_602011 = ref object of OpenApiRestCall_601389
proc url_DeleteActivity_602013(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteActivity_602012(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes an activity.
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
      "AWSStepFunctions.DeleteActivity"))
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

proc call*(call_602023: Call_DeleteActivity_602011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an activity.
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_DeleteActivity_602011; body: JsonNode): Recallable =
  ## deleteActivity
  ## Deletes an activity.
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var deleteActivity* = Call_DeleteActivity_602011(name: "deleteActivity",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DeleteActivity",
    validator: validate_DeleteActivity_602012, base: "/", url: url_DeleteActivity_602013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStateMachine_602026 = ref object of OpenApiRestCall_601389
proc url_DeleteStateMachine_602028(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStateMachine_602027(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes a state machine. This is an asynchronous operation: It sets the state machine's status to <code>DELETING</code> and begins the deletion process. Each state machine execution is deleted the next time it makes a state transition.</p> <note> <p>The state machine itself is deleted after all executions are completed or deleted.</p> </note>
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
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "AWSStepFunctions.DeleteStateMachine"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_DeleteStateMachine_602026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a state machine. This is an asynchronous operation: It sets the state machine's status to <code>DELETING</code> and begins the deletion process. Each state machine execution is deleted the next time it makes a state transition.</p> <note> <p>The state machine itself is deleted after all executions are completed or deleted.</p> </note>
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_DeleteStateMachine_602026; body: JsonNode): Recallable =
  ## deleteStateMachine
  ## <p>Deletes a state machine. This is an asynchronous operation: It sets the state machine's status to <code>DELETING</code> and begins the deletion process. Each state machine execution is deleted the next time it makes a state transition.</p> <note> <p>The state machine itself is deleted after all executions are completed or deleted.</p> </note>
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var deleteStateMachine* = Call_DeleteStateMachine_602026(
    name: "deleteStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DeleteStateMachine",
    validator: validate_DeleteStateMachine_602027, base: "/",
    url: url_DeleteStateMachine_602028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivity_602041 = ref object of OpenApiRestCall_601389
proc url_DescribeActivity_602043(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeActivity_602042(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Describes an activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
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
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "AWSStepFunctions.DescribeActivity"))
  if valid_602044 != nil:
    section.add "X-Amz-Target", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_DescribeActivity_602041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes an activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_DescribeActivity_602041; body: JsonNode): Recallable =
  ## describeActivity
  ## <p>Describes an activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var describeActivity* = Call_DescribeActivity_602041(name: "describeActivity",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeActivity",
    validator: validate_DescribeActivity_602042, base: "/",
    url: url_DescribeActivity_602043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExecution_602056 = ref object of OpenApiRestCall_601389
proc url_DescribeExecution_602058(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeExecution_602057(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Describes an execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
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
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "AWSStepFunctions.DescribeExecution"))
  if valid_602059 != nil:
    section.add "X-Amz-Target", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_DescribeExecution_602056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes an execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_DescribeExecution_602056; body: JsonNode): Recallable =
  ## describeExecution
  ## <p>Describes an execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var describeExecution* = Call_DescribeExecution_602056(name: "describeExecution",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeExecution",
    validator: validate_DescribeExecution_602057, base: "/",
    url: url_DescribeExecution_602058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStateMachine_602071 = ref object of OpenApiRestCall_601389
proc url_DescribeStateMachine_602073(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeStateMachine_602072(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes a state machine.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
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
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "AWSStepFunctions.DescribeStateMachine"))
  if valid_602074 != nil:
    section.add "X-Amz-Target", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_DescribeStateMachine_602071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a state machine.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_DescribeStateMachine_602071; body: JsonNode): Recallable =
  ## describeStateMachine
  ## <p>Describes a state machine.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var describeStateMachine* = Call_DescribeStateMachine_602071(
    name: "describeStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeStateMachine",
    validator: validate_DescribeStateMachine_602072, base: "/",
    url: url_DescribeStateMachine_602073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStateMachineForExecution_602086 = ref object of OpenApiRestCall_601389
proc url_DescribeStateMachineForExecution_602088(protocol: Scheme; host: string;
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

proc validate_DescribeStateMachineForExecution_602087(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the state machine associated with a specific execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
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
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "AWSStepFunctions.DescribeStateMachineForExecution"))
  if valid_602089 != nil:
    section.add "X-Amz-Target", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_DescribeStateMachineForExecution_602086;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the state machine associated with a specific execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_DescribeStateMachineForExecution_602086;
          body: JsonNode): Recallable =
  ## describeStateMachineForExecution
  ## <p>Describes the state machine associated with a specific execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var describeStateMachineForExecution* = Call_DescribeStateMachineForExecution_602086(
    name: "describeStateMachineForExecution", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeStateMachineForExecution",
    validator: validate_DescribeStateMachineForExecution_602087, base: "/",
    url: url_DescribeStateMachineForExecution_602088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetActivityTask_602101 = ref object of OpenApiRestCall_601389
proc url_GetActivityTask_602103(protocol: Scheme; host: string; base: string;
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

proc validate_GetActivityTask_602102(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Used by workers to retrieve a task (with the specified activity ARN) which has been scheduled for execution by a running state machine. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available (i.e. an execution of a task of this type is needed.) The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns a <code>taskToken</code> with a null string.</p> <important> <p>Workers should set their client side socket timeout to at least 65 seconds (5 seconds higher than the maximum time the service may hold the poll request).</p> <p>Polling with <code>GetActivityTask</code> can cause latency in some implementations. See <a href="https://docs.aws.amazon.com/step-functions/latest/dg/bp-activity-pollers.html">Avoid Latency When Polling for Activity Tasks</a> in the Step Functions Developer Guide.</p> </important>
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
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "AWSStepFunctions.GetActivityTask"))
  if valid_602104 != nil:
    section.add "X-Amz-Target", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-SignedHeaders", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602113: Call_GetActivityTask_602101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by workers to retrieve a task (with the specified activity ARN) which has been scheduled for execution by a running state machine. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available (i.e. an execution of a task of this type is needed.) The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns a <code>taskToken</code> with a null string.</p> <important> <p>Workers should set their client side socket timeout to at least 65 seconds (5 seconds higher than the maximum time the service may hold the poll request).</p> <p>Polling with <code>GetActivityTask</code> can cause latency in some implementations. See <a href="https://docs.aws.amazon.com/step-functions/latest/dg/bp-activity-pollers.html">Avoid Latency When Polling for Activity Tasks</a> in the Step Functions Developer Guide.</p> </important>
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_GetActivityTask_602101; body: JsonNode): Recallable =
  ## getActivityTask
  ## <p>Used by workers to retrieve a task (with the specified activity ARN) which has been scheduled for execution by a running state machine. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available (i.e. an execution of a task of this type is needed.) The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns a <code>taskToken</code> with a null string.</p> <important> <p>Workers should set their client side socket timeout to at least 65 seconds (5 seconds higher than the maximum time the service may hold the poll request).</p> <p>Polling with <code>GetActivityTask</code> can cause latency in some implementations. See <a href="https://docs.aws.amazon.com/step-functions/latest/dg/bp-activity-pollers.html">Avoid Latency When Polling for Activity Tasks</a> in the Step Functions Developer Guide.</p> </important>
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var getActivityTask* = Call_GetActivityTask_602101(name: "getActivityTask",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.GetActivityTask",
    validator: validate_GetActivityTask_602102, base: "/", url: url_GetActivityTask_602103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExecutionHistory_602116 = ref object of OpenApiRestCall_601389
proc url_GetExecutionHistory_602118(protocol: Scheme; host: string; base: string;
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

proc validate_GetExecutionHistory_602117(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns the history of the specified execution as a list of events. By default, the results are returned in ascending order of the <code>timeStamp</code> of the events. Use the <code>reverseOrder</code> parameter to get the latest events first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602119 = query.getOrDefault("nextToken")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "nextToken", valid_602119
  var valid_602120 = query.getOrDefault("maxResults")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "maxResults", valid_602120
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
  var valid_602121 = header.getOrDefault("X-Amz-Target")
  valid_602121 = validateParameter(valid_602121, JString, required = true, default = newJString(
      "AWSStepFunctions.GetExecutionHistory"))
  if valid_602121 != nil:
    section.add "X-Amz-Target", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Signature")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Signature", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Content-Sha256", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Date")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Date", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Credential")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Credential", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Security-Token")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Security-Token", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Algorithm")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Algorithm", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-SignedHeaders", valid_602128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602130: Call_GetExecutionHistory_602116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the history of the specified execution as a list of events. By default, the results are returned in ascending order of the <code>timeStamp</code> of the events. Use the <code>reverseOrder</code> parameter to get the latest events first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p>
  ## 
  let valid = call_602130.validator(path, query, header, formData, body)
  let scheme = call_602130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602130.url(scheme.get, call_602130.host, call_602130.base,
                         call_602130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602130, url, valid)

proc call*(call_602131: Call_GetExecutionHistory_602116; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getExecutionHistory
  ## <p>Returns the history of the specified execution as a list of events. By default, the results are returned in ascending order of the <code>timeStamp</code> of the events. Use the <code>reverseOrder</code> parameter to get the latest events first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602132 = newJObject()
  var body_602133 = newJObject()
  add(query_602132, "nextToken", newJString(nextToken))
  if body != nil:
    body_602133 = body
  add(query_602132, "maxResults", newJString(maxResults))
  result = call_602131.call(nil, query_602132, nil, nil, body_602133)

var getExecutionHistory* = Call_GetExecutionHistory_602116(
    name: "getExecutionHistory", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.GetExecutionHistory",
    validator: validate_GetExecutionHistory_602117, base: "/",
    url: url_GetExecutionHistory_602118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActivities_602135 = ref object of OpenApiRestCall_601389
proc url_ListActivities_602137(protocol: Scheme; host: string; base: string;
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

proc validate_ListActivities_602136(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Lists the existing activities.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602138 = query.getOrDefault("nextToken")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "nextToken", valid_602138
  var valid_602139 = query.getOrDefault("maxResults")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "maxResults", valid_602139
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
  var valid_602140 = header.getOrDefault("X-Amz-Target")
  valid_602140 = validateParameter(valid_602140, JString, required = true, default = newJString(
      "AWSStepFunctions.ListActivities"))
  if valid_602140 != nil:
    section.add "X-Amz-Target", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Signature")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Signature", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Content-Sha256", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Date")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Date", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Credential")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Credential", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Security-Token")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Security-Token", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Algorithm")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Algorithm", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-SignedHeaders", valid_602147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602149: Call_ListActivities_602135; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the existing activities.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_602149.validator(path, query, header, formData, body)
  let scheme = call_602149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602149.url(scheme.get, call_602149.host, call_602149.base,
                         call_602149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602149, url, valid)

proc call*(call_602150: Call_ListActivities_602135; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listActivities
  ## <p>Lists the existing activities.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602151 = newJObject()
  var body_602152 = newJObject()
  add(query_602151, "nextToken", newJString(nextToken))
  if body != nil:
    body_602152 = body
  add(query_602151, "maxResults", newJString(maxResults))
  result = call_602150.call(nil, query_602151, nil, nil, body_602152)

var listActivities* = Call_ListActivities_602135(name: "listActivities",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListActivities",
    validator: validate_ListActivities_602136, base: "/", url: url_ListActivities_602137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExecutions_602153 = ref object of OpenApiRestCall_601389
proc url_ListExecutions_602155(protocol: Scheme; host: string; base: string;
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

proc validate_ListExecutions_602154(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Lists the executions of a state machine that meet the filtering criteria. Results are sorted by time, with the most recent execution first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602156 = query.getOrDefault("nextToken")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "nextToken", valid_602156
  var valid_602157 = query.getOrDefault("maxResults")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "maxResults", valid_602157
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
  var valid_602158 = header.getOrDefault("X-Amz-Target")
  valid_602158 = validateParameter(valid_602158, JString, required = true, default = newJString(
      "AWSStepFunctions.ListExecutions"))
  if valid_602158 != nil:
    section.add "X-Amz-Target", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Signature")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Signature", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Content-Sha256", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Date")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Date", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Credential")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Credential", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Security-Token")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Security-Token", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Algorithm")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Algorithm", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-SignedHeaders", valid_602165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602167: Call_ListExecutions_602153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the executions of a state machine that meet the filtering criteria. Results are sorted by time, with the most recent execution first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_602167.validator(path, query, header, formData, body)
  let scheme = call_602167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602167.url(scheme.get, call_602167.host, call_602167.base,
                         call_602167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602167, url, valid)

proc call*(call_602168: Call_ListExecutions_602153; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listExecutions
  ## <p>Lists the executions of a state machine that meet the filtering criteria. Results are sorted by time, with the most recent execution first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602169 = newJObject()
  var body_602170 = newJObject()
  add(query_602169, "nextToken", newJString(nextToken))
  if body != nil:
    body_602170 = body
  add(query_602169, "maxResults", newJString(maxResults))
  result = call_602168.call(nil, query_602169, nil, nil, body_602170)

var listExecutions* = Call_ListExecutions_602153(name: "listExecutions",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListExecutions",
    validator: validate_ListExecutions_602154, base: "/", url: url_ListExecutions_602155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStateMachines_602171 = ref object of OpenApiRestCall_601389
proc url_ListStateMachines_602173(protocol: Scheme; host: string; base: string;
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

proc validate_ListStateMachines_602172(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Lists the existing state machines.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602174 = query.getOrDefault("nextToken")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "nextToken", valid_602174
  var valid_602175 = query.getOrDefault("maxResults")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "maxResults", valid_602175
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
  var valid_602176 = header.getOrDefault("X-Amz-Target")
  valid_602176 = validateParameter(valid_602176, JString, required = true, default = newJString(
      "AWSStepFunctions.ListStateMachines"))
  if valid_602176 != nil:
    section.add "X-Amz-Target", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Signature")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Signature", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Content-Sha256", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Date")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Date", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Credential")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Credential", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Security-Token")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Security-Token", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Algorithm")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Algorithm", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-SignedHeaders", valid_602183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602185: Call_ListStateMachines_602171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the existing state machines.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_602185.validator(path, query, header, formData, body)
  let scheme = call_602185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602185.url(scheme.get, call_602185.host, call_602185.base,
                         call_602185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602185, url, valid)

proc call*(call_602186: Call_ListStateMachines_602171; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listStateMachines
  ## <p>Lists the existing state machines.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602187 = newJObject()
  var body_602188 = newJObject()
  add(query_602187, "nextToken", newJString(nextToken))
  if body != nil:
    body_602188 = body
  add(query_602187, "maxResults", newJString(maxResults))
  result = call_602186.call(nil, query_602187, nil, nil, body_602188)

var listStateMachines* = Call_ListStateMachines_602171(name: "listStateMachines",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListStateMachines",
    validator: validate_ListStateMachines_602172, base: "/",
    url: url_ListStateMachines_602173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602189 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602191(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602190(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>List tags for a given resource.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
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
  var valid_602192 = header.getOrDefault("X-Amz-Target")
  valid_602192 = validateParameter(valid_602192, JString, required = true, default = newJString(
      "AWSStepFunctions.ListTagsForResource"))
  if valid_602192 != nil:
    section.add "X-Amz-Target", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Signature")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Signature", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Content-Sha256", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Date")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Date", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Credential")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Credential", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Security-Token")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Security-Token", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Algorithm")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Algorithm", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-SignedHeaders", valid_602199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602201: Call_ListTagsForResource_602189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List tags for a given resource.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ## 
  let valid = call_602201.validator(path, query, header, formData, body)
  let scheme = call_602201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602201.url(scheme.get, call_602201.host, call_602201.base,
                         call_602201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602201, url, valid)

proc call*(call_602202: Call_ListTagsForResource_602189; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>List tags for a given resource.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ##   body: JObject (required)
  var body_602203 = newJObject()
  if body != nil:
    body_602203 = body
  result = call_602202.call(nil, nil, nil, nil, body_602203)

var listTagsForResource* = Call_ListTagsForResource_602189(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListTagsForResource",
    validator: validate_ListTagsForResource_602190, base: "/",
    url: url_ListTagsForResource_602191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTaskFailure_602204 = ref object of OpenApiRestCall_601389
proc url_SendTaskFailure_602206(protocol: Scheme; host: string; base: string;
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

proc validate_SendTaskFailure_602205(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> failed.
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
  var valid_602207 = header.getOrDefault("X-Amz-Target")
  valid_602207 = validateParameter(valid_602207, JString, required = true, default = newJString(
      "AWSStepFunctions.SendTaskFailure"))
  if valid_602207 != nil:
    section.add "X-Amz-Target", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Signature")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Signature", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Content-Sha256", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Date")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Date", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Credential")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Credential", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Security-Token")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Security-Token", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Algorithm")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Algorithm", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-SignedHeaders", valid_602214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602216: Call_SendTaskFailure_602204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> failed.
  ## 
  let valid = call_602216.validator(path, query, header, formData, body)
  let scheme = call_602216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602216.url(scheme.get, call_602216.host, call_602216.base,
                         call_602216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602216, url, valid)

proc call*(call_602217: Call_SendTaskFailure_602204; body: JsonNode): Recallable =
  ## sendTaskFailure
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> failed.
  ##   body: JObject (required)
  var body_602218 = newJObject()
  if body != nil:
    body_602218 = body
  result = call_602217.call(nil, nil, nil, nil, body_602218)

var sendTaskFailure* = Call_SendTaskFailure_602204(name: "sendTaskFailure",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.SendTaskFailure",
    validator: validate_SendTaskFailure_602205, base: "/", url: url_SendTaskFailure_602206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTaskHeartbeat_602219 = ref object of OpenApiRestCall_601389
proc url_SendTaskHeartbeat_602221(protocol: Scheme; host: string; base: string;
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

proc validate_SendTaskHeartbeat_602220(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report to Step Functions that the task represented by the specified <code>taskToken</code> is still making progress. This action resets the <code>Heartbeat</code> clock. The <code>Heartbeat</code> threshold is specified in the state machine's Amazon States Language definition (<code>HeartbeatSeconds</code>). This action does not in itself create an event in the execution history. However, if the task times out, the execution history contains an <code>ActivityTimedOut</code> entry for activities, or a <code>TaskTimedOut</code> entry for for tasks using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-sync">job run</a> or <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern.</p> <note> <p>The <code>Timeout</code> of a task, defined in the state machine's Amazon States Language definition, is its maximum allowed duration, regardless of the number of <a>SendTaskHeartbeat</a> requests received. Use <code>HeartbeatSeconds</code> to configure the timeout interval for heartbeats.</p> </note>
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
  var valid_602222 = header.getOrDefault("X-Amz-Target")
  valid_602222 = validateParameter(valid_602222, JString, required = true, default = newJString(
      "AWSStepFunctions.SendTaskHeartbeat"))
  if valid_602222 != nil:
    section.add "X-Amz-Target", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Signature")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Signature", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Content-Sha256", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Date")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Date", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Credential")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Credential", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Security-Token")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Security-Token", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Algorithm")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Algorithm", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-SignedHeaders", valid_602229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602231: Call_SendTaskHeartbeat_602219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report to Step Functions that the task represented by the specified <code>taskToken</code> is still making progress. This action resets the <code>Heartbeat</code> clock. The <code>Heartbeat</code> threshold is specified in the state machine's Amazon States Language definition (<code>HeartbeatSeconds</code>). This action does not in itself create an event in the execution history. However, if the task times out, the execution history contains an <code>ActivityTimedOut</code> entry for activities, or a <code>TaskTimedOut</code> entry for for tasks using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-sync">job run</a> or <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern.</p> <note> <p>The <code>Timeout</code> of a task, defined in the state machine's Amazon States Language definition, is its maximum allowed duration, regardless of the number of <a>SendTaskHeartbeat</a> requests received. Use <code>HeartbeatSeconds</code> to configure the timeout interval for heartbeats.</p> </note>
  ## 
  let valid = call_602231.validator(path, query, header, formData, body)
  let scheme = call_602231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602231.url(scheme.get, call_602231.host, call_602231.base,
                         call_602231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602231, url, valid)

proc call*(call_602232: Call_SendTaskHeartbeat_602219; body: JsonNode): Recallable =
  ## sendTaskHeartbeat
  ## <p>Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report to Step Functions that the task represented by the specified <code>taskToken</code> is still making progress. This action resets the <code>Heartbeat</code> clock. The <code>Heartbeat</code> threshold is specified in the state machine's Amazon States Language definition (<code>HeartbeatSeconds</code>). This action does not in itself create an event in the execution history. However, if the task times out, the execution history contains an <code>ActivityTimedOut</code> entry for activities, or a <code>TaskTimedOut</code> entry for for tasks using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-sync">job run</a> or <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern.</p> <note> <p>The <code>Timeout</code> of a task, defined in the state machine's Amazon States Language definition, is its maximum allowed duration, regardless of the number of <a>SendTaskHeartbeat</a> requests received. Use <code>HeartbeatSeconds</code> to configure the timeout interval for heartbeats.</p> </note>
  ##   body: JObject (required)
  var body_602233 = newJObject()
  if body != nil:
    body_602233 = body
  result = call_602232.call(nil, nil, nil, nil, body_602233)

var sendTaskHeartbeat* = Call_SendTaskHeartbeat_602219(name: "sendTaskHeartbeat",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.SendTaskHeartbeat",
    validator: validate_SendTaskHeartbeat_602220, base: "/",
    url: url_SendTaskHeartbeat_602221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTaskSuccess_602234 = ref object of OpenApiRestCall_601389
proc url_SendTaskSuccess_602236(protocol: Scheme; host: string; base: string;
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

proc validate_SendTaskSuccess_602235(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> completed successfully.
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
  var valid_602237 = header.getOrDefault("X-Amz-Target")
  valid_602237 = validateParameter(valid_602237, JString, required = true, default = newJString(
      "AWSStepFunctions.SendTaskSuccess"))
  if valid_602237 != nil:
    section.add "X-Amz-Target", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Signature")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Signature", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Content-Sha256", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Date")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Date", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Credential")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Credential", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Security-Token")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Security-Token", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Algorithm")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Algorithm", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-SignedHeaders", valid_602244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602246: Call_SendTaskSuccess_602234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> completed successfully.
  ## 
  let valid = call_602246.validator(path, query, header, formData, body)
  let scheme = call_602246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602246.url(scheme.get, call_602246.host, call_602246.base,
                         call_602246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602246, url, valid)

proc call*(call_602247: Call_SendTaskSuccess_602234; body: JsonNode): Recallable =
  ## sendTaskSuccess
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> completed successfully.
  ##   body: JObject (required)
  var body_602248 = newJObject()
  if body != nil:
    body_602248 = body
  result = call_602247.call(nil, nil, nil, nil, body_602248)

var sendTaskSuccess* = Call_SendTaskSuccess_602234(name: "sendTaskSuccess",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.SendTaskSuccess",
    validator: validate_SendTaskSuccess_602235, base: "/", url: url_SendTaskSuccess_602236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExecution_602249 = ref object of OpenApiRestCall_601389
proc url_StartExecution_602251(protocol: Scheme; host: string; base: string;
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

proc validate_StartExecution_602250(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Starts a state machine execution.</p> <note> <p> <code>StartExecution</code> is idempotent. If <code>StartExecution</code> is called with the same name and input as a running execution, the call will succeed and return the same response as the original request. If the execution is closed or if the input is different, it will return a 400 <code>ExecutionAlreadyExists</code> error. Names can be reused after 90 days. </p> </note>
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
  var valid_602252 = header.getOrDefault("X-Amz-Target")
  valid_602252 = validateParameter(valid_602252, JString, required = true, default = newJString(
      "AWSStepFunctions.StartExecution"))
  if valid_602252 != nil:
    section.add "X-Amz-Target", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Signature")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Signature", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Content-Sha256", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Date")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Date", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Credential")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Credential", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Security-Token")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Security-Token", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Algorithm")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Algorithm", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-SignedHeaders", valid_602259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602261: Call_StartExecution_602249; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a state machine execution.</p> <note> <p> <code>StartExecution</code> is idempotent. If <code>StartExecution</code> is called with the same name and input as a running execution, the call will succeed and return the same response as the original request. If the execution is closed or if the input is different, it will return a 400 <code>ExecutionAlreadyExists</code> error. Names can be reused after 90 days. </p> </note>
  ## 
  let valid = call_602261.validator(path, query, header, formData, body)
  let scheme = call_602261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602261.url(scheme.get, call_602261.host, call_602261.base,
                         call_602261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602261, url, valid)

proc call*(call_602262: Call_StartExecution_602249; body: JsonNode): Recallable =
  ## startExecution
  ## <p>Starts a state machine execution.</p> <note> <p> <code>StartExecution</code> is idempotent. If <code>StartExecution</code> is called with the same name and input as a running execution, the call will succeed and return the same response as the original request. If the execution is closed or if the input is different, it will return a 400 <code>ExecutionAlreadyExists</code> error. Names can be reused after 90 days. </p> </note>
  ##   body: JObject (required)
  var body_602263 = newJObject()
  if body != nil:
    body_602263 = body
  result = call_602262.call(nil, nil, nil, nil, body_602263)

var startExecution* = Call_StartExecution_602249(name: "startExecution",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.StartExecution",
    validator: validate_StartExecution_602250, base: "/", url: url_StartExecution_602251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopExecution_602264 = ref object of OpenApiRestCall_601389
proc url_StopExecution_602266(protocol: Scheme; host: string; base: string;
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

proc validate_StopExecution_602265(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops an execution.
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
  var valid_602267 = header.getOrDefault("X-Amz-Target")
  valid_602267 = validateParameter(valid_602267, JString, required = true, default = newJString(
      "AWSStepFunctions.StopExecution"))
  if valid_602267 != nil:
    section.add "X-Amz-Target", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Signature")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Signature", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Content-Sha256", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Date")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Date", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Credential")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Credential", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Security-Token")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Security-Token", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Algorithm")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Algorithm", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-SignedHeaders", valid_602274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602276: Call_StopExecution_602264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops an execution.
  ## 
  let valid = call_602276.validator(path, query, header, formData, body)
  let scheme = call_602276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602276.url(scheme.get, call_602276.host, call_602276.base,
                         call_602276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602276, url, valid)

proc call*(call_602277: Call_StopExecution_602264; body: JsonNode): Recallable =
  ## stopExecution
  ## Stops an execution.
  ##   body: JObject (required)
  var body_602278 = newJObject()
  if body != nil:
    body_602278 = body
  result = call_602277.call(nil, nil, nil, nil, body_602278)

var stopExecution* = Call_StopExecution_602264(name: "stopExecution",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.StopExecution",
    validator: validate_StopExecution_602265, base: "/", url: url_StopExecution_602266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602279 = ref object of OpenApiRestCall_601389
proc url_TagResource_602281(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602280(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Add a tag to a Step Functions resource.</p> <p>An array of key-value pairs. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>, and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html">Controlling Access Using IAM Tags</a>.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
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
  var valid_602282 = header.getOrDefault("X-Amz-Target")
  valid_602282 = validateParameter(valid_602282, JString, required = true, default = newJString(
      "AWSStepFunctions.TagResource"))
  if valid_602282 != nil:
    section.add "X-Amz-Target", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Signature")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Signature", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Content-Sha256", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Date")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Date", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Credential")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Credential", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Security-Token")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Security-Token", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Algorithm")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Algorithm", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-SignedHeaders", valid_602289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602291: Call_TagResource_602279; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add a tag to a Step Functions resource.</p> <p>An array of key-value pairs. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>, and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html">Controlling Access Using IAM Tags</a>.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ## 
  let valid = call_602291.validator(path, query, header, formData, body)
  let scheme = call_602291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602291.url(scheme.get, call_602291.host, call_602291.base,
                         call_602291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602291, url, valid)

proc call*(call_602292: Call_TagResource_602279; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add a tag to a Step Functions resource.</p> <p>An array of key-value pairs. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>, and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html">Controlling Access Using IAM Tags</a>.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ##   body: JObject (required)
  var body_602293 = newJObject()
  if body != nil:
    body_602293 = body
  result = call_602292.call(nil, nil, nil, nil, body_602293)

var tagResource* = Call_TagResource_602279(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "states.amazonaws.com", route: "/#X-Amz-Target=AWSStepFunctions.TagResource",
                                        validator: validate_TagResource_602280,
                                        base: "/", url: url_TagResource_602281,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602294 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602296(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602295(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a tag from a Step Functions resource
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
  var valid_602297 = header.getOrDefault("X-Amz-Target")
  valid_602297 = validateParameter(valid_602297, JString, required = true, default = newJString(
      "AWSStepFunctions.UntagResource"))
  if valid_602297 != nil:
    section.add "X-Amz-Target", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Signature")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Signature", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Content-Sha256", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Date")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Date", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Credential")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Credential", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Security-Token")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Security-Token", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Algorithm")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Algorithm", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-SignedHeaders", valid_602304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602306: Call_UntagResource_602294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove a tag from a Step Functions resource
  ## 
  let valid = call_602306.validator(path, query, header, formData, body)
  let scheme = call_602306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602306.url(scheme.get, call_602306.host, call_602306.base,
                         call_602306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602306, url, valid)

proc call*(call_602307: Call_UntagResource_602294; body: JsonNode): Recallable =
  ## untagResource
  ## Remove a tag from a Step Functions resource
  ##   body: JObject (required)
  var body_602308 = newJObject()
  if body != nil:
    body_602308 = body
  result = call_602307.call(nil, nil, nil, nil, body_602308)

var untagResource* = Call_UntagResource_602294(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.UntagResource",
    validator: validate_UntagResource_602295, base: "/", url: url_UntagResource_602296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStateMachine_602309 = ref object of OpenApiRestCall_601389
proc url_UpdateStateMachine_602311(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStateMachine_602310(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Updates an existing state machine by modifying its <code>definition</code> and/or <code>roleArn</code>. Running executions will continue to use the previous <code>definition</code> and <code>roleArn</code>. You must include at least one of <code>definition</code> or <code>roleArn</code> or you will receive a <code>MissingRequiredParameter</code> error.</p> <note> <p>All <code>StartExecution</code> calls within a few seconds will use the updated <code>definition</code> and <code>roleArn</code>. Executions started immediately after calling <code>UpdateStateMachine</code> may use the previous state machine <code>definition</code> and <code>roleArn</code>. </p> </note>
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
  var valid_602312 = header.getOrDefault("X-Amz-Target")
  valid_602312 = validateParameter(valid_602312, JString, required = true, default = newJString(
      "AWSStepFunctions.UpdateStateMachine"))
  if valid_602312 != nil:
    section.add "X-Amz-Target", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Signature")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Signature", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Content-Sha256", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Date")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Date", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Credential")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Credential", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Security-Token")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Security-Token", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Algorithm")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Algorithm", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-SignedHeaders", valid_602319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602321: Call_UpdateStateMachine_602309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing state machine by modifying its <code>definition</code> and/or <code>roleArn</code>. Running executions will continue to use the previous <code>definition</code> and <code>roleArn</code>. You must include at least one of <code>definition</code> or <code>roleArn</code> or you will receive a <code>MissingRequiredParameter</code> error.</p> <note> <p>All <code>StartExecution</code> calls within a few seconds will use the updated <code>definition</code> and <code>roleArn</code>. Executions started immediately after calling <code>UpdateStateMachine</code> may use the previous state machine <code>definition</code> and <code>roleArn</code>. </p> </note>
  ## 
  let valid = call_602321.validator(path, query, header, formData, body)
  let scheme = call_602321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602321.url(scheme.get, call_602321.host, call_602321.base,
                         call_602321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602321, url, valid)

proc call*(call_602322: Call_UpdateStateMachine_602309; body: JsonNode): Recallable =
  ## updateStateMachine
  ## <p>Updates an existing state machine by modifying its <code>definition</code> and/or <code>roleArn</code>. Running executions will continue to use the previous <code>definition</code> and <code>roleArn</code>. You must include at least one of <code>definition</code> or <code>roleArn</code> or you will receive a <code>MissingRequiredParameter</code> error.</p> <note> <p>All <code>StartExecution</code> calls within a few seconds will use the updated <code>definition</code> and <code>roleArn</code>. Executions started immediately after calling <code>UpdateStateMachine</code> may use the previous state machine <code>definition</code> and <code>roleArn</code>. </p> </note>
  ##   body: JObject (required)
  var body_602323 = newJObject()
  if body != nil:
    body_602323 = body
  result = call_602322.call(nil, nil, nil, nil, body_602323)

var updateStateMachine* = Call_UpdateStateMachine_602309(
    name: "updateStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.UpdateStateMachine",
    validator: validate_UpdateStateMachine_602310, base: "/",
    url: url_UpdateStateMachine_602311, schemes: {Scheme.Https, Scheme.Http})
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
