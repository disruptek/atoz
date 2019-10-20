
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateActivity_592703 = ref object of OpenApiRestCall_592364
proc url_CreateActivity_592705(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateActivity_592704(path: JsonNode; query: JsonNode;
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
  var valid_592830 = header.getOrDefault("X-Amz-Target")
  valid_592830 = validateParameter(valid_592830, JString, required = true, default = newJString(
      "AWSStepFunctions.CreateActivity"))
  if valid_592830 != nil:
    section.add "X-Amz-Target", valid_592830
  var valid_592831 = header.getOrDefault("X-Amz-Signature")
  valid_592831 = validateParameter(valid_592831, JString, required = false,
                                 default = nil)
  if valid_592831 != nil:
    section.add "X-Amz-Signature", valid_592831
  var valid_592832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Content-Sha256", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Date")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Date", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Credential")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Credential", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Security-Token")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Security-Token", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Algorithm")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Algorithm", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-SignedHeaders", valid_592837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592861: Call_CreateActivity_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an activity. An activity is a task that you write in any programming language and host on any machine that has access to AWS Step Functions. Activities must poll Step Functions using the <code>GetActivityTask</code> API action and respond using <code>SendTask*</code> API actions. This function lets Step Functions know the existence of your activity and returns an identifier for use in a state machine and when polling from the activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateActivity</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateActivity</code>'s idempotency check is based on the activity <code>name</code>. If a following request has different <code>tags</code> values, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>tags</code> will not be updated, even if they are different.</p> </note>
  ## 
  let valid = call_592861.validator(path, query, header, formData, body)
  let scheme = call_592861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592861.url(scheme.get, call_592861.host, call_592861.base,
                         call_592861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592861, url, valid)

proc call*(call_592932: Call_CreateActivity_592703; body: JsonNode): Recallable =
  ## createActivity
  ## <p>Creates an activity. An activity is a task that you write in any programming language and host on any machine that has access to AWS Step Functions. Activities must poll Step Functions using the <code>GetActivityTask</code> API action and respond using <code>SendTask*</code> API actions. This function lets Step Functions know the existence of your activity and returns an identifier for use in a state machine and when polling from the activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateActivity</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateActivity</code>'s idempotency check is based on the activity <code>name</code>. If a following request has different <code>tags</code> values, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>tags</code> will not be updated, even if they are different.</p> </note>
  ##   body: JObject (required)
  var body_592933 = newJObject()
  if body != nil:
    body_592933 = body
  result = call_592932.call(nil, nil, nil, nil, body_592933)

var createActivity* = Call_CreateActivity_592703(name: "createActivity",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.CreateActivity",
    validator: validate_CreateActivity_592704, base: "/", url: url_CreateActivity_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStateMachine_592972 = ref object of OpenApiRestCall_592364
proc url_CreateStateMachine_592974(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateStateMachine_592973(path: JsonNode; query: JsonNode;
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
  var valid_592975 = header.getOrDefault("X-Amz-Target")
  valid_592975 = validateParameter(valid_592975, JString, required = true, default = newJString(
      "AWSStepFunctions.CreateStateMachine"))
  if valid_592975 != nil:
    section.add "X-Amz-Target", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Signature")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Signature", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Content-Sha256", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Date")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Date", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Credential")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Credential", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Security-Token")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Security-Token", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Algorithm")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Algorithm", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-SignedHeaders", valid_592982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592984: Call_CreateStateMachine_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a state machine. A state machine consists of a collection of states that can do work (<code>Task</code> states), determine to which states to transition next (<code>Choice</code> states), stop an execution with an error (<code>Fail</code> states), and so on. State machines are specified using a JSON-based, structured language.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateStateMachine</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateStateMachine</code>'s idempotency check is based on the state machine <code>name</code> and <code>definition</code>. If a following request has a different <code>roleArn</code> or <code>tags</code>, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>roleArn</code> and <code>tags</code> will not be updated, even if they are different.</p> </note>
  ## 
  let valid = call_592984.validator(path, query, header, formData, body)
  let scheme = call_592984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592984.url(scheme.get, call_592984.host, call_592984.base,
                         call_592984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592984, url, valid)

proc call*(call_592985: Call_CreateStateMachine_592972; body: JsonNode): Recallable =
  ## createStateMachine
  ## <p>Creates a state machine. A state machine consists of a collection of states that can do work (<code>Task</code> states), determine to which states to transition next (<code>Choice</code> states), stop an execution with an error (<code>Fail</code> states), and so on. State machines are specified using a JSON-based, structured language.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateStateMachine</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateStateMachine</code>'s idempotency check is based on the state machine <code>name</code> and <code>definition</code>. If a following request has a different <code>roleArn</code> or <code>tags</code>, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>roleArn</code> and <code>tags</code> will not be updated, even if they are different.</p> </note>
  ##   body: JObject (required)
  var body_592986 = newJObject()
  if body != nil:
    body_592986 = body
  result = call_592985.call(nil, nil, nil, nil, body_592986)

