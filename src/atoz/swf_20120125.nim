
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Simple Workflow Service
## version: 2012-01-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Simple Workflow Service</fullname> <p>The Amazon Simple Workflow Service (Amazon SWF) makes it easy to build applications that use Amazon's cloud to coordinate work across distributed components. In Amazon SWF, a <i>task</i> represents a logical unit of work that is performed by a component of your workflow. Coordinating tasks in a workflow involves managing intertask dependencies, scheduling, and concurrency in accordance with the logical flow of the application.</p> <p>Amazon SWF gives you full control over implementing tasks and coordinating them without worrying about underlying complexities such as tracking their progress and maintaining their state.</p> <p>This documentation serves as reference only. For a broader overview of the Amazon SWF programming model, see the <i> <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/">Amazon SWF Developer Guide</a> </i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/swf/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "swf.ap-northeast-1.amazonaws.com", "ap-southeast-1": "swf.ap-southeast-1.amazonaws.com",
                           "us-west-2": "swf.us-west-2.amazonaws.com",
                           "eu-west-2": "swf.eu-west-2.amazonaws.com", "ap-northeast-3": "swf.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "swf.eu-central-1.amazonaws.com",
                           "us-east-2": "swf.us-east-2.amazonaws.com",
                           "us-east-1": "swf.us-east-1.amazonaws.com", "cn-northwest-1": "swf.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "swf.ap-south-1.amazonaws.com",
                           "eu-north-1": "swf.eu-north-1.amazonaws.com", "ap-northeast-2": "swf.ap-northeast-2.amazonaws.com",
                           "us-west-1": "swf.us-west-1.amazonaws.com",
                           "us-gov-east-1": "swf.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "swf.eu-west-3.amazonaws.com",
                           "cn-north-1": "swf.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "swf.sa-east-1.amazonaws.com",
                           "eu-west-1": "swf.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "swf.us-gov-west-1.amazonaws.com", "ap-southeast-2": "swf.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "swf.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "swf.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "swf.ap-southeast-1.amazonaws.com",
      "us-west-2": "swf.us-west-2.amazonaws.com",
      "eu-west-2": "swf.eu-west-2.amazonaws.com",
      "ap-northeast-3": "swf.ap-northeast-3.amazonaws.com",
      "eu-central-1": "swf.eu-central-1.amazonaws.com",
      "us-east-2": "swf.us-east-2.amazonaws.com",
      "us-east-1": "swf.us-east-1.amazonaws.com",
      "cn-northwest-1": "swf.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "swf.ap-south-1.amazonaws.com",
      "eu-north-1": "swf.eu-north-1.amazonaws.com",
      "ap-northeast-2": "swf.ap-northeast-2.amazonaws.com",
      "us-west-1": "swf.us-west-1.amazonaws.com",
      "us-gov-east-1": "swf.us-gov-east-1.amazonaws.com",
      "eu-west-3": "swf.eu-west-3.amazonaws.com",
      "cn-north-1": "swf.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "swf.sa-east-1.amazonaws.com",
      "eu-west-1": "swf.eu-west-1.amazonaws.com",
      "us-gov-west-1": "swf.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "swf.ap-southeast-2.amazonaws.com",
      "ca-central-1": "swf.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "swf"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CountClosedWorkflowExecutions_602803 = ref object of OpenApiRestCall_602466
proc url_CountClosedWorkflowExecutions_602805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CountClosedWorkflowExecutions_602804(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the number of closed workflow executions within the given domain that meet the specified filtering criteria.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagFilter.tag</code>: String constraint. The key is <code>swf:tagFilter.tag</code>.</p> </li> <li> <p> <code>typeFilter.name</code>: String constraint. The key is <code>swf:typeFilter.name</code>.</p> </li> <li> <p> <code>typeFilter.version</code>: String constraint. The key is <code>swf:typeFilter.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "SimpleWorkflowService.CountClosedWorkflowExecutions"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_CountClosedWorkflowExecutions_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the number of closed workflow executions within the given domain that meet the specified filtering criteria.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagFilter.tag</code>: String constraint. The key is <code>swf:tagFilter.tag</code>.</p> </li> <li> <p> <code>typeFilter.name</code>: String constraint. The key is <code>swf:typeFilter.name</code>.</p> </li> <li> <p> <code>typeFilter.version</code>: String constraint. The key is <code>swf:typeFilter.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_CountClosedWorkflowExecutions_602803; body: JsonNode): Recallable =
  ## countClosedWorkflowExecutions
  ## <p>Returns the number of closed workflow executions within the given domain that meet the specified filtering criteria.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagFilter.tag</code>: String constraint. The key is <code>swf:tagFilter.tag</code>.</p> </li> <li> <p> <code>typeFilter.name</code>: String constraint. The key is <code>swf:typeFilter.name</code>.</p> </li> <li> <p> <code>typeFilter.version</code>: String constraint. The key is <code>swf:typeFilter.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var countClosedWorkflowExecutions* = Call_CountClosedWorkflowExecutions_602803(
    name: "countClosedWorkflowExecutions", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com", route: "/#X-Amz-Target=SimpleWorkflowService.CountClosedWorkflowExecutions",
    validator: validate_CountClosedWorkflowExecutions_602804, base: "/",
    url: url_CountClosedWorkflowExecutions_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CountOpenWorkflowExecutions_603072 = ref object of OpenApiRestCall_602466
