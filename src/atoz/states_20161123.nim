
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_CreateActivity_599705 = ref object of OpenApiRestCall_599368
proc url_CreateActivity_599707(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateActivity_599706(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "AWSStepFunctions.CreateActivity"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_CreateActivity_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an activity. An activity is a task that you write in any programming language and host on any machine that has access to AWS Step Functions. Activities must poll Step Functions using the <code>GetActivityTask</code> API action and respond using <code>SendTask*</code> API actions. This function lets Step Functions know the existence of your activity and returns an identifier for use in a state machine and when polling from the activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateActivity</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateActivity</code>'s idempotency check is based on the activity <code>name</code>. If a following request has different <code>tags</code> values, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>tags</code> will not be updated, even if they are different.</p> </note>
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_CreateActivity_599705; body: JsonNode): Recallable =
  ## createActivity
  ## <p>Creates an activity. An activity is a task that you write in any programming language and host on any machine that has access to AWS Step Functions. Activities must poll Step Functions using the <code>GetActivityTask</code> API action and respond using <code>SendTask*</code> API actions. This function lets Step Functions know the existence of your activity and returns an identifier for use in a state machine and when polling from the activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateActivity</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateActivity</code>'s idempotency check is based on the activity <code>name</code>. If a following request has different <code>tags</code> values, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>tags</code> will not be updated, even if they are different.</p> </note>
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var createActivity* = Call_CreateActivity_599705(name: "createActivity",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.CreateActivity",
    validator: validate_CreateActivity_599706, base: "/", url: url_CreateActivity_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStateMachine_599974 = ref object of OpenApiRestCall_599368
proc url_CreateStateMachine_599976(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStateMachine_599975(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "AWSStepFunctions.CreateStateMachine"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_CreateStateMachine_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a state machine. A state machine consists of a collection of states that can do work (<code>Task</code> states), determine to which states to transition next (<code>Choice</code> states), stop an execution with an error (<code>Fail</code> states), and so on. State machines are specified using a JSON-based, structured language.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateStateMachine</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateStateMachine</code>'s idempotency check is based on the state machine <code>name</code> and <code>definition</code>. If a following request has a different <code>roleArn</code> or <code>tags</code>, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>roleArn</code> and <code>tags</code> will not be updated, even if they are different.</p> </note>
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_CreateStateMachine_599974; body: JsonNode): Recallable =
  ## createStateMachine
  ## <p>Creates a state machine. A state machine consists of a collection of states that can do work (<code>Task</code> states), determine to which states to transition next (<code>Choice</code> states), stop an execution with an error (<code>Fail</code> states), and so on. State machines are specified using a JSON-based, structured language.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note> <note> <p> <code>CreateStateMachine</code> is an idempotent API. Subsequent requests won’t create a duplicate resource if it was already created. <code>CreateStateMachine</code>'s idempotency check is based on the state machine <code>name</code> and <code>definition</code>. If a following request has a different <code>roleArn</code> or <code>tags</code>, Step Functions will ignore these differences and treat it as an idempotent request of the previous. In this case, <code>roleArn</code> and <code>tags</code> will not be updated, even if they are different.</p> </note>
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var createStateMachine* = Call_CreateStateMachine_599974(
    name: "createStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.CreateStateMachine",
    validator: validate_CreateStateMachine_599975, base: "/",
    url: url_CreateStateMachine_599976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivity_599989 = ref object of OpenApiRestCall_599368
proc url_DeleteActivity_599991(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteActivity_599990(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "AWSStepFunctions.DeleteActivity"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_DeleteActivity_599989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an activity.
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_DeleteActivity_599989; body: JsonNode): Recallable =
  ## deleteActivity
  ## Deletes an activity.
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var deleteActivity* = Call_DeleteActivity_599989(name: "deleteActivity",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DeleteActivity",
    validator: validate_DeleteActivity_599990, base: "/", url: url_DeleteActivity_599991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStateMachine_600004 = ref object of OpenApiRestCall_599368
proc url_DeleteStateMachine_600006(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteStateMachine_600005(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "AWSStepFunctions.DeleteStateMachine"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_DeleteStateMachine_600004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a state machine. This is an asynchronous operation: It sets the state machine's status to <code>DELETING</code> and begins the deletion process. Each state machine execution is deleted the next time it makes a state transition.</p> <note> <p>The state machine itself is deleted after all executions are completed or deleted.</p> </note>
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_DeleteStateMachine_600004; body: JsonNode): Recallable =
  ## deleteStateMachine
  ## <p>Deletes a state machine. This is an asynchronous operation: It sets the state machine's status to <code>DELETING</code> and begins the deletion process. Each state machine execution is deleted the next time it makes a state transition.</p> <note> <p>The state machine itself is deleted after all executions are completed or deleted.</p> </note>
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var deleteStateMachine* = Call_DeleteStateMachine_600004(
    name: "deleteStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DeleteStateMachine",
    validator: validate_DeleteStateMachine_600005, base: "/",
    url: url_DeleteStateMachine_600006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivity_600019 = ref object of OpenApiRestCall_599368
proc url_DescribeActivity_600021(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeActivity_600020(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "AWSStepFunctions.DescribeActivity"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_DescribeActivity_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes an activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_DescribeActivity_600019; body: JsonNode): Recallable =
  ## describeActivity
  ## <p>Describes an activity.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var describeActivity* = Call_DescribeActivity_600019(name: "describeActivity",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeActivity",
    validator: validate_DescribeActivity_600020, base: "/",
    url: url_DescribeActivity_600021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExecution_600034 = ref object of OpenApiRestCall_599368
proc url_DescribeExecution_600036(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExecution_600035(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "AWSStepFunctions.DescribeExecution"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_DescribeExecution_600034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes an execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_DescribeExecution_600034; body: JsonNode): Recallable =
  ## describeExecution
  ## <p>Describes an execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var describeExecution* = Call_DescribeExecution_600034(name: "describeExecution",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeExecution",
    validator: validate_DescribeExecution_600035, base: "/",
    url: url_DescribeExecution_600036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStateMachine_600049 = ref object of OpenApiRestCall_599368
proc url_DescribeStateMachine_600051(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStateMachine_600050(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "AWSStepFunctions.DescribeStateMachine"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_DescribeStateMachine_600049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a state machine.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_DescribeStateMachine_600049; body: JsonNode): Recallable =
  ## describeStateMachine
  ## <p>Describes a state machine.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var describeStateMachine* = Call_DescribeStateMachine_600049(
    name: "describeStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeStateMachine",
    validator: validate_DescribeStateMachine_600050, base: "/",
    url: url_DescribeStateMachine_600051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStateMachineForExecution_600064 = ref object of OpenApiRestCall_599368
proc url_DescribeStateMachineForExecution_600066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStateMachineForExecution_600065(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "AWSStepFunctions.DescribeStateMachineForExecution"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_DescribeStateMachineForExecution_600064;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Describes the state machine associated with a specific execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_DescribeStateMachineForExecution_600064;
          body: JsonNode): Recallable =
  ## describeStateMachineForExecution
  ## <p>Describes the state machine associated with a specific execution.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var describeStateMachineForExecution* = Call_DescribeStateMachineForExecution_600064(
    name: "describeStateMachineForExecution", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.DescribeStateMachineForExecution",
    validator: validate_DescribeStateMachineForExecution_600065, base: "/",
    url: url_DescribeStateMachineForExecution_600066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetActivityTask_600079 = ref object of OpenApiRestCall_599368
proc url_GetActivityTask_600081(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetActivityTask_600080(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "AWSStepFunctions.GetActivityTask"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_GetActivityTask_600079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by workers to retrieve a task (with the specified activity ARN) which has been scheduled for execution by a running state machine. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available (i.e. an execution of a task of this type is needed.) The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns a <code>taskToken</code> with a null string.</p> <important> <p>Workers should set their client side socket timeout to at least 65 seconds (5 seconds higher than the maximum time the service may hold the poll request).</p> <p>Polling with <code>GetActivityTask</code> can cause latency in some implementations. See <a href="https://docs.aws.amazon.com/step-functions/latest/dg/bp-activity-pollers.html">Avoid Latency When Polling for Activity Tasks</a> in the Step Functions Developer Guide.</p> </important>
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_GetActivityTask_600079; body: JsonNode): Recallable =
  ## getActivityTask
  ## <p>Used by workers to retrieve a task (with the specified activity ARN) which has been scheduled for execution by a running state machine. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available (i.e. an execution of a task of this type is needed.) The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns a <code>taskToken</code> with a null string.</p> <important> <p>Workers should set their client side socket timeout to at least 65 seconds (5 seconds higher than the maximum time the service may hold the poll request).</p> <p>Polling with <code>GetActivityTask</code> can cause latency in some implementations. See <a href="https://docs.aws.amazon.com/step-functions/latest/dg/bp-activity-pollers.html">Avoid Latency When Polling for Activity Tasks</a> in the Step Functions Developer Guide.</p> </important>
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var getActivityTask* = Call_GetActivityTask_600079(name: "getActivityTask",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.GetActivityTask",
    validator: validate_GetActivityTask_600080, base: "/", url: url_GetActivityTask_600081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExecutionHistory_600094 = ref object of OpenApiRestCall_599368
proc url_GetExecutionHistory_600096(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetExecutionHistory_600095(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns the history of the specified execution as a list of events. By default, the results are returned in ascending order of the <code>timeStamp</code> of the events. Use the <code>reverseOrder</code> parameter to get the latest events first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p>
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
  var valid_600097 = query.getOrDefault("maxResults")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "maxResults", valid_600097
  var valid_600098 = query.getOrDefault("nextToken")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "nextToken", valid_600098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600099 = header.getOrDefault("X-Amz-Date")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Date", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Security-Token")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Security-Token", valid_600100
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600101 = header.getOrDefault("X-Amz-Target")
  valid_600101 = validateParameter(valid_600101, JString, required = true, default = newJString(
      "AWSStepFunctions.GetExecutionHistory"))
  if valid_600101 != nil:
    section.add "X-Amz-Target", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Content-Sha256", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Algorithm")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Algorithm", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Signature")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Signature", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-SignedHeaders", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Credential")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Credential", valid_600106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600108: Call_GetExecutionHistory_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the history of the specified execution as a list of events. By default, the results are returned in ascending order of the <code>timeStamp</code> of the events. Use the <code>reverseOrder</code> parameter to get the latest events first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p>
  ## 
  let valid = call_600108.validator(path, query, header, formData, body)
  let scheme = call_600108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600108.url(scheme.get, call_600108.host, call_600108.base,
                         call_600108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600108, url, valid)

proc call*(call_600109: Call_GetExecutionHistory_600094; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getExecutionHistory
  ## <p>Returns the history of the specified execution as a list of events. By default, the results are returned in ascending order of the <code>timeStamp</code> of the events. Use the <code>reverseOrder</code> parameter to get the latest events first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600110 = newJObject()
  var body_600111 = newJObject()
  add(query_600110, "maxResults", newJString(maxResults))
  add(query_600110, "nextToken", newJString(nextToken))
  if body != nil:
    body_600111 = body
  result = call_600109.call(nil, query_600110, nil, nil, body_600111)

var getExecutionHistory* = Call_GetExecutionHistory_600094(
    name: "getExecutionHistory", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.GetExecutionHistory",
    validator: validate_GetExecutionHistory_600095, base: "/",
    url: url_GetExecutionHistory_600096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActivities_600113 = ref object of OpenApiRestCall_599368
proc url_ListActivities_600115(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListActivities_600114(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_600116 = query.getOrDefault("maxResults")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "maxResults", valid_600116
  var valid_600117 = query.getOrDefault("nextToken")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "nextToken", valid_600117
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600118 = header.getOrDefault("X-Amz-Date")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Date", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Security-Token")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Security-Token", valid_600119
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600120 = header.getOrDefault("X-Amz-Target")
  valid_600120 = validateParameter(valid_600120, JString, required = true, default = newJString(
      "AWSStepFunctions.ListActivities"))
  if valid_600120 != nil:
    section.add "X-Amz-Target", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Content-Sha256", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Algorithm")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Algorithm", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Signature")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Signature", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-SignedHeaders", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Credential")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Credential", valid_600125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600127: Call_ListActivities_600113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the existing activities.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_600127.validator(path, query, header, formData, body)
  let scheme = call_600127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600127.url(scheme.get, call_600127.host, call_600127.base,
                         call_600127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600127, url, valid)

proc call*(call_600128: Call_ListActivities_600113; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listActivities
  ## <p>Lists the existing activities.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600129 = newJObject()
  var body_600130 = newJObject()
  add(query_600129, "maxResults", newJString(maxResults))
  add(query_600129, "nextToken", newJString(nextToken))
  if body != nil:
    body_600130 = body
  result = call_600128.call(nil, query_600129, nil, nil, body_600130)

var listActivities* = Call_ListActivities_600113(name: "listActivities",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListActivities",
    validator: validate_ListActivities_600114, base: "/", url: url_ListActivities_600115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExecutions_600131 = ref object of OpenApiRestCall_599368
proc url_ListExecutions_600133(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListExecutions_600132(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Lists the executions of a state machine that meet the filtering criteria. Results are sorted by time, with the most recent execution first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
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
  var valid_600134 = query.getOrDefault("maxResults")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "maxResults", valid_600134
  var valid_600135 = query.getOrDefault("nextToken")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "nextToken", valid_600135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600136 = header.getOrDefault("X-Amz-Date")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Date", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Security-Token")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Security-Token", valid_600137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600138 = header.getOrDefault("X-Amz-Target")
  valid_600138 = validateParameter(valid_600138, JString, required = true, default = newJString(
      "AWSStepFunctions.ListExecutions"))
  if valid_600138 != nil:
    section.add "X-Amz-Target", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Content-Sha256", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Algorithm")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Algorithm", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Signature")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Signature", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-SignedHeaders", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Credential")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Credential", valid_600143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600145: Call_ListExecutions_600131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the executions of a state machine that meet the filtering criteria. Results are sorted by time, with the most recent execution first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_600145.validator(path, query, header, formData, body)
  let scheme = call_600145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600145.url(scheme.get, call_600145.host, call_600145.base,
                         call_600145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600145, url, valid)

proc call*(call_600146: Call_ListExecutions_600131; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listExecutions
  ## <p>Lists the executions of a state machine that meet the filtering criteria. Results are sorted by time, with the most recent execution first.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600147 = newJObject()
  var body_600148 = newJObject()
  add(query_600147, "maxResults", newJString(maxResults))
  add(query_600147, "nextToken", newJString(nextToken))
  if body != nil:
    body_600148 = body
  result = call_600146.call(nil, query_600147, nil, nil, body_600148)

var listExecutions* = Call_ListExecutions_600131(name: "listExecutions",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListExecutions",
    validator: validate_ListExecutions_600132, base: "/", url: url_ListExecutions_600133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStateMachines_600149 = ref object of OpenApiRestCall_599368
proc url_ListStateMachines_600151(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStateMachines_600150(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_600152 = query.getOrDefault("maxResults")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "maxResults", valid_600152
  var valid_600153 = query.getOrDefault("nextToken")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "nextToken", valid_600153
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600154 = header.getOrDefault("X-Amz-Date")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Date", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Security-Token")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Security-Token", valid_600155
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600156 = header.getOrDefault("X-Amz-Target")
  valid_600156 = validateParameter(valid_600156, JString, required = true, default = newJString(
      "AWSStepFunctions.ListStateMachines"))
  if valid_600156 != nil:
    section.add "X-Amz-Target", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Content-Sha256", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Algorithm")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Algorithm", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Signature")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Signature", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-SignedHeaders", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Credential")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Credential", valid_600161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600163: Call_ListStateMachines_600149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the existing state machines.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ## 
  let valid = call_600163.validator(path, query, header, formData, body)
  let scheme = call_600163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600163.url(scheme.get, call_600163.host, call_600163.base,
                         call_600163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600163, url, valid)

proc call*(call_600164: Call_ListStateMachines_600149; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listStateMachines
  ## <p>Lists the existing state machines.</p> <p>If <code>nextToken</code> is returned, there are more results available. The value of <code>nextToken</code> is a unique pagination token for each page. Make the call again using the returned token to retrieve the next page. Keep all other arguments unchanged. Each pagination token expires after 24 hours. Using an expired pagination token will return an <i>HTTP 400 InvalidToken</i> error.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.</p> </note>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600165 = newJObject()
  var body_600166 = newJObject()
  add(query_600165, "maxResults", newJString(maxResults))
  add(query_600165, "nextToken", newJString(nextToken))
  if body != nil:
    body_600166 = body
  result = call_600164.call(nil, query_600165, nil, nil, body_600166)

var listStateMachines* = Call_ListStateMachines_600149(name: "listStateMachines",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListStateMachines",
    validator: validate_ListStateMachines_600150, base: "/",
    url: url_ListStateMachines_600151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600167 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600169(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600168(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600170 = header.getOrDefault("X-Amz-Date")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Date", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Security-Token")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Security-Token", valid_600171
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600172 = header.getOrDefault("X-Amz-Target")
  valid_600172 = validateParameter(valid_600172, JString, required = true, default = newJString(
      "AWSStepFunctions.ListTagsForResource"))
  if valid_600172 != nil:
    section.add "X-Amz-Target", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Content-Sha256", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Algorithm")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Algorithm", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Signature")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Signature", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-SignedHeaders", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Credential")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Credential", valid_600177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600179: Call_ListTagsForResource_600167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List tags for a given resource.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ## 
  let valid = call_600179.validator(path, query, header, formData, body)
  let scheme = call_600179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600179.url(scheme.get, call_600179.host, call_600179.base,
                         call_600179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600179, url, valid)

proc call*(call_600180: Call_ListTagsForResource_600167; body: JsonNode): Recallable =
  ## listTagsForResource
  ## <p>List tags for a given resource.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ##   body: JObject (required)
  var body_600181 = newJObject()
  if body != nil:
    body_600181 = body
  result = call_600180.call(nil, nil, nil, nil, body_600181)

var listTagsForResource* = Call_ListTagsForResource_600167(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.ListTagsForResource",
    validator: validate_ListTagsForResource_600168, base: "/",
    url: url_ListTagsForResource_600169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTaskFailure_600182 = ref object of OpenApiRestCall_599368
proc url_SendTaskFailure_600184(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendTaskFailure_600183(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600185 = header.getOrDefault("X-Amz-Date")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Date", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Security-Token")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Security-Token", valid_600186
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600187 = header.getOrDefault("X-Amz-Target")
  valid_600187 = validateParameter(valid_600187, JString, required = true, default = newJString(
      "AWSStepFunctions.SendTaskFailure"))
  if valid_600187 != nil:
    section.add "X-Amz-Target", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Content-Sha256", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Algorithm")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Algorithm", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Signature")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Signature", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-SignedHeaders", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Credential")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Credential", valid_600192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600194: Call_SendTaskFailure_600182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> failed.
  ## 
  let valid = call_600194.validator(path, query, header, formData, body)
  let scheme = call_600194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600194.url(scheme.get, call_600194.host, call_600194.base,
                         call_600194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600194, url, valid)

proc call*(call_600195: Call_SendTaskFailure_600182; body: JsonNode): Recallable =
  ## sendTaskFailure
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> failed.
  ##   body: JObject (required)
  var body_600196 = newJObject()
  if body != nil:
    body_600196 = body
  result = call_600195.call(nil, nil, nil, nil, body_600196)

var sendTaskFailure* = Call_SendTaskFailure_600182(name: "sendTaskFailure",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.SendTaskFailure",
    validator: validate_SendTaskFailure_600183, base: "/", url: url_SendTaskFailure_600184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTaskHeartbeat_600197 = ref object of OpenApiRestCall_599368
proc url_SendTaskHeartbeat_600199(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendTaskHeartbeat_600198(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600200 = header.getOrDefault("X-Amz-Date")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Date", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Security-Token")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Security-Token", valid_600201
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600202 = header.getOrDefault("X-Amz-Target")
  valid_600202 = validateParameter(valid_600202, JString, required = true, default = newJString(
      "AWSStepFunctions.SendTaskHeartbeat"))
  if valid_600202 != nil:
    section.add "X-Amz-Target", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Content-Sha256", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Algorithm")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Algorithm", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Signature")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Signature", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-SignedHeaders", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Credential")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Credential", valid_600207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600209: Call_SendTaskHeartbeat_600197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report to Step Functions that the task represented by the specified <code>taskToken</code> is still making progress. This action resets the <code>Heartbeat</code> clock. The <code>Heartbeat</code> threshold is specified in the state machine's Amazon States Language definition (<code>HeartbeatSeconds</code>). This action does not in itself create an event in the execution history. However, if the task times out, the execution history contains an <code>ActivityTimedOut</code> entry for activities, or a <code>TaskTimedOut</code> entry for for tasks using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-sync">job run</a> or <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern.</p> <note> <p>The <code>Timeout</code> of a task, defined in the state machine's Amazon States Language definition, is its maximum allowed duration, regardless of the number of <a>SendTaskHeartbeat</a> requests received. Use <code>HeartbeatSeconds</code> to configure the timeout interval for heartbeats.</p> </note>
  ## 
  let valid = call_600209.validator(path, query, header, formData, body)
  let scheme = call_600209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600209.url(scheme.get, call_600209.host, call_600209.base,
                         call_600209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600209, url, valid)

proc call*(call_600210: Call_SendTaskHeartbeat_600197; body: JsonNode): Recallable =
  ## sendTaskHeartbeat
  ## <p>Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report to Step Functions that the task represented by the specified <code>taskToken</code> is still making progress. This action resets the <code>Heartbeat</code> clock. The <code>Heartbeat</code> threshold is specified in the state machine's Amazon States Language definition (<code>HeartbeatSeconds</code>). This action does not in itself create an event in the execution history. However, if the task times out, the execution history contains an <code>ActivityTimedOut</code> entry for activities, or a <code>TaskTimedOut</code> entry for for tasks using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-sync">job run</a> or <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern.</p> <note> <p>The <code>Timeout</code> of a task, defined in the state machine's Amazon States Language definition, is its maximum allowed duration, regardless of the number of <a>SendTaskHeartbeat</a> requests received. Use <code>HeartbeatSeconds</code> to configure the timeout interval for heartbeats.</p> </note>
  ##   body: JObject (required)
  var body_600211 = newJObject()
  if body != nil:
    body_600211 = body
  result = call_600210.call(nil, nil, nil, nil, body_600211)

var sendTaskHeartbeat* = Call_SendTaskHeartbeat_600197(name: "sendTaskHeartbeat",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.SendTaskHeartbeat",
    validator: validate_SendTaskHeartbeat_600198, base: "/",
    url: url_SendTaskHeartbeat_600199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendTaskSuccess_600212 = ref object of OpenApiRestCall_599368
proc url_SendTaskSuccess_600214(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendTaskSuccess_600213(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600215 = header.getOrDefault("X-Amz-Date")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Date", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Security-Token")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Security-Token", valid_600216
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600217 = header.getOrDefault("X-Amz-Target")
  valid_600217 = validateParameter(valid_600217, JString, required = true, default = newJString(
      "AWSStepFunctions.SendTaskSuccess"))
  if valid_600217 != nil:
    section.add "X-Amz-Target", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Content-Sha256", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Algorithm")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Algorithm", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Signature")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Signature", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-SignedHeaders", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Credential")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Credential", valid_600222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600224: Call_SendTaskSuccess_600212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> completed successfully.
  ## 
  let valid = call_600224.validator(path, query, header, formData, body)
  let scheme = call_600224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600224.url(scheme.get, call_600224.host, call_600224.base,
                         call_600224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600224, url, valid)

proc call*(call_600225: Call_SendTaskSuccess_600212; body: JsonNode): Recallable =
  ## sendTaskSuccess
  ## Used by activity workers and task states using the <a href="https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html#connect-wait-token">callback</a> pattern to report that the task identified by the <code>taskToken</code> completed successfully.
  ##   body: JObject (required)
  var body_600226 = newJObject()
  if body != nil:
    body_600226 = body
  result = call_600225.call(nil, nil, nil, nil, body_600226)

var sendTaskSuccess* = Call_SendTaskSuccess_600212(name: "sendTaskSuccess",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.SendTaskSuccess",
    validator: validate_SendTaskSuccess_600213, base: "/", url: url_SendTaskSuccess_600214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExecution_600227 = ref object of OpenApiRestCall_599368
proc url_StartExecution_600229(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartExecution_600228(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600230 = header.getOrDefault("X-Amz-Date")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Date", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Security-Token")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Security-Token", valid_600231
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600232 = header.getOrDefault("X-Amz-Target")
  valid_600232 = validateParameter(valid_600232, JString, required = true, default = newJString(
      "AWSStepFunctions.StartExecution"))
  if valid_600232 != nil:
    section.add "X-Amz-Target", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Content-Sha256", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Algorithm")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Algorithm", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Signature")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Signature", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-SignedHeaders", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Credential")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Credential", valid_600237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600239: Call_StartExecution_600227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a state machine execution.</p> <note> <p> <code>StartExecution</code> is idempotent. If <code>StartExecution</code> is called with the same name and input as a running execution, the call will succeed and return the same response as the original request. If the execution is closed or if the input is different, it will return a 400 <code>ExecutionAlreadyExists</code> error. Names can be reused after 90 days. </p> </note>
  ## 
  let valid = call_600239.validator(path, query, header, formData, body)
  let scheme = call_600239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600239.url(scheme.get, call_600239.host, call_600239.base,
                         call_600239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600239, url, valid)

proc call*(call_600240: Call_StartExecution_600227; body: JsonNode): Recallable =
  ## startExecution
  ## <p>Starts a state machine execution.</p> <note> <p> <code>StartExecution</code> is idempotent. If <code>StartExecution</code> is called with the same name and input as a running execution, the call will succeed and return the same response as the original request. If the execution is closed or if the input is different, it will return a 400 <code>ExecutionAlreadyExists</code> error. Names can be reused after 90 days. </p> </note>
  ##   body: JObject (required)
  var body_600241 = newJObject()
  if body != nil:
    body_600241 = body
  result = call_600240.call(nil, nil, nil, nil, body_600241)

var startExecution* = Call_StartExecution_600227(name: "startExecution",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.StartExecution",
    validator: validate_StartExecution_600228, base: "/", url: url_StartExecution_600229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopExecution_600242 = ref object of OpenApiRestCall_599368
proc url_StopExecution_600244(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopExecution_600243(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600245 = header.getOrDefault("X-Amz-Date")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Date", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Security-Token")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Security-Token", valid_600246
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600247 = header.getOrDefault("X-Amz-Target")
  valid_600247 = validateParameter(valid_600247, JString, required = true, default = newJString(
      "AWSStepFunctions.StopExecution"))
  if valid_600247 != nil:
    section.add "X-Amz-Target", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Content-Sha256", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Algorithm")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Algorithm", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Signature")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Signature", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-SignedHeaders", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Credential")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Credential", valid_600252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600254: Call_StopExecution_600242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops an execution.
  ## 
  let valid = call_600254.validator(path, query, header, formData, body)
  let scheme = call_600254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600254.url(scheme.get, call_600254.host, call_600254.base,
                         call_600254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600254, url, valid)

proc call*(call_600255: Call_StopExecution_600242; body: JsonNode): Recallable =
  ## stopExecution
  ## Stops an execution.
  ##   body: JObject (required)
  var body_600256 = newJObject()
  if body != nil:
    body_600256 = body
  result = call_600255.call(nil, nil, nil, nil, body_600256)

var stopExecution* = Call_StopExecution_600242(name: "stopExecution",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.StopExecution",
    validator: validate_StopExecution_600243, base: "/", url: url_StopExecution_600244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600257 = ref object of OpenApiRestCall_599368
proc url_TagResource_600259(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600258(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600260 = header.getOrDefault("X-Amz-Date")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Date", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Security-Token")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Security-Token", valid_600261
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600262 = header.getOrDefault("X-Amz-Target")
  valid_600262 = validateParameter(valid_600262, JString, required = true, default = newJString(
      "AWSStepFunctions.TagResource"))
  if valid_600262 != nil:
    section.add "X-Amz-Target", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Content-Sha256", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Algorithm")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Algorithm", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Signature")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Signature", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-SignedHeaders", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Credential")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Credential", valid_600267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600269: Call_TagResource_600257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add a tag to a Step Functions resource.</p> <p>An array of key-value pairs. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>, and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html">Controlling Access Using IAM Tags</a>.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ## 
  let valid = call_600269.validator(path, query, header, formData, body)
  let scheme = call_600269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600269.url(scheme.get, call_600269.host, call_600269.base,
                         call_600269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600269, url, valid)

proc call*(call_600270: Call_TagResource_600257; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add a tag to a Step Functions resource.</p> <p>An array of key-value pairs. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>, and <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html">Controlling Access Using IAM Tags</a>.</p> <p>Tags may only contain Unicode letters, digits, white space, or these symbols: <code>_ . : / = + - @</code>.</p>
  ##   body: JObject (required)
  var body_600271 = newJObject()
  if body != nil:
    body_600271 = body
  result = call_600270.call(nil, nil, nil, nil, body_600271)

var tagResource* = Call_TagResource_600257(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "states.amazonaws.com", route: "/#X-Amz-Target=AWSStepFunctions.TagResource",
                                        validator: validate_TagResource_600258,
                                        base: "/", url: url_TagResource_600259,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600272 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600274(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600273(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600275 = header.getOrDefault("X-Amz-Date")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Date", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Security-Token")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Security-Token", valid_600276
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600277 = header.getOrDefault("X-Amz-Target")
  valid_600277 = validateParameter(valid_600277, JString, required = true, default = newJString(
      "AWSStepFunctions.UntagResource"))
  if valid_600277 != nil:
    section.add "X-Amz-Target", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Content-Sha256", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Algorithm")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Algorithm", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Signature")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Signature", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-SignedHeaders", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Credential")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Credential", valid_600282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600284: Call_UntagResource_600272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove a tag from a Step Functions resource
  ## 
  let valid = call_600284.validator(path, query, header, formData, body)
  let scheme = call_600284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600284.url(scheme.get, call_600284.host, call_600284.base,
                         call_600284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600284, url, valid)

proc call*(call_600285: Call_UntagResource_600272; body: JsonNode): Recallable =
  ## untagResource
  ## Remove a tag from a Step Functions resource
  ##   body: JObject (required)
  var body_600286 = newJObject()
  if body != nil:
    body_600286 = body
  result = call_600285.call(nil, nil, nil, nil, body_600286)

var untagResource* = Call_UntagResource_600272(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.UntagResource",
    validator: validate_UntagResource_600273, base: "/", url: url_UntagResource_600274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStateMachine_600287 = ref object of OpenApiRestCall_599368
proc url_UpdateStateMachine_600289(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateStateMachine_600288(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600290 = header.getOrDefault("X-Amz-Date")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Date", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Security-Token")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Security-Token", valid_600291
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600292 = header.getOrDefault("X-Amz-Target")
  valid_600292 = validateParameter(valid_600292, JString, required = true, default = newJString(
      "AWSStepFunctions.UpdateStateMachine"))
  if valid_600292 != nil:
    section.add "X-Amz-Target", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Content-Sha256", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Algorithm")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Algorithm", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Signature")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Signature", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-SignedHeaders", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Credential")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Credential", valid_600297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600299: Call_UpdateStateMachine_600287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing state machine by modifying its <code>definition</code> and/or <code>roleArn</code>. Running executions will continue to use the previous <code>definition</code> and <code>roleArn</code>. You must include at least one of <code>definition</code> or <code>roleArn</code> or you will receive a <code>MissingRequiredParameter</code> error.</p> <note> <p>All <code>StartExecution</code> calls within a few seconds will use the updated <code>definition</code> and <code>roleArn</code>. Executions started immediately after calling <code>UpdateStateMachine</code> may use the previous state machine <code>definition</code> and <code>roleArn</code>. </p> </note>
  ## 
  let valid = call_600299.validator(path, query, header, formData, body)
  let scheme = call_600299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600299.url(scheme.get, call_600299.host, call_600299.base,
                         call_600299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600299, url, valid)

proc call*(call_600300: Call_UpdateStateMachine_600287; body: JsonNode): Recallable =
  ## updateStateMachine
  ## <p>Updates an existing state machine by modifying its <code>definition</code> and/or <code>roleArn</code>. Running executions will continue to use the previous <code>definition</code> and <code>roleArn</code>. You must include at least one of <code>definition</code> or <code>roleArn</code> or you will receive a <code>MissingRequiredParameter</code> error.</p> <note> <p>All <code>StartExecution</code> calls within a few seconds will use the updated <code>definition</code> and <code>roleArn</code>. Executions started immediately after calling <code>UpdateStateMachine</code> may use the previous state machine <code>definition</code> and <code>roleArn</code>. </p> </note>
  ##   body: JObject (required)
  var body_600301 = newJObject()
  if body != nil:
    body_600301 = body
  result = call_600300.call(nil, nil, nil, nil, body_600301)

var updateStateMachine* = Call_UpdateStateMachine_600287(
    name: "updateStateMachine", meth: HttpMethod.HttpPost,
    host: "states.amazonaws.com",
    route: "/#X-Amz-Target=AWSStepFunctions.UpdateStateMachine",
    validator: validate_UpdateStateMachine_600288, base: "/",
    url: url_UpdateStateMachine_600289, schemes: {Scheme.Https, Scheme.Http})
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