var createStateMachine* = Call_CreateStateMachine_592972(
    name: "createStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.CreateStateMachine",
    validator: validate_CreateStateMachine_592973, base: "/",
    url: url_CreateStateMachine_592974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivity_592987 = ref object of OpenApiRestCall_592364
proc url_DeleteActivity_592989(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteActivity_592988(path: JsonNode; query: JsonNode;
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
  var valid_592990 = header.getOrDefault("X-Amz-Target")
  valid_592990 = validateParameter(valid_592990, JString, required = true, default = newJString(
      "AWSStepFunctions.DeleteActivity"))
  if valid_592990 != nil:
    section.add "X-Amz-Target", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Signature")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Signature", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Content-Sha256", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Date")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Date", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Credential")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Credential", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Security-Token")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Security-Token", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Algorithm")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Algorithm", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-SignedHeaders", valid_592997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592999: Call_DeleteActivity_592987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an activity.
  ## 
  let valid = call_592999.validator(path, query, header, formData, body)
  let scheme = call_592999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592999.url(scheme.get, call_592999.host, call_592999.base,
                         call_592999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592999, url, valid)

proc call*(call_593000: Call_DeleteActivity_592987; body: JsonNode): Recallable =
  ## deleteActivity
  ## Deletes an activity.
  ##   body: JObject (required)
  var body_593001 = newJObject()
  if body != nil:
    body_593001 = body
  result = call_593000.call(nil, nil, nil, nil, body_593001)

var deleteActivity* = Call_DeleteActivity_592987(name: "deleteActivity",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DeleteActivity",
    validator: validate_DeleteActivity_592988, base: "/", url: url_DeleteActivity_592989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStateMachine_593002 = ref object of OpenApiRestCall_592364
proc url_DeleteStateMachine_593004(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteStateMachine_593003(path: JsonNode; query: JsonNode;
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
  var valid_593005 = header.getOrDefault("X-Amz-Target")
  valid_593005 = validateParameter(valid_593005, JString, required = true, default = newJString(
      "AWSStepFunctions.DeleteStateMachine"))
  if valid_593005 != nil:
    section.add "X-Amz-Target", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Signature")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Signature", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Content-Sha256", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Date")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Date", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Credential")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Credential", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Security-Token")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Security-Token", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Algorithm")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Algorithm", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-SignedHeaders", valid_593012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593014: Call_DeleteStateMachine_593002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a state machine. This is an asynchronous operation: It sets the state machine's status to <code>DELETING</code> and begins the deletion process. Each state machine execution is deleted the next time it makes a state transition.</p> <note> <p>The state machine itself is deleted after all executions are completed or deleted.</p> </note>
  ## 
  let valid = call_593014.validator(path, query, header, formData, body)
  let scheme = call_593014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593014.url(scheme.get, call_593014.host, call_593014.base,
                         call_593014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593014, url, valid)

proc call*(call_593015: Call_DeleteStateMachine_593002; body: JsonNode): Recallable =
  ## deleteStateMachine
  ## <p>Deletes a state machine. This is an asynchronous operation: It sets the state machine's status to <code>DELETING</code> and begins the deletion process. Each state machine execution is deleted the next time it makes a state transition.</p> <note> <p>The state machine itself is deleted after all executions are completed or deleted.</p> </note>
  ##   body: JObject (required)
  var body_593016 = newJObject()
  if body != nil:
    body_593016 = body
  result = call_593015.call(nil, nil, nil, nil, body_593016)

var deleteStateMachine* = Call_DeleteStateMachine_593002(
    name: "deleteStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DeleteStateMachine",
    validator: validate_DeleteStateMachine_593003, base: "/",
    url: url_DeleteStateMachine_593004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivity_593017 = ref object of OpenApiRestCall_592364
proc url_DescribeActivity_593019(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeActivity_593018(path: JsonNode; query: JsonNode;
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
  var valid_593020 = header.getOrDefault("X-Amz-Target")
  valid_593020 = validateParameter(valid_593020, JString, required = true, default = newJString(
      "AWSStepFunctions.DescribeActivity"))
  if valid_593020 != nil:
    section.add "X-Amz-Target", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Signature")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Signature", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Content-Sha256", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Date")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Date", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Credential")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Credential", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Security-Token")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Security-Token", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Algorithm")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Algorithm", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-SignedHeaders", valid_593027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593029: Call_DescribeActivity_593017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes an activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_593029.validator(path, query, header, formData, body)
  let scheme = call_593029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593029.url(scheme.get, call_593029.host, call_593029.base,
                         call_593029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593029, url, valid)

proc call*(call_593030: Call_DescribeActivity_593017; body: JsonNode): Recallable =
  ## describeActivity
  ## <p>Describes an activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_593031 = newJObject()
  if body != nil:
    body_593031 = body
  result = call_593030.call(nil, nil, nil, nil, body_593031)

