
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Inspector
## version: 2016-02-16
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Inspector</fullname> <p>Amazon Inspector enables you to analyze the behavior of your AWS resources and to identify potential security issues. For more information, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_introduction.html"> Amazon Inspector User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/inspector/
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "inspector.ap-northeast-1.amazonaws.com", "ap-southeast-1": "inspector.ap-southeast-1.amazonaws.com",
                           "us-west-2": "inspector.us-west-2.amazonaws.com",
                           "eu-west-2": "inspector.eu-west-2.amazonaws.com", "ap-northeast-3": "inspector.ap-northeast-3.amazonaws.com", "eu-central-1": "inspector.eu-central-1.amazonaws.com",
                           "us-east-2": "inspector.us-east-2.amazonaws.com",
                           "us-east-1": "inspector.us-east-1.amazonaws.com", "cn-northwest-1": "inspector.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "inspector.ap-south-1.amazonaws.com",
                           "eu-north-1": "inspector.eu-north-1.amazonaws.com", "ap-northeast-2": "inspector.ap-northeast-2.amazonaws.com",
                           "us-west-1": "inspector.us-west-1.amazonaws.com", "us-gov-east-1": "inspector.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "inspector.eu-west-3.amazonaws.com", "cn-north-1": "inspector.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "inspector.sa-east-1.amazonaws.com",
                           "eu-west-1": "inspector.eu-west-1.amazonaws.com", "us-gov-west-1": "inspector.us-gov-west-1.amazonaws.com", "ap-southeast-2": "inspector.ap-southeast-2.amazonaws.com", "ca-central-1": "inspector.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "inspector.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "inspector.ap-southeast-1.amazonaws.com",
      "us-west-2": "inspector.us-west-2.amazonaws.com",
      "eu-west-2": "inspector.eu-west-2.amazonaws.com",
      "ap-northeast-3": "inspector.ap-northeast-3.amazonaws.com",
      "eu-central-1": "inspector.eu-central-1.amazonaws.com",
      "us-east-2": "inspector.us-east-2.amazonaws.com",
      "us-east-1": "inspector.us-east-1.amazonaws.com",
      "cn-northwest-1": "inspector.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "inspector.ap-south-1.amazonaws.com",
      "eu-north-1": "inspector.eu-north-1.amazonaws.com",
      "ap-northeast-2": "inspector.ap-northeast-2.amazonaws.com",
      "us-west-1": "inspector.us-west-1.amazonaws.com",
      "us-gov-east-1": "inspector.us-gov-east-1.amazonaws.com",
      "eu-west-3": "inspector.eu-west-3.amazonaws.com",
      "cn-north-1": "inspector.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "inspector.sa-east-1.amazonaws.com",
      "eu-west-1": "inspector.eu-west-1.amazonaws.com",
      "us-gov-west-1": "inspector.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "inspector.ap-southeast-2.amazonaws.com",
      "ca-central-1": "inspector.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "inspector"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddAttributesToFindings_605927 = ref object of OpenApiRestCall_605589