proc url_CountOpenWorkflowExecutions_603074(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CountOpenWorkflowExecutions_603073(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the number of open workflow executions within the given domain that meet the specified filtering criteria.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagFilter.tag</code>: String constraint. The key is <code>swf:tagFilter.tag</code>.</p> </li> <li> <p> <code>typeFilter.name</code>: String constraint. The key is <code>swf:typeFilter.name</code>.</p> </li> <li> <p> <code>typeFilter.version</code>: String constraint. The key is <code>swf:typeFilter.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "SimpleWorkflowService.CountOpenWorkflowExecutions"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_CountOpenWorkflowExecutions_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the number of open workflow executions within the given domain that meet the specified filtering criteria.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagFilter.tag</code>: String constraint. The key is <code>swf:tagFilter.tag</code>.</p> </li> <li> <p> <code>typeFilter.name</code>: String constraint. The key is <code>swf:typeFilter.name</code>.</p> </li> <li> <p> <code>typeFilter.version</code>: String constraint. The key is <code>swf:typeFilter.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_CountOpenWorkflowExecutions_603072; body: JsonNode): Recallable =
  ## countOpenWorkflowExecutions
  ## <p>Returns the number of open workflow executions within the given domain that meet the specified filtering criteria.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagFilter.tag</code>: String constraint. The key is <code>swf:tagFilter.tag</code>.</p> </li> <li> <p> <code>typeFilter.name</code>: String constraint. The key is <code>swf:typeFilter.name</code>.</p> </li> <li> <p> <code>typeFilter.version</code>: String constraint. The key is <code>swf:typeFilter.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var countOpenWorkflowExecutions* = Call_CountOpenWorkflowExecutions_603072(
    name: "countOpenWorkflowExecutions", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.CountOpenWorkflowExecutions",
    validator: validate_CountOpenWorkflowExecutions_603073, base: "/",
    url: url_CountOpenWorkflowExecutions_603074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CountPendingActivityTasks_603087 = ref object of OpenApiRestCall_602466
proc url_CountPendingActivityTasks_603089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CountPendingActivityTasks_603088(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the estimated number of activity tasks in the specified task list. The count returned is an approximation and isn't guaranteed to be exact. If you specify a task list that no activity task was ever scheduled in then <code>0</code> is returned.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the <code>taskList.name</code> parameter by using a <code>Condition</code> element with the <code>swf:taskList.name</code> key to allow the action to access only certain task lists.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "SimpleWorkflowService.CountPendingActivityTasks"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_CountPendingActivityTasks_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the estimated number of activity tasks in the specified task list. The count returned is an approximation and isn't guaranteed to be exact. If you specify a task list that no activity task was ever scheduled in then <code>0</code> is returned.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the <code>taskList.name</code> parameter by using a <code>Condition</code> element with the <code>swf:taskList.name</code> key to allow the action to access only certain task lists.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_CountPendingActivityTasks_603087; body: JsonNode): Recallable =
  ## countPendingActivityTasks
  ## <p>Returns the estimated number of activity tasks in the specified task list. The count returned is an approximation and isn't guaranteed to be exact. If you specify a task list that no activity task was ever scheduled in then <code>0</code> is returned.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the <code>taskList.name</code> parameter by using a <code>Condition</code> element with the <code>swf:taskList.name</code> key to allow the action to access only certain task lists.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var countPendingActivityTasks* = Call_CountPendingActivityTasks_603087(
    name: "countPendingActivityTasks", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.CountPendingActivityTasks",
    validator: validate_CountPendingActivityTasks_603088, base: "/",
    url: url_CountPendingActivityTasks_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CountPendingDecisionTasks_603102 = ref object of OpenApiRestCall_602466
proc url_CountPendingDecisionTasks_603104(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CountPendingDecisionTasks_603103(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the estimated number of decision tasks in the specified task list. The count returned is an approximation and isn't guaranteed to be exact. If you specify a task list that no decision task was ever scheduled in then <code>0</code> is returned.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the <code>taskList.name</code> parameter by using a <code>Condition</code> element with the <code>swf:taskList.name</code> key to allow the action to access only certain task lists.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "SimpleWorkflowService.CountPendingDecisionTasks"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_CountPendingDecisionTasks_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the estimated number of decision tasks in the specified task list. The count returned is an approximation and isn't guaranteed to be exact. If you specify a task list that no decision task was ever scheduled in then <code>0</code> is returned.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the <code>taskList.name</code> parameter by using a <code>Condition</code> element with the <code>swf:taskList.name</code> key to allow the action to access only certain task lists.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CountPendingDecisionTasks_603102; body: JsonNode): Recallable =
  ## countPendingDecisionTasks
  ## <p>Returns the estimated number of decision tasks in the specified task list. The count returned is an approximation and isn't guaranteed to be exact. If you specify a task list that no decision task was ever scheduled in then <code>0</code> is returned.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the <code>taskList.name</code> parameter by using a <code>Condition</code> element with the <code>swf:taskList.name</code> key to allow the action to access only certain task lists.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var countPendingDecisionTasks* = Call_CountPendingDecisionTasks_603102(
    name: "countPendingDecisionTasks", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.CountPendingDecisionTasks",
    validator: validate_CountPendingDecisionTasks_603103, base: "/",
    url: url_CountPendingDecisionTasks_603104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeprecateActivityType_603117 = ref object of OpenApiRestCall_602466
proc url_DeprecateActivityType_603119(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeprecateActivityType_603118(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deprecates the specified <i>activity type</i>. After an activity type has been deprecated, you cannot create new tasks of that activity type. Tasks of this type that were scheduled before the type was deprecated continue to run.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>activityType.name</code>: String constraint. The key is <code>swf:activityType.name</code>.</p> </li> <li> <p> <code>activityType.version</code>: String constraint. The key is <code>swf:activityType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "SimpleWorkflowService.DeprecateActivityType"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_DeprecateActivityType_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deprecates the specified <i>activity type</i>. After an activity type has been deprecated, you cannot create new tasks of that activity type. Tasks of this type that were scheduled before the type was deprecated continue to run.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>activityType.name</code>: String constraint. The key is <code>swf:activityType.name</code>.</p> </li> <li> <p> <code>activityType.version</code>: String constraint. The key is <code>swf:activityType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_DeprecateActivityType_603117; body: JsonNode): Recallable =
  ## deprecateActivityType
  ## <p>Deprecates the specified <i>activity type</i>. After an activity type has been deprecated, you cannot create new tasks of that activity type. Tasks of this type that were scheduled before the type was deprecated continue to run.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>activityType.name</code>: String constraint. The key is <code>swf:activityType.name</code>.</p> </li> <li> <p> <code>activityType.version</code>: String constraint. The key is <code>swf:activityType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var deprecateActivityType* = Call_DeprecateActivityType_603117(
    name: "deprecateActivityType", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.DeprecateActivityType",
    validator: validate_DeprecateActivityType_603118, base: "/",
    url: url_DeprecateActivityType_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeprecateDomain_603132 = ref object of OpenApiRestCall_602466
proc url_DeprecateDomain_603134(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeprecateDomain_603133(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deprecates the specified domain. After a domain has been deprecated it cannot be used to create new workflow executions or register new types. However, you can still use visibility actions on this domain. Deprecating a domain also deprecates all activity and workflow types registered in the domain. Executions that were started before the domain was deprecated continues to run.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "SimpleWorkflowService.DeprecateDomain"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_DeprecateDomain_603132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deprecates the specified domain. After a domain has been deprecated it cannot be used to create new workflow executions or register new types. However, you can still use visibility actions on this domain. Deprecating a domain also deprecates all activity and workflow types registered in the domain. Executions that were started before the domain was deprecated continues to run.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_DeprecateDomain_603132; body: JsonNode): Recallable =
  ## deprecateDomain
  ## <p>Deprecates the specified domain. After a domain has been deprecated it cannot be used to create new workflow executions or register new types. However, you can still use visibility actions on this domain. Deprecating a domain also deprecates all activity and workflow types registered in the domain. Executions that were started before the domain was deprecated continues to run.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var deprecateDomain* = Call_DeprecateDomain_603132(name: "deprecateDomain",
    meth: HttpMethod.HttpPost, host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.DeprecateDomain",
    validator: validate_DeprecateDomain_603133, base: "/", url: url_DeprecateDomain_603134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeprecateWorkflowType_603147 = ref object of OpenApiRestCall_602466
proc url_DeprecateWorkflowType_603149(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeprecateWorkflowType_603148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deprecates the specified <i>workflow type</i>. After a workflow type has been deprecated, you cannot create new executions of that type. Executions that were started before the type was deprecated continues to run. A deprecated workflow type may still be used when calling visibility actions.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>workflowType.name</code>: String constraint. The key is <code>swf:workflowType.name</code>.</p> </li> <li> <p> <code>workflowType.version</code>: String constraint. The key is <code>swf:workflowType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "SimpleWorkflowService.DeprecateWorkflowType"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_DeprecateWorkflowType_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deprecates the specified <i>workflow type</i>. After a workflow type has been deprecated, you cannot create new executions of that type. Executions that were started before the type was deprecated continues to run. A deprecated workflow type may still be used when calling visibility actions.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>workflowType.name</code>: String constraint. The key is <code>swf:workflowType.name</code>.</p> </li> <li> <p> <code>workflowType.version</code>: String constraint. The key is <code>swf:workflowType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_DeprecateWorkflowType_603147; body: JsonNode): Recallable =
  ## deprecateWorkflowType
  ## <p>Deprecates the specified <i>workflow type</i>. After a workflow type has been deprecated, you cannot create new executions of that type. Executions that were started before the type was deprecated continues to run. A deprecated workflow type may still be used when calling visibility actions.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>workflowType.name</code>: String constraint. The key is <code>swf:workflowType.name</code>.</p> </li> <li> <p> <code>workflowType.version</code>: String constraint. The key is <code>swf:workflowType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var deprecateWorkflowType* = Call_DeprecateWorkflowType_603147(
    name: "deprecateWorkflowType", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.DeprecateWorkflowType",
    validator: validate_DeprecateWorkflowType_603148, base: "/",
    url: url_DeprecateWorkflowType_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivityType_603162 = ref object of OpenApiRestCall_602466
proc url_DescribeActivityType_603164(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeActivityType_603163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about the specified activity type. This includes configuration settings provided when the type was registered and other general information about the type.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>activityType.name</code>: String constraint. The key is <code>swf:activityType.name</code>.</p> </li> <li> <p> <code>activityType.version</code>: String constraint. The key is <code>swf:activityType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "SimpleWorkflowService.DescribeActivityType"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_DescribeActivityType_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the specified activity type. This includes configuration settings provided when the type was registered and other general information about the type.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>activityType.name</code>: String constraint. The key is <code>swf:activityType.name</code>.</p> </li> <li> <p> <code>activityType.version</code>: String constraint. The key is <code>swf:activityType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_DescribeActivityType_603162; body: JsonNode): Recallable =
  ## describeActivityType
  ## <p>Returns information about the specified activity type. This includes configuration settings provided when the type was registered and other general information about the type.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>activityType.name</code>: String constraint. The key is <code>swf:activityType.name</code>.</p> </li> <li> <p> <code>activityType.version</code>: String constraint. The key is <code>swf:activityType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var describeActivityType* = Call_DescribeActivityType_603162(
    name: "describeActivityType", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.DescribeActivityType",
    validator: validate_DescribeActivityType_603163, base: "/",
    url: url_DescribeActivityType_603164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_603177 = ref object of OpenApiRestCall_602466
proc url_DescribeDomain_603179(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDomain_603178(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns information about the specified domain, including description and status.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "SimpleWorkflowService.DescribeDomain"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_DescribeDomain_603177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the specified domain, including description and status.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_DescribeDomain_603177; body: JsonNode): Recallable =
  ## describeDomain
  ## <p>Returns information about the specified domain, including description and status.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var describeDomain* = Call_DescribeDomain_603177(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.DescribeDomain",
    validator: validate_DescribeDomain_603178, base: "/", url: url_DescribeDomain_603179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkflowExecution_603192 = ref object of OpenApiRestCall_602466
proc url_DescribeWorkflowExecution_603194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkflowExecution_603193(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about the specified workflow execution including its type and some statistics.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "SimpleWorkflowService.DescribeWorkflowExecution"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_DescribeWorkflowExecution_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the specified workflow execution including its type and some statistics.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_DescribeWorkflowExecution_603192; body: JsonNode): Recallable =
  ## describeWorkflowExecution
  ## <p>Returns information about the specified workflow execution including its type and some statistics.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var describeWorkflowExecution* = Call_DescribeWorkflowExecution_603192(
    name: "describeWorkflowExecution", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.DescribeWorkflowExecution",
    validator: validate_DescribeWorkflowExecution_603193, base: "/",
    url: url_DescribeWorkflowExecution_603194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkflowType_603207 = ref object of OpenApiRestCall_602466
proc url_DescribeWorkflowType_603209(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkflowType_603208(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about the specified <i>workflow type</i>. This includes configuration settings specified when the type was registered and other information such as creation date, current status, etc.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>workflowType.name</code>: String constraint. The key is <code>swf:workflowType.name</code>.</p> </li> <li> <p> <code>workflowType.version</code>: String constraint. The key is <code>swf:workflowType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "SimpleWorkflowService.DescribeWorkflowType"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_DescribeWorkflowType_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the specified <i>workflow type</i>. This includes configuration settings specified when the type was registered and other information such as creation date, current status, etc.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>workflowType.name</code>: String constraint. The key is <code>swf:workflowType.name</code>.</p> </li> <li> <p> <code>workflowType.version</code>: String constraint. The key is <code>swf:workflowType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_DescribeWorkflowType_603207; body: JsonNode): Recallable =
  ## describeWorkflowType
  ## <p>Returns information about the specified <i>workflow type</i>. This includes configuration settings specified when the type was registered and other information such as creation date, current status, etc.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>workflowType.name</code>: String constraint. The key is <code>swf:workflowType.name</code>.</p> </li> <li> <p> <code>workflowType.version</code>: String constraint. The key is <code>swf:workflowType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var describeWorkflowType* = Call_DescribeWorkflowType_603207(
    name: "describeWorkflowType", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.DescribeWorkflowType",
    validator: validate_DescribeWorkflowType_603208, base: "/",
    url: url_DescribeWorkflowType_603209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowExecutionHistory_603222 = ref object of OpenApiRestCall_602466
proc url_GetWorkflowExecutionHistory_603224(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWorkflowExecutionHistory_603223(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the history of the specified workflow execution. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the <code>nextPageToken</code> returned by the initial call.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextPageToken: JString
  ##                : Pagination token
  ##   maximumPageSize: JString
  ##                  : Pagination limit
  section = newJObject()
  var valid_603225 = query.getOrDefault("nextPageToken")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "nextPageToken", valid_603225
  var valid_603226 = query.getOrDefault("maximumPageSize")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "maximumPageSize", valid_603226
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
  var valid_603227 = header.getOrDefault("X-Amz-Date")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Date", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Security-Token")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Security-Token", valid_603228
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603229 = header.getOrDefault("X-Amz-Target")
  valid_603229 = validateParameter(valid_603229, JString, required = true, default = newJString(
      "SimpleWorkflowService.GetWorkflowExecutionHistory"))
  if valid_603229 != nil:
    section.add "X-Amz-Target", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Content-Sha256", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Algorithm")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Algorithm", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Signature")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Signature", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-SignedHeaders", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Credential")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Credential", valid_603234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603236: Call_GetWorkflowExecutionHistory_603222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the history of the specified workflow execution. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the <code>nextPageToken</code> returned by the initial call.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603236.validator(path, query, header, formData, body)
  let scheme = call_603236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603236.url(scheme.get, call_603236.host, call_603236.base,
                         call_603236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603236, url, valid)

proc call*(call_603237: Call_GetWorkflowExecutionHistory_603222; body: JsonNode;
          nextPageToken: string = ""; maximumPageSize: string = ""): Recallable =
  ## getWorkflowExecutionHistory
  ## <p>Returns the history of the specified workflow execution. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the <code>nextPageToken</code> returned by the initial call.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   nextPageToken: string
  ##                : Pagination token
  ##   maximumPageSize: string
  ##                  : Pagination limit
  ##   body: JObject (required)
  var query_603238 = newJObject()
  var body_603239 = newJObject()
  add(query_603238, "nextPageToken", newJString(nextPageToken))
  add(query_603238, "maximumPageSize", newJString(maximumPageSize))
  if body != nil:
    body_603239 = body
  result = call_603237.call(nil, query_603238, nil, nil, body_603239)

var getWorkflowExecutionHistory* = Call_GetWorkflowExecutionHistory_603222(
    name: "getWorkflowExecutionHistory", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.GetWorkflowExecutionHistory",
    validator: validate_GetWorkflowExecutionHistory_603223, base: "/",
    url: url_GetWorkflowExecutionHistory_603224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActivityTypes_603241 = ref object of OpenApiRestCall_602466
proc url_ListActivityTypes_603243(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListActivityTypes_603242(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Returns information about all activities registered in the specified domain that match the specified name and registration status. The result includes information like creation date, current status of the activity, etc. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the <code>nextPageToken</code> returned by the initial call.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextPageToken: JString
  ##                : Pagination token
  ##   maximumPageSize: JString
  ##                  : Pagination limit
  section = newJObject()
  var valid_603244 = query.getOrDefault("nextPageToken")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "nextPageToken", valid_603244
  var valid_603245 = query.getOrDefault("maximumPageSize")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "maximumPageSize", valid_603245
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
  var valid_603246 = header.getOrDefault("X-Amz-Date")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Date", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Security-Token")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Security-Token", valid_603247
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603248 = header.getOrDefault("X-Amz-Target")
  valid_603248 = validateParameter(valid_603248, JString, required = true, default = newJString(
      "SimpleWorkflowService.ListActivityTypes"))
  if valid_603248 != nil:
    section.add "X-Amz-Target", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Content-Sha256", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Algorithm")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Algorithm", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Signature")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Signature", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-SignedHeaders", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Credential")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Credential", valid_603253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603255: Call_ListActivityTypes_603241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all activities registered in the specified domain that match the specified name and registration status. The result includes information like creation date, current status of the activity, etc. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the <code>nextPageToken</code> returned by the initial call.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603255.validator(path, query, header, formData, body)
  let scheme = call_603255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603255.url(scheme.get, call_603255.host, call_603255.base,
                         call_603255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603255, url, valid)

proc call*(call_603256: Call_ListActivityTypes_603241; body: JsonNode;
          nextPageToken: string = ""; maximumPageSize: string = ""): Recallable =
  ## listActivityTypes
  ## <p>Returns information about all activities registered in the specified domain that match the specified name and registration status. The result includes information like creation date, current status of the activity, etc. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the <code>nextPageToken</code> returned by the initial call.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   nextPageToken: string
  ##                : Pagination token
  ##   maximumPageSize: string
  ##                  : Pagination limit
  ##   body: JObject (required)
  var query_603257 = newJObject()
  var body_603258 = newJObject()
  add(query_603257, "nextPageToken", newJString(nextPageToken))
  add(query_603257, "maximumPageSize", newJString(maximumPageSize))
  if body != nil:
    body_603258 = body
  result = call_603256.call(nil, query_603257, nil, nil, body_603258)

var listActivityTypes* = Call_ListActivityTypes_603241(name: "listActivityTypes",
    meth: HttpMethod.HttpPost, host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.ListActivityTypes",
    validator: validate_ListActivityTypes_603242, base: "/",
    url: url_ListActivityTypes_603243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClosedWorkflowExecutions_603259 = ref object of OpenApiRestCall_602466
proc url_ListClosedWorkflowExecutions_603261(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListClosedWorkflowExecutions_603260(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of closed workflow executions in the specified domain that meet the filtering criteria. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagFilter.tag</code>: String constraint. The key is <code>swf:tagFilter.tag</code>.</p> </li> <li> <p> <code>typeFilter.name</code>: String constraint. The key is <code>swf:typeFilter.name</code>.</p> </li> <li> <p> <code>typeFilter.version</code>: String constraint. The key is <code>swf:typeFilter.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextPageToken: JString
  ##                : Pagination token
  ##   maximumPageSize: JString
  ##                  : Pagination limit
  section = newJObject()
  var valid_603262 = query.getOrDefault("nextPageToken")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "nextPageToken", valid_603262
  var valid_603263 = query.getOrDefault("maximumPageSize")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "maximumPageSize", valid_603263
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
  var valid_603264 = header.getOrDefault("X-Amz-Date")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Date", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Security-Token")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Security-Token", valid_603265
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603266 = header.getOrDefault("X-Amz-Target")
  valid_603266 = validateParameter(valid_603266, JString, required = true, default = newJString(
      "SimpleWorkflowService.ListClosedWorkflowExecutions"))
  if valid_603266 != nil:
    section.add "X-Amz-Target", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Content-Sha256", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Algorithm")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Algorithm", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Signature")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Signature", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-SignedHeaders", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Credential")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Credential", valid_603271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603273: Call_ListClosedWorkflowExecutions_603259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of closed workflow executions in the specified domain that meet the filtering criteria. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagFilter.tag</code>: String constraint. The key is <code>swf:tagFilter.tag</code>.</p> </li> <li> <p> <code>typeFilter.name</code>: String constraint. The key is <code>swf:typeFilter.name</code>.</p> </li> <li> <p> <code>typeFilter.version</code>: String constraint. The key is <code>swf:typeFilter.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603273.validator(path, query, header, formData, body)
  let scheme = call_603273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603273.url(scheme.get, call_603273.host, call_603273.base,
                         call_603273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603273, url, valid)

proc call*(call_603274: Call_ListClosedWorkflowExecutions_603259; body: JsonNode;
          nextPageToken: string = ""; maximumPageSize: string = ""): Recallable =
  ## listClosedWorkflowExecutions
  ## <p>Returns a list of closed workflow executions in the specified domain that meet the filtering criteria. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagFilter.tag</code>: String constraint. The key is <code>swf:tagFilter.tag</code>.</p> </li> <li> <p> <code>typeFilter.name</code>: String constraint. The key is <code>swf:typeFilter.name</code>.</p> </li> <li> <p> <code>typeFilter.version</code>: String constraint. The key is <code>swf:typeFilter.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   nextPageToken: string
  ##                : Pagination token
  ##   maximumPageSize: string
  ##                  : Pagination limit
  ##   body: JObject (required)
  var query_603275 = newJObject()
  var body_603276 = newJObject()
  add(query_603275, "nextPageToken", newJString(nextPageToken))
  add(query_603275, "maximumPageSize", newJString(maximumPageSize))
  if body != nil:
    body_603276 = body
  result = call_603274.call(nil, query_603275, nil, nil, body_603276)

var listClosedWorkflowExecutions* = Call_ListClosedWorkflowExecutions_603259(
    name: "listClosedWorkflowExecutions", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.ListClosedWorkflowExecutions",
    validator: validate_ListClosedWorkflowExecutions_603260, base: "/",
    url: url_ListClosedWorkflowExecutions_603261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_603277 = ref object of OpenApiRestCall_602466
proc url_ListDomains_603279(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDomains_603278(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the list of domains registered in the account. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains. The element must be set to <code>arn:aws:swf::AccountID:domain/*</code>, where <i>AccountID</i> is the account ID, with no dashes.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextPageToken: JString
  ##                : Pagination token
  ##   maximumPageSize: JString
  ##                  : Pagination limit
  section = newJObject()
  var valid_603280 = query.getOrDefault("nextPageToken")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "nextPageToken", valid_603280
  var valid_603281 = query.getOrDefault("maximumPageSize")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "maximumPageSize", valid_603281
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
  var valid_603282 = header.getOrDefault("X-Amz-Date")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Date", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Security-Token")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Security-Token", valid_603283
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603284 = header.getOrDefault("X-Amz-Target")
  valid_603284 = validateParameter(valid_603284, JString, required = true, default = newJString(
      "SimpleWorkflowService.ListDomains"))
  if valid_603284 != nil:
    section.add "X-Amz-Target", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Content-Sha256", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Algorithm")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Algorithm", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Signature")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Signature", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-SignedHeaders", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Credential")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Credential", valid_603289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603291: Call_ListDomains_603277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of domains registered in the account. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains. The element must be set to <code>arn:aws:swf::AccountID:domain/*</code>, where <i>AccountID</i> is the account ID, with no dashes.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603291.validator(path, query, header, formData, body)
  let scheme = call_603291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603291.url(scheme.get, call_603291.host, call_603291.base,
                         call_603291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603291, url, valid)

proc call*(call_603292: Call_ListDomains_603277; body: JsonNode;
          nextPageToken: string = ""; maximumPageSize: string = ""): Recallable =
  ## listDomains
  ## <p>Returns the list of domains registered in the account. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains. The element must be set to <code>arn:aws:swf::AccountID:domain/*</code>, where <i>AccountID</i> is the account ID, with no dashes.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   nextPageToken: string
  ##                : Pagination token
  ##   maximumPageSize: string
  ##                  : Pagination limit
  ##   body: JObject (required)
  var query_603293 = newJObject()
  var body_603294 = newJObject()
  add(query_603293, "nextPageToken", newJString(nextPageToken))
  add(query_603293, "maximumPageSize", newJString(maximumPageSize))
  if body != nil:
    body_603294 = body
  result = call_603292.call(nil, query_603293, nil, nil, body_603294)

var listDomains* = Call_ListDomains_603277(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "swf.amazonaws.com", route: "/#X-Amz-Target=SimpleWorkflowService.ListDomains",
                                        validator: validate_ListDomains_603278,
                                        base: "/", url: url_ListDomains_603279,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOpenWorkflowExecutions_603295 = ref object of OpenApiRestCall_602466
proc url_ListOpenWorkflowExecutions_603297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOpenWorkflowExecutions_603296(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of open workflow executions in the specified domain that meet the filtering criteria. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagFilter.tag</code>: String constraint. The key is <code>swf:tagFilter.tag</code>.</p> </li> <li> <p> <code>typeFilter.name</code>: String constraint. The key is <code>swf:typeFilter.name</code>.</p> </li> <li> <p> <code>typeFilter.version</code>: String constraint. The key is <code>swf:typeFilter.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextPageToken: JString
  ##                : Pagination token
  ##   maximumPageSize: JString
  ##                  : Pagination limit
  section = newJObject()
  var valid_603298 = query.getOrDefault("nextPageToken")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "nextPageToken", valid_603298
  var valid_603299 = query.getOrDefault("maximumPageSize")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "maximumPageSize", valid_603299
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
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "SimpleWorkflowService.ListOpenWorkflowExecutions"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_ListOpenWorkflowExecutions_603295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of open workflow executions in the specified domain that meet the filtering criteria. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagFilter.tag</code>: String constraint. The key is <code>swf:tagFilter.tag</code>.</p> </li> <li> <p> <code>typeFilter.name</code>: String constraint. The key is <code>swf:typeFilter.name</code>.</p> </li> <li> <p> <code>typeFilter.version</code>: String constraint. The key is <code>swf:typeFilter.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_ListOpenWorkflowExecutions_603295; body: JsonNode;
          nextPageToken: string = ""; maximumPageSize: string = ""): Recallable =
  ## listOpenWorkflowExecutions
  ## <p>Returns a list of open workflow executions in the specified domain that meet the filtering criteria. The results may be split into multiple pages. To retrieve subsequent pages, make the call again using the nextPageToken returned by the initial call.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagFilter.tag</code>: String constraint. The key is <code>swf:tagFilter.tag</code>.</p> </li> <li> <p> <code>typeFilter.name</code>: String constraint. The key is <code>swf:typeFilter.name</code>.</p> </li> <li> <p> <code>typeFilter.version</code>: String constraint. The key is <code>swf:typeFilter.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   nextPageToken: string
  ##                : Pagination token
  ##   maximumPageSize: string
  ##                  : Pagination limit
  ##   body: JObject (required)
  var query_603311 = newJObject()
  var body_603312 = newJObject()
  add(query_603311, "nextPageToken", newJString(nextPageToken))
  add(query_603311, "maximumPageSize", newJString(maximumPageSize))
  if body != nil:
    body_603312 = body
  result = call_603310.call(nil, query_603311, nil, nil, body_603312)

var listOpenWorkflowExecutions* = Call_ListOpenWorkflowExecutions_603295(
    name: "listOpenWorkflowExecutions", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.ListOpenWorkflowExecutions",
    validator: validate_ListOpenWorkflowExecutions_603296, base: "/",
    url: url_ListOpenWorkflowExecutions_603297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603313 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603315(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_603314(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List tags for a given domain.
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
  var valid_603316 = header.getOrDefault("X-Amz-Date")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Date", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Security-Token")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Security-Token", valid_603317
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603318 = header.getOrDefault("X-Amz-Target")
  valid_603318 = validateParameter(valid_603318, JString, required = true, default = newJString(
      "SimpleWorkflowService.ListTagsForResource"))
  if valid_603318 != nil:
    section.add "X-Amz-Target", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Content-Sha256", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Algorithm")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Algorithm", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Signature")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Signature", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-SignedHeaders", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Credential")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Credential", valid_603323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603325: Call_ListTagsForResource_603313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List tags for a given domain.
  ## 
  let valid = call_603325.validator(path, query, header, formData, body)
  let scheme = call_603325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603325.url(scheme.get, call_603325.host, call_603325.base,
                         call_603325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603325, url, valid)

proc call*(call_603326: Call_ListTagsForResource_603313; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List tags for a given domain.
  ##   body: JObject (required)
  var body_603327 = newJObject()
  if body != nil:
    body_603327 = body
  result = call_603326.call(nil, nil, nil, nil, body_603327)

var listTagsForResource* = Call_ListTagsForResource_603313(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.ListTagsForResource",
    validator: validate_ListTagsForResource_603314, base: "/",
    url: url_ListTagsForResource_603315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkflowTypes_603328 = ref object of OpenApiRestCall_602466
proc url_ListWorkflowTypes_603330(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWorkflowTypes_603329(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Returns information about workflow types in the specified domain. The results may be split into multiple pages that can be retrieved by making the call repeatedly.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextPageToken: JString
  ##                : Pagination token
  ##   maximumPageSize: JString
  ##                  : Pagination limit
  section = newJObject()
  var valid_603331 = query.getOrDefault("nextPageToken")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "nextPageToken", valid_603331
  var valid_603332 = query.getOrDefault("maximumPageSize")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "maximumPageSize", valid_603332
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
  var valid_603333 = header.getOrDefault("X-Amz-Date")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Date", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Security-Token")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Security-Token", valid_603334
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603335 = header.getOrDefault("X-Amz-Target")
  valid_603335 = validateParameter(valid_603335, JString, required = true, default = newJString(
      "SimpleWorkflowService.ListWorkflowTypes"))
  if valid_603335 != nil:
    section.add "X-Amz-Target", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Content-Sha256", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Algorithm")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Algorithm", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Signature")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Signature", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-SignedHeaders", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Credential")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Credential", valid_603340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603342: Call_ListWorkflowTypes_603328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about workflow types in the specified domain. The results may be split into multiple pages that can be retrieved by making the call repeatedly.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603342.validator(path, query, header, formData, body)
  let scheme = call_603342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603342.url(scheme.get, call_603342.host, call_603342.base,
                         call_603342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603342, url, valid)

proc call*(call_603343: Call_ListWorkflowTypes_603328; body: JsonNode;
          nextPageToken: string = ""; maximumPageSize: string = ""): Recallable =
  ## listWorkflowTypes
  ## <p>Returns information about workflow types in the specified domain. The results may be split into multiple pages that can be retrieved by making the call repeatedly.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   nextPageToken: string
  ##                : Pagination token
  ##   maximumPageSize: string
  ##                  : Pagination limit
  ##   body: JObject (required)
  var query_603344 = newJObject()
  var body_603345 = newJObject()
  add(query_603344, "nextPageToken", newJString(nextPageToken))
  add(query_603344, "maximumPageSize", newJString(maximumPageSize))
  if body != nil:
    body_603345 = body
  result = call_603343.call(nil, query_603344, nil, nil, body_603345)

var listWorkflowTypes* = Call_ListWorkflowTypes_603328(name: "listWorkflowTypes",
    meth: HttpMethod.HttpPost, host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.ListWorkflowTypes",
    validator: validate_ListWorkflowTypes_603329, base: "/",
    url: url_ListWorkflowTypes_603330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForActivityTask_603346 = ref object of OpenApiRestCall_602466
proc url_PollForActivityTask_603348(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PollForActivityTask_603347(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Used by workers to get an <a>ActivityTask</a> from the specified activity <code>taskList</code>. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available. The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns an empty result. An empty result, in this context, means that an ActivityTask is returned, but that the value of taskToken is an empty string. If a task is returned, the worker should use its type to identify and process it correctly.</p> <important> <p>Workers should set their client side socket timeout to at least 70 seconds (10 seconds higher than the maximum time service may hold the poll request).</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the <code>taskList.name</code> parameter by using a <code>Condition</code> element with the <code>swf:taskList.name</code> key to allow the action to access only certain task lists.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603349 = header.getOrDefault("X-Amz-Date")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Date", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Security-Token")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Security-Token", valid_603350
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603351 = header.getOrDefault("X-Amz-Target")
  valid_603351 = validateParameter(valid_603351, JString, required = true, default = newJString(
      "SimpleWorkflowService.PollForActivityTask"))
  if valid_603351 != nil:
    section.add "X-Amz-Target", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Content-Sha256", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Algorithm")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Algorithm", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Signature")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Signature", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-SignedHeaders", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Credential")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Credential", valid_603356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603358: Call_PollForActivityTask_603346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by workers to get an <a>ActivityTask</a> from the specified activity <code>taskList</code>. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available. The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns an empty result. An empty result, in this context, means that an ActivityTask is returned, but that the value of taskToken is an empty string. If a task is returned, the worker should use its type to identify and process it correctly.</p> <important> <p>Workers should set their client side socket timeout to at least 70 seconds (10 seconds higher than the maximum time service may hold the poll request).</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the <code>taskList.name</code> parameter by using a <code>Condition</code> element with the <code>swf:taskList.name</code> key to allow the action to access only certain task lists.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603358.validator(path, query, header, formData, body)
  let scheme = call_603358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603358.url(scheme.get, call_603358.host, call_603358.base,
                         call_603358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603358, url, valid)

proc call*(call_603359: Call_PollForActivityTask_603346; body: JsonNode): Recallable =
  ## pollForActivityTask
  ## <p>Used by workers to get an <a>ActivityTask</a> from the specified activity <code>taskList</code>. This initiates a long poll, where the service holds the HTTP connection open and responds as soon as a task becomes available. The maximum time the service holds on to the request before responding is 60 seconds. If no task is available within 60 seconds, the poll returns an empty result. An empty result, in this context, means that an ActivityTask is returned, but that the value of taskToken is an empty string. If a task is returned, the worker should use its type to identify and process it correctly.</p> <important> <p>Workers should set their client side socket timeout to at least 70 seconds (10 seconds higher than the maximum time service may hold the poll request).</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the <code>taskList.name</code> parameter by using a <code>Condition</code> element with the <code>swf:taskList.name</code> key to allow the action to access only certain task lists.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603360 = newJObject()
  if body != nil:
    body_603360 = body
  result = call_603359.call(nil, nil, nil, nil, body_603360)

var pollForActivityTask* = Call_PollForActivityTask_603346(
    name: "pollForActivityTask", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.PollForActivityTask",
    validator: validate_PollForActivityTask_603347, base: "/",
    url: url_PollForActivityTask_603348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PollForDecisionTask_603361 = ref object of OpenApiRestCall_602466
proc url_PollForDecisionTask_603363(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PollForDecisionTask_603362(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Used by deciders to get a <a>DecisionTask</a> from the specified decision <code>taskList</code>. A decision task may be returned for any open workflow execution that is using the specified task list. The task includes a paginated view of the history of the workflow execution. The decider should use the workflow type and the history to determine how to properly handle the task.</p> <p>This action initiates a long poll, where the service holds the HTTP connection open and responds as soon a task becomes available. If no decision task is available in the specified task list before the timeout of 60 seconds expires, an empty result is returned. An empty result, in this context, means that a DecisionTask is returned, but that the value of taskToken is an empty string.</p> <important> <p>Deciders should set their client side socket timeout to at least 70 seconds (10 seconds higher than the timeout).</p> </important> <important> <p>Because the number of workflow history events for a single workflow execution might be very large, the result returned might be split up across a number of pages. To retrieve subsequent pages, make additional calls to <code>PollForDecisionTask</code> using the <code>nextPageToken</code> returned by the initial call. Note that you do <i>not</i> call <code>GetWorkflowExecutionHistory</code> with this <code>nextPageToken</code>. Instead, call <code>PollForDecisionTask</code> again.</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the <code>taskList.name</code> parameter by using a <code>Condition</code> element with the <code>swf:taskList.name</code> key to allow the action to access only certain task lists.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextPageToken: JString
  ##                : Pagination token
  ##   maximumPageSize: JString
  ##                  : Pagination limit
  section = newJObject()
  var valid_603364 = query.getOrDefault("nextPageToken")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "nextPageToken", valid_603364
  var valid_603365 = query.getOrDefault("maximumPageSize")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "maximumPageSize", valid_603365
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
  var valid_603366 = header.getOrDefault("X-Amz-Date")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Date", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Security-Token")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Security-Token", valid_603367
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603368 = header.getOrDefault("X-Amz-Target")
  valid_603368 = validateParameter(valid_603368, JString, required = true, default = newJString(
      "SimpleWorkflowService.PollForDecisionTask"))
  if valid_603368 != nil:
    section.add "X-Amz-Target", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Content-Sha256", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Algorithm")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Algorithm", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Signature")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Signature", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-SignedHeaders", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Credential")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Credential", valid_603373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603375: Call_PollForDecisionTask_603361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by deciders to get a <a>DecisionTask</a> from the specified decision <code>taskList</code>. A decision task may be returned for any open workflow execution that is using the specified task list. The task includes a paginated view of the history of the workflow execution. The decider should use the workflow type and the history to determine how to properly handle the task.</p> <p>This action initiates a long poll, where the service holds the HTTP connection open and responds as soon a task becomes available. If no decision task is available in the specified task list before the timeout of 60 seconds expires, an empty result is returned. An empty result, in this context, means that a DecisionTask is returned, but that the value of taskToken is an empty string.</p> <important> <p>Deciders should set their client side socket timeout to at least 70 seconds (10 seconds higher than the timeout).</p> </important> <important> <p>Because the number of workflow history events for a single workflow execution might be very large, the result returned might be split up across a number of pages. To retrieve subsequent pages, make additional calls to <code>PollForDecisionTask</code> using the <code>nextPageToken</code> returned by the initial call. Note that you do <i>not</i> call <code>GetWorkflowExecutionHistory</code> with this <code>nextPageToken</code>. Instead, call <code>PollForDecisionTask</code> again.</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the <code>taskList.name</code> parameter by using a <code>Condition</code> element with the <code>swf:taskList.name</code> key to allow the action to access only certain task lists.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603375.validator(path, query, header, formData, body)
  let scheme = call_603375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603375.url(scheme.get, call_603375.host, call_603375.base,
                         call_603375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603375, url, valid)

proc call*(call_603376: Call_PollForDecisionTask_603361; body: JsonNode;
          nextPageToken: string = ""; maximumPageSize: string = ""): Recallable =
  ## pollForDecisionTask
  ## <p>Used by deciders to get a <a>DecisionTask</a> from the specified decision <code>taskList</code>. A decision task may be returned for any open workflow execution that is using the specified task list. The task includes a paginated view of the history of the workflow execution. The decider should use the workflow type and the history to determine how to properly handle the task.</p> <p>This action initiates a long poll, where the service holds the HTTP connection open and responds as soon a task becomes available. If no decision task is available in the specified task list before the timeout of 60 seconds expires, an empty result is returned. An empty result, in this context, means that a DecisionTask is returned, but that the value of taskToken is an empty string.</p> <important> <p>Deciders should set their client side socket timeout to at least 70 seconds (10 seconds higher than the timeout).</p> </important> <important> <p>Because the number of workflow history events for a single workflow execution might be very large, the result returned might be split up across a number of pages. To retrieve subsequent pages, make additional calls to <code>PollForDecisionTask</code> using the <code>nextPageToken</code> returned by the initial call. Note that you do <i>not</i> call <code>GetWorkflowExecutionHistory</code> with this <code>nextPageToken</code>. Instead, call <code>PollForDecisionTask</code> again.</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the <code>taskList.name</code> parameter by using a <code>Condition</code> element with the <code>swf:taskList.name</code> key to allow the action to access only certain task lists.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   nextPageToken: string
  ##                : Pagination token
  ##   maximumPageSize: string
  ##                  : Pagination limit
  ##   body: JObject (required)
  var query_603377 = newJObject()
  var body_603378 = newJObject()
  add(query_603377, "nextPageToken", newJString(nextPageToken))
  add(query_603377, "maximumPageSize", newJString(maximumPageSize))
  if body != nil:
    body_603378 = body
  result = call_603376.call(nil, query_603377, nil, nil, body_603378)

var pollForDecisionTask* = Call_PollForDecisionTask_603361(
    name: "pollForDecisionTask", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.PollForDecisionTask",
    validator: validate_PollForDecisionTask_603362, base: "/",
    url: url_PollForDecisionTask_603363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RecordActivityTaskHeartbeat_603379 = ref object of OpenApiRestCall_602466
proc url_RecordActivityTaskHeartbeat_603381(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RecordActivityTaskHeartbeat_603380(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Used by activity workers to report to the service that the <a>ActivityTask</a> represented by the specified <code>taskToken</code> is still making progress. The worker can also specify details of the progress, for example percent complete, using the <code>details</code> parameter. This action can also be used by the worker as a mechanism to check if cancellation is being requested for the activity task. If a cancellation is being attempted for the specified task, then the boolean <code>cancelRequested</code> flag returned by the service is set to <code>true</code>.</p> <p>This action resets the <code>taskHeartbeatTimeout</code> clock. The <code>taskHeartbeatTimeout</code> is specified in <a>RegisterActivityType</a>.</p> <p>This action doesn't in itself create an event in the workflow execution history. However, if the task times out, the workflow execution history contains a <code>ActivityTaskTimedOut</code> event that contains the information from the last heartbeat generated by the activity worker.</p> <note> <p>The <code>taskStartToCloseTimeout</code> of an activity type is the maximum duration of an activity task, regardless of the number of <a>RecordActivityTaskHeartbeat</a> requests received. The <code>taskStartToCloseTimeout</code> is also specified in <a>RegisterActivityType</a>.</p> </note> <note> <p>This operation is only useful for long-lived activities to report liveliness of the task and to determine if a cancellation is being attempted.</p> </note> <important> <p>If the <code>cancelRequested</code> flag returns <code>true</code>, a cancellation is being attempted. If the worker can cancel the activity, it should respond with <a>RespondActivityTaskCanceled</a>. Otherwise, it should ignore the cancellation request.</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603382 = header.getOrDefault("X-Amz-Date")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Date", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Security-Token")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Security-Token", valid_603383
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603384 = header.getOrDefault("X-Amz-Target")
  valid_603384 = validateParameter(valid_603384, JString, required = true, default = newJString(
      "SimpleWorkflowService.RecordActivityTaskHeartbeat"))
  if valid_603384 != nil:
    section.add "X-Amz-Target", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Content-Sha256", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Algorithm")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Algorithm", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-Signature")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Signature", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-SignedHeaders", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Credential")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Credential", valid_603389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603391: Call_RecordActivityTaskHeartbeat_603379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by activity workers to report to the service that the <a>ActivityTask</a> represented by the specified <code>taskToken</code> is still making progress. The worker can also specify details of the progress, for example percent complete, using the <code>details</code> parameter. This action can also be used by the worker as a mechanism to check if cancellation is being requested for the activity task. If a cancellation is being attempted for the specified task, then the boolean <code>cancelRequested</code> flag returned by the service is set to <code>true</code>.</p> <p>This action resets the <code>taskHeartbeatTimeout</code> clock. The <code>taskHeartbeatTimeout</code> is specified in <a>RegisterActivityType</a>.</p> <p>This action doesn't in itself create an event in the workflow execution history. However, if the task times out, the workflow execution history contains a <code>ActivityTaskTimedOut</code> event that contains the information from the last heartbeat generated by the activity worker.</p> <note> <p>The <code>taskStartToCloseTimeout</code> of an activity type is the maximum duration of an activity task, regardless of the number of <a>RecordActivityTaskHeartbeat</a> requests received. The <code>taskStartToCloseTimeout</code> is also specified in <a>RegisterActivityType</a>.</p> </note> <note> <p>This operation is only useful for long-lived activities to report liveliness of the task and to determine if a cancellation is being attempted.</p> </note> <important> <p>If the <code>cancelRequested</code> flag returns <code>true</code>, a cancellation is being attempted. If the worker can cancel the activity, it should respond with <a>RespondActivityTaskCanceled</a>. Otherwise, it should ignore the cancellation request.</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603391.validator(path, query, header, formData, body)
  let scheme = call_603391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603391.url(scheme.get, call_603391.host, call_603391.base,
                         call_603391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603391, url, valid)

proc call*(call_603392: Call_RecordActivityTaskHeartbeat_603379; body: JsonNode): Recallable =
  ## recordActivityTaskHeartbeat
  ## <p>Used by activity workers to report to the service that the <a>ActivityTask</a> represented by the specified <code>taskToken</code> is still making progress. The worker can also specify details of the progress, for example percent complete, using the <code>details</code> parameter. This action can also be used by the worker as a mechanism to check if cancellation is being requested for the activity task. If a cancellation is being attempted for the specified task, then the boolean <code>cancelRequested</code> flag returned by the service is set to <code>true</code>.</p> <p>This action resets the <code>taskHeartbeatTimeout</code> clock. The <code>taskHeartbeatTimeout</code> is specified in <a>RegisterActivityType</a>.</p> <p>This action doesn't in itself create an event in the workflow execution history. However, if the task times out, the workflow execution history contains a <code>ActivityTaskTimedOut</code> event that contains the information from the last heartbeat generated by the activity worker.</p> <note> <p>The <code>taskStartToCloseTimeout</code> of an activity type is the maximum duration of an activity task, regardless of the number of <a>RecordActivityTaskHeartbeat</a> requests received. The <code>taskStartToCloseTimeout</code> is also specified in <a>RegisterActivityType</a>.</p> </note> <note> <p>This operation is only useful for long-lived activities to report liveliness of the task and to determine if a cancellation is being attempted.</p> </note> <important> <p>If the <code>cancelRequested</code> flag returns <code>true</code>, a cancellation is being attempted. If the worker can cancel the activity, it should respond with <a>RespondActivityTaskCanceled</a>. Otherwise, it should ignore the cancellation request.</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603393 = newJObject()
  if body != nil:
    body_603393 = body
  result = call_603392.call(nil, nil, nil, nil, body_603393)

var recordActivityTaskHeartbeat* = Call_RecordActivityTaskHeartbeat_603379(
    name: "recordActivityTaskHeartbeat", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.RecordActivityTaskHeartbeat",
    validator: validate_RecordActivityTaskHeartbeat_603380, base: "/",
    url: url_RecordActivityTaskHeartbeat_603381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterActivityType_603394 = ref object of OpenApiRestCall_602466
proc url_RegisterActivityType_603396(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterActivityType_603395(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Registers a new <i>activity type</i> along with its configuration settings in the specified domain.</p> <important> <p>A <code>TypeAlreadyExists</code> fault is returned if the type already exists in the domain. You cannot change any configuration settings of the type after its registration, and it must be registered as a new version.</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>defaultTaskList.name</code>: String constraint. The key is <code>swf:defaultTaskList.name</code>.</p> </li> <li> <p> <code>name</code>: String constraint. The key is <code>swf:name</code>.</p> </li> <li> <p> <code>version</code>: String constraint. The key is <code>swf:version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603397 = header.getOrDefault("X-Amz-Date")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Date", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Security-Token")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Security-Token", valid_603398
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603399 = header.getOrDefault("X-Amz-Target")
  valid_603399 = validateParameter(valid_603399, JString, required = true, default = newJString(
      "SimpleWorkflowService.RegisterActivityType"))
  if valid_603399 != nil:
    section.add "X-Amz-Target", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Content-Sha256", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Algorithm")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Algorithm", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Signature")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Signature", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-SignedHeaders", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Credential")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Credential", valid_603404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603406: Call_RegisterActivityType_603394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a new <i>activity type</i> along with its configuration settings in the specified domain.</p> <important> <p>A <code>TypeAlreadyExists</code> fault is returned if the type already exists in the domain. You cannot change any configuration settings of the type after its registration, and it must be registered as a new version.</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>defaultTaskList.name</code>: String constraint. The key is <code>swf:defaultTaskList.name</code>.</p> </li> <li> <p> <code>name</code>: String constraint. The key is <code>swf:name</code>.</p> </li> <li> <p> <code>version</code>: String constraint. The key is <code>swf:version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603406.validator(path, query, header, formData, body)
  let scheme = call_603406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603406.url(scheme.get, call_603406.host, call_603406.base,
                         call_603406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603406, url, valid)

proc call*(call_603407: Call_RegisterActivityType_603394; body: JsonNode): Recallable =
  ## registerActivityType
  ## <p>Registers a new <i>activity type</i> along with its configuration settings in the specified domain.</p> <important> <p>A <code>TypeAlreadyExists</code> fault is returned if the type already exists in the domain. You cannot change any configuration settings of the type after its registration, and it must be registered as a new version.</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>defaultTaskList.name</code>: String constraint. The key is <code>swf:defaultTaskList.name</code>.</p> </li> <li> <p> <code>name</code>: String constraint. The key is <code>swf:name</code>.</p> </li> <li> <p> <code>version</code>: String constraint. The key is <code>swf:version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603408 = newJObject()
  if body != nil:
    body_603408 = body
  result = call_603407.call(nil, nil, nil, nil, body_603408)

var registerActivityType* = Call_RegisterActivityType_603394(
    name: "registerActivityType", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.RegisterActivityType",
    validator: validate_RegisterActivityType_603395, base: "/",
    url: url_RegisterActivityType_603396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDomain_603409 = ref object of OpenApiRestCall_602466
proc url_RegisterDomain_603411(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterDomain_603410(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Registers a new domain.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>You cannot use an IAM policy to control domain access for this action. The name of the domain being registered is available as the resource of this action.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603412 = header.getOrDefault("X-Amz-Date")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Date", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Security-Token")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Security-Token", valid_603413
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603414 = header.getOrDefault("X-Amz-Target")
  valid_603414 = validateParameter(valid_603414, JString, required = true, default = newJString(
      "SimpleWorkflowService.RegisterDomain"))
  if valid_603414 != nil:
    section.add "X-Amz-Target", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Content-Sha256", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Algorithm")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Algorithm", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Signature")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Signature", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-SignedHeaders", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Credential")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Credential", valid_603419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603421: Call_RegisterDomain_603409; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a new domain.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>You cannot use an IAM policy to control domain access for this action. The name of the domain being registered is available as the resource of this action.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603421.validator(path, query, header, formData, body)
  let scheme = call_603421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603421.url(scheme.get, call_603421.host, call_603421.base,
                         call_603421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603421, url, valid)

proc call*(call_603422: Call_RegisterDomain_603409; body: JsonNode): Recallable =
  ## registerDomain
  ## <p>Registers a new domain.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>You cannot use an IAM policy to control domain access for this action. The name of the domain being registered is available as the resource of this action.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603423 = newJObject()
  if body != nil:
    body_603423 = body
  result = call_603422.call(nil, nil, nil, nil, body_603423)

var registerDomain* = Call_RegisterDomain_603409(name: "registerDomain",
    meth: HttpMethod.HttpPost, host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.RegisterDomain",
    validator: validate_RegisterDomain_603410, base: "/", url: url_RegisterDomain_603411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterWorkflowType_603424 = ref object of OpenApiRestCall_602466
proc url_RegisterWorkflowType_603426(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterWorkflowType_603425(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Registers a new <i>workflow type</i> and its configuration settings in the specified domain.</p> <p>The retention period for the workflow history is set by the <a>RegisterDomain</a> action.</p> <important> <p>If the type already exists, then a <code>TypeAlreadyExists</code> fault is returned. You cannot change the configuration settings of a workflow type once it is registered and it must be registered as a new version.</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>defaultTaskList.name</code>: String constraint. The key is <code>swf:defaultTaskList.name</code>.</p> </li> <li> <p> <code>name</code>: String constraint. The key is <code>swf:name</code>.</p> </li> <li> <p> <code>version</code>: String constraint. The key is <code>swf:version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603427 = header.getOrDefault("X-Amz-Date")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Date", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Security-Token")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Security-Token", valid_603428
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603429 = header.getOrDefault("X-Amz-Target")
  valid_603429 = validateParameter(valid_603429, JString, required = true, default = newJString(
      "SimpleWorkflowService.RegisterWorkflowType"))
  if valid_603429 != nil:
    section.add "X-Amz-Target", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Content-Sha256", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Algorithm")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Algorithm", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-Signature")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Signature", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-SignedHeaders", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Credential")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Credential", valid_603434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603436: Call_RegisterWorkflowType_603424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a new <i>workflow type</i> and its configuration settings in the specified domain.</p> <p>The retention period for the workflow history is set by the <a>RegisterDomain</a> action.</p> <important> <p>If the type already exists, then a <code>TypeAlreadyExists</code> fault is returned. You cannot change the configuration settings of a workflow type once it is registered and it must be registered as a new version.</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>defaultTaskList.name</code>: String constraint. The key is <code>swf:defaultTaskList.name</code>.</p> </li> <li> <p> <code>name</code>: String constraint. The key is <code>swf:name</code>.</p> </li> <li> <p> <code>version</code>: String constraint. The key is <code>swf:version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603436.validator(path, query, header, formData, body)
  let scheme = call_603436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603436.url(scheme.get, call_603436.host, call_603436.base,
                         call_603436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603436, url, valid)

proc call*(call_603437: Call_RegisterWorkflowType_603424; body: JsonNode): Recallable =
  ## registerWorkflowType
  ## <p>Registers a new <i>workflow type</i> and its configuration settings in the specified domain.</p> <p>The retention period for the workflow history is set by the <a>RegisterDomain</a> action.</p> <important> <p>If the type already exists, then a <code>TypeAlreadyExists</code> fault is returned. You cannot change the configuration settings of a workflow type once it is registered and it must be registered as a new version.</p> </important> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>defaultTaskList.name</code>: String constraint. The key is <code>swf:defaultTaskList.name</code>.</p> </li> <li> <p> <code>name</code>: String constraint. The key is <code>swf:name</code>.</p> </li> <li> <p> <code>version</code>: String constraint. The key is <code>swf:version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603438 = newJObject()
  if body != nil:
    body_603438 = body
  result = call_603437.call(nil, nil, nil, nil, body_603438)

var registerWorkflowType* = Call_RegisterWorkflowType_603424(
    name: "registerWorkflowType", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.RegisterWorkflowType",
    validator: validate_RegisterWorkflowType_603425, base: "/",
    url: url_RegisterWorkflowType_603426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RequestCancelWorkflowExecution_603439 = ref object of OpenApiRestCall_602466
proc url_RequestCancelWorkflowExecution_603441(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RequestCancelWorkflowExecution_603440(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Records a <code>WorkflowExecutionCancelRequested</code> event in the currently running workflow execution identified by the given domain, workflowId, and runId. This logically requests the cancellation of the workflow execution as a whole. It is up to the decider to take appropriate actions when it receives an execution history with this event.</p> <note> <p>If the runId isn't specified, the <code>WorkflowExecutionCancelRequested</code> event is recorded in the history of the current open workflow execution with the specified workflowId in the domain.</p> </note> <note> <p>Because this action allows the workflow to properly clean up and gracefully close, it should be used instead of <a>TerminateWorkflowExecution</a> when possible.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603442 = header.getOrDefault("X-Amz-Date")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Date", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Security-Token")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Security-Token", valid_603443
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603444 = header.getOrDefault("X-Amz-Target")
  valid_603444 = validateParameter(valid_603444, JString, required = true, default = newJString(
      "SimpleWorkflowService.RequestCancelWorkflowExecution"))
  if valid_603444 != nil:
    section.add "X-Amz-Target", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Content-Sha256", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Algorithm")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Algorithm", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-Signature")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Signature", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-SignedHeaders", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-Credential")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Credential", valid_603449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603451: Call_RequestCancelWorkflowExecution_603439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Records a <code>WorkflowExecutionCancelRequested</code> event in the currently running workflow execution identified by the given domain, workflowId, and runId. This logically requests the cancellation of the workflow execution as a whole. It is up to the decider to take appropriate actions when it receives an execution history with this event.</p> <note> <p>If the runId isn't specified, the <code>WorkflowExecutionCancelRequested</code> event is recorded in the history of the current open workflow execution with the specified workflowId in the domain.</p> </note> <note> <p>Because this action allows the workflow to properly clean up and gracefully close, it should be used instead of <a>TerminateWorkflowExecution</a> when possible.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603451.validator(path, query, header, formData, body)
  let scheme = call_603451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603451.url(scheme.get, call_603451.host, call_603451.base,
                         call_603451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603451, url, valid)

proc call*(call_603452: Call_RequestCancelWorkflowExecution_603439; body: JsonNode): Recallable =
  ## requestCancelWorkflowExecution
  ## <p>Records a <code>WorkflowExecutionCancelRequested</code> event in the currently running workflow execution identified by the given domain, workflowId, and runId. This logically requests the cancellation of the workflow execution as a whole. It is up to the decider to take appropriate actions when it receives an execution history with this event.</p> <note> <p>If the runId isn't specified, the <code>WorkflowExecutionCancelRequested</code> event is recorded in the history of the current open workflow execution with the specified workflowId in the domain.</p> </note> <note> <p>Because this action allows the workflow to properly clean up and gracefully close, it should be used instead of <a>TerminateWorkflowExecution</a> when possible.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603453 = newJObject()
  if body != nil:
    body_603453 = body
  result = call_603452.call(nil, nil, nil, nil, body_603453)

var requestCancelWorkflowExecution* = Call_RequestCancelWorkflowExecution_603439(
    name: "requestCancelWorkflowExecution", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com", route: "/#X-Amz-Target=SimpleWorkflowService.RequestCancelWorkflowExecution",
    validator: validate_RequestCancelWorkflowExecution_603440, base: "/",
    url: url_RequestCancelWorkflowExecution_603441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RespondActivityTaskCanceled_603454 = ref object of OpenApiRestCall_602466
proc url_RespondActivityTaskCanceled_603456(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RespondActivityTaskCanceled_603455(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Used by workers to tell the service that the <a>ActivityTask</a> identified by the <code>taskToken</code> was successfully canceled. Additional <code>details</code> can be provided using the <code>details</code> argument.</p> <p>These <code>details</code> (if provided) appear in the <code>ActivityTaskCanceled</code> event added to the workflow history.</p> <important> <p>Only use this operation if the <code>canceled</code> flag of a <a>RecordActivityTaskHeartbeat</a> request returns <code>true</code> and if the activity can be safely undone or abandoned.</p> </important> <p>A task is considered open from the time that it is scheduled until it is closed. Therefore a task is reported as open while a worker is processing it. A task is closed after it has been specified in a call to <a>RespondActivityTaskCompleted</a>, RespondActivityTaskCanceled, <a>RespondActivityTaskFailed</a>, or the task has <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-basic.html#swf-dev-timeout-types">timed out</a>.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603457 = header.getOrDefault("X-Amz-Date")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Date", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Security-Token")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Security-Token", valid_603458
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603459 = header.getOrDefault("X-Amz-Target")
  valid_603459 = validateParameter(valid_603459, JString, required = true, default = newJString(
      "SimpleWorkflowService.RespondActivityTaskCanceled"))
  if valid_603459 != nil:
    section.add "X-Amz-Target", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Content-Sha256", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Algorithm")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Algorithm", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Signature")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Signature", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-SignedHeaders", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Credential")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Credential", valid_603464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603466: Call_RespondActivityTaskCanceled_603454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by workers to tell the service that the <a>ActivityTask</a> identified by the <code>taskToken</code> was successfully canceled. Additional <code>details</code> can be provided using the <code>details</code> argument.</p> <p>These <code>details</code> (if provided) appear in the <code>ActivityTaskCanceled</code> event added to the workflow history.</p> <important> <p>Only use this operation if the <code>canceled</code> flag of a <a>RecordActivityTaskHeartbeat</a> request returns <code>true</code> and if the activity can be safely undone or abandoned.</p> </important> <p>A task is considered open from the time that it is scheduled until it is closed. Therefore a task is reported as open while a worker is processing it. A task is closed after it has been specified in a call to <a>RespondActivityTaskCompleted</a>, RespondActivityTaskCanceled, <a>RespondActivityTaskFailed</a>, or the task has <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-basic.html#swf-dev-timeout-types">timed out</a>.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603466.validator(path, query, header, formData, body)
  let scheme = call_603466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603466.url(scheme.get, call_603466.host, call_603466.base,
                         call_603466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603466, url, valid)

proc call*(call_603467: Call_RespondActivityTaskCanceled_603454; body: JsonNode): Recallable =
  ## respondActivityTaskCanceled
  ## <p>Used by workers to tell the service that the <a>ActivityTask</a> identified by the <code>taskToken</code> was successfully canceled. Additional <code>details</code> can be provided using the <code>details</code> argument.</p> <p>These <code>details</code> (if provided) appear in the <code>ActivityTaskCanceled</code> event added to the workflow history.</p> <important> <p>Only use this operation if the <code>canceled</code> flag of a <a>RecordActivityTaskHeartbeat</a> request returns <code>true</code> and if the activity can be safely undone or abandoned.</p> </important> <p>A task is considered open from the time that it is scheduled until it is closed. Therefore a task is reported as open while a worker is processing it. A task is closed after it has been specified in a call to <a>RespondActivityTaskCompleted</a>, RespondActivityTaskCanceled, <a>RespondActivityTaskFailed</a>, or the task has <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-basic.html#swf-dev-timeout-types">timed out</a>.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603468 = newJObject()
  if body != nil:
    body_603468 = body
  result = call_603467.call(nil, nil, nil, nil, body_603468)

var respondActivityTaskCanceled* = Call_RespondActivityTaskCanceled_603454(
    name: "respondActivityTaskCanceled", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.RespondActivityTaskCanceled",
    validator: validate_RespondActivityTaskCanceled_603455, base: "/",
    url: url_RespondActivityTaskCanceled_603456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RespondActivityTaskCompleted_603469 = ref object of OpenApiRestCall_602466
proc url_RespondActivityTaskCompleted_603471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RespondActivityTaskCompleted_603470(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Used by workers to tell the service that the <a>ActivityTask</a> identified by the <code>taskToken</code> completed successfully with a <code>result</code> (if provided). The <code>result</code> appears in the <code>ActivityTaskCompleted</code> event in the workflow history.</p> <important> <p>If the requested task doesn't complete successfully, use <a>RespondActivityTaskFailed</a> instead. If the worker finds that the task is canceled through the <code>canceled</code> flag returned by <a>RecordActivityTaskHeartbeat</a>, it should cancel the task, clean up and then call <a>RespondActivityTaskCanceled</a>.</p> </important> <p>A task is considered open from the time that it is scheduled until it is closed. Therefore a task is reported as open while a worker is processing it. A task is closed after it has been specified in a call to RespondActivityTaskCompleted, <a>RespondActivityTaskCanceled</a>, <a>RespondActivityTaskFailed</a>, or the task has <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-basic.html#swf-dev-timeout-types">timed out</a>.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603472 = header.getOrDefault("X-Amz-Date")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Date", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Security-Token")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Security-Token", valid_603473
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603474 = header.getOrDefault("X-Amz-Target")
  valid_603474 = validateParameter(valid_603474, JString, required = true, default = newJString(
      "SimpleWorkflowService.RespondActivityTaskCompleted"))
  if valid_603474 != nil:
    section.add "X-Amz-Target", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Content-Sha256", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Algorithm")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Algorithm", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Signature")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Signature", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-SignedHeaders", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Credential")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Credential", valid_603479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603481: Call_RespondActivityTaskCompleted_603469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by workers to tell the service that the <a>ActivityTask</a> identified by the <code>taskToken</code> completed successfully with a <code>result</code> (if provided). The <code>result</code> appears in the <code>ActivityTaskCompleted</code> event in the workflow history.</p> <important> <p>If the requested task doesn't complete successfully, use <a>RespondActivityTaskFailed</a> instead. If the worker finds that the task is canceled through the <code>canceled</code> flag returned by <a>RecordActivityTaskHeartbeat</a>, it should cancel the task, clean up and then call <a>RespondActivityTaskCanceled</a>.</p> </important> <p>A task is considered open from the time that it is scheduled until it is closed. Therefore a task is reported as open while a worker is processing it. A task is closed after it has been specified in a call to RespondActivityTaskCompleted, <a>RespondActivityTaskCanceled</a>, <a>RespondActivityTaskFailed</a>, or the task has <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-basic.html#swf-dev-timeout-types">timed out</a>.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603481.validator(path, query, header, formData, body)
  let scheme = call_603481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603481.url(scheme.get, call_603481.host, call_603481.base,
                         call_603481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603481, url, valid)

proc call*(call_603482: Call_RespondActivityTaskCompleted_603469; body: JsonNode): Recallable =
  ## respondActivityTaskCompleted
  ## <p>Used by workers to tell the service that the <a>ActivityTask</a> identified by the <code>taskToken</code> completed successfully with a <code>result</code> (if provided). The <code>result</code> appears in the <code>ActivityTaskCompleted</code> event in the workflow history.</p> <important> <p>If the requested task doesn't complete successfully, use <a>RespondActivityTaskFailed</a> instead. If the worker finds that the task is canceled through the <code>canceled</code> flag returned by <a>RecordActivityTaskHeartbeat</a>, it should cancel the task, clean up and then call <a>RespondActivityTaskCanceled</a>.</p> </important> <p>A task is considered open from the time that it is scheduled until it is closed. Therefore a task is reported as open while a worker is processing it. A task is closed after it has been specified in a call to RespondActivityTaskCompleted, <a>RespondActivityTaskCanceled</a>, <a>RespondActivityTaskFailed</a>, or the task has <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-basic.html#swf-dev-timeout-types">timed out</a>.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603483 = newJObject()
  if body != nil:
    body_603483 = body
  result = call_603482.call(nil, nil, nil, nil, body_603483)

var respondActivityTaskCompleted* = Call_RespondActivityTaskCompleted_603469(
    name: "respondActivityTaskCompleted", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.RespondActivityTaskCompleted",
    validator: validate_RespondActivityTaskCompleted_603470, base: "/",
    url: url_RespondActivityTaskCompleted_603471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RespondActivityTaskFailed_603484 = ref object of OpenApiRestCall_602466
proc url_RespondActivityTaskFailed_603486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RespondActivityTaskFailed_603485(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Used by workers to tell the service that the <a>ActivityTask</a> identified by the <code>taskToken</code> has failed with <code>reason</code> (if specified). The <code>reason</code> and <code>details</code> appear in the <code>ActivityTaskFailed</code> event added to the workflow history.</p> <p>A task is considered open from the time that it is scheduled until it is closed. Therefore a task is reported as open while a worker is processing it. A task is closed after it has been specified in a call to <a>RespondActivityTaskCompleted</a>, <a>RespondActivityTaskCanceled</a>, RespondActivityTaskFailed, or the task has <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-basic.html#swf-dev-timeout-types">timed out</a>.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603487 = header.getOrDefault("X-Amz-Date")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Date", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Security-Token")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Security-Token", valid_603488
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603489 = header.getOrDefault("X-Amz-Target")
  valid_603489 = validateParameter(valid_603489, JString, required = true, default = newJString(
      "SimpleWorkflowService.RespondActivityTaskFailed"))
  if valid_603489 != nil:
    section.add "X-Amz-Target", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Content-Sha256", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Algorithm")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Algorithm", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Signature")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Signature", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-SignedHeaders", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Credential")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Credential", valid_603494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603496: Call_RespondActivityTaskFailed_603484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by workers to tell the service that the <a>ActivityTask</a> identified by the <code>taskToken</code> has failed with <code>reason</code> (if specified). The <code>reason</code> and <code>details</code> appear in the <code>ActivityTaskFailed</code> event added to the workflow history.</p> <p>A task is considered open from the time that it is scheduled until it is closed. Therefore a task is reported as open while a worker is processing it. A task is closed after it has been specified in a call to <a>RespondActivityTaskCompleted</a>, <a>RespondActivityTaskCanceled</a>, RespondActivityTaskFailed, or the task has <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-basic.html#swf-dev-timeout-types">timed out</a>.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603496.validator(path, query, header, formData, body)
  let scheme = call_603496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603496.url(scheme.get, call_603496.host, call_603496.base,
                         call_603496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603496, url, valid)

proc call*(call_603497: Call_RespondActivityTaskFailed_603484; body: JsonNode): Recallable =
  ## respondActivityTaskFailed
  ## <p>Used by workers to tell the service that the <a>ActivityTask</a> identified by the <code>taskToken</code> has failed with <code>reason</code> (if specified). The <code>reason</code> and <code>details</code> appear in the <code>ActivityTaskFailed</code> event added to the workflow history.</p> <p>A task is considered open from the time that it is scheduled until it is closed. Therefore a task is reported as open while a worker is processing it. A task is closed after it has been specified in a call to <a>RespondActivityTaskCompleted</a>, <a>RespondActivityTaskCanceled</a>, RespondActivityTaskFailed, or the task has <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dg-basic.html#swf-dev-timeout-types">timed out</a>.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603498 = newJObject()
  if body != nil:
    body_603498 = body
  result = call_603497.call(nil, nil, nil, nil, body_603498)

var respondActivityTaskFailed* = Call_RespondActivityTaskFailed_603484(
    name: "respondActivityTaskFailed", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.RespondActivityTaskFailed",
    validator: validate_RespondActivityTaskFailed_603485, base: "/",
    url: url_RespondActivityTaskFailed_603486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RespondDecisionTaskCompleted_603499 = ref object of OpenApiRestCall_602466
proc url_RespondDecisionTaskCompleted_603501(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RespondDecisionTaskCompleted_603500(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Used by deciders to tell the service that the <a>DecisionTask</a> identified by the <code>taskToken</code> has successfully completed. The <code>decisions</code> argument specifies the list of decisions made while processing the task.</p> <p>A <code>DecisionTaskCompleted</code> event is added to the workflow history. The <code>executionContext</code> specified is attached to the event in the workflow execution history.</p> <p> <b>Access Control</b> </p> <p>If an IAM policy grants permission to use <code>RespondDecisionTaskCompleted</code>, it can express permissions for the list of decisions in the <code>decisions</code> parameter. Each of the decisions has one or more parameters, much like a regular API call. To allow for policies to be as readable as possible, you can express permissions on decisions as if they were actual API calls, including applying conditions to some parameters. For more information, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603502 = header.getOrDefault("X-Amz-Date")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Date", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Security-Token")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Security-Token", valid_603503
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603504 = header.getOrDefault("X-Amz-Target")
  valid_603504 = validateParameter(valid_603504, JString, required = true, default = newJString(
      "SimpleWorkflowService.RespondDecisionTaskCompleted"))
  if valid_603504 != nil:
    section.add "X-Amz-Target", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Content-Sha256", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Algorithm")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Algorithm", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Signature")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Signature", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-SignedHeaders", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Credential")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Credential", valid_603509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603511: Call_RespondDecisionTaskCompleted_603499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Used by deciders to tell the service that the <a>DecisionTask</a> identified by the <code>taskToken</code> has successfully completed. The <code>decisions</code> argument specifies the list of decisions made while processing the task.</p> <p>A <code>DecisionTaskCompleted</code> event is added to the workflow history. The <code>executionContext</code> specified is attached to the event in the workflow execution history.</p> <p> <b>Access Control</b> </p> <p>If an IAM policy grants permission to use <code>RespondDecisionTaskCompleted</code>, it can express permissions for the list of decisions in the <code>decisions</code> parameter. Each of the decisions has one or more parameters, much like a regular API call. To allow for policies to be as readable as possible, you can express permissions on decisions as if they were actual API calls, including applying conditions to some parameters. For more information, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603511.validator(path, query, header, formData, body)
  let scheme = call_603511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603511.url(scheme.get, call_603511.host, call_603511.base,
                         call_603511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603511, url, valid)

proc call*(call_603512: Call_RespondDecisionTaskCompleted_603499; body: JsonNode): Recallable =
  ## respondDecisionTaskCompleted
  ## <p>Used by deciders to tell the service that the <a>DecisionTask</a> identified by the <code>taskToken</code> has successfully completed. The <code>decisions</code> argument specifies the list of decisions made while processing the task.</p> <p>A <code>DecisionTaskCompleted</code> event is added to the workflow history. The <code>executionContext</code> specified is attached to the event in the workflow execution history.</p> <p> <b>Access Control</b> </p> <p>If an IAM policy grants permission to use <code>RespondDecisionTaskCompleted</code>, it can express permissions for the list of decisions in the <code>decisions</code> parameter. Each of the decisions has one or more parameters, much like a regular API call. To allow for policies to be as readable as possible, you can express permissions on decisions as if they were actual API calls, including applying conditions to some parameters. For more information, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603513 = newJObject()
  if body != nil:
    body_603513 = body
  result = call_603512.call(nil, nil, nil, nil, body_603513)

var respondDecisionTaskCompleted* = Call_RespondDecisionTaskCompleted_603499(
    name: "respondDecisionTaskCompleted", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.RespondDecisionTaskCompleted",
    validator: validate_RespondDecisionTaskCompleted_603500, base: "/",
    url: url_RespondDecisionTaskCompleted_603501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SignalWorkflowExecution_603514 = ref object of OpenApiRestCall_602466
proc url_SignalWorkflowExecution_603516(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SignalWorkflowExecution_603515(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Records a <code>WorkflowExecutionSignaled</code> event in the workflow execution history and creates a decision task for the workflow execution identified by the given domain, workflowId and runId. The event is recorded with the specified user defined signalName and input (if provided).</p> <note> <p>If a runId isn't specified, then the <code>WorkflowExecutionSignaled</code> event is recorded in the history of the current open workflow with the matching workflowId in the domain.</p> </note> <note> <p>If the specified workflow execution isn't open, this method fails with <code>UnknownResource</code>.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603517 = header.getOrDefault("X-Amz-Date")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Date", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Security-Token")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Security-Token", valid_603518
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603519 = header.getOrDefault("X-Amz-Target")
  valid_603519 = validateParameter(valid_603519, JString, required = true, default = newJString(
      "SimpleWorkflowService.SignalWorkflowExecution"))
  if valid_603519 != nil:
    section.add "X-Amz-Target", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Content-Sha256", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Algorithm")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Algorithm", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Signature")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Signature", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-SignedHeaders", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Credential")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Credential", valid_603524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603526: Call_SignalWorkflowExecution_603514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Records a <code>WorkflowExecutionSignaled</code> event in the workflow execution history and creates a decision task for the workflow execution identified by the given domain, workflowId and runId. The event is recorded with the specified user defined signalName and input (if provided).</p> <note> <p>If a runId isn't specified, then the <code>WorkflowExecutionSignaled</code> event is recorded in the history of the current open workflow with the matching workflowId in the domain.</p> </note> <note> <p>If the specified workflow execution isn't open, this method fails with <code>UnknownResource</code>.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603526.validator(path, query, header, formData, body)
  let scheme = call_603526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603526.url(scheme.get, call_603526.host, call_603526.base,
                         call_603526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603526, url, valid)

proc call*(call_603527: Call_SignalWorkflowExecution_603514; body: JsonNode): Recallable =
  ## signalWorkflowExecution
  ## <p>Records a <code>WorkflowExecutionSignaled</code> event in the workflow execution history and creates a decision task for the workflow execution identified by the given domain, workflowId and runId. The event is recorded with the specified user defined signalName and input (if provided).</p> <note> <p>If a runId isn't specified, then the <code>WorkflowExecutionSignaled</code> event is recorded in the history of the current open workflow with the matching workflowId in the domain.</p> </note> <note> <p>If the specified workflow execution isn't open, this method fails with <code>UnknownResource</code>.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603528 = newJObject()
  if body != nil:
    body_603528 = body
  result = call_603527.call(nil, nil, nil, nil, body_603528)

var signalWorkflowExecution* = Call_SignalWorkflowExecution_603514(
    name: "signalWorkflowExecution", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.SignalWorkflowExecution",
    validator: validate_SignalWorkflowExecution_603515, base: "/",
    url: url_SignalWorkflowExecution_603516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkflowExecution_603529 = ref object of OpenApiRestCall_602466
proc url_StartWorkflowExecution_603531(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartWorkflowExecution_603530(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts an execution of the workflow type in the specified domain using the provided <code>workflowId</code> and input data.</p> <p>This action returns the newly started workflow execution.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagList.member.0</code>: The key is <code>swf:tagList.member.0</code>.</p> </li> <li> <p> <code>tagList.member.1</code>: The key is <code>swf:tagList.member.1</code>.</p> </li> <li> <p> <code>tagList.member.2</code>: The key is <code>swf:tagList.member.2</code>.</p> </li> <li> <p> <code>tagList.member.3</code>: The key is <code>swf:tagList.member.3</code>.</p> </li> <li> <p> <code>tagList.member.4</code>: The key is <code>swf:tagList.member.4</code>.</p> </li> <li> <p> <code>taskList</code>: String constraint. The key is <code>swf:taskList.name</code>.</p> </li> <li> <p> <code>workflowType.name</code>: String constraint. The key is <code>swf:workflowType.name</code>.</p> </li> <li> <p> <code>workflowType.version</code>: String constraint. The key is <code>swf:workflowType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603532 = header.getOrDefault("X-Amz-Date")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Date", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Security-Token")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Security-Token", valid_603533
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603534 = header.getOrDefault("X-Amz-Target")
  valid_603534 = validateParameter(valid_603534, JString, required = true, default = newJString(
      "SimpleWorkflowService.StartWorkflowExecution"))
  if valid_603534 != nil:
    section.add "X-Amz-Target", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Content-Sha256", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Algorithm")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Algorithm", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Signature")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Signature", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-SignedHeaders", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Credential")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Credential", valid_603539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603541: Call_StartWorkflowExecution_603529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an execution of the workflow type in the specified domain using the provided <code>workflowId</code> and input data.</p> <p>This action returns the newly started workflow execution.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagList.member.0</code>: The key is <code>swf:tagList.member.0</code>.</p> </li> <li> <p> <code>tagList.member.1</code>: The key is <code>swf:tagList.member.1</code>.</p> </li> <li> <p> <code>tagList.member.2</code>: The key is <code>swf:tagList.member.2</code>.</p> </li> <li> <p> <code>tagList.member.3</code>: The key is <code>swf:tagList.member.3</code>.</p> </li> <li> <p> <code>tagList.member.4</code>: The key is <code>swf:tagList.member.4</code>.</p> </li> <li> <p> <code>taskList</code>: String constraint. The key is <code>swf:taskList.name</code>.</p> </li> <li> <p> <code>workflowType.name</code>: String constraint. The key is <code>swf:workflowType.name</code>.</p> </li> <li> <p> <code>workflowType.version</code>: String constraint. The key is <code>swf:workflowType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603541.validator(path, query, header, formData, body)
  let scheme = call_603541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603541.url(scheme.get, call_603541.host, call_603541.base,
                         call_603541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603541, url, valid)

proc call*(call_603542: Call_StartWorkflowExecution_603529; body: JsonNode): Recallable =
  ## startWorkflowExecution
  ## <p>Starts an execution of the workflow type in the specified domain using the provided <code>workflowId</code> and input data.</p> <p>This action returns the newly started workflow execution.</p> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>tagList.member.0</code>: The key is <code>swf:tagList.member.0</code>.</p> </li> <li> <p> <code>tagList.member.1</code>: The key is <code>swf:tagList.member.1</code>.</p> </li> <li> <p> <code>tagList.member.2</code>: The key is <code>swf:tagList.member.2</code>.</p> </li> <li> <p> <code>tagList.member.3</code>: The key is <code>swf:tagList.member.3</code>.</p> </li> <li> <p> <code>tagList.member.4</code>: The key is <code>swf:tagList.member.4</code>.</p> </li> <li> <p> <code>taskList</code>: String constraint. The key is <code>swf:taskList.name</code>.</p> </li> <li> <p> <code>workflowType.name</code>: String constraint. The key is <code>swf:workflowType.name</code>.</p> </li> <li> <p> <code>workflowType.version</code>: String constraint. The key is <code>swf:workflowType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603543 = newJObject()
  if body != nil:
    body_603543 = body
  result = call_603542.call(nil, nil, nil, nil, body_603543)

var startWorkflowExecution* = Call_StartWorkflowExecution_603529(
    name: "startWorkflowExecution", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.StartWorkflowExecution",
    validator: validate_StartWorkflowExecution_603530, base: "/",
    url: url_StartWorkflowExecution_603531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603544 = ref object of OpenApiRestCall_602466
proc url_TagResource_603546(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_603545(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Add a tag to a Amazon SWF domain.</p> <note> <p>Amazon SWF supports a maximum of 50 tags per resource.</p> </note>
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
  var valid_603547 = header.getOrDefault("X-Amz-Date")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Date", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Security-Token")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Security-Token", valid_603548
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603549 = header.getOrDefault("X-Amz-Target")
  valid_603549 = validateParameter(valid_603549, JString, required = true, default = newJString(
      "SimpleWorkflowService.TagResource"))
  if valid_603549 != nil:
    section.add "X-Amz-Target", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Content-Sha256", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Algorithm")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Algorithm", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Signature")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Signature", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-SignedHeaders", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Credential")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Credential", valid_603554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603556: Call_TagResource_603544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add a tag to a Amazon SWF domain.</p> <note> <p>Amazon SWF supports a maximum of 50 tags per resource.</p> </note>
  ## 
  let valid = call_603556.validator(path, query, header, formData, body)
  let scheme = call_603556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603556.url(scheme.get, call_603556.host, call_603556.base,
                         call_603556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603556, url, valid)

proc call*(call_603557: Call_TagResource_603544; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add a tag to a Amazon SWF domain.</p> <note> <p>Amazon SWF supports a maximum of 50 tags per resource.</p> </note>
  ##   body: JObject (required)
  var body_603558 = newJObject()
  if body != nil:
    body_603558 = body
  result = call_603557.call(nil, nil, nil, nil, body_603558)

var tagResource* = Call_TagResource_603544(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "swf.amazonaws.com", route: "/#X-Amz-Target=SimpleWorkflowService.TagResource",
                                        validator: validate_TagResource_603545,
                                        base: "/", url: url_TagResource_603546,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateWorkflowExecution_603559 = ref object of OpenApiRestCall_602466
proc url_TerminateWorkflowExecution_603561(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TerminateWorkflowExecution_603560(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Records a <code>WorkflowExecutionTerminated</code> event and forces closure of the workflow execution identified by the given domain, runId, and workflowId. The child policy, registered with the workflow type or specified when starting this execution, is applied to any open child workflow executions of this workflow execution.</p> <important> <p>If the identified workflow execution was in progress, it is terminated immediately.</p> </important> <note> <p>If a runId isn't specified, then the <code>WorkflowExecutionTerminated</code> event is recorded in the history of the current open workflow with the matching workflowId in the domain.</p> </note> <note> <p>You should consider using <a>RequestCancelWorkflowExecution</a> action instead because it allows the workflow to gracefully close while <a>TerminateWorkflowExecution</a> doesn't.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603562 = header.getOrDefault("X-Amz-Date")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Date", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Security-Token")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Security-Token", valid_603563
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603564 = header.getOrDefault("X-Amz-Target")
  valid_603564 = validateParameter(valid_603564, JString, required = true, default = newJString(
      "SimpleWorkflowService.TerminateWorkflowExecution"))
  if valid_603564 != nil:
    section.add "X-Amz-Target", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Content-Sha256", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Algorithm")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Algorithm", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Signature")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Signature", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-SignedHeaders", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Credential")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Credential", valid_603569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603571: Call_TerminateWorkflowExecution_603559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Records a <code>WorkflowExecutionTerminated</code> event and forces closure of the workflow execution identified by the given domain, runId, and workflowId. The child policy, registered with the workflow type or specified when starting this execution, is applied to any open child workflow executions of this workflow execution.</p> <important> <p>If the identified workflow execution was in progress, it is terminated immediately.</p> </important> <note> <p>If a runId isn't specified, then the <code>WorkflowExecutionTerminated</code> event is recorded in the history of the current open workflow with the matching workflowId in the domain.</p> </note> <note> <p>You should consider using <a>RequestCancelWorkflowExecution</a> action instead because it allows the workflow to gracefully close while <a>TerminateWorkflowExecution</a> doesn't.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603571.validator(path, query, header, formData, body)
  let scheme = call_603571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603571.url(scheme.get, call_603571.host, call_603571.base,
                         call_603571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603571, url, valid)

proc call*(call_603572: Call_TerminateWorkflowExecution_603559; body: JsonNode): Recallable =
  ## terminateWorkflowExecution
  ## <p>Records a <code>WorkflowExecutionTerminated</code> event and forces closure of the workflow execution identified by the given domain, runId, and workflowId. The child policy, registered with the workflow type or specified when starting this execution, is applied to any open child workflow executions of this workflow execution.</p> <important> <p>If the identified workflow execution was in progress, it is terminated immediately.</p> </important> <note> <p>If a runId isn't specified, then the <code>WorkflowExecutionTerminated</code> event is recorded in the history of the current open workflow with the matching workflowId in the domain.</p> </note> <note> <p>You should consider using <a>RequestCancelWorkflowExecution</a> action instead because it allows the workflow to gracefully close while <a>TerminateWorkflowExecution</a> doesn't.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603573 = newJObject()
  if body != nil:
    body_603573 = body
  result = call_603572.call(nil, nil, nil, nil, body_603573)

var terminateWorkflowExecution* = Call_TerminateWorkflowExecution_603559(
    name: "terminateWorkflowExecution", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.TerminateWorkflowExecution",
    validator: validate_TerminateWorkflowExecution_603560, base: "/",
    url: url_TerminateWorkflowExecution_603561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UndeprecateActivityType_603574 = ref object of OpenApiRestCall_602466
proc url_UndeprecateActivityType_603576(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UndeprecateActivityType_603575(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Undeprecates a previously deprecated <i>activity type</i>. After an activity type has been undeprecated, you can create new tasks of that activity type.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>activityType.name</code>: String constraint. The key is <code>swf:activityType.name</code>.</p> </li> <li> <p> <code>activityType.version</code>: String constraint. The key is <code>swf:activityType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603577 = header.getOrDefault("X-Amz-Date")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Date", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Security-Token")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Security-Token", valid_603578
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603579 = header.getOrDefault("X-Amz-Target")
  valid_603579 = validateParameter(valid_603579, JString, required = true, default = newJString(
      "SimpleWorkflowService.UndeprecateActivityType"))
  if valid_603579 != nil:
    section.add "X-Amz-Target", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Content-Sha256", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Algorithm")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Algorithm", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Signature")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Signature", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-SignedHeaders", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Credential")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Credential", valid_603584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603586: Call_UndeprecateActivityType_603574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Undeprecates a previously deprecated <i>activity type</i>. After an activity type has been undeprecated, you can create new tasks of that activity type.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>activityType.name</code>: String constraint. The key is <code>swf:activityType.name</code>.</p> </li> <li> <p> <code>activityType.version</code>: String constraint. The key is <code>swf:activityType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603586.validator(path, query, header, formData, body)
  let scheme = call_603586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603586.url(scheme.get, call_603586.host, call_603586.base,
                         call_603586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603586, url, valid)

proc call*(call_603587: Call_UndeprecateActivityType_603574; body: JsonNode): Recallable =
  ## undeprecateActivityType
  ## <p>Undeprecates a previously deprecated <i>activity type</i>. After an activity type has been undeprecated, you can create new tasks of that activity type.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>activityType.name</code>: String constraint. The key is <code>swf:activityType.name</code>.</p> </li> <li> <p> <code>activityType.version</code>: String constraint. The key is <code>swf:activityType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603588 = newJObject()
  if body != nil:
    body_603588 = body
  result = call_603587.call(nil, nil, nil, nil, body_603588)

var undeprecateActivityType* = Call_UndeprecateActivityType_603574(
    name: "undeprecateActivityType", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.UndeprecateActivityType",
    validator: validate_UndeprecateActivityType_603575, base: "/",
    url: url_UndeprecateActivityType_603576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UndeprecateDomain_603589 = ref object of OpenApiRestCall_602466
proc url_UndeprecateDomain_603591(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UndeprecateDomain_603590(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Undeprecates a previously deprecated domain. After a domain has been undeprecated it can be used to create new workflow executions or register new types.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603592 = header.getOrDefault("X-Amz-Date")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Date", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Security-Token")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Security-Token", valid_603593
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603594 = header.getOrDefault("X-Amz-Target")
  valid_603594 = validateParameter(valid_603594, JString, required = true, default = newJString(
      "SimpleWorkflowService.UndeprecateDomain"))
  if valid_603594 != nil:
    section.add "X-Amz-Target", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Content-Sha256", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Algorithm")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Algorithm", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Signature")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Signature", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-SignedHeaders", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Credential")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Credential", valid_603599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603601: Call_UndeprecateDomain_603589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Undeprecates a previously deprecated domain. After a domain has been undeprecated it can be used to create new workflow executions or register new types.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603601.validator(path, query, header, formData, body)
  let scheme = call_603601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603601.url(scheme.get, call_603601.host, call_603601.base,
                         call_603601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603601, url, valid)

proc call*(call_603602: Call_UndeprecateDomain_603589; body: JsonNode): Recallable =
  ## undeprecateDomain
  ## <p>Undeprecates a previously deprecated domain. After a domain has been undeprecated it can be used to create new workflow executions or register new types.</p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>You cannot use an IAM policy to constrain this action's parameters.</p> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603603 = newJObject()
  if body != nil:
    body_603603 = body
  result = call_603602.call(nil, nil, nil, nil, body_603603)

var undeprecateDomain* = Call_UndeprecateDomain_603589(name: "undeprecateDomain",
    meth: HttpMethod.HttpPost, host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.UndeprecateDomain",
    validator: validate_UndeprecateDomain_603590, base: "/",
    url: url_UndeprecateDomain_603591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UndeprecateWorkflowType_603604 = ref object of OpenApiRestCall_602466
proc url_UndeprecateWorkflowType_603606(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UndeprecateWorkflowType_603605(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Undeprecates a previously deprecated <i>workflow type</i>. After a workflow type has been undeprecated, you can create new executions of that type. </p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>workflowType.name</code>: String constraint. The key is <code>swf:workflowType.name</code>.</p> </li> <li> <p> <code>workflowType.version</code>: String constraint. The key is <code>swf:workflowType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
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
  var valid_603607 = header.getOrDefault("X-Amz-Date")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Date", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Security-Token")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Security-Token", valid_603608
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603609 = header.getOrDefault("X-Amz-Target")
  valid_603609 = validateParameter(valid_603609, JString, required = true, default = newJString(
      "SimpleWorkflowService.UndeprecateWorkflowType"))
  if valid_603609 != nil:
    section.add "X-Amz-Target", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Content-Sha256", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Algorithm")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Algorithm", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-Signature")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-Signature", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-SignedHeaders", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Credential")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Credential", valid_603614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603616: Call_UndeprecateWorkflowType_603604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Undeprecates a previously deprecated <i>workflow type</i>. After a workflow type has been undeprecated, you can create new executions of that type. </p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>workflowType.name</code>: String constraint. The key is <code>swf:workflowType.name</code>.</p> </li> <li> <p> <code>workflowType.version</code>: String constraint. The key is <code>swf:workflowType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ## 
  let valid = call_603616.validator(path, query, header, formData, body)
  let scheme = call_603616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603616.url(scheme.get, call_603616.host, call_603616.base,
                         call_603616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603616, url, valid)

proc call*(call_603617: Call_UndeprecateWorkflowType_603604; body: JsonNode): Recallable =
  ## undeprecateWorkflowType
  ## <p>Undeprecates a previously deprecated <i>workflow type</i>. After a workflow type has been undeprecated, you can create new executions of that type. </p> <note> <p>This operation is eventually consistent. The results are best effort and may not exactly reflect recent updates and changes.</p> </note> <p> <b>Access Control</b> </p> <p>You can use IAM policies to control this action's access to Amazon SWF resources as follows:</p> <ul> <li> <p>Use a <code>Resource</code> element with the domain name to limit the action to only specified domains.</p> </li> <li> <p>Use an <code>Action</code> element to allow or deny permission to call this action.</p> </li> <li> <p>Constrain the following parameters by using a <code>Condition</code> element with the appropriate keys.</p> <ul> <li> <p> <code>workflowType.name</code>: String constraint. The key is <code>swf:workflowType.name</code>.</p> </li> <li> <p> <code>workflowType.version</code>: String constraint. The key is <code>swf:workflowType.version</code>.</p> </li> </ul> </li> </ul> <p>If the caller doesn't have sufficient permissions to invoke the action, or the parameter values fall outside the specified constraints, the action fails. The associated event attribute's <code>cause</code> parameter is set to <code>OPERATION_NOT_PERMITTED</code>. For details and example IAM policies, see <a href="https://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-iam.html">Using IAM to Manage Access to Amazon SWF Workflows</a> in the <i>Amazon SWF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603618 = newJObject()
  if body != nil:
    body_603618 = body
  result = call_603617.call(nil, nil, nil, nil, body_603618)

var undeprecateWorkflowType* = Call_UndeprecateWorkflowType_603604(
    name: "undeprecateWorkflowType", meth: HttpMethod.HttpPost,
    host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.UndeprecateWorkflowType",
    validator: validate_UndeprecateWorkflowType_603605, base: "/",
    url: url_UndeprecateWorkflowType_603606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603619 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603621(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_603620(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a tag from a Amazon SWF domain.
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
  var valid_603622 = header.getOrDefault("X-Amz-Date")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Date", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Security-Token")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Security-Token", valid_603623
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603624 = header.getOrDefault("X-Amz-Target")
  valid_603624 = validateParameter(valid_603624, JString, required = true, default = newJString(
      "SimpleWorkflowService.UntagResource"))
  if valid_603624 != nil:
    section.add "X-Amz-Target", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Content-Sha256", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Algorithm")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Algorithm", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Signature")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Signature", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-SignedHeaders", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Credential")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Credential", valid_603629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603631: Call_UntagResource_603619; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove a tag from a Amazon SWF domain.
  ## 
  let valid = call_603631.validator(path, query, header, formData, body)
  let scheme = call_603631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603631.url(scheme.get, call_603631.host, call_603631.base,
                         call_603631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603631, url, valid)

proc call*(call_603632: Call_UntagResource_603619; body: JsonNode): Recallable =
  ## untagResource
  ## Remove a tag from a Amazon SWF domain.
  ##   body: JObject (required)
  var body_603633 = newJObject()
  if body != nil:
    body_603633 = body
  result = call_603632.call(nil, nil, nil, nil, body_603633)

var untagResource* = Call_UntagResource_603619(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "swf.amazonaws.com",
    route: "/#X-Amz-Target=SimpleWorkflowService.UntagResource",
    validator: validate_UntagResource_603620, base: "/", url: url_UntagResource_603621,
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