var describeActivity* = Call_DescribeActivity_593017(name: "describeActivity",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeActivity",
    validator: validate_DescribeActivity_593018, base: "/",
    url: url_DescribeActivity_593019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExecution_593032 = ref object of OpenApiRestCall_592364
proc url_DescribeExecution_593034(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeExecution_593033(path: JsonNode; query: JsonNode;
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
  var valid_593035 = header.getOrDefault("X-Amz-Target")
  valid_593035 = validateParameter(valid_593035, JString, required = true, default = newJString(
      "AWSStepFunctions.DescribeExecution"))
  if valid_593035 != nil:
    section.add "X-Amz-Target", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Signature")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Signature", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Content-Sha256", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Date")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Date", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Credential")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Credential", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Security-Token")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Security-Token", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Algorithm")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Algorithm", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-SignedHeaders", valid_593042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593044: Call_DescribeExecution_593032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes an execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_593044.validator(path, query, header, formData, body)
  let scheme = call_593044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593044.url(scheme.get, call_593044.host, call_593044.base,
                         call_593044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593044, url, valid)

proc call*(call_593045: Call_DescribeExecution_593032; body: JsonNode): Recallable =
  ## describeExecution
  ## <p>Describes an execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_593046 = newJObject()
  if body != nil:
    body_593046 = body
  result = call_593045.call(nil, nil, nil, nil, body_593046)

var describeExecution* = Call_DescribeExecution_593032(name: "describeExecution",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeExecution",
    validator: validate_DescribeExecution_593033, base: "/",
    url: url_DescribeExecution_593034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStateMachine_593047 = ref object of OpenApiRestCall_592364
proc url_DescribeStateMachine_593049(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeStateMachine_593048(path: JsonNode; query: JsonNode;
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
  var valid_593050 = header.getOrDefault("X-Amz-Target")
  valid_593050 = validateParameter(valid_593050, JString, required = true, default = newJString(
      "AWSStepFunctions.DescribeStateMachine"))
  if valid_593050 != nil:
    section.add "X-Amz-Target", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Signature")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Signature", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Content-Sha256", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Date")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Date", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Credential")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Credential", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Security-Token")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Security-Token", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Algorithm")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Algorithm", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-SignedHeaders", valid_593057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593059: Call_DescribeStateMachine_593047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a state machine.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_593059.validator(path, query, header, formData, body)
  let scheme = call_593059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593059.url(scheme.get, call_593059.host, call_593059.base,
                         call_593059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593059, url, valid)

proc call*(call_593060: Call_DescribeStateMachine_593047; body: JsonNode): Recallable =
  ## describeStateMachine
  ## <p>Describes a state machine.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_593061 = newJObject()
  if body != nil:
    body_593061 = body
  result = call_593060.call(nil, nil, nil, nil, body_593061)

var describeStateMachine* = Call_DescribeStateMachine_593047(
    name: "describeStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeStateMachine",
    validator: validate_DescribeStateMachine_593048, base: "/",
    url: url_DescribeStateMachine_593049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStateMachineForExecution_593062 = ref object of OpenApiRestCall_592364
proc url_DescribeStateMachineForExecution_593064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeStateMachineForExecution_593063(path: JsonNode;
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
  var valid_593065 = header.getOrDefault("X-Amz-Target")
  valid_593065 = validateParameter(valid_593065, JString, required = true, default = newJString(
      "AWSStepFunctions.DescribeStateMachineForExecution"))
  if valid_593065 != nil:
    section.add "X-Amz-Target", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Signature")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Signature", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Content-Sha256", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Date")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Date", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Credential")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Credential", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Security-Token")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Security-Token", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Algorithm")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Algorithm", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-SignedHeaders", valid_593072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593074: Call_DescribeStateMachineForExecution_593062;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the state machine associated with a specific execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_593074.validator(path, query, header, formData, body)
  let scheme = call_593074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593074.url(scheme.get, call_593074.host, call_593074.base,
                         call_593074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593074, url, valid)

proc call*(call_593075: Call_DescribeStateMachineForExecution_593062;
          body: JsonNode): Recallable =
  ## describeStateMachineForExecution
  ## <p>Describes the state machine associated with a specific execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_593076 = newJObject()
  if body != nil:
    body_593076 = body
  result = call_593075.call(nil, nil, nil, nil, body_593076)

var describeStateMachineForExecution* = Call_DescribeStateMachineForExecution_593062(
    name: "describeStateMachineForExecution", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeStateMachineForExecution",
    validator: validate_DescribeStateMachineForExecution_593063, base: "/",
    url: url_DescribeStateMachineForExecution_593064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetActivityTask_593077 = ref object of OpenApiRestCall_592364
proc url_GetActivityTask_593079(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetActivityTask_593078(path: JsonNode; query: JsonNode;
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
  var valid_593080 = header.getOrDefault("X-Amz-Target")
  valid_593080 = validateParameter(valid_593080, JString, required = true, default = newJString(
      "AWSStepFunctions.GetActivityTask"))
  if valid_593080 != nil:
    section.add "X-Amz-Target", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Signature")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Signature", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Content-Sha256", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Date")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Date", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Credential")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Credential", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Security-Token")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Security-Token", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Algorithm")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Algorithm", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-SignedHeaders", valid_593087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593089: Call_GetActivityTask_593077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by workers to retrieve a task (with the specified activity ARN) which has been scheduled for execution by a running state machine. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available (i.e. an execution of a task of this type is needed.) The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns a <code>taskToken</code> with a null string.</p> <important> <p>Workers should set their client side socket timeout to at least 65 seconds (5 seconds higher than the maximum time the service may hold the poll request).</p> <p>Polling with <code>GetActivityTask</code> can cause latency in some implementations. See <a href="https://docs.aws.amazon.com/step-functions/latest/dg/bp-activity-pollers.html">Avoid Latency When Polling for Activity Tasks</a> in the Step Functions Developer Guide.</p> </important>
  ## 
  let valid = call_593089.validator(path, query, header, formData, body)
  let scheme = call_593089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593089.url(scheme.get, call_593089.host, call_593089.base,
                         call_593089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593089, url, valid)

