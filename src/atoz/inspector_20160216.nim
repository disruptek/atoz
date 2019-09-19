
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddAttributesToFindings_772933 = ref object of OpenApiRestCall_772597
proc url_AddAttributesToFindings_772935(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddAttributesToFindings_772934(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773062 = header.getOrDefault("X-Amz-Target")
  valid_773062 = validateParameter(valid_773062, JString, required = true, default = newJString(
      "InspectorService.AddAttributesToFindings"))
  if valid_773062 != nil:
    section.add "X-Amz-Target", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Content-Sha256", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Algorithm")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Algorithm", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Signature")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Signature", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-SignedHeaders", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Credential")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Credential", valid_773067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773091: Call_AddAttributesToFindings_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns attributes (key and value pairs) to the findings that are specified by the ARNs of the findings.
  ## 
  let valid = call_773091.validator(path, query, header, formData, body)
  let scheme = call_773091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773091.url(scheme.get, call_773091.host, call_773091.base,
                         call_773091.route, valid.getOrDefault("path"))
  result = hook(call_773091, url, valid)

proc call*(call_773162: Call_AddAttributesToFindings_772933; body: JsonNode): Recallable =
  ## addAttributesToFindings
  ## Assigns attributes (key and value pairs) to the findings that are specified by the ARNs of the findings.
  ##   body: JObject (required)
  var body_773163 = newJObject()
  if body != nil:
    body_773163 = body
  result = call_773162.call(nil, nil, nil, nil, body_773163)