proc url_AddAttributesToFindings_605929(protocol: Scheme; host: string; base: string;
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

proc validate_AddAttributesToFindings_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Assigns attributes (key and value pairs) to the findings that are specified by the ARNs of the findings.
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
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "InspectorService.AddAttributesToFindings"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_AddAttributesToFindings_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns attributes (key and value pairs) to the findings that are specified by the ARNs of the findings.
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AddAttributesToFindings_605927; body: JsonNode): Recallable =
  ## addAttributesToFindings
  ## Assigns attributes (key and value pairs) to the findings that are specified by the ARNs of the findings.
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var addAttributesToFindings* = Call_AddAttributesToFindings_605927(
    name: "addAttributesToFindings", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.AddAttributesToFindings",
    validator: validate_AddAttributesToFindings_605928, base: "/",
    url: url_AddAttributesToFindings_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssessmentTarget_606196 = ref object of OpenApiRestCall_605589
proc url_CreateAssessmentTarget_606198(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAssessmentTarget_606197(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new assessment target using the ARN of the resource group that is generated by <a>CreateResourceGroup</a>. If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments. You can create up to 50 assessment targets per AWS account. You can run up to 500 concurrent agents per AWS account. For more information, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html"> Amazon Inspector Assessment Targets</a>.
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
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "InspectorService.CreateAssessmentTarget"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_CreateAssessmentTarget_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new assessment target using the ARN of the resource group that is generated by <a>CreateResourceGroup</a>. If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments. You can create up to 50 assessment targets per AWS account. You can run up to 500 concurrent agents per AWS account. For more information, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html"> Amazon Inspector Assessment Targets</a>.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_CreateAssessmentTarget_606196; body: JsonNode): Recallable =
  ## createAssessmentTarget
  ## Creates a new assessment target using the ARN of the resource group that is generated by <a>CreateResourceGroup</a>. If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments. You can create up to 50 assessment targets per AWS account. You can run up to 500 concurrent agents per AWS account. For more information, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html"> Amazon Inspector Assessment Targets</a>.
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var createAssessmentTarget* = Call_CreateAssessmentTarget_606196(
    name: "createAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateAssessmentTarget",
    validator: validate_CreateAssessmentTarget_606197, base: "/",
    url: url_CreateAssessmentTarget_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssessmentTemplate_606211 = ref object of OpenApiRestCall_605589
proc url_CreateAssessmentTemplate_606213(protocol: Scheme; host: string;
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

proc validate_CreateAssessmentTemplate_606212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an assessment template for the assessment target that is specified by the ARN of the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments.
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
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "InspectorService.CreateAssessmentTemplate"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_CreateAssessmentTemplate_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an assessment template for the assessment target that is specified by the ARN of the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments.
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_CreateAssessmentTemplate_606211; body: JsonNode): Recallable =
  ## createAssessmentTemplate
  ## Creates an assessment template for the assessment target that is specified by the ARN of the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments.
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var createAssessmentTemplate* = Call_CreateAssessmentTemplate_606211(
    name: "createAssessmentTemplate", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateAssessmentTemplate",
    validator: validate_CreateAssessmentTemplate_606212, base: "/",
    url: url_CreateAssessmentTemplate_606213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExclusionsPreview_606226 = ref object of OpenApiRestCall_605589
proc url_CreateExclusionsPreview_606228(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExclusionsPreview_606227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts the generation of an exclusions preview for the specified assessment template. The exclusions preview lists the potential exclusions (ExclusionPreview) that Inspector can detect before it runs the assessment. 
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
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "InspectorService.CreateExclusionsPreview"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_CreateExclusionsPreview_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the generation of an exclusions preview for the specified assessment template. The exclusions preview lists the potential exclusions (ExclusionPreview) that Inspector can detect before it runs the assessment. 
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_CreateExclusionsPreview_606226; body: JsonNode): Recallable =
  ## createExclusionsPreview
  ## Starts the generation of an exclusions preview for the specified assessment template. The exclusions preview lists the potential exclusions (ExclusionPreview) that Inspector can detect before it runs the assessment. 
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var createExclusionsPreview* = Call_CreateExclusionsPreview_606226(
    name: "createExclusionsPreview", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateExclusionsPreview",
    validator: validate_CreateExclusionsPreview_606227, base: "/",
    url: url_CreateExclusionsPreview_606228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceGroup_606241 = ref object of OpenApiRestCall_605589
proc url_CreateResourceGroup_606243(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResourceGroup_606242(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a resource group using the specified set of tags (key and value pairs) that are used to select the EC2 instances to be included in an Amazon Inspector assessment target. The created resource group is then used to create an Amazon Inspector assessment target. For more information, see <a>CreateAssessmentTarget</a>.
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
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "InspectorService.CreateResourceGroup"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_CreateResourceGroup_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource group using the specified set of tags (key and value pairs) that are used to select the EC2 instances to be included in an Amazon Inspector assessment target. The created resource group is then used to create an Amazon Inspector assessment target. For more information, see <a>CreateAssessmentTarget</a>.
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_CreateResourceGroup_606241; body: JsonNode): Recallable =
  ## createResourceGroup
  ## Creates a resource group using the specified set of tags (key and value pairs) that are used to select the EC2 instances to be included in an Amazon Inspector assessment target. The created resource group is then used to create an Amazon Inspector assessment target. For more information, see <a>CreateAssessmentTarget</a>.
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var createResourceGroup* = Call_CreateResourceGroup_606241(
    name: "createResourceGroup", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateResourceGroup",
    validator: validate_CreateResourceGroup_606242, base: "/",
    url: url_CreateResourceGroup_606243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentRun_606256 = ref object of OpenApiRestCall_605589
proc url_DeleteAssessmentRun_606258(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAssessmentRun_606257(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes the assessment run that is specified by the ARN of the assessment run.
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
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentRun"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_DeleteAssessmentRun_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment run that is specified by the ARN of the assessment run.
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_DeleteAssessmentRun_606256; body: JsonNode): Recallable =
  ## deleteAssessmentRun
  ## Deletes the assessment run that is specified by the ARN of the assessment run.
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var deleteAssessmentRun* = Call_DeleteAssessmentRun_606256(
    name: "deleteAssessmentRun", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentRun",
    validator: validate_DeleteAssessmentRun_606257, base: "/",
    url: url_DeleteAssessmentRun_606258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentTarget_606271 = ref object of OpenApiRestCall_605589
proc url_DeleteAssessmentTarget_606273(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAssessmentTarget_606272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the assessment target that is specified by the ARN of the assessment target.
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
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentTarget"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_DeleteAssessmentTarget_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment target that is specified by the ARN of the assessment target.
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_DeleteAssessmentTarget_606271; body: JsonNode): Recallable =
  ## deleteAssessmentTarget
  ## Deletes the assessment target that is specified by the ARN of the assessment target.
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var deleteAssessmentTarget* = Call_DeleteAssessmentTarget_606271(
    name: "deleteAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentTarget",
    validator: validate_DeleteAssessmentTarget_606272, base: "/",
    url: url_DeleteAssessmentTarget_606273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentTemplate_606286 = ref object of OpenApiRestCall_605589
proc url_DeleteAssessmentTemplate_606288(protocol: Scheme; host: string;
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

proc validate_DeleteAssessmentTemplate_606287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the assessment template that is specified by the ARN of the assessment template.
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
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentTemplate"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_DeleteAssessmentTemplate_606286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment template that is specified by the ARN of the assessment template.
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_DeleteAssessmentTemplate_606286; body: JsonNode): Recallable =
  ## deleteAssessmentTemplate
  ## Deletes the assessment template that is specified by the ARN of the assessment template.
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var deleteAssessmentTemplate* = Call_DeleteAssessmentTemplate_606286(
    name: "deleteAssessmentTemplate", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentTemplate",
    validator: validate_DeleteAssessmentTemplate_606287, base: "/",
    url: url_DeleteAssessmentTemplate_606288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentRuns_606301 = ref object of OpenApiRestCall_605589
proc url_DescribeAssessmentRuns_606303(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAssessmentRuns_606302(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the assessment runs that are specified by the ARNs of the assessment runs.
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
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentRuns"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_DescribeAssessmentRuns_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_DescribeAssessmentRuns_606301; body: JsonNode): Recallable =
  ## describeAssessmentRuns
  ## Describes the assessment runs that are specified by the ARNs of the assessment runs.
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var describeAssessmentRuns* = Call_DescribeAssessmentRuns_606301(
    name: "describeAssessmentRuns", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentRuns",
    validator: validate_DescribeAssessmentRuns_606302, base: "/",
    url: url_DescribeAssessmentRuns_606303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentTargets_606316 = ref object of OpenApiRestCall_605589
proc url_DescribeAssessmentTargets_606318(protocol: Scheme; host: string;
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

proc validate_DescribeAssessmentTargets_606317(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the assessment targets that are specified by the ARNs of the assessment targets.
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
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentTargets"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_DescribeAssessmentTargets_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment targets that are specified by the ARNs of the assessment targets.
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_DescribeAssessmentTargets_606316; body: JsonNode): Recallable =
  ## describeAssessmentTargets
  ## Describes the assessment targets that are specified by the ARNs of the assessment targets.
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var describeAssessmentTargets* = Call_DescribeAssessmentTargets_606316(
    name: "describeAssessmentTargets", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentTargets",
    validator: validate_DescribeAssessmentTargets_606317, base: "/",
    url: url_DescribeAssessmentTargets_606318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentTemplates_606331 = ref object of OpenApiRestCall_605589
proc url_DescribeAssessmentTemplates_606333(protocol: Scheme; host: string;
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

proc validate_DescribeAssessmentTemplates_606332(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the assessment templates that are specified by the ARNs of the assessment templates.
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
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentTemplates"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_DescribeAssessmentTemplates_606331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment templates that are specified by the ARNs of the assessment templates.
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_DescribeAssessmentTemplates_606331; body: JsonNode): Recallable =
  ## describeAssessmentTemplates
  ## Describes the assessment templates that are specified by the ARNs of the assessment templates.
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var describeAssessmentTemplates* = Call_DescribeAssessmentTemplates_606331(
    name: "describeAssessmentTemplates", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentTemplates",
    validator: validate_DescribeAssessmentTemplates_606332, base: "/",
    url: url_DescribeAssessmentTemplates_606333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCrossAccountAccessRole_606346 = ref object of OpenApiRestCall_605589
proc url_DescribeCrossAccountAccessRole_606348(protocol: Scheme; host: string;
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

proc validate_DescribeCrossAccountAccessRole_606347(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the IAM role that enables Amazon Inspector to access your AWS account.
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
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "InspectorService.DescribeCrossAccountAccessRole"))
  if valid_606349 != nil:
    section.add "X-Amz-Target", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606357: Call_DescribeCrossAccountAccessRole_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the IAM role that enables Amazon Inspector to access your AWS account.
  ## 
  let valid = call_606357.validator(path, query, header, formData, body)
  let scheme = call_606357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606357.url(scheme.get, call_606357.host, call_606357.base,
                         call_606357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606357, url, valid)

proc call*(call_606358: Call_DescribeCrossAccountAccessRole_606346): Recallable =
  ## describeCrossAccountAccessRole
  ## Describes the IAM role that enables Amazon Inspector to access your AWS account.
  result = call_606358.call(nil, nil, nil, nil, nil)

var describeCrossAccountAccessRole* = Call_DescribeCrossAccountAccessRole_606346(
    name: "describeCrossAccountAccessRole", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeCrossAccountAccessRole",
    validator: validate_DescribeCrossAccountAccessRole_606347, base: "/",
    url: url_DescribeCrossAccountAccessRole_606348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExclusions_606359 = ref object of OpenApiRestCall_605589
proc url_DescribeExclusions_606361(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeExclusions_606360(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Describes the exclusions that are specified by the exclusions' ARNs.
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
  var valid_606362 = header.getOrDefault("X-Amz-Target")
  valid_606362 = validateParameter(valid_606362, JString, required = true, default = newJString(
      "InspectorService.DescribeExclusions"))
  if valid_606362 != nil:
    section.add "X-Amz-Target", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Signature")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Signature", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Content-Sha256", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Date")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Date", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Credential")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Credential", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Security-Token")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Security-Token", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Algorithm")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Algorithm", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-SignedHeaders", valid_606369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606371: Call_DescribeExclusions_606359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the exclusions that are specified by the exclusions' ARNs.
  ## 
  let valid = call_606371.validator(path, query, header, formData, body)
  let scheme = call_606371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606371.url(scheme.get, call_606371.host, call_606371.base,
                         call_606371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606371, url, valid)

proc call*(call_606372: Call_DescribeExclusions_606359; body: JsonNode): Recallable =
  ## describeExclusions
  ## Describes the exclusions that are specified by the exclusions' ARNs.
  ##   body: JObject (required)
  var body_606373 = newJObject()
  if body != nil:
    body_606373 = body
  result = call_606372.call(nil, nil, nil, nil, body_606373)

var describeExclusions* = Call_DescribeExclusions_606359(
    name: "describeExclusions", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeExclusions",
    validator: validate_DescribeExclusions_606360, base: "/",
    url: url_DescribeExclusions_606361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFindings_606374 = ref object of OpenApiRestCall_605589
proc url_DescribeFindings_606376(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFindings_606375(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes the findings that are specified by the ARNs of the findings.
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
  var valid_606377 = header.getOrDefault("X-Amz-Target")
  valid_606377 = validateParameter(valid_606377, JString, required = true, default = newJString(
      "InspectorService.DescribeFindings"))
  if valid_606377 != nil:
    section.add "X-Amz-Target", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Signature")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Signature", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Content-Sha256", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Date")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Date", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Credential")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Credential", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Security-Token")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Security-Token", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Algorithm")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Algorithm", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-SignedHeaders", valid_606384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606386: Call_DescribeFindings_606374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the findings that are specified by the ARNs of the findings.
  ## 
  let valid = call_606386.validator(path, query, header, formData, body)
  let scheme = call_606386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606386.url(scheme.get, call_606386.host, call_606386.base,
                         call_606386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606386, url, valid)

proc call*(call_606387: Call_DescribeFindings_606374; body: JsonNode): Recallable =
  ## describeFindings
  ## Describes the findings that are specified by the ARNs of the findings.
  ##   body: JObject (required)
  var body_606388 = newJObject()
  if body != nil:
    body_606388 = body
  result = call_606387.call(nil, nil, nil, nil, body_606388)

var describeFindings* = Call_DescribeFindings_606374(name: "describeFindings",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeFindings",
    validator: validate_DescribeFindings_606375, base: "/",
    url: url_DescribeFindings_606376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceGroups_606389 = ref object of OpenApiRestCall_605589
proc url_DescribeResourceGroups_606391(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeResourceGroups_606390(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the resource groups that are specified by the ARNs of the resource groups.
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
  var valid_606392 = header.getOrDefault("X-Amz-Target")
  valid_606392 = validateParameter(valid_606392, JString, required = true, default = newJString(
      "InspectorService.DescribeResourceGroups"))
  if valid_606392 != nil:
    section.add "X-Amz-Target", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Signature")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Signature", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Content-Sha256", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Date")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Date", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Credential")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Credential", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Security-Token")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Security-Token", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Algorithm")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Algorithm", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-SignedHeaders", valid_606399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606401: Call_DescribeResourceGroups_606389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the resource groups that are specified by the ARNs of the resource groups.
  ## 
  let valid = call_606401.validator(path, query, header, formData, body)
  let scheme = call_606401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606401.url(scheme.get, call_606401.host, call_606401.base,
                         call_606401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606401, url, valid)

proc call*(call_606402: Call_DescribeResourceGroups_606389; body: JsonNode): Recallable =
  ## describeResourceGroups
  ## Describes the resource groups that are specified by the ARNs of the resource groups.
  ##   body: JObject (required)
  var body_606403 = newJObject()
  if body != nil:
    body_606403 = body
  result = call_606402.call(nil, nil, nil, nil, body_606403)

var describeResourceGroups* = Call_DescribeResourceGroups_606389(
    name: "describeResourceGroups", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeResourceGroups",
    validator: validate_DescribeResourceGroups_606390, base: "/",
    url: url_DescribeResourceGroups_606391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRulesPackages_606404 = ref object of OpenApiRestCall_605589
proc url_DescribeRulesPackages_606406(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRulesPackages_606405(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the rules packages that are specified by the ARNs of the rules packages.
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
  var valid_606407 = header.getOrDefault("X-Amz-Target")
  valid_606407 = validateParameter(valid_606407, JString, required = true, default = newJString(
      "InspectorService.DescribeRulesPackages"))
  if valid_606407 != nil:
    section.add "X-Amz-Target", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Signature")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Signature", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Content-Sha256", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Date")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Date", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Credential")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Credential", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Security-Token")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Security-Token", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Algorithm")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Algorithm", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-SignedHeaders", valid_606414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606416: Call_DescribeRulesPackages_606404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the rules packages that are specified by the ARNs of the rules packages.
  ## 
  let valid = call_606416.validator(path, query, header, formData, body)
  let scheme = call_606416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606416.url(scheme.get, call_606416.host, call_606416.base,
                         call_606416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606416, url, valid)

proc call*(call_606417: Call_DescribeRulesPackages_606404; body: JsonNode): Recallable =
  ## describeRulesPackages
  ## Describes the rules packages that are specified by the ARNs of the rules packages.
  ##   body: JObject (required)
  var body_606418 = newJObject()
  if body != nil:
    body_606418 = body
  result = call_606417.call(nil, nil, nil, nil, body_606418)

var describeRulesPackages* = Call_DescribeRulesPackages_606404(
    name: "describeRulesPackages", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeRulesPackages",
    validator: validate_DescribeRulesPackages_606405, base: "/",
    url: url_DescribeRulesPackages_606406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssessmentReport_606419 = ref object of OpenApiRestCall_605589
proc url_GetAssessmentReport_606421(protocol: Scheme; host: string; base: string;
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

proc validate_GetAssessmentReport_606420(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Produces an assessment report that includes detailed and comprehensive results of a specified assessment run. 
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
  var valid_606422 = header.getOrDefault("X-Amz-Target")
  valid_606422 = validateParameter(valid_606422, JString, required = true, default = newJString(
      "InspectorService.GetAssessmentReport"))
  if valid_606422 != nil:
    section.add "X-Amz-Target", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Signature")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Signature", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Content-Sha256", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Date")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Date", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Credential")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Credential", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Security-Token")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Security-Token", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Algorithm")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Algorithm", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-SignedHeaders", valid_606429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606431: Call_GetAssessmentReport_606419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces an assessment report that includes detailed and comprehensive results of a specified assessment run. 
  ## 
  let valid = call_606431.validator(path, query, header, formData, body)
  let scheme = call_606431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606431.url(scheme.get, call_606431.host, call_606431.base,
                         call_606431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606431, url, valid)

proc call*(call_606432: Call_GetAssessmentReport_606419; body: JsonNode): Recallable =
  ## getAssessmentReport
  ## Produces an assessment report that includes detailed and comprehensive results of a specified assessment run. 
  ##   body: JObject (required)
  var body_606433 = newJObject()
  if body != nil:
    body_606433 = body
  result = call_606432.call(nil, nil, nil, nil, body_606433)

var getAssessmentReport* = Call_GetAssessmentReport_606419(
    name: "getAssessmentReport", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetAssessmentReport",
    validator: validate_GetAssessmentReport_606420, base: "/",
    url: url_GetAssessmentReport_606421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExclusionsPreview_606434 = ref object of OpenApiRestCall_605589
proc url_GetExclusionsPreview_606436(protocol: Scheme; host: string; base: string;
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

proc validate_GetExclusionsPreview_606435(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the exclusions preview (a list of ExclusionPreview objects) specified by the preview token. You can obtain the preview token by running the CreateExclusionsPreview API.
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
  var valid_606437 = query.getOrDefault("nextToken")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "nextToken", valid_606437
  var valid_606438 = query.getOrDefault("maxResults")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "maxResults", valid_606438
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
  var valid_606439 = header.getOrDefault("X-Amz-Target")
  valid_606439 = validateParameter(valid_606439, JString, required = true, default = newJString(
      "InspectorService.GetExclusionsPreview"))
  if valid_606439 != nil:
    section.add "X-Amz-Target", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606448: Call_GetExclusionsPreview_606434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the exclusions preview (a list of ExclusionPreview objects) specified by the preview token. You can obtain the preview token by running the CreateExclusionsPreview API.
  ## 
  let valid = call_606448.validator(path, query, header, formData, body)
  let scheme = call_606448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606448.url(scheme.get, call_606448.host, call_606448.base,
                         call_606448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606448, url, valid)

proc call*(call_606449: Call_GetExclusionsPreview_606434; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getExclusionsPreview
  ## Retrieves the exclusions preview (a list of ExclusionPreview objects) specified by the preview token. You can obtain the preview token by running the CreateExclusionsPreview API.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606450 = newJObject()
  var body_606451 = newJObject()
  add(query_606450, "nextToken", newJString(nextToken))
  if body != nil:
    body_606451 = body
  add(query_606450, "maxResults", newJString(maxResults))
  result = call_606449.call(nil, query_606450, nil, nil, body_606451)

var getExclusionsPreview* = Call_GetExclusionsPreview_606434(
    name: "getExclusionsPreview", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetExclusionsPreview",
    validator: validate_GetExclusionsPreview_606435, base: "/",
    url: url_GetExclusionsPreview_606436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTelemetryMetadata_606453 = ref object of OpenApiRestCall_605589
proc url_GetTelemetryMetadata_606455(protocol: Scheme; host: string; base: string;
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

proc validate_GetTelemetryMetadata_606454(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Information about the data that is collected for the specified assessment run.
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
  var valid_606456 = header.getOrDefault("X-Amz-Target")
  valid_606456 = validateParameter(valid_606456, JString, required = true, default = newJString(
      "InspectorService.GetTelemetryMetadata"))
  if valid_606456 != nil:
    section.add "X-Amz-Target", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Signature")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Signature", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Content-Sha256", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Date")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Date", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Credential")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Credential", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Security-Token")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Security-Token", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Algorithm")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Algorithm", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-SignedHeaders", valid_606463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606465: Call_GetTelemetryMetadata_606453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Information about the data that is collected for the specified assessment run.
  ## 
  let valid = call_606465.validator(path, query, header, formData, body)
  let scheme = call_606465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606465.url(scheme.get, call_606465.host, call_606465.base,
                         call_606465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606465, url, valid)

proc call*(call_606466: Call_GetTelemetryMetadata_606453; body: JsonNode): Recallable =
  ## getTelemetryMetadata
  ## Information about the data that is collected for the specified assessment run.
  ##   body: JObject (required)
  var body_606467 = newJObject()
  if body != nil:
    body_606467 = body
  result = call_606466.call(nil, nil, nil, nil, body_606467)

var getTelemetryMetadata* = Call_GetTelemetryMetadata_606453(
    name: "getTelemetryMetadata", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetTelemetryMetadata",
    validator: validate_GetTelemetryMetadata_606454, base: "/",
    url: url_GetTelemetryMetadata_606455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentRunAgents_606468 = ref object of OpenApiRestCall_605589
proc url_ListAssessmentRunAgents_606470(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssessmentRunAgents_606469(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the agents of the assessment runs that are specified by the ARNs of the assessment runs.
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
  var valid_606471 = query.getOrDefault("nextToken")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "nextToken", valid_606471
  var valid_606472 = query.getOrDefault("maxResults")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "maxResults", valid_606472
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
  var valid_606473 = header.getOrDefault("X-Amz-Target")
  valid_606473 = validateParameter(valid_606473, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentRunAgents"))
  if valid_606473 != nil:
    section.add "X-Amz-Target", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Signature")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Signature", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Content-Sha256", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Date")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Date", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Credential")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Credential", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Security-Token")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Security-Token", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Algorithm")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Algorithm", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-SignedHeaders", valid_606480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606482: Call_ListAssessmentRunAgents_606468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the agents of the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_606482.validator(path, query, header, formData, body)
  let scheme = call_606482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606482.url(scheme.get, call_606482.host, call_606482.base,
                         call_606482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606482, url, valid)

proc call*(call_606483: Call_ListAssessmentRunAgents_606468; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssessmentRunAgents
  ## Lists the agents of the assessment runs that are specified by the ARNs of the assessment runs.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606484 = newJObject()
  var body_606485 = newJObject()
  add(query_606484, "nextToken", newJString(nextToken))
  if body != nil:
    body_606485 = body
  add(query_606484, "maxResults", newJString(maxResults))
  result = call_606483.call(nil, query_606484, nil, nil, body_606485)

var listAssessmentRunAgents* = Call_ListAssessmentRunAgents_606468(
    name: "listAssessmentRunAgents", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentRunAgents",
    validator: validate_ListAssessmentRunAgents_606469, base: "/",
    url: url_ListAssessmentRunAgents_606470, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentRuns_606486 = ref object of OpenApiRestCall_605589
proc url_ListAssessmentRuns_606488(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssessmentRuns_606487(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists the assessment runs that correspond to the assessment templates that are specified by the ARNs of the assessment templates.
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
  var valid_606489 = query.getOrDefault("nextToken")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "nextToken", valid_606489
  var valid_606490 = query.getOrDefault("maxResults")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "maxResults", valid_606490
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
  var valid_606491 = header.getOrDefault("X-Amz-Target")
  valid_606491 = validateParameter(valid_606491, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentRuns"))
  if valid_606491 != nil:
    section.add "X-Amz-Target", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Signature")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Signature", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Content-Sha256", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Date")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Date", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Credential")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Credential", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Security-Token")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Security-Token", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Algorithm")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Algorithm", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-SignedHeaders", valid_606498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606500: Call_ListAssessmentRuns_606486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the assessment runs that correspond to the assessment templates that are specified by the ARNs of the assessment templates.
  ## 
  let valid = call_606500.validator(path, query, header, formData, body)
  let scheme = call_606500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606500.url(scheme.get, call_606500.host, call_606500.base,
                         call_606500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606500, url, valid)

proc call*(call_606501: Call_ListAssessmentRuns_606486; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssessmentRuns
  ## Lists the assessment runs that correspond to the assessment templates that are specified by the ARNs of the assessment templates.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606502 = newJObject()
  var body_606503 = newJObject()
  add(query_606502, "nextToken", newJString(nextToken))
  if body != nil:
    body_606503 = body
  add(query_606502, "maxResults", newJString(maxResults))
  result = call_606501.call(nil, query_606502, nil, nil, body_606503)

var listAssessmentRuns* = Call_ListAssessmentRuns_606486(
    name: "listAssessmentRuns", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentRuns",
    validator: validate_ListAssessmentRuns_606487, base: "/",
    url: url_ListAssessmentRuns_606488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentTargets_606504 = ref object of OpenApiRestCall_605589
proc url_ListAssessmentTargets_606506(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssessmentTargets_606505(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the ARNs of the assessment targets within this AWS account. For more information about assessment targets, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html">Amazon Inspector Assessment Targets</a>.
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
  var valid_606507 = query.getOrDefault("nextToken")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "nextToken", valid_606507
  var valid_606508 = query.getOrDefault("maxResults")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "maxResults", valid_606508
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
  var valid_606509 = header.getOrDefault("X-Amz-Target")
  valid_606509 = validateParameter(valid_606509, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentTargets"))
  if valid_606509 != nil:
    section.add "X-Amz-Target", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Signature")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Signature", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Content-Sha256", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Date")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Date", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Credential")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Credential", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Security-Token")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Security-Token", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Algorithm")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Algorithm", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-SignedHeaders", valid_606516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606518: Call_ListAssessmentTargets_606504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the ARNs of the assessment targets within this AWS account. For more information about assessment targets, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html">Amazon Inspector Assessment Targets</a>.
  ## 
  let valid = call_606518.validator(path, query, header, formData, body)
  let scheme = call_606518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606518.url(scheme.get, call_606518.host, call_606518.base,
                         call_606518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606518, url, valid)

proc call*(call_606519: Call_ListAssessmentTargets_606504; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssessmentTargets
  ## Lists the ARNs of the assessment targets within this AWS account. For more information about assessment targets, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html">Amazon Inspector Assessment Targets</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606520 = newJObject()
  var body_606521 = newJObject()
  add(query_606520, "nextToken", newJString(nextToken))
  if body != nil:
    body_606521 = body
  add(query_606520, "maxResults", newJString(maxResults))
  result = call_606519.call(nil, query_606520, nil, nil, body_606521)

var listAssessmentTargets* = Call_ListAssessmentTargets_606504(
    name: "listAssessmentTargets", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentTargets",
    validator: validate_ListAssessmentTargets_606505, base: "/",
    url: url_ListAssessmentTargets_606506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentTemplates_606522 = ref object of OpenApiRestCall_605589
proc url_ListAssessmentTemplates_606524(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssessmentTemplates_606523(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the assessment templates that correspond to the assessment targets that are specified by the ARNs of the assessment targets.
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
  var valid_606525 = query.getOrDefault("nextToken")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "nextToken", valid_606525
  var valid_606526 = query.getOrDefault("maxResults")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "maxResults", valid_606526
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
  var valid_606527 = header.getOrDefault("X-Amz-Target")
  valid_606527 = validateParameter(valid_606527, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentTemplates"))
  if valid_606527 != nil:
    section.add "X-Amz-Target", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-Signature")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Signature", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Content-Sha256", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Date")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Date", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Credential")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Credential", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Security-Token")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Security-Token", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Algorithm")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Algorithm", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-SignedHeaders", valid_606534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606536: Call_ListAssessmentTemplates_606522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the assessment templates that correspond to the assessment targets that are specified by the ARNs of the assessment targets.
  ## 
  let valid = call_606536.validator(path, query, header, formData, body)
  let scheme = call_606536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606536.url(scheme.get, call_606536.host, call_606536.base,
                         call_606536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606536, url, valid)

proc call*(call_606537: Call_ListAssessmentTemplates_606522; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssessmentTemplates
  ## Lists the assessment templates that correspond to the assessment targets that are specified by the ARNs of the assessment targets.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606538 = newJObject()
  var body_606539 = newJObject()
  add(query_606538, "nextToken", newJString(nextToken))
  if body != nil:
    body_606539 = body
  add(query_606538, "maxResults", newJString(maxResults))
  result = call_606537.call(nil, query_606538, nil, nil, body_606539)

var listAssessmentTemplates* = Call_ListAssessmentTemplates_606522(
    name: "listAssessmentTemplates", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentTemplates",
    validator: validate_ListAssessmentTemplates_606523, base: "/",
    url: url_ListAssessmentTemplates_606524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSubscriptions_606540 = ref object of OpenApiRestCall_605589
proc url_ListEventSubscriptions_606542(protocol: Scheme; host: string; base: string;
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

proc validate_ListEventSubscriptions_606541(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the event subscriptions for the assessment template that is specified by the ARN of the assessment template. For more information, see <a>SubscribeToEvent</a> and <a>UnsubscribeFromEvent</a>.
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
  var valid_606543 = query.getOrDefault("nextToken")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "nextToken", valid_606543
  var valid_606544 = query.getOrDefault("maxResults")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "maxResults", valid_606544
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
  var valid_606545 = header.getOrDefault("X-Amz-Target")
  valid_606545 = validateParameter(valid_606545, JString, required = true, default = newJString(
      "InspectorService.ListEventSubscriptions"))
  if valid_606545 != nil:
    section.add "X-Amz-Target", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Signature")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Signature", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Content-Sha256", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Date")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Date", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Credential")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Credential", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Security-Token")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Security-Token", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Algorithm")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Algorithm", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-SignedHeaders", valid_606552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606554: Call_ListEventSubscriptions_606540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the event subscriptions for the assessment template that is specified by the ARN of the assessment template. For more information, see <a>SubscribeToEvent</a> and <a>UnsubscribeFromEvent</a>.
  ## 
  let valid = call_606554.validator(path, query, header, formData, body)
  let scheme = call_606554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606554.url(scheme.get, call_606554.host, call_606554.base,
                         call_606554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606554, url, valid)

proc call*(call_606555: Call_ListEventSubscriptions_606540; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listEventSubscriptions
  ## Lists all the event subscriptions for the assessment template that is specified by the ARN of the assessment template. For more information, see <a>SubscribeToEvent</a> and <a>UnsubscribeFromEvent</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606556 = newJObject()
  var body_606557 = newJObject()
  add(query_606556, "nextToken", newJString(nextToken))
  if body != nil:
    body_606557 = body
  add(query_606556, "maxResults", newJString(maxResults))
  result = call_606555.call(nil, query_606556, nil, nil, body_606557)

var listEventSubscriptions* = Call_ListEventSubscriptions_606540(
    name: "listEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListEventSubscriptions",
    validator: validate_ListEventSubscriptions_606541, base: "/",
    url: url_ListEventSubscriptions_606542, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExclusions_606558 = ref object of OpenApiRestCall_605589
proc url_ListExclusions_606560(protocol: Scheme; host: string; base: string;
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

proc validate_ListExclusions_606559(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## List exclusions that are generated by the assessment run.
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
  var valid_606561 = query.getOrDefault("nextToken")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "nextToken", valid_606561
  var valid_606562 = query.getOrDefault("maxResults")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "maxResults", valid_606562
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
  var valid_606563 = header.getOrDefault("X-Amz-Target")
  valid_606563 = validateParameter(valid_606563, JString, required = true, default = newJString(
      "InspectorService.ListExclusions"))
  if valid_606563 != nil:
    section.add "X-Amz-Target", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Signature")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Signature", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Content-Sha256", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Date")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Date", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Credential")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Credential", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Security-Token")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Security-Token", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Algorithm")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Algorithm", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-SignedHeaders", valid_606570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606572: Call_ListExclusions_606558; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List exclusions that are generated by the assessment run.
  ## 
  let valid = call_606572.validator(path, query, header, formData, body)
  let scheme = call_606572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606572.url(scheme.get, call_606572.host, call_606572.base,
                         call_606572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606572, url, valid)

proc call*(call_606573: Call_ListExclusions_606558; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listExclusions
  ## List exclusions that are generated by the assessment run.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606574 = newJObject()
  var body_606575 = newJObject()
  add(query_606574, "nextToken", newJString(nextToken))
  if body != nil:
    body_606575 = body
  add(query_606574, "maxResults", newJString(maxResults))
  result = call_606573.call(nil, query_606574, nil, nil, body_606575)

var listExclusions* = Call_ListExclusions_606558(name: "listExclusions",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListExclusions",
    validator: validate_ListExclusions_606559, base: "/", url: url_ListExclusions_606560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_606576 = ref object of OpenApiRestCall_605589
proc url_ListFindings_606578(protocol: Scheme; host: string; base: string;
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

proc validate_ListFindings_606577(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists findings that are generated by the assessment runs that are specified by the ARNs of the assessment runs.
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
  var valid_606579 = query.getOrDefault("nextToken")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "nextToken", valid_606579
  var valid_606580 = query.getOrDefault("maxResults")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "maxResults", valid_606580
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
  var valid_606581 = header.getOrDefault("X-Amz-Target")
  valid_606581 = validateParameter(valid_606581, JString, required = true, default = newJString(
      "InspectorService.ListFindings"))
  if valid_606581 != nil:
    section.add "X-Amz-Target", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Signature")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Signature", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Content-Sha256", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Date")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Date", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Credential")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Credential", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Security-Token")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Security-Token", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-Algorithm")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Algorithm", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-SignedHeaders", valid_606588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606590: Call_ListFindings_606576; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists findings that are generated by the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_606590.validator(path, query, header, formData, body)
  let scheme = call_606590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606590.url(scheme.get, call_606590.host, call_606590.base,
                         call_606590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606590, url, valid)

proc call*(call_606591: Call_ListFindings_606576; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listFindings
  ## Lists findings that are generated by the assessment runs that are specified by the ARNs of the assessment runs.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606592 = newJObject()
  var body_606593 = newJObject()
  add(query_606592, "nextToken", newJString(nextToken))
  if body != nil:
    body_606593 = body
  add(query_606592, "maxResults", newJString(maxResults))
  result = call_606591.call(nil, query_606592, nil, nil, body_606593)

var listFindings* = Call_ListFindings_606576(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListFindings",
    validator: validate_ListFindings_606577, base: "/", url: url_ListFindings_606578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRulesPackages_606594 = ref object of OpenApiRestCall_605589
proc url_ListRulesPackages_606596(protocol: Scheme; host: string; base: string;
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

proc validate_ListRulesPackages_606595(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists all available Amazon Inspector rules packages.
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
  var valid_606597 = query.getOrDefault("nextToken")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "nextToken", valid_606597
  var valid_606598 = query.getOrDefault("maxResults")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "maxResults", valid_606598
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
  var valid_606599 = header.getOrDefault("X-Amz-Target")
  valid_606599 = validateParameter(valid_606599, JString, required = true, default = newJString(
      "InspectorService.ListRulesPackages"))
  if valid_606599 != nil:
    section.add "X-Amz-Target", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Signature")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Signature", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Content-Sha256", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Date")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Date", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Credential")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Credential", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-Security-Token")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Security-Token", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Algorithm")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Algorithm", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-SignedHeaders", valid_606606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606608: Call_ListRulesPackages_606594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all available Amazon Inspector rules packages.
  ## 
  let valid = call_606608.validator(path, query, header, formData, body)
  let scheme = call_606608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606608.url(scheme.get, call_606608.host, call_606608.base,
                         call_606608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606608, url, valid)

proc call*(call_606609: Call_ListRulesPackages_606594; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRulesPackages
  ## Lists all available Amazon Inspector rules packages.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606610 = newJObject()
  var body_606611 = newJObject()
  add(query_606610, "nextToken", newJString(nextToken))
  if body != nil:
    body_606611 = body
  add(query_606610, "maxResults", newJString(maxResults))
  result = call_606609.call(nil, query_606610, nil, nil, body_606611)

var listRulesPackages* = Call_ListRulesPackages_606594(name: "listRulesPackages",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListRulesPackages",
    validator: validate_ListRulesPackages_606595, base: "/",
    url: url_ListRulesPackages_606596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606612 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606614(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606613(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all tags associated with an assessment template.
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
  var valid_606615 = header.getOrDefault("X-Amz-Target")
  valid_606615 = validateParameter(valid_606615, JString, required = true, default = newJString(
      "InspectorService.ListTagsForResource"))
  if valid_606615 != nil:
    section.add "X-Amz-Target", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Signature")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Signature", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Content-Sha256", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Date")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Date", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Credential")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Credential", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Security-Token")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Security-Token", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Algorithm")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Algorithm", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-SignedHeaders", valid_606622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606624: Call_ListTagsForResource_606612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags associated with an assessment template.
  ## 
  let valid = call_606624.validator(path, query, header, formData, body)
  let scheme = call_606624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606624.url(scheme.get, call_606624.host, call_606624.base,
                         call_606624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606624, url, valid)

proc call*(call_606625: Call_ListTagsForResource_606612; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags associated with an assessment template.
  ##   body: JObject (required)
  var body_606626 = newJObject()
  if body != nil:
    body_606626 = body
  result = call_606625.call(nil, nil, nil, nil, body_606626)

var listTagsForResource* = Call_ListTagsForResource_606612(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListTagsForResource",
    validator: validate_ListTagsForResource_606613, base: "/",
    url: url_ListTagsForResource_606614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PreviewAgents_606627 = ref object of OpenApiRestCall_605589
proc url_PreviewAgents_606629(protocol: Scheme; host: string; base: string;
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

proc validate_PreviewAgents_606628(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Previews the agents installed on the EC2 instances that are part of the specified assessment target.
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
  var valid_606630 = query.getOrDefault("nextToken")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "nextToken", valid_606630
  var valid_606631 = query.getOrDefault("maxResults")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "maxResults", valid_606631
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
  var valid_606632 = header.getOrDefault("X-Amz-Target")
  valid_606632 = validateParameter(valid_606632, JString, required = true, default = newJString(
      "InspectorService.PreviewAgents"))
  if valid_606632 != nil:
    section.add "X-Amz-Target", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-Signature")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-Signature", valid_606633
  var valid_606634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-Content-Sha256", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Date")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Date", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Credential")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Credential", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Security-Token")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Security-Token", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Algorithm")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Algorithm", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-SignedHeaders", valid_606639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606641: Call_PreviewAgents_606627; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Previews the agents installed on the EC2 instances that are part of the specified assessment target.
  ## 
  let valid = call_606641.validator(path, query, header, formData, body)
  let scheme = call_606641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606641.url(scheme.get, call_606641.host, call_606641.base,
                         call_606641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606641, url, valid)

proc call*(call_606642: Call_PreviewAgents_606627; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## previewAgents
  ## Previews the agents installed on the EC2 instances that are part of the specified assessment target.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606643 = newJObject()
  var body_606644 = newJObject()
  add(query_606643, "nextToken", newJString(nextToken))
  if body != nil:
    body_606644 = body
  add(query_606643, "maxResults", newJString(maxResults))
  result = call_606642.call(nil, query_606643, nil, nil, body_606644)

var previewAgents* = Call_PreviewAgents_606627(name: "previewAgents",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.PreviewAgents",
    validator: validate_PreviewAgents_606628, base: "/", url: url_PreviewAgents_606629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterCrossAccountAccessRole_606645 = ref object of OpenApiRestCall_605589
proc url_RegisterCrossAccountAccessRole_606647(protocol: Scheme; host: string;
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

proc validate_RegisterCrossAccountAccessRole_606646(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers the IAM role that grants Amazon Inspector access to AWS Services needed to perform security assessments.
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
  var valid_606648 = header.getOrDefault("X-Amz-Target")
  valid_606648 = validateParameter(valid_606648, JString, required = true, default = newJString(
      "InspectorService.RegisterCrossAccountAccessRole"))
  if valid_606648 != nil:
    section.add "X-Amz-Target", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-Signature")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-Signature", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Content-Sha256", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Date")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Date", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Credential")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Credential", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Security-Token")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Security-Token", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Algorithm")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Algorithm", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-SignedHeaders", valid_606655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606657: Call_RegisterCrossAccountAccessRole_606645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the IAM role that grants Amazon Inspector access to AWS Services needed to perform security assessments.
  ## 
  let valid = call_606657.validator(path, query, header, formData, body)
  let scheme = call_606657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606657.url(scheme.get, call_606657.host, call_606657.base,
                         call_606657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606657, url, valid)

proc call*(call_606658: Call_RegisterCrossAccountAccessRole_606645; body: JsonNode): Recallable =
  ## registerCrossAccountAccessRole
  ## Registers the IAM role that grants Amazon Inspector access to AWS Services needed to perform security assessments.
  ##   body: JObject (required)
  var body_606659 = newJObject()
  if body != nil:
    body_606659 = body
  result = call_606658.call(nil, nil, nil, nil, body_606659)

var registerCrossAccountAccessRole* = Call_RegisterCrossAccountAccessRole_606645(
    name: "registerCrossAccountAccessRole", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.RegisterCrossAccountAccessRole",
    validator: validate_RegisterCrossAccountAccessRole_606646, base: "/",
    url: url_RegisterCrossAccountAccessRole_606647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributesFromFindings_606660 = ref object of OpenApiRestCall_605589
proc url_RemoveAttributesFromFindings_606662(protocol: Scheme; host: string;
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

proc validate_RemoveAttributesFromFindings_606661(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes entire attributes (key and value pairs) from the findings that are specified by the ARNs of the findings where an attribute with the specified key exists.
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
  var valid_606663 = header.getOrDefault("X-Amz-Target")
  valid_606663 = validateParameter(valid_606663, JString, required = true, default = newJString(
      "InspectorService.RemoveAttributesFromFindings"))
  if valid_606663 != nil:
    section.add "X-Amz-Target", valid_606663
  var valid_606664 = header.getOrDefault("X-Amz-Signature")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "X-Amz-Signature", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Content-Sha256", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Date")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Date", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Credential")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Credential", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Security-Token")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Security-Token", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Algorithm")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Algorithm", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-SignedHeaders", valid_606670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606672: Call_RemoveAttributesFromFindings_606660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes entire attributes (key and value pairs) from the findings that are specified by the ARNs of the findings where an attribute with the specified key exists.
  ## 
  let valid = call_606672.validator(path, query, header, formData, body)
  let scheme = call_606672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606672.url(scheme.get, call_606672.host, call_606672.base,
                         call_606672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606672, url, valid)

proc call*(call_606673: Call_RemoveAttributesFromFindings_606660; body: JsonNode): Recallable =
  ## removeAttributesFromFindings
  ## Removes entire attributes (key and value pairs) from the findings that are specified by the ARNs of the findings where an attribute with the specified key exists.
  ##   body: JObject (required)
  var body_606674 = newJObject()
  if body != nil:
    body_606674 = body
  result = call_606673.call(nil, nil, nil, nil, body_606674)

var removeAttributesFromFindings* = Call_RemoveAttributesFromFindings_606660(
    name: "removeAttributesFromFindings", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.RemoveAttributesFromFindings",
    validator: validate_RemoveAttributesFromFindings_606661, base: "/",
    url: url_RemoveAttributesFromFindings_606662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetTagsForResource_606675 = ref object of OpenApiRestCall_605589
proc url_SetTagsForResource_606677(protocol: Scheme; host: string; base: string;
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

proc validate_SetTagsForResource_606676(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Sets tags (key and value pairs) to the assessment template that is specified by the ARN of the assessment template.
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
  var valid_606678 = header.getOrDefault("X-Amz-Target")
  valid_606678 = validateParameter(valid_606678, JString, required = true, default = newJString(
      "InspectorService.SetTagsForResource"))
  if valid_606678 != nil:
    section.add "X-Amz-Target", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Signature")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Signature", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Content-Sha256", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Date")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Date", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Credential")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Credential", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Security-Token")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Security-Token", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Algorithm")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Algorithm", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-SignedHeaders", valid_606685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606687: Call_SetTagsForResource_606675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets tags (key and value pairs) to the assessment template that is specified by the ARN of the assessment template.
  ## 
  let valid = call_606687.validator(path, query, header, formData, body)
  let scheme = call_606687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606687.url(scheme.get, call_606687.host, call_606687.base,
                         call_606687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606687, url, valid)

proc call*(call_606688: Call_SetTagsForResource_606675; body: JsonNode): Recallable =
  ## setTagsForResource
  ## Sets tags (key and value pairs) to the assessment template that is specified by the ARN of the assessment template.
  ##   body: JObject (required)
  var body_606689 = newJObject()
  if body != nil:
    body_606689 = body
  result = call_606688.call(nil, nil, nil, nil, body_606689)

var setTagsForResource* = Call_SetTagsForResource_606675(
    name: "setTagsForResource", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.SetTagsForResource",
    validator: validate_SetTagsForResource_606676, base: "/",
    url: url_SetTagsForResource_606677, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssessmentRun_606690 = ref object of OpenApiRestCall_605589
proc url_StartAssessmentRun_606692(protocol: Scheme; host: string; base: string;
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

proc validate_StartAssessmentRun_606691(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Starts the assessment run specified by the ARN of the assessment template. For this API to function properly, you must not exceed the limit of running up to 500 concurrent agents per AWS account.
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
  var valid_606693 = header.getOrDefault("X-Amz-Target")
  valid_606693 = validateParameter(valid_606693, JString, required = true, default = newJString(
      "InspectorService.StartAssessmentRun"))
  if valid_606693 != nil:
    section.add "X-Amz-Target", valid_606693
  var valid_606694 = header.getOrDefault("X-Amz-Signature")
  valid_606694 = validateParameter(valid_606694, JString, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "X-Amz-Signature", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Content-Sha256", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Date")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Date", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Credential")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Credential", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Security-Token")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Security-Token", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Algorithm")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Algorithm", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-SignedHeaders", valid_606700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606702: Call_StartAssessmentRun_606690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the assessment run specified by the ARN of the assessment template. For this API to function properly, you must not exceed the limit of running up to 500 concurrent agents per AWS account.
  ## 
  let valid = call_606702.validator(path, query, header, formData, body)
  let scheme = call_606702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606702.url(scheme.get, call_606702.host, call_606702.base,
                         call_606702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606702, url, valid)

proc call*(call_606703: Call_StartAssessmentRun_606690; body: JsonNode): Recallable =
  ## startAssessmentRun
  ## Starts the assessment run specified by the ARN of the assessment template. For this API to function properly, you must not exceed the limit of running up to 500 concurrent agents per AWS account.
  ##   body: JObject (required)
  var body_606704 = newJObject()
  if body != nil:
    body_606704 = body
  result = call_606703.call(nil, nil, nil, nil, body_606704)

var startAssessmentRun* = Call_StartAssessmentRun_606690(
    name: "startAssessmentRun", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.StartAssessmentRun",
    validator: validate_StartAssessmentRun_606691, base: "/",
    url: url_StartAssessmentRun_606692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAssessmentRun_606705 = ref object of OpenApiRestCall_605589
proc url_StopAssessmentRun_606707(protocol: Scheme; host: string; base: string;
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

proc validate_StopAssessmentRun_606706(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Stops the assessment run that is specified by the ARN of the assessment run.
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
  var valid_606708 = header.getOrDefault("X-Amz-Target")
  valid_606708 = validateParameter(valid_606708, JString, required = true, default = newJString(
      "InspectorService.StopAssessmentRun"))
  if valid_606708 != nil:
    section.add "X-Amz-Target", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Signature")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Signature", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Content-Sha256", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Date")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Date", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Credential")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Credential", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Security-Token")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Security-Token", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Algorithm")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Algorithm", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-SignedHeaders", valid_606715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606717: Call_StopAssessmentRun_606705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the assessment run that is specified by the ARN of the assessment run.
  ## 
  let valid = call_606717.validator(path, query, header, formData, body)
  let scheme = call_606717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606717.url(scheme.get, call_606717.host, call_606717.base,
                         call_606717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606717, url, valid)

proc call*(call_606718: Call_StopAssessmentRun_606705; body: JsonNode): Recallable =
  ## stopAssessmentRun
  ## Stops the assessment run that is specified by the ARN of the assessment run.
  ##   body: JObject (required)
  var body_606719 = newJObject()
  if body != nil:
    body_606719 = body
  result = call_606718.call(nil, nil, nil, nil, body_606719)

var stopAssessmentRun* = Call_StopAssessmentRun_606705(name: "stopAssessmentRun",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.StopAssessmentRun",
    validator: validate_StopAssessmentRun_606706, base: "/",
    url: url_StopAssessmentRun_606707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubscribeToEvent_606720 = ref object of OpenApiRestCall_605589
proc url_SubscribeToEvent_606722(protocol: Scheme; host: string; base: string;
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

proc validate_SubscribeToEvent_606721(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Enables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
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
  var valid_606723 = header.getOrDefault("X-Amz-Target")
  valid_606723 = validateParameter(valid_606723, JString, required = true, default = newJString(
      "InspectorService.SubscribeToEvent"))
  if valid_606723 != nil:
    section.add "X-Amz-Target", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Signature")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Signature", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Content-Sha256", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Date")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Date", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Credential")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Credential", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Security-Token")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Security-Token", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Algorithm")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Algorithm", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-SignedHeaders", valid_606730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606732: Call_SubscribeToEvent_606720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ## 
  let valid = call_606732.validator(path, query, header, formData, body)
  let scheme = call_606732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606732.url(scheme.get, call_606732.host, call_606732.base,
                         call_606732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606732, url, valid)

proc call*(call_606733: Call_SubscribeToEvent_606720; body: JsonNode): Recallable =
  ## subscribeToEvent
  ## Enables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ##   body: JObject (required)
  var body_606734 = newJObject()
  if body != nil:
    body_606734 = body
  result = call_606733.call(nil, nil, nil, nil, body_606734)

var subscribeToEvent* = Call_SubscribeToEvent_606720(name: "subscribeToEvent",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.SubscribeToEvent",
    validator: validate_SubscribeToEvent_606721, base: "/",
    url: url_SubscribeToEvent_606722, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnsubscribeFromEvent_606735 = ref object of OpenApiRestCall_605589
proc url_UnsubscribeFromEvent_606737(protocol: Scheme; host: string; base: string;
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

proc validate_UnsubscribeFromEvent_606736(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
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
  var valid_606738 = header.getOrDefault("X-Amz-Target")
  valid_606738 = validateParameter(valid_606738, JString, required = true, default = newJString(
      "InspectorService.UnsubscribeFromEvent"))
  if valid_606738 != nil:
    section.add "X-Amz-Target", valid_606738
  var valid_606739 = header.getOrDefault("X-Amz-Signature")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-Signature", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Content-Sha256", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-Date")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Date", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Credential")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Credential", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Security-Token")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Security-Token", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Algorithm")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Algorithm", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-SignedHeaders", valid_606745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606747: Call_UnsubscribeFromEvent_606735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ## 
  let valid = call_606747.validator(path, query, header, formData, body)
  let scheme = call_606747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606747.url(scheme.get, call_606747.host, call_606747.base,
                         call_606747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606747, url, valid)

proc call*(call_606748: Call_UnsubscribeFromEvent_606735; body: JsonNode): Recallable =
  ## unsubscribeFromEvent
  ## Disables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ##   body: JObject (required)
  var body_606749 = newJObject()
  if body != nil:
    body_606749 = body
  result = call_606748.call(nil, nil, nil, nil, body_606749)

var unsubscribeFromEvent* = Call_UnsubscribeFromEvent_606735(
    name: "unsubscribeFromEvent", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.UnsubscribeFromEvent",
    validator: validate_UnsubscribeFromEvent_606736, base: "/",
    url: url_UnsubscribeFromEvent_606737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssessmentTarget_606750 = ref object of OpenApiRestCall_605589
proc url_UpdateAssessmentTarget_606752(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAssessmentTarget_606751(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the assessment target that is specified by the ARN of the assessment target.</p> <p>If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target.</p>
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
  var valid_606753 = header.getOrDefault("X-Amz-Target")
  valid_606753 = validateParameter(valid_606753, JString, required = true, default = newJString(
      "InspectorService.UpdateAssessmentTarget"))
  if valid_606753 != nil:
    section.add "X-Amz-Target", valid_606753
  var valid_606754 = header.getOrDefault("X-Amz-Signature")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-Signature", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Content-Sha256", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Date")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Date", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Credential")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Credential", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Security-Token")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Security-Token", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Algorithm")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Algorithm", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-SignedHeaders", valid_606760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606762: Call_UpdateAssessmentTarget_606750; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the assessment target that is specified by the ARN of the assessment target.</p> <p>If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target.</p>
  ## 
  let valid = call_606762.validator(path, query, header, formData, body)
  let scheme = call_606762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606762.url(scheme.get, call_606762.host, call_606762.base,
                         call_606762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606762, url, valid)

proc call*(call_606763: Call_UpdateAssessmentTarget_606750; body: JsonNode): Recallable =
  ## updateAssessmentTarget
  ## <p>Updates the assessment target that is specified by the ARN of the assessment target.</p> <p>If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target.</p>
  ##   body: JObject (required)
  var body_606764 = newJObject()
  if body != nil:
    body_606764 = body
  result = call_606763.call(nil, nil, nil, nil, body_606764)

var updateAssessmentTarget* = Call_UpdateAssessmentTarget_606750(
    name: "updateAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.UpdateAssessmentTarget",
    validator: validate_UpdateAssessmentTarget_606751, base: "/",
    url: url_UpdateAssessmentTarget_606752, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