proc call*(call_593090: Call_GetActivityTask_593077; body: JsonNode): Recallable =
  ## getActivityTask
  ## <p>Used by workers to retrieve a task (with the specified activity ARN) which has been scheduled for execution by a running state machine. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available (i.e. an execution of a task of this type is needed.) The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns a <code>taskToken</code> with a null string.</p> <important> <p>Workers should set their client side socket timeout to at least 65 seconds (5 seconds higher than the maximum time the service may hold the poll request).</p> <p>Polling with <code>GetActivityTask</code> can cause latency in some implementations. See <a href="https://docs.aws.amazon.com/step-functions/latest/dg/bp-activity-pollers.html">Avoid Latency When Polling for Activity Tasks</a> in the Step Functions Developer Guide.</p> </important>
  ##   body: JObject (required)
  var body_593091 = newJObject()
  if body != nil:
    body_593091 = body
  result = call_593090.call(nil, nil, nil, nil, body_593091)

var getActivityTask* = Call_GetActivityTask_593077(name: "getActivityTask",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.GetActivityTask",
    validator: validate_GetActivityTask_593078, base: "/", url: url_GetActivityTask_593079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExecutionHistory_593092 = ref object of OpenApiRestCall_592364
proc url_GetExecutionHistory_593094(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetExecutionHistory_593093(path: JsonNode; query: JsonNode;
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
  var valid_593095 = query.getOrDefault("nextToken")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "nextToken", valid_593095
  var valid_593096 = query.getOrDefault("maxResults")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "maxResults", valid_593096
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
  var valid_593097 = header.getOrDefault("X-Amz-Target")
  valid_593097 = validateParameter(valid_593097, JString, required = true, default = newJString(
      "AWSStepFunctions.GetExecutionHistory"))
  if valid_593097 != nil:
    section.add "X-Amz-Target", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Signature")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Signature", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Content-Sha256", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Date")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Date", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Credential")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Credential", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Security-Token")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Security-Token", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Algorithm")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Algorithm", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-SignedHeaders", valid_593104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593106: Call_GetExecutionHistory_593092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the history of the specified execution as a list of events. By default, the results are returned in ascending order of the <code>timeStamp</code> of the events. Use the <code>reverseOrder</code> parameter to get the latest events first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p>
  ## 
  let valid = call_593106.validator(path, query, header, formData, body)
  let scheme = call_593106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593106.url(scheme.get, call_593106.host, call_593106.base,
                         call_593106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593106, url, valid)

proc call*(call_593107: Call_GetExecutionHistory_593092; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getExecutionHistory
  ## <p>Returns the history of the specified execution as a list of events. By default, the results are returned in ascending order of the <code>timeStamp</code> of the events. Use the <code>reverseOrder</code> parameter to get the latest events first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593108 = newJObject()
  var body_593109 = newJObject()
  add(query_593108, "nextToken", newJString(nextToken))
  if body != nil:
    body_593109 = body
  add(query_593108, "maxResults", newJString(maxResults))
  result = call_593107.call(nil, query_593108, nil, nil, body_593109)

var getExecutionHistory* = Call_GetExecutionHistory_593092(
    name: "getExecutionHistory", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.GetExecutionHistory",
    validator: validate_GetExecutionHistory_593093, base: "/",
    url: url_GetExecutionHistory_593094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActivities_593111 = ref object of OpenApiRestCall_592364
proc url_ListActivities_593113(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListActivities_593112(path: JsonNode; query: JsonNode;
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
  var valid_593114 = query.getOrDefault("nextToken")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "nextToken", valid_593114
  var valid_593115 = query.getOrDefault("maxResults")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "maxResults", valid_593115
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
  var valid_593116 = header.getOrDefault("X-Amz-Target")
  valid_593116 = validateParameter(valid_593116, JString, required = true, default = newJString(
      "AWSStepFunctions.ListActivities"))
  if valid_593116 != nil:
    section.add "X-Amz-Target", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Signature")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Signature", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Content-Sha256", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Date")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Date", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Credential")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Credential", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Security-Token")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Security-Token", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Algorithm")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Algorithm", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-SignedHeaders", valid_593123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593125: Call_ListActivities_593111; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the existing activities.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_593125.validator(path, query, header, formData, body)
  let scheme = call_593125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593125.url(scheme.get, call_593125.host, call_593125.base,
                         call_593125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593125, url, valid)