var addAttributesToFindings* = Call_AddAttributesToFindings_772933(
    name: "addAttributesToFindings", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.AddAttributesToFindings",
    validator: validate_AddAttributesToFindings_772934, base: "/",
    url: url_AddAttributesToFindings_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssessmentTarget_773202 = ref object of OpenApiRestCall_772597
proc url_CreateAssessmentTarget_773204(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAssessmentTarget_773203(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773207 = header.getOrDefault("X-Amz-Target")
  valid_773207 = validateParameter(valid_773207, JString, required = true, default = newJString(
      "InspectorService.CreateAssessmentTarget"))
  if valid_773207 != nil:
    section.add "X-Amz-Target", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_CreateAssessmentTarget_773202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new assessment target using the ARN of the resource group that is generated by <a>CreateResourceGroup</a>. If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments. You can create up to 50 assessment targets per AWS account. You can run up to 500 concurrent agents per AWS account. For more information, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html"> Amazon Inspector Assessment Targets</a>.
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_CreateAssessmentTarget_773202; body: JsonNode): Recallable =
  ## createAssessmentTarget
  ## Creates a new assessment target using the ARN of the resource group that is generated by <a>CreateResourceGroup</a>. If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments. You can create up to 50 assessment targets per AWS account. You can run up to 500 concurrent agents per AWS account. For more information, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html"> Amazon Inspector Assessment Targets</a>.
  ##   body: JObject (required)
  var body_773216 = newJObject()
  if body != nil:
    body_773216 = body
  result = call_773215.call(nil, nil, nil, nil, body_773216)

var createAssessmentTarget* = Call_CreateAssessmentTarget_773202(
    name: "createAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateAssessmentTarget",
    validator: validate_CreateAssessmentTarget_773203, base: "/",
    url: url_CreateAssessmentTarget_773204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssessmentTemplate_773217 = ref object of OpenApiRestCall_772597
proc url_CreateAssessmentTemplate_773219(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAssessmentTemplate_773218(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773222 = header.getOrDefault("X-Amz-Target")
  valid_773222 = validateParameter(valid_773222, JString, required = true, default = newJString(
      "InspectorService.CreateAssessmentTemplate"))
  if valid_773222 != nil:
    section.add "X-Amz-Target", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773229: Call_CreateAssessmentTemplate_773217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an assessment template for the assessment target that is specified by the ARN of the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments.
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_CreateAssessmentTemplate_773217; body: JsonNode): Recallable =
  ## createAssessmentTemplate
  ## Creates an assessment template for the assessment target that is specified by the ARN of the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments.
  ##   body: JObject (required)
  var body_773231 = newJObject()
  if body != nil:
    body_773231 = body
  result = call_773230.call(nil, nil, nil, nil, body_773231)

var createAssessmentTemplate* = Call_CreateAssessmentTemplate_773217(
    name: "createAssessmentTemplate", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateAssessmentTemplate",
    validator: validate_CreateAssessmentTemplate_773218, base: "/",
    url: url_CreateAssessmentTemplate_773219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExclusionsPreview_773232 = ref object of OpenApiRestCall_772597
proc url_CreateExclusionsPreview_773234(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateExclusionsPreview_773233(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773235 = header.getOrDefault("X-Amz-Date")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Date", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Security-Token")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Security-Token", valid_773236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773237 = header.getOrDefault("X-Amz-Target")
  valid_773237 = validateParameter(valid_773237, JString, required = true, default = newJString(
      "InspectorService.CreateExclusionsPreview"))
  if valid_773237 != nil:
    section.add "X-Amz-Target", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Content-Sha256", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Algorithm")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Algorithm", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Signature")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Signature", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-SignedHeaders", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Credential")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Credential", valid_773242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_CreateExclusionsPreview_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the generation of an exclusions preview for the specified assessment template. The exclusions preview lists the potential exclusions (ExclusionPreview) that Inspector can detect before it runs the assessment. 
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_CreateExclusionsPreview_773232; body: JsonNode): Recallable =
  ## createExclusionsPreview
  ## Starts the generation of an exclusions preview for the specified assessment template. The exclusions preview lists the potential exclusions (ExclusionPreview) that Inspector can detect before it runs the assessment. 
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var createExclusionsPreview* = Call_CreateExclusionsPreview_773232(
    name: "createExclusionsPreview", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateExclusionsPreview",
    validator: validate_CreateExclusionsPreview_773233, base: "/",
    url: url_CreateExclusionsPreview_773234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceGroup_773247 = ref object of OpenApiRestCall_772597
proc url_CreateResourceGroup_773249(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateResourceGroup_773248(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773252 = header.getOrDefault("X-Amz-Target")
  valid_773252 = validateParameter(valid_773252, JString, required = true, default = newJString(
      "InspectorService.CreateResourceGroup"))
  if valid_773252 != nil:
    section.add "X-Amz-Target", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Content-Sha256", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Algorithm")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Algorithm", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Signature", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-SignedHeaders", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Credential")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Credential", valid_773257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_CreateResourceGroup_773247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource group using the specified set of tags (key and value pairs) that are used to select the EC2 instances to be included in an Amazon Inspector assessment target. The created resource group is then used to create an Amazon Inspector assessment target. For more information, see <a>CreateAssessmentTarget</a>.
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_CreateResourceGroup_773247; body: JsonNode): Recallable =
  ## createResourceGroup
  ## Creates a resource group using the specified set of tags (key and value pairs) that are used to select the EC2 instances to be included in an Amazon Inspector assessment target. The created resource group is then used to create an Amazon Inspector assessment target. For more information, see <a>CreateAssessmentTarget</a>.
  ##   body: JObject (required)
  var body_773261 = newJObject()
  if body != nil:
    body_773261 = body
  result = call_773260.call(nil, nil, nil, nil, body_773261)

var createResourceGroup* = Call_CreateResourceGroup_773247(
    name: "createResourceGroup", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateResourceGroup",
    validator: validate_CreateResourceGroup_773248, base: "/",
    url: url_CreateResourceGroup_773249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentRun_773262 = ref object of OpenApiRestCall_772597
proc url_DeleteAssessmentRun_773264(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAssessmentRun_773263(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773265 = header.getOrDefault("X-Amz-Date")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Date", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Security-Token")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Security-Token", valid_773266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773267 = header.getOrDefault("X-Amz-Target")
  valid_773267 = validateParameter(valid_773267, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentRun"))
  if valid_773267 != nil:
    section.add "X-Amz-Target", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Content-Sha256", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Algorithm")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Algorithm", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Signature")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Signature", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-SignedHeaders", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Credential")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Credential", valid_773272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773274: Call_DeleteAssessmentRun_773262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment run that is specified by the ARN of the assessment run.
  ## 
  let valid = call_773274.validator(path, query, header, formData, body)
  let scheme = call_773274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773274.url(scheme.get, call_773274.host, call_773274.base,
                         call_773274.route, valid.getOrDefault("path"))
  result = hook(call_773274, url, valid)

proc call*(call_773275: Call_DeleteAssessmentRun_773262; body: JsonNode): Recallable =
  ## deleteAssessmentRun
  ## Deletes the assessment run that is specified by the ARN of the assessment run.
  ##   body: JObject (required)
  var body_773276 = newJObject()
  if body != nil:
    body_773276 = body
  result = call_773275.call(nil, nil, nil, nil, body_773276)

var deleteAssessmentRun* = Call_DeleteAssessmentRun_773262(
    name: "deleteAssessmentRun", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentRun",
    validator: validate_DeleteAssessmentRun_773263, base: "/",
    url: url_DeleteAssessmentRun_773264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentTarget_773277 = ref object of OpenApiRestCall_772597
proc url_DeleteAssessmentTarget_773279(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAssessmentTarget_773278(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773280 = header.getOrDefault("X-Amz-Date")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Date", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Security-Token")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Security-Token", valid_773281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773282 = header.getOrDefault("X-Amz-Target")
  valid_773282 = validateParameter(valid_773282, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentTarget"))
  if valid_773282 != nil:
    section.add "X-Amz-Target", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Content-Sha256", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Algorithm")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Algorithm", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Signature")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Signature", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-SignedHeaders", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Credential")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Credential", valid_773287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773289: Call_DeleteAssessmentTarget_773277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment target that is specified by the ARN of the assessment target.
  ## 
  let valid = call_773289.validator(path, query, header, formData, body)
  let scheme = call_773289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773289.url(scheme.get, call_773289.host, call_773289.base,
                         call_773289.route, valid.getOrDefault("path"))
  result = hook(call_773289, url, valid)

proc call*(call_773290: Call_DeleteAssessmentTarget_773277; body: JsonNode): Recallable =
  ## deleteAssessmentTarget
  ## Deletes the assessment target that is specified by the ARN of the assessment target.
  ##   body: JObject (required)
  var body_773291 = newJObject()
  if body != nil:
    body_773291 = body
  result = call_773290.call(nil, nil, nil, nil, body_773291)

var deleteAssessmentTarget* = Call_DeleteAssessmentTarget_773277(
    name: "deleteAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentTarget",
    validator: validate_DeleteAssessmentTarget_773278, base: "/",
    url: url_DeleteAssessmentTarget_773279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentTemplate_773292 = ref object of OpenApiRestCall_772597
proc url_DeleteAssessmentTemplate_773294(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAssessmentTemplate_773293(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773295 = header.getOrDefault("X-Amz-Date")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Date", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Security-Token")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Security-Token", valid_773296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773297 = header.getOrDefault("X-Amz-Target")
  valid_773297 = validateParameter(valid_773297, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentTemplate"))
  if valid_773297 != nil:
    section.add "X-Amz-Target", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Content-Sha256", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Algorithm")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Algorithm", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Signature")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Signature", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-SignedHeaders", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Credential")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Credential", valid_773302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773304: Call_DeleteAssessmentTemplate_773292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment template that is specified by the ARN of the assessment template.
  ## 
  let valid = call_773304.validator(path, query, header, formData, body)
  let scheme = call_773304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773304.url(scheme.get, call_773304.host, call_773304.base,
                         call_773304.route, valid.getOrDefault("path"))
  result = hook(call_773304, url, valid)

proc call*(call_773305: Call_DeleteAssessmentTemplate_773292; body: JsonNode): Recallable =
  ## deleteAssessmentTemplate
  ## Deletes the assessment template that is specified by the ARN of the assessment template.
  ##   body: JObject (required)
  var body_773306 = newJObject()
  if body != nil:
    body_773306 = body
  result = call_773305.call(nil, nil, nil, nil, body_773306)

var deleteAssessmentTemplate* = Call_DeleteAssessmentTemplate_773292(
    name: "deleteAssessmentTemplate", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentTemplate",
    validator: validate_DeleteAssessmentTemplate_773293, base: "/",
    url: url_DeleteAssessmentTemplate_773294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentRuns_773307 = ref object of OpenApiRestCall_772597
proc url_DescribeAssessmentRuns_773309(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAssessmentRuns_773308(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773310 = header.getOrDefault("X-Amz-Date")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Date", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Security-Token")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Security-Token", valid_773311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773312 = header.getOrDefault("X-Amz-Target")
  valid_773312 = validateParameter(valid_773312, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentRuns"))
  if valid_773312 != nil:
    section.add "X-Amz-Target", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Content-Sha256", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Algorithm")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Algorithm", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Signature")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Signature", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-SignedHeaders", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Credential")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Credential", valid_773317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773319: Call_DescribeAssessmentRuns_773307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_773319.validator(path, query, header, formData, body)
  let scheme = call_773319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773319.url(scheme.get, call_773319.host, call_773319.base,
                         call_773319.route, valid.getOrDefault("path"))
  result = hook(call_773319, url, valid)

proc call*(call_773320: Call_DescribeAssessmentRuns_773307; body: JsonNode): Recallable =
  ## describeAssessmentRuns
  ## Describes the assessment runs that are specified by the ARNs of the assessment runs.
  ##   body: JObject (required)
  var body_773321 = newJObject()
  if body != nil:
    body_773321 = body
  result = call_773320.call(nil, nil, nil, nil, body_773321)

var describeAssessmentRuns* = Call_DescribeAssessmentRuns_773307(
    name: "describeAssessmentRuns", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentRuns",
    validator: validate_DescribeAssessmentRuns_773308, base: "/",
    url: url_DescribeAssessmentRuns_773309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentTargets_773322 = ref object of OpenApiRestCall_772597
proc url_DescribeAssessmentTargets_773324(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAssessmentTargets_773323(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773325 = header.getOrDefault("X-Amz-Date")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Date", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Security-Token")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Security-Token", valid_773326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773327 = header.getOrDefault("X-Amz-Target")
  valid_773327 = validateParameter(valid_773327, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentTargets"))
  if valid_773327 != nil:
    section.add "X-Amz-Target", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Content-Sha256", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Algorithm")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Algorithm", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Signature")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Signature", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-SignedHeaders", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Credential")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Credential", valid_773332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773334: Call_DescribeAssessmentTargets_773322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment targets that are specified by the ARNs of the assessment targets.
  ## 
  let valid = call_773334.validator(path, query, header, formData, body)
  let scheme = call_773334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773334.url(scheme.get, call_773334.host, call_773334.base,
                         call_773334.route, valid.getOrDefault("path"))
  result = hook(call_773334, url, valid)

proc call*(call_773335: Call_DescribeAssessmentTargets_773322; body: JsonNode): Recallable =
  ## describeAssessmentTargets
  ## Describes the assessment targets that are specified by the ARNs of the assessment targets.
  ##   body: JObject (required)
  var body_773336 = newJObject()
  if body != nil:
    body_773336 = body
  result = call_773335.call(nil, nil, nil, nil, body_773336)

var describeAssessmentTargets* = Call_DescribeAssessmentTargets_773322(
    name: "describeAssessmentTargets", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentTargets",
    validator: validate_DescribeAssessmentTargets_773323, base: "/",
    url: url_DescribeAssessmentTargets_773324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentTemplates_773337 = ref object of OpenApiRestCall_772597
proc url_DescribeAssessmentTemplates_773339(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAssessmentTemplates_773338(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773340 = header.getOrDefault("X-Amz-Date")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Date", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Security-Token")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Security-Token", valid_773341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773342 = header.getOrDefault("X-Amz-Target")
  valid_773342 = validateParameter(valid_773342, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentTemplates"))
  if valid_773342 != nil:
    section.add "X-Amz-Target", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Content-Sha256", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Algorithm")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Algorithm", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Signature")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Signature", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-SignedHeaders", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Credential")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Credential", valid_773347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773349: Call_DescribeAssessmentTemplates_773337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment templates that are specified by the ARNs of the assessment templates.
  ## 
  let valid = call_773349.validator(path, query, header, formData, body)
  let scheme = call_773349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773349.url(scheme.get, call_773349.host, call_773349.base,
                         call_773349.route, valid.getOrDefault("path"))
  result = hook(call_773349, url, valid)

proc call*(call_773350: Call_DescribeAssessmentTemplates_773337; body: JsonNode): Recallable =
  ## describeAssessmentTemplates
  ## Describes the assessment templates that are specified by the ARNs of the assessment templates.
  ##   body: JObject (required)
  var body_773351 = newJObject()
  if body != nil:
    body_773351 = body
  result = call_773350.call(nil, nil, nil, nil, body_773351)

var describeAssessmentTemplates* = Call_DescribeAssessmentTemplates_773337(
    name: "describeAssessmentTemplates", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentTemplates",
    validator: validate_DescribeAssessmentTemplates_773338, base: "/",
    url: url_DescribeAssessmentTemplates_773339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCrossAccountAccessRole_773352 = ref object of OpenApiRestCall_772597
proc url_DescribeCrossAccountAccessRole_773354(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCrossAccountAccessRole_773353(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773355 = header.getOrDefault("X-Amz-Date")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Date", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Security-Token")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Security-Token", valid_773356
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773357 = header.getOrDefault("X-Amz-Target")
  valid_773357 = validateParameter(valid_773357, JString, required = true, default = newJString(
      "InspectorService.DescribeCrossAccountAccessRole"))
  if valid_773357 != nil:
    section.add "X-Amz-Target", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Content-Sha256", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Algorithm", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Signature")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Signature", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-SignedHeaders", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Credential")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Credential", valid_773362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773363: Call_DescribeCrossAccountAccessRole_773352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the IAM role that enables Amazon Inspector to access your AWS account.
  ## 
  let valid = call_773363.validator(path, query, header, formData, body)
  let scheme = call_773363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773363.url(scheme.get, call_773363.host, call_773363.base,
                         call_773363.route, valid.getOrDefault("path"))
  result = hook(call_773363, url, valid)

proc call*(call_773364: Call_DescribeCrossAccountAccessRole_773352): Recallable =
  ## describeCrossAccountAccessRole
  ## Describes the IAM role that enables Amazon Inspector to access your AWS account.
  result = call_773364.call(nil, nil, nil, nil, nil)

var describeCrossAccountAccessRole* = Call_DescribeCrossAccountAccessRole_773352(
    name: "describeCrossAccountAccessRole", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeCrossAccountAccessRole",
    validator: validate_DescribeCrossAccountAccessRole_773353, base: "/",
    url: url_DescribeCrossAccountAccessRole_773354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExclusions_773365 = ref object of OpenApiRestCall_772597
proc url_DescribeExclusions_773367(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeExclusions_773366(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773368 = header.getOrDefault("X-Amz-Date")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Date", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Security-Token")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Security-Token", valid_773369
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773370 = header.getOrDefault("X-Amz-Target")
  valid_773370 = validateParameter(valid_773370, JString, required = true, default = newJString(
      "InspectorService.DescribeExclusions"))
  if valid_773370 != nil:
    section.add "X-Amz-Target", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Content-Sha256", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Algorithm")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Algorithm", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Signature")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Signature", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-SignedHeaders", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Credential")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Credential", valid_773375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773377: Call_DescribeExclusions_773365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the exclusions that are specified by the exclusions' ARNs.
  ## 
  let valid = call_773377.validator(path, query, header, formData, body)
  let scheme = call_773377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773377.url(scheme.get, call_773377.host, call_773377.base,
                         call_773377.route, valid.getOrDefault("path"))
  result = hook(call_773377, url, valid)

proc call*(call_773378: Call_DescribeExclusions_773365; body: JsonNode): Recallable =
  ## describeExclusions
  ## Describes the exclusions that are specified by the exclusions' ARNs.
  ##   body: JObject (required)
  var body_773379 = newJObject()
  if body != nil:
    body_773379 = body
  result = call_773378.call(nil, nil, nil, nil, body_773379)

var describeExclusions* = Call_DescribeExclusions_773365(
    name: "describeExclusions", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeExclusions",
    validator: validate_DescribeExclusions_773366, base: "/",
    url: url_DescribeExclusions_773367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFindings_773380 = ref object of OpenApiRestCall_772597
proc url_DescribeFindings_773382(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeFindings_773381(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773383 = header.getOrDefault("X-Amz-Date")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Date", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-Security-Token")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-Security-Token", valid_773384
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773385 = header.getOrDefault("X-Amz-Target")
  valid_773385 = validateParameter(valid_773385, JString, required = true, default = newJString(
      "InspectorService.DescribeFindings"))
  if valid_773385 != nil:
    section.add "X-Amz-Target", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Content-Sha256", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Algorithm")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Algorithm", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Signature")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Signature", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-SignedHeaders", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Credential")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Credential", valid_773390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773392: Call_DescribeFindings_773380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the findings that are specified by the ARNs of the findings.
  ## 
  let valid = call_773392.validator(path, query, header, formData, body)
  let scheme = call_773392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773392.url(scheme.get, call_773392.host, call_773392.base,
                         call_773392.route, valid.getOrDefault("path"))
  result = hook(call_773392, url, valid)

proc call*(call_773393: Call_DescribeFindings_773380; body: JsonNode): Recallable =
  ## describeFindings
  ## Describes the findings that are specified by the ARNs of the findings.
  ##   body: JObject (required)
  var body_773394 = newJObject()
  if body != nil:
    body_773394 = body
  result = call_773393.call(nil, nil, nil, nil, body_773394)

var describeFindings* = Call_DescribeFindings_773380(name: "describeFindings",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeFindings",
    validator: validate_DescribeFindings_773381, base: "/",
    url: url_DescribeFindings_773382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceGroups_773395 = ref object of OpenApiRestCall_772597
proc url_DescribeResourceGroups_773397(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeResourceGroups_773396(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773398 = header.getOrDefault("X-Amz-Date")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Date", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Security-Token")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Security-Token", valid_773399
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773400 = header.getOrDefault("X-Amz-Target")
  valid_773400 = validateParameter(valid_773400, JString, required = true, default = newJString(
      "InspectorService.DescribeResourceGroups"))
  if valid_773400 != nil:
    section.add "X-Amz-Target", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Content-Sha256", valid_773401
  var valid_773402 = header.getOrDefault("X-Amz-Algorithm")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Algorithm", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Signature")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Signature", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-SignedHeaders", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Credential")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Credential", valid_773405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773407: Call_DescribeResourceGroups_773395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the resource groups that are specified by the ARNs of the resource groups.
  ## 
  let valid = call_773407.validator(path, query, header, formData, body)
  let scheme = call_773407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773407.url(scheme.get, call_773407.host, call_773407.base,
                         call_773407.route, valid.getOrDefault("path"))
  result = hook(call_773407, url, valid)

proc call*(call_773408: Call_DescribeResourceGroups_773395; body: JsonNode): Recallable =
  ## describeResourceGroups
  ## Describes the resource groups that are specified by the ARNs of the resource groups.
  ##   body: JObject (required)
  var body_773409 = newJObject()
  if body != nil:
    body_773409 = body
  result = call_773408.call(nil, nil, nil, nil, body_773409)

var describeResourceGroups* = Call_DescribeResourceGroups_773395(
    name: "describeResourceGroups", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeResourceGroups",
    validator: validate_DescribeResourceGroups_773396, base: "/",
    url: url_DescribeResourceGroups_773397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRulesPackages_773410 = ref object of OpenApiRestCall_772597
proc url_DescribeRulesPackages_773412(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRulesPackages_773411(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773413 = header.getOrDefault("X-Amz-Date")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Date", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-Security-Token")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-Security-Token", valid_773414
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773415 = header.getOrDefault("X-Amz-Target")
  valid_773415 = validateParameter(valid_773415, JString, required = true, default = newJString(
      "InspectorService.DescribeRulesPackages"))
  if valid_773415 != nil:
    section.add "X-Amz-Target", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Content-Sha256", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-Algorithm")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Algorithm", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Signature")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Signature", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-SignedHeaders", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Credential")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Credential", valid_773420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773422: Call_DescribeRulesPackages_773410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the rules packages that are specified by the ARNs of the rules packages.
  ## 
  let valid = call_773422.validator(path, query, header, formData, body)
  let scheme = call_773422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773422.url(scheme.get, call_773422.host, call_773422.base,
                         call_773422.route, valid.getOrDefault("path"))
  result = hook(call_773422, url, valid)

proc call*(call_773423: Call_DescribeRulesPackages_773410; body: JsonNode): Recallable =
  ## describeRulesPackages
  ## Describes the rules packages that are specified by the ARNs of the rules packages.
  ##   body: JObject (required)
  var body_773424 = newJObject()
  if body != nil:
    body_773424 = body
  result = call_773423.call(nil, nil, nil, nil, body_773424)

var describeRulesPackages* = Call_DescribeRulesPackages_773410(
    name: "describeRulesPackages", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeRulesPackages",
    validator: validate_DescribeRulesPackages_773411, base: "/",
    url: url_DescribeRulesPackages_773412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssessmentReport_773425 = ref object of OpenApiRestCall_772597
proc url_GetAssessmentReport_773427(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAssessmentReport_773426(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773428 = header.getOrDefault("X-Amz-Date")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Date", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-Security-Token")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-Security-Token", valid_773429
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773430 = header.getOrDefault("X-Amz-Target")
  valid_773430 = validateParameter(valid_773430, JString, required = true, default = newJString(
      "InspectorService.GetAssessmentReport"))
  if valid_773430 != nil:
    section.add "X-Amz-Target", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Content-Sha256", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-Algorithm")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-Algorithm", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Signature")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Signature", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-SignedHeaders", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-Credential")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Credential", valid_773435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773437: Call_GetAssessmentReport_773425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces an assessment report that includes detailed and comprehensive results of a specified assessment run. 
  ## 
  let valid = call_773437.validator(path, query, header, formData, body)
  let scheme = call_773437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773437.url(scheme.get, call_773437.host, call_773437.base,
                         call_773437.route, valid.getOrDefault("path"))
  result = hook(call_773437, url, valid)

proc call*(call_773438: Call_GetAssessmentReport_773425; body: JsonNode): Recallable =
  ## getAssessmentReport
  ## Produces an assessment report that includes detailed and comprehensive results of a specified assessment run. 
  ##   body: JObject (required)
  var body_773439 = newJObject()
  if body != nil:
    body_773439 = body
  result = call_773438.call(nil, nil, nil, nil, body_773439)

var getAssessmentReport* = Call_GetAssessmentReport_773425(
    name: "getAssessmentReport", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetAssessmentReport",
    validator: validate_GetAssessmentReport_773426, base: "/",
    url: url_GetAssessmentReport_773427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExclusionsPreview_773440 = ref object of OpenApiRestCall_772597
proc url_GetExclusionsPreview_773442(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetExclusionsPreview_773441(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the exclusions preview (a list of ExclusionPreview objects) specified by the preview token. You can obtain the preview token by running the CreateExclusionsPreview API.
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
  var valid_773443 = query.getOrDefault("maxResults")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "maxResults", valid_773443
  var valid_773444 = query.getOrDefault("nextToken")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "nextToken", valid_773444
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
  var valid_773445 = header.getOrDefault("X-Amz-Date")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Date", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Security-Token")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Security-Token", valid_773446
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773447 = header.getOrDefault("X-Amz-Target")
  valid_773447 = validateParameter(valid_773447, JString, required = true, default = newJString(
      "InspectorService.GetExclusionsPreview"))
  if valid_773447 != nil:
    section.add "X-Amz-Target", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Content-Sha256", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Algorithm")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Algorithm", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Signature")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Signature", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-SignedHeaders", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Credential")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Credential", valid_773452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773454: Call_GetExclusionsPreview_773440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the exclusions preview (a list of ExclusionPreview objects) specified by the preview token. You can obtain the preview token by running the CreateExclusionsPreview API.
  ## 
  let valid = call_773454.validator(path, query, header, formData, body)
  let scheme = call_773454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773454.url(scheme.get, call_773454.host, call_773454.base,
                         call_773454.route, valid.getOrDefault("path"))
  result = hook(call_773454, url, valid)

proc call*(call_773455: Call_GetExclusionsPreview_773440; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getExclusionsPreview
  ## Retrieves the exclusions preview (a list of ExclusionPreview objects) specified by the preview token. You can obtain the preview token by running the CreateExclusionsPreview API.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773456 = newJObject()
  var body_773457 = newJObject()
  add(query_773456, "maxResults", newJString(maxResults))
  add(query_773456, "nextToken", newJString(nextToken))
  if body != nil:
    body_773457 = body
  result = call_773455.call(nil, query_773456, nil, nil, body_773457)

var getExclusionsPreview* = Call_GetExclusionsPreview_773440(
    name: "getExclusionsPreview", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetExclusionsPreview",
    validator: validate_GetExclusionsPreview_773441, base: "/",
    url: url_GetExclusionsPreview_773442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTelemetryMetadata_773459 = ref object of OpenApiRestCall_772597
proc url_GetTelemetryMetadata_773461(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTelemetryMetadata_773460(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773462 = header.getOrDefault("X-Amz-Date")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "X-Amz-Date", valid_773462
  var valid_773463 = header.getOrDefault("X-Amz-Security-Token")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Security-Token", valid_773463
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773464 = header.getOrDefault("X-Amz-Target")
  valid_773464 = validateParameter(valid_773464, JString, required = true, default = newJString(
      "InspectorService.GetTelemetryMetadata"))
  if valid_773464 != nil:
    section.add "X-Amz-Target", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Content-Sha256", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Algorithm")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Algorithm", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Signature")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Signature", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-SignedHeaders", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Credential")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Credential", valid_773469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773471: Call_GetTelemetryMetadata_773459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Information about the data that is collected for the specified assessment run.
  ## 
  let valid = call_773471.validator(path, query, header, formData, body)
  let scheme = call_773471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773471.url(scheme.get, call_773471.host, call_773471.base,
                         call_773471.route, valid.getOrDefault("path"))
  result = hook(call_773471, url, valid)

proc call*(call_773472: Call_GetTelemetryMetadata_773459; body: JsonNode): Recallable =
  ## getTelemetryMetadata
  ## Information about the data that is collected for the specified assessment run.
  ##   body: JObject (required)
  var body_773473 = newJObject()
  if body != nil:
    body_773473 = body
  result = call_773472.call(nil, nil, nil, nil, body_773473)

var getTelemetryMetadata* = Call_GetTelemetryMetadata_773459(
    name: "getTelemetryMetadata", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetTelemetryMetadata",
    validator: validate_GetTelemetryMetadata_773460, base: "/",
    url: url_GetTelemetryMetadata_773461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentRunAgents_773474 = ref object of OpenApiRestCall_772597
proc url_ListAssessmentRunAgents_773476(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssessmentRunAgents_773475(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the agents of the assessment runs that are specified by the ARNs of the assessment runs.
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
  var valid_773477 = query.getOrDefault("maxResults")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "maxResults", valid_773477
  var valid_773478 = query.getOrDefault("nextToken")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "nextToken", valid_773478
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
  var valid_773479 = header.getOrDefault("X-Amz-Date")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Date", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Security-Token")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Security-Token", valid_773480
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773481 = header.getOrDefault("X-Amz-Target")
  valid_773481 = validateParameter(valid_773481, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentRunAgents"))
  if valid_773481 != nil:
    section.add "X-Amz-Target", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Content-Sha256", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Algorithm")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Algorithm", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-Signature")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Signature", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-SignedHeaders", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Credential")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Credential", valid_773486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773488: Call_ListAssessmentRunAgents_773474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the agents of the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_773488.validator(path, query, header, formData, body)
  let scheme = call_773488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773488.url(scheme.get, call_773488.host, call_773488.base,
                         call_773488.route, valid.getOrDefault("path"))
  result = hook(call_773488, url, valid)

proc call*(call_773489: Call_ListAssessmentRunAgents_773474; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listAssessmentRunAgents
  ## Lists the agents of the assessment runs that are specified by the ARNs of the assessment runs.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773490 = newJObject()
  var body_773491 = newJObject()
  add(query_773490, "maxResults", newJString(maxResults))
  add(query_773490, "nextToken", newJString(nextToken))
  if body != nil:
    body_773491 = body
  result = call_773489.call(nil, query_773490, nil, nil, body_773491)

var listAssessmentRunAgents* = Call_ListAssessmentRunAgents_773474(
    name: "listAssessmentRunAgents", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentRunAgents",
    validator: validate_ListAssessmentRunAgents_773475, base: "/",
    url: url_ListAssessmentRunAgents_773476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentRuns_773492 = ref object of OpenApiRestCall_772597
proc url_ListAssessmentRuns_773494(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssessmentRuns_773493(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists the assessment runs that correspond to the assessment templates that are specified by the ARNs of the assessment templates.
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
  var valid_773495 = query.getOrDefault("maxResults")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "maxResults", valid_773495
  var valid_773496 = query.getOrDefault("nextToken")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "nextToken", valid_773496
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
  var valid_773497 = header.getOrDefault("X-Amz-Date")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Date", valid_773497
  var valid_773498 = header.getOrDefault("X-Amz-Security-Token")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-Security-Token", valid_773498
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773499 = header.getOrDefault("X-Amz-Target")
  valid_773499 = validateParameter(valid_773499, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentRuns"))
  if valid_773499 != nil:
    section.add "X-Amz-Target", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Content-Sha256", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Algorithm")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Algorithm", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Signature")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Signature", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-SignedHeaders", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Credential")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Credential", valid_773504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773506: Call_ListAssessmentRuns_773492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the assessment runs that correspond to the assessment templates that are specified by the ARNs of the assessment templates.
  ## 
  let valid = call_773506.validator(path, query, header, formData, body)
  let scheme = call_773506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773506.url(scheme.get, call_773506.host, call_773506.base,
                         call_773506.route, valid.getOrDefault("path"))
  result = hook(call_773506, url, valid)

proc call*(call_773507: Call_ListAssessmentRuns_773492; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listAssessmentRuns
  ## Lists the assessment runs that correspond to the assessment templates that are specified by the ARNs of the assessment templates.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773508 = newJObject()
  var body_773509 = newJObject()
  add(query_773508, "maxResults", newJString(maxResults))
  add(query_773508, "nextToken", newJString(nextToken))
  if body != nil:
    body_773509 = body
  result = call_773507.call(nil, query_773508, nil, nil, body_773509)

var listAssessmentRuns* = Call_ListAssessmentRuns_773492(
    name: "listAssessmentRuns", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentRuns",
    validator: validate_ListAssessmentRuns_773493, base: "/",
    url: url_ListAssessmentRuns_773494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentTargets_773510 = ref object of OpenApiRestCall_772597
proc url_ListAssessmentTargets_773512(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssessmentTargets_773511(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the ARNs of the assessment targets within this AWS account. For more information about assessment targets, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html">Amazon Inspector Assessment Targets</a>.
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
  var valid_773513 = query.getOrDefault("maxResults")
  valid_773513 = validateParameter(valid_773513, JString, required = false,
                                 default = nil)
  if valid_773513 != nil:
    section.add "maxResults", valid_773513
  var valid_773514 = query.getOrDefault("nextToken")
  valid_773514 = validateParameter(valid_773514, JString, required = false,
                                 default = nil)
  if valid_773514 != nil:
    section.add "nextToken", valid_773514
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
  var valid_773515 = header.getOrDefault("X-Amz-Date")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Date", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-Security-Token")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Security-Token", valid_773516
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773517 = header.getOrDefault("X-Amz-Target")
  valid_773517 = validateParameter(valid_773517, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentTargets"))
  if valid_773517 != nil:
    section.add "X-Amz-Target", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Content-Sha256", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Algorithm")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Algorithm", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Signature")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Signature", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-SignedHeaders", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Credential")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Credential", valid_773522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773524: Call_ListAssessmentTargets_773510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the ARNs of the assessment targets within this AWS account. For more information about assessment targets, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html">Amazon Inspector Assessment Targets</a>.
  ## 
  let valid = call_773524.validator(path, query, header, formData, body)
  let scheme = call_773524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773524.url(scheme.get, call_773524.host, call_773524.base,
                         call_773524.route, valid.getOrDefault("path"))
  result = hook(call_773524, url, valid)

proc call*(call_773525: Call_ListAssessmentTargets_773510; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listAssessmentTargets
  ## Lists the ARNs of the assessment targets within this AWS account. For more information about assessment targets, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html">Amazon Inspector Assessment Targets</a>.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773526 = newJObject()
  var body_773527 = newJObject()
  add(query_773526, "maxResults", newJString(maxResults))
  add(query_773526, "nextToken", newJString(nextToken))
  if body != nil:
    body_773527 = body
  result = call_773525.call(nil, query_773526, nil, nil, body_773527)

var listAssessmentTargets* = Call_ListAssessmentTargets_773510(
    name: "listAssessmentTargets", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentTargets",
    validator: validate_ListAssessmentTargets_773511, base: "/",
    url: url_ListAssessmentTargets_773512, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentTemplates_773528 = ref object of OpenApiRestCall_772597
proc url_ListAssessmentTemplates_773530(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssessmentTemplates_773529(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the assessment templates that correspond to the assessment targets that are specified by the ARNs of the assessment targets.
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
  var valid_773531 = query.getOrDefault("maxResults")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "maxResults", valid_773531
  var valid_773532 = query.getOrDefault("nextToken")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "nextToken", valid_773532
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
  var valid_773533 = header.getOrDefault("X-Amz-Date")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Date", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-Security-Token")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Security-Token", valid_773534
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773535 = header.getOrDefault("X-Amz-Target")
  valid_773535 = validateParameter(valid_773535, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentTemplates"))
  if valid_773535 != nil:
    section.add "X-Amz-Target", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Content-Sha256", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-Algorithm")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Algorithm", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Signature")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Signature", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-SignedHeaders", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Credential")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Credential", valid_773540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773542: Call_ListAssessmentTemplates_773528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the assessment templates that correspond to the assessment targets that are specified by the ARNs of the assessment targets.
  ## 
  let valid = call_773542.validator(path, query, header, formData, body)
  let scheme = call_773542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773542.url(scheme.get, call_773542.host, call_773542.base,
                         call_773542.route, valid.getOrDefault("path"))
  result = hook(call_773542, url, valid)

proc call*(call_773543: Call_ListAssessmentTemplates_773528; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listAssessmentTemplates
  ## Lists the assessment templates that correspond to the assessment targets that are specified by the ARNs of the assessment targets.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773544 = newJObject()
  var body_773545 = newJObject()
  add(query_773544, "maxResults", newJString(maxResults))
  add(query_773544, "nextToken", newJString(nextToken))
  if body != nil:
    body_773545 = body
  result = call_773543.call(nil, query_773544, nil, nil, body_773545)

var listAssessmentTemplates* = Call_ListAssessmentTemplates_773528(
    name: "listAssessmentTemplates", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentTemplates",
    validator: validate_ListAssessmentTemplates_773529, base: "/",
    url: url_ListAssessmentTemplates_773530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSubscriptions_773546 = ref object of OpenApiRestCall_772597
proc url_ListEventSubscriptions_773548(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListEventSubscriptions_773547(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the event subscriptions for the assessment template that is specified by the ARN of the assessment template. For more information, see <a>SubscribeToEvent</a> and <a>UnsubscribeFromEvent</a>.
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
  var valid_773549 = query.getOrDefault("maxResults")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "maxResults", valid_773549
  var valid_773550 = query.getOrDefault("nextToken")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "nextToken", valid_773550
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
  var valid_773551 = header.getOrDefault("X-Amz-Date")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Date", valid_773551
  var valid_773552 = header.getOrDefault("X-Amz-Security-Token")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Security-Token", valid_773552
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773553 = header.getOrDefault("X-Amz-Target")
  valid_773553 = validateParameter(valid_773553, JString, required = true, default = newJString(
      "InspectorService.ListEventSubscriptions"))
  if valid_773553 != nil:
    section.add "X-Amz-Target", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Content-Sha256", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Algorithm")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Algorithm", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-Signature")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-Signature", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-SignedHeaders", valid_773557
  var valid_773558 = header.getOrDefault("X-Amz-Credential")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-Credential", valid_773558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773560: Call_ListEventSubscriptions_773546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the event subscriptions for the assessment template that is specified by the ARN of the assessment template. For more information, see <a>SubscribeToEvent</a> and <a>UnsubscribeFromEvent</a>.
  ## 
  let valid = call_773560.validator(path, query, header, formData, body)
  let scheme = call_773560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773560.url(scheme.get, call_773560.host, call_773560.base,
                         call_773560.route, valid.getOrDefault("path"))
  result = hook(call_773560, url, valid)

proc call*(call_773561: Call_ListEventSubscriptions_773546; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listEventSubscriptions
  ## Lists all the event subscriptions for the assessment template that is specified by the ARN of the assessment template. For more information, see <a>SubscribeToEvent</a> and <a>UnsubscribeFromEvent</a>.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773562 = newJObject()
  var body_773563 = newJObject()
  add(query_773562, "maxResults", newJString(maxResults))
  add(query_773562, "nextToken", newJString(nextToken))
  if body != nil:
    body_773563 = body
  result = call_773561.call(nil, query_773562, nil, nil, body_773563)

var listEventSubscriptions* = Call_ListEventSubscriptions_773546(
    name: "listEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListEventSubscriptions",
    validator: validate_ListEventSubscriptions_773547, base: "/",
    url: url_ListEventSubscriptions_773548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExclusions_773564 = ref object of OpenApiRestCall_772597
proc url_ListExclusions_773566(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListExclusions_773565(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## List exclusions that are generated by the assessment run.
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
  var valid_773567 = query.getOrDefault("maxResults")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "maxResults", valid_773567
  var valid_773568 = query.getOrDefault("nextToken")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "nextToken", valid_773568
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
  var valid_773569 = header.getOrDefault("X-Amz-Date")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Date", valid_773569
  var valid_773570 = header.getOrDefault("X-Amz-Security-Token")
  valid_773570 = validateParameter(valid_773570, JString, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "X-Amz-Security-Token", valid_773570
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773571 = header.getOrDefault("X-Amz-Target")
  valid_773571 = validateParameter(valid_773571, JString, required = true, default = newJString(
      "InspectorService.ListExclusions"))
  if valid_773571 != nil:
    section.add "X-Amz-Target", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Content-Sha256", valid_773572
  var valid_773573 = header.getOrDefault("X-Amz-Algorithm")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "X-Amz-Algorithm", valid_773573
  var valid_773574 = header.getOrDefault("X-Amz-Signature")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "X-Amz-Signature", valid_773574
  var valid_773575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-SignedHeaders", valid_773575
  var valid_773576 = header.getOrDefault("X-Amz-Credential")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-Credential", valid_773576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773578: Call_ListExclusions_773564; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List exclusions that are generated by the assessment run.
  ## 
  let valid = call_773578.validator(path, query, header, formData, body)
  let scheme = call_773578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773578.url(scheme.get, call_773578.host, call_773578.base,
                         call_773578.route, valid.getOrDefault("path"))
  result = hook(call_773578, url, valid)

proc call*(call_773579: Call_ListExclusions_773564; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listExclusions
  ## List exclusions that are generated by the assessment run.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773580 = newJObject()
  var body_773581 = newJObject()
  add(query_773580, "maxResults", newJString(maxResults))
  add(query_773580, "nextToken", newJString(nextToken))
  if body != nil:
    body_773581 = body
  result = call_773579.call(nil, query_773580, nil, nil, body_773581)

var listExclusions* = Call_ListExclusions_773564(name: "listExclusions",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListExclusions",
    validator: validate_ListExclusions_773565, base: "/", url: url_ListExclusions_773566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_773582 = ref object of OpenApiRestCall_772597
proc url_ListFindings_773584(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListFindings_773583(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists findings that are generated by the assessment runs that are specified by the ARNs of the assessment runs.
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
  var valid_773585 = query.getOrDefault("maxResults")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "maxResults", valid_773585
  var valid_773586 = query.getOrDefault("nextToken")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "nextToken", valid_773586
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
  var valid_773587 = header.getOrDefault("X-Amz-Date")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Date", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Security-Token")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Security-Token", valid_773588
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773589 = header.getOrDefault("X-Amz-Target")
  valid_773589 = validateParameter(valid_773589, JString, required = true, default = newJString(
      "InspectorService.ListFindings"))
  if valid_773589 != nil:
    section.add "X-Amz-Target", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-Content-Sha256", valid_773590
  var valid_773591 = header.getOrDefault("X-Amz-Algorithm")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-Algorithm", valid_773591
  var valid_773592 = header.getOrDefault("X-Amz-Signature")
  valid_773592 = validateParameter(valid_773592, JString, required = false,
                                 default = nil)
  if valid_773592 != nil:
    section.add "X-Amz-Signature", valid_773592
  var valid_773593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "X-Amz-SignedHeaders", valid_773593
  var valid_773594 = header.getOrDefault("X-Amz-Credential")
  valid_773594 = validateParameter(valid_773594, JString, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "X-Amz-Credential", valid_773594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773596: Call_ListFindings_773582; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists findings that are generated by the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_773596.validator(path, query, header, formData, body)
  let scheme = call_773596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773596.url(scheme.get, call_773596.host, call_773596.base,
                         call_773596.route, valid.getOrDefault("path"))
  result = hook(call_773596, url, valid)

proc call*(call_773597: Call_ListFindings_773582; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listFindings
  ## Lists findings that are generated by the assessment runs that are specified by the ARNs of the assessment runs.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773598 = newJObject()
  var body_773599 = newJObject()
  add(query_773598, "maxResults", newJString(maxResults))
  add(query_773598, "nextToken", newJString(nextToken))
  if body != nil:
    body_773599 = body
  result = call_773597.call(nil, query_773598, nil, nil, body_773599)

var listFindings* = Call_ListFindings_773582(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListFindings",
    validator: validate_ListFindings_773583, base: "/", url: url_ListFindings_773584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRulesPackages_773600 = ref object of OpenApiRestCall_772597
proc url_ListRulesPackages_773602(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListRulesPackages_773601(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists all available Amazon Inspector rules packages.
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
  var valid_773603 = query.getOrDefault("maxResults")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "maxResults", valid_773603
  var valid_773604 = query.getOrDefault("nextToken")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "nextToken", valid_773604
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
  var valid_773605 = header.getOrDefault("X-Amz-Date")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "X-Amz-Date", valid_773605
  var valid_773606 = header.getOrDefault("X-Amz-Security-Token")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "X-Amz-Security-Token", valid_773606
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773607 = header.getOrDefault("X-Amz-Target")
  valid_773607 = validateParameter(valid_773607, JString, required = true, default = newJString(
      "InspectorService.ListRulesPackages"))
  if valid_773607 != nil:
    section.add "X-Amz-Target", valid_773607
  var valid_773608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "X-Amz-Content-Sha256", valid_773608
  var valid_773609 = header.getOrDefault("X-Amz-Algorithm")
  valid_773609 = validateParameter(valid_773609, JString, required = false,
                                 default = nil)
  if valid_773609 != nil:
    section.add "X-Amz-Algorithm", valid_773609
  var valid_773610 = header.getOrDefault("X-Amz-Signature")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Signature", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-SignedHeaders", valid_773611
  var valid_773612 = header.getOrDefault("X-Amz-Credential")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-Credential", valid_773612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773614: Call_ListRulesPackages_773600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all available Amazon Inspector rules packages.
  ## 
  let valid = call_773614.validator(path, query, header, formData, body)
  let scheme = call_773614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773614.url(scheme.get, call_773614.host, call_773614.base,
                         call_773614.route, valid.getOrDefault("path"))
  result = hook(call_773614, url, valid)

proc call*(call_773615: Call_ListRulesPackages_773600; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listRulesPackages
  ## Lists all available Amazon Inspector rules packages.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773616 = newJObject()
  var body_773617 = newJObject()
  add(query_773616, "maxResults", newJString(maxResults))
  add(query_773616, "nextToken", newJString(nextToken))
  if body != nil:
    body_773617 = body
  result = call_773615.call(nil, query_773616, nil, nil, body_773617)

var listRulesPackages* = Call_ListRulesPackages_773600(name: "listRulesPackages",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListRulesPackages",
    validator: validate_ListRulesPackages_773601, base: "/",
    url: url_ListRulesPackages_773602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773618 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_773620(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_773619(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773621 = header.getOrDefault("X-Amz-Date")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-Date", valid_773621
  var valid_773622 = header.getOrDefault("X-Amz-Security-Token")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Security-Token", valid_773622
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773623 = header.getOrDefault("X-Amz-Target")
  valid_773623 = validateParameter(valid_773623, JString, required = true, default = newJString(
      "InspectorService.ListTagsForResource"))
  if valid_773623 != nil:
    section.add "X-Amz-Target", valid_773623
  var valid_773624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-Content-Sha256", valid_773624
  var valid_773625 = header.getOrDefault("X-Amz-Algorithm")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Algorithm", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Signature")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Signature", valid_773626
  var valid_773627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773627 = validateParameter(valid_773627, JString, required = false,
                                 default = nil)
  if valid_773627 != nil:
    section.add "X-Amz-SignedHeaders", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-Credential")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-Credential", valid_773628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773630: Call_ListTagsForResource_773618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags associated with an assessment template.
  ## 
  let valid = call_773630.validator(path, query, header, formData, body)
  let scheme = call_773630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773630.url(scheme.get, call_773630.host, call_773630.base,
                         call_773630.route, valid.getOrDefault("path"))
  result = hook(call_773630, url, valid)

proc call*(call_773631: Call_ListTagsForResource_773618; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags associated with an assessment template.
  ##   body: JObject (required)
  var body_773632 = newJObject()
  if body != nil:
    body_773632 = body
  result = call_773631.call(nil, nil, nil, nil, body_773632)

var listTagsForResource* = Call_ListTagsForResource_773618(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListTagsForResource",
    validator: validate_ListTagsForResource_773619, base: "/",
    url: url_ListTagsForResource_773620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PreviewAgents_773633 = ref object of OpenApiRestCall_772597
proc url_PreviewAgents_773635(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PreviewAgents_773634(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Previews the agents installed on the EC2 instances that are part of the specified assessment target.
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
  var valid_773636 = query.getOrDefault("maxResults")
  valid_773636 = validateParameter(valid_773636, JString, required = false,
                                 default = nil)
  if valid_773636 != nil:
    section.add "maxResults", valid_773636
  var valid_773637 = query.getOrDefault("nextToken")
  valid_773637 = validateParameter(valid_773637, JString, required = false,
                                 default = nil)
  if valid_773637 != nil:
    section.add "nextToken", valid_773637
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
  var valid_773638 = header.getOrDefault("X-Amz-Date")
  valid_773638 = validateParameter(valid_773638, JString, required = false,
                                 default = nil)
  if valid_773638 != nil:
    section.add "X-Amz-Date", valid_773638
  var valid_773639 = header.getOrDefault("X-Amz-Security-Token")
  valid_773639 = validateParameter(valid_773639, JString, required = false,
                                 default = nil)
  if valid_773639 != nil:
    section.add "X-Amz-Security-Token", valid_773639
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773640 = header.getOrDefault("X-Amz-Target")
  valid_773640 = validateParameter(valid_773640, JString, required = true, default = newJString(
      "InspectorService.PreviewAgents"))
  if valid_773640 != nil:
    section.add "X-Amz-Target", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Content-Sha256", valid_773641
  var valid_773642 = header.getOrDefault("X-Amz-Algorithm")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "X-Amz-Algorithm", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-Signature")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Signature", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-SignedHeaders", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Credential")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Credential", valid_773645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773647: Call_PreviewAgents_773633; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Previews the agents installed on the EC2 instances that are part of the specified assessment target.
  ## 
  let valid = call_773647.validator(path, query, header, formData, body)
  let scheme = call_773647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773647.url(scheme.get, call_773647.host, call_773647.base,
                         call_773647.route, valid.getOrDefault("path"))
  result = hook(call_773647, url, valid)

proc call*(call_773648: Call_PreviewAgents_773633; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## previewAgents
  ## Previews the agents installed on the EC2 instances that are part of the specified assessment target.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773649 = newJObject()
  var body_773650 = newJObject()
  add(query_773649, "maxResults", newJString(maxResults))
  add(query_773649, "nextToken", newJString(nextToken))
  if body != nil:
    body_773650 = body
  result = call_773648.call(nil, query_773649, nil, nil, body_773650)

var previewAgents* = Call_PreviewAgents_773633(name: "previewAgents",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.PreviewAgents",
    validator: validate_PreviewAgents_773634, base: "/", url: url_PreviewAgents_773635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterCrossAccountAccessRole_773651 = ref object of OpenApiRestCall_772597
proc url_RegisterCrossAccountAccessRole_773653(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterCrossAccountAccessRole_773652(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773654 = header.getOrDefault("X-Amz-Date")
  valid_773654 = validateParameter(valid_773654, JString, required = false,
                                 default = nil)
  if valid_773654 != nil:
    section.add "X-Amz-Date", valid_773654
  var valid_773655 = header.getOrDefault("X-Amz-Security-Token")
  valid_773655 = validateParameter(valid_773655, JString, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "X-Amz-Security-Token", valid_773655
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773656 = header.getOrDefault("X-Amz-Target")
  valid_773656 = validateParameter(valid_773656, JString, required = true, default = newJString(
      "InspectorService.RegisterCrossAccountAccessRole"))
  if valid_773656 != nil:
    section.add "X-Amz-Target", valid_773656
  var valid_773657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773657 = validateParameter(valid_773657, JString, required = false,
                                 default = nil)
  if valid_773657 != nil:
    section.add "X-Amz-Content-Sha256", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-Algorithm")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Algorithm", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-Signature")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Signature", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-SignedHeaders", valid_773660
  var valid_773661 = header.getOrDefault("X-Amz-Credential")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-Credential", valid_773661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773663: Call_RegisterCrossAccountAccessRole_773651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the IAM role that grants Amazon Inspector access to AWS Services needed to perform security assessments.
  ## 
  let valid = call_773663.validator(path, query, header, formData, body)
  let scheme = call_773663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773663.url(scheme.get, call_773663.host, call_773663.base,
                         call_773663.route, valid.getOrDefault("path"))
  result = hook(call_773663, url, valid)

proc call*(call_773664: Call_RegisterCrossAccountAccessRole_773651; body: JsonNode): Recallable =
  ## registerCrossAccountAccessRole
  ## Registers the IAM role that grants Amazon Inspector access to AWS Services needed to perform security assessments.
  ##   body: JObject (required)
  var body_773665 = newJObject()
  if body != nil:
    body_773665 = body
  result = call_773664.call(nil, nil, nil, nil, body_773665)

var registerCrossAccountAccessRole* = Call_RegisterCrossAccountAccessRole_773651(
    name: "registerCrossAccountAccessRole", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.RegisterCrossAccountAccessRole",
    validator: validate_RegisterCrossAccountAccessRole_773652, base: "/",
    url: url_RegisterCrossAccountAccessRole_773653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributesFromFindings_773666 = ref object of OpenApiRestCall_772597
proc url_RemoveAttributesFromFindings_773668(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveAttributesFromFindings_773667(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773669 = header.getOrDefault("X-Amz-Date")
  valid_773669 = validateParameter(valid_773669, JString, required = false,
                                 default = nil)
  if valid_773669 != nil:
    section.add "X-Amz-Date", valid_773669
  var valid_773670 = header.getOrDefault("X-Amz-Security-Token")
  valid_773670 = validateParameter(valid_773670, JString, required = false,
                                 default = nil)
  if valid_773670 != nil:
    section.add "X-Amz-Security-Token", valid_773670
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773671 = header.getOrDefault("X-Amz-Target")
  valid_773671 = validateParameter(valid_773671, JString, required = true, default = newJString(
      "InspectorService.RemoveAttributesFromFindings"))
  if valid_773671 != nil:
    section.add "X-Amz-Target", valid_773671
  var valid_773672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773672 = validateParameter(valid_773672, JString, required = false,
                                 default = nil)
  if valid_773672 != nil:
    section.add "X-Amz-Content-Sha256", valid_773672
  var valid_773673 = header.getOrDefault("X-Amz-Algorithm")
  valid_773673 = validateParameter(valid_773673, JString, required = false,
                                 default = nil)
  if valid_773673 != nil:
    section.add "X-Amz-Algorithm", valid_773673
  var valid_773674 = header.getOrDefault("X-Amz-Signature")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Signature", valid_773674
  var valid_773675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773675 = validateParameter(valid_773675, JString, required = false,
                                 default = nil)
  if valid_773675 != nil:
    section.add "X-Amz-SignedHeaders", valid_773675
  var valid_773676 = header.getOrDefault("X-Amz-Credential")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-Credential", valid_773676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773678: Call_RemoveAttributesFromFindings_773666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes entire attributes (key and value pairs) from the findings that are specified by the ARNs of the findings where an attribute with the specified key exists.
  ## 
  let valid = call_773678.validator(path, query, header, formData, body)
  let scheme = call_773678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773678.url(scheme.get, call_773678.host, call_773678.base,
                         call_773678.route, valid.getOrDefault("path"))
  result = hook(call_773678, url, valid)

proc call*(call_773679: Call_RemoveAttributesFromFindings_773666; body: JsonNode): Recallable =
  ## removeAttributesFromFindings
  ## Removes entire attributes (key and value pairs) from the findings that are specified by the ARNs of the findings where an attribute with the specified key exists.
  ##   body: JObject (required)
  var body_773680 = newJObject()
  if body != nil:
    body_773680 = body
  result = call_773679.call(nil, nil, nil, nil, body_773680)

var removeAttributesFromFindings* = Call_RemoveAttributesFromFindings_773666(
    name: "removeAttributesFromFindings", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.RemoveAttributesFromFindings",
    validator: validate_RemoveAttributesFromFindings_773667, base: "/",
    url: url_RemoveAttributesFromFindings_773668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetTagsForResource_773681 = ref object of OpenApiRestCall_772597
proc url_SetTagsForResource_773683(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetTagsForResource_773682(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773684 = header.getOrDefault("X-Amz-Date")
  valid_773684 = validateParameter(valid_773684, JString, required = false,
                                 default = nil)
  if valid_773684 != nil:
    section.add "X-Amz-Date", valid_773684
  var valid_773685 = header.getOrDefault("X-Amz-Security-Token")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "X-Amz-Security-Token", valid_773685
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773686 = header.getOrDefault("X-Amz-Target")
  valid_773686 = validateParameter(valid_773686, JString, required = true, default = newJString(
      "InspectorService.SetTagsForResource"))
  if valid_773686 != nil:
    section.add "X-Amz-Target", valid_773686
  var valid_773687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773687 = validateParameter(valid_773687, JString, required = false,
                                 default = nil)
  if valid_773687 != nil:
    section.add "X-Amz-Content-Sha256", valid_773687
  var valid_773688 = header.getOrDefault("X-Amz-Algorithm")
  valid_773688 = validateParameter(valid_773688, JString, required = false,
                                 default = nil)
  if valid_773688 != nil:
    section.add "X-Amz-Algorithm", valid_773688
  var valid_773689 = header.getOrDefault("X-Amz-Signature")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Signature", valid_773689
  var valid_773690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773690 = validateParameter(valid_773690, JString, required = false,
                                 default = nil)
  if valid_773690 != nil:
    section.add "X-Amz-SignedHeaders", valid_773690
  var valid_773691 = header.getOrDefault("X-Amz-Credential")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-Credential", valid_773691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773693: Call_SetTagsForResource_773681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets tags (key and value pairs) to the assessment template that is specified by the ARN of the assessment template.
  ## 
  let valid = call_773693.validator(path, query, header, formData, body)
  let scheme = call_773693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773693.url(scheme.get, call_773693.host, call_773693.base,
                         call_773693.route, valid.getOrDefault("path"))
  result = hook(call_773693, url, valid)

proc call*(call_773694: Call_SetTagsForResource_773681; body: JsonNode): Recallable =
  ## setTagsForResource
  ## Sets tags (key and value pairs) to the assessment template that is specified by the ARN of the assessment template.
  ##   body: JObject (required)
  var body_773695 = newJObject()
  if body != nil:
    body_773695 = body
  result = call_773694.call(nil, nil, nil, nil, body_773695)

var setTagsForResource* = Call_SetTagsForResource_773681(
    name: "setTagsForResource", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.SetTagsForResource",
    validator: validate_SetTagsForResource_773682, base: "/",
    url: url_SetTagsForResource_773683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssessmentRun_773696 = ref object of OpenApiRestCall_772597
proc url_StartAssessmentRun_773698(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartAssessmentRun_773697(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773699 = header.getOrDefault("X-Amz-Date")
  valid_773699 = validateParameter(valid_773699, JString, required = false,
                                 default = nil)
  if valid_773699 != nil:
    section.add "X-Amz-Date", valid_773699
  var valid_773700 = header.getOrDefault("X-Amz-Security-Token")
  valid_773700 = validateParameter(valid_773700, JString, required = false,
                                 default = nil)
  if valid_773700 != nil:
    section.add "X-Amz-Security-Token", valid_773700
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773701 = header.getOrDefault("X-Amz-Target")
  valid_773701 = validateParameter(valid_773701, JString, required = true, default = newJString(
      "InspectorService.StartAssessmentRun"))
  if valid_773701 != nil:
    section.add "X-Amz-Target", valid_773701
  var valid_773702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773702 = validateParameter(valid_773702, JString, required = false,
                                 default = nil)
  if valid_773702 != nil:
    section.add "X-Amz-Content-Sha256", valid_773702
  var valid_773703 = header.getOrDefault("X-Amz-Algorithm")
  valid_773703 = validateParameter(valid_773703, JString, required = false,
                                 default = nil)
  if valid_773703 != nil:
    section.add "X-Amz-Algorithm", valid_773703
  var valid_773704 = header.getOrDefault("X-Amz-Signature")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-Signature", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-SignedHeaders", valid_773705
  var valid_773706 = header.getOrDefault("X-Amz-Credential")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "X-Amz-Credential", valid_773706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773708: Call_StartAssessmentRun_773696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the assessment run specified by the ARN of the assessment template. For this API to function properly, you must not exceed the limit of running up to 500 concurrent agents per AWS account.
  ## 
  let valid = call_773708.validator(path, query, header, formData, body)
  let scheme = call_773708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773708.url(scheme.get, call_773708.host, call_773708.base,
                         call_773708.route, valid.getOrDefault("path"))
  result = hook(call_773708, url, valid)

proc call*(call_773709: Call_StartAssessmentRun_773696; body: JsonNode): Recallable =
  ## startAssessmentRun
  ## Starts the assessment run specified by the ARN of the assessment template. For this API to function properly, you must not exceed the limit of running up to 500 concurrent agents per AWS account.
  ##   body: JObject (required)
  var body_773710 = newJObject()
  if body != nil:
    body_773710 = body
  result = call_773709.call(nil, nil, nil, nil, body_773710)

var startAssessmentRun* = Call_StartAssessmentRun_773696(
    name: "startAssessmentRun", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.StartAssessmentRun",
    validator: validate_StartAssessmentRun_773697, base: "/",
    url: url_StartAssessmentRun_773698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAssessmentRun_773711 = ref object of OpenApiRestCall_772597
proc url_StopAssessmentRun_773713(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopAssessmentRun_773712(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773714 = header.getOrDefault("X-Amz-Date")
  valid_773714 = validateParameter(valid_773714, JString, required = false,
                                 default = nil)
  if valid_773714 != nil:
    section.add "X-Amz-Date", valid_773714
  var valid_773715 = header.getOrDefault("X-Amz-Security-Token")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Security-Token", valid_773715
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773716 = header.getOrDefault("X-Amz-Target")
  valid_773716 = validateParameter(valid_773716, JString, required = true, default = newJString(
      "InspectorService.StopAssessmentRun"))
  if valid_773716 != nil:
    section.add "X-Amz-Target", valid_773716
  var valid_773717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773717 = validateParameter(valid_773717, JString, required = false,
                                 default = nil)
  if valid_773717 != nil:
    section.add "X-Amz-Content-Sha256", valid_773717
  var valid_773718 = header.getOrDefault("X-Amz-Algorithm")
  valid_773718 = validateParameter(valid_773718, JString, required = false,
                                 default = nil)
  if valid_773718 != nil:
    section.add "X-Amz-Algorithm", valid_773718
  var valid_773719 = header.getOrDefault("X-Amz-Signature")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-Signature", valid_773719
  var valid_773720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-SignedHeaders", valid_773720
  var valid_773721 = header.getOrDefault("X-Amz-Credential")
  valid_773721 = validateParameter(valid_773721, JString, required = false,
                                 default = nil)
  if valid_773721 != nil:
    section.add "X-Amz-Credential", valid_773721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773723: Call_StopAssessmentRun_773711; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the assessment run that is specified by the ARN of the assessment run.
  ## 
  let valid = call_773723.validator(path, query, header, formData, body)
  let scheme = call_773723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773723.url(scheme.get, call_773723.host, call_773723.base,
                         call_773723.route, valid.getOrDefault("path"))
  result = hook(call_773723, url, valid)

proc call*(call_773724: Call_StopAssessmentRun_773711; body: JsonNode): Recallable =
  ## stopAssessmentRun
  ## Stops the assessment run that is specified by the ARN of the assessment run.
  ##   body: JObject (required)
  var body_773725 = newJObject()
  if body != nil:
    body_773725 = body
  result = call_773724.call(nil, nil, nil, nil, body_773725)

var stopAssessmentRun* = Call_StopAssessmentRun_773711(name: "stopAssessmentRun",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.StopAssessmentRun",
    validator: validate_StopAssessmentRun_773712, base: "/",
    url: url_StopAssessmentRun_773713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubscribeToEvent_773726 = ref object of OpenApiRestCall_772597
proc url_SubscribeToEvent_773728(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SubscribeToEvent_773727(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773729 = header.getOrDefault("X-Amz-Date")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "X-Amz-Date", valid_773729
  var valid_773730 = header.getOrDefault("X-Amz-Security-Token")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Security-Token", valid_773730
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773731 = header.getOrDefault("X-Amz-Target")
  valid_773731 = validateParameter(valid_773731, JString, required = true, default = newJString(
      "InspectorService.SubscribeToEvent"))
  if valid_773731 != nil:
    section.add "X-Amz-Target", valid_773731
  var valid_773732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773732 = validateParameter(valid_773732, JString, required = false,
                                 default = nil)
  if valid_773732 != nil:
    section.add "X-Amz-Content-Sha256", valid_773732
  var valid_773733 = header.getOrDefault("X-Amz-Algorithm")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "X-Amz-Algorithm", valid_773733
  var valid_773734 = header.getOrDefault("X-Amz-Signature")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "X-Amz-Signature", valid_773734
  var valid_773735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "X-Amz-SignedHeaders", valid_773735
  var valid_773736 = header.getOrDefault("X-Amz-Credential")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "X-Amz-Credential", valid_773736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773738: Call_SubscribeToEvent_773726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ## 
  let valid = call_773738.validator(path, query, header, formData, body)
  let scheme = call_773738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773738.url(scheme.get, call_773738.host, call_773738.base,
                         call_773738.route, valid.getOrDefault("path"))
  result = hook(call_773738, url, valid)

proc call*(call_773739: Call_SubscribeToEvent_773726; body: JsonNode): Recallable =
  ## subscribeToEvent
  ## Enables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ##   body: JObject (required)
  var body_773740 = newJObject()
  if body != nil:
    body_773740 = body
  result = call_773739.call(nil, nil, nil, nil, body_773740)

var subscribeToEvent* = Call_SubscribeToEvent_773726(name: "subscribeToEvent",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.SubscribeToEvent",
    validator: validate_SubscribeToEvent_773727, base: "/",
    url: url_SubscribeToEvent_773728, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnsubscribeFromEvent_773741 = ref object of OpenApiRestCall_772597
proc url_UnsubscribeFromEvent_773743(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UnsubscribeFromEvent_773742(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773744 = header.getOrDefault("X-Amz-Date")
  valid_773744 = validateParameter(valid_773744, JString, required = false,
                                 default = nil)
  if valid_773744 != nil:
    section.add "X-Amz-Date", valid_773744
  var valid_773745 = header.getOrDefault("X-Amz-Security-Token")
  valid_773745 = validateParameter(valid_773745, JString, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "X-Amz-Security-Token", valid_773745
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773746 = header.getOrDefault("X-Amz-Target")
  valid_773746 = validateParameter(valid_773746, JString, required = true, default = newJString(
      "InspectorService.UnsubscribeFromEvent"))
  if valid_773746 != nil:
    section.add "X-Amz-Target", valid_773746
  var valid_773747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "X-Amz-Content-Sha256", valid_773747
  var valid_773748 = header.getOrDefault("X-Amz-Algorithm")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-Algorithm", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Signature")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Signature", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-SignedHeaders", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-Credential")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Credential", valid_773751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773753: Call_UnsubscribeFromEvent_773741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ## 
  let valid = call_773753.validator(path, query, header, formData, body)
  let scheme = call_773753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773753.url(scheme.get, call_773753.host, call_773753.base,
                         call_773753.route, valid.getOrDefault("path"))
  result = hook(call_773753, url, valid)

proc call*(call_773754: Call_UnsubscribeFromEvent_773741; body: JsonNode): Recallable =
  ## unsubscribeFromEvent
  ## Disables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ##   body: JObject (required)
  var body_773755 = newJObject()
  if body != nil:
    body_773755 = body
  result = call_773754.call(nil, nil, nil, nil, body_773755)

var unsubscribeFromEvent* = Call_UnsubscribeFromEvent_773741(
    name: "unsubscribeFromEvent", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.UnsubscribeFromEvent",
    validator: validate_UnsubscribeFromEvent_773742, base: "/",
    url: url_UnsubscribeFromEvent_773743, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssessmentTarget_773756 = ref object of OpenApiRestCall_772597
proc url_UpdateAssessmentTarget_773758(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAssessmentTarget_773757(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773759 = header.getOrDefault("X-Amz-Date")
  valid_773759 = validateParameter(valid_773759, JString, required = false,
                                 default = nil)
  if valid_773759 != nil:
    section.add "X-Amz-Date", valid_773759
  var valid_773760 = header.getOrDefault("X-Amz-Security-Token")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-Security-Token", valid_773760
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773761 = header.getOrDefault("X-Amz-Target")
  valid_773761 = validateParameter(valid_773761, JString, required = true, default = newJString(
      "InspectorService.UpdateAssessmentTarget"))
  if valid_773761 != nil:
    section.add "X-Amz-Target", valid_773761
  var valid_773762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773762 = validateParameter(valid_773762, JString, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "X-Amz-Content-Sha256", valid_773762
  var valid_773763 = header.getOrDefault("X-Amz-Algorithm")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "X-Amz-Algorithm", valid_773763
  var valid_773764 = header.getOrDefault("X-Amz-Signature")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Signature", valid_773764
  var valid_773765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-SignedHeaders", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-Credential")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-Credential", valid_773766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773768: Call_UpdateAssessmentTarget_773756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the assessment target that is specified by the ARN of the assessment target.</p> <p>If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target.</p>
  ## 
  let valid = call_773768.validator(path, query, header, formData, body)
  let scheme = call_773768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773768.url(scheme.get, call_773768.host, call_773768.base,
                         call_773768.route, valid.getOrDefault("path"))
  result = hook(call_773768, url, valid)

proc call*(call_773769: Call_UpdateAssessmentTarget_773756; body: JsonNode): Recallable =
  ## updateAssessmentTarget
  ## <p>Updates the assessment target that is specified by the ARN of the assessment target.</p> <p>If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target.</p>
  ##   body: JObject (required)
  var body_773770 = newJObject()
  if body != nil:
    body_773770 = body
  result = call_773769.call(nil, nil, nil, nil, body_773770)

var updateAssessmentTarget* = Call_UpdateAssessmentTarget_773756(
    name: "updateAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.UpdateAssessmentTarget",
    validator: validate_UpdateAssessmentTarget_773757, base: "/",
    url: url_UpdateAssessmentTarget_773758, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