proc call*(call_593126: Call_ListActivities_593111; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listActivities
  ## <p>Lists the existing activities.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593127 = newJObject()
  var body_593128 = newJObject()
  add(query_593127, "nextToken", newJString(nextToken))
  if body != nil:
    body_593128 = body
  add(query_593127, "maxResults", newJString(maxResults))
  result = call_593126.call(nil, query_593127, nil, nil, body_593128)

var listActivities* = Call_ListActivities_593111(name: "listActivities",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListActivities",
    validator: validate_ListActivities_593112, base: "/", url: url_ListActivities_593113,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExecutions_593129 = ref object of OpenApiRestCall_592364
proc url_ListExecutions_593131(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListExecutions_593130(path: JsonNode; query: JsonNode;
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
  var valid_593132 = query.getOrDefault("nextToken")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "nextToken", valid_593132
  var valid_593133 = query.getOrDefault("maxResults")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "maxResults", valid_593133
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
  var valid_593134 = header.getOrDefault("X-Amz-Target")
  valid_593134 = validateParameter(valid_593134, JString, required = true, default = newJString(
      "AWSStepFunctions.ListExecutions"))
  if valid_593134 != nil:
    section.add "X-Amz-Target", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Signature")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Signature", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Content-Sha256", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Date")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Date", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Credential")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Credential", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Security-Token")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Security-Token", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Algorithm")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Algorithm", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-SignedHeaders", valid_593141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593143: Call_ListExecutions_593129; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the executions of a state machine that meet the filtering criteria. Results are sorted by time, with the most recent execution first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_593143.validator(path, query, header, formData, body)
  let scheme = call_593143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593143.url(scheme.get, call_593143.host, call_593143.base,
                         call_593143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593143, url, valid)

proc call*(call_593144: Call_ListExecutions_593129; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listExecutions
  ## <p>Lists the executions of a state machine that meet the filtering criteria. Results are sorted by time, with the most recent execution first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593145 = newJObject()
  var body_593146 = newJObject()
  add(query_593145, "nextToken", newJString(nextToken))
  if body != nil:
    body_593146 = body
  add(query_593145, "maxResults", newJString(maxResults))
  result = call_593144.call(nil, query_593145, nil, nil, body_593146)

var listExecutions* = Call_ListExecutions_593129(name: "listExecutions",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListExecutions",
    validator: validate_ListExecutions_593130, base: "/", url: url_ListExecutions_593131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStateMachines_593147 = ref object of OpenApiRestCall_592364
proc url_ListStateMachines_593149(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListStateMachines_593148(path: JsonNode; query: JsonNode;
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
  var valid_593150 = query.getOrDefault("nextToken")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "nextToken", valid_593150
  var valid_593151 = query.getOrDefault("maxResults")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "maxResults", valid_593151
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
  var valid_593152 = header.getOrDefault("X-Amz-Target")
  valid_593152 = validateParameter(valid_593152, JString, required = true, default = newJString(
      "AWSStepFunctions.ListStateMachines"))
  if valid_593152 != nil:
    section.add "X-Amz-Target", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Signature")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Signature", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-Content-Sha256", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Date")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Date", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Credential")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Credential", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Security-Token")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Security-Token", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Algorithm")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Algorithm", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-SignedHeaders", valid_593159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593161: Call_ListStateMachines_593147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the existing state machines.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_593161.validator(path, query, header, formData, body)
  let scheme = call_593161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593161.url(scheme.get, call_593161.host, call_593161.base,
                         call_593161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593161, url, valid)

proc call*(call_593162: Call_ListStateMachines_593147; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listStateMachines
  ## <p>Lists the existing state machines.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593163 = newJObject()
  var body_593164 = newJObject()
  add(query_593163, "nextToken", newJString(nextToken))
  if body != nil:
    body_593164 = body
  add(query_593163, "maxResults", newJString(maxResults))
  result = call_593162.call(nil, query_593163, nil, nil, body_593164)

var listStateMachines* = Call_ListStateMachines_593147(name: "listStateMachines",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListStateMachines",
    validator: validate_ListStateMachines_593148, base: "/",
    url: url_ListStateMachines_593149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593165 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593167(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_593166(path: JsonNode; query: JsonNode;
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
  var valid_593168 = header.getOrDefault("X-Amz-Target")
  valid_593168 = validateParameter(valid_593168, JString, required = true, default = newJString(
      "AWSStepFunctions.ListTagsForResource"))
  if valid_593168 != nil:
    section.add "X-Amz-Target", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Signature")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Signature", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Content-Sha256", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Date")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Date", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Credential")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Credential", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Security-Token")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Security-Token", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Algorithm")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Algorithm", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-SignedHeaders", valid_593175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593177: Call_ListTagsForResource_593165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List tags for a given resource.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ## 
  let valid = call_593177.validator(path, query, header, formData, body)
  let scheme = call_593177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593177.url(scheme.get, call_593177.host, call_593177.base,
                         call_593177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593177, url, valid)

proc call*(call_593178: Call_ListTagsForResource_593165; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>List tags for a given resource.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ##   body: JObject (required)
  var body_593179 = newJObject()
  if body != nil:
    body_593179 = body
  result = call_593178.call(nil, nil, nil, nil, body_593179)

var listTagsForResource* = Call_ListTagsForResource_593165(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListTagsForResource",
    validator: validate_ListTagsForResource_593166, base: "/",
    url: url_ListTagsForResource_593167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTaskFailure_593180 = ref object of OpenApiRestCall_592364
proc url_SendTaskFailure_593182(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendTaskFailure_593181(path: JsonNode; query: JsonNode;
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
  var valid_593183 = header.getOrDefault("X-Amz-Target")
  valid_593183 = validateParameter(valid_593183, JString, required = true, default = newJString(
      "AWSStepFunctions.SendTaskFailure"))
  if valid_593183 != nil:
    section.add "X-Amz-Target", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Signature")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Signature", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Content-Sha256", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Date")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Date", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Credential")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Credential", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Security-Token")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Security-Token", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Algorithm")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Algorithm", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-SignedHeaders", valid_593190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593192: Call_SendTaskFailure_593180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> failed.
  ## 
  let valid = call_593192.validator(path, query, header, formData, body)
  let scheme = call_593192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593192.url(scheme.get, call_593192.host, call_593192.base,
                         call_593192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593192, url, valid)

proc call*(call_593193: Call_SendTaskFailure_593180; body: JsonNode): Recallable =
  ## sendTaskFailure
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> failed.
  ##   body: JObject (required)
  var body_593194 = newJObject()
  if body != nil:
    body_593194 = body
  result = call_593193.call(nil, nil, nil, nil, body_593194)

var sendTaskFailure* = Call_SendTaskFailure_593180(name: "sendTaskFailure",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.SendTaskFailure",
    validator: validate_SendTaskFailure_593181, base: "/", url: url_SendTaskFailure_593182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTaskHeartbeat_593195 = ref object of OpenApiRestCall_592364
proc url_SendTaskHeartbeat_593197(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendTaskHeartbeat_593196(path: JsonNode; query: JsonNode;
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
  var valid_593198 = header.getOrDefault("X-Amz-Target")
  valid_593198 = validateParameter(valid_593198, JString, required = true, default = newJString(
      "AWSStepFunctions.SendTaskHeartbeat"))
  if valid_593198 != nil:
    section.add "X-Amz-Target", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Signature")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Signature", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Content-Sha256", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Date")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Date", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Credential")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Credential", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Security-Token")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Security-Token", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Algorithm")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Algorithm", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-SignedHeaders", valid_593205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593207: Call_SendTaskHeartbeat_593195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report to Step Functions that the task represented by the specified <code>taskToken</code> is still making progress. This action resets the <code>Heartbeat</code> clock. The <code>Heartbeat</code> threshold is specified in the state machine's Amazon States Language definition (<code>HeartbeatSeconds</code>). This action does not in itself create an event in the execution history. However, if the task times out, the execution history contains an <code>ActivityTimedOut</code> entry for activities, or a <code>TaskTimedOut</code> entry for for tasks using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-sync">job run</a> or <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern.</p> <note> <p>The <code>Timeout</code> of a task, defined in the state machine's Amazon States Language definition, is its maximum allowed duration, regardless of the number of <a>SendTaskHeartbeat</a> requests received. Use <code>HeartbeatSeconds</code> to configure the timeout interval for heartbeats.</p> </note>
  ## 
  let valid = call_593207.validator(path, query, header, formData, body)
  let scheme = call_593207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593207.url(scheme.get, call_593207.host, call_593207.base,
                         call_593207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593207, url, valid)

proc call*(call_593208: Call_SendTaskHeartbeat_593195; body: JsonNode): Recallable =
  ## sendTaskHeartbeat
  ## <p>Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report to Step Functions that the task represented by the specified <code>taskToken</code> is still making progress. This action resets the <code>Heartbeat</code> clock. The <code>Heartbeat</code> threshold is specified in the state machine's Amazon States Language definition (<code>HeartbeatSeconds</code>). This action does not in itself create an event in the execution history. However, if the task times out, the execution history contains an <code>ActivityTimedOut</code> entry for activities, or a <code>TaskTimedOut</code> entry for for tasks using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-sync">job run</a> or <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern.</p> <note> <p>The <code>Timeout</code> of a task, defined in the state machine's Amazon States Language definition, is its maximum allowed duration, regardless of the number of <a>SendTaskHeartbeat</a> requests received. Use <code>HeartbeatSeconds</code> to configure the timeout interval for heartbeats.</p> </note>
  ##   body: JObject (required)
  var body_593209 = newJObject()
  if body != nil:
    body_593209 = body
  result = call_593208.call(nil, nil, nil, nil, body_593209)

var sendTaskHeartbeat* = Call_SendTaskHeartbeat_593195(name: "sendTaskHeartbeat",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.SendTaskHeartbeat",
    validator: validate_SendTaskHeartbeat_593196, base: "/",
    url: url_SendTaskHeartbeat_593197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTaskSuccess_593210 = ref object of OpenApiRestCall_592364
proc url_SendTaskSuccess_593212(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendTaskSuccess_593211(path: JsonNode; query: JsonNode;
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
  var valid_593213 = header.getOrDefault("X-Amz-Target")
  valid_593213 = validateParameter(valid_593213, JString, required = true, default = newJString(
      "AWSStepFunctions.SendTaskSuccess"))
  if valid_593213 != nil:
    section.add "X-Amz-Target", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-Signature")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-Signature", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Content-Sha256", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Date")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Date", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Credential")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Credential", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Security-Token")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Security-Token", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Algorithm")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Algorithm", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-SignedHeaders", valid_593220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593222: Call_SendTaskSuccess_593210; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> completed successfully.
  ## 
  let valid = call_593222.validator(path, query, header, formData, body)
  let scheme = call_593222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593222.url(scheme.get, call_593222.host, call_593222.base,
                         call_593222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593222, url, valid)

proc call*(call_593223: Call_SendTaskSuccess_593210; body: JsonNode): Recallable =
  ## sendTaskSuccess
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> completed successfully.
  ##   body: JObject (required)
  var body_593224 = newJObject()
  if body != nil:
    body_593224 = body
  result = call_593223.call(nil, nil, nil, nil, body_593224)

var sendTaskSuccess* = Call_SendTaskSuccess_593210(name: "sendTaskSuccess",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.SendTaskSuccess",
    validator: validate_SendTaskSuccess_593211, base: "/", url: url_SendTaskSuccess_593212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExecution_593225 = ref object of OpenApiRestCall_592364
proc url_StartExecution_593227(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartExecution_593226(path: JsonNode; query: JsonNode;
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
  var valid_593228 = header.getOrDefault("X-Amz-Target")
  valid_593228 = validateParameter(valid_593228, JString, required = true, default = newJString(
      "AWSStepFunctions.StartExecution"))
  if valid_593228 != nil:
    section.add "X-Amz-Target", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Signature")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Signature", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Content-Sha256", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Date")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Date", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Credential")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Credential", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Security-Token")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Security-Token", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Algorithm")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Algorithm", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-SignedHeaders", valid_593235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593237: Call_StartExecution_593225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a state machine execution.</p> <note> <p> <code>StartExecution</code> is idempotent. If <code>StartExecution</code> is called with the same name and input as a running execution, the call will succeed and return the same response as the original request. If the execution is closed or if the input is different, it will return a 400 <code>ExecutionAlreadyExists</code> error. Names can be reused after 90 days. </p> </note>
  ## 
  let valid = call_593237.validator(path, query, header, formData, body)
  let scheme = call_593237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593237.url(scheme.get, call_593237.host, call_593237.base,
                         call_593237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593237, url, valid)

proc call*(call_593238: Call_StartExecution_593225; body: JsonNode): Recallable =
  ## startExecution
  ## <p>Starts a state machine execution.</p> <note> <p> <code>StartExecution</code> is idempotent. If <code>StartExecution</code> is called with the same name and input as a running execution, the call will succeed and return the same response as the original request. If the execution is closed or if the input is different, it will return a 400 <code>ExecutionAlreadyExists</code> error. Names can be reused after 90 days. </p> </note>
  ##   body: JObject (required)
  var body_593239 = newJObject()
  if body != nil:
    body_593239 = body
  result = call_593238.call(nil, nil, nil, nil, body_593239)

var startExecution* = Call_StartExecution_593225(name: "startExecution",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.StartExecution",
    validator: validate_StartExecution_593226, base: "/", url: url_StartExecution_593227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopExecution_593240 = ref object of OpenApiRestCall_592364
proc url_StopExecution_593242(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopExecution_593241(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593243 = header.getOrDefault("X-Amz-Target")
  valid_593243 = validateParameter(valid_593243, JString, required = true, default = newJString(
      "AWSStepFunctions.StopExecution"))
  if valid_593243 != nil:
    section.add "X-Amz-Target", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Signature")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Signature", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Content-Sha256", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Date")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Date", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Credential")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Credential", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Security-Token")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Security-Token", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Algorithm")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Algorithm", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-SignedHeaders", valid_593250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593252: Call_StopExecution_593240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops an execution.
  ## 
  let valid = call_593252.validator(path, query, header, formData, body)
  let scheme = call_593252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593252.url(scheme.get, call_593252.host, call_593252.base,
                         call_593252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593252, url, valid)

proc call*(call_593253: Call_StopExecution_593240; body: JsonNode): Recallable =
  ## stopExecution
  ## Stops an execution.
  ##   body: JObject (required)
  var body_593254 = newJObject()
  if body != nil:
    body_593254 = body
  result = call_593253.call(nil, nil, nil, nil, body_593254)

var stopExecution* = Call_StopExecution_593240(name: "stopExecution",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.StopExecution",
    validator: validate_StopExecution_593241, base: "/", url: url_StopExecution_593242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593255 = ref object of OpenApiRestCall_592364
proc url_TagResource_593257(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593256(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593258 = header.getOrDefault("X-Amz-Target")
  valid_593258 = validateParameter(valid_593258, JString, required = true, default = newJString(
      "AWSStepFunctions.TagResource"))
  if valid_593258 != nil:
    section.add "X-Amz-Target", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Signature")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Signature", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Content-Sha256", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Date")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Date", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Credential")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Credential", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Security-Token")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Security-Token", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Algorithm")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Algorithm", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-SignedHeaders", valid_593265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593267: Call_TagResource_593255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add a tag to a Step Functions resource.</p> <p>An array of key-value pairs. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>, and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html">Controlling Access Using IAM Tags</a>.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ## 
  let valid = call_593267.validator(path, query, header, formData, body)
  let scheme = call_593267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593267.url(scheme.get, call_593267.host, call_593267.base,
                         call_593267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593267, url, valid)

proc call*(call_593268: Call_TagResource_593255; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add a tag to a Step Functions resource.</p> <p>An array of key-value pairs. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>, and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html">Controlling Access Using IAM Tags</a>.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ##   body: JObject (required)
  var body_593269 = newJObject()
  if body != nil:
    body_593269 = body
  result = call_593268.call(nil, nil, nil, nil, body_593269)

var tagResource* = Call_TagResource_593255(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "states.amazonaws.com", route: "/#X-Amz-Target=AWSStepFunctions.TagResource",
                                        validator: validate_TagResource_593256,
                                        base: "/", url: url_TagResource_593257,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593270 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593272(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_593271(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593273 = header.getOrDefault("X-Amz-Target")
  valid_593273 = validateParameter(valid_593273, JString, required = true, default = newJString(
      "AWSStepFunctions.UntagResource"))
  if valid_593273 != nil:
    section.add "X-Amz-Target", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Signature")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Signature", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Content-Sha256", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Date")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Date", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Credential")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Credential", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Security-Token")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Security-Token", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Algorithm")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Algorithm", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-SignedHeaders", valid_593280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593282: Call_UntagResource_593270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove a tag from a Step Functions resource
  ## 
  let valid = call_593282.validator(path, query, header, formData, body)
  let scheme = call_593282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593282.url(scheme.get, call_593282.host, call_593282.base,
                         call_593282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593282, url, valid)

proc call*(call_593283: Call_UntagResource_593270; body: JsonNode): Recallable =
  ## untagResource
  ## Remove a tag from a Step Functions resource
  ##   body: JObject (required)
  var body_593284 = newJObject()
  if body != nil:
    body_593284 = body
  result = call_593283.call(nil, nil, nil, nil, body_593284)

var untagResource* = Call_UntagResource_593270(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.UntagResource",
    validator: validate_UntagResource_593271, base: "/", url: url_UntagResource_593272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStateMachine_593285 = ref object of OpenApiRestCall_592364
proc url_UpdateStateMachine_593287(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateStateMachine_593286(path: JsonNode; query: JsonNode;
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
  var valid_593288 = header.getOrDefault("X-Amz-Target")
  valid_593288 = validateParameter(valid_593288, JString, required = true, default = newJString(
      "AWSStepFunctions.UpdateStateMachine"))
  if valid_593288 != nil:
    section.add "X-Amz-Target", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Signature")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Signature", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Content-Sha256", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Date")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Date", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Credential")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Credential", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Security-Token")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Security-Token", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Algorithm")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Algorithm", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-SignedHeaders", valid_593295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593297: Call_UpdateStateMachine_593285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing state machine by modifying its <code>definition</code> and/or <code>roleArn</code>. Running executions will continue to use the previous <code>definition</code> and <code>roleArn</code>. You must include at least one of <code>definition</code> or <code>roleArn</code> or you will receive a <code>MissingRequiredParameter</code> error.</p> <note> <p>All <code>StartExecution</code> calls within a few seconds will use the updated <code>definition</code> and <code>roleArn</code>. Executions started immediately after calling <code>UpdateStateMachine</code> may use the previous state machine <code>definition</code> and <code>roleArn</code>. </p> </note>
  ## 
  let valid = call_593297.validator(path, query, header, formData, body)
  let scheme = call_593297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593297.url(scheme.get, call_593297.host, call_593297.base,
                         call_593297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593297, url, valid)

proc call*(call_593298: Call_UpdateStateMachine_593285; body: JsonNode): Recallable =
  ## updateStateMachine
  ## <p>Updates an existing state machine by modifying its <code>definition</code> and/or <code>roleArn</code>. Running executions will continue to use the previous <code>definition</code> and <code>roleArn</code>. You must include at least one of <code>definition</code> or <code>roleArn</code> or you will receive a <code>MissingRequiredParameter</code> error.</p> <note> <p>All <code>StartExecution</code> calls within a few seconds will use the updated <code>definition</code> and <code>roleArn</code>. Executions started immediately after calling <code>UpdateStateMachine</code> may use the previous state machine <code>definition</code> and <code>roleArn</code>. </p> </note>
  ##   body: JObject (required)
  var body_593299 = newJObject()
  if body != nil:
    body_593299 = body
  result = call_593298.call(nil, nil, nil, nil, body_593299)

var updateStateMachine* = Call_UpdateStateMachine_593285(
    name: "updateStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.UpdateStateMachine",
    validator: validate_UpdateStateMachine_593286, base: "/",
    url: url_UpdateStateMachine_593287, schemes: {Scheme.Https, Scheme.Http})
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
